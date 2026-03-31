//authentication_serv.dart
// Rand - Full Authentication Service (Email, Phone, & Google)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
class AuthenticationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // --- 1. تسجيل الدخول بجوجل (Google Sign-In) ---
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      User? currentUser = _auth.currentUser;

      if (currentUser != null) {
        // ربط قوقل بالحساب الحالي
        UserCredential result =
        await currentUser.linkWithCredential(credential);
        return result.user;
      } else {
        // تسجيل دخول طبيعي
        UserCredential result =
        await _auth.signInWithCredential(credential);
        return result.user;
      }
    } catch (e) {
      print("خطأ في دخول قوقل: $e");
      rethrow;
    }
  }

  // --- 2. تسجيل دخول (إيميل مع التحقق من التفعيل) ---
  Future<User?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      User? user = result.user;

      if (user != null && !user.emailVerified) {
        await logout();
        throw Exception(
            "الرجاء تفعيل حسابك عبر الرابط المرسل إلى بريدك الإلكتروني أولاً.");
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print("خطأ في تسجيل الدخول: ${e.message}");
      rethrow;
    }
  }

  // --- 3. تسجيل مستخدم جديد ---
  Future<User?> register({
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      if (password != confirmPassword) {
        throw Exception("كلمتا المرور غير متطابقتين!");
      }

      if (!validatePassword(password)) {
        throw Exception("كلمة المرور يجب أن تكون 6 خانات على الأقل");
      }

      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      User? user = result.user;

      if (user != null) {
        await user.updateDisplayName(username);
        await user.sendEmailVerification();
        await logout();
      }

      return user;
    } catch (e) {
      print("خطأ في التسجيل: $e");
      rethrow;
    }
  }

  // --- 4. التحقق من رقم الجوال ---
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,

        verificationCompleted: (PhoneAuthCredential credential) async {
          User? currentUser = _auth.currentUser;

          if (currentUser != null) {
            // ربط الجوال بالحساب الحالي
            await currentUser.linkWithCredential(credential);
          } else {
            await _auth.signInWithCredential(credential);
          }
        },

        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? "حدث خطأ في التحقق");
        },

        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },

        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  // --- تسجيل الدخول بالكود OTP ---
  Future<User?> signInWithOTP(String verificationId, String smsCode) async {
    try {
      AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      User? currentUser = _auth.currentUser;

      if (currentUser != null) {
        // ربط الجوال بالحساب الحالي
        UserCredential result =
        await currentUser.linkWithCredential(credential);
        return result.user;
      } else {
        // تسجيل دخول طبيعي
        UserCredential result =
        await _auth.signInWithCredential(credential);
        return result.user;
      }
    } catch (e) {
      throw Exception("كود التحقق غير صحيح");
    }
  }

  // --- 5. وظائف إضافية ---
  bool validatePassword(String password) => password.length >= 6;

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
  // --- دالة تحديث كلمة السر ---
  Future<void> updatePassword(String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      } else {
        throw Exception("لا يوجد مستخدم مسجل دخول حالياً");
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception("يرجى تسجيل الخروج والدخول مجدداً لتحديث كلمة السر.");
      }
      throw Exception("خطأ في تحديث كلمة السر: ${e.message}");
    }
  }
}