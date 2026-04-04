// lib/models/match_model.dart
import 'item_model.dart'; // تأكد من المسار الصحيح

class MatchModel {
  final String matchId;
  final Item lostItem;   // الغرض المفقود
  final Item foundItem;  // الغرض الموجود
  final double matchPercentage; // نسبة التطابق (مثلاً 0.85 يعني 85%)
  final DateTime matchDate;

  MatchModel({
    required this.matchId,
    required this.lostItem,
    required this.foundItem,
    required this.matchPercentage,
    required this.matchDate,
  });

  // لتحويل البيانات لـ Firestore
  Map<String, dynamic> toMap() {
    return {
      'matchId': matchId,
      'lostItem': lostItem.toMap(),
      'foundItem': foundItem.toMap(),
      'matchPercentage': matchPercentage,
      'matchDate': matchDate.toIso8601String(),
    };
  }
}