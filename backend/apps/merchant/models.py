import math
import random
import time
from datetime import timedelta, date

from django.core.exceptions import ValidationError
from django.db import models, transaction
from django.utils import timezone
from model_utils.models import TimeStampedModel
from django.db.models import F
from ckeditor.fields import RichTextField
from rest_framework.response import Response
from rest_framework import status
from decimal import Decimal
from django.db.models import F, fields, ExpressionWrapper

from apps.customer.models import Profile, Location
from apps.product.models import ProductItem


class BankCardModel(models.Model):
    title = models.BigIntegerField(default=0, null=True, blank=True)
    card_holder = models.CharField(max_length=100, null=True, blank=True)

    def __str__(self) -> str:
        return str(self.title)

    class Meta:
        verbose_name = 'BankCardModel'
        verbose_name_plural = 'BankCardModels'


class Service(TimeStampedModel, models.Model):
    delivery_fee = models.DecimalField(max_digits=10, decimal_places=0, default=0)

    def __str__(self) -> str:
        return f"{self.id}-service - {self.delivery_fee}"


class ShippingSettings(models.Model):
    """Singleton: og'irlikka asoslangan yetkazib berish narxi sozlamalari.

    20 kg qadam BIZNES QOIDASI sifatida FIKS (o'zgarmas) - admin uni
    o'zgartira olmaydi. Faqat bitta 20 kg pochta birligi narxi sozlanadi.

    shipping_fee = ceil(total_weight / 20) * base_fee
    """
    WEIGHT_STEP_KG = Decimal("20")

    base_fee = models.DecimalField(
        max_digits=10, decimal_places=0, default=5000,
        help_text="Har bir 20 kg pochta birligi uchun narx (KRW)"
    )

    def __str__(self) -> str:
        return f"ShippingSettings (20kg = {self.base_fee})"

    @classmethod
    def get_solo(cls):
        obj, _ = cls.objects.get_or_create(pk=1)
        return obj


def generate_order_number():
    # 10000 dan 99999 gacha bo'lgan 5 ta tasodifiy sonni oladi
    number = random.randint(10000, 99999)
    return f"ORD{number}"


def get_default_service():
    service = Service.objects.first()  # birinchi mavjud service row ni olamiz
    if service:
        return service.id
    # agar mavjud bo'lmasa, yangi service yaratamiz
    service = Service.objects.create(delivery_fee=0)
    return service.id


