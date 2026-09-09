from django.db.models.signals import post_save
from django.dispatch import receiver

from apps.customer.fcm_service import FCMService
from .models import ProductItem

# ESLATMA: News (e'lon/xabarnoma) yaratilganda avtomatik push yuborish OLIB
# TASHLANDI. Endi admin dashboard'da News/Notification yaratilgandan keyin
# alohida, ongli "Push yuborish" tugmasi bosiladi (apps/dashboard/main.py,
# NewsSendPushView). Agar bu yerda ham avtomatik yuborilsa, bitta News uchun
# IKKI marta push ketardi (bir marta yaratilganda avtomatik, yana bir marta
# admin tugmani bosganda) - shu sababli bu signal butunlay olib tashlandi.
#
# ProductItem uchun dashboard'da alohida "push yuborish" tugmasi yo'q, shuning
# uchun quyidagi ikkita signal saqlab qolindi va yangi FCMService orqali
# ishlaydigan qilib ko'chirildi (eski https://fcm.googleapis.com/fcm/send +
# FCM_SERVER_KEY - bekor qilingan/ishlamaydigan Legacy FCM HTTP API edi).
#
# Eski kod "topic" argumentini butunlay e'tiborsiz qoldirib, doim
# "/topics/all"ga yuborardi (topilgan xato). Yangi arxitektura FCM
# "topic"laridan umuman foydalanmaydi - o'rniga bazadagi FAOL DeviceToken
# yozuvlariga bevosita (multicast) yuboradi, shuning uchun topic argumenti
# butunlay kerak bo'lmay qoldi.


@receiver(post_save, sender=ProductItem)
def product_created(sender, instance, created, **kwargs):
    if not created:
        return
    FCMService.broadcast(
        title="Yangi mahsulot!",
        body=instance.desc or "Yangi mahsulot qo'shildi",
        data={"type": "PRODUCT", "productId": str(instance.id)},
    )


@receiver(post_save, sender=ProductItem)
def product_price_changed(sender, instance, created, **kwargs):
    if created:
        return
    if instance.price_changed():
        FCMService.broadcast(
            title="Mahsulot narxi arzonladi",
            body=instance.desc or "Mahsulot narxi arzonlashtirildi",
            data={"type": "SALE", "productId": str(instance.id)},
        )
