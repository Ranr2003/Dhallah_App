import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/database_serv.dart';
import '../services/notification_serv.dart';

class MessageService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String myUid = FirebaseAuth.instance.currentUser?.uid ?? "";

  /// [initializeChatRoom]: تنشئ غرفة محادثة جديدة في Firestore وتخزن بيانات المشاركين والبلاغات المرتبطة.
  Future<void> initializeChatRoom({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required String reportId,
    required String receiverReportId,
    required String userName,
  }) async {
    final chatRoomRef = _db.collection('chat_rooms').doc(chatRoomId);
    final DatabaseService dbService = DatabaseService();
    final receiverData = await dbService.getUserById(receiverId);
    final senderData = await dbService.getUserById(senderId);

    await chatRoomRef.set({
      'participants': [senderId, receiverId],
      'timestamp': FieldValue.serverTimestamp(),
      'senderId': senderId,
      'senderName': senderData?.name ?? "مستخدم",
      'senderreportId': reportId,
      'receiverId': receiverId,
      'receiverName': receiverData?.name ?? userName,
      'receiverreportId': receiverReportId,
      'lastMessage': "",
    }, SetOptions(merge: true));
  }

  /// [markAsRead]: تصفّر عداد الرسائل غير المقروءة للمستخدم الحالي داخل غرفة محادثة محددة.
  Future<void> markAsRead(String chatRoomId) async {
    try {
      await _db
          .collection('chat_rooms')
          .doc(chatRoomId)
          .update({'unreadCount_$myUid': 0});
    } catch (e) {
      debugPrint("⚠️ تنبيه تصفير العداد: $e");
    }
  }

  /// [sendMessage]: ترسل رسالة جديدة، تحدث "آخر رسالة" في الغرفة، وتزيد عداد غير المقروء للمستلم.
  Future<void> sendMessage({
    required String chatRoomId,
    required String messageText,
    required String receiverId,
    required String senderName,
  }) async {
    await _db.collection('chat_rooms').doc(chatRoomId).update({
      'lastMessage': messageText,
      'lastSenderId': myUid,
      'timestamp': FieldValue.serverTimestamp(),
      'unreadCount_$receiverId': FieldValue.increment(1),
    });

    await _db
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add({
      'senderId': myUid,
      'receiverId': receiverId,
      'message': messageText,
      'timestamp': FieldValue.serverTimestamp(),
    });

  }

  /// [terminateConversation]: تحذف غرفة المحادثة وجميع رسائلها نهائياً، ويمكنها إغلاق البلاغات المرتبطة بها أيضاً.
  Future<void> terminateConversation({
    required String chatRoomId,
    required bool shouldCloseStatus,
    required String reportId,
    required String receiverReportId,
  }) async {
    try {
      final chatRef = _db.collection('chat_rooms').doc(chatRoomId);
      var messagesSnapshot = await chatRef.collection('messages').get();
      WriteBatch batch = _db.batch();

      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      if (shouldCloseStatus) {
        batch.update(
            _db.collection('reports').doc(reportId), {'status': 'closed'});
        batch.update(_db.collection('reports').doc(receiverReportId),
            {'status': 'closed'});
      }

      batch.delete(chatRef);
      await batch.commit();
      debugPrint("✅ تم حذف المحادثة والرسائل نهائياً");
    } catch (e) {
      debugPrint("❌ خطأ في إنهاء المحادثة و إغلاق البلاغ$e");
    }
  }

  /// [getMyReportType]: تحدد نوع بلاغ المستخدم الحالي (مفقود أم موجود) داخل المحادثة لعرض الواجهة المناسبة.
   Future<String?> getMyReportType({
    required String senderId,
    required String reportId,
    required String receiverReportId,
  }) async {
    try {
      String myReportId = (myUid == senderId) ? reportId : receiverReportId;
      DocumentSnapshot reportDoc =
      await _db.collection('reports').doc(myReportId).get();
      return reportDoc.exists ? reportDoc['type'] as String? : null;
    } catch (e) {
      return null;
    }
  }

  /// [startRoomListener]: تراقب الغرفة باستمرار لإغلاق صفحة الدردشة فوراً إذا قام الطرف الآخر بحذف المحادثة.
  StreamSubscription<DocumentSnapshot> startRoomListener({
    required String chatRoomId,
    required VoidCallback onRoomDeleted,
  }) {
    return _db
        .collection('chat_rooms')
        .doc(chatRoomId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) {
        onRoomDeleted();
      }
    });
  }

  /// [getMessages]: تجلب تدفقاً حياً (Stream) لجميع الرسائل داخل الغرفة مرتبة زمنياً.
  Stream<QuerySnapshot> getMessages(String chatRoomId) {
    return _db
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// [getChatRoomStream]: تجلب تدفقاً حياً لبيانات غرفة المحادثة (مثل أسماء الأطراف وحالة العدادات) لتحديث الواجهة لحظياً.
  Stream<DocumentSnapshot> getChatRoomStream(String chatRoomId) {
    return _db.collection('chat_rooms').doc(chatRoomId).snapshots();
  }
}