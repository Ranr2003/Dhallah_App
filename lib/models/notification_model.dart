import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String receiverId; // معرف المستلم
  final String title;
  final String body;
  final DateTime createdAt;
  final String type;
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

  factory NotificationModel.fromMap(Map<String, dynamic> map, String documentId) {
    return NotificationModel(
      id: documentId,
      receiverId: map['receiverId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: map['type'] ?? 'system',
      isRead: map['isRead'] ?? false,
    );
  }
}