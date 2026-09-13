import telebot
from django.urls import reverse
from django.http import HttpResponseRedirect, HttpResponse
from django.views.decorators.csrf import csrf_exempt
from telebot import types

from apps.merchant.models import Information, Service, Order, Bonus, LoyaltyPendingBonus
from apps.customer.models import Banner, Profile
from apps.product.models import SoldProduct, ProductItem
from decouple import config
import requests
import urllib.parse
import json
from django.shortcuts import render, redirect, get_object_or_404
from django.views.generic import ListView, DetailView
from django.views import View
from django.contrib import messages
from .forms import ServiceEditForm, InformationEditForm
from apps.dashboard.forms import BannerForm, NewsForm, NewsEditForm, BonusEditForm
from apps.customer.models import News
from apps.customer.fcm_service import FCMService
from datetime import date
from decimal import Decimal

CHANNEL = int(config("CHANNEL", default="0"))
CHAT_ID = int(config("CHAT_ID", default="0"))
BOT_TOKEN = config("BOT_TOKEN", default="")
CHANNEL_USERNAME = "@openai_chat_gpt_robot"
ADMINS = config("ADMIN", [255081705])
tbot = telebot.TeleBot(BOT_TOKEN, parse_mode="HTML")





def number_cutter(number):
    if number is not None:
        number = number.count()
        if number >= 100000:
            number = f"{round(number / 1000000, 2)}M"
        elif number >= 1000:
            return f"{round(number / 1000, 2)}K"
        else:
            return number
    else:
        return 0


def decimal_cutter(number):
    if number is not None:
        if number >= Decimal("100000"):
            return f"{round(number / Decimal('1000000'), 2)}M"
        elif number >= Decimal("1000"):
            return f"{round(number / Decimal('1000'), 2)}K"
        else:
            return number
    else:
        return 0


from django.db.models import Count, Sum, F


def dashboard(request):
    today = date.today()

    # Umumiy buyurtmalar obyekti
    all_orders = Order.objects.all()

    # --- 1. TEZKOR HARAKATLAR (Admin tasdiqlashi kerak bo'lgan narsalar) ---
    pending_orders_count = all_orders.filter(status="pending").count()  # Tovar borligini kutayotganlar
    check_pending_count = all_orders.filter(
        status="check_pending").count()  # To'lov cheki tekshirilishi kerak bo'lganlar
    pending_bonuses = LoyaltyPendingBonus.objects.filter(status="pending").count()
    # pending_b2b = B2BApplication.objects.filter(status="pending").count() # Agar model bo'lsa qo'shing

    # --- 2. BUGUNGI STATISTIKA ---
    order_today = all_orders.filter(created_at__date=today)
    order_today_count = order_today.count()

    # Bugungi daromad (faqat tasdiqlangan va yuborilganlar)
    revenue_today = order_today.filter(status__in=["approved", "sent"]).aggregate(total=Sum("total_amount"))[
                        "total"] or 0

    # --- 3. UMUMIY STATISTIKA ---
    customers_count = Profile.objects.count()
    customers_today_count = Profile.objects.filter(created_at__date=today).count()
    total_revenue = all_orders.filter(status__in=["approved", "sent"]).aggregate(total=Sum("total_amount"))[
                        "total"] or 0

    # --- 4. MAHSULOTLAR TAHLILI ---
    # Omborda kam qolganlar (Shoshilinch)
    low_stock_products = ProductItem.objects.filter(available_quantity__lt=10, active=True).order_by(
        'available_quantity')[:10]

    # Eng ko'p sotilganlar
    top_selling_products = SoldProduct.objects.values(
        "product__goods__name_uz",
        "product__phones__model_name_uz",
        "product__tickets__event_name_uz"
    ).annotate(total_qty=Sum("quantity")).order_by("-total_qty")[:10]

    # Grafik uchun ma'lumotlar
    chart_data = []
    for p in top_selling_products:
        title = p.get("product__goods__name_uz") or p.get("product__phones__model_name_uz") or p.get(
            "product__tickets__event_name_uz") or "Nomsiz"
        chart_data.append({"title": title, "total_quantity": p["total_qty"]})

    # So'nggi buyurtmalar
    recent_orders = all_orders.select_related("user").order_by("-created_at")[:15]

    # Buyurtmalar holati taqsimoti (donut chart uchun - real, hisoblab olingan ma'lumot)
    status_display_map = dict(Order.STATUS_CHOICES)
    order_status_data = [
        {"label": status_display_map.get(row["status"], row["status"]), "count": row["count"]}
        for row in all_orders.values("status").annotate(count=Count("id")).order_by("-count")
        if row["count"] > 0
    ]

    return render(request, "base.html", {
        "pending_orders": pending_orders_count,
        "check_pending": check_pending_count,
        "pending_bonuses": pending_bonuses,
        "order_today_count": order_today_count,
        "revenue_today": revenue_today,
        "customers": customers_count,
        "customers_today": customers_today_count,
        "total_revenue": total_revenue,
        "recent": recent_orders,
        "chart_data": chart_data,
        "order_status_data": order_status_data,
        "low_stock": low_stock_products,
        "comments": all_orders.exclude(comment="").order_by("-created_at")[:10],
    })


