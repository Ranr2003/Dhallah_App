import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/report_model.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;


  Future<void> submitReport(Report report, XFile? imageFile) async {
    try {
      if (imageFile == null) throw Exception('الرجاء إرفاق صورة');
      String uploadedUrl = await _uploadImageToStorage(imageFile);
      DocumentReference newReportRef = _firestore.collection('reports').doc();
      Map<String, dynamic> reportMap = report.toMap();
      reportMap['reportId'] = newReportRef.id;
      reportMap['item']['imageURL'] = uploadedUrl;
      await newReportRef.set(reportMap);
    } catch (e) {
      rethrow;
    }
  }


  Stream<List<Report>> getUserReportsStream(String userId) {
    return _firestore
        .collection('reports')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((querySnapshot) => querySnapshot.docs
        .map((docSnapshot) => Report.fromMap(docSnapshot.data(), docSnapshot.id))
        .toList());
  }


  Future<Report?> fetchReportById(String reportId) async {
    try {
      final reportDoc = await _firestore.collection('reports').doc(reportId).get();
      final reportData = reportDoc.data();
      if (reportData != null) return Report.fromMap(reportData, reportDoc.id);
      return null;
    } catch (e) {
      rethrow;
    }
  }


  Future<void> deleteReport(String reportId, String? imageUrl) async {
    try {
      await _firestore.collection('reports').doc(reportId).delete();
      if (imageUrl != null && imageUrl.isNotEmpty) {
        await _storage.refFromURL(imageUrl).delete();
      }
    } catch (e) {
      rethrow;
    }
  }


  Stream<List<Report>> getAllReportsStream() {
    return _firestore
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Report.fromMap(doc.data(), doc.id))
        .toList());
  }


  Future<String> _uploadImageToStorage(XFile imageFile) async {
    String fileName = 'reports/${DateTime.now().millisecondsSinceEpoch}.jpg';
    Reference storageRef = _storage.ref().child(fileName);
    if (kIsWeb) {
      await storageRef.putData(
        await imageFile.readAsBytes(),
        SettableMetadata(contentType: 'image/jpeg'),
      );
    } else {
      await storageRef.putFile(File(imageFile.path));
    }
    return await storageRef.getDownloadURL();
  }
}