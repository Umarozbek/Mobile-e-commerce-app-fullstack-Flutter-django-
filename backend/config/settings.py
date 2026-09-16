import os
from datetime import timedelta
from pathlib import Path
from dotenv import load_dotenv
# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent

# ============================================
# ASOSIY SOZLAMALAR
# ============================================
load_dotenv()
# SECRET KEY
SECRET_KEY = os.getenv("SECRET_KEY")

# DEBUG rejimi
DEBUG = os.getenv("DEBUG", "False") == "True"

# Ruxsat berilgan hostlar
ALLOWED_HOSTS = [h.strip() for h in os.getenv("ALLOWED_HOSTS", "").split(",") if h.strip()]

# CSRF ishonchli domenlar
CSRF_TRUSTED_ORIGINS = [h.strip() for h in os.getenv("CSRF_TRUSTED_ORIGINS", "").split(",") if h.strip()]

# Render avtomatik shu env var'ni beradi - qo'lda ALLOWED_HOSTS/CSRF_TRUSTED_ORIGINS
# sozlanmagan bo'lsa ham (masalan health check) 400/403 bo'lib qolmasligi uchun.
RENDER_EXTERNAL_HOSTNAME = os.getenv("RENDER_EXTERNAL_HOSTNAME")
if RENDER_EXTERNAL_HOSTNAME:
    if RENDER_EXTERNAL_HOSTNAME not in ALLOWED_HOSTS:
        ALLOWED_HOSTS.append(RENDER_EXTERNAL_HOSTNAME)
    render_origin = f"https://{RENDER_EXTERNAL_HOSTNAME}"
    if render_origin not in CSRF_TRUSTED_ORIGINS:
        CSRF_TRUSTED_ORIGINS.append(render_origin)

# Login redirect
LOGIN_REDIRECT_URL = "dashboard"
LOGIN_URL = "login_page"

# Domain
DOMAIN_NAME = os.getenv("DOMAIN_NAME")

# ============================================
# ILOVALAR
# ============================================

LOCAL_APPS = [
    "apps.product",
    'apps.merchant.apps.MerchantConfig',
    'apps.customer.apps.CustomerConfig',
]

INSTALLED_APPS = [
    "modeltranslation",
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "django_filters",
    "rest_framework",
    "rest_framework.authtoken",
    "corsheaders",
    "ckeditor",
    "ckeditor_uploader",
    "drf_spectacular",
] + LOCAL_APPS

# Cloudinary faqat CLOUDINARY_URL o'rnatilgan bo'lsa yoqiladi - aks holda
# mediafayllar lokal diskka yoziladi (local dev uchun). Render kabi
# ephemeral fayl tizimida CLOUDINARY_URL SHART, aks holda har deploy'da
# yuklangan rasmlar o'chib ketadi.
#
# E'TIBOR: "cloudinary_storage" ilovasi ATAYLAB INSTALLED_APPS'ga
# QO'SHILMAYDI - u o'zining collectstatic buyrug'ini ro'yxatdan
# o'tkazadi va bu loyihada mavjud bo'lmagan STATICFILES_STORAGE
# sozlamasiga tayanadi (build'ni qulatib qo'ygan edi). Faqat Storage
# klassi kerak, app-darajasidagi buyruq override emas.
#
# E'TIBOR 2: eski DEFAULT_FILE_STORAGE emas, yangi STORAGES dict
# ishlatiladi - Django 4.2+ da DEFAULT_FILE_STORAGE aslida e'tiborga
# olinmaydi (STORAGES ochiq belgilanmagan bo'lsa ham Django o'zining
# implicit default'ini ishlatadi, eski setting'ni yutib yuboradi).
STORAGES = {
    "default": {"BACKEND": "django.core.files.storage.FileSystemStorage"},
    "staticfiles": {"BACKEND": "django.contrib.staticfiles.storage.StaticFilesStorage"},
}
if os.getenv("CLOUDINARY_URL"):
    STORAGES["default"]["BACKEND"] = "cloudinary_storage.storage.MediaCloudinaryStorage"

# ============================================
# MIDDLEWARE
# ============================================

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    'whitenoise.middleware.WhiteNoiseMiddleware',
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
    "corsheaders.middleware.CorsMiddleware",
]

# if DEBUG:
#     INSTALLED_APPS += ["debug_toolbar"]
#     MIDDLEWARE += ["debug_toolbar.middleware.DebugToolbarMiddleware"]

# ============================================
# URL VA WSGI
# ============================================

ROOT_URLCONF = "config.urls"
WSGI_APPLICATION = "config.wsgi.application"

# ============================================
# TEMPLATES
# ============================================

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [BASE_DIR / "../templates", os.path.join(BASE_DIR, "templates")],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

# ============================================
# DATABASE
# ============================================

if os.getenv("DB_NAME"):
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.postgresql',
            'NAME': os.getenv("DB_NAME"),
            'USER': os.getenv("DB_USER"),
            'PASSWORD': os.getenv("DB_PASSWORD"),
            'HOST': os.getenv("DB_HOST", "localhost"),
            'PORT': os.getenv("DB_PORT", "5432"),
        }
    }
else:
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.sqlite3',
            'NAME': BASE_DIR / 'db.sqlite3',
        }
    }

# ============================================
# PASSWORD VALIDATION
# ============================================

