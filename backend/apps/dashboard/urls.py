from collections import namedtuple

from django.urls import path

from .loyalty_card_managment import loyalty_customer_list, approve_bonus, \
    loyalty_user_detail_view, edit_loyalty_card, all_pending_bonuses, all_referrals, \
    toggle_referral_system
from .product import (
    PhoneListView,
    PhoneCreateView,
    TicketCreateView,
    TicketListView,
    GoodListView,
    GoodCreateView,
    PhoneCategoryCreateView,
    TicketCategoryCreateView,
    PhoneEditDeleteView,
    PhoneDeleteView,
    TicketDeleteView,
    TicketEditDeleteView,
    GoodEditDeleteView,
    GoodDeleteView,
    GoodMainCategoryCreateView,
    CategoryCreateView,
    CategoryListView,
    CategoryEditView,
    CategoryDeleteView,
    ChildrenView,
    ChildActionView, delete_good, bulk_delete_goods,
)

from .users import (
    UserListView,
    UserOrdersView,
    UserOrderDetailView,
    OrdersListView,
    BlockActivateUserView,
    update_order_status, order_update_status, update_b2b_status, b2b_applications_list, BankCardListView,
    BankCardCreateView, BankCardUpdateView, BankCardDeleteView, ServiceListView, ServiceCreateView, ServiceUpdateView,
    UnpaidOrdersListView, PaymentPendingOrdersListView, delete_order, delete_user, delete_b2b_application,
    update_shipping_settings,
    OrderBonusTierListView, OrderBonusTierCreateView, OrderBonusTierUpdateView, OrderBonusTierDeleteView,
    OrderBonusHistoryListView,
    telegram_settings_view, telegram_test_action, telegram_toggle_buttons_action, push_compose_view,
)
from .main import (
    dashboard,
    InformationView,
    BonusEditView,
    InformationEditView,
    ServiceView,
    ServiceEditView,
    BannerView,
    BannerActionView,
    NewsCreateView,
    NewsListView,
    NewsEditView,
    NewsActionView,
    NewsSendPushView,
    OrdersView, delete_order_dash,
)
from .users import (
    UserListView,
    UserOrdersView,
    UserOrderDetailView,
    OrdersListView,
    BlockActivateUserView,
)
from .bot import index
from django.contrib.auth.decorators import login_required
from .information import (
    edit_reminder,
    edit_agreement,
    edit_shipment,
    edit_privacy,
    edit_aboutus,
    edit_support,
    edit_payment,
    SocialMediaListView,
    SocialMediaEditView,
    base_info,
)