class Order(models.Model):
    order_number = models.CharField(max_length=10, unique=True, default=generate_order_number, editable=False)
    STATUS_CHOICES = (
        ("in_cart", "Savatchada"),
        ("pending", "Admin tasdig'i kutilmoqda"),
        ("payment_pending", "To'lov kutilmoqda"),
        ("approved", "Tasdiqlandi"),
        ("cancelled", "Bekor qilindi"),
        ("Sent", "Yetkazildi"),
    )

    user = models.ForeignKey(Profile, on_delete=models.CASCADE, related_name="order")
    products = models.ManyToManyField(ProductItem, through="OrderItem", related_name="order")
    comment = models.TextField(blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="in_cart")
    location = models.ForeignKey(Location, on_delete=models.SET_NULL, null=True)
    total_amount = models.DecimalField(decimal_places=0, max_digits=20, default=0)
    created_at = models.DateTimeField(auto_now_add=True, null=True)

    # Yetkazib berish xizmati (ForeignKey).
    # E'TIBOR: default=get_default_service OLIB TASHLANDI. Avval bu default
    # HAR safar Order() obyekt yaratilganda (hatto "in_cart" bo'lsa ham)
    # darhol delivery_fee'ni to'ldirib qo'yardi, shu sababli pastdagi
    # "hali belgilanmagan" tekshiruvi hech qachon ishlamas edi va og'irlikka
    # asoslangan hisob-kitob umuman chaqirilmasdi. Endi delivery_fee faqat
    # savatdan chiqishda (pastdagi save() ichida) hisoblanadi.
    delivery_fee = models.ForeignKey(Service, on_delete=models.SET_NULL, null=True, blank=True,
                                     related_name='order_delivere_fee')

    bonus_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    payment_receipt = models.ImageField(upload_to='receipts/', null=True, blank=True)
    loyalty_payment = models.IntegerField(default=0, null=True, blank=True)
    bankcard = models.ForeignKey(BankCardModel, on_delete=models.CASCADE, null=True, blank=True,
                                 related_name='bank_card')

    # ---------------- SAVE METHOD (ASOSIY MANTIQ) ----------------
    def save(self, *args, **kwargs):
        old_status = None
        if self.pk:
            # Eskisining statusini bazadan olish
            old_status = Order.objects.get(pk=self.pk).status

        # A) Avtomatik biriktirishlar
        if self.status != "in_cart":
            if not self.bankcard:
                first_card = BankCardModel.objects.first()
                if first_card:
                    self.bankcard = first_card
            # Yetkazib berish narxi endi pastda (super().save() dan keyin,
            # orderitem'lar mavjud bo'lganda) og'irlik asosida hisoblanadi.

        # --- B) LOYALTY PULDAN YECHISH (Siz bergan kod) ---
        if old_status == "in_cart" and self.status == "pending":
            if self.loyalty_payment and self.loyalty_payment > 0:
                try:
                    card = self.user.loyalty_card
                    payment_decimal = Decimal(str(self.loyalty_payment))
                    if card.current_balance >= payment_decimal:
                        with transaction.atomic():
                            card.current_balance -= payment_decimal
                            card.save()
                            print(f"PUL YECHILDI: {payment_decimal}")
                except Exception as e:
                    print(f"Yechishda xato: {e}")

        # --- C) PULNI QAYTARISH (Siz bergan kod) ---
        if old_status and old_status != "cancelled" and self.status == "cancelled":
            if self.loyalty_payment and self.loyalty_payment > 0:
                try:
                    card = self.user.loyalty_card
                    refund_decimal = Decimal(str(self.loyalty_payment))
                    with transaction.atomic():
                        card.current_balance += refund_decimal
                        card.save()
                        print(f"PUL QAYTARILDI: {refund_decimal}")
                except Exception as e:
                    print(f"Qaytarishda xato: {e}")

        # 1️⃣ Orderni asosiy saqlash (Hamma statuslar uchun ishlashi shart)
        super().save(*args, **kwargs)

        # 1.5️⃣ YETKAZIB BERISH NARXINI OG'IRLIK ASOSIDA HISOBLASH
        # Faqat savatdan chiqqanda va hali narx belgilanmagan bo'lsa (finalized
        # buyurtmalarning tarixiy narxi o'zgarmasligi uchun shart muhim).
        if self.status != "in_cart" and not self.delivery_fee_id:
            computed_fee = self.calculate_shipping_fee()
            service, _ = Service.objects.get_or_create(delivery_fee=computed_fee)
            self.delivery_fee = service
            Order.objects.filter(pk=self.pk).update(delivery_fee=service)

        # 2️⃣ JAMI SUMMANI HISOBLASH (O'zgarishsiz)
        total = Decimal(0)
        items = self.orderitem.all()
        for item in items:
            if item.product:
                price = item.product.new_price if item.product.new_price > 0 else item.product.old_price
                total += price * item.quantity

        # Yetkazib berish narxini qo'shish
        if self.delivery_fee:
            total += self.delivery_fee.delivery_fee

        # Bazadagi total_amountni yangilaymiz
        if self.total_amount != total:
            self.total_amount = total
            Order.objects.filter(pk=self.pk).update(total_amount=total)

        # 4️⃣ Bonus yaratish - buyurtma "yakunlangan" statuslardan biriga birinchi
        # marta o'tganda (approved / check_pending / sent). Bu yerda - total_amount
        # allaqachon yuqorida (2️⃣) yangilangandan KEYIN - chunki Order post_save
        # signali (super().save() ichida, hali 2️⃣ ishlamasdan oldin) hali eski/nol
        # total_amount bilan chaqiriladi va noto'g'ri natija berardi.
        COMPLETION_STATUSES = ("approved", "check_pending", "sent")
        if self.status in COMPLETION_STATUSES and old_status not in COMPLETION_STATUSES:
            self.create_loyalty_pending_bonus()

    def calculate_shipping_fee(self):
        """Jami paket og'irligi asosida yetkazib berish narxini hisoblaydi.

        shipping_fee = ceil(total_weight / 20) * base_fee
        20 kg qadam FIKS biznes qoidasi (admin o'zgartira olmaydi).
        Og'irligi noma'lum (null) mahsulotlar 0 sifatida hisoblanadi (o'ylab
        topilmaydi), 0 kg bo'lsa narx ham 0 bo'ladi.
        """
        settings_obj = ShippingSettings.get_solo()
        total_weight = Decimal("0")
        for item in self.orderitem.all():
            if item.product and item.product.weight:
                total_weight += Decimal(str(item.product.weight)) * item.quantity

        if total_weight <= 0:
            return Decimal("0")

        steps = math.ceil(total_weight / ShippingSettings.WEIGHT_STEP_KG)
        return Decimal(steps) * settings_obj.base_fee

    # ---------------- BOSHQA METODLAR ----------------
    def update_total_amount(self):
        """Bu metodni ham yangilab qo'yamiz (delivery_fee bilan)"""
        total = Decimal(0)
        for item in self.orderitem.all():
            if item.product:
                price = item.product.new_price if item.product.new_price > 0 else item.product.old_price
                total += price * item.quantity

        if self.delivery_fee:
            total += self.delivery_fee.delivery_fee

        self.total_amount = total
        self.save(update_fields=['total_amount'])

    def get_status_display_value(self):
        return dict(self.STATUS_CHOICES).get(self.status, "Noma'lum")

    def create_loyalty_pending_bonus(self):
        """Buyurtma yakunlanganda (status='approved'/'check_pending' - signals.py
        orqali, yoki 'sent' - pastdagi save() orqali) chaqiriladi.

        OneToOneField(order) + shu yerdagi mavjudlik tekshiruvi - buyurtma
        necha marta saqlansa ham, va qaysi "yakunlangan" status birinchi
        bo'lib kelsa ham (approved/check_pending/sent), bonus FAQAT BIR
        MARTA berilishini ta'minlaydi: qaysi status birinchi kelsa, shu
        LoyaltyPendingBonus yozuvini yaratadi, qolganlari mavjudlik
        tekshiruvida to'xtaydi.

        Mos keluvchi FAOL OrderBonusTier topilsa - LoyaltyPendingBonus
        status='approved' bilan yaratiladi. Balansga qo'shish ISHI
        signals.py dagi update_loyalty_card_balance signaliga tegishli
        (bitta joyda - takror hisoblanmasligi uchun). Hech qanday pog'ona
        mos kelmasa (bo'sh joy yoki sozlama yo'q) - bonus berilmaydi,
        hech narsa o'ylab topilmaydi.
        """
        if LoyaltyPendingBonus.objects.filter(order=self).exists():
            return
        total = self.total_amount
        if total <= 0:
            return

        tier = OrderBonusTier.find_tier(total)
        if tier is None:
            return

        LoyaltyPendingBonus.objects.create(
            profile=self.user,
            order=self,
            order_name=f"Order #{self.order_number}",
            order_amount=total,
            bonus_amount=tier.bonus_amount,
            status="approved",
        )


