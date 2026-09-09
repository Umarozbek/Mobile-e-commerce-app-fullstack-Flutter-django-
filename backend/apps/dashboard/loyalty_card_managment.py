from decimal import Decimal

from django.core.paginator import Paginator
from django.db import transaction
from django.db.models import Q
from django.shortcuts import render, get_object_or_404, redirect
from django.contrib import messages
from django.urls import reverse
from django.utils.http import urlencode

from apps.customer.models import Profile
from apps.merchant.models import LoyaltyPendingBonus, Referral, LoyaltyCard, ReferralSettings
from datetime import date, timedelta


def loyalty_customer_list(request):
    # 1. Qidiruv so'rovini olish
    query = request.GET.get('q', '')

    # 2. Querysetni boshlash
    profiles = Profile.objects.select_related('loyalty_card').all()

    # 3. Agar qidiruv so'rovi bo'lsa
    if query:
        profiles = profiles.filter(
            Q(full_name__icontains=query) |  # To'g'ridan-to'g'ri Profile ichidagi maydon
            Q(phone_number__icontains=query)  # To'g'ridan-to'g'ri Profile ichidagi maydon
        ).distinct()

    context = {
        'profiles': profiles,
        'query': query  # Qidiruv maydonida so'z qolishi uchun
    }

    return render(request, 'loyalty_card/customer-list.html', context)


def loyalty_customer_detail(request, profile_id):
    profile = get_object_or_404(Profile, id=profile_id)

    loyalty_card = getattr(profile, 'loyalty_card', None)
    pending_bonuses = LoyaltyPendingBonus.objects.filter(profile=profile).order_by('-created_at')
    referrals = Referral.objects.filter(referrer=profile).order_by('-created_at')

    context = {
        'profile': profile,
        'loyalty_card': loyalty_card,
        'pending_bonuses': pending_bonuses,
        'referrals': referrals,
    }
    # DIQQAT: Rasmingizda fayl nomi 'customers.html' edi, shuni to'g'irladim:
    return render(request, 'loyalty_card/customers.html', context)


def loyalty_user_detail_view(request, profile_id):
    # 1. Profilni olish
    profile = get_object_or_404(Profile, id=profile_id)

    # 2. Loyalty Card ma'lumotlarini olish (OneToOne bo'lgani uchun getattr ishlatamiz)
    loyalty_card = getattr(profile, 'loyalty_card', None)

    # 3. Kutilayotgan bonuslar (Hamma buyurtmalar bo'yicha)
    pending_bonuses = LoyaltyPendingBonus.objects.filter(profile=profile).order_by('-created_at')

    # 4. Referallar (Bu foydalanuvchi taklif qilgan odamlar)
    referrals = Referral.objects.filter(referrer=profile).order_by('-created_at')

    # 5. Statistika hisoblash (Shablon uchun qo'shimcha)
    total_spent_on_bonuses = sum(b.order_amount for b in pending_bonuses)
    bonuses_count = pending_bonuses.count()

    context = {
        'profile': profile,
        'loyalty_card': loyalty_card,
        'pending_bonuses': pending_bonuses,
        'referrals': referrals,
        'total_spent': total_spent_on_bonuses,
        'bonuses_count': bonuses_count,
    }

    return render(request, 'loyalty_card/customers.html', context)


def edit_loyalty_card(request, profile_id):
    profile = get_object_or_404(Profile, id=profile_id)
    # Karta borligini tekshiramiz, bo'lmasa None qaytadi
    card = getattr(profile, 'loyalty_card', None)

    if request.method == "POST":
        balance = request.POST.get('balance')
        cycle_start = request.POST.get('cycle_start')
        cycle_end = request.POST.get('cycle_end')
        cycle_number = request.POST.get('cycle_number')
        cycle_days = request.POST.get('cycle_days')

        if card:
            # Mavjud kartani yangilash
            card.current_balance = balance
            card.cycle_start = cycle_start
            card.cycle_end = cycle_end
            card.cycle_number = cycle_number
            card.cycle_days = cycle_days
            card.save()
            messages.success(request, "Loyallik kartasi muvaffaqiyatli yangilandi!")
        else:
            # Agar karta hali yo'q bo'lsa, yangi yaratish (ixtiyoriy, lekin foydali)
            from apps.merchant.models import LoyaltyCard
            LoyaltyCard.objects.create(
                profile=profile,
                current_balance=balance,
                cycle_start=cycle_start,
                cycle_end=cycle_end,
                cycle_number=cycle_number,
                cycle_days=cycle_days
            )
            messages.success(request, "Yangi loyallik kartasi yaratildi!")

        # MANA BU YERDA XATO EDI: 'loyalty_card/loyalty_edit.html' o'rniga name yozamiz
        return redirect('loyalty_customer_detail', profile_id=profile.id)

    return render(request, 'loyalty_card/loyalty_edit.html', {'profile': profile, 'card': card})


