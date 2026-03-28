// lib/models/report_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'item_model.dart';


/// Base class for all report types.
abstract class Report {
  final String? reportId;
  String description;
  DateTime date;
  String status;
  String userId;
  Item item;

  Report({
    this.reportId,
    required this.description,
    required this.date,
    required this.status,
    required this.userId,
    required this.item,
  });
}

/// Represents a lost item report submitted by a user.
class LostItemReport extends Report {

  String lastKnownLocation;
  final LatLng coordinates;

  LostItemReport({
    super.reportId,
    required super.description,
    required super.date,
    required super.status,
    required super.userId,
    required super.item,
    this.lastKnownLocation = '',
    required this.coordinates,
  });

  /// Converts this report into a [Map] for Firestore storage.
  /// Note: [geo_location] and [createdAt] are added separately in [ItemService].
  Map<String, dynamic> toMap() {
    return {
      'reportType': 'lost',
      'description': description,
      'status': status,
      'userId': userId,
      'lastKnownLocation': lastKnownLocation,
      'item': item.toMap(),
    };
  }

  /// Creates a [LostItemReport] from a Firestore document.
  /// Handles both [GeoPoint] and legacy [Map] formats for coordinates.
  /// Handles both [Timestamp] and legacy [String] formats for dates.
  factory LostItemReport.fromMap(Map<String, dynamic> map, String id) {
    final geo = map['geo_location'];
    LatLng coordinates;
    if (geo is GeoPoint) {
      coordinates = LatLng(geo.latitude, geo.longitude);
    } else if (geo is Map) {
      coordinates = LatLng(
        (geo['lat'] ?? 0.0).toDouble(),
        (geo['lng'] ?? 0.0).toDouble(),
      );
    } else {
      coordinates = const LatLng(24.7136, 46.6753);  // Default: Riyadh
    }

    DateTime date;
    final createdAt = map['createdAt'];
    if (createdAt is Timestamp) {
      date = createdAt.toDate();
    } else if (map['date'] is String) {
      date = DateTime.parse(map['date']);
    } else {
      date = DateTime.now();
    }

    return LostItemReport(
      reportId:          id,
      description:       map['description']       ?? '',
      date:              date,
      status:            map['status']             ?? 'Active',
      userId:            map['userId']             ?? '',
      lastKnownLocation: map['lastKnownLocation']  ?? '',
      item:              Item.fromMap(map['item']  ?? {}),
      coordinates:       coordinates,
    );
  }
}


/// Represents a found item report submitted by a user.
class FoundItemReport extends Report {

  String itemFoundLocation;
  final LatLng coordinates;

  FoundItemReport({
    super.reportId,
    required super.description,
    required super.date,
    required super.status,
    required super.userId,
    required super.item,
    this.itemFoundLocation = '',
    required this.coordinates,
  });

  /// Converts this report into a [Map] for Firestore storage.
  /// Note: [geo_location] and [createdAt] are added separately in [ItemService].
  Map<String, dynamic> toMap() {
    return {
      'reportType': 'found',
      'description': description,
      'status': status,
      'userId': userId,
      'itemFoundLocation': itemFoundLocation,
      'item': item.toMap(),
    };
  }

  /// Creates a [FoundItemReport] from a Firestore document.
  /// Handles both [GeoPoint] and legacy [Map] formats for coordinates.
  /// Handles both [Timestamp] and legacy [String] formats for dates.
  factory FoundItemReport.fromMap(Map<String, dynamic> map, String id) {
    final geo = map['geo_location'];
    LatLng coordinates;
    if (geo is GeoPoint) {
      coordinates = LatLng(geo.latitude, geo.longitude);
    } else if (geo is Map) {
      coordinates = LatLng(
        (geo['lat'] ?? 0.0).toDouble(),
        (geo['lng'] ?? 0.0).toDouble(),
      );
    } else {
      coordinates = const LatLng(24.7136, 46.6753); // Default: Riyadh
    }

    DateTime date;
    final createdAt = map['createdAt'];
    if (createdAt is Timestamp) {
      date = createdAt.toDate();
    } else if (map['date'] is String) {
      date = DateTime.parse(map['date']);
    } else {
      date = DateTime.now();
    }

    return FoundItemReport(
      reportId:          id,
      description:       map['description']      ?? '',
      date:              date,
      status:            map['status']            ?? 'Active',
      userId:            map['userId']            ?? '',
      itemFoundLocation: map['itemFoundLocation'] ?? '',
      item:              Item.fromMap(map['item'] ?? {}),
      coordinates:       coordinates,
    );
  }
}