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

# DJANGO_SUPERUSER_USERNAME/PASSWORD Render Environment'da o'rnatilgan
# bo'lsa - shu nomdagi admin mavjud bo'lmasa avtomatik yaratadi.
# Xavfsiz: allaqachon mavjud bo'lsa hech narsa qilmaydi, build'ni
# to'xtatmaydi (Shell'ga kirish shart emas).
python manage.py shell -c "
import os
from django.contrib.auth import get_user_model
User = get_user_model()
username = os.getenv('DJANGO_SUPERUSER_USERNAME')
password = os.getenv('DJANGO_SUPERUSER_PASSWORD')
email = os.getenv('DJANGO_SUPERUSER_EMAIL', '')
if username and password and not User.objects.filter(username=username).exists():
    User.objects.create_superuser(username=username, password=password, email=email)
    print('Superuser created:', username)
"

# MANA SHU QATORLARNI QO'SHING:
mkdir -p /opt/render/project/src/mediafiles
chmod -R 777 /opt/render/project/src/mediafiles
