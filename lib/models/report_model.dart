import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'item_model.dart';

class Report {
  final String? reportId;
  final String type;
  final String userId;
  final String status;
  final String ai_status;
  final List<Map<String, dynamic>> matches;
  final Item item;
  final String locationName;
  final LatLng coordinates;
  final DateTime createdAt;

  Report({
    this.reportId,
    required this.type,
    required this.userId,
    this.status = "open",
    this.ai_status = "pending",
    this.matches = const [],
    required this.item,
    required this.locationName,
    required this.coordinates,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'reportId': reportId,
      'type': type,
      'userId': userId,
      'status': status,
      'ai_status': ai_status,
      'matches': matches,
      'item': item.toMap(),
      'locationName': locationName,
      'geo_location': GeoPoint(coordinates.latitude, coordinates.longitude),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory Report.fromMap(Map<String, dynamic> map, String id) {
    final geo = map['geo_location'] as GeoPoint?;
    return Report(
      reportId: map['reportId'] ?? id,
      type: map['type'] ?? '',
      userId: map['userId'] ?? '',
      status: map['status'] ?? 'open',
      ai_status: map['ai_status'] ?? 'pending',
      matches: List<Map<String, dynamic>>.from(map['matches'] ?? []),
      item: Item.fromMap(map['item'] ?? {}),
      locationName: map['locationName'] ?? '',
      coordinates: LatLng(geo?.latitude ?? 0, geo?.longitude ?? 0),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}