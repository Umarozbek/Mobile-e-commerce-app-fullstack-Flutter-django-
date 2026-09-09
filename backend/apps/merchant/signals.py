from datetime import timedelta

from django.db.models import F
from django.db.models.signals import m2m_changed, post_save
from django.dispatch import receiver
from django.utils import timezone

from .models import Order, OrderItem, LoyaltyCard, LoyaltyPendingBonus
from ..customer.models import Profile


@receiver(m2m_changed, sender=Order.products.through)
def update_order_total(sender, instance, action, **kwargs):
    if action in ["post_add", "post_remove", "post_clear"]:
        instance.update_total_amount()
        





# ESLATMA: "approved"/"check_pending"/"sent" bo'lganda bonus yaratish endi
# Order.save() metodi ICHIDA ("4️⃣ Bonus yaratish" qismi, models.py) amalga
# oshiriladi - total_amount yangilangandan KEYIN. Bu yerda (post_save signalida)
# emas, chunki bu signal super().save() ICHIDA - ya'ni total_amount hali
# qayta hisoblanmasdan OLDIN - chaqiriladi va noto'g'ri (eski/nol) summa bilan
# ishlagan bo'lardi. Signal shu sababli olib tashlandi (Order.save() yetarli).


@receiver(post_save, sender=Profile)
def create_loyalty_card(sender, instance, created, **kwargs):
    """
    Автоматически создаёт LoyaltyCard
    при создании Profile
    """
    if not created:
        return

    today = timezone.now().date()

    LoyaltyCard.objects.create(
        profile=instance,
        cycle_start=today,
        cycle_end=today + timedelta(days=60),
        cycle_number=1
    )

@receiver(post_save, sender=LoyaltyPendingBonus)
def update_loyalty_card_balance(sender, instance, created, **kwargs):

    # Условия начисления
    if instance.status == "approved" and instance.bonus_amount > 0:
        today = timezone.now().date()
        card, _ = LoyaltyCard.objects.get_or_create(
            profile=instance.profile,
            defaults={
                "cycle_start": today,
                "cycle_end": today + timedelta(days=60),
                "current_balance": 0,
            },
        )

        card.current_balance = F("current_balance") + instance.bonus_amount
        card.save(update_fields=["current_balance"])


