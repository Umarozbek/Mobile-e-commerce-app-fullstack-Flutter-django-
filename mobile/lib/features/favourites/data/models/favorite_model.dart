import '../../../home/data/models/product_model.dart';

class FavoriteResponse {
  final int? count;
  final String? next;
  final String? previous;
  final List<FavoriteItem>? results;

  FavoriteResponse({this.count, this.next, this.previous, this.results});

  factory FavoriteResponse.fromJson(Map<String, dynamic> json) {
    return FavoriteResponse(
      count: json['count'],
      next: json['next'],
      previous: json['previous'],
      results: json['results'] != null
          ? (json['results'] as List).map((i) => FavoriteItem.fromJson(i)).toList()
          : null,
    );
  }
}

/// Favourite list API dagi `product` obyekti (names, descriptions, prices, images).
class FavouriteProductDto {
  final int? id;
  final LocalizedData? names;
  final LocalizedData? descriptions;
  final Map<String, dynamic>? prices; // price, b2b_price, discount_price (yoki discount_percent eski API uchun)
  final List<String>? images;
  final String? productType;

  FavouriteProductDto({
    this.id,
    this.names,
    this.descriptions,
    this.prices,
    this.images,
    this.productType,
  });

  factory FavouriteProductDto.fromJson(Map<String, dynamic> json) {
    final namesJson = json['names'] as Map<String, dynamic>?;
    LocalizedData? names;
    if (namesJson != null) {
      names = LocalizedData(
        uz: namesJson['uz'],
        ru: namesJson['ru'],
        en: namesJson['en'],
        kr: namesJson['ko'] ?? namesJson['kr'],
      );
    }

    final descJson = json['descriptions'] as Map<String, dynamic>?;
    LocalizedData? descriptions;
    if (descJson != null) {
      descriptions = LocalizedData(
        uz: descJson['uz'],
        ru: descJson['ru'],
        en: descJson['en'],
        kr: descJson['ko'] ?? descJson['kr'],
      );
    }

    List<String>? images;
    if (json['images'] is List) {
      images = [];
      for (final item in (json['images'] as List)) {
        if (item is String) {
          images.add(item);
        } else if (item is Map && item['image'] != null) {
          images.add(item['image'].toString());
        }
      }
      if (images.isEmpty) {
        images = null;
      }
    }

    return FavouriteProductDto(
      id: json['id'],
      names: names,
      descriptions: descriptions,
      prices: json['prices'] as Map<String, dynamic>?,
      images: images,
      productType: json['product_type'],
    );
  }
}

class FavoriteItem {
  final int? id;
  final FavouriteProductDto? product;
  final String? created;
  final String? modified;
  final int? user;

  FavoriteItem({
    this.id,
    this.product,
    this.created,
    this.modified,
    this.user,
  });

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      id: json['id'],
      product: json['product'] != null
          ? FavouriteProductDto.fromJson(json['product'] as Map<String, dynamic>)
          : null,
      created: json['created'],
      modified: json['modified'],
      user: json['user'],
    );
  }
}