class OrderItem(TimeStampedModel, models.Model):
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name="orderitem")
    product = models.ForeignKey(
        "product.ProductItem",
        on_delete=models.CASCADE,
        related_name="orderitem",
        null=True,
    )
    quantity = models.IntegerField(default=0)


class Information(TimeStampedModel, models.Model):
    reminder = RichTextField(blank=True, null=True)
    agreement = RichTextField(blank=True, null=True)
    shipment_terms = RichTextField(blank=True, null=True)
    privacy_policy = RichTextField(blank=True, null=True)
    about_us = RichTextField(blank=True, null=True)
    support_center = RichTextField(blank=True, null=True)
    payment_data = RichTextField(blank=True, null=True)

    def __str__(self) -> str:
        return str(self.created)


class SocialMedia(TimeStampedModel, models.Model):
    telegram = models.CharField(max_length=255, blank=True, null=True)
    instagram = models.CharField(max_length=255, blank=True, null=True)
    whatsapp = models.CharField(max_length=255, blank=True, null=True)
    phone_number = models.CharField(max_length=255, blank=True, null=True)
    imo = models.CharField(max_length=255, blank=True, null=True)
    kakao = models.CharField(max_length=255, blank=True, null=True)
    tiktok = models.CharField(max_length=255, blank=True, null=True)

    def __str__(self) -> str:
        return "SocialMedias"