urlpatterns = [
    path("", login_required(dashboard), name="dashboard"),
    path(
        "product/category/create/",
        login_required(CategoryCreateView.as_view()),
        name="category-create",
    ),
    path(
        "product/category/list/",
        login_required(CategoryListView.as_view()),
        name="category-list",
    ),
    path(
        "product/category/edit/<int:pk>/",
        login_required(CategoryEditView.as_view()),
        name="category-edit",
    ),
    path(
        "product/category/<int:pk>/detelet",
        login_required(CategoryDeleteView.as_view()),
        name="category-delete",
    ),

    path(
        "product/create-phone/",
        login_required(PhoneCreateView.as_view()),
        name="create_phone",
    ),
    path(
        "product/phone-category/",
        login_required(PhoneCategoryCreateView.as_view()),
        name="phone_category",
    ),
    path("product/phones/", login_required(PhoneListView.as_view()), name="phone_list"),
    path(
        "product/phones/edit-delete/<int:pk>/",
        login_required(PhoneEditDeleteView.as_view()),
        name="edit_delete_phone",
    ),
    path(
        "product/phone/<int:pk>/delete/",
        login_required(PhoneDeleteView.as_view()),
        name="delete_phone",
    ),
    path(
        "product/ticket-create/",
        login_required(TicketCreateView.as_view()),
        name="ticket_create",
    ),
    path(
        "product/ticket-category/",
        login_required(TicketCategoryCreateView.as_view()),
        name="ticket_category",
    ),
    path(
        "product/tickets/", login_required(TicketListView.as_view()), name="ticket-list"
    ),
    path(
        "product/ticket/edit-delete/<int:pk>/",
        login_required(TicketEditDeleteView.as_view()),
        name="edit_delete_ticket",
    ),
    path(
        "product/ticket/<int:pk>/delete/",
        login_required(TicketDeleteView.as_view()),
        name="delete_ticket",
    ),
    path(
        "product/good-create/",
        login_required(GoodCreateView.as_view()),
        name="good_create",
    ),
    path(
        "product/good-category/",
        login_required(GoodMainCategoryCreateView.as_view()),
        name="good_category",
    ),
    path(
        "product/good-child/<int:pk>/",
        login_required(ChildrenView.as_view()),
        name="add_product_child",
    ),
    path(
        "product/good-child/action/<int:parent_pk>/<int:pk>/",
        login_required(ChildActionView.as_view()),
        name="product-child-action",
    ),
    path("product/goods/", login_required(GoodListView.as_view()), name="good-list"),
    path(
        "product/good/edit-delete/<int:pk>/",
        login_required(GoodEditDeleteView.as_view()),
        name="edit-delete-good",
    ),
    path(
        "product/good/<int:pk>/delete/",
        login_required(GoodDeleteView.as_view()),
        name="delete_good",
    ),
    path("product/news/", login_required(NewsListView.as_view()), name="news-list"),
    path(
        "product/news-create/",
        login_required(NewsCreateView.as_view()),
        name="news-create",
    ),
    path("users/", login_required(UserListView.as_view()), name="users-list"),
    path(
        "users/<int:pk>/order",
        login_required(UserOrdersView.as_view()),
        name="user-orders-list",
    ),
    path(
        "users/order-detail/<int:pk>/",
        login_required(UserOrderDetailView.as_view()),
        name="user-order-detail",
    ),
    path(
        "block_activate_user/<int:pk>/",
        login_required(BlockActivateUserView.as_view()),
        name="block_activate_user",
    ),
    path("orders/", login_required(OrdersListView.as_view()), name="all-orders-list"),
    path("other/news/", login_required(NewsListView.as_view()), name="news-list"),
    path(
        "other/news-create/",
        login_required(NewsCreateView.as_view()),
        name="news-create",
    ),
    path(
        "other/news/edit/<int:pk>/",
        login_required(NewsEditView.as_view()),
        name="edit_delete_news",
    ),
    path(
        "other/news/action/<int:pk>/",
        login_required(NewsActionView.as_view()),
        name="news-action",
    ),
    path(
        "other/news/send-push/<int:pk>/",
        login_required(NewsSendPushView.as_view()),
        name="news-send-push",
    ),
    path(
        "other/info/list/", login_required(InformationView.as_view()), name="info-list"
    ),
    path(
        "other/info/edit/<int:pk>/",
        login_required(InformationEditView.as_view()),
        name="edit_info",
    ),
    path(
        "other/service/list", login_required(ServiceView.as_view()), name="service-list"
    ),
    path(
        "other/service/edit/<int:pk>/",
        login_required(ServiceEditView.as_view()),
        name="edit_service",
    ),
    path(
        "other/banners/list/", login_required(BannerView.as_view()), name="banner-list"
    ),
    path(
        "other/banner/action/<int:pk>/",
        login_required(BannerActionView.as_view()),
        name="banner-action",
    ),
    path("orders/<int:pk>/", login_required(OrdersView.as_view()), name="orders-list"),
    path('orders/unpaid/', UnpaidOrdersListView.as_view(), name='unpaid-orders-list'),
    path('orders/payment_pending/', PaymentPendingOrdersListView.as_view(), name='payment-pending-orders'),
    path('orders/delete/<int:pk>/', delete_order, name='delete-order'),
    path(
        "update-order-status/<int:pk>/",
        login_required(update_order_status),
        name="update-order-status",
    ),
    path("bot/", index, name="bot"),
    # info
    path(
        "edit-reminder/<int:pk>/", login_required(edit_reminder), name="edit_reminder"
    ),
    path(
        "edit-agreement/<int:pk>/",
        login_required(edit_agreement),
        name="edit_agreement",
    ),
    path(
        "edit-shipment/<int:pk>/", login_required(edit_shipment), name="edit_shipment"
    ),
    path("edit-privacy/<int:pk>/", login_required(edit_privacy), name="edit_privacy"),
    path("edit-about_us/<int:pk>/", login_required(edit_aboutus), name="edit_aboutus"),
    path("edit-support/<int:pk>/", login_required(edit_support), name="edit_support"),
    path("edit-payment/<int:pk>/", login_required(edit_payment), name="edit_payment"),
    path(
        "bonus-edit/<int:pk>/",
        login_required(BonusEditView.as_view()),
        name="edit_bonus",
    ),
    path(
        "other/socialmedia/",
        login_required(SocialMediaListView.as_view()),
        name="socialmedia",
    ),
    path(
        "socialmedia-edit/<int:pk>/",
        login_required(SocialMediaEditView.as_view()),
        name="edit_media",
    ),
    path("base-info/", base_info, name="base_info"),

    path('loyalty/customers/', login_required(loyalty_customer_list), name='loyalty_customer_list'),
    path('loyalty/customer/<int:profile_id>/', login_required(loyalty_user_detail_view), name='loyalty_customer_detail'),
    path('loyalty/approve-bonus/<int:bonus_id>/', login_required(approve_bonus), name='approve_bonus'),
    path('loyalty/edit-card/<int:profile_id>/', login_required(edit_loyalty_card), name='edit_loyalty_card'),
    path('loyalty/pending-bonuses/', login_required(all_pending_bonuses), name='all_pending_bonuses'),
    path('loyalty/referrals/', login_required(all_referrals), name='referral_list'),
    path('loyalty/referrals/toggle/', login_required(toggle_referral_system), name='toggle_referral_system'),
    path('order-update-status/<int:pk>/', order_update_status, name='order-update-status'),
    path('b2b/applications/', b2b_applications_list, name='b2b-applications-list'),
    path('b2b/update-status/<int:pk>/', update_b2b_status, name='update-b2b-status'),
    path('b2b/delete/<int:pk>/', delete_b2b_application, name='delete-b2b-application'),

    # Bank Kartalari
    path('bank-cards/', BankCardListView.as_view(), name='bank-card-list'),
    path('bank-cards/create/', BankCardCreateView.as_view(), name='bank-card-create'),
    path('bank-cards/update/<int:pk>/', BankCardUpdateView.as_view(), name='bank-card-edit'),
    path('bank-cards/delete/<int:pk>/', BankCardDeleteView.as_view(), name='bank-card-delete'),

    # Yetkazib berish (Service)
    path('delivery-fees/', login_required(ServiceListView.as_view()), name='delivery-fee-list'),
    path('delivery-fees/create/', login_required(ServiceCreateView.as_view()), name='delivery-fee-create'),
    path('delivery-fees/update/<int:pk>/', login_required(ServiceUpdateView.as_view()), name='delivery-fee-edit'),
    path('delivery-fees/shipping-settings/', login_required(update_shipping_settings), name='update-shipping-settings'),

    # Buyurtma yakunlash bonusi (tier) sozlamalari
    path('bonus-tiers/', login_required(OrderBonusTierListView.as_view()), name='bonus-tier-list'),
    path('bonus-tiers/create/', login_required(OrderBonusTierCreateView.as_view()), name='bonus-tier-create'),
    path('bonus-tiers/update/<int:pk>/', login_required(OrderBonusTierUpdateView.as_view()), name='bonus-tier-edit'),
    path('bonus-tiers/delete/<int:pk>/', login_required(OrderBonusTierDeleteView.as_view()), name='bonus-tier-delete'),
    path('bonus-tiers/history/', login_required(OrderBonusHistoryListView.as_view()), name='bonus-tier-history'),

    # Telegram xabarnoma sozlamalari
    path('settings/telegram/', login_required(telegram_settings_view), name='telegram-settings'),
    path('settings/telegram/test/', login_required(telegram_test_action), name='telegram-test'),
    path('settings/telegram/toggle-buttons/', login_required(telegram_toggle_buttons_action), name='telegram-toggle-buttons'),

    # Push xabarnoma yozish (broadcast)
    path('settings/push/compose/', login_required(push_compose_view), name='push-compose'),

    path('users/delete/<int:pk>/', delete_user, name='delete-user'),
    path('dashboard/delete/<int:pk>/', delete_order_dash, name='delete_dashboard'),
    path('good/delete/<int:pk>/', delete_good, name='delete_good'),
    path('product/good/bulk-delete/', bulk_delete_goods, name='bulk_delete_goods'),
]
