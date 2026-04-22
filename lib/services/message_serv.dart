import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. إرسال رسالة جديدة
  Future<void> sendMessage(String receiverId, String messageText) async {
    try {
      final String currentUserId = _auth.currentUser!.uid;

      MessageModel newMessage = MessageModel(
        senderId: currentUserId,
        receiverId: receiverId,
        messageText: messageText,
        timestamp: DateTime.now(),
        isRead: false,
      );

      // تخزين الرسالة في مجموعة "messages"
      // ملاحظة: يفضل استخدام chatRoomId لترتيب الرسائل بين شخصين محددين
      List<String> ids = [currentUserId, receiverId];
      ids.sort(); // ترتيب المعرفات لضمان وجود ID موحد لغرفة الدردشة
      String chatRoomId = ids.join("_");

      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .add(newMessage.toMap());

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
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MessageModel.fromMap(doc.data());
      }).toList();
    });
  }

  // 3. جلب قائمة المحادثات الأخيرة (لشاشة الرسائل الرئيسية)
  // هذه الدالة ستحتاجها لعرض قائمة "سارة، فراس، خالد..."
  Stream<QuerySnapshot> getChatRooms() {
    return _firestore.collection('chat_rooms').snapshots();
  }
}