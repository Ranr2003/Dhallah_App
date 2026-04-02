// 1. السطر الصحيح لاستدعاء مكتبة الفايربيس
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  // الآن سيعرف التطبيق معنى FirebaseFirestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendMessage(String receiverId, String receiverName, String message) async {
    final String currentUserId = "02";

    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join("_");

    // إضافة الرسالة
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add({
      'senderId': currentUserId,
      'receiverId': receiverId,
      'messageText': message,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('chat_rooms').doc(chatRoomId).set({
      'lastMessage': message,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'lastSenderId': currentUserId,
      'timestamp': FieldValue.serverTimestamp(),
      'unreadCount': FieldValue.increment(1),
    }, SetOptions(merge: true));

  }

  // دالة جلب الرسائل
  Stream<QuerySnapshot> getMessages(String chatRoomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
}