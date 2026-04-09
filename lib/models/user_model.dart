// user_model.dart
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
  String? provider;

  RegularUser({
    required super.userId,
    required super.name,
    required super.email,
    super.phone,
    super.lastUpdate,
    this.userType = 'regular',
    this.isProfileComplete = false,
    this.provider,
  });

  //لما ناخذ البيانات من الفاير ستور تجينا بشكل ماب فحنا بنحولها لاوبجكت عشان نقدر نستخدمه
  factory RegularUser.fromMap(Map<String, dynamic> data) {
    return RegularUser(
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
        isProfileComplete: data['isProfileComplete'] ?? false ,
      provider: data['provider'],
      lastUpdate: (data['lastUpdate'] as Timestamp?)?.toDate(),
      userType: data['userType'] ?? 'regular',
    );
  }

  //لما بنرجع نحفظ البيانات لفاير ستور محتاجين نحولها من اوبجكت لماب
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'isProfileComplete': isProfileComplete,
      'provider': provider,
      'lastUpdate': FieldValue.serverTimestamp(),
      'userType': userType,
    };
  }

  // احس ماله فايده هنا
  void createLostReport(Object itemData) {
    // كود إرسال البلاغ...
  }
}

// الادمن يرث من المستخدم واضفنا له صفحه زيادة
class Admin extends User {
  String adminLevel;

  Admin({
    required super.userId,
    required super.name,
    required super.email,
    super.phone,
    super.lastUpdate,
    required this.adminLevel,
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
}