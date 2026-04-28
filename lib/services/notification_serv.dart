import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // 1. حفظ توكن الجهاز
  Future<void> saveDeviceToken(String userId) async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        await _db.collection('users').doc(userId).set({
          'fcmToken': token,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print("Error saving token: $e");
    }
  }

  // 2. جلب الإشعارات (مع معالجة خطأ الترتيب المحتمل)
  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('receiverId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // 3. دالة جديدة: جلب عدد الإشعارات غير المقروءة (للنقطة الحمراء)
  Stream<int> getUnreadCount(String userId) {
    return _db
        .collection('notifications')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // 4. إرسال الإشعار مع منع التكرار (تعديلك الذكي)
  Future<void> sendNotification({
    required String receiverId,
    required String title,
    required String body,
    required String type,
    String? reportId,
  }) async {
    try {
      // التحقق من التكرار في حال كان تطابق
      if (type == 'match' && reportId != null) {
        var existing = await _db
            .collection('notifications')
            .where('receiverId', isEqualTo: receiverId)
            .where('reportId', isEqualTo: reportId)
            .where('type', isEqualTo: 'match')
            .limit(1)
            .get();

        if (existing.docs.isNotEmpty) {
          return;
        }
      }

      // إضافة الإشعار
      await _db.collection('notifications').add({
        'receiverId': receiverId,
        'reportId': reportId,
        'title': title,
        'body': body,
        'type': type,
        'createdAt': FieldValue.serverTimestamp(), // الوقت من السيرفر
        'isRead': false,
      });
    } catch (e) {
      print("Error sending notification: $e");
    }
  }

  // 5. تحديث الحالة كمقروء
  Future<void> markAsRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({'isRead': true});
  }

  // 6. تحديث الكل كمقروء (باستخدام Batch لأداء أسرع)
  Future<void> markAllAsRead(String userId) async {
    var snapshots = await _db
        .collection('notifications')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    if (snapshots.docs.isEmpty) return;

    var batch = _db.batch();
    for (var doc in snapshots.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
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



}