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
    String? reportId, // 👈 أضفنا هذا السطر ليتعرف عليه فلاتر
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

  // 1. تحديث إشعار واحد فقط عند الضغط عليه ليصبح "مقروء"
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

  // 3. مسح جميع الإشعارات للمستخدم (المستخدمة في خيارات صفحة الإشعارات)
  Future<void> clearAllNotifications(String userId) async {
    var batch = _db.batch();
    var snapshots = await _db
        .collection('notifications')
        .where('receiverId', isEqualTo: userId)
        .get();

    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // دالة لإرسال إشعارات بناءً على التطابقات الموجودة في البلاغ
  Future<void> notifyOnNewMatch(String reportId) async {
    try {
      DocumentSnapshot reportDoc = await _db.collection('reports').doc(reportId).get();

      if (reportDoc.exists) {
        List matches = reportDoc.get('matches') ?? [];

        for (var match in matches) {
          double score = (match['score'] as num).toDouble();
          String matchedReportId = match['matched_report_id'];

          // إرسال إشعار إذا كانت نسبة التطابق 80% فأكثر
          if (score >= 0.8) {
            DocumentSnapshot matchedDoc = await _db.collection('reports').doc(matchedReportId).get();

            if (matchedDoc.exists) {
              String targetUserId = matchedDoc.get('userId');

              await sendNotification(
                receiverId: targetUserId,
                title: "تطابق ذكي! ✨",
                body: "تم العثور على غرض يطابق بلاغك بنسبة ${(score * 100).toInt()}%",
                type: "match",
              );
            }
          }
        }
      }
    } catch (e) {
      print("خطأ في إرسال إشعار التطابق: $e");
    }
  }

  // دالة تجريبية لفحص كل التقارير القديمة وإرسال إشعارات لها
  Future<void> testOldMatches() async {
    print("جاري فحص التطابقات القديمة لإرسال الإشعارات...");
    try {
      QuerySnapshot allReports = await _db.collection('reports').get();

      for (var reportDoc in allReports.docs) {
        await notifyOnNewMatch(reportDoc.id);
      }
      print("تم الانتهاء من فحص جميع التقارير.");
    } catch (e) {
      print("خطأ أثناء تجربة التطابقات القديمة: $e");
    }
  }
}