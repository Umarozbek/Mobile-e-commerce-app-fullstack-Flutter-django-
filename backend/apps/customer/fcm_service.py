"""
Firebase Cloud Messaging (FCM) orqali push xabarnoma yuborish uchun markaziy
servis. Barcha Firebase Admin SDK logikasi shu yerda joylashgan - dashboard
view'lar yoki signal'lar Firebase bilan bevosita ishlamaydi (faqat shu
servisni chaqiradi).

Ishlatilishi:
    result = FCMService.broadcast(
        title="Katta chegirma",
        body="30% gacha chegirma",
        image="https://.../banner.jpg",
        data={"notificationId": "12", "type": "SALE", "link": "/sale"},
    )
    # result = {"sent": 5, "failed": 1, "deactivated": 1, "configured": True}
"""
import base64
import json
import os

import firebase_admin
from firebase_admin import credentials, exceptions, messaging

_firebase_app = None
_init_attempted = False


def _load_credentials():
    """Firebase service-account ma'lumotlarini uchta manbadan birida qidiradi:

    1. FIREBASE_CREDENTIALS_JSON_B64 - base64 kodlangan JSON (Render uchun tavsiya etiladi)
    2. FIREBASE_CREDENTIALS_JSON - xom (raw) JSON matni env o'zgaruvchida
    3. FIREBASE_CREDENTIALS_PATH - lokal fayl yo'li (standart: firebase-service-account.json)
    """
    b64_value = os.getenv("FIREBASE_CREDENTIALS_JSON_B64")
    if b64_value:
        try:
            decoded = base64.b64decode(b64_value)
            return credentials.Certificate(json.loads(decoded))
        except Exception as e:
            print(f"[FCMService] FIREBASE_CREDENTIALS_JSON_B64 noto'g'ri: {e}")
            return None

    raw_json = os.getenv("FIREBASE_CREDENTIALS_JSON")
    if raw_json:
        try:
            return credentials.Certificate(json.loads(raw_json))
        except Exception as e:
            print(f"[FCMService] FIREBASE_CREDENTIALS_JSON noto'g'ri: {e}")
            return None

    local_path = os.getenv("FIREBASE_CREDENTIALS_PATH", "firebase-service-account.json")
    if os.path.exists(local_path):
        try:
            return credentials.Certificate(local_path)
        except Exception as e:
            print(f"[FCMService] {local_path} o'qib bo'lmadi: {e}")
            return None

    return None


def _get_firebase_app():
    """Firebase Admin ilovasini bir marta ishga tushiradi (lazy singleton)."""
    global _firebase_app, _init_attempted
    if _firebase_app is not None:
        return _firebase_app
    if _init_attempted:
        # Avvalgi urinish muvaffaqiyatsiz bo'lgan - qayta urinib
        # bazaga/tarmoqqa keraksiz zarba bermaymiz, faqat shu process
        # davomida (masalan credentials keyin to'g'irlansa, server qayta
        # ishga tushirilganda qaytadan urinadi).
        return None

    _init_attempted = True
    cred = _load_credentials()
    if cred is None:
        return None
    try:
        _firebase_app = firebase_admin.initialize_app(cred)
    except ValueError:
        # Ilova allaqachon ishga tushirilgan (masalan autoreload paytida)
        _firebase_app = firebase_admin.get_app()
    return _firebase_app


# Xato turlari - token endi yaroqsiz, DeviceToken'ni o'chirish (deactivate) kerak
_INVALID_TOKEN_ERRORS = (
    messaging.UnregisteredError,
    messaging.SenderIdMismatchError,
    exceptions.InvalidArgumentError,
    exceptions.NotFoundError,
)

_MULTICAST_CHUNK_SIZE = 500  # FCM'ning bitta so'rovdagi maksimal token soni