class Bonus(TimeStampedModel, models.Model):
    title = models.CharField(max_length=255, blank=True)
    amount = models.DecimalField(default=0, decimal_places=0, max_digits=10)
    percentage = models.PositiveIntegerField(default=0)
    active = models.BooleanField(default=False)

    def __str__(self) -> str:
        return self.title if len(self.title) > 0 else str(self.amount)


class LoyaltyCard(models.Model):
    profile = models.OneToOneField(
        Profile,
        on_delete=models.CASCADE,
        related_name='loyalty_card'
    )
    current_balance = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=0
    )
    cycle_start = models.DateField()
    cycle_end = models.DateField()
    cycle_days = models.PositiveIntegerField(default=60)
    cycle_number = models.PositiveIntegerField(default=1)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def check_and_reset(self):
        """
        Karta muddatini tekshiradi. Agar 60 kun o'tgan bo'lsa,
        avtomatik balansni nol qilib, yangi siklni boshlaydi.
        """
        today = timezone.now().date()

        # Agar bugungi sana cycle_end dan o'tib ketgan bo'lsa
        if today >= self.cycle_end:
            # Nechta 60 kunlik muddat o'tib ketganini hisoblaymiz
            # (Masalan, user 150 kun kirmagan bo'lsa, bu bir necha siklni o'zgartiradi)
            while today >= self.cycle_end:
                self.cycle_start = self.cycle_end
                self.cycle_end = self.cycle_start + timedelta(days=self.cycle_days)
                self.cycle_number += 1

            # Muddat o'tdimi - balans o'chadi
            self.current_balance = Decimal('0.00')
            self.save()
            return True
        return False

    def __str__(self):
        return f"LoyaltyCard({self.profile})"


class OrderBonusTier(models.Model):
    """Admin tomonidan sozlanadigan buyurtma-yakunlash bonus pog'onalari.

    Har bir qator bitta oraliqni bildiradi: [min_amount, max_amount].
    max_amount = NULL bo'lsa, yuqori chegara yo'q (masalan "300 001 va undan yuqori").
    Faqat active=True qatorlar hisobga olinadi. Bo'sh joy (gap) yoki mos
    keluvchi pog'ona topilmasa - bonus berilmaydi (o'ylab topilmaydi).
    """
    min_amount = models.DecimalField(max_digits=12, decimal_places=0)
    max_amount = models.DecimalField(max_digits=12, decimal_places=0, null=True, blank=True,
                                     help_text="Bo'sh qoldirsangiz - yuqori chegara yo'q")
    bonus_amount = models.DecimalField(max_digits=12, decimal_places=0)
    active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["min_amount"]

    def __str__(self) -> str:
        upper = self.max_amount if self.max_amount is not None else "∞"
        return f"{self.min_amount} - {upper} → {self.bonus_amount}"

    @classmethod
    def find_tier(cls, order_amount):
        """order_amount uchun mos keluvchi FAOL pog'onani qaytaradi, topilmasa None."""
        order_amount = Decimal(order_amount)
        qs = cls.objects.filter(active=True, min_amount__lte=order_amount)
        qs = qs.filter(models.Q(max_amount__isnull=True) | models.Q(max_amount__gte=order_amount))
        return qs.order_by("min_amount").first()


class LoyaltyPendingBonus(models.Model):
    STATUS_CHOICES = (
        ("pending", "Pending"),
        ("approved", "Approved"),
    )

    profile = models.ForeignKey(
        "customer.Profile",
        on_delete=models.CASCADE
    )
    order = models.OneToOneField(
        "merchant.Order",
        on_delete=models.CASCADE,
        related_name="pending_bonus"
    )

    order_name = models.CharField(max_length=255)
    order_amount = models.DecimalField(max_digits=20, decimal_places=0)

    percent = models.PositiveIntegerField(null=True, blank=True)
    bonus_amount = models.DecimalField(
        max_digits=20,
        decimal_places=0,
        default=0
    )

    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default="pending"
    )

    created_at = models.DateTimeField(auto_now_add=True)

    def save(self, *args, **kwargs):
        """
        Автоматический расчёт bonus_amount:
        - только если статус approved
        - только если percent указан
        """
        if self.status == "approved" and self.percent:
            # Приводим к Decimal для точного вычисления
            self.bonus_amount = Decimal(self.order_amount) * Decimal(self.percent) / Decimal(100)
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.order_name} | {self.order_amount}"


