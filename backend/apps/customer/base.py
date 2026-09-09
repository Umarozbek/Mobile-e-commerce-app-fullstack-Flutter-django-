"""
Customer uchun umumiy logika va helper funksiyalar
Bu fayl barcha customer view'larida qayta ishlatiladigan logikani saqlaydi
"""

from django.db.models import Q, Prefetch
from django.utils import timezone
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter
from .models import Profile, Favorite, Location, News, Banner, ViewedNews
from .serializers import (
    ProfileSerializer,
    FavoriteListSerializer,
    LocationListSerializer,
    NewsSerializer,
    BannerSerializer,
)


class CustomerListService:
    """
    Customer va unga bog'liq ma'lumotlarni list qilish uchun umumiy logika
    """

    @staticmethod
    def get_customer_list(filters=None, search_query=None):
        """
        Barcha customer'larni (Profile) list qilish
        
        Args:
            filters: Filter parametrlari
            search_query: Qidiruv so'zi
            
        Returns:
            Filtered queryset
        """
        queryset = Profile.objects.all().order_by('-id')

        if search_query:
            queryset = queryset.filter(
                Q(full_name__icontains=search_query) |
                Q(phone_number__icontains=search_query)
            )

        return queryset

    @staticmethod
    def get_customer_favorites(user_profile, filters=None):
        """
        Foydalanuvchining sevimli mahsulotlarini list qilish
        """
        queryset = Favorite.objects.filter(
            user=user_profile
        ).select_related(
            'product__tickets',
            'product__goods',
            'product__phones'
        ).prefetch_related(
            'product__images'
        ).order_by('-pk')

        return queryset

    @staticmethod
    def get_customer_locations(user_profile):
        """
        Foydalanuvchining manzillarini list qilish
        """
        queryset = Location.objects.filter(
            user=user_profile
        ).order_by('-pk')

        return queryset

    @staticmethod
    def get_news_list(filters=None):
        """
        Barcha yangiliklarni list qilish
        """
        queryset = News.objects.all().order_by('-pk')
        return queryset

    @staticmethod
    def get_notifications_list(notification_type=None):
        """
        Mobil ilova uchun ko'rinadigan bildirishnomalar ro'yxati.

        Qoidalar:
        - active=True
        - start_date bo'sh YOKI start_date <= hozirgi vaqt
        - end_date bo'sh YOKI end_date >= hozirgi vaqt
        Tartiblash: priority DESC, keyin created DESC.
        """
        now = timezone.now()
        queryset = News.objects.filter(active=True).filter(
            Q(start_date__isnull=True) | Q(start_date__lte=now)
        ).filter(
            Q(end_date__isnull=True) | Q(end_date__gte=now)
        )
        if notification_type:
            queryset = queryset.filter(type=notification_type)
        return queryset.order_by("-priority", "-created")

    @staticmethod
    def get_banners_list():
        """
        Barcha banner'larni list qilish
        """
        queryset = Banner.objects.all().order_by('-pk')
        return queryset


class CustomerFilterService:
    """
    Filter va search parametrlarini qayta ishlash
    """

    @staticmethod
    def get_filter_backends():
        """Filter va search backend'lari"""
        return [DjangoFilterBackend, SearchFilter]

    @staticmethod
    def get_customer_search_fields():
        """Customer qidiruv maydonlari"""
        return ['full_name', 'phone_number']

    @staticmethod
    def get_location_search_fields():
        """Location qidiruv maydonlari"""
        return ['user__full_name', 'address']

    @staticmethod
    def get_news_search_fields():
        """News qidiruv maydonlari"""
        return ['description']

    @staticmethod
    def get_favorite_search_fields():
        """Favorite qidiruv maydonlari"""
        return ['product__name', 'user__full_name']