def get_first_image_url(product_item):
    first_image = product_item.images.first()
    return first_image.image.url if first_image else None


class InformationView(ListView):
    model = Information
    template_name = "dashboard/information/info_list.html"
    context_object_name = "infos"

    def get_queryset(self):
        return Information.objects.all()

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        return context


class InformationEditView(View):
    template_name = "dashboard/information/edit_info.html"

    def get(self, request, pk):
        info = get_object_or_404(Information, pk=pk)
        key = request.GET.get("key", None)
        form = InformationEditForm(instance=info)
        return render(
            request, self.template_name, {"form": form, "info": info, "key": key}
        )

    def post(self, request, pk):
        info = get_object_or_404(Information, pk=pk)
        form = InformationEditForm(request.POST, instance=info)

        if "edit" in request.POST and form.is_valid():
            form.save()
            return redirect("info-list")

        return render(request, self.template_name, {"form": form, "info": info})


class ServiceView(ListView):
    model = Service
    template_name = "dashboard/service/service_list.html"
    context_object_name = "services"

    def get_queryset(self):
        return Service.objects.all()

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)

        # Fetch Bonus objects separately
        bonuses = Bonus.objects.all().order_by("pk")

        # Add the Bonus objects to the context
        context["bonuses"] = bonuses

        return context


class BannerView(ListView):
    model = Banner
    template_name = "dashboard/banner.html"
    context_object_name = "banners"
    form_class = BannerForm

    def get_queryset(self):
        return Banner.objects.all().order_by("-created")

    def get(self, request, *args, **kwargs):
        form = self.form_class()
        return render(
            request, self.template_name, {"banners": self.get_queryset(), "form": form}
        )

    def post(self, request, *args, **kwargs):
        form = self.form_class(request.POST, request.FILES)
        if form.is_valid():
            form.save()
            return redirect("banner-list")
        else:
            return render(
                request,
                self.template_name,
                {"banners": self.get_queryset(), "form": form},
            )


class BannerActionView(View):
    def post(self, request, *args, **kwargs):
        if "action" not in request.POST:
            return render(
                request, "error.html", {"error_message": "Action not specified"}
            )

        action = request.POST.get("action")

        if action == "toggle":
            # Toggle the active status
            banner = get_object_or_404(Banner, pk=kwargs["pk"])
            banner.active = not banner.active
            banner.save()
        elif action == "delete":
            # Delete the banner
            banner = get_object_or_404(Banner, pk=kwargs["pk"])
            banner.delete()

        return redirect("banner-list")


class ServiceEditView(View):
    template_name = "dashboard/service/edit_service.html"

    def get(self, request, pk):
        service = get_object_or_404(Service, pk=pk)
        form = ServiceEditForm(instance=service)
        return render(request, self.template_name, {"form": form, "service": service})

    def post(self, request, pk):
        service = get_object_or_404(Service, pk=pk)
        if "edit" in request.POST:
            form = ServiceEditForm(request.POST, instance=service)
            if form.is_valid():
                form.save()
                return redirect("service-list")
        return render(request, self.template_name, {"form": form, "service": service})


class NewsListView(ListView):
    model = News
    template_name = "dashboard/news/news_list.html"
    context_object_name = "news"

    def get_queryset(self):
        return News.objects.all().order_by("-pk")

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        return context


class NewsCreateView(View):
    template_name = "dashboard/news/news_create.html"

    def get(self, request):
        form = NewsForm()
        return render(request, self.template_name, {"form": form})

    def post(self, request):
        form = NewsForm(request.POST, request.FILES)
        if form.is_valid():
            form.save()
            return redirect("news-list")
        else:
            return render(request, self.template_name, {"form": form})


