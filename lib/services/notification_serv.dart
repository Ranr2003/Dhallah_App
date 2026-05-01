import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  /// [saveDeviceToken]: تجلب رمز الجهاز (FCM Token) من جوجل وتحفظه في حساب المستخدم بـ Firestore لمراسلته لاحقاً.
  Future<void> saveDeviceToken() async {
    try {
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      String? token = await _fcm.getToken();

      if (token != null) {
        await _db.collection('users').doc(uid).set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print("✅ تم حفظ التوكن بنجاح: $token");
      }
    } catch (e) {
      print("❌ خطأ في حفظ التوكن: $e");
    }
  }

  /// [deleteDeviceToken]: تحذف رمز الجهاز من قاعدة البيانات وتُبطله من جهاز المستخدم عند تسجيل الخروج للأمان.
  Future<void> deleteDeviceToken() async {
    try {
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      
      // 1. حذف التوكن من Firestore أولاً لقطع الصلة في السيرفر
      if (uid != null) {
        await _db.collection('users').doc(uid).update({
          'fcmToken': FieldValue.delete(),
        });
      }

      // 2. إبطال التوكن من FCM على الجهاز
      await _fcm.deleteToken();
      print("✅ تم حذف وإبطال التوكن بنجاح");
    } catch (e) {
      print("❌ خطأ في حذف التوكن: $e");
    }
  }

  /// [setupForegroundNotifications]: تهيئ إعدادات ظهور الإشعار كـ "تنبيه علوي" عندما يكون المستخدم فاتحاً للتطبيق.
  void setupTokenListeners() {
    _fcm.onTokenRefresh.listen((newToken) {
      saveDeviceToken();
    });
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
              channel.id, channel.name,
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

  /// [setupChatNotifications]: تراقب غرف الدردشة في Firestore؛ إذا وصلت رسالة جديدة ولم تُقرأ، تُظهر إشعاراً محلياً للمستخدم.
  void setupChatNotifications(String userId) {
    FirebaseFirestore.instance
        .collection('chat_rooms')
        .where('participants', arrayContains: userId)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          var data = change.doc.data() as Map<String, dynamic>;
          String lastSenderId = data['lastSenderId'] ?? '';
          String lastMessage = data['lastMessage'] ?? '';
          
          // ✅ تم التعديل هنا ليتوافق مع حقل عداد الرسائل الخاص بكل مستخدم
          int unreadCount = (data['unreadCount_$userId'] ?? 0).toInt();

          if (lastSenderId != userId && unreadCount > 0 && lastMessage.isNotEmpty) {
            String correctSenderName = (lastSenderId == data['senderId'])
                ? (data['senderName'] ?? '')
                : (data['receiverName'] ?? '');

            flutterLocalNotificationsPlugin.show(
              change.doc.id.hashCode,
              "رسالة جديدة من $correctSenderName",
              lastMessage,
              NotificationDetails(
                android: AndroidNotificationDetails(
                  channel.id, channel.name,
                  channelDescription: channel.description,
                  importance: Importance.max,
                  priority: Priority.high,
                  icon: '@mipmap/ic_launcher',
                ),
              ),
            );
          }
        }
      }
    });
  }


  /// [sendMatchNotification]: تمر على مصفوفة التطابقات وترسل إشعاراً منفصلاً لكل تقرير جديد لم يسبق التنبيه عنه.
  /// [sendMatchNotification]: تُرسل تنبيهاً واحداً فقط عند اكتشاف عناصر جديدة في مصفوفة التطابقات.
  Future<void> sendMatchNotification({
    required String userId,
    required String reportId,
    required String category,
    required List<String> currentMatchIds,
  }) async {
    try {
      print("==============");
      print("🚀 دخلت sendMatchNotification");

      // 1. تنظيف القائمة
      List<String> validMatchIds = currentMatchIds
          .where((id) => id != "null" && id.isNotEmpty)
          .toList();

      print("📌 validMatchIds: $validMatchIds");

      if (validMatchIds.isEmpty) {
        print("❌ القائمة فارغة، تم الإيقاف");
        return;
      }

      // 2. إنشاء مرجع الإشعار
      DocumentReference notifRef =
      _db.collection('notifications').doc("match_notif_$reportId");

      print("📄 notification doc id: match_notif_$reportId");

      // 3. فحص هل المستند موجود
      var lastNotification = await notifRef.get();

      print("📥 notification exists: ${lastNotification.exists}");

      if (lastNotification.exists) {
        var lastData = lastNotification.data() as Map<String, dynamic>;

        List<String> lastNotifiedIds =
        List<String>.from(lastData['notifiedMatchIds'] ?? []);

        print("📌 lastNotifiedIds: $lastNotifiedIds");

        List<String> newMatches = validMatchIds.where((id) {
          return !lastNotifiedIds.contains(id);
        }).toList();

        print("🆕 newMatches: $newMatches");

        if (newMatches.isEmpty) {
          print("🚫 لا توجد تطابقات جديدة → إيقاف");
          return;
        }

        print("✨ يوجد تطابقات جديدة → سيتم إرسال إشعار");
      }

      print("💾 سيتم حفظ الإشعار الآن...");

      // 4. حفظ الإشعار في Firestore
      await notifRef.set({
        'receiverId': userId,
        'reportId': reportId,

        // مهم جدًا لصفحة الإشعارات
        'title': "تطابق جديد لبلاغ $category ✨",
        'body': "وجدنا نتائج جديدة تطابق مواصفات بلاغك، تفقدها الآن.",

        'notifiedMatchIds': validMatchIds,
        'type': 'match',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      }, SetOptions(merge: true));

      print("✅ تم حفظ الإشعار في Firestore بنجاح");

      // 5. إظهار Local Notification
      int notificationId = reportId.hashCode;

      await flutterLocalNotificationsPlugin.show(
        notificationId,
        "تطابق جديد لبلاغ $category ✨",
        "وجدنا نتائج جديدة تطابق مواصفات بلاغك، تفقدها الآن.",
        NotificationDetails(
          android: AndroidNotificationDetails(
            'matches_channel_id',
            'Matches Notifications',
            importance: Importance.max,
            priority: Priority.high,
            groupKey: 'com.dhallah.MATCHES_GROUP',
          ),
        ),
      );

      print("🔔 تم إظهار الإشعار المحلي");
      print("==============");
    } catch (e, stackTrace) {
      print("❌ خطأ داخل sendMatchNotification");
      print(e);
      print(stackTrace);
    }
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

}
