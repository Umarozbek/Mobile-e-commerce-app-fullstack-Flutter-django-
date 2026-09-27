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

# E'TIBOR: bu faylda ILGARI o'zining ALOHIDA TeleBot obyekti ("bot") va
# alohida yes|/no|/sent| handler'lari bo'lgan - order_bot.py dagi tbot bilan
# BUTUNLAY BOG'LIQ EMAS edi. Telegram bir vaqtning o'zida faqat BITTA
# webhook URL'ga so'rov yuboradi (yoki bot.py dagi /dashboard/bot/, yoki
# order_bot.py dagi /bot/index/) - qaysi biri ro'yxatdan o'tgan bo'lsa,
# FAQAT o'sha fayl handler'lari haqiqiy tugma bosishlarni qabul qilardi,
# ikkinchisi esa hech qachon ishlamaydigan "o'lik" kod bo'lib qolardi.
# Bu aynan "tugmalarni boshqara olmayapman" xatosining sababi edi -
# ehtimol webhook shu faylga (yoki aksincha) ko'rsatilgan bo'lib, aynan
# o'sha fayldagi eskirroq/xatolarga to'la handler ishlagan.
#
# Yechim: BU FAYL ENDI O'ZINING TeleBot OBYEKTINI SAQLAMAYDI - qaysi URL
# chaqirilsa ham, ikkalasi ham order_bot.py dagi BITTA tbot orqali qayta
# ishlanadi, shu bilan qaysi webhook ro'yxatdan o'tganidan qat'iy nazar
# xatti-harakat bir xil va to'g'ri bo'ladi.
from apps.dashboard.order_bot import tbot as bot


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


# E'TIBOR: "yes|"/"no|" handler'lari BU YERDAN OLIB TASHLANDI - order_bot.py
# dagi handle_order_decision() ENDI YAGONA MANBA (bot ikkalasi ham bitta
# tbot obyekti bo'lgani uchun, shu yerda qayta ro'yxatdan o'tkazish ikki
# marta ishlov berishga - va ikkinchi answer_callback_query chaqiruvi
# Telegram xatosiga - olib kelardi). "Qabul qilish"/"Rad etish" mantig'i
# uchun order_bot.py'ga qarang.


# --- CALLBACK: YUBORILDI (SENT) ---
@bot.callback_query_handler(func=lambda call: call.data.startswith("sent|"))
def handle_sent(call):
    from apps.merchant.models import TelegramSettings

    try:
        order_id = int(call.data.split('|')[-1])
    except (ValueError, IndexError):
        bot.answer_callback_query(call.id, text="Noto'g'ri callback ma'lumoti.", show_alert=True)
        return

    settings_obj = TelegramSettings.get_solo()
    if not settings_obj.is_authorized_admin(call.from_user.id):
        bot.answer_callback_query(call.id, text="Sizga bu amalni bajarishga ruxsat berilmagan.", show_alert=True)
        return

    try:
        order = Order.objects.get(id=order_id)
    except Order.DoesNotExist:
        bot.answer_callback_query(call.id, text="Buyurtma topilmadi.", show_alert=True)
        return

    try:
        # E'TIBOR: "sent" pastki harf bilan emas - Order.STATUS_CHOICES'dagi
        # haqiqiy qiymat katta harf bilan "Sent" (avval bu yerda "sent"
        # yozilgan bo'lib, hech qachon haqiqiy statusga mos kelmasdi va
        # bonus/statistika logikasi uni "noma'lum" status sifatida ko'rardi).
        if order.status == "Sent":
            bot.answer_callback_query(call.id, text="Bu buyurtma allaqachon yuborilgan deb belgilangan.", show_alert=True)
            return

        with transaction.atomic():
            order.status = 'Sent'
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

        try:
            if call.message.photo:
                bot.edit_message_caption(chat_id=call.message.chat.id, message_id=call.message.message_id,
                                         caption=text, reply_markup=None)
            else:
                bot.edit_message_text(chat_id=call.message.chat.id, message_id=call.message.message_id,
                                      text=text, reply_markup=None)
        except Exception as e:
            print(f"[WARNING] Xabarni tahrirlab bo'lmadi: {e}")

        bot.answer_callback_query(call.id, text="Buyurtma yuborildi deb belgilandi!")

    except Exception as e:
        print(f"[ERROR] handle_sent xatosi: {e}")
        try:
            bot.answer_callback_query(call.id, text="Xatolik yuz berdi, qaytadan urinib ko'ring.", show_alert=True)
        except Exception:
            pass
