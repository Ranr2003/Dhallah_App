import '../models/item_model.dart';
import '../models/match_model.dart';

class MatchingService {

  // هذه الدالة هي جوهر مهمتك رقم 3
  // تأخذ غرض مفقود وتقارنه بغرض موجود وترجع نسبة التطابق
  double calculateMatchScore(Item lostItem, Item foundItem) {
    double score = 0.0;

    // 1. فحص الفئة (Category) - إذا اختلف النوع لا يوجد تطابق
    if (lostItem.category.trim().toLowerCase() != foundItem.category.trim().toLowerCase()) {
      return 0.0;
    }
    score += 0.4; // 40% إذا كانت من نفس الفئة (مثلاً كلاهما "محفظة")

    // 2. فحص اللون (Color)
    if (lostItem.color.trim().toLowerCase() == foundItem.color.trim().toLowerCase()) {
      score += 0.3; // 30% إضافية إذا كان اللون متطابقاً
    }

    // 3. فحص الوصف والمميزات الفريدة (Description & Unique Features)
    // نجمع النصوص مع بعض ونبحث عن الكلمات المشتركة
    String lostText = "${lostItem.description} ${lostItem.uniqueFeatures}".toLowerCase();
    String foundText = "${foundItem.description} ${foundItem.uniqueFeatures}".toLowerCase();

    List<String> keywords = lostText.split(' ');
    int matchCount = 0;

    for (var word in keywords) {
      if (word.length > 3 && foundText.contains(word)) {
        matchCount++;
      }
    }

    // إذا وجدنا كلمتين وصفية مشتركة على الأقل، نعطيه الـ 30% المتبقية
    if (matchCount >= 2) {
      score += 0.3;
    } else if (matchCount == 1) {
      score += 0.15;
    }

    return score; // النتيجة النهائية من 1.0 (أي 100%)
  }

  // دالة لجلب أفضل المطابقات (تستخدمها لاحقاً في الهوم بيج)
  List<MatchModel> getTopMatches(Item userItem, List<Item> allItemsFromDB) {
    List<MatchModel> potentialMatches = [];

    for (var dbItem in allItemsFromDB) {
      double score = calculateMatchScore(userItem, dbItem);

      // إذا كانت النسبة أعلى من 50% نعتبرها مطابقة محتملة
      if (score >= 0.5) {
        potentialMatches.add(MatchModel(
          matchId: DateTime.now().millisecondsSinceEpoch.toString(),
          lostItem: userItem,
          foundItem: dbItem,
          matchPercentage: score,
          matchDate: DateTime.now(),
        ));
      }
    }

    // ترتيب النتائج من الأعلى تطابقاً للأقل
    potentialMatches.sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));
    return potentialMatches;
  }
}