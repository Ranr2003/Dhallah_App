// Rand - Updated with Email Verification Logic
import 'package:firebase_auth/firebase_auth.dart';

class AuthenticationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- تسجيل دخول (معدل للتحقق من التفعيل) ---
  Future<User?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      User? user = result.user;

      // التأكد من أن البريد مفعل
      if (user != null && !user.emailVerified) {
        // إذا لم يكن مفعلاً، نقوم بتسجيل الخروج فوراً ونرمي خطأ
        await logout();
        throw Exception("الرجاء تفعيل حسابك عبر الرابط المرسل إلى بريدك الإلكتروني أولاً.");
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print("خطأ في تسجيل الدخول: ${e.message}");
      rethrow;
    }
  }

  // --- تسجيل مستخدم جديد (معدل لإرسال رابط تفعيل) ---
  Future<User?> register({
    required String username,
    required String email,
    required String password,
    required String confirmPassword
  }) async {
    try {
      if (password != confirmPassword) {
        throw Exception("كلمتا المرور غير متطابقتين!");
      }

      if (!validatePassword(password)) {
        throw Exception("كلمة المرور يجب أن تكون 6 خانات على الأقل");
      }

      // 1. إنشاء الحساب
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      User? user = result.user;

      if (user != null) {
        // 2. تحديث الاسم
        await user.updateDisplayName(username);

        // 3. إرسال رابط التفعيل للبريد
        await user.sendEmailVerification();

        // 4. تسجيل الخروج لإجباره على تفعيل البريد قبل أول دخول
        await logout();
      }

      return user;
    } catch (e) {
      print("خطأ في التسجيل: $e");
      rethrow;
    }
  }

  bool validatePassword(String password) {
    return password.length >= 6;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
