#!/usr/bin/env bash
# exit on error
set -o errexit

# Pip-ni yangilaymiz va setuptools-ni o'rnatamiz (drf-yasg uchun pkg_resources kerak)
python -m pip install --upgrade pip
# pkg_resources yangi setuptools versiyalarida olib tashlangan (drf-yasg
# hali ham shunga tayanadi) - shu sababli versiyani cheklaymiz.
pip install "setuptools<81"

pip install -r requirements.txt

python manage.py migrate
python manage.py collectstatic --no-input

# 'admin' mavjud bo'lmasa avtomatik yaratadi - Shell'ga kirish shart emas.
# ESLATMA: parol shu faylda ochiq matnda (GitHub'da hamma ko'radi) -
# birinchi kirishdan keyin darhol /dashboard/ orqali o'zgartiring.
python manage.py shell -c "
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser(username='admin', password='123456', email='admin@example.com')
    print('Superuser created: admin')
"

# E'TIBOR: avval bu yerda /opt/render/project/src/mediafiles yaratilardi,
# lekin Django'ning haqiqiy MEDIA_ROOT'i BUTUNLAY BOSHQA yo'lga (config/
# ichida, BASE_DIR quirk sababli) tushardi - bu mkdir Django uchun
# umuman foydasiz edi. Endi MEDIA_ROOT bilan BIR XIL manba (env var)
# ishlatiladi.
MEDIA_DIR="${MEDIA_ROOT:-/opt/render/project/src/backend/config/mediafiles}"
mkdir -p "$MEDIA_DIR" 2>/dev/null || true
chmod -R 777 "$MEDIA_DIR" 2>/dev/null || true

# Demo katalog: 10 kategoriya + 30 mahsulot (faqat bo'sh bo'lsa yaratadi)
python manage.py shell -c "
from apps.product.models import Category
if Category.objects.count() == 0:
    from django.core.management import call_command
    call_command('seed_demo_catalog')
    print('Demo catalog seeded')
else:
    print('Catalog already has data, skipping seed')
"
