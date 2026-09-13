"""Vercel serverless entrypoint for the Django admin panel.

Vercel's Python runtime (@vercel/python) detects a WSGI-compatible `app`
callable in this file and routes all requests to it directly - no
gunicorn/uvicorn process, no adapter package needed.

This serves the SAME Django project as the Render deployment (identical
apps/models/urls) - only the *domain* differs. Render remains the one
that runs migrations and serves the mobile API + Telegram webhook;
this Vercel deployment is meant to be used for /dashboard/ (the admin
panel) only, pointed at the same Postgres database via the same
DB_NAME/DB_USER/DB_PASSWORD/DB_HOST/DB_PORT env vars.
"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")

import django
django.setup()

from django.core.wsgi import get_wsgi_application

app = get_wsgi_application()
