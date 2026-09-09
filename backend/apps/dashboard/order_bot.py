import json
import telebot
from telebot import types
from django.http import HttpResponse
from django.views.decorators.csrf import csrf_exempt
from decouple import config
from decimal import Decimal

from apps.merchant.models import TelegramSettings
from apps.customer.fcm_service import FCMService


def _get_bot_token():
    """TelegramSettings'dagi tokenni ishlatadi, bo'sh bo'lsa .env dagi
    BOT_TOKEN ga qaytadi (eski deploy'lar uchun moslik)."""
    settings_obj = TelegramSettings.get_solo()
    return settings_obj.bot_token or config("BOT_TOKEN", default="")


# Bot obyektini funksiya bilan adashtirmaslik uchun tbot deb nomlaymiz.
# validate_token=False - token bo'sh/placeholder bo'lsa ham import vaqtida
# butun Django ilovasi ishga tushishdan to'xtab qolmasligi uchun.
tbot = telebot.TeleBot(_get_bot_token() or "0", parse_mode="HTML", validate_token=False)


def refresh_bot_token():
    """TelegramSettings dashboard'da yangilangandan keyin chaqiriladi -
    ishlab turgan tbot obyektining tokenini yangilaydi (server qayta ishga
    tushirilishi shart emas). Callback handler'lar shu OBYEKTGA
    biriktirilgan, shuning uchun yangi obyekt yaratish kerak emas - faqat
    token maydonini yangilash yetarli."""
    tbot.token = _get_bot_token() or "0"


def send_test_message(chat_id):
    """Bitta chat ID'ga sinov xabari yuboradi. (success: bool, error: str|None) qaytaradi."""
    try:
        tbot.send_message(chat_id, "✅ Bu Million Halal Market'dan sinov xabari.")
        return True, None
    except Exception as e:
        return False, str(e)


@csrf_exempt
def telegram_webhook(request):
    print("\n[STEP 1] Webhook: Telegramdan signal keldi!")
    if request.method == "POST":
        try:
            json_str = request.body.decode("utf-8")
            update = telebot.types.Update.de_json(json_str)
            print(f"[STEP 2] Update ID: {update.update_id}")

            tbot.process_new_updates([update])

            print("[STEP 3] Ma'lumot handlerga uzatildi.")
            return HttpResponse(status=200)
        except Exception as e:
            print(f"[ERROR] Webhookda xato: {e}")
            return HttpResponse(status=500)
    return HttpResponse("OK")


def bot_send_order(order):
    print(f"\n[STEP 4] Bot: Xabar yuborish boshlandi. Order ID: {order.id}")

    settings_obj = TelegramSettings.get_solo()
    targets = settings_obj.get_chat_id_list()
    if not targets:
        # Eski .env qiymatlariga qaytish (hali sozlamalar sahifasidan
        # sozlanmagan bo'lsa ham xabar yuborishni to'xtatmaslik uchun)
        targets = [c for c in [config("CHAT_ID", default=None), config("CHANNEL", default=None)] if c]

    delivery_price = order.delivery_fee.delivery_fee if order.delivery_fee else 0
    product_amount = order.total_amount - delivery_price

    # Matn tayyorlash (bu bir marta tayyorlanadi)
    text = f"🧾 <b>BUYURTMA MAʼLUMOTI</b>\n\n"
    text += f"📦 Buyurtma: #{order.id}\n"
    text += f"👤 Mijoz: {order.user.full_name} (ID: #{order.user.id})\n"
    text += f"📞 Telefon: {order.user.phone_number}\n\n"
    text += f"📍 Manzil:\n\"{order.location.address if order.location else 'Koʻrsatilmagan'}\"\n\n"
    text += f"📝 Izoh: {order.comment or 'Yo‘q'}\n\n"
    text += f"📅 Sana: {order.created_at.strftime('%d.%m.%Y | %H:%M')}\n"
    text += f"📌 Holat: {order.get_status_display_value()}\n\n"
    text += f"💰 Jami: {order.total_amount:,.0f} ₩\n"
    text += f"  • Mahsulotlar: {product_amount:,.0f} ₩\n"
    text += f"  • Yetkazib berish: {delivery_price:,.0f} ₩\n\n"
    text += "📦 <b>MAHSULOTLAR</b>\n"

    for item in order.orderitem.all():
        p = item.product
        p_name = p.goods.name if hasattr(p, 'goods') else (p.phones.model_name if hasattr(p, 'phones') else "Mahsulot")
        price = p.new_price if p.new_price > 0 else p.old_price

        # 1. O'lchov birligini olish (KG, DONA, L va h.k.)
        measure_unit = p.get_measure_display()

        # 2. Jami narxni hisoblash
        total_item_price = item.quantity * price

        # 3. Matnga chiroyli qilib o'lchov birligi bilan qo'shish
        text += f" 🟢 <i>{p_name} — {item.quantity} {measure_unit} × {price:,.0f} ₩ = {total_item_price:,.0f} ₩</i>\n"

    # Faqat tugmalar yoqilgan bo'lsa savol qo'shamiz va klaviatura biriktiramiz
    markup = None
    if settings_obj.buttons_enabled:
        text += f"\n⁉️ <u>To`lov amalga oshirilganligini tasdiqlaysizmi?</u>"
        markup = types.InlineKeyboardMarkup(row_width=2)
        markup.add(
            types.InlineKeyboardButton("✅ Tasdiqlash", callback_data=f"yes|{order.id}"),
            types.InlineKeyboardButton("❌ Rad etish", callback_data=f"no|{order.id}")
        )

    # --- ASOSIY O'ZGARISH SHU YERDA ---
    for target in targets:
        if not target:
            continue

        try:
            if order.payment_receipt:
                # Har safar rasmni boshidan ochish kerak (Seek(0))
                with order.payment_receipt.open('rb') as photo:
                    tbot.send_photo(target, photo, caption=text, reply_markup=markup, parse_mode="HTML")
                print(f"[STEP 5] Xabar {target} manziliga yuborildi!")
            else:
                tbot.send_message(target, text, reply_markup=markup, parse_mode="HTML")
                print(f"[STEP 6] Xabar {target} manziliga yuborildi!")
        except Exception as e:
            # Telegram xatosi buyurtma yaratishni HECH QACHON to'xtatmasligi
            # kerak - shu sababli bu yerda faqat log qilinadi.
            print(f"[ERROR] {target} manziliga yuborishda xato: {e}")


