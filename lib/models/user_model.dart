// user_model.dart

// ---------------------------------------------------------
//  (اولا) استيراد الباكجيز
// ---------------------------------------------------------
import 'package:cloud_firestore/cloud_firestore.dart';
// ---------------------------------------------------------
//  (ثانيا) تعريف الكلاس الرئيسي والمتغيرات المطلوبة لبناءالمودل
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


// 1. المستخدم العادي يرث من المستخدم وزدنا عليه كذا متغير
class RegularUser extends User {
  String userType;
  bool isProfileComplete;
  bool isBanned;
  String? provider;

  RegularUser({
    required super.userId,
    required super.name,
    required super.email,
    super.phone,
    super.lastUpdate,
    this.userType = 'regular',
    this.isProfileComplete = false,
    this.isBanned = false,
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
      isBanned: data['isBanned'] ?? false,
      provider: data['provider'],
      lastUpdate: (data['lastUpdate'] as Timestamp?)?.toDate(),
      userType: data['userType'] ?? 'regular',
    );
  }

  // لما بنرجع نحفظ البيانات للفاير ستور
  Map<String, dynamic> toMap({bool updateTime = false}) {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'isProfileComplete': isProfileComplete,
      'isBanned': isBanned,
      'provider': provider,
      if (updateTime) 'lastUpdate': FieldValue.serverTimestamp(), //فقط في صفحه البروفايل خليته ترو
      'userType': userType,
    };
  }
}

//  2. كلاس الأدمن يرث من المستخدم
class Admin extends User {
  String adminLevel;
  String userType;

  Admin({
    required super.userId,
    required super.name,
    required super.email,
    super.phone,
    super.lastUpdate,
    required this.adminLevel,
    this.userType = 'admin',
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