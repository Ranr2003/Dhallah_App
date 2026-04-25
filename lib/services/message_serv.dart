import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';
import 'notification_serv.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. إرسال رسالة جديدة
  Future<void> sendMessage(String receiverId, String messageText) async {
    try {
      final String currentUserId = _auth.currentUser!.uid;

      // 1. جلب اسم المرسل (أنتِ) من مجموعة users في الفايربيس
      final senderDoc = await _firestore.collection('users').doc(currentUserId).get();
      String senderName = senderDoc.data()?['name'] ?? "مستخدم";

      MessageModel newMessage = MessageModel(
        senderId: currentUserId,
        receiverId: receiverId,
        messageText: messageText,
        timestamp: DateTime.now(),
        isRead: false,
      );

      // 2. بناء معرف الغرفة الموحد
      List<String> ids = [currentUserId, receiverId];
      ids.sort();
      String chatRoomId = ids.join("_");

      // 3. تخزين الرسالة في Firestore
      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .add(newMessage.toMap());

      // 4. إرسال الإشعار للمستلم مع اسم المرسل الحقيقي
      await NotificationService().sendNotification(
        receiverId: receiverId,
        title: "رسالة من $senderName 💬",
        body: messageText,
        type: "chat",
      );

      print("تم إرسال الرسالة والإشعار بنجاح من $senderName");

    } catch (e) {
      print("Error sending message: $e");
    }
  }

  // 2. استقبال الرسائل (Stream) لتحديث الشاشة تلقائياً
  Stream<List<MessageModel>> getMessages(String userId, String otherUserId) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join("_");

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MessageModel.fromMap(doc.data());
      }).toList();
    });
  }

  // 3. جلب قائمة المحادثات الأخيرة (لشاشة الرسائل الرئيسية)
  Stream<QuerySnapshot> getChatRooms() {
    return _firestore.collection('chat_rooms').snapshots();
  }
}