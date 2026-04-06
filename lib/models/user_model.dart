// user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/* هذا الموديل محدث ليتوافق تماماً مع حقول Firestore:
  (email, name, phone, uid, provider, isProfileComplete, lastUpdate)
*/

abstract class User {
  String uid;             // تم التغيير من int إلى String
  String name;            // تم التغيير من username إلى name
  String email;
  String? phone;          // نجعله nullable لأن البداية قد تكون null
  DateTime? lastUpdate;   // ليطابق التايم ستامب في الداتابيز

  User({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    this.lastUpdate,
  });
}

//############################################
// --- Regular User Model ---
class RegularUser extends User {
  String userType;
  bool isProfileComplete;
  String? provider;

  RegularUser({
    required super.uid,
    required super.name,
    required super.email,
    super.phone,
    super.lastUpdate,
    this.userType = 'regular',
    this.isProfileComplete = false,
    this.provider,
  });

  // --- دالة سحرية: تحول بيانات Firestore (Map) إلى كائن برمجى (Object) ---
  factory RegularUser.fromMap(Map<String, dynamic> data) {
    return RegularUser(
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      isProfileComplete: data['isProfileComplete'] ?? false,
      provider: data['provider'],
      lastUpdate: (data['lastUpdate'] as Timestamp?)?.toDate(),
      userType: data['userType'] ?? 'regular',
    );
  }

  // --- دالة سحرية: تحول الكائن إلى (Map) لإرساله إلى Firestore ---
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'isProfileComplete': isProfileComplete,
      'provider': provider,
      'lastUpdate': FieldValue.serverTimestamp(),
      'userType': userType,
    };
  }

  // الدوال المنطقية الخاصة بكِ (مثل إنشاء بلاغ) تبقى كما هي هنا
  void createLostReport(Object itemData) {
    // كود إرسال البلاغ...
  }
}

//############################################
// --- Admin Model ---
class Admin extends User {
  String adminLevel;

  Admin({
    required super.uid,
    required super.name,
    required super.email,
    super.phone,
    super.lastUpdate,
    required this.adminLevel,
  });

  factory Admin.fromMap(Map<String, dynamic> data) {
    return Admin(
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      lastUpdate: (data['lastUpdate'] as Timestamp?)?.toDate(),
      adminLevel: data['adminLevel'] ?? 'basic',
    );
  }
}