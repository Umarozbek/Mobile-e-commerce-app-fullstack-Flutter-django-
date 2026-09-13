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

# MANA SHU QATORLARNI QO'SHING:
mkdir -p /opt/render/project/src/mediafiles
chmod -R 777 /opt/render/project/src/mediafiles
