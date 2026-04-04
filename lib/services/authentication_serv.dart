// authentication_serv.dart
// Rand - Full Authentication Service (Email, Phone, & Google)
// تم التحديث لمنع تكرار البريد الإلكتروني ورقم الجوال في قاعدة البيانات

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthenticationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- 1. تسجيل الدخول بجوجل ---
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      if (user != null) {
        // حفظ بيانات مستخدم جوجل إذا كان جديداً مع دمج البيانات
        await _firestore.collection('users').doc(user.uid).set({
          'name': user.displayName ?? "مستخدم جوجل",
          'email': user.email,
          'lastUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      return user;
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
        throw Exception("الرجاء تفعيل حسابك عبر الرابط المرسل إلى بريدك الإلكتروني أولاً.");
      }
      return user;
    } on FirebaseAuthException catch (e) {
      rethrow;
    }
  }

  // --- 3. تسجيل مستخدم جديد (مع منع تكرار البريد) ---
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

      // ** فحص Firestore للتأكد من أن البريد غير مستخدم مسبقاً **
      final emailCheck = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .get();

      if (emailCheck.docs.isNotEmpty) {
        throw Exception("هذا البريد الإلكتروني مسجل بالفعل بحساب آخر.");
      }

      if (!validatePassword(password)) {
        throw Exception("كلمة المرور يجب أن تكون 6 خانات على الأقل");
      }

      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      User? user = result.user;

      if (user != null) {
        await user.updateDisplayName(username);

        // حفظ البيانات الأساسية في Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'name': username,
          'email': email,
          'isProfileComplete': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await user.sendEmailVerification();
        await logout();
      }
      return user;
    } catch (e) {
      print("خطأ في التسجيل: $e");
      rethrow;
    }
  }

  // --- 4. التحقق من رقم الجوال (مع منع تكرار الرقم) ---
  // --- 4. التحقق من رقم الجوال (للدخول الصريح) ---
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    try {
      // أزلنا الفحص من هنا لنسمح للمستخدم المسجل مسبقاً بالدخول
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
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
      UserCredential result = await _auth.signInWithCredential(credential);
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

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

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