def _notify_customer_push(order, status_for_mobile):
    """Buyurtma holati Telegram tugmasi orqali o'zgarganda mijozning
    qurilmasiga (barcha faol DeviceToken'lariga) maqsadli push yuboradi.

    Payload shakli MOBIL BILAN KELISHILGAN SHARTNOMA - o'zgartirilmaydi:
        {"type": "order_status", "order_id": "<id>", "status": "approved"|"rejected"}
    """
    try:
        title = "Buyurtma tasdiqlandi" if status_for_mobile == "approved" else "Buyurtma rad etildi"
        body = f"Buyurtma #{order.order_number} holati yangilandi."
        FCMService.send_to_profile(
            order.user,
            title=title,
            body=body,
            data={
                "type": "order_status",
                "order_id": str(order.id),
                "status": status_for_mobile,
            },
        )
    except Exception as e:
        # Push xatosi Telegram callback'ni yoki buyurtma holatini
        # o'zgartirishni HECH QACHON bloklamasligi kerak.
        print(f"[ERROR] Maqsadli push yuborishda xato: {e}")


@tbot.callback_query_handler(func=lambda call: call.data.startswith(('yes|', 'no|')))
def handle_order_decision(call):
    print(f"\n[STEP 7] Handler: Tugma bosildi! Data: {call.data}")
    action, order_id = call.data.split('|')

    try:
        from apps.merchant.models import Order
        order = Order.objects.get(id=int(order_id))

        resolver_name = call.from_user.first_name or call.from_user.username or "Admin"
        if call.from_user.last_name:
            resolver_name += f" {call.from_user.last_name}"

        if action == 'yes':
            order.status = 'approved'
            status_msg = "TASDIQLANDI"
            status_for_mobile = "approved"
        else:
            # ESLATMA: "rejected" alohida Order status sifatida QO'SHILMADI -
            # mavjud "cancelled" statusi ishlatilmoqda (u allaqachon
            # bonus/refund logikasiga bog'langan). Mobil ilova uchun esa
            # payload'da aynan "rejected" yuboriladi (shartnoma shunday).
            order.status = 'cancelled'
            status_msg = "BEKOR QILINDI (RAD ETILDI)"
            status_for_mobile = "rejected"

        order.save()
        print(f"[STEP 8] Baza yangilandi: {order.status}")

        new_text = (
            f"📌 <b>Buyurtma holati o'zgardi</b>\n\n"
            f"Natija: <b>{status_msg}</b>\n"
            f"Kim hal qildi: <b>{resolver_name}</b>\n\n"
        )

        # Xabarni tahrirlash (Edit)
        if call.message.photo:
            # Rasm ostidagi matnni tahrirlaymiz
            tbot.edit_message_caption(
                chat_id=call.message.chat.id,
                message_id=call.message.message_id,
                caption=new_text + (call.message.caption or ""),
                reply_markup=None,
                parse_mode="HTML"
            )
        else:
            # Oddiy matnni tahrirlaymiz
            tbot.edit_message_text(
                chat_id=call.message.chat.id,
                message_id=call.message.message_id,
                text=new_text + (call.message.text or ""),
                reply_markup=None,
                parse_mode="HTML"
            )

        tbot.answer_callback_query(call.id, text=f"Buyurtma {status_msg}!")
        print("[STEP 9] Xabar tahrirlandi.")

        # Mijozga maqsadli push (broadcast EMAS - faqat shu buyurtma egasiga)
        _notify_customer_push(order, status_for_mobile)

    except Exception as e:
        print(f"[ERROR] Handler xatosi: {e}")