AUTH_PASSWORD_VALIDATORS = [
    {
        "NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.MinimumLengthValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.CommonPasswordValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.NumericPasswordValidator",
    },
]

# ============================================
# INTERNATIONALIZATION
# ============================================

LANGUAGE_CODE = "uz"
TIME_ZONE = "UTC"
USE_I18N = True
USE_TZ = True

LANGUAGES = (
    ("en", "English"),
    ("uz", "Uzbek"),
    ("ru", "Russian"),
    ("ko", "Korean"),
)

MODELTRANSLATION_DEFAULT_LANGUAGE = "en"
MODELTRANSLATION_LANGUAGES = ("uz", "en", "ru", "ko")

# ============================================
# STATIC VA MEDIA FILES
# ============================================

STATIC_URL = os.getenv("STATIC_URL", "static/")
STATICFILES_DIRS = [os.path.join(BASE_DIR, "../", "static")]
STATIC_ROOT = os.path.join(BASE_DIR, "../", "staticfiles")

MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'mediafiles')

# ============================================
# REST FRAMEWORK
# ============================================

REST_FRAMEWORK = {
    "DEFAULT_SCHEMA_CLASS": "drf_spectacular.openapi.AutoSchema",
    "DEFAULT_PERMISSION_CLASSES": [
        "rest_framework.permissions.AllowAny",
    ],
    "DEFAULT_AUTHENTICATION_CLASSES": [
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ],
}

# ============================================
# JWT SOZLAMALARI
# ============================================

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(days=180),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=180),
    'ROTATE_REFRESH_TOKENS': False,
    'BLACKLIST_AFTER_ROTATION': False,
    'AUTH_HEADER_TYPES': ('Bearer',),
}

# ============================================
# CORS SOZLAMALARI
# ============================================

CORS_ALLOW_ALL_ORIGINS = True
CORS_ALLOW_CREDENTIALS = True
CORS_ALLOW_HEADERS = "*"

# ============================================
# CKEDITOR
# ============================================

CKEDITOR_UPLOAD_PATH = "uploads/"
CKEDITOR_CONFIGS = {
    'default': {
        'versionCheck': False,  # True bo'lsa ogohlantirish chiqadi, False bo'lsa yo'qoladi
        'toolbar': 'full',      # Toolbar sozlamalari (ixtiyoriy)
    },
}

# ============================================
# DRF SPECTACULAR (SWAGGER)
# ============================================

SPECTACULAR_SETTINGS = {
    'TITLE': 'Million Mart API',
    'DESCRIPTION': 'API for Million Mart Project',
    'VERSION': '1.0.0',
    'SERVE_INCLUDE_SCHEMA': False,
    'COMPONENTS': {
        'SECURITY_SCHEMES': {
            'Bearer': {
                'type': 'http',
                'scheme': 'bearer',
                'bearerFormat': 'JWT',
                'description': 'JWT Token based authentication',
            }
        }
    },
    'SECURITY': [{'Bearer': []}],
}

SWAGGER_SETTINGS = {
    'USE_SESSION_AUTH': False,
    'JSON_EDITOR': True,
}

# ============================================
# DEBUG TOOLBAR
# ============================================

INTERNAL_IPS = [
    "127.0.0.1",
    "0.0.0.0",
]

DEBUG_TOOLBAR_CONFIG = {"SHOW_TOOLBAR_CALLBACK": lambda request: True}

# ============================================
# CUSTOM USER MODEL
# ============================================

AUTH_USER_MODEL = "customer.User"

# ============================================
# TWILIO SOZLAMALARI (bo'sh qoldiring agar kerak bo'lmasa)
# ============================================

TOKEN_LIFESPAN = int(os.getenv("TOKEN_LIFESPAN", 10))  # default 10 mins
OTP_EXPIRE_TIME = int(os.getenv("OTP_EXPIRE_TIME", 10))

TWILIO_ACCOUNT_SID = os.getenv("TWILIO_ACCOUNT_SID")
TWILIO_AUTH_TOKEN = os.getenv("TWILIO_AUTH_TOKEN")
TWILIO_PHONE_NUMBER = os.getenv("TWILIO_PHONE_NUMBER")

# ============================================
# FIREBASE
# ============================================
# Legacy FCM HTTP API (FCM_SERVER_KEY) OLIB TASHLANDI - Google 2024-yil
# iyunda uni butunlay o'chirdi. Endi Firebase Admin SDK (HTTP v1 API)
# ishlatiladi - qarang: apps/customer/fcm_service.py (FCMService).
#
# Kerakli credentials (biror biri yetarli, apps/customer/fcm_service.py
# ularni shu tartibda qidiradi):
#   FIREBASE_CREDENTIALS_JSON_B64  - base64 kodlangan service-account JSON (Render uchun tavsiya)
#   FIREBASE_CREDENTIALS_JSON      - xom (raw) service-account JSON matni
#   FIREBASE_CREDENTIALS_PATH      - lokal fayl yo'li (standart: firebase-service-account.json)
# Bu yerda alohida sozlama kerak emas - fcm_service.py ularni to'g'ridan-to'g'ri
# os.getenv() orqali o'qiydi (lazy, birinchi push yuborilganda).

# ============================================
# DEFAULT SETTINGS
# ============================================

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"