class TelegramSettings(models.Model):
    """Singleton: buyurtma xabarnomalari yuboriladigan Telegram sozlamalari.

    bot_token HECH QACHON dashboard/API javoblarida to'liq ko'rsatilmaydi -
    kiritish maydoni doim bo'sh chiqadi. Forma bo'sh saqlansa, eski qiymat
    o'zgarmaydi (admin faqat chat_ids yoki buttons_enabled'ni yangilamoqchi
    bo'lishi mumkin, tokenni qayta kiritmasdan).
    """
    bot_token = models.CharField(max_length=255, blank=True, default="")
    chat_ids = models.TextField(
        blank=True, default="",
        help_text="Har bir qatorda bitta chat ID (yoki kanal @username)"
    )
    buttons_enabled = models.BooleanField(default=False)

    def __str__(self) -> str:
        return f"TelegramSettings (buttons_enabled={self.buttons_enabled})"

    @classmethod
    def get_solo(cls):
        obj, _ = cls.objects.get_or_create(pk=1)
        return obj

    def get_chat_id_list(self):
        return [line.strip() for line in (self.chat_ids or "").splitlines() if line.strip()]


class ReferralSettings(models.Model):
    """Singleton: referral tizimi uchun global sozlamalar."""
    referral_system_active = models.BooleanField(default=False)
    bonus_amount = models.DecimalField(max_digits=10, decimal_places=0, default=500)

    def __str__(self) -> str:
        return f"ReferralSettings (active={self.referral_system_active}, bonus={self.bonus_amount})"

    @classmethod
    def get_solo(cls):
        obj, _ = cls.objects.get_or_create(pk=1)
        return obj


class Referral(models.Model):
    STATUS_CHOICES = (
        ('pending', 'Pending'),
        ('rewarded', 'Rewarded'),
        ('expired', 'Expired'),
    )

    referrer = models.ForeignKey(
        'customer.Profile',  # <--- ИСПРАВЬ ЗДЕСЬ (добавь customer.)
        on_delete=models.CASCADE,
        related_name='referrals_made'
    )
    referee = models.ForeignKey(
        'customer.Profile',  # <--- ИСПРАВЬ ЗДЕСЬ (добавь customer.)
        on_delete=models.CASCADE,
        related_name='referrals_received'
    )
    status = models.CharField(
        max_length=10,
        choices=STATUS_CHOICES,
        default='pending'
    )
    created_at = models.DateTimeField(auto_now_add=True)

    def save(self, *args, **kwargs):
        # Логика автоматического начисления при создании
        if not self.pk and self.status == 'rewarded':
            super().save(*args, **kwargs)
            self.make_rewarded_logic()
            return

        # Логика при обновлении статуса
        if self.pk:
            old_status = Referral.objects.get(pk=self.pk).status
            if old_status == 'pending' and self.status == 'rewarded':
                self.make_rewarded_logic()

        super().save(*args, **kwargs)

    def make_rewarded_logic(self):
        from .models import LoyaltyCard
        bonus_amount = ReferralSettings.get_solo().bonus_amount
        with transaction.atomic():
            card, created = LoyaltyCard.objects.get_or_create(
                profile=self.referrer,
                defaults={
                    'cycle_start': date.today(),
                    'cycle_end': date.today() + timedelta(days=60),
                    'current_balance': 0
                }
            )
            card.current_balance = F('current_balance') + bonus_amount
            card.save()

    class Meta:
        unique_together = ('referrer', 'referee')

    def __str__(self):
        return f"{self.referrer.full_name} -> {self.referee.full_name}"

# WalletTransaction model removed - history is now fetched directly from Order, LoyaltyPendingBonus, and Referral models
