from decimal import Decimal, InvalidOperation

from apps.customer.models import Profile, Location, B2BApplication, News
from apps.merchant.models import Order, OrderItem, Service, BankCardModel, ShippingSettings, OrderBonusTier, LoyaltyPendingBonus, TelegramSettings, AppUpdateSettings
from django.contrib import messages
from django.views.generic import ListView, DetailView, CreateView, UpdateView, DeleteView
from django.shortcuts import render, redirect, HttpResponse
from django.shortcuts import get_object_or_404, redirect
from django.views import View
from django.views.generic import ListView
from django.db.models import Subquery, OuterRef
from django.urls import reverse, reverse_lazy
from django.http import HttpResponseRedirect
from django.db.models import Prefetch, Q, Count


class UserListView(ListView):
    model = Profile
    template_name = "customer/users/users_list.html"
    context_object_name = "users"
    paginate_by = 10

    def get_queryset(self):
        # Qidiruv so'rovini olish
        query = self.request.GET.get('q', '').strip()

        # Asosiy queryset
        profiles = Profile.objects.select_related("origin").order_by("-pk")

        # Agar qidiruv so'zi bo'lsa, ism, tel raqam yoki ID bo'yicha filterlash
        if query:
            profiles = profiles.filter(
                Q(full_name__icontains=query) |
                Q(phone_number__icontains=query) |
                Q(id__icontains=query)
            )
        return profiles

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)

        # Hozirgi sahifadagi foydalanuvchilar (pagination hisobga olingan)
        users = context.get('users')

        # Faqat hozirgi sahifadagi foydalanuvchilarning manzillarini olish (Optimizatsiya)
        active_locations = {}
        if users:
            for profile in users:
                profile_locations = Location.objects.filter(user=profile, active=True)
                active_locations[profile] = profile_locations

        context["active_locations"] = active_locations
        return context


class BlockActivateUserView(View):
    def get(self, request, pk):
        user = get_object_or_404(Profile, id=pk)
        user.origin.is_active = not user.origin.is_active
        user.origin.save()
        return redirect("users-list")


class UserOrdersView(DetailView):
    model = Profile
    template_name = "customer/users/user_orders_list.html"

    def get_context_data(self, **kwargs):
        context = super(UserOrdersView, self).get_context_data(**kwargs)

        # 1. Foydalanuvchini olish (DetailView o'zi self.object orqali beradi)
        user_profile = self.get_object()

        # 2. Qidiruv so'rovini olish
        query = self.request.GET.get('q')

        # 3. Shu foydalanuvchiga tegishli buyurtmalarni olish
        orders = Order.objects.filter(user=user_profile).order_by('-created_at')

        # 4. Agar qidiruv so'rovi bo'lsa, filterlash
        if query:
            orders = orders.filter(
                Q(order_number__icontains=query) |  # ID bo'yicha qidirish
                Q(status__icontains=query) |  # Holati bo'yicha
                Q(total_amount__icontains=query)  # Summa bo'yicha
            )

        # 5. Context-ga ma'lumotlarni yuklash
        context["orders"] = orders
        context["user"] = user_profile

        if not orders.exists():
            if query:
                context["no_orders_message"] = f"'{query}' bo'yicha buyurtma topilmadi."
            else:
                context["no_orders_message"] = "Foydalanuvchi hali buyurtma qilmagan."

        return context