def all_pending_bonuses(request):
    query = request.GET.get('q', '').strip()
    status = request.GET.get('status', '')
    start_date = request.GET.get('start_date', '')
    end_date = request.GET.get('end_date', '')
    page_number = request.GET.get('page', 1) # Sahifa raqami

    bonuses_list = LoyaltyPendingBonus.objects.all().select_related('profile').order_by('-id')

    if query:
        bonuses_list = bonuses_list.filter(Q(profile__full_name__icontains=query) | Q(order_name__icontains=query))
    if status:
        bonuses_list = bonuses_list.filter(status=status)
    if start_date:
        bonuses_list = bonuses_list.filter(created_at__date__gte=start_date)
    if end_date:
        bonuses_list = bonuses_list.filter(created_at__date__lte=end_date)

    # PAGINATSIYA: Har bir sahifada 15 tadan chiqaradi
    paginator = Paginator(bonuses_list, 20)
    page_obj = paginator.get_page(page_number)

    return render(request, 'loyalty_card/pending_all.html', {
        'bonuses': page_obj, # Endi queryset emas, sahifa obyekti
        'page_obj': page_obj,
        'query': query,
        'current_status': status,
        'start_date': start_date,
        'end_date': end_date
    })


def approve_bonus(request, bonus_id):
    if request.method == "POST":
        bonus = get_object_or_404(LoyaltyPendingBonus, id=bonus_id, status='pending')
        percent_from_input = request.POST.get('percent')

        if percent_from_input:
            bonus.percent = int(percent_from_input)

        if not bonus.percent or bonus.percent <= 0:
            bonus.percent = 10

        with transaction.atomic():
            order_sum = Decimal(str(bonus.order_amount))
            perc_val = Decimal(str(bonus.percent))
            bonus.bonus_amount = (order_sum * perc_val) / Decimal('100')

            # E'TIBOR: LoyaltyCard balansiga qo'shish ISHI shu yerda QILINMAYDI.
            # bonus.status='approved' bilan saqlanganda, signals.py dagi
            # update_loyalty_card_balance signali AVTOMATIK balansni oshiradi.
            # Ilgari bu yerda HAM qo'lda qo'shilardi, HAM signal ishlardi -
            # bu mijozga bonusni IKKI MARTA berardi (topilgan xato, tuzatildi).
            bonus.status = 'approved'
            bonus.save()

        # --- FILTRLARNI URL'DA SAQLAB QOLISH QISMI ---
        q = request.POST.get('q', '')
        status_f = request.POST.get('status_filter', '')
        s_date = request.POST.get('start_date', '')
        e_date = request.POST.get('end_date', '')
        page = request.POST.get('page', 1)

        params = {}
        if q: params['q'] = q
        if status_f: params['status'] = status_f
        if s_date: params['start_date'] = s_date
        if e_date: params['end_date'] = e_date
        if page: params['page'] = page

        query_string = urlencode(params)
        return redirect(f"{reverse('all_pending_bonuses')}?{query_string}")

    return redirect('all_pending_bonuses')


# 2. Barcha referallar ro'yxati (Search bilan)
def all_referrals(request):
    query = request.GET.get('q', '')
    referrals = Referral.objects.all().select_related('referrer', 'referee')

    if query:
        # Ham taklif qilgan, ham kelgan mijoz ismida qidiradi
        referrals = referrals.filter(
            Q(referrer__full_name__icontains=query) |
            Q(referee__full_name__icontains=query)
        )

    settings_obj = ReferralSettings.get_solo()

    return render(request, 'loyalty_card/all_referrals.html', {
        'referrals': referrals,
        'query': query,
        'referral_settings': settings_obj,
    })


# 3. Referral tizimini yoqish/o'chirish va bonus summasini o'rnatish
def toggle_referral_system(request):
    settings_obj = ReferralSettings.get_solo()

    if request.method == 'POST':
        bonus_amount = request.POST.get('bonus_amount')
        if bonus_amount:
            try:
                settings_obj.bonus_amount = Decimal(bonus_amount)
            except Exception:
                messages.error(request, "Bonus summasi noto'g'ri kiritildi.")
                return redirect('referral_list')

        if 'toggle_active' in request.POST:
            settings_obj.referral_system_active = not settings_obj.referral_system_active

        settings_obj.save()
        messages.success(request, "Referral tizimi sozlamalari yangilandi.")

    return redirect('referral_list')
