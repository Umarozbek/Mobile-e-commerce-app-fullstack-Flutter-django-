class BannerModel {
  final int? count;
  final String? next;
  final String? previous;
  final List<BannerItem>? results;

  BannerModel({
    this.count,
    this.next,
    this.previous,
    this.results,
  });

  /// API javobi: { "count", "next", "previous", "results": [ { "id", "created", "modified", "title", "image", "active" } ] }
  factory BannerModel.fromJson(Map<String, dynamic> json) {
    List<BannerItem>? results;
    if (json['results'] != null && json['results'] is List) {
      results = (json['results'] as List)
          .map((i) => BannerItem.fromJson(Map<String, dynamic>.from(i as Map)))
          .toList();
    }
    return BannerModel(
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
      'results': results?.map((e) => e.toJson()).toList(),
    };
  }
}

class BannerItem {
  final int? id;
  final DateTime? created;
  final DateTime? modified;
  final String? title;
  final String? image;
  final bool? active;
  /// Banner bosilganda ochiladigan link (API: link, url yoki title ichida URL)
  final String? link;

  BannerItem({
    this.id,
    this.created,
    this.modified,
    this.title,
    this.image,
    this.active,
    this.link,
  });

  /// Bosilganda ochiladigan URL: link maydoni yoki title agar URL bo'lsa
  String? get clickUrl {
    final l = link?.trim();
    if (l != null && l.isNotEmpty && _isValidUrl(l)) return l;
    final t = title?.trim();
    if (t != null && t.isNotEmpty && _isValidUrl(t)) return t;
    return null;
  }

  static bool _isValidUrl(String s) {
    return s.startsWith('http://') || s.startsWith('https://');
  }

  /// API element: { "id", "created", "modified", "title", "image", "active", "link" }
  factory BannerItem.fromJson(Map<String, dynamic> json) {
    DateTime? created;
    DateTime? modified;
    if (json['created'] != null) {
      try {
        created = DateTime.parse(json['created'].toString());
      } catch (_) {}
    }
    if (json['modified'] != null) {
      try {
        modified = DateTime.parse(json['modified'].toString());
      } catch (_) {}
    }
    return BannerItem(
      id: json['id'] is int ? json['id'] as int : null,
      created: created,
      modified: modified,
      title: json['title']?.toString(),
      image: json['image']?.toString(),
      active: json['active'] == true,
      link: (json['link'] ?? json['url'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created': created?.toIso8601String(),
      'modified': modified?.toIso8601String(),
      'title': title,
      'image': image,
      'active': active,
      'link': link,
    };
  }

  /// Rasm URL — HTTP bo'lsa Android uchun HTTPS ga o'giramiz (Render qo'llab-quvvatlaydi).
  String? get imageUrl {
    final url = image;
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://')) {
      return 'https://${url.substring(7)}';
    }
    return url;
  }
}