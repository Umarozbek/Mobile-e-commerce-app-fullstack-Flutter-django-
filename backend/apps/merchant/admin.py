from django import forms
from django.contrib import admin
from .models import *


class InformationAdmin(admin.ModelAdmin):
    list_display = [
        "reminder",
        "agreement",
        "shipment_terms",
        "privacy_policy",
        "about_us",
        "support_center",
        "payment_data",
    ]


class ServiceAdmin(admin.ModelAdmin):
    list_display = ["id", "delivery_fee"]
admin.site.register(Service, ServiceAdmin)


@admin.register(ShippingSettings)
class ShippingSettingsAdmin(admin.ModelAdmin):
    list_display = ('base_fee',)

    def has_add_permission(self, request):
        return not ShippingSettings.objects.exists()

    def has_delete_permission(self, request, obj=None):
        return False


class SocialMediaAdmin(admin.ModelAdmin):
    list_display = ["telegram", "instagram", "whatsapp", "phone_number", "imo", "kakao"]
admin.site.register(SocialMedia, SocialMediaAdmin)


admin.site.register(Information, InformationAdmin)
class BonusaAdmin(admin.ModelAdmin):
    list_display = ["amount", "percentage", "title", "created", "modified", 'active']
admin.site.register(Bonus, BonusaAdmin)

admin.site.register(OrderItem)


class OrderItemInline(admin.TabularInline):
    model = OrderItem
    extra = 1  # Agar siz yangi Order yaratayotganda bitta bo'sh OrderItem qo'shmoqchi bo'lsangiz


class OrderAdmin(admin.ModelAdmin):
    inlines = [OrderItemInline]
    list_display = ("user", "status", "total_amount", "loyalty_payment", "created_at")
    search_fields = ("user__full_name", "status")
    list_filter = ("status",)

admin.site.register(Order, OrderAdmin)


@admin.register(LoyaltyCard)
class LoyaltyCardModelAdmin(admin.ModelAdmin):
    list_display = ['profile','current_balance','cycle_start','cycle_end','cycle_days','cycle_number','created_at','updated_at']
    search_fields = ['profile__phone_number', 'profile__full_name']

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        # Hamma kartalarni bittadan tekshirib chiqadi
        for card in qs:
            card.check_and_reset()
        return qs


@admin.register(OrderBonusTier)
class OrderBonusTierAdmin(admin.ModelAdmin):
    list_display = ('min_amount', 'max_amount', 'bonus_amount', 'active', 'created_at')
    list_editable = ('bonus_amount', 'active')
    ordering = ('min_amount',)


@admin.register(LoyaltyPendingBonus)
class LoyaltyPendingBonusAdmin(admin.ModelAdmin):
    list_display = [
        "order_name",
        "profile",
        "order_amount",
        "percent",
        "bonus_amount",
        "status",
        "created_at",
    ]

    list_editable = ["percent", "status"]

    readonly_fields = [
        "order",
        "order_name",
        "order_amount",
        "bonus_amount",
        "profile",
    ]


class TelegramSettingsAdminForm(forms.ModelForm):
    """Django admin'da ham bot_token hech qachon ochiq ko'rsatilmaydi."""
    bot_token = forms.CharField(required=False, widget=forms.PasswordInput(render_value=False))

    class Meta:
        model = TelegramSettings
        fields = "__all__"

    def save(self, commit=True):
        instance = super().save(commit=False)
        if not self.cleaned_data.get('bot_token'):
            instance.bot_token = TelegramSettings.get_solo().bot_token
        if commit:
            instance.save()
        return instance


@admin.register(TelegramSettings)
class TelegramSettingsAdmin(admin.ModelAdmin):
    form = TelegramSettingsAdminForm
    list_display = ('buttons_enabled',)

    def has_add_permission(self, request):
        return not TelegramSettings.objects.exists()

    def has_delete_permission(self, request, obj=None):
        return False


@admin.register(ReferralSettings)
class ReferralSettingsAdmin(admin.ModelAdmin):
    list_display = ('referral_system_active', 'bonus_amount')

    def has_add_permission(self, request):
        return not ReferralSettings.objects.exists()

    def has_delete_permission(self, request, obj=None):
        return False


@admin.register(Referral)
class ReferralAdmin(admin.ModelAdmin):
    list_display = ('referrer', 'referee', 'status', 'created_at')
    list_filter = ('status',)
    actions = ['approve_referral_bonus']

    def approve_referral_bonus(self, request, queryset):
        for ref in queryset:
            if ref.status == 'pending':
                ref.status = 'rewarded'  # Меняем статус
                ref.save()  # Это само вызовет нашу логику из метода save()



# WalletTransaction admin removed - model no longer exists


admin.site.register(BankCardModel)