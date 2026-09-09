class NewsResponseModel {
  final int count;
  final String? next;
  final String? previous;
  final List<NewsModel> results;

  NewsResponseModel({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory NewsResponseModel.fromJson(Map<String, dynamic> json) {
    return NewsResponseModel(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results: (json['results'] as List?)
              ?.map((e) => NewsModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class NewsModel {
  final int id;
  final String created;
  final String modified;
  final String title;
  final String? titleUz;
  final String? titleEn;
  final String? titleRu;
  final String? titleKr;
  final String startDate;
  final String endDate;
  final String description;
  final String? descriptionUz;
  final String? descriptionEn;
  final String? descriptionRu;
  final String? descriptionKr;
  final String? image;
  final bool active;
  /// Ixtiyoriy havola: tashqi URL (https://...) yoki ichki route. Backendda
  /// erkin matn sifatida saqlanadi (aniq ichki-route konvensiyasi yo'q).
  final String? link;
  /// NEWS, SALE, PROMOTION, ANNOUNCEMENT, PRODUCT yoki GENERAL (backend enum).
  final String? type;
  /// Yuqori raqam = yuqori ustuvorlik (backend priority DESC tartiblaydi).
  final int priority;

  NewsModel({
    required this.id,
    required this.created,
    required this.modified,
    required this.title,
    this.titleUz,
    this.titleEn,
    this.titleRu,
    this.titleKr,
    required this.startDate,
    required this.endDate,
    required this.description,
    this.descriptionUz,
    this.descriptionEn,
    this.descriptionRu,
    this.descriptionKr,
    this.image,
    required this.active,
    this.link,
    this.type,
    this.priority = 0,
  });

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      id: json['id'],
      created: json['created'] ?? '',
      modified: json['modified'] ?? '',
      title: json['title'] ?? '',
      titleUz: json['title_uz'],
      titleEn: json['title_en'],
      titleRu: json['title_ru'],
      titleKr: json['title_kr'] ?? json['title_ko'],
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      description: json['description'] ?? '',
      descriptionUz: json['description_uz'],
      descriptionEn: json['description_en'],
      descriptionRu: json['description_ru'],
      descriptionKr: json['description_kr'] ?? json['description_ko'],
      image: json['image'],
      active: json['active'] ?? false,
      link: json['link'],
      type: json['type'],
      priority: json['priority'] is int
          ? json['priority']
          : int.tryParse(json['priority']?.toString() ?? '0') ?? 0,
    );
  }

  /// Backend `type` enumini (NEWS/SALE/PROMOTION/ANNOUNCEMENT/PRODUCT/GENERAL)
  /// tarjima kalitiga moslaydi. Noma'lum/bo'sh qiymat uchun umumiy belgi.
  String get typeLabelKey {
    switch (type) {
      case 'NEWS':
        return 'news_type_news';
      case 'SALE':
        return 'news_type_sale';
      case 'PROMOTION':
        return 'news_type_promotion';
      case 'ANNOUNCEMENT':
        return 'news_type_announcement';
      case 'PRODUCT':
        return 'news_type_product';
      default:
        return 'news_type_general';
    }
  }
}
