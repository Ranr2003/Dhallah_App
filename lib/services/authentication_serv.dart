// authentication_serv.dart  // اضفته من برانش ليلى
// Rand
// ---------------------------------------------------------
//  (اولا) استيراد الباكجيز
// ---------------------------------------------------------
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'database_serv.dart';
import '../models/user_model.dart';

// ---------------------------------------------------------
//  (ثانيا) تعريف الويدجت الرئيسية والمتغيرات المطلوبة لبناء الصفحة والقيم المبدأية
// ---------------------------------------------------------
class AuthenticationService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final DatabaseService _dbService = DatabaseService();
  // --- حفظ/تحديث المستخدم في Firestore ---
  // نستخدم merge: true لضمان عدم مسح البيانات القديمة
  Future<void> _saveUserData(fb.User user, {String? providedName, String? provider}) async {
    final modelUser = RegularUser(
      userId: user.uid,
      name: providedName ?? user.displayName ?? "مستخدم جديد",
      email: user.email ?? '',
      phone: user.phoneNumber,
      isProfileComplete: false,
      provider: provider ?? "unknown",
    );

    await _dbService.updateOrCreateUser(modelUser);
  }

  // --- 1. تسجيل الدخول بجوجل (مع الربط التلقائي) ---
  Future<fb.User?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      fb.User? currentUser = _auth.currentUser;

      if (currentUser != null) {
        try {
          final result = await currentUser.linkWithCredential(credential);
          await _saveUserData(result.user!, provider: 'google');
          return result.user;
        } on fb.FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use') {
            final result = await _auth.signInWithCredential(credential);
            await _saveUserData(result.user!, provider: 'google');
            return result.user;
          } else {
            throw Exception(e.message);
          }
        }
      } else {
        final result = await _auth.signInWithCredential(credential);
        await _saveUserData(result.user!, provider: 'google');
        return result.user;
      }
    } catch (e) {
      print("خطأ في دخول قوقل: $e");
      rethrow;
    }
  }

  // --- 2. تسجيل دخول بالإيميل ---
  Future<fb.User?> login(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      fb.User? user = result.user;
      await user?.reload();
      user = _auth.currentUser;

      if (user != null && !user.emailVerified) {
        await logout();
        throw Exception("الرجاء تفعيل البريد الإلكتروني أولاً.");
      }


      await _saveUserData(user!, provider: 'email');
      return user;
    } on fb.FirebaseAuthException catch (e) {
      // هنا نوحد جميع رسائل خطأ تسجيل الدخول في رسالة واحدة مفهومة
      // الأكواد الشائعة: user-not-found, wrong-password, invalid-credential
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-email') {
        throw "البريد الإلكتروني أو كلمة السر غير صحيحة.";
      } else if (e.code == 'too-many-requests') {
        throw "تمت محاولة الدخول بشكل خاطئ كثيراً، جرب لاحقاً.";
      } else {
        throw "حدث خطأ أثناء تسجيل الدخول، يرجى المحاولة ثانية.";
      }
    } catch (e) {
      throw "عذراً، حدث خطأ غير متوقع.";
    }
  }

  // --- 3. تسجيل مستخدم جديد ---
  Future<fb.User?> register({
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      if (password != confirmPassword) throw Exception(
          "كلمتا المرور غير متطابقتين!");
      if (!validatePassword(password)) throw Exception(
          "كلمة المرور يجب أن تكون 6 خانات على الأقل");

      final result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      fb.User? user = result.user;

      if (user != null) {
        await user.updateDisplayName(username);
        await _saveUserData(user, providedName: username, provider: 'email');
        await user.sendEmailVerification();
      }
      return user;
    } on fb.FirebaseAuthException catch (e) {
      // هنا نحول أكواد الفايربيس إلى رسائل عربية
      switch (e.code) {
        case 'email-already-in-use':
          throw "هذا البريد الإلكتروني مسجل مسبقاً، جرب تسجيل الدخول.";
        case 'invalid-email':
          throw "صيغة البريد الإلكتروني غير صحيحة.";
        case 'operation-not-allowed':
          throw "عملية التسجيل معطلة حالياً، تواصل مع الدعم.";
        case 'weak-password':
          throw "كلمة المرور التي اخترتها ضعيفة جداً.";
        default:
          throw "حدث خطأ غير متوقع، يرجى المحاولة لاحقاً.";
      }
    } catch (e) {
      throw e.toString();
    }
  }

  // --- 4. إرسال كود التحقق (للدخول أو للربط من البروفايل) ---
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (fb.PhoneAuthCredential credential) async {
          // التحقق التلقائي (في بعض أجهزة أندرويد)
          fb.User? user = _auth.currentUser;
          if (user != null) {
            await user.linkWithCredential(credential);
            await _saveUserData(user, provider: 'phone');
          }
        },
        verificationFailed: (fb.FirebaseAuthException e) => onError(e.message ?? "حدث خطأ"),
        codeSent: (verificationId, resendToken) => onCodeSent(verificationId),
        codeAutoRetrievalTimeout: (verificationId) {},
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  // --- 5. دالة الربط النهائية (تستخدم في البروفايل) ---
  Future<void> linkPhoneNumber(String verificationId, String smsCode) async {
    try {
      final credential = fb.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      fb.User? user = _auth.currentUser;
      if (user != null) {
        // نربط الرقم بالحساب الحالي (الإيميل) لتوحيد الـ UID
        final result = await user.linkWithCredential(credential);
        await _saveUserData(result.user!, provider: 'phone');
      }
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        throw Exception("هذا الرقم مرتبط بحساب آخر بالفعل.");
      }
      throw Exception("كود التحقق غير صحيح");
    }
  }

  // --- 6. تسجيل الدخول العادي بالـ OTP (في حال لم يكن هناك حساب حالي) ---
  Future<fb.User?> signInWithOTP(String verificationId, String smsCode) async {
    try {
      final credential = fb.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final result = await _auth.signInWithCredential(credential);
      await _saveUserData(result.user!, provider: 'phone');
      return result.user;
    } catch (e) {
      throw Exception("كود التحقق غير صحيح");
    }
  }

  // --- وظائف مساعدة ---
  String get currentUserId => _auth.currentUser?.uid ?? 'unknown';

  bool validatePassword(String password) => password.length >= 6;

  Future<void> logout() async {
    try {
      // نضع خروج قوقل داخل try-catch منفصل لأنه أحياناً يعلق إذا لم يكن المستخدم داخلاً بقوقل أصلاً
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        print("Google SignOut Error: $e"); // تجاهل الخطأ واكمل
      }

      // الخروج الأساسي من فايربيس
      await _auth.signOut();
      print("User logged out successfully");
    } catch (e) {
      print("Logout Error: $e");
      // حتى لو صار خطأ، نحاول نخرج من فايربيس كحل أخير
      await _auth.signOut();
    }
  }
  fb.User? getCurrentUser() {
    return _auth.currentUser;
  }
  // 1. دالة لتغيير كلمة المرور (بدلاً من استدعائها مباشرة في الصفحة)
  Future<void> updatePassword(String newPassword) async {
    try {
      fb.User? user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      }
    } catch (e) {
      rethrow; // نترك التعامل مع الخطأ للصفحة لتعرض التنبيه المناسب
    }
  }

  // 2. دالة لجلب رقم الجوال الحالي المخزن في فايربيس (للمقارنة)
  String? get currentPhone => _auth.currentUser?.phoneNumber;

  // 3. دالة لجلب البريد الإلكتروني الحالي
  String? get currentEmail => _auth.currentUser?.email;
}