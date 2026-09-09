import 'package:firebase_messaging/firebase_messaging.dart';

/// Data-only push announcement: dialog ko'rsatish uchun (notification bo'lib chiqmaydi).
///
/// Backend FCM payload (faqat `data`, `notification` bo'lmasin):
/// ```json
/// {
///   "data": {
///     "action": "announcement",
///     "id": "unique_id_123",
///     "title": "Sarlavha",
///     "body": "Matn yoki HTML",
///     "image": "https://..."
///   }
/// }
/// ```
class AnnouncementData {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final Map<String, dynamic>? rawData;

  AnnouncementData({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    this.rawData,
  });

  /// FCM data payload dan (action: "announcement")
  factory AnnouncementData.fromRemoteMessage(RemoteMessage message) {
    final data = message.data;
    return AnnouncementData(
      id: (data['id'] ?? message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString()).toString(),
      title: (data['title'] ?? data['heading'] ?? '').toString(),
      body: (data['body'] ?? data['message'] ?? data['content'] ?? '').toString(),
      imageUrl: data['image']?.toString() ?? data['image_url']?.toString(),
      rawData: data,
    );
  }

  /// Local storage (GetStorage) dan
  factory AnnouncementData.fromJson(Map<String, dynamic> json) {
    return AnnouncementData(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? json['message'] ?? '').toString(),
      imageUrl: json['image_url']?.toString(),
      rawData: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      if (imageUrl != null) 'image_url': imageUrl,
      ...?rawData,
    };
  }
}
