

import '../../../home/data/models/product_model.dart';

class SearchModel {
  final List<dynamic> tickets;
  final List<dynamic> phones;
  final List<ProductModel> goods;

  SearchModel({
    required this.tickets,
    required this.phones,
    required this.goods,
  });

  factory SearchModel.fromJson(Map<String, dynamic> json) {
    return SearchModel(
      tickets: json['tickets'] ?? [],
      phones: json['phones'] ?? [],
      goods: (json['goods'] as List)
          .map((i) => ProductModel.fromJson(i))
          .toList(),
    );
  }
}


