import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String senderId;
  final String receiverId;
  final String messageText;
  final DateTime timestamp;
  final bool isRead;
  final String type; // 'text' or 'image'

  MessageModel({
    required this.senderId,
    required this.receiverId,
    required this.messageText,
    required this.timestamp,
    this.isRead = false,
    this.type = 'text',
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      messageText: map['messageText'] ?? '',
      // معالجة الـ Timestamp لتجنب الانهيار إذا كان فارغاً
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      type: map['type'] ?? 'text',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'messageText': messageText,
      'timestamp': FieldValue.serverTimestamp(), // يفضل استخدام وقت السيرفر
      'isRead': isRead,
      'type': type,
    };
  }
}