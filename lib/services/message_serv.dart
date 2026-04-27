import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/database_serv.dart';

class MessageService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String myUid = FirebaseAuth.instance.currentUser?.uid ?? "";

  // ✅ تهيئة غرفة المحادثة
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

  // ✅ تصفير عداد الرسائل غير المقروءة
  Future<void> markAsRead(String chatRoomId) async {
    try {
      await _db
          .collection('chat_rooms')
          .doc(chatRoomId)
          .update({'unreadCount': 0});
    } catch (e) {
      debugPrint("⚠️ تنبيه تصفير العداد: $e");
    }
  }

  // ✅ إرسال رسالة
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
      'unreadCount': FieldValue.increment(1),
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

    await sendPushNotification(
      receiverId: receiverId,
      msg: messageText,
      senderName: senderName,
    );
  }

  // ✅ إرسال إشعار Push
  Future<void> sendPushNotification({
    required String receiverId,
    required String msg,
    required String senderName,
  }) async {
    try {
      DocumentSnapshot userDoc =
      await _db.collection('users').doc(receiverId).get();
      if (!userDoc.exists) return;

      String? receiverToken = userDoc.get('fcmToken');
      if (receiverToken == null) return;

      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=YOUR_SERVER_KEY_HERE',
        },
        body: jsonEncode({
          'notification': {
            'title': 'رسالة جديدة من $senderName',
            'body': msg,
            'sound': 'default',
          },
          'priority': 'high',
          'to': receiverToken,
        }),
      );
    } catch (e) {
      debugPrint("❌ خطأ في إرسال الإشعارات: $e");
    }
  }

  // ✅ و إنهاء المحادثة وحذف الرسائل
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

  // ✅ جلب نوع بلاغ المستخدم الحالي
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

  // ✅ مستمع غرفة المحادثة (للكشف عن حذفها)
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

  // ✅ Stream رسائل الغرفة
  Stream<QuerySnapshot> getMessages(String chatRoomId) {
    return _db
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // ✅ Stream بيانات الغرفة
  Stream<DocumentSnapshot> getChatRoomStream(String chatRoomId) {
    return _db.collection('chat_rooms').doc(chatRoomId).snapshots();
  }
}