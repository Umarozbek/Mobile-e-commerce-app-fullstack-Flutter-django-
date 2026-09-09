"""
Local-only demo data seeder. Populates the local SQLite dev database with
fake categories/products/customers/orders so the admin dashboard shows
non-trivial numbers. Not intended for production use.

Run with: python seed_local_demo.py
"""
import os
import random
from datetime import date, timedelta
from decimal import Decimal

import django

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
django.setup()

from django.utils import timezone

from apps.product.models import Category, ProductItem, Good
from apps.customer.models import User, Profile, Location
from apps.merchant.models import Order, OrderItem, Service, LoyaltyCard

random.seed(42)

print("Clearing existing demo data...")
Order.objects.all().delete()
Good.objects.all().delete()
ProductItem.objects.all().delete()
Category.objects.all().delete()
Profile.objects.all().delete()
User.objects.filter(is_superuser=False).delete()

print("Creating delivery service fee...")
Service.objects.get_or_create(id=1, defaults={"delivery_fee": 15000})

print("Creating categories & products...")
categories = {
    "meva": Category.objects.create(name_uz="Mevalar", name_ru="Фрукты", name_en="Fruits", name_ko="과일", main_type="f"),
    "sabzavot": Category.objects.create(name_uz="Sabzavotlar", name_ru="Овощи", name_en="Vegetables", name_ko="야채", main_type="f"),
    "sut": Category.objects.create(name_uz="Sut mahsulotlari", name_ru="Молочные продукты", name_en="Dairy", name_ko="유제품", main_type="f"),
    "non": Category.objects.create(name_uz="Non va qandolat", name_ru="Хлеб и выпечка", name_en="Bakery", name_ko="베이커리", main_type="f"),
    "gosht": Category.objects.create(name_uz="Go'sht mahsulotlari", name_ru="Мясные продукты", name_en="Meat Products", name_ko="육류 제품", main_type="f"),
    "ichimlik": Category.objects.create(name_uz="Ichimliklar", name_ru="Напитки", name_en="Drinks", name_ko="음료", main_type="f"),
    "shirinlik": Category.objects.create(name_uz="Shirinliklar", name_ru="Сладости", name_en="Sweets", name_ko="사탕", main_type="f"),
}

def add_good(cat, names, price, expire_days=30):
    pi = ProductItem.objects.create(
        desc_uz=f"{names['uz']} - yangi mahsulot",
        desc_ru=f"{names['ru']} - свежий продукт",
        desc_en=f"{names['en']} - fresh product",
        desc_ko=f"{names['ko']} - 신선한 제품",
        new_price=price, old_price=price + 1000, available_quantity=random.randint(0, 150),
        main=True, active=True,
    )
    Good.objects.create(
        product=pi, category=cat,
        name_uz=names['uz'], name_ru=names['ru'], name_en=names['en'], name_ko=names['ko'],
        expire_date=date.today() + timedelta(days=expire_days),
    )
    return pi

product_seed = {
    "meva": [({"uz": "Mango", "ru": "Манго", "en": "Mango", "ko": "망고"}, 5000),
              ({"uz": "Olma", "ru": "Яблоко", "en": "Apple", "ko": "사과"}, 2000),
              ({"uz": "Banan", "ru": "Банан", "en": "Banana", "ko": "바나나"}, 3500)],
    "sabzavot": [({"uz": "Bodring", "ru": "Огурец", "en": "Cucumber", "ko": "오이"}, 1500),
                 ({"uz": "Pomidor", "ru": "Помидор", "en": "Tomato", "ko": "토마토"}, 2000),
                 ({"uz": "Kartoshka", "ru": "Картофель", "en": "Potato", "ko": "감자"}, 1200)],
    "sut": [({"uz": "Sut", "ru": "Молоко", "en": "Milk", "ko": "우유"}, 2500),
            ({"uz": "Pishloq", "ru": "Сыр", "en": "Cheese", "ko": "치즈"}, 12000)],
    "non": [({"uz": "Non", "ru": "Хлеб", "en": "Bread", "ko": "빵"}, 3000),
            ({"uz": "Pechenye", "ru": "Печенье", "en": "Cookies", "ko": "쿠키"}, 15000)],
    "gosht": [({"uz": "Tovuq go'shti", "ru": "Курица", "en": "Chicken", "ko": "닭고기"}, 35000),
              ({"uz": "Mol go'shti", "ru": "Говядина", "en": "Beef", "ko": "소고기"}, 85000)],
    "ichimlik": [({"uz": "Suv", "ru": "Вода", "en": "Water", "ko": "물"}, 1000),
                 ({"uz": "Cola", "ru": "Кола", "en": "Cola", "ko": "콜라"}, 4000)],
    "shirinlik": [({"uz": "Shokolad", "ru": "Шоколад", "en": "Chocolate", "ko": "초콜릿"}, 18000)],
}

products = []
for key, items in product_seed.items():
    for names, price in items:
        products.append(add_good(categories[key], names, price))

print(f"Created {len(products)} products across {len(categories)} categories.")

print("Creating fake customers...")
first_names = ["Aziz", "Malika", "Bekzod", "Nodira", "Sardor", "Gulnora", "Jasur", "Dilnoza",
               "Otabek", "Feruza", "Shohrux", "Kamola", "Rustam", "Zilola", "Anvar", "Sevara"]
last_names = ["Karimov", "Yusupova", "Toshmatov", "Rashidova", "Aliyev", "Nazarova",
              "Ergashev", "Xolmatova", "Saidov", "Yuldasheva"]

profiles = []
for i in range(60):
    username = f"user{i+1:03d}"
    user = User.objects.create_user(username=username, password="testpass123")
    full_name = f"{random.choice(first_names)} {random.choice(last_names)}"
    profile = Profile.objects.create(
        origin=user,
        full_name=full_name,
        phone_number=f"+99890{random.randint(1000000, 9999999)}",
        lang=random.choice(["uz", "ru", "en", "kr"]),
        cashback=random.randint(0, 50000),
    )
    Location.objects.create(user=profile, address=f"Tashkent, house {random.randint(1,200)}", active=True)
    profiles.append(profile)

print(f"Created {len(profiles)} customer profiles.")

print("Creating fake orders...")
statuses = ["in_cart", "pending", "payment_pending", "approved", "cancelled", "Sent"]
status_weights = [0.05, 0.35, 0.15, 0.15, 0.1, 0.2]

now = timezone.now()
order_count = 0
for profile in profiles:
    for _ in range(random.randint(0, 4)):
        status = random.choices(statuses, weights=status_weights, k=1)[0]
        order = Order.objects.create(
            user=profile,
            status=status,
            location=profile.location.first(),
        )
        order.created_at = now - timedelta(days=random.randint(0, 60), hours=random.randint(0, 23))
        for _ in range(random.randint(1, 5)):
            OrderItem.objects.create(
                order=order,
                product=random.choice(products),
                quantity=random.randint(1, 5),
            )
        order.update_total_amount()
        Order.objects.filter(pk=order.pk).update(created_at=order.created_at)
        order_count += 1

print(f"Created {order_count} orders.")

print("Creating loyalty cards for some users...")
for profile in random.sample(profiles, 20):
    LoyaltyCard.objects.get_or_create(
        profile=profile,
        defaults={
            "current_balance": Decimal(random.randint(0, 100000)),
            "cycle_start": date.today() - timedelta(days=10),
            "cycle_end": date.today() + timedelta(days=50),
        },
    )

print("Done! Local demo data seeded.")
