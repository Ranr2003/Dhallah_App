// lib/services/item_serv.dart
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/report_model.dart';
import 'notification_serv.dart';

class ItemService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final NotificationService _notificationService = NotificationService();

  /// Uploads image and saves the report document to Firestore.
  Future<void> uploadReport(Report report, XFile? imageFile) async {
    try {
      if (imageFile == null) throw Exception('الرجاء إرفاق صورة');
      String uploadedUrl = await _uploadXFile(imageFile);
      DocumentReference docRef = _firestore.collection('reports').doc();
      Map<String, dynamic> finalData = report.toMap();
      finalData['reportId'] = docRef.id;
      finalData['item']['imageURL'] = uploadedUrl;
      await docRef.set(finalData);
      // --- التعديل المطلوب هنا (إرسال الإشعار بعد النجاح) ---
      await _notificationService.sendNotification(
        receiverId: report.userId, // صاحب البلاغ
        title: "تم إنشاء بلاغ",
        body: "تم تسجيل بلاغك بنجاح في نظام ضاله - ${report.item.category}",
        type: "creation",
      );
      // --------------------------------------------------
    } catch (e) {
      rethrow;
    }
  }

  /// Returns a real-time stream of reports belonging to the given user [uid].
  Stream<List<Report>> getMyReportsStream(String uid) {
    return _firestore
        .collection('reports')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Report.fromMap(doc.data(), doc.id))
        .toList());
  }

  /// Fetches a single report by its [reportId], returns null if not found.
  Future<Report?> getReportById(String reportId) async {
    try {
      final doc = await _firestore.collection('reports').doc(reportId).get();
      final data = doc.data();
      if (data != null) return Report.fromMap(data, doc.id);
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Deletes a report document and its associated image from storage.
  /// Deletes a report document and cleans up references in other reports' matches.
  Future<void> deleteReport(String reportId, String? imageUrl) async {
    try {
      // 1. حذف الوثيقة الأساسية من Firestore
      await _firestore.collection('reports').doc(reportId).delete();

      // 2. حذف الصورة من Storage إذا وجدت
      if (imageUrl != null && imageUrl.isNotEmpty) {
        await _storage.refFromURL(imageUrl).delete();
      }

      // 3. التحديث السحري: حذف أي إشارة لهذا البلاغ في مصفوفات المطابقة (matches) للبلاغات الأخرى
      // نبحث عن كل التقارير التي تحتوي على هذا الـ ID في قائمة مطابقتها
      final relatedReports = await _firestore
          .collection('reports')
          .where('matches', isNotEqualTo: []) // فقط التقارير التي لديها مطابقات
          .get();

      WriteBatch batch = _firestore.batch();
      bool needUpdate = false;

      for (var doc in relatedReports.docs) {
        List matches = List.from(doc.data()['matches'] ?? []);

        // إذا كانت القائمة تحتوي على البلاغ المحذوف، نقوم بإزالته
        int initialLength = matches.length;
        matches.removeWhere((m) => m['matched_report_id'] == reportId);

        // إذا تغير طول القائمة، يعني وجدنا البلاغ المحذوف وحذفناه من القائمة
        if (matches.length != initialLength) {
          batch.update(doc.reference, {'matches': matches});
          needUpdate = true;
        }
      }

      if (needUpdate) {
        await batch.commit();
      }

    } catch (e) {
      print("Error deleting report and cleaning matches: $e");
      rethrow;
    }
  }

  /// Returns a real-time stream of all reports ordered by creation date.
  Stream<List<Report>> getAllReportsStream() {
    return _firestore
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Report.fromMap(doc.data(), doc.id))
        .toList());
  }

  /// Uploads an [XFile] image to Firebase Storage and returns its download URL.
  Future<String> _uploadXFile(XFile file) async {
    String fileName = 'reports/${DateTime.now().millisecondsSinceEpoch}.jpg';
    Reference ref = _storage.ref().child(fileName);
    if (kIsWeb) {
      await ref.putData(
        await file.readAsBytes(),
        SettableMetadata(contentType: 'image/jpeg'),
      );
    } else {
      await ref.putFile(File(file.path));
    }
    return await ref.getDownloadURL();
  }
}