class FCMService:
    """Push xabarnoma yuborish uchun yagona kirish nuqtasi."""

    @classmethod
    def is_configured(cls) -> bool:
        """Firebase ishga tushirilishi mumkinmi (kerakli credentials bormi)."""
        return _get_firebase_app() is not None

    @classmethod
    def broadcast(cls, title, body, image=None, data=None):
        """Barcha FAOL DeviceToken'larga (bazadagi) push yuboradi.

        Bitta yaroqsiz/ro'yxatdan o'chirilgan token BOSHQA foydalanuvchilarga
        yuborishni to'xtatmaydi - har bir xato alohida ushlanadi.

        Returns:
            dict: {
                "configured": bool,   # Firebase sozlanganmi
                "total_tokens": int,  # yuborishga urinilgan tokenlar soni
                "sent": int,          # muvaffaqiyatli yuborilganlar
                "failed": int,        # xato bilan tugaganlar (yaroqsizlardan tashqari ham bo'lishi mumkin)
                "deactivated": int,   # yaroqsiz deb topilib faolsizlantirilgan tokenlar
                "error": str | None,
            }
        """
        from .models import DeviceToken

        result = {
            "configured": False,
            "total_tokens": 0,
            "sent": 0,
            "failed": 0,
            "deactivated": 0,
            "error": None,
        }

        if not title and not body:
            result["error"] = "title yoki body kerak"
            return result

        app = cls._get_app_or_error(result)
        if app is None:
            return result
        result["configured"] = True

        tokens = list(
            DeviceToken.objects.filter(is_active=True).values_list("token", flat=True)
        )
        result["total_tokens"] = len(tokens)
        if not tokens:
            return result

        str_data = {str(k): str(v) for k, v in (data or {}).items()}
        notification = messaging.Notification(title=title, body=body, image=image)

        for chunk_start in range(0, len(tokens), _MULTICAST_CHUNK_SIZE):
            chunk = tokens[chunk_start:chunk_start + _MULTICAST_CHUNK_SIZE]
            cls._send_chunk(chunk, notification, str_data, result)

        return result

    @classmethod
    def send_to_profile(cls, profile, title, body, image=None, data=None):
        """Faqat BITTA profilning FAOL qurilmalariga push yuboradi.

        Kelajakda shaxsiy (targeted) xabarnomalar kerak bo'lganda ishlatiladi
        (hozircha asosiy talab - broadcast).
        """
        from .models import DeviceToken

        result = {
            "configured": False, "total_tokens": 0, "sent": 0,
            "failed": 0, "deactivated": 0, "error": None,
        }
        app = cls._get_app_or_error(result)
        if app is None:
            return result
        result["configured"] = True

        tokens = list(
            DeviceToken.objects.filter(profile=profile, is_active=True).values_list("token", flat=True)
        )
        result["total_tokens"] = len(tokens)
        if not tokens:
            return result

        str_data = {str(k): str(v) for k, v in (data or {}).items()}
        notification = messaging.Notification(title=title, body=body, image=image)
        cls._send_chunk(tokens, notification, str_data, result)
        return result

    # ---------------- ICHKI YORDAMCHI METODLAR ----------------

    @classmethod
    def _get_app_or_error(cls, result):
        app = _get_firebase_app()
        if app is None:
            result["error"] = "Firebase sozlanmagan (FIREBASE_CREDENTIALS_* topilmadi)"
        return app

    @classmethod
    def _send_chunk(cls, tokens, notification, str_data, result):
        message = messaging.MulticastMessage(
            notification=notification,
            data=str_data,
            tokens=tokens,
        )
        try:
            response = messaging.send_each_for_multicast(message)
        except Exception as e:
            # Butun so'rov muvaffaqiyatsiz bo'lsa ham (masalan tarmoq xatosi),
            # dastur to'xtamaydi - shu chunk "failed" deb hisoblanadi.
            print(f"[FCMService] multicast so'rovi muvaffaqiyatsiz: {e}")
            result["failed"] += len(tokens)
            return

        invalid_tokens = []
        for idx, send_response in enumerate(response.responses):
            if send_response.success:
                result["sent"] += 1
            else:
                result["failed"] += 1
                if isinstance(send_response.exception, _INVALID_TOKEN_ERRORS):
                    invalid_tokens.append(tokens[idx])

        if invalid_tokens:
            from .models import DeviceToken
            deactivated = DeviceToken.objects.filter(
                token__in=invalid_tokens
            ).update(is_active=False)
            result["deactivated"] += deactivated
