"""LOCAL-ONLY: Good/Category mahsulotlarini boshqa (masalan production)
muhitga ko'chirish uchun JSON + rasm fayllarini tayyorlaydi.

Faqat Good'ga bog'liq Category/ProductItem/Good/Image'larni oladi -
Phone/Ticket'ga tegishli hech narsa qamrab olinmaydi.

Natija: apps/product/fixtures/goods_transfer/data.json va
apps/product/fixtures/goods_transfer/media/ ichida rasm fayllari.
Bu fayllarni target repo'ga push qilib, load_goods_transfer buyrug'ini
u yerda (masalan Render Shell'da) ishga tushirish kerak.
"""
import json
import os
import shutil

from django.core.management.base import BaseCommand

from apps.product.models import Category, ProductItem, Good, Image

# settings.BASE_DIR shu loyihada "config/" ga teng (project root emas) -
# shu sababli ushbu fayl joylashuvidan nisbiy hisoblanadi:
# apps/product/management/commands/ -> apps/product/
PRODUCT_APP_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUTPUT_DIR = os.path.join(PRODUCT_APP_DIR, "fixtures", "goods_transfer")
MEDIA_OUTPUT_DIR = os.path.join(OUTPUT_DIR, "media")


class Command(BaseCommand):
    help = "Dump Good-related Category/ProductItem/Good/Image data + images for transfer to another environment."

    def handle(self, *args, **options):
        os.makedirs(MEDIA_OUTPUT_DIR, exist_ok=True)

        categories = Category.objects.filter(goods__isnull=False).distinct().order_by("id")
        goods = Good.objects.select_related("product", "category").order_by("id")
        product_items = ProductItem.objects.filter(goods__isnull=False).distinct().order_by("id")
        images = Image.objects.filter(product__goods__isnull=False).distinct().order_by("id")

        def copy_media(field_file):
            if not field_file:
                return None
            src_path = field_file.path
            if not os.path.exists(src_path):
                self.stderr.write(self.style.WARNING(f"Missing file on disk: {src_path}"))
                return None
            rel_name = field_file.name  # e.g. "category/foo.jpg"
            dest_path = os.path.join(MEDIA_OUTPUT_DIR, rel_name)
            os.makedirs(os.path.dirname(dest_path), exist_ok=True)
            shutil.copy2(src_path, dest_path)
            return rel_name

        data = {
            "categories": [],
            "product_items": [],
            "goods": [],
            "images": [],
        }

        for c in categories:
            data["categories"].append({
                "old_pk": c.pk,
                "main_type": c.main_type,
                "name": c.name,
                "image": copy_media(c.image),
                "desc": c.desc,
                "active": c.active,
                "is_top": c.is_top,
            })

        for p in product_items:
            data["product_items"].append({
                "old_pk": p.pk,
                "name": p.name,
                "desc": p.desc,
                "product_type": str(p.product_type),
                "old_price": str(p.old_price) if p.old_price is not None else None,
                "new_price": str(p.new_price) if p.new_price is not None else None,
                "b2b_price": str(p.b2b_price) if p.b2b_price is not None else None,
                "min_wholesale_quantity": p.min_wholesale_quantity,
                "weight": p.weight,
                "measure": p.measure,
                "available_quantity": p.available_quantity,
                "bonus": p.bonus,
                "discount_price": p.discount_price,
                "main": p.main,
                "active": p.active,
            })

        for g in goods:
            data["goods"].append({
                "old_pk": g.pk,
                "name": g.name,
                "product_old_pk": g.product_id,
                "ingredients": g.ingredients,
                "expire_date": g.expire_date.isoformat() if g.expire_date else None,
                "category_old_pk": g.category_id,
            })

        for img in images:
            data["images"].append({
                "old_pk": img.pk,
                "name": img.name,
                "product_old_pk": img.product_id,
                "image": copy_media(img.image),
            })

        out_file = os.path.join(OUTPUT_DIR, "data.json")
        with open(out_file, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

        self.stdout.write(self.style.SUCCESS(
            f"Dumped {len(data['categories'])} categories, {len(data['product_items'])} product_items, "
            f"{len(data['goods'])} goods, {len(data['images'])} images -> {out_file}"
        ))
