import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String receiverId; // معرف المستلم
  final String title;
  final String body;
  final DateTime createdAt;
  final String type; // مثلاً: 'match', 'message', 'system'
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.receiverId,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.type,
    this.isRead = false,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      isRead: map['isRead'] ?? false,
      type: map['type'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(), receiverId: '',
    );
  }
}