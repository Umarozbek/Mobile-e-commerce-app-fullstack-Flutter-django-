// 1. Asosiy javob (Response)
class CartOrderResponse {
  final int? count;
  final String? next;
  final String? previous;
  final List<CartOrderModel>? results;

  CartOrderResponse({
    this.count,
    this.next,
    this.previous,
    this.results,
  });

  factory CartOrderResponse.fromJson(Map<String, dynamic> json) {
    return CartOrderResponse(
      count: json['count'],
      next: json['next'],
      previous: json['previous'],
      results: json['results'] != null
          ? (json['results'] as List)
          .map((i) => CartOrderModel.fromJson(i))
          .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'next': next,
      'previous': previous,
      'results': results?.map((v) => v.toJson()).toList(),
    };
  }
}

// 2. Buyurtma obyekti (OrderResult)
class CartOrderModel {
  final int? id;
  final String? orderNumber;
  final String? status;
  final String? statusDisplay;
  final String? customerName;
  final String? totalAmount;  // JSONda string ("6150")
  final num? deliveryFee;  // JSONda raqam yoki string bo'lishi mumkin
  final String? bonusAmount;  // JSONda string ("0.00")
  final num? loyaltyPayment;  // JSONda raqam (0)
  final String? comment;
  final List<OrderProductItem>? productsDetails;
  final String? createdAt;

  CartOrderModel({
    this.id,
    this.orderNumber,
    this.status,
    this.statusDisplay,
    this.customerName,
    this.totalAmount,
    this.deliveryFee,
    this.bonusAmount,
    this.loyaltyPayment,
    this.comment,
    this.productsDetails,
    this.createdAt,
  });

  factory CartOrderModel.fromJson(Map<String, dynamic> json) {
    return CartOrderModel(
      id: json['id'],
      orderNumber: json['order_number'],
      status: json['status'],
      statusDisplay: json['status_display'],
      customerName: json['customer_name'],
      totalAmount: json['total_amount'],
      deliveryFee: CartOrderModel._parseNum(json['delivery_fee']),
      bonusAmount: json['bonus_amount'],
      loyaltyPayment: CartOrderModel._parseNum(json['loyalty_payment']),
      comment: json['comment'],
      productsDetails: json['products_details'] != null
          ? (json['products_details'] as List)
          .map((i) => OrderProductItem.fromJson(i))
          .toList()
          : [],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'status': status,
      'status_display': statusDisplay,
      'customer_name': customerName,
      'total_amount': totalAmount,
      'delivery_fee': deliveryFee,
      'bonus_amount': bonusAmount,
      'loyalty_payment': loyaltyPayment,
      'comment': comment,
      'products_details': productsDetails?.map((v) => v.toJson()).toList(),
      'created_at': createdAt,
    };
  }

  /// Har xil formatdagi raqamlarni (int, double, string) xavfsiz num ga o'girish
  static num? _parseNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) {
      return num.tryParse(value);
    }
    return null;
  }
}

// 3. Buyurtma ichidagi mahsulot (OrderProductItem)
class OrderProductItem {
  final int? id;
  final int? orderItemId;
  int? orderId;
  final int? productId; // Mahsulot yoki variant ID (cart-product matching uchun)

  final LocalizedData? names;
  int? quantity;
  final num? price;
  final num? totalPrice;
  final String? measure;
  final List<String>? images;
  final LocalizedData? descriptions;
  final num? bonus;
  bool? isAvailable;

  OrderProductItem({
    this.id,
    this.orderItemId,
    this.orderId,
    this.productId,
    this.names,
    this.quantity,
    this.price,
    this.totalPrice,
    this.measure,
    this.images,
    this.descriptions,
    this.bonus,
    this.isAvailable,
  });

