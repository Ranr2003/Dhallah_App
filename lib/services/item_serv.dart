// lib/services/item_serv.dart
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import '../models/report_model.dart';


/// Handles all Firebase operations for lost and found reports.
/// Covers: upload, read, update, delete, and image storage.
class ItemService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;


  // ════════════════════════════════════════════
  // Upload
  // ════════════════════════════════════════════

  /// Uploads a lost item report to Firestore.
  /// Uploads the image first, then saves the report with [geo_location] and [createdAt].
  /// Returns the generated Firestore document ID.
  Future<String> uploadLostReport(LostItemReport report) async {
    String imageUrl = await _uploadImage(report.item.imageURL);
    report.item.imageURL = imageUrl;

    Map<String, dynamic> data = report.toMap();
    data['createdAt']    = FieldValue.serverTimestamp();
    data['geo_location'] = GeoPoint(
      report.coordinates.latitude,
      report.coordinates.longitude,
    );

    DocumentReference ref = await _firestore
        .collection('lost_reports')
        .add(data);

    return ref.id;
  }

  /// Uploads a found item report to Firestore.
  /// Uploads the image first, then saves the report with [geo_location] and [createdAt].
  /// Returns the generated Firestore document ID.
  Future<String> uploadFoundReport(FoundItemReport report) async {
    String imageUrl = await _uploadImage(report.item.imageURL);
    report.item.imageURL = imageUrl;

    Map<String, dynamic> data = report.toMap();
    data['createdAt']    = FieldValue.serverTimestamp();
    data['geo_location'] = GeoPoint(
      report.coordinates.latitude,
      report.coordinates.longitude,
    );

    DocumentReference ref = await _firestore
        .collection('found_reports')
        .add(data);

    return ref.id;
  }


  // ════════════════════════════════════════════
  // Read
  // ════════════════════════════════════════════

  /// Returns a real-time stream of all lost reports, ordered by newest first.
  Stream<QuerySnapshot> getLostReports() {
    return _firestore
        .collection('lost_reports')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Returns a real-time stream of all found reports, ordered by newest first.
  Stream<QuerySnapshot> getFoundReports() {
    return _firestore
        .collection('found_reports')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Returns a real-time stream of lost reports belonging to a specific user.
  Stream<QuerySnapshot> getUserLostReports(String uid) {
    return _firestore
        .collection('lost_reports')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Returns a real-time stream of found reports belonging to a specific user.
  Stream<QuerySnapshot> getUserFoundReports(String uid) {
    return _firestore
        .collection('found_reports')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Fetches a single lost report by its Firestore document ID.
  /// Returns null if the document does not exist.
  Future<LostItemReport?> getLostReportById(String reportId) async {
    DocumentSnapshot doc = await _firestore
        .collection('lost_reports')
        .doc(reportId)
        .get();

    if (!doc.exists) return null;

    return LostItemReport.fromMap(
      doc.data() as Map<String, dynamic>,
      doc.id,
    );
  }

  /// Fetches a single found report by its Firestore document ID.
  /// Returns null if the document does not exist.
  Future<FoundItemReport?> getFoundReportById(String reportId) async {
    DocumentSnapshot doc = await _firestore
        .collection('found_reports')
        .doc(reportId)
        .get();

    if (!doc.exists) return null;

    return FoundItemReport.fromMap(
      doc.data() as Map<String, dynamic>,
      doc.id,
    );
  }


  // ════════════════════════════════════════════
  // Update
  // ════════════════════════════════════════════

  /// Updates the status of a lost report (e.g. 'Active' → 'Closed').
  /// Only modifies the [status] field — all other data remains unchanged.
  Future<void> updateLostReportStatus(String reportId, String newStatus) async {
    await _firestore
        .collection('lost_reports')
        .doc(reportId)
        .update({'status': newStatus});
  }

  /// Updates the status of a found report (e.g. 'Active' → 'Closed').
  /// Only modifies the [status] field — all other data remains unchanged.
  Future<void> updateFoundReportStatus(String reportId, String newStatus) async {
    await _firestore
        .collection('found_reports')
        .doc(reportId)
        .update({'status': newStatus});
  }


  // ════════════════════════════════════════════
  // Delete
  // ════════════════════════════════════════════

  /// Permanently deletes a lost report from Firestore by its document ID.
  Future<void> deleteLostReport(String reportId) async {
    await _firestore
        .collection('lost_reports')
        .doc(reportId)
        .delete();
  }

  /// Permanently deletes a found report from Firestore by its document ID.
  Future<void> deleteFoundReport(String reportId) async {
    await _firestore
        .collection('found_reports')
        .doc(reportId)
        .delete();
  }


  // ════════════════════════════════════════════
  // Private: Image Upload
  // ════════════════════════════════════════════

  /// Uploads a local image to Firebase Storage and returns its download URL.
  /// Skips upload if the path is already an HTTP URL.
  /// Supports both web (bytes via HTTP) and mobile (local file).
  Future<String> _uploadImage(String localPath) async {
    if (localPath.startsWith('http')) return localPath;

    try {
      String fileName = 'item_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = _storage.ref().child(fileName);
      UploadTask uploadTask;

      if (kIsWeb) {
        final response = await http.get(Uri.parse(localPath));
        final bytes    = response.bodyBytes;
        uploadTask = storageRef.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        File imageFile = File(localPath);
        uploadTask = storageRef.putFile(imageFile);
      }

      TaskSnapshot snapshot    = await uploadTask;
      String       downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;

    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }
}