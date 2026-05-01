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

  /// [saveDeviceToken]: تحفظ التوكن لأول مرة فقط؛ إذا وجد توكن مخزن مسبقاً لا تقم بتحديثه نهائياً.
  Future<void> saveDeviceToken() async {
    try {
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // 1. التحقق أولاً من وجود مستند للمستخدم وتوفر توكن فيه
      DocumentSnapshot userDoc = await _db.collection('users').doc(uid).get();

      if (userDoc.exists && userDoc.data() != null) {
        var data = userDoc.data() as Map<String, dynamic>;
        // إذا كان حقل fcmToken موجوداً (مهما كانت قيمته)، نتوقف فوراً ولا نحدثه
        if (data.containsKey('fcmToken') && data['fcmToken'] != null) {
          print("ℹ️ تم العثور على توكن سابق، لن يتم التحديث بناءً على تفضيلاتك.");
          return;
        }
      }

      // 2. إذا لم يوجد توكن نهائياً، نقوم بجلبه وحفظه لأول مرة
      String? newToken = await _fcm.getToken();
      if (newToken != null) {
        await _db.collection('users').doc(uid).set({
          'fcmToken': newToken,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print("✅ تم حفظ التوكن لأول مرة بنجاح.");
      }

    } catch (e) {
      print("❌ خطأ في عملية حفظ التوكن: $e");
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

  /// DELETE [setupChatNotifications]: تراقب غرف الدردشة في Firestore؛ إذا وصلت رسالة جديدة ولم تُقرأ، تُظهر إشعاراً محلياً للمستخدم.



  /// [sendMatchNotification]: تمر على مصفوفة التطابقات وترسل إشعاراً منفصلاً لكل تقرير جديد لم يسبق التنبيه عنه.
  /// [sendMatchNotification]: تُرسل تنبيهاً واحداً فقط عند اكتشاف عناصر جديدة في مصفوفة التطابقات.
  Future<void> sendMatchNotification({
    required String userId,
    required String reportId,
    required String category,
    required List<String> currentMatchIds,
  }) async {
    // 1. جلب جميع الـ IDs التي تم التنبيه عنها مسبقاً لهذا البلاغ
    var notifiedDocs = await _db.collection('notifications')
        .where('receiverId', isEqualTo: userId)
        .where('reportId', isEqualTo: reportId)
        .where('type', isEqualTo: 'match')
        .get();

    Set<String> alreadyNotifiedIds = {};
    for (var doc in notifiedDocs.docs) {
      var data = doc.data();
      if (data['notifiedMatchIds'] != null) {
        alreadyNotifiedIds.addAll(List<String>.from(data['notifiedMatchIds']));
      }
      if (data['matchedReportId'] != null) {
        alreadyNotifiedIds.add(data['matchedReportId'] as String);
      }
    }

    // 2. تصفية القائمة لمعرفة الـ IDs "الجديدة فقط" التي لم يسبق إرسال إشعار عنها
    List<String> newMatchIds = currentMatchIds
        .where((id) => id != "null" && id.isNotEmpty && !alreadyNotifiedIds.contains(id))
        .toList();

    // 3. إذا لم يوجد أي عنصر جديد، نتوقف (هذا يمنع الإشعارات الـ 3 المكررة)
    if (newMatchIds.isEmpty) return;

    // 4. إظهار إشعار "واحد" فقط للمجموعة الجديدة
    flutterLocalNotificationsPlugin.show(
      reportId.hashCode, // معرف ثابت للبلاغ يضمن تحديث الإشعار بدلاً من تكراره
      "تم العثور على تطابق جديد ✨",
      "وجدنا نتائج جديدة تطابق بلاغك ($category)، تحقّق منها الآن",
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id, channel.name,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          groupKey: 'com.dhallah.MATCHES_GROUP',
        ),
      ),
    );

    // 5. حفظ مستند واحد في الفايرستور يحتوي على الـ IDs الجديدة
    await _db.collection('notifications').add({
      'receiverId': userId,
      'reportId': reportId,
      'matchedReportId': newMatchIds.first,
      'notifiedMatchIds': newMatchIds, // قائمة العناصر الجديدة
      'title': "تم العثور على تطابق جديد ✨",
      'body': "وجدنا نتائج جديدة تطابق بلاغك ($category)، تحقّق منها الآن",
      'type': 'match',
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
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

}
