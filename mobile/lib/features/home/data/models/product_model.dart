// 1. Asosiy javob (Response) modeli
class ProductResponse {
  final int? count;
  final String? next;
  final String? previous;
  final List<ProductModel>? results;

  ProductResponse({
    this.count,
    this.next,
    this.previous,
    this.results,
  });

  /// API: { count, next, previous, results: [ { id, product_id, names, descriptions, prices, images, variants, is_favorite } ] }
  factory ProductResponse.fromJson(Map<String, dynamic> json) {
    List<ProductModel> results = [];
    if (json['results'] != null && json['results'] is List) {
      for (final i in json['results'] as List) {
        if (i is Map<String, dynamic>) {
          results.add(ProductModel.fromJson(i));
        } else if (i is Map) {
          results.add(ProductModel.fromJson(Map<String, dynamic>.from(i)));
        }
      }
    }
    return ProductResponse(
      count: json['count'] is int ? json['count'] as int : null,
      next: json['next']?.toString(),
      previous: json['previous']?.toString(),
      results: results,
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

// 2. Ro'yxatdagi har bir element (ProductResult)
class ProductModel {
  final int? id;
   bool? isFavorite;
  final ProductDetails? product;
  final LocalizedData? names;
  final LocalizedData? ingredientsDict;
  final String? name;
  final String? nameUz;
  final String? nameEn;
  final String? nameRu;
  final String? nameKr;
  final String? ingredients;
  final String? ingredientsUz;
  final String? ingredientsEn;
  final String? ingredientsRu;
  final String? ingredientsKr;
  final String? expireDate;
  final List<ProductVariant>? variants;

  ProductModel({
    this.id,
    this.isFavorite,
    this.product,
    this.names,
    this.ingredientsDict,
    this.name,
    this.nameUz,
    this.nameEn,
    this.nameRu,
    this.nameKr,
    this.ingredients,
    this.ingredientsUz,
    this.ingredientsEn,
    this.ingredientsRu,
    this.ingredientsKr,
    this.expireDate,
    this.variants,
  });

  /// Returns the effective product ID, preferring the internal `product` ID if available,
  /// otherwise falling back to the wrapper `id`.
  int get effectiveId => product?.id ?? id ?? 0;

  /// API: id, product_id, names {uz,ru,en,ko}, descriptions {uz,ru,en,ko},
  /// prices {price, discount_price, min_wholesale_quantity, b2b_price}, images [], variants [], is_favorite
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('product_id')) {
      final namesNode = json['names'] != null && json['names'] is Map
          ? LocalizedData.fromJson(Map<String, dynamic>.from(json['names'] as Map))
          : null;
      final prices = json['prices'] is Map ? Map<String, dynamic>.from(json['prices'] as Map) : null;
      final num? priceVal = _numFrom(prices?['price']);
      final num? oldPriceVal = _numFrom(prices?['old_price']);
      final num? discountPriceVal = _numFrom(prices?['discount_price']);
      final int? discountPercent = _intFrom(prices?['discount_percent']);
      final int? minWholesaleQty = _intFrom(prices?['min_wholesale_quantity']);
      String? newPrice;
      String? oldPrice;

      // 1) Asosiy mantiq: price va old_price dan foydalanamiz (backend misolidagi kabi).
      if (priceVal != null && priceVal > 0 && oldPriceVal != null && oldPriceVal > 0 && oldPriceVal != priceVal) {
        final num minVal = priceVal < oldPriceVal ? priceVal : oldPriceVal;
        final num maxVal = priceVal > oldPriceVal ? priceVal : oldPriceVal;
        newPrice = minVal.toString();
        oldPrice = maxVal.toString();
      }
      // 2) Agar old_price yo'q bo'lsa, price va discount_price juftligi bo'yicha aniqlaymiz
      else if (priceVal != null && priceVal > 0 && discountPriceVal != null && discountPriceVal > 0 && discountPriceVal != priceVal) {
        final num minVal = priceVal < discountPriceVal ? priceVal : discountPriceVal;
        final num maxVal = priceVal > discountPriceVal ? priceVal : discountPriceVal;
        newPrice = minVal.toString();
        oldPrice = maxVal.toString();
      }
      // 3) Fallback: discount_percent bo'yicha eski mantiq
      else if (discountPercent != null && discountPercent > 0 && priceVal != null && priceVal > 0) {
        newPrice = priceVal.toString();
        oldPrice = (priceVal / (1 - discountPercent / 100)).toStringAsFixed(0);
      } else {
        // 4) Hech qanday juftlik bo'lmasa – faqat bitta mavjud narxni asosiy qilib olamiz
        final num? base = priceVal ?? oldPriceVal ?? discountPriceVal;
        newPrice = base?.toString();
        oldPrice = null;
      }

      final num? b2bPriceVal = _numFrom(prices?['b2b_price']);

      final imagesRaw = json['images'];
      final List<ProductImage> imagesList = [];
      if (imagesRaw is List) {
        for (final i in imagesRaw) {
          if (i is String) {
            imagesList.add(ProductImage(image: i));
          } else if (i is Map) {
            imagesList.add(ProductImage.fromJson(Map<String, dynamic>.from(i)));
          }
        }
      }

      final variantsRaw = json['variants'];
      final List<ProductVariant> variantsList = [];
      if (variantsRaw is List) {
        for (final v in variantsRaw) {
          if (v is Map) {
            variantsList.add(ProductVariant.fromJson(Map<String, dynamic>.from(v)));
          }
        }
      }

      return ProductModel(
        id: json['id'] is int ? json['id'] as int : null,
        isFavorite: json['is_favorite'] == true,
        product: ProductDetails(
          id: json['product_id'] is int ? json['product_id'] as int : null,
          descriptions: json['descriptions'] != null && json['descriptions'] is Map
              ? LocalizedData.fromJson(Map<String, dynamic>.from(json['descriptions'] as Map))
              : null,
          newPrice: newPrice,
          oldPrice: oldPrice,
          price: priceVal,
          b2bPrice: b2bPriceVal,
          minWholesaleQuantity: minWholesaleQty,
          measure: _parseMeasure(json['measure']),
          availableQuantity: json['available_stock'] is int ? json['available_stock'] as int : null,
          images: imagesList,
        ),
        names: namesNode,
        nameUz: namesNode?.uz,
        nameEn: namesNode?.en,
        nameRu: namesNode?.ru,
        nameKr: namesNode?.kr,
        variants: variantsList,
      );
    }

    // Fallback: eski API strukturasi
    ProductDetails? fallbackProduct;
    if (json['product'] != null) {
      fallbackProduct = ProductDetails.fromJson(json['product']);
    } else if (json['images'] != null || json['price'] != null || json['product_type'] != null) {
      fallbackProduct = ProductDetails.fromJson(json);
    }

    return ProductModel(
      id: json['id'],
      isFavorite: json['is_favorite'],
      product: fallbackProduct,
      names: json['names'] != null ? LocalizedData.fromJson(json['names']) : null,
      ingredientsDict: json['ingredients_dict'] != null
          ? LocalizedData.fromJson(json['ingredients_dict'])
          : null,
      name: json['name'],
      nameUz: json['name_uz'],
      nameEn: json['name_en'],
      nameRu: json['name_ru'],
      nameKr: json['name_kr'],
      ingredients: json['ingredients'],
      ingredientsUz: json['ingredients_uz'],
      ingredientsEn: json['ingredients_en'],
      ingredientsRu: json['ingredients_ru'],
      ingredientsKr: json['ingredients_kr'],
      expireDate: json['expire_date'],
      variants: json['variants'] != null
          ? (json['variants'] as List).map((v) => ProductVariant.fromJson(v)).toList()
          : [],
    );
  }

  static num? _numFrom(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    return double.tryParse(v.toString());
  }

  static int? _intFrom(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static int _parseMeasure(dynamic measure) {
    if (measure is int) return measure;
    if (measure is String) {
      switch (measure.toUpperCase()) {
        case 'KG':
          return 0;
        case 'DONA':
          return 1;
        case 'L':
          return 2;
        case 'PAKET':
          return 3;
        default:
          return 0;
      }
    }
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'is_favorite': isFavorite,
      'product': product?.toJson(),
      'names': names?.toJson(),
      'ingredients_dict': ingredientsDict?.toJson(),
      'name': name,
      'name_uz': nameUz,
      'name_en': nameEn,
      'name_ru': nameRu,
      'name_kr': nameKr,
      'ingredients': ingredients,
      'ingredients_uz': ingredientsUz,
      'ingredients_en': ingredientsEn,
      'ingredients_ru': ingredientsRu,
      'ingredients_kr': ingredientsKr,
      'expire_date': expireDate,
    };
  }
}

// 3. Ichki mahsulot tafsilotlari (ProductDetails)
class ProductDetails {
  final int? id;
  final String? desc;
  final LocalizedData? descriptions;
  final String? productType;
  final String? oldPrice;
  final String? newPrice;
  final num? price;
  final num? b2bPrice;
  final int? minWholesaleQuantity;
  final int? sale;
  final num? weight;
  final int? measure;
  final int? availableQuantity;
  final int? bonus;
  final bool? main;
  final bool? active;
  final String? created;
  final String? modified;
  final List<ProductImage>? images;
  final ProductGoods? goods;

