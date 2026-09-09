import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationModel {
  final int? id;
  final String? title;
  final String? message;
  final String? type;
  final bool? isRead;
  final String? createdAt;
  final String? image;
  final Map<String, dynamic>? data;

  NotificationModel({
    this.id,
    this.title,
    this.message,
    this.type,
    this.isRead,
    this.createdAt,
    this.image,
    this.data,
  });

  /// Create from Firebase RemoteMessage
  factory NotificationModel.fromRemoteMessage(RemoteMessage remoteMessage) {
    final notification = remoteMessage.notification;
    final data = remoteMessage.data;
    
    return NotificationModel(
      id: remoteMessage.messageId?.hashCode,
      title: notification?.title ?? data['title'],
      message: notification?.body ?? data['message'] ?? data['body'],
      type: data['type'] ?? 'system',
      isRead: false,
      createdAt: DateTime.now().toIso8601String(),
      image: notification?.android?.imageUrl ?? notification?.apple?.imageUrl ?? data['image'],
      data: data,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      message: json['message'] ?? json['body'],
      type: json['type'],
      isRead: json['is_read'] ?? json['isRead'] ?? false,
      createdAt: json['created_at'] ?? json['createdAt'],
      image: json['image'],
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'is_read': isRead,
      'created_at': createdAt,
      'image': image,
      'data': data,
    };
  }
}









