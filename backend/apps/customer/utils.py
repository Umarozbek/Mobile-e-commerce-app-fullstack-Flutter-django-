import random
from .models import Profile


def generate_otp():
    return random.randint(1000, 9999)


def parse_version(version: str) -> tuple:
    """"1.2.0" -> (1, 2, 0). Bo'sh/noto'g'ri qiymatlar (0,) sifatida olinadi
    (taqqoslashda eng past versiya sifatida ishlaydi)."""
    if not version:
        return (0,)
    parts = []
    for chunk in str(version).strip().split("."):
        digits = "".join(ch for ch in chunk if ch.isdigit())
        parts.append(int(digits) if digits else 0)
    return tuple(parts) if parts else (0,)


def is_version_lower(version: str, than: str) -> bool:
    """Semantik versiya taqqoslash (string taqqoslash EMAS - "2.10.0" < "2.9.0"
    satr sifatida noto'g'ri, lekin versiya sifatida noto'g'ri emas)."""
    return parse_version(version) < parse_version(than)