  OrderProductItem copyWith({
    int? id,
    int? orderItemId,
    int? orderId,
    int? productId,
    LocalizedData? names,
    int? quantity,
    num? price,
    num? totalPrice,
    String? measure,
    List<String>? images,
    LocalizedData? descriptions,
    num? bonus,
    bool? isAvailable,
  }) {
    return OrderProductItem(
      id: id ?? this.id,
      orderItemId: orderItemId ?? this.orderItemId,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      names: names ?? this.names,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      totalPrice: totalPrice ?? this.totalPrice,
      measure: measure ?? this.measure,
      images: images ?? this.images,
      descriptions: descriptions ?? this.descriptions,
      bonus: bonus ?? this.bonus,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  factory OrderProductItem.fromJson(Map<String, dynamic> json) {
    return OrderProductItem(
      id: json['id'],
      orderItemId: json['order_item_id'],
      orderId: json['order_id'],
      productId: json['product_id'] ?? json['product'] ?? json['id'],
      names: _parseLocalizedNames(json),
      quantity: json['quantity'],
      price: json['price'],
      totalPrice: json['total_price'],
      measure: json['measure'],
      images: json['images'] != null
          ? (json['images'] as List).map((i) => i.toString()).toList()
          : [],
      descriptions: json['descriptions'] != null
          ? LocalizedData.fromJson(json['descriptions'])
          : null,
      bonus: json['bonus'],
      isAvailable: json['is_available'],
    );
  }

  /// API dan names obyekti yoki tekis name_uz/name_ru/name_en/keylaridan lokalizatsiya olish
  static LocalizedData? _parseLocalizedNames(Map<String, dynamic> json) {
    if (json['names'] != null && json['names'] is Map<String, dynamic>) {
      return LocalizedData.fromJson(json['names'] as Map<String, dynamic>);
    }
    final uz = json['name_uz'];
    final ru = json['name_ru'];
    final en = json['name_en'];
    final kr = json['name_kr'] ?? json['name_ko'];
    if (uz != null || ru != null || en != null || kr != null) {
      return LocalizedData(
        uz: uz?.toString(),
        ru: ru?.toString(),
        en: en?.toString(),
        kr: kr?.toString(),
      );
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_item_id': orderItemId,
      'order_id': orderId,
      'product_id': productId,
      'names': names?.toJson(),
      'quantity': quantity,
      'price': price,
      'total_price': totalPrice,
      'measure': measure,
      'images': images?.map((v) => v).toList(),
      'descriptions': descriptions?.toJson(),
      'bonus': bonus,
      'is_available': isAvailable,
    };
  }
}

// ---------------------------------------------------------
// QUYIDAGI KLASSLAR OLDINGI KODDAN QAYTA ISHLATILMOQDA
// (Lekin to'liq bo'lishi uchun bu yerga ham qo'shib qo'ydim)
// ---------------------------------------------------------

// 4. Tarjimalar (Names va Descriptions uchun)
class LocalizedData {
  final String? uz;
  final String? ru;
  final String? en;
  final String? kr;

  LocalizedData({this.uz, this.ru, this.en, this.kr});

  /// Joriy tilga mos matnni qaytaradi. Topilmasa fallback.
  String? byLocale(String langCode) {
    switch (langCode) {
      case 'uz': return uz ?? en ?? ru ?? kr;
      case 'ru': return ru ?? uz ?? en ?? kr;
      case 'en': return en ?? uz ?? ru ?? kr;
      case 'ko': return kr ?? en ?? uz ?? ru;
      default:   return uz ?? en ?? ru ?? kr;
    }
  }

  factory LocalizedData.fromJson(Map<String, dynamic> json) {
    return LocalizedData(
      uz: json['uz']?.toString(),
      ru: json['ru']?.toString(),
      en: json['en']?.toString(),
      kr: (json['kr'] ?? json['ko'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'uz': uz, 'ru': ru, 'en': en, 'kr': kr};
  }
}

// 5. Rasmlar (ProductImage)
class ProductImage {
  final int? id;
  final String? image;
  final bool? isMain;

  ProductImage({this.id, this.image, this.isMain});

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'],
      image: json['image'],
      isMain: json['is_main'], // Agar JSONda yo'q bo'lsa null bo'ladi
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'image': image, 'is_main': isMain};
  }
}