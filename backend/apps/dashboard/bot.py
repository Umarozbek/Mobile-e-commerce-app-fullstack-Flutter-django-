import json
import requests
from django.utils import timezone
from datetime import datetime, timedelta
import telebot
from django.shortcuts import HttpResponse
from django.views.decorators.csrf import csrf_exempt
from telebot import types
from decouple import config
from django.db import transaction
from apps.merchant.models import Order
from apps.product.models import SoldProduct
from django.core.exceptions import ObjectDoesNotExist
from decimal import Decimal

# --- CONFIG ---
BOT_TOKEN = config("BOT_TOKEN")
CHAT_ID = config("CHAT_ID")
bot = telebot.TeleBot(BOT_TOKEN, parse_mode="HTML")


# --- YORDAMCHI FUNKSIYA: MATNNI FORMATLASH ---
def get_order_formatted_text(order, status_title="BUYURTMA MAʼLUMOTI"):
    delivery_price = order.delivery_fee.delivery_fee if order.delivery_fee else 0
    product_amount = order.total_amount - delivery_price

    text = f"🧾 <b>{status_title}</b>\n\n"
    text += f"📦 Buyurtma: #{order.id} ({order.order_number})\n"
    text += f"👤 Mijoz: {order.user.full_name} (ID: #{order.user.id})\n"
    text += f"📞 Telefon: {order.user.phone_number}\n\n"

    text += f"📍 Manzil:\n\"{order.location.address if order.location else 'Koʻrsatilmagan'}\"\n\n"
    text += f"📝 Izoh: {order.comment or 'Yo‘q'}\n\n"

    text += f"📅 Sana: {order.created_at.strftime('%d.%m.%Y | %H:%M')}\n"
    text += f"📌 Holat: {order.get_status_display_value().upper()}\n\n"

    text += f"💰 Jami: {order.total_amount:,.0f} ₩\n"
    text += f"  • Mahsulotlar: {product_amount:,.0f} ₩\n"
    text += f"  • Yetkazib berish: {delivery_price:,.0f} ₩\n\n"

    text += "📦 <b>MAHSULOTLAR</b>\n\n"
    for item in order.orderitem.all():
        p = item.product
        p_name = "Mahsulot"
        if hasattr(p, 'goods'):
            p_name = p.goods.name
        elif hasattr(p, 'phones'):
            p_name = p.phones.model_name
        elif hasattr(p, 'tickets'):
            p_name = p.tickets.event_name

        price = p.new_price if p.new_price > 0 else p.old_price
        item_total = price * item.quantity
        text += f"🟢 {p_name} — {item.quantity} dona × {price:,.0f} ₩ = {item_total:,.0f} ₩\n"

    return text


@csrf_exempt
def index(request):
    if request.method == "POST":
        bot.process_new_updates([telebot.types.Update.de_json(request.body.decode("utf-8"))])
        return HttpResponse(status=200)
    return HttpResponse("Bot is running...")


# --- CALLBACK: HA (TASDIQLASH) ---
@bot.callback_query_handler(func=lambda call: call.data.startswith("yes|"))
def handle_yes(call):
    order_id = int(call.data.split('|')[-1])
    try:
        order = Order.objects.get(id=order_id)
        order.status = "approved"
        order.save()

        text = get_order_formatted_text(order, "✅ TASDIQLANDI")
        text += "\n\n⁉️ <u>Buyurtma yuborildimi?</u>"

        markup = types.InlineKeyboardMarkup()
        markup.add(types.InlineKeyboardButton(text="🚚 Yuborildi (Sent)", callback_data=f"sent|{order.id}"))

        # Xabarni yangilash
        if call.message.photo:
            bot.edit_message_caption(chat_id=call.message.chat.id, message_id=call.message.message_id,
                                     caption=text, reply_markup=markup)
        else:
            bot.edit_message_text(chat_id=call.message.chat.id, message_id=call.message.message_id,
                                  text=text, reply_markup=markup)

    except Exception as e:
        bot.answer_callback_query(call.id, text=f"Xato: {e}")


# --- CALLBACK: YO'Q (RAD ETISH) ---
@bot.callback_query_handler(func=lambda call: call.data.startswith("no|"))
def handle_no(call):
    order_id = int(call.data.split('|')[-1])
    try:
        order = Order.objects.get(id=order_id)
        order.status = "cancelled"
        order.save()

        text = get_order_formatted_text(order, "❌ BEKOR QILINDI")

        if call.message.photo:
            bot.edit_message_caption(chat_id=call.message.chat.id, message_id=call.message.message_id,
                                     caption=text, reply_markup=None)
        else:
            bot.edit_message_text(chat_id=call.message.chat.id, message_id=call.message.message_id,
                                  text=text, reply_markup=None)
    except Exception as e:
        bot.answer_callback_query(call.id, text=f"Xato: {e}")


# --- CALLBACK: YUBORILDI (SENT) ---
@bot.callback_query_handler(func=lambda call: call.data.startswith("sent|"))
def handle_sent(call):
    order_id = int(call.data.split('|')[-1])
    try:
        with transaction.atomic():
            order = Order.objects.get(id=order_id)
            order.status = 'sent'
            order.save()

            # Statistika (SoldProduct) qismi
            for order_item in order.orderitem.all():
                p = order_item.product
                price = p.new_price if p.new_price > 0 else p.old_price

                sold_product, created = SoldProduct.objects.get_or_create(
                    product=p, user=order.user,
                    defaults={'quantity': order_item.quantity, 'amount': price * order_item.quantity}
                )
                if not created:
                    sold_product.quantity += order_item.quantity
                    sold_product.amount += price * order_item.quantity
                    sold_product.save()

        text = get_order_formatted_text(order, "🚚 YUBORILDI")

        if call.message.photo:
            bot.edit_message_caption(chat_id=call.message.chat.id, message_id=call.message.message_id,
                                     caption=text, reply_markup=None)
        else:
            bot.edit_message_text(chat_id=call.message.chat.id, message_id=call.message.message_id,
                                  text=text, reply_markup=None)

    except Exception as e:
        bot.answer_callback_query(call.id, text=f"Xato: {e}")