  ProductDetails({
    this.id,
    this.desc,
    this.descriptions,
    this.productType,
    this.oldPrice,
    this.newPrice,
    this.price,
    this.b2bPrice,
    this.minWholesaleQuantity,
    this.sale,
    this.weight,
    this.measure,
    this.availableQuantity,
    this.bonus,
    this.main,
    this.active,
    this.created,
    this.modified,
    // Konstruktorga qo'shildi
    this.images,
    this.goods,
  });

  factory ProductDetails.fromJson(Map<String, dynamic> json) {
    return ProductDetails(
      id: json['id'],
      desc: json['desc'],
      descriptions: json['descriptions'] != null
          ? LocalizedData.fromJson(json['descriptions'])
          : null,
      productType: json['product_type'],
      oldPrice: json['old_price'],
      newPrice: json['new_price'],
      price: json['price'],
      b2bPrice: json['b2b_price'],
      minWholesaleQuantity: json['min_wholesale_quantity'],
      sale: json['sale'],
      weight: json['weight'],
      measure: json['measure'],
      availableQuantity: json['available_quantity'],
      bonus: json['bonus'],
      main: json['main'],
      active: json['active'],
      created: json['created'],
      modified: json['modified'],
      // JSON parslash logikasi
      images: (json['images'] is List)
          ? (json['images'] as List).map((i) {
              if (i is String) return ProductImage(image: i);
              if (i is Map<String, dynamic>) return ProductImage.fromJson(i);
              if (i is Map) return ProductImage.fromJson(Map<String, dynamic>.from(i));
              return ProductImage(image: i?.toString());
            }).toList()
          : [],
      goods: json['goods'] != null ? ProductGoods.fromJson(json['goods']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'desc': desc,
      'descriptions': descriptions?.toJson(),
      'product_type': productType,
      'old_price': oldPrice,
      'new_price': newPrice,
      'price': price,
      'b2b_price': b2bPrice,
      'min_wholesale_quantity': minWholesaleQuantity,
      'sale': sale,
      'weight': weight,
      'measure': measure,
      'available_quantity': availableQuantity,
      'bonus': bonus,
      'main': main,
      'active': active,
      'created': created,
      'modified': modified,
      // JSONga qaytarish logikasi
      'images': images?.map((v) => v.toJson()).toList(),
      'goods': goods?.toJson(),
    };
  }
}

// Product Goods Model (nested in ProductDetails)
class ProductGoods {
  final int? id;
  final String? name;
  final String? nameUz;
  final String? nameEn;
  final String? nameRu;
  final String? nameKo;
  final String? ingredients;
  final String? ingredientsUz;
  final String? ingredientsEn;
  final String? ingredientsRu;
  final String? ingredientsKo;
  final String? expireDate;
  final int? product;
  final int? category;

  ProductGoods({
    this.id,
    this.name,
    this.nameUz,
    this.nameEn,
    this.nameRu,
    this.nameKo,
    this.ingredients,
    this.ingredientsUz,
    this.ingredientsEn,
    this.ingredientsRu,
    this.ingredientsKo,
    this.expireDate,
    this.product,
    this.category,
  });

  factory ProductGoods.fromJson(Map<String, dynamic> json) {
    return ProductGoods(
      id: json['id'],
      name: json['name'],
      nameUz: json['name_uz'],
      nameEn: json['name_en'],
      nameRu: json['name_ru'],
      nameKo: json['name_ko'],
      ingredients: json['ingredients'],
      ingredientsUz: json['ingredients_uz'],
      ingredientsEn: json['ingredients_en'],
      ingredientsRu: json['ingredients_ru'],
      ingredientsKo: json['ingredients_ko'],
      expireDate: json['expire_date'],
      product: json['product'],
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_uz': nameUz,
      'name_en': nameEn,
      'name_ru': nameRu,
      'name_ko': nameKo,
      'ingredients': ingredients,
      'ingredients_uz': ingredientsUz,
      'ingredients_en': ingredientsEn,
      'ingredients_ru': ingredientsRu,
      'ingredients_ko': ingredientsKo,
      'expire_date': expireDate,
      'product': product,
      'category': category,
    };
  }
}

// 4. Tarjimalar va lug'atlar uchun umumiy klass (LocalizedData)
class LocalizedData {
  final String? uz;
  final String? ru;
  final String? en;
  final String? kr;

  LocalizedData({
    this.uz,
    this.ru,
    this.en,
    this.kr,
  });

  /// Joriy tilga mos matnni qaytaradi. Topilmasa fallback: uz -> en -> birinchi mavjud.
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
      uz: json['uz'],
      ru: json['ru'],
      en: json['en'],
      kr: json['ko'] ?? json['kr'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uz': uz,
      'ru': ru,
      'en': en,
      'kr': kr,
    };
  }
}
class ProductImage {
  final int? id;
  final String? image;
  final String? name;

  ProductImage({this.id, this.image, this.name});

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    final imageVal = json['image'];
    String? imageUrl;
    if (imageVal is String) {
      imageUrl = imageVal;
    } else if (imageVal != null) {
      imageUrl = imageVal.toString();
    }
    return ProductImage(
      id: json['id'] is int ? json['id'] as int : null,
      image: imageUrl,
      name: json['name']?.toString(),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image': image,
      'name': name,
    };
  }
}

// Variant Prices Model
class VariantPrices {
  final num? retailNew;
  final num? retailOld;
  final num? b2bPrice;
  final num? salePercent;
  final int? minWholesaleQuantity;

  VariantPrices({
    this.retailNew,
    this.retailOld,
    this.b2bPrice,
    this.salePercent,
    this.minWholesaleQuantity,
  });

  factory VariantPrices.fromJson(Map<String, dynamic> json) {
    num? _toNum(dynamic v) {
      if (v == null) return null;
      if (v is num) return v;
      return double.tryParse(v.toString());
    }

    int? _toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    final num? priceVal = _toNum(json['price']);
    final num? oldPriceVal = _toNum(json['old_price']);
    final num? discountPriceVal = _toNum(json['discount_price']);

    num? retailNew;
    num? retailOld;

    // 1) Asosiy mantiq: price va old_price dan foydalanamiz (agar ikkalasi ham > 0 va turlicha bo'lsa)
    if (priceVal != null && priceVal > 0 && oldPriceVal != null && oldPriceVal > 0 && oldPriceVal != priceVal) {
      final num minVal = priceVal < oldPriceVal ? priceVal : oldPriceVal;
      final num maxVal = priceVal > oldPriceVal ? priceVal : oldPriceVal;
      retailNew = minVal;
      retailOld = maxVal;
    }
    // 2) Agar old_price yo'q bo'lsa, price va discount_price juftligi bo'yicha aniqlaymiz
    else if (priceVal != null && priceVal > 0 && discountPriceVal != null && discountPriceVal > 0 && discountPriceVal != priceVal) {
      final num minVal = priceVal < discountPriceVal ? priceVal : discountPriceVal;
      final num maxVal = priceVal > discountPriceVal ? priceVal : discountPriceVal;
      retailNew = minVal;
      retailOld = maxVal;
    } else {
      // 3) Fallback: eski mappinglar (agar faqat bitta qiymat bo'lsa)
      retailNew = _toNum(json['discount_price'] ?? json['retail_new'] ?? json['price']);
      retailOld = _toNum(json['price'] ?? json['retail_old'] ?? json['old_price']);
    }
    final num? b2b = _toNum(json['b2b_price']);
    final int? minQty = _toInt(json['min_wholesale_quantity']);

    return VariantPrices(
      retailNew: retailNew,
      retailOld: retailOld,
      b2bPrice: b2b,
      salePercent: _toNum(json['discount_percent'] ?? json['sale_percent']),
      minWholesaleQuantity: minQty,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'retail_new': retailNew,
      'retail_old': retailOld,
      'b2b_price': b2bPrice,
      'sale_percent': salePercent,
      'min_wholesale_quantity': minWholesaleQuantity,
    };
  }
}

