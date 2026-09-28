"""10 ta kategoriya va 30 ta mahsulot (Good) yaratadi, har biriga PIL bilan
generatsiya qilingan oddiy rasm biriktiriladi (haqiqiy fayl kerak emas).

Rasm Django File API orqali saqlanadi - CLOUDINARY_URL o'rnatilgan bo'lsa
(masalan Render'da) avtomatik Cloudinary'ga yuklanadi.

Ishga tushirish: python manage.py seed_demo_catalog
"""
import random
import uuid
from decimal import Decimal
from io import BytesIO

from django.core.files.base import ContentFile
from django.core.management.base import BaseCommand
from PIL import Image as PILImage, ImageDraw, ImageFont

from apps.product.models import Category, ProductItem, Good, Image

CATEGORIES = [
    ("Mevalar", "#e74c3c"),
    ("Sabzavotlar", "#27ae60"),
    ("Sut mahsulotlari", "#3498db"),
    ("Non va qandolat", "#e67e22"),
    ("Go'sht mahsulotlari", "#c0392b"),
    ("Ichimliklar", "#2980b9"),
    ("Shirinliklar", "#9b59b6"),
    ("Baliq mahsulotlari", "#16a085"),
    ("Yong'oqlar va quritilgan mevalar", "#d35400"),
    ("Ziravorlar", "#8e44ad"),
]

PRODUCT_NAMES = [
    "Olma", "Banan", "Apelsin", "Uzum", "Qulupnay",
    "Pomidor", "Bodring", "Kartoshka", "Sabzi", "Piyoz",
    "Sut", "Tvorog", "Qaymoq", "Pishloq", "Yogurt",
    "Non", "Bulochka", "Tort", "Pechenye", "Vafli",
    "Mol go'shti", "Tovuq go'shti", "Qo'y go'shti", "Kolbasa", "Sosiska",
    "Suv", "Sok", "Cola", "Choy", "Kofe",
]


def make_placeholder_image(text, color):
    img = PILImage.new("RGB", (400, 400), color=color)
    draw = ImageDraw.Draw(img)
    try:
        font = ImageFont.truetype("arial.ttf", 28)
    except Exception:
        font = ImageFont.load_default()
    bbox = draw.textbbox((0, 0), text, font=font)
    w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
    draw.text(((400 - w) / 2, (400 - h) / 2), text, fill="white", font=font)
    buf = BytesIO()
    img.save(buf, format="PNG")
    buf.seek(0)
    return buf.read()


class Command(BaseCommand):
    help = "Seed 10 demo categories and 30 demo products (Good) with generated placeholder images."

    def handle(self, *args, **options):
        created_categories = []
        skipped_categories = 0
        for name, color in CATEGORIES:
            cat, created = Category.objects.get_or_create(
                name=name,
                defaults=dict(main_type="f", desc="", active=True, is_top=False),
            )
            if created:
                image_bytes = make_placeholder_image(name[:14], color)
                cat.image.save(f"{name.lower().replace(' ', '_')}.png", ContentFile(image_bytes), save=True)
            else:
                skipped_categories += 1
            created_categories.append(cat)
        new_cats = len(created_categories) - skipped_categories
        self.stdout.write(self.style.SUCCESS(f"Categories: {new_cats} created, {skipped_categories} already existed"))

        created_goods = 0
        skipped_goods = 0
        for i, product_name in enumerate(PRODUCT_NAMES):
            if Good.objects.filter(name=product_name).exists():
                skipped_goods += 1
                continue

            category = created_categories[i % len(created_categories)]
            price = random.randint(5, 100) * 1000

            product = ProductItem.objects.create(
                name=product_name,
                desc=f"{product_name} - sifatli va yangi mahsulot",
                product_type=uuid.uuid4(),
                old_price=Decimal(price + random.randint(1, 10) * 1000),
                new_price=Decimal(price),
                b2b_price=Decimal(price - random.randint(0, 5) * 1000),
                min_wholesale_quantity=1,
                weight=round(random.uniform(0.5, 5.0), 2),
                measure=random.choice([0, 1, 2, 3]),
                available_quantity=random.randint(10, 200),
                bonus=0,
                discount_price=0,
                main=True,
                active=True,
            )
            Good.objects.create(
                name=product_name,
                product=product,
                ingredients="",
                category=category,
            )
            _, color = CATEGORIES[i % len(CATEGORIES)]
            image_bytes = make_placeholder_image(product_name[:14], color)
            img_obj = Image.objects.create(name=product_name, product=product)
            img_obj.image.save(f"{product_name.lower()}_{i}.png", ContentFile(image_bytes), save=True)

            created_goods += 1

        self.stdout.write(self.style.SUCCESS(f"Products: {created_goods} created, {skipped_goods} already existed"))
