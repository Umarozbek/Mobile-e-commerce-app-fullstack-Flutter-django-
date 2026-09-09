class CategoryModel {
  final int? id;
  final String? name;
  final String? nameUz;
  final String? nameEn;
  final String? nameRu;
  final String? nameKr;
  final String? image;
  final int? parent;
  final bool? active;

  CategoryModel({
    this.id,
    this.name,
    this.nameUz,
    this.nameEn,
    this.nameRu,
    this.nameKr,
    this.image,
    this.parent,
    this.active,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final names = json['names'] is Map ? json['names'] as Map<String, dynamic> : null;
    return CategoryModel(
      id: json['id'],
      name: json['name'] ?? names?['uz'] ?? names?['en'] ?? names?['ru'],
      nameUz: json['name_uz'] ?? names?['uz'],
      nameEn: json['name_en'] ?? names?['en'],
      nameRu: json['name_ru'] ?? names?['ru'],
      nameKr: json['name_ko'] ?? names?['ko'],
      image: json['image']?.toString(),
      parent: json['parent'],
      active: json['active'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_uz': nameUz,
      'name_en': nameEn,
      'name_ru': nameRu,
      'name_kr': nameKr,
      'image': image,
      'parent': parent,
      'active': active,
    };
  }
}

/// Paginated category list response (count, next, previous, results).
class CategoryListResponse {
  final int? count;
  final String? next;
  final String? previous;
  final List<CategoryModel> results;

  CategoryListResponse({
    this.count,
    this.next,
    this.previous,
    this.results = const [],
  });

  factory CategoryListResponse.fromJson(Map<String, dynamic> json) {
    return CategoryListResponse(
      count: json['count'],
      next: json['next'],
      previous: json['previous'],
      results: json['results'] != null
          ? (json['results'] as List)
              .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}









