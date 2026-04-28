// user_model.dart // اضفته من برانش ليلى
//Rand
// ---------------------------------------------------------
//  (اولا) استيراد الباكجيز
// ---------------------------------------------------------
import 'package:cloud_firestore/cloud_firestore.dart';
// ---------------------------------------------------------
//  (ثانيا) تعريف الويدجت الرئيسية والمتغيرات المطلوبة لبناء الصفحة والقيم المبدأية
// ---------------------------------------------------------

abstract class User {
  String userId;
  String name;
  String email;
  String? phone;
  DateTime? lastUpdate;

  User({
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    this.lastUpdate,
  });
}


// المستخدم العادي يرث من المستخدم وزدنا عليه كذا متغير
class RegularUser extends User {
  String userType;
  bool isProfileComplete;
  bool isBanned; // 1. أضفنا هذا الحقل الجديد هنا
  String? provider;

  RegularUser({
    required super.userId,
    required super.name,
    required super.email,
    super.phone,
    super.lastUpdate,
    this.userType = 'regular',
    this.isProfileComplete = false,
    this.isBanned = false, // 2. القيمة الافتراضية "غير محظور"
    this.provider,
  });

  // لما ناخذ البيانات من الفاير ستور بنحولها لأوبجكت
  factory RegularUser.fromMap(Map<String, dynamic> data) {
    return RegularUser(
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      isProfileComplete: data['isProfileComplete'] ?? false,
      isBanned: data['isBanned'] ?? false, // 3. نجلب حالة الحظر من الداتابيز
      provider: data['provider'],
      lastUpdate: (data['lastUpdate'] as Timestamp?)?.toDate(),
      userType: data['userType'] ?? 'regular',
    );
  }

  // لما بنرجع نحفظ البيانات للفاير ستور
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'isProfileComplete': isProfileComplete,
      'isBanned': isBanned,
      'provider': provider,
      'lastUpdate': FieldValue.serverTimestamp(),
      'userType': userType,
    };
  }
}

// 2. كلاس الأدمن
class Admin extends User {
  String adminLevel;
  String userType; // أضفنا هذا الحقل لتسهيل الفحص

  Admin({
    required super.userId,
    required super.name,
    required super.email,
    super.phone,
    super.lastUpdate,
    required this.adminLevel,
    this.userType = 'admin', // القيمة الافتراضية دائماً admin
  });

  factory Admin.fromMap(Map<String, dynamic> data) {
    return Admin(
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      lastUpdate: (data['lastUpdate'] as Timestamp?)?.toDate(),
      adminLevel: data['adminLevel'] ?? 'basic',
    );
  }

  // أضفت لكِ toMap للأدمن للاحتياط
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'lastUpdate': FieldValue.serverTimestamp(),
      'adminLevel': adminLevel,
      'userType': userType,
    };
  }
}