import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // جلب الـ ID الخاص بالمستخدم المسجل حالياً
  String? get currentUserId => _auth.currentUser?.uid;

  Future<void> sendMessage(String receiverId, String receiverName, String message) async {
    // التأكد أن المستخدم مسجل دخول
    if (currentUserId == null) return;

    // بناء معرف الغرفة (دائماً مرتب أبجدياً لضمان عدم التكرار)
    List<String> ids = [currentUserId!, receiverId];
    ids.sort();
    String chatRoomId = ids.join("_");

    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add({
      'participants': [currentUserId, receiverId],
      'senderId': currentUserId,
      'receiverId': receiverId,
      'messageText': message,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('chat_rooms').doc(chatRoomId).set({
      'lastMessage': message,
      'lastSenderId': currentUserId,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'timestamp': FieldValue.serverTimestamp(),
      'unreadCount': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  // دالة لتصفير العداد عند قراءة الرسائل
  Future<void> markAsRead(String chatRoomId) async {
    try {
      await _firestore.collection('chat_rooms').doc(chatRoomId).update({
        'unreadCount': 0,
      });
    } catch (e) {
      print("خطأ أثناء تحديث حالة القراءة: $e");
    }
  }
}