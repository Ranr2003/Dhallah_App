import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'database_serv.dart';

class MessageService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String myUid = FirebaseAuth.instance.currentUser?.uid ?? "";

  // 1. إنشاء أو تحديث بيانات غرفة المحادثة
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

    // جلب بيانات الطرفين لضمان وجود الأسماء
    final [senderData, receiverData] = await Future.wait([
      dbService.getUserById(senderId),
      dbService.getUserById(receiverId),
    ]);

    await chatRoomRef.set({
      'participants': [senderId, receiverId],
      'senderId': senderId,
      'senderName': senderData?.name ?? "مستخدم",
      'senderreportId': reportId,
      'receiverId': receiverId,
      'receiverName': receiverData?.name ?? userName,
      'receiverreportId': receiverReportId,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // 2. إرسال رسالة وتحديث بيانات الغرفة والعدادات
  Future<void> sendMessage({
    required String chatRoomId,
    required String messageText,
    required String receiverId,
    required String senderName,
  }) async {
    // تحديث بيانات الغرفة الرئيسية (للقائمة الخارجية)
    await _db.collection('chat_rooms').doc(chatRoomId).update({
      'lastMessage': messageText,
      'lastSenderId': myUid,
      'timestamp': FieldValue.serverTimestamp(),
      'unreadCount_$receiverId': FieldValue.increment(1), // عداد خاص بالمستلم
    });

    // إضافة الرسالة في المجموعة الفرعية
    await _db.collection('chat_rooms').doc(chatRoomId).collection('messages').add({
      'senderId': myUid,
      'receiverId': receiverId,
      'message': messageText,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // 3. تصفير العداد للمستخدم الحالي
  Future<void> markAsRead(String chatRoomId) async {
    try {
      await _db.collection('chat_rooms').doc(chatRoomId).update({
        'unreadCount_$myUid': 0,
      });
    } catch (e) {
      debugPrint("ℹ️ العداد صفر بالفعل أو الغرفة غير موجودة");
    }
  }

  // 4. إنهاء المحادثة (حذف الرسائل + إغلاق البلاغات)
  Future<void> terminateConversation({
    required String chatRoomId,
    required bool shouldCloseStatus,
    required String reportId,
    required String receiverReportId,
  }) async {
    try {
      WriteBatch batch = _db.batch();

      // حذف جميع الرسائل داخل الغرفة
      var messages = await _db.collection('chat_rooms').doc(chatRoomId).collection('messages').get();
      for (var doc in messages.docs) {
        batch.delete(doc.reference);
      }

      // إذا اختار المستخدم "نعم" (تم العثور)، نغلق البلاغات
      if (shouldCloseStatus) {
        batch.update(_db.collection('reports').doc(reportId), {'status': 'closed'});
        batch.update(_db.collection('reports').doc(receiverReportId), {'status': 'closed'});
      }

      // حذف الغرفة نفسها
      batch.delete(_db.collection('chat_rooms').doc(chatRoomId));

      await batch.commit();
    } catch (e) {
      debugPrint("❌ فشل إنهاء المحادثة: $e");
    }
  }

  // 5. الاستماع للرسائل (Stream)
  Stream<QuerySnapshot> getMessages(String chatRoomId) {
    return _db
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // 6. الاستماع لحالة الغرفة (لإغلاق الصفحة إذا حذفها الطرف الآخر)
  StreamSubscription<DocumentSnapshot> startRoomListener({
    required String chatRoomId,
    required VoidCallback onRoomDeleted,
  }) {
    return _db.collection('chat_rooms').doc(chatRoomId).snapshots().listen((snap) {
      if (!snap.exists) onRoomDeleted();
    });
  }

  // 7. جلب نوع بلاغ المستخدم (Lost/Found) لتحديد الصلاحيات
  Future<String?> getMyReportType({
    required String senderId,
    required String reportId,
    required String receiverReportId,
  }) async {
    String myReportId = (myUid == senderId) ? reportId : receiverReportId;
    var doc = await _db.collection('reports').doc(myReportId).get();
    return doc.exists ? doc['type'] as String? : null;
  }

  // 8. ستريم لبيانات الغرفة (لتحديث الـ UI)
  Stream<DocumentSnapshot> getChatRoomStream(String chatRoomId) {
    return _db.collection('chat_rooms').doc(chatRoomId).snapshots();
  }
}