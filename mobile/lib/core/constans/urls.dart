class MainUrls {
  static const String categoryList = "product/categories/list/?page=1&page_size=30";
  static const String subCatsList = "product/subcats/list/";
  static const String goodsList = "product/goods/";
  static const String goodsSaleList = "product/goods/?page=1&page_size=30&is_discount=true";
  static const String goodsNewList = "product/new-goods/list/?page=1&page_size=30";
  static const String goodsTopList = "product/goods/?page=1&page_size=30&active=true";
  static const String phonesList = "product/phones/list/";
  static const String phonesSaleList = "product/sale-phones/list/";
  static const String phonesNewList = "product/new-phones/list/";
  static const String phonesTopList = "product/popular-phones/list/";
  static const String ticketsList = "product/tickets/list/";
  static const String ticketsSaleList = "product/sale-tickets/list/";
  static const String ticketsNewList = "product/new-tickets/list/";
  static const String ticketsTopList = "product/new-tickets/list/";
  static const String goodVariants ="product/good-variants/";
  static const String ticketVariants ="product/ticket-variants/";
  static const String phoneVariantsVariants ="product/phone-variants/";
  // Paginated favourites: /api/customer/favorite/list/?page=1&page_size=30
  static const String favoriteList = "customer/favorite/list/?page=1&page_size=30";
  static const String bonusList = "merchant/bonus-list/";
  static const String myLoyaltyCard = "merchant/my-loyalty-card/";
  static const String loyaltyHistory = "merchant/loyalty/history/";




  static const String favoriteCreate = "customer/favorite/create/";
  static const String favoriteDelete = "customer/favorite/delete/";
  static const String newsList = "customer/news/list/";
  // Notifications/News/Sales feed: supports optional ?type= filter (NEWS, SALE,
  // PROMOTION, ANNOUNCEMENT, PRODUCT, GENERAL). Backend already filters to
  // active + current start/end date range and sorts by priority DESC.
  static const String notificationsList = "customer/notifications/list/";
  // Single notification/news retrieve by id (for push notificationId lookups).
  static const String newsRetrieve = "customer/news/"; // + "$id/retrieve/"
  // FCM device token registration (multi-device). Body: {token, platform}.
  static const String deviceTokenRegister = "customer/device-token/register/";
  // FCM device token removal on logout. DELETE body: {token}.
  static const String deviceTokenRemove = "customer/device-token/";
  // Paginated banners: api/customer/banners/?page=1&page_size=30
  static const String bannerList = "customer/banners/?page=1&page_size=30";
  static const String search = "product/product-search/";
  static const String locations = "customer/location/list/";
  static const String banners = "customer/banners/";
  static const String singleNews ="customer/latest-unviewed-news/";
  static const String markSingleNewsAsRead ="customer/mark-news-as-viewed/";
  static const String login ="customer/login/";
  static const String updateToken = "customer/auth/token-to-jwt/";
  static const String verifyOtp = "customer/verify-otp/";
  static const String register ="customer/register/";

  static const String orderList  ="merchant/order/list";
  static const String information  ="merchant/information";
  static const String merchantItemCreate = "merchant/order-item/create/";
  static const String merchantItemList = "merchant/item/list/";
  static const String location  ="customer/location/";
  static const String locationsCreate  ="customer/location/create/";
  static const String merchantService  ="merchant/service/";
  static const String socialMedia  ="merchant/social-media-urls/";
  static const String merchantItem ="merchant/order-item/";
  static const String setPassword ="customer/set-password/";
  static const String profileCreate ="customer/profile/create/";
  static const String profileDelete ="customer/profile/delete/";
  static const String referralCode ="customer/referral-code/";
  static const String enterReferralCode ="customer/enter-referral-code/";
  static const String myBonus = "merchant/my-bonus/";
  static const String merchantCartManage = "merchant/cart/manage/";
  static const String merchantCartCheckout = "merchant/cart/checkout/";
  static const String merchantOrdersList = "merchant/orders/?page=1&page_size=20";
  static const String merchantOrder = "merchant/orders/"; // For single order: merchant/orders/{id}/
  static const String cartOrderList = "merchant/order/list/?status=in_cart";
  static const String uploadReceipt = "merchant/order/upload-receipt/";







  static const String b2bApply = 'customer/b2b/apply/';
  static const String b2bStatus = 'merchant/user/b2b-status/';
  static const String merchantCartUpdateQuantity = 'merchant/cart/update-quantity/';
}
