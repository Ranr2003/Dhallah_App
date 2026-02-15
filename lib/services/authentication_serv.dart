//Rand
import 'package:firebase_auth/firebase_auth.dart';

class AuthenticationService {
  // تعريف مرجع الفايربيس بشكل صحيح داخل الكلاس
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // تسجيل دخول
  Future<User?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      // التعامل مع أخطاء فايربيس المحددة
      print("خطأ في تسجيل الدخول: ${e.message}");
      rethrow;
    }
  }

  // تسجيل مستخدم جديد مع التحقق من تطابق كلمة المرور
  Future<User?> register({
    required String username,
    required String email,
    required String password,
    required String confirmPassword
  }) async {
    try {
      // 1. التحقق من تطابق كلمتي المرور (محلياً)
      if (password != confirmPassword) {
        throw Exception("كلمتا المرور غير متطابقتين!");
      }

      // 2. التحقق من الطول
      if (!validatePassword(password)) {
        throw Exception("كلمة المرور يجب أن تكون 6 خانات على الأقل");
      }

      // 3. إنشاء الحساب في فايربيس
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password
      );

      // 4. تحديث اسم المستخدم (DisplayName)
      await result.user?.updateDisplayName(username);

      return result.user;
    } catch (e) {
      print("خطأ في التسجيل: $e");
      rethrow;
    }
  }

  // التحقق من قوة كلمة المرور
  bool validatePassword(String password) {
    return password.length >= 6;
  }

  // تسجيل الخروج
  Future<void> logout() async {
    await _auth.signOut();
  }

  // إعادة تعيين كلمة المرور
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
