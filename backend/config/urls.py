from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path, re_path
from django.views.static import serve
from django.shortcuts import redirect

from apps.dashboard.order_bot import telegram_webhook
from apps.dashboard.users import user_login, user_logout

from drf_spectacular.views import (
    SpectacularAPIView,
    SpectacularSwaggerView,
)

import debug_toolbar


def redirect_dashboard(request):
    return redirect("dashboard")


urlpatterns = [
    # API lar
    path("api/customer/", include("apps.customer.urls")),
    path("api/product/", include("apps.product.urls")),
    path("api/merchant/", include("apps.merchant.urls")),

    # Admin
    path("admin/", admin.site.urls),

    # Dashboard
    path("dashboard/", include("apps.dashboard.urls")),
    path("", redirect_dashboard),

    # Auth
    path("login/", user_login, name="login_page"),
    path("logout/", user_logout, name="logout"),

    # Debug
    path("__debug__/", include(debug_toolbar.urls)),

    # Swagger / OpenAPI
    path("api/schema/", SpectacularAPIView.as_view(), name="schema"),
    path("swagger/", SpectacularSwaggerView.as_view(url_name="schema")),
    path('bot/index/', telegram_webhook, name='telegram_webhook'),
]

# Static & media
urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

urlpatterns += [
    re_path(r'^media/(?P<path>.*)$', serve, {'document_root': settings.MEDIA_ROOT}),
]
