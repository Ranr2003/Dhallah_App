import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'إشعارات ضالة الهامة',
  description: 'هذه القناة تستخدم لإشعارات الدردشة والمطابقة',
  importance: Importance.max,
);


final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();


class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  /// ... (إعدادات الـ Singleton)  /// [requestPermissions]: تطلب الإذن من المستخدم لإظهار الإشعارات (تنبيه، صوت، شارة).
  Future<void> requestPermissions() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ تم منح الإذن من قبل المستخدم');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('⚠️ تم منح إذن مؤقت');
    } else {
      print('❌ رفض المستخدم منح الإذن');
    }
  }

  /// [setupForegroundNotifications]: تهيئ إعدادات ظهور الإشعار كـ "تنبيه علوي" عندما يكون المستخدم فاتحاً للتطبيق.
  void setupForegroundNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        print("تم الضغط على الإشعار: ${details.payload}");
      },
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });
  }

  /// [getNotifications]: تجلب قائمة بجميع إشعارات المستخدم (رسائل، تطابقات) مرتبة من الأحدث للأقدم.
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

  /// [getUnreadCount]: تحسب عدد الإشعارات غير المقروءة لعرضها كرقم (Badge) فوق أيقونة الجرس.
  Stream<int> getUnreadCount(String userId) {
    return _db
        .collection('notifications')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// [markAsRead]: تحول حالة إشعار معين إلى "مقروء" عند الضغط عليه.
  Future<void> markAsRead(String notificationId) async {
    await _db
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  /// [markAllAsRead]: تحول جميع إشعارات المستخدم إلى "مقروءة" دفعة واحدة (مثلاً عند فتح صفحة التنبيهات).
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
  /// داله جديده لزر حذف الاشعارات ///
  Future<void> clearAllNotifications(String userId) async {
    var snapshots = await _db.collection('notifications')
        .where('receiverId', isEqualTo: userId)
        .get();

    for (var doc in snapshots.docs) {
      await doc.reference.delete();
    }
  }
}