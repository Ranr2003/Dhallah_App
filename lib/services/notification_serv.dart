import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // أضفنا هذا
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance; // أضفنا هذا

  // --- وظائف جديدة للـ Push Notifications ---

  // 1. الحصول على الـ Token الخاص بالجهاز وتخزينه
  Future<void> saveDeviceToken(String userId) async {
    String? token = await _fcm.getToken();
    if (token != null) {
      await _db.collection('users').doc(userId).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
      print("Token Saved: $token");
    }
  }

  // --- وظائفك القديمة مع تعديل بسيط ---

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

  // تعديل دالة إرسال الإشعار لتشمل الـ Push Notification مستقبلاً
  Future<void> sendNotification({
    required String receiverId,
    required String title,
    required String body,
    required String type,
  }) async {
    // 1. حفظ في قاعدة البيانات (كما هو)
    await _db.collection('notifications').add({
      'receiverId': receiverId,
      'title': title,
      'body': body,
      'type': type,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    // 2. هنا مستقبلاً سنستدعي Cloud Functions لإرسال التنبيه الفعلي للجوال
    // لأن إرسال Push Notification مباشرة من التطبيق لم يعد آمناً (Legacy API)
  }

  // ... باقي دوالك (markAsRead, markAllAsRead, notifyOnNewMatch) كما هي بدون تغيير

  Future<void> markAsRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({'isRead': true});
  }

  Future<void> markAllAsRead(String userId) async {
    var batch = _db.batch();
    var snapshots = await _db.collection('notifications')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false).get();
    for (var doc in snapshots.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}