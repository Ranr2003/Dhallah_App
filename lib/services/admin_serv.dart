import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/report_model.dart';
import 'package:flutter/foundation.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. جلب إحصائيات سريعة (مستخدمين، بلاغات مفقودة، بلاغات معثورة)
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      var reportsSnapshot = await _firestore.collection('reports').get();
      var allReports = reportsSnapshot.docs;

      // 1. حساب الحالات (بناءً على status عندك)
      int total = allReports.length;
      int completed = allReports.where((doc) => doc['status'] == 'completed').length;
      int open = allReports.where((doc) => doc['status'] == 'open').length;

      // 2. حساب المطابقات (البلاغات التي تحتوي على مصفوفة matches غير فارغة)
      int matched = allReports.where((doc) {
        final data = doc.data();
        return data.containsKey('matches') && (data['matches'] as List).isNotEmpty;
      }).length;

      // 3. توزيع البلاغات شهرياً بناءً على createdAt (لأول 5 أشهر من 2026)
      List<double> monthlyData = [0, 0, 0, 0, 0];
      for (var doc in allReports) {
        final data = doc.data();
        if (data.containsKey('createdAt') && data['createdAt'] != null) {
          DateTime date = (data['createdAt'] as Timestamp).toDate();
          // date.month يعطي 1 يناير، 2 فبراير... الخ
          int index = date.month - 1;
          if (index >= 0 && index < 5) {
            monthlyData[index] += 1;
          }
        }
      }

      var usersSnapshot = await _firestore.collection('users').get();

      return {
        'totalUsers': usersSnapshot.docs.length,
        'totalReports': total,
        'completedReports': completed,
        'openReports': open,
        'lostReports': allReports.where((doc) => doc['type'] == 'lost').length,
        'foundReports': allReports.where((doc) => doc['type'] == 'found').length,
        'matchedCount': matched,
        'monthlyStats': monthlyData,
      };
    } catch (e) {
      debugPrint("Error: $e");
      return {};
    }
  }

  // 2. جلب قائمة المستخدمين العاديين (باستخدام الموديل)
  Stream<List<RegularUser>> getUsersStream() {
    return _firestore
        .collection('users')
        .where('userType', isEqualTo: 'regular')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => RegularUser.fromMap(doc.data()))
        .toList());
  }

  // 3. حذف بلاغ مخالف
  Future<void> deleteReport(String reportId) async {
    await _firestore.collection('reports').doc(reportId).delete();
  }

  // 4. حظر مستخدم (تحديث حالته في الداتابيز)
  Future<void> updateUserStatus(String uid, bool isBanned) async {
    await _firestore.collection('users').doc(uid).update({
      'isBanned': isBanned, // تحتاجين إضافة هذا الحقل في الفايرستور لاحقاً
    });
  }
// 4. حظر أو فك حظر مستخدم (تم دمجها في دالة واحدة احترافية)
// 4. حظر أو فك حظر مستخدم (دالة موحدة ومعالجة للأخطاء)
  Future<void> toggleUserBan(String userId, bool currentBanStatus) async {
    try {
      // نحدث الحالة لعكس الحالة الحالية
      await _firestore.collection('users').doc(userId).update({
        'isBanned': !currentBanStatus,
      });
      debugPrint("تم تحديث حالة المستخدم $userId إلى: ${!currentBanStatus}");
    } catch (e) {
      debugPrint("فشل تحديث حالة الحظر: $e");
      rethrow;
    }
  }

  // جلب المستخدمين مع ضمان وجود حقل الحظر حتى لو لم يكن موجوداً في الداتابيز
  Stream<List<Map<String, dynamic>>> getUsersWithDataStream() {
    return _firestore
        .collection('users')
        .where('userType', isEqualTo: 'regular')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data();
      data['userId'] = doc.id;

      // ✅ حماية إضافية: إذا الحقل مو موجود في الفايربيس، نعتبره false افتراضياً
      if (!data.containsKey('isBanned')) {
        data['isBanned'] = false;
      }

      return data;
    }).toList());
  }
}