import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // جلب الإشعارات الخاصة بمستخدم معين من الكولكشن الموحد
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

  // دالة لإرسال إشعار جديد
  Future<void> sendNotification({
    required String receiverId,
    required String title,
    required String body,
    required String type,
  }) async {
    await _db.collection('notifications').add({
      'receiverId': receiverId,
      'title': title,
      'body': body,
      'type': type,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }
  // 1. تحديث إشعار واحد فقط عند الضغط عليه
  Future<void> markAsRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

// 2. تحديث كل الإشعارات للمستخدم الحالي (تحديد الكل كمقروء)
  Future<void> markAllAsRead(String userId) async {
    var batch = _db.batch();
    var snapshots = await _db
        .collection('notifications')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshots.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}