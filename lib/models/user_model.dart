//user_model.dart
//Rand

/* ---------------------------------------------------------
  HOW TO USE THIS MODEL IN OTHER FILES:
  ---------------------------------------------------------
  1. Add this import at the top of your file:
     import 'package:Dhallah_App/models/user_model.dart';

  2. Create an instance for a Regular User:
     var user = RegularUser(...params...);

  3. Create an instance for an Admin:
     var admin = Admin(...params...);
  ---------------------------------------------------------
*/

//############################################
// --- Base Model ---
abstract class User {
  int userId;
  String username;
  String email;
  String phone;
  String password;
  DateTime registrationDate;

  User({
    required this.userId,
    required this.username,
    required this.email,
    required this.phone,
    required this.password,
    required this.registrationDate,
  });
}

//############################################
// --- Regular User Model ---
class RegularUser extends User {
  String userType;
  bool verificationStatus;

  RegularUser({
    required super.userId,
    required super.username,
    required super.email,
    required super.phone,
    required super.password,
    required super.registrationDate,
    required this.userType,
    required this.verificationStatus,
  });

  /// إنشاء بلاغ عن مفقود
  /// المقترح: استقبال كائن 'Item' يحتوي على (الاسم، التصنيف، الموقع، وصورة)
  void createLostReport(Object itemData) {
    // TODO: إرسال بيانات المفقود إلى قاعدة البيانات (Firestore/API)
    // TODO: تفعيل تنبيه للمستخدمين القريبين من الموقع الجغرافي
  }

  /// إنشاء بلاغ عن غرض تم العثور عليه
  void createFoundReport(Object itemData) {
    // TODO: حفظ بيانات الغرض وربطها بمعرف المستخدم الحالي (Finder)
  }

  /// البحث عن الأغراض
  /// المقترح: إرجاع قائمة 'List<Item>' بناءً على نص البحث أو التصنيف
  List<dynamic> searchItems(String query, {String? category}) {
    // TODO: تنفيذ استعلام (Query) في قاعدة البيانات لتصفية النتائج
    return [];
  }

  /// التواصل مع الشخص الذي وجد الغرض
  /// المقترح: استقبال 'receiverId' لفتح قناة دردشة
  void communicateWithFinder(int finderId) {
    // TODO: فتح واجهة الدردشة (Chat Screen) وبدء جلسة مراسلة
  }

  /// التحقق من الملكية
  /// المقترح: رفع إثبات (صورة أو وصف دقيق) ومقارنته ببيانات البلاغ
  bool verifyOwnership(int reportId, dynamic proofData) {
    // TODO: إرسال الإثبات للمدير (Admin) للمراجعة أو التحقق آلياً
    return false;
  }
}

//############################################
// --- Admin Model ---
class Admin extends User {
  String adminLevel;

  Admin({
    required super.userId,
    required super.username,
    required super.email,
    required super.phone,
    required super.password,
    required super.registrationDate,
    required this.adminLevel,
  });

  /// إدارة المستخدمين (حظر، تفعيل، تعديل)
  void manageUsers(int targetUserId, String action) {
    // TODO: تحديث حالة المستخدم في قاعدة البيانات (Active/Banned)
  }

  /// إدارة البلاغات (حذف بلاغات مخالفة أو مكررة)
  void manageReports(int reportId) {
    // TODO: مراجعة محتوى البلاغ واتخاذ إجراء (حذف/تثبيت)
  }

  /// مراجعة طلبات إثبات الملكية
  void reviewOwnershipVerification(int requestId) {
    // TODO: فحص الصور والبيانات المقدمة من المستخدم العادي والموافقة عليها
  }

  /// مراقبة نظام المطابقة الذكي (AI)
  /// المقترح: عرض البلاغات التي اقترحها الذكاء الاصطناعي كـ "تطابق محتمل"
  void monitorAIMatching() {
    // TODO: جلب قائمة النتائج التي حققت نسبة تطابق عالية (High Confidence Score)
  }

  /// معالجة الشكاوى المرفوعة من المستخدمين
  void handleComplaints(int complaintId) {
    // TODO: قراءة نص الشكوى والتواصل مع الأطراف المعنية لحل النزاع
  }
}