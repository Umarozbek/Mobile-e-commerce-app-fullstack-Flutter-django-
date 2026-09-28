#!/usr/bin/env bash

# Render Disk faqat runtime'da mavjud - media papkasini yaratamiz
MEDIA_DIR="${MEDIA_ROOT:-/opt/render/project/src/backend/config/mediafiles}"
mkdir -p "$MEDIA_DIR" 2>/dev/null || true

# Demo katalog: 10 kategoriya + 30 mahsulot (mavjudlarini o'tkazib yuboradi)
python manage.py seed_demo_catalog

# Gunicorn'ni ishga tushiramiz
exec gunicorn config.wsgi:application --bind 0.0.0.0:$PORT