class NewsEditView(View):
    template_name = "dashboard/news/edit_delete_news.html"

    def get(self, request, pk):
        news = get_object_or_404(News, pk=pk)
        form = NewsEditForm(instance=news)
        return render(request, self.template_name, {"form": form, "news": news})

    def post(self, request, pk):
        news = get_object_or_404(News, pk=pk)
        form = NewsEditForm(request.POST, request.FILES, instance=news)

        if "edit" in request.POST:
            if form.is_valid():
                # NewsEditForm.save() 'commit' argumentisiz chaqirilsa, uning
                # o'z default qiymati (commit=False) ishlatiladi va yozuv
                # bazaga YOZILMAYDI - faqat yangi rasm yuklanganda tasodifan
                # saqlanardi (FieldFile.save() to'liq instance.save()ni
                # chaqiradi). Shu sababli rasm o'zgartirilmasa, tahrirlash
                # HECH NARSANI saqlamas edi (topilgan xato, tuzatildi).
                form.save(commit=True)
                return redirect("news-list")
        if "delete" in request.POST:
            news = get_object_or_404(News, pk=pk)
            news.delete()
            return redirect("news-list")

        # If it's not a valid form or a delete action, render the form with the existing data
        return render(request, self.template_name, {"form": form, "news": news})


class NewsActionView(View):
    """E'lonni faollashtirish/o'chirish (list sahifasidan bitta tugma bilan)."""

    def post(self, request, *args, **kwargs):
        if "action" not in request.POST:
            return render(
                request, "error.html", {"error_message": "Action not specified"}
            )

        action = request.POST.get("action")
        news = get_object_or_404(News, pk=kwargs["pk"])

        if action == "toggle":
            news.active = not news.active
            news.save()
        elif action == "delete":
            news.delete()

        return redirect("news-list")


def send_push_for_news(request, news):
    """News/Notification uchun push payload'ini quradi va FCMService orqali
    yuboradi. Bitta joyda - NewsSendPushView VA push_compose_view (bunda
    xabar avval News sifatida saqlanadi) ikkalasi ham shu funksiyani
    ishlatadi, mantiq ikki joyda duplikatsiya bo'lib chalkashib
    ketmasligi uchun.

    Firebase bilan bevosita ishlamaydi - hammasi FCMService orqali
    (apps/customer/fcm_service.py). Bu yerda faqat: News'dan payload
    yig'ish va servisni chaqirish.
    """
    image_url = None
    if news.image and hasattr(news.image, "url"):
        image_url = request.build_absolute_uri(news.image.url)

    return FCMService.broadcast(
        title=news.title or "",
        body=news.description or "",
        image=image_url,
        data={
            "notificationId": str(news.id),
            "type": news.type,
            "link": news.link or "",
        },
    )


def report_push_result(request, result):
    """FCMService.broadcast() natijasini admin'ga messages orqali ko'rsatadi."""
    if not result["configured"]:
        messages.error(request, f"Firebase sozlanmagan: {result['error']}")
    elif result["total_tokens"] == 0:
        messages.warning(request, "Faol qurilma tokeni topilmadi - push yuborilmadi.")
    else:
        messages.success(
            request,
            f"Push yuborildi: {result['sent']} ta muvaffaqiyatli, "
            f"{result['failed']} ta xato, {result['deactivated']} ta yaroqsiz token faolsizlantirildi."
        )


class NewsSendPushView(View):
    """"Push yuborish" tugmasi - News/Notification bo'yicha barcha FAOL
    DeviceToken'larga (bazadagi) push xabarnoma yuboradi."""

    def post(self, request, pk):
        news = get_object_or_404(News, pk=pk)
        result = send_push_for_news(request, news)
        report_push_result(request, result)
        return redirect("news-list")


class OrdersView(DetailView):
    model = Profile
    template_name = "customer/orders/orders_list.html"

    def get_context_data(self, **kwargs):
        context = super(OrdersView, self).get_context_data(**kwargs)
        user = get_object_or_404(Profile, id=self.kwargs["pk"])
        orders = Order.objects.filter(user=user)

        if orders:
            context["orders"] = orders
            context["user"] = user
        else:
            context["no_orders_message"] = "Foydalanuvhi hali buyurtma qilmagan"

        return context

    def post(self, request, *args, **kwargs):
        order_id = self.kwargs["pk"]
        order = get_object_or_404(Order, id=order_id)
        new_status = request.POST.get("status")

        if new_status in dict(order.STATUS_CHOICES):
            order.status = new_status
            order.save()

        return HttpResponseRedirect(
            reverse("orders-list", kwargs={"pk": order.user.id})
        )


def bot(order):
    print(f"\n[SEND] Bot: Xabar yuborish boshlandi. Order ID: {order.id}")
    delivery_price = order.delivery_fee.delivery_fee if order.delivery_fee else 0
    product_amount = order.total_amount - delivery_price

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
    text += "📦 <b>MAHSULOTLAR</b>\n\n"

    for item in order.orderitem.all():
        p = item.product
        p_name = p.goods.name if hasattr(p, 'goods') else (p.phones.model_name if hasattr(p, 'phones') else "Mahsulot")
        price = p.new_price if p.new_price > 0 else p.old_price
        text += f"🟢 {p_name} — {item.quantity} dona × {price:,.0f} ₩ = {(price * item.quantity):,.0f} ₩\n"
    print(f"[SEND] Bot: Tugmalar ORD ID {order.id} bilan yasaldi.")
    text += f"\n⁉️ <u>To`lov amalga oshirilganligini tasdiqlaysizmi?</u>"

    # Tugmalar
    markup = types.InlineKeyboardMarkup(row_width=2)
    # Callback_data ichiga order.id ni yashirib yuboramiz
    markup.add(
        types.InlineKeyboardButton("✅ Ha", callback_data=f"yes|{order.id}"),
        types.InlineKeyboardButton("❌ Yo'q", callback_data=f"no|{order.id}")
    )
    print(markup)

    try:
        if order.payment_receipt:
            with order.payment_receipt.open('rb') as photo:
                tbot.send_message(CHAT_ID, text, reply_markup=markup)
                print("[SEND] Bot: Xabar Telegram kanalga yuborildi!")
        else:
            tbot.send_message(CHAT_ID, text, reply_markup=markup)
    except Exception as e:
        print(f"Telegram yuborishda xato: {e}")


@tbot.callback_query_handler(func=lambda call: call.data.startswith(('yes|', 'no|')))
def handle_order_decision(call):
    print(f"\n[STEP 4] Handler: Tugma bosildi! Data: {call.data}")

    try:
        action, order_id = call.data.split('|')
        print(f"[STEP 5] Handler: Action: {action}, Order ID: {order_id}")

        from apps.merchant.models import Order
        order = Order.objects.get(id=int(order_id))
        print(f"[STEP 6] Baza: Buyurtma topildi. Hozirgi status: {order.status}")

        if action == 'yes':
            order.status = 'approved'
            status_msg = "TASDIQLANDI"
        else:
            order.status = 'cancelled'
            status_msg = "BEKOR QILINDI"

        order.save()
        print(f"[STEP 7] Baza: Buyurtma yangi statusda saqlandi: {order.status}")

        # Telegramdagi xabarni yangilash
        print("[STEP 8] Telegram: Xabarni tahrirlash boshlandi...")

        if call.message.photo:
            tbot.edit_message_caption(
                chat_id=call.message.chat.id,
                message_id=call.message.message_id,
                caption=f"{call.message.caption}\n\n<b>Natija: {status_msg}</b>",
                parse_mode="HTML",
                reply_markup=None
            )
        else:
            tbot.edit_message_text(
                chat_id=call.message.chat.id,
                message_id=call.message.message_id,
                text=f"{call.message.text}\n\n<b>Natija: {status_msg}</b>",
                parse_mode="HTML",
                reply_markup=None
            )

        print("[STEP 9] Telegram: Xabar muvaffaqiyatli tahrirlandi.")
        tbot.answer_callback_query(call.id, text=f"Buyurtma {status_msg}!")

    except Exception as e:
        print(f"[ERROR] Handler ichida xato: {e}")
        tbot.answer_callback_query(call.id, text="Xatolik yuz berdi!", show_alert=True)


class BonusEditView(View):
    template_name = "dashboard/service/edit_bonus.html"

    def get(self, request, pk):
        bonus = get_object_or_404(Bonus, pk=pk)
        form = BonusEditForm(instance=bonus)
        return render(request, self.template_name, {"form": form, "bonus": bonus})

    def post(self, request, pk):
        bonus = get_object_or_404(Bonus, pk=pk)
        form = BonusEditForm(request.POST, instance=bonus)

        if form.is_valid():
            form.save()
            return redirect("service-list")

        return render(request, self.template_name, {"form": form, "bonus": bonus})


def delete_order_dash(request, pk):
    order = get_object_or_404(Order, pk=pk)
    # Qaysi sahifadan o'chirilayotganini bilish uchun
    page = request.POST.get('page', 1)

    if request.method == 'POST':
        order.delete()
        # O'chirib bo'lgandan keyin o'sha sahifaga qaytadi
        return redirect(f"{reverse('dashboard')}?page={page}")

    return redirect('dashboard')
