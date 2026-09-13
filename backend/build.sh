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

# MANA SHU QATORLARNI QO'SHING:
mkdir -p /opt/render/project/src/mediafiles
chmod -R 777 /opt/render/project/src/mediafiles