class UserOrderDetailView(DetailView):
    model = Order
    template_name = "customer/users/user_order_detail.html"

    def get_context_data(self, **kwargs):
        context = super(UserOrderDetailView, self).get_context_data(**kwargs)
        order = Order.objects.get(id=self.kwargs["pk"])
        order_items = OrderItem.objects.filter(order__id=self.kwargs["pk"])
        user = order.user
        cargo = Service.objects.all().first().delivery_fee

        total_products_amount = 0
        order_items_data = []  # List to store data for each OrderItem

        for order_item in order_items:
            product_type, details = self.get_product_type(order_item.product)
            first_image_url = self.get_first_image_url(order_item.product)
            # Calculate total price for each OrderItem
            if order_item.product.new_price:
                total_price = order_item.quantity * order_item.product.new_price
            elif order_item.product.old_price:
                total_price = order_item.quantity * order_item.product.old_price
            else:
                total_price = 0

            total_products_amount += total_price

            # Add data for each OrderItem to the list
            order_items_data.append(
                {
                    "order_item": order_item,
                    "product_type": product_type,
                    "details": details,
                    "total_price": total_price,
                    "first_image_url": first_image_url,
                }
            )

        if order_items:
            context["order_items_data"] = order_items_data
            context["user"] = user
            context["order"] = order
            context["cargo"] = cargo
            context["total_products_amount"] = total_products_amount
        else:
            context["no_orders_message"] = "This user has no orders."

        return context

    def get_first_image_url(self, product_item):
        # Get the first image URL for the product
        first_image = product_item.images.first()
        return first_image.image.url if first_image else None

    def get_product_type(self, product_item):
        if hasattr(product_item, "phones"):
            return "Phone", {
                "model_name": product_item.phones.model_name,
                "ram": product_item.phones.get_ram_display(),
                "storage": product_item.phones.get_storage_display(),
                "color": product_item.phones.get_color_display(),
                "condition": product_item.phones.get_condition_display(),
            }
        elif hasattr(product_item, "tickets"):
            x = "Ticket", {
                "event_name": product_item.tickets.event_name,
                "event_date": product_item.tickets.event_date,
                "category": (
                    product_item.tickets.category.name
                    if product_item.tickets.category
                    else "Bilet"
                ),
                "price": (
                    product_item.new_price
                    if product_item.new_price
                    else product_item.old_price
                ),
            }
            return x
        elif hasattr(product_item, "goods"):
            return "Good", {
                "name": product_item.goods.name_uz,
                "ingredients": product_item.goods.ingredients,
                "expire_date": product_item.goods.expire_date,
            }
        return None, None


class OrdersListView(ListView):
    template_name = "customer/orders/orders_list.html"
    context_object_name = "orders"

    def get_paginate_by(self, queryset):
        # URLdan per_page ni oladi, bo'lmasa 10 ni ishlatadi
        return self.request.GET.get('per_page', 25)

    def get_queryset(self):
        query = self.request.GET.get('q', '')
        # Faqat savatchada bo'lmagan (in_cart emas) haqiqiy buyurtmalar
        # Va ixtiyoriy: faqat lokatsiyasi borlarini ko'rsatish mumkin
        orders = Order.objects.exclude(status='in_cart').select_related("user").order_by("-id")

        if query:
            orders = orders.filter(Q(user__full_name__icontains=query) |
                                   Q(user__phone_number__icontains=query) |
                                   Q(id__icontains=query))
        return orders




class UnpaidOrdersListView(ListView):
    template_name = "customer/orders/unpaid_orders_list.html"
    context_object_name = "orders"
    paginate_by = 10

    def get_queryset(self):
        query = self.request.GET.get('q', '')
        # Faqat to'lovi kutilayotgan yoki lokatsiyasi yo'q shubhali buyurtmalar
        orders = Order.objects.filter(status='pending').select_related("user").order_by("-id")

        if query:
            orders = orders.filter(Q(user__full_name__icontains=query) | Q(id__icontains=query))
        return orders


class PaymentPendingOrdersListView(ListView):
    template_name = "customer/orders/payment_pending_orders.html"
    context_object_name = "orders"
    paginate_by = 25

    def get_queryset(self):
        query = self.request.GET.get('q', '')
        # Faqat to'lov kutilayotgan buyurtmalar
        orders = Order.objects.filter(status='payment_pending').select_related("user").order_by("-id")

        if query:
            orders = orders.filter(Q(user__full_name__icontains=query) | Q(id__icontains=query))
        return orders


