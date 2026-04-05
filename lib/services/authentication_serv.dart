// authentication_serv.dart
// Rand - Full Authentication Service (Email, Phone, & Google with Smart Linking)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthenticationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- حفظ/تحديث المستخدم في Firestore ---
  // نستخدم merge: true لضمان عدم مسح البيانات القديمة
  Future<void> _saveUserData(User user) async {
    await _firestore.collection('users').doc(user.uid).set({
      'name': user.displayName ?? "مستخدم",
      'email': user.email,
      'phone': user.phoneNumber, // سيتم تخزينه هنا تلقائياً بعد نجاح الربط
      'lastUpdate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // --- 1. تسجيل الدخول بجوجل (مع الربط التلقائي) ---
  Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      User? currentUser = _auth.currentUser;

      if (currentUser != null) {
        try {
          final result = await currentUser.linkWithCredential(credential);
          await _saveUserData(result.user!);
          return result.user;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use') {
            final result = await _auth.signInWithCredential(credential);
            await _saveUserData(result.user!);
            return result.user;
          } else {
            throw Exception(e.message);
          }
        }
      } else {
        final result = await _auth.signInWithCredential(credential);
        await _saveUserData(result.user!);
        return result.user;
      }
    } catch (e) {
      print("خطأ في دخول قوقل: $e");
      rethrow;
    }
  }

  // --- 2. تسجيل دخول بالإيميل ---
  Future<User?> login(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      User? user = result.user;
      await user?.reload();
      user = _auth.currentUser;

      if (user != null && !user.emailVerified) {
        await logout();
        throw Exception("الرجاء تفعيل البريد الإلكتروني أولاً.");
      }

      await _saveUserData(user!);
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
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
      if (password != confirmPassword) throw Exception("كلمتا المرور غير متطابقتين!");
      if (!validatePassword(password)) throw Exception("كلمة المرور يجب أن تكون 6 خانات على الأقل");

      final result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;

      if (user != null) {
        await user.updateDisplayName(username);
        await _saveUserData(user);
        await user.sendEmailVerification();
      }
      return user;
    } catch (e) {
      rethrow;
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
        verificationCompleted: (PhoneAuthCredential credential) async {
          // التحقق التلقائي (في بعض أجهزة أندرويد)
          User? user = _auth.currentUser;
          if (user != null) {
            await user.linkWithCredential(credential);
            await _saveUserData(user);
          }
        },
        verificationFailed: (FirebaseAuthException e) => onError(e.message ?? "حدث خطأ"),
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
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      User? user = _auth.currentUser;
      if (user != null) {
        // نربط الرقم بالحساب الحالي (الإيميل) لتوحيد الـ UID
        final result = await user.linkWithCredential(credential);
        await _saveUserData(result.user!);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        throw Exception("هذا الرقم مرتبط بحساب آخر بالفعل.");
      }
      throw Exception("كود التحقق غير صحيح");
    }
  }

  // --- 6. تسجيل الدخول العادي بالـ OTP (في حال لم يكن هناك حساب حالي) ---
  Future<User?> signInWithOTP(String verificationId, String smsCode) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final result = await _auth.signInWithCredential(credential);
      await _saveUserData(result.user!);
      return result.user;
    } catch (e) {
      throw Exception("كود التحقق غير صحيح");
    }
  }

  // --- وظائف مساعدة ---
  bool validatePassword(String password) => password.length >= 6;

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}