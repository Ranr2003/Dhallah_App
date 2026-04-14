import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String senderId;
  final String receiverId;
  final String messageText;
  final DateTime timestamp;
  final bool isRead;

  MessageModel({
    required this.senderId,
    required this.receiverId,
    required this.messageText,
    required this.timestamp,
    this.isRead = false,
  });

  // تحويل البيانات من JSON (Firebase) إلى Object (Flutter)
  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      messageText: map['messageText'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
    );
  }

  // تحويل الـ Object إلى Map لإرساله لـ Firebase
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'messageText': messageText,
      'timestamp': timestamp,
      'isRead': isRead,
    };
  }
}