def update_order_status(request, pk):
    order = get_object_or_404(Order, id=pk)

    if request.method == "POST":
        new_status = request.POST.get("status")
        if new_status in dict(order.STATUS_CHOICES):
            order.status = new_status
            order.save()

    # 1. Qayerdan kelganini aniqlaymiz
    referer = request.META.get('HTTP_REFERER')

    # 2. Agar referer bo'lsa (ya'ni qaysidir sahifadan kelgan bo'lsa), o'sha yerga qaytaramiz
    if referer:
        return HttpResponseRedirect(referer)

    # 3. Agar referer topilmasa (masalan, to'g'ridan-to'g'ri link orqali kirgan bo'lsa),
    # zaxira sifatida asosiy ro'yxatga qaytaramiz
    return HttpResponseRedirect(reverse("all-orders-list"))


from django.shortcuts import render, redirect
from django.contrib.auth import authenticate, login, logout
from .forms import LoginForm, BankCardForm, ServiceForm, OrderBonusTierForm, TelegramSettingsForm, PushComposeForm, AppUpdateSettingsForm
from django.contrib import messages


def user_login(request):
    if request.method == "POST":
        form = LoginForm(request.POST)
        if form.is_valid():
            username = form.cleaned_data["username"]
            password = form.cleaned_data["password"]
            user = authenticate(request, username=username, password=password)

            if user is not None:
                login(request, user)
                next_url = request.POST.get("next", "dashboard")
                if next_url == "":
                    return redirect("dashboard")
                    # Agar 'next' mavjud bo'lmasa, 'dashboard'ga yo'naltiradi
                return redirect(next_url)
            else:
                messages.error(request, "Login yoki parol xato")
    else:
        form = LoginForm()

    return render(request, "login.html", {"form": form})


# logout page
def user_logout(request):
    logout(request)
    return redirect("login_page")


def order_update_status(request, pk):
    if request.method == "POST":
        order = get_object_or_404(Order, id=pk)
        new_status = request.POST.get('status')
        if new_status:
            order.status = new_status
            order.save()

    # Qayerga qaytishni ko'rsatish (buyurtmalar ro'yxati sahifasiga)
    return redirect(request.META.get('HTTP_REFERER', 'user-orders-list'))


def b2b_applications_list(request):
    applications = B2BApplication.objects.all().order_by('-created')

    # MANA SHU QATORNI QO'SHING:
    status_choices = B2BApplication.Status.choices

    return render(request, "customer/users/b2b_applications.html", {
        "applications": applications,
        "status_choices": status_choices  # Context-ga qo'shib yuboramiz
    })


def update_b2b_status(request, pk):
    if request.method == "POST":
        application = get_object_or_404(B2BApplication, pk=pk)
        new_status = request.POST.get('status')
        if new_status in B2BApplication.Status.values:
            application.status = new_status
            application.save()  # Bu yerda modeldagi save() ishlaydi va user.is_b2b = True bo'ladi
    return redirect('b2b-applications-list')


class BankCardListView(ListView):
    model = BankCardModel
    template_name = "finance/bank_card_list.html"
    context_object_name = "cards"


class BankCardCreateView(CreateView):
    model = BankCardModel
    form_class = BankCardForm
    template_name = "finance/form.html"
    success_url = reverse_lazy('bank-card-list')
    extra_context = {'title': 'Yangi bank kartasi qo\'shish'}


class BankCardUpdateView(UpdateView):
    model = BankCardModel
    form_class = BankCardForm
    template_name = "finance/form.html"
    success_url = reverse_lazy('bank-card-list')
    extra_context = {'title': 'Kartani tahrirlash'}


class BankCardDeleteView(DeleteView):
    model = BankCardModel
    success_url = reverse_lazy('bank-card-list')


# --- SERVICE (DELIVERY FEE) VIEWS ---
class ServiceListView(ListView):
    model = Service
    template_name = "finance/service_list.html"
    context_object_name = "services"

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context["shipping_settings"] = ShippingSettings.get_solo()
        return context


def update_shipping_settings(request):
    settings_obj = ShippingSettings.get_solo()

    if request.method == 'POST':
        try:
            base_fee = Decimal(request.POST.get('base_fee', ''))
            if base_fee < 0:
                raise InvalidOperation
        except (InvalidOperation, TypeError):
            messages.error(request, "Narx to'g'ri kiritilishi kerak.")
            return redirect('delivery-fee-list')

        settings_obj.base_fee = base_fee
        settings_obj.save()
        messages.success(request, "Yetkazib berish sozlamalari yangilandi.")

    return redirect('delivery-fee-list')


class ServiceCreateView(CreateView):
    model = Service
    form_class = ServiceForm
    template_name = "finance/form.html"
    success_url = reverse_lazy('delivery-fee-list')
    extra_context = {'title': 'Yetkazib berish narxini kiritish'}


class ServiceUpdateView(UpdateView):
    model = Service
    form_class = ServiceForm
    template_name = "finance/form.html"
    success_url = reverse_lazy('delivery-fee-list')
    extra_context = {'title': 'Yetkazib berish narxini tahrirlash'}


# --- ORDER COMPLETION BONUS (TIER) SETTINGS ---
class OrderBonusTierListView(ListView):
    model = OrderBonusTier
    template_name = "finance/bonus_tier_list.html"
    context_object_name = "tiers"
    ordering = ["min_amount"]


class OrderBonusTierCreateView(CreateView):
    model = OrderBonusTier
    form_class = OrderBonusTierForm
    template_name = "finance/form.html"
    success_url = reverse_lazy('bonus-tier-list')
    extra_context = {'title': "Yangi bonus pog'onasi qo'shish"}


class OrderBonusTierUpdateView(UpdateView):
    model = OrderBonusTier
    form_class = OrderBonusTierForm
    template_name = "finance/form.html"
    success_url = reverse_lazy('bonus-tier-list')
    extra_context = {'title': "Bonus pog'onasini tahrirlash"}


class OrderBonusTierDeleteView(DeleteView):
    model = OrderBonusTier
    success_url = reverse_lazy('bonus-tier-list')


class OrderBonusHistoryListView(ListView):
    """Buyurtma yakunlanganda avtomatik berilgan bonuslar tarixi (admin uchun)."""
    model = LoyaltyPendingBonus
    template_name = "finance/bonus_history_list.html"
    context_object_name = "bonuses"
    paginate_by = 25

    def get_queryset(self):
        qs = LoyaltyPendingBonus.objects.select_related('profile', 'order').order_by('-created_at')
        query = self.request.GET.get('q', '')
        if query:
            qs = qs.filter(
                Q(profile__full_name__icontains=query) | Q(order_name__icontains=query)
            )
        return qs

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['query'] = self.request.GET.get('q', '')
        return context


def delete_order(request, pk):
    order = get_object_or_404(Order, pk=pk)
    # Qaysi sahifadan o'chirilayotganini bilish uchun
    page = request.POST.get('page', 1)

    if request.method == 'POST':
        order.delete()
        # O'chirib bo'lgandan keyin o'sha sahifaga qaytadi
        return redirect(f"{reverse('all-orders-list')}?page={page}")

    return redirect('all-orders-list')




def delete_user(request, pk):
    profile = get_object_or_404(Profile, id=pk)
    if request.method == "POST":
        # Foydalanuvchining o'zini (Django User) o'chirsa, Profile ham o'chib ketadi
        user = profile.user
        user.delete()
        messages.success(request, f"{profile.full_name} muvaffaqiyatli o'chirildi.")
        return redirect('users-list') # Ro'yxat sahifasiga qaytish
    return redirect('users-list')


def delete_b2b_application(request, pk):
    application = get_object_or_404(B2BApplication, pk=pk)
    if request.method == "POST":
        company_name = application.company_name
        application.delete()
        messages.success(request, f"{company_name} arizasi muvaffaqiyatli o'chirildi.")
    return redirect('b2b-applications-list') # Ro'yxat view nomi bilan bir xil bo'lishi kerak


# --- TELEGRAM SOZLAMALARI ---
def telegram_settings_view(request):
    settings_obj = TelegramSettings.get_solo()

    if request.method == 'POST':
        form = TelegramSettingsForm(request.POST, instance=settings_obj)
        if form.is_valid():
            form.save()
            from apps.dashboard.order_bot import refresh_bot_token
            refresh_bot_token()
            messages.success(request, "Telegram sozlamalari saqlandi.")
            return redirect('telegram-settings')
    else:
        form = TelegramSettingsForm(instance=settings_obj)

    return render(request, 'dashboard/settings/telegram.html', {
        'form': form,
        'settings_obj': settings_obj,
        'has_token': bool(settings_obj.bot_token),
    })


def app_update_settings_view(request):
    settings_obj = AppUpdateSettings.get_solo()

    if request.method == 'POST':
        form = AppUpdateSettingsForm(request.POST, instance=settings_obj)
        if form.is_valid():
            form.save()
            messages.success(request, "Ilova yangilanish sozlamalari saqlandi.")
            return redirect('app-update-settings')
    else:
        form = AppUpdateSettingsForm(instance=settings_obj)

    return render(request, 'dashboard/settings/app_update.html', {
        'form': form,
        'settings_obj': settings_obj,
    })


def telegram_test_action(request):
    if request.method != 'POST':
        return redirect('telegram-settings')

    settings_obj = TelegramSettings.get_solo()
    chat_ids = settings_obj.get_chat_id_list()

    if not settings_obj.bot_token:
        messages.error(request, "Avval Bot Token'ni saqlang.")
        return redirect('telegram-settings')

    if not chat_ids:
        messages.error(request, "Hech qanday Chat ID kiritilmagan.")
        return redirect('telegram-settings')

    from apps.dashboard.order_bot import send_test_message
    results = []
    for chat_id in chat_ids:
        ok, error = send_test_message(chat_id)
        results.append((chat_id, ok, error))

    ok_count = sum(1 for _, ok, _ in results if ok)
    fail_count = len(results) - ok_count

    if fail_count == 0:
        messages.success(request, f"Sinov xabari barcha {ok_count} ta chat ID'ga muvaffaqiyatli yuborildi.")
    else:
        failed_list = "; ".join(f"{cid}: {err}" for cid, ok, err in results if not ok)
        messages.warning(
            request,
            f"{ok_count} ta muvaffaqiyatli, {fail_count} ta xato. Xatolar: {failed_list}"
        )

    return redirect('telegram-settings')


def telegram_toggle_buttons_action(request):
    if request.method != 'POST':
        return redirect('telegram-settings')

    settings_obj = TelegramSettings.get_solo()

    if not settings_obj.buttons_enabled and not settings_obj.bot_token:
        messages.error(request, "Tugmalarni yoqishdan oldin avval Bot Token saqlanishi kerak.")
        return redirect('telegram-settings')

    settings_obj.buttons_enabled = not settings_obj.buttons_enabled
    settings_obj.save()
    state = "yoqildi" if settings_obj.buttons_enabled else "o'chirildi"
    messages.success(request, f"Admin botga tugmalar {state}.")
    return redirect('telegram-settings')


# --- PUSH XABARNOMA YOZISH (broadcast, News modelidan mustaqil) ---
def push_compose_view(request):
    """Bir martalik broadcast push yozish.

    ESLATMA: yuborilgan xabar endi News (Notification) sifatida ham
    bazaga SAQLANADI (active=True) - shu bilan birga mobil ilovaning
    /api/customer/notifications/list/ ro'yxatida ham ko'rinadi, va
    "Push yuborish" tugmasi bilan bir xil send-payload logikasi
    ishlatiladi (apps/dashboard/main.py: send_push_for_news).
    """
    from datetime import timedelta
    from django.utils import timezone
    from apps.dashboard.main import send_push_for_news, report_push_result

    if request.method == 'POST':
        form = PushComposeForm(request.POST, request.FILES)
        if form.is_valid():
            now = timezone.now()
            news = News.objects.create(
                title=form.cleaned_data['title'],
                description=form.cleaned_data['body'],
                image=form.cleaned_data.get('image') or None,
                link=form.cleaned_data.get('link') or "",
                type=form.cleaned_data.get('type') or News.TYPE_GENERAL,
                priority=form.cleaned_data.get('priority') or 0,
                active=True,
                start_date=now,
                end_date=now + timedelta(days=30),
            )
            result = send_push_for_news(request, news)
            report_push_result(request, result)
            return redirect('push-compose')
    else:
        form = PushComposeForm()

    return render(request, 'dashboard/settings/push_compose.html', {'form': form})