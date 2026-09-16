"""Render (yoki boshqa target) muhitida ishga tushiriladi: shu repo bilan
birga push qilingan apps/product/fixtures/goods_transfer/data.json va
media/ fayllaridan Category/ProductItem/Good/Image yozuvlarini yaratadi.

Rasm fayllari Django File API orqali saqlanadi - shu sababli agar
CLOUDINARY_URL o'rnatilgan bo'lsa, avtomatik Cloudinary'ga yuklanadi
(default_storage orqali).

Eski PK'lar SAQLANMAYDI - yangi obyektlar yaratiladi va bog'lanishlar
(Good.product, Good.category, Image.product) xotiradagi old_pk -> yangi
instance xaritasi orqali to'g'rilanadi. Bu target DB'da allaqachon
boshqa ma'lumotlar bo'lsa ham xavfsiz (PK to'qnashuvi bo'lmaydi).

Idempotent EMAS - ikki marta ishga tushirilsa ikkilanadi. Faqat bir
marta ishga tushiring.
"""
import json
import os

from django.core.files import File
from django.core.management.base import BaseCommand

from apps.product.models import Category, ProductItem, Good, Image

# settings.BASE_DIR shu loyihada "config/" ga teng (project root emas) -
# shu sababli ushbu fayl joylashuvidan nisbiy hisoblanadi:
# apps/product/management/commands/ -> apps/product/
PRODUCT_APP_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
INPUT_DIR = os.path.join(PRODUCT_APP_DIR, "fixtures", "goods_transfer")
MEDIA_INPUT_DIR = os.path.join(INPUT_DIR, "media")


class Command(BaseCommand):
    help = "Load Good-related Category/ProductItem/Good/Image data + images dumped by dump_goods_transfer."

    def handle(self, *args, **options):
        data_file = os.path.join(INPUT_DIR, "data.json")
        if not os.path.exists(data_file):
            self.stderr.write(self.style.ERROR(f"Not found: {data_file}"))
            return

        with open(data_file, "r", encoding="utf-8") as f:
            data = json.load(f)

        def attach_image(field_file, rel_name):
            if not rel_name:
                return
            src_path = os.path.join(MEDIA_INPUT_DIR, rel_name)
            if not os.path.exists(src_path):
                self.stderr.write(self.style.WARNING(f"Missing media file: {src_path}"))
                return
            basename = os.path.basename(rel_name)
            with open(src_path, "rb") as fh:
                field_file.save(basename, File(fh), save=True)

        category_map = {}
        for c in data["categories"]:
            obj = Category.objects.create(
                main_type=c["main_type"],
                name=c["name"],
                desc=c["desc"],
                active=c["active"],
                is_top=c["is_top"],
            )
            attach_image(obj.image, c["image"])
            category_map[c["old_pk"]] = obj
        self.stdout.write(self.style.SUCCESS(f"Created {len(category_map)} categories"))

        product_map = {}
        for p in data["product_items"]:
            obj = ProductItem.objects.create(
                name=p["name"],
                desc=p["desc"],
                product_type=p["product_type"],
                old_price=p["old_price"],
                new_price=p["new_price"],
                b2b_price=p["b2b_price"],
                min_wholesale_quantity=p["min_wholesale_quantity"],
                weight=p["weight"],
                measure=p["measure"],
                available_quantity=p["available_quantity"],
                bonus=p["bonus"],
                discount_price=p["discount_price"],
                main=p["main"],
                active=p["active"],
            )
            product_map[p["old_pk"]] = obj
        self.stdout.write(self.style.SUCCESS(f"Created {len(product_map)} product items"))

        good_count = 0
        for g in data["goods"]:
            Good.objects.create(
                name=g["name"],
                product=product_map.get(g["product_old_pk"]),
                ingredients=g["ingredients"],
                expire_date=g["expire_date"],
                category=category_map.get(g["category_old_pk"]),
            )
            good_count += 1
        self.stdout.write(self.style.SUCCESS(f"Created {good_count} goods"))

        image_count = 0
        for img in data["images"]:
            product = product_map.get(img["product_old_pk"])
            if not product:
                continue
            obj = Image.objects.create(name=img["name"], product=product)
            attach_image(obj.image, img["image"])
            image_count += 1
        self.stdout.write(self.style.SUCCESS(f"Created {image_count} images"))