// Product Variant Model
class ProductVariant {
  final int? id;
  final LocalizedData? names;
  final LocalizedData? descriptions;
  final VariantPrices? prices;
  final int? availableQuantity;
  final int? measure;
  final String? measureLabel;
  final int? bonus;
  final List<String>? images;
  final String? productType;
  final bool? main;

  ProductVariant({
    this.id,
    this.names,
    this.descriptions,
    this.prices,
    this.availableQuantity,
    this.measure,
    this.measureLabel,
    this.bonus,
    this.images,
    this.productType,
    this.main,
  });

  /// API: id, names {uz,ru,en,ko}, prices {price, b2b_price, discount_price, min_wholesale_quantity}, images []
  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    LocalizedData? names;
    if (json['names'] != null && json['names'] is Map) {
      names = LocalizedData.fromJson(Map<String, dynamic>.from(json['names'] as Map));
    }
    VariantPrices? prices;
    if (json['prices'] != null && json['prices'] is Map) {
      prices = VariantPrices.fromJson(Map<String, dynamic>.from(json['prices'] as Map));
    }
    List<String> imagesList = [];
    if (json['images'] is List) {
      for (final e in json['images'] as List) {
        if (e is String) {
          imagesList.add(e);
        } else if (e is Map && e['image'] != null) {
          imagesList.add(e['image'].toString());
        }
      }
    }
    return ProductVariant(
      id: json['id'] is int ? json['id'] as int : null,
      names: names,
      descriptions: json['descriptions'] != null && json['descriptions'] is Map
          ? LocalizedData.fromJson(Map<String, dynamic>.from(json['descriptions'] as Map))
          : null,
      prices: prices,
      availableQuantity: json['available_quantity'] is int ? json['available_quantity'] as int : null,
      measure: json['measure'] is int ? json['measure'] as int : null,
      measureLabel: json['measure_label']?.toString(),
      bonus: json['bonus'] is int ? json['bonus'] as int : null,
      images: imagesList.isEmpty ? null : imagesList,
      productType: json['product_type']?.toString(),
      main: json['main'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'names': names?.toJson(),
      'descriptions': descriptions?.toJson(),
      'prices': prices?.toJson(),
      'available_quantity': availableQuantity,
      'measure': measure,
      'measure_label': measureLabel,
      'bonus': bonus,
      'images': images,
      'product_type': productType,
      'main': main,
    };
  }
}

/// Turli strukturalardagi mahsulot ma'lumotlaridan yagona `List<ProductModel>` olish uchun yordamchi funksiya.
///
/// Qo'llab-quvvatlanadigan formatlar:
/// - `ProductResponse`
/// - `List<ProductModel>` yoki `List<Map>`
/// - `Map` ichida `results` / `data` / `products` ro'yxatlari
List<ProductModel> extractProducts(dynamic productsData) {
  if (productsData == null) return [];

  List<dynamic> list = [];

  if (productsData is ProductResponse) {
    list = productsData.results ?? [];
  } else if (productsData is List) {
    list = productsData;
  } else if (productsData is Map) {
    if (productsData['results'] is List) {
      list = productsData['results'] as List;
    } else if (productsData['data'] is List) {
      list = productsData['data'] as List;
    } else if (productsData['products'] is List) {
      list = productsData['products'] as List;
    }
  }

  return list.map((item) {
    if (item is ProductModel) return item;
    if (item is Map<String, dynamic>) {
      try {
        return ProductModel.fromJson(item);
      } catch (_) {
        return null;
      }
    }
    if (item is Map) {
      try {
        return ProductModel.fromJson(Map<String, dynamic>.from(item));
      } catch (_) {
        return null;
      }
    }
    return null;
  }).whereType<ProductModel>().toList();
}