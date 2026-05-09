//database_serv.dart

// ---------------------------------------------------------
// (أولا) استيراد المكتبات والباكجيز
// ---------------------------------------------------------
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // نحتاجهاللالتوكن
// ---------------------------------------------------------
// (ثانيا) استيراد الصفحات الأخرى لإستخدامها
// ---------------------------------------------------------
import '../models/user_model.dart';
import '../services/authentication_serv.dart';

// ---------------------------------------------------------
//  (ثالثا) تعريف الكلاس والمتغيرات المطلوبة لبناء الصفحة والقيم المبدأية
// ---------------------------------------------------------
class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  AuthenticationService get _authService => AuthenticationService();

// ---------------------------------------------------------
//  (رابعا)  الدوال
// ---------------------------------------------------------
  Future<void> updateOrCreateUser(RegularUser user) async {
    try {
      final docRef = _db.collection('users').doc(user.userId);
      final docSnap = await docRef.get();
      if (docSnap.exists) {
        // إذا المستخدم موجود، نحدث البيانات مع الحفاظ على الاسم القديم إذا كان موجوداً
        Map<String, dynamic> existingData = docSnap.data() as Map<String, dynamic>;
        Map<String, dynamic> newData = user.toMap();

        if (existingData['userType'] == 'admin') {
          newData['userType'] = 'admin';
        }
        // حماية حالة الحظر (المحظور يبقى محظوراً ولا يتم تصفير حالته عند الدخول)
        if (existingData['isBanned'] == true) {
          newData['isBanned'] = true;
        }
        if (existingData['name'] != null && existingData['name'].toString().isNotEmpty) {
          newData.remove('name');
        }
        if (existingData['isProfileComplete'] == true) {
          newData.remove('isProfileComplete');
        }
        await docRef.set(newData, SetOptions(merge: true));
      } else {
        await docRef.set(user.toMap(), SetOptions(merge: true));
      }
    } catch (e) {
      throw "❌ خطأ في حفظ بيانات المستخدم في القاعدة: $e";
    }
  }

  /// حفظ التوكن فقط إذا كان غير موجود ///
  Future<void> getAndSaveFcmToken(String uid) async {
    try {
      final docSnap = await _db.collection('users').doc(uid).get();
      final data = docSnap.data();

      // إذا التوكن غير موجود، نجلبه ونخزنه
      if (data == null || !data.containsKey('fcmToken') || data['fcmToken'] == null) {
        final String? newToken = await FirebaseMessaging.instance.getToken();
        if (newToken != null) {
          await updateFcmToken(uid, newToken);
          print("✅ تم حفظ FCM Token بنجاح.");
        }
      } else {
        print("ℹ️ التوكن موجود مسبقاً.");
      }
    } catch (e) {
      print("❌ خطأ في حفظ Token: $e");
    }
  }

  Future<void> updateFcmToken(String uid, String token) async {
    await _db.collection('users').doc(uid).set({
      'fcmToken': token,
      'lastTokenUpdate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteFcmToken(String uid) async {
    try {
      await _db.collection('users').doc(uid).update({
        'fcmToken': FieldValue.delete(),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
      print("✅ تم حذف FCM Token بنجاح.");
    } catch (e) {
      print("❌ خطأ في حذف Token: $e");
    }
  }

  Future<bool> checkProfileCompletion(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final userData = RegularUser.fromMap(doc.data() as Map<String, dynamic>);
        return userData.isProfileComplete;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> loadUserData({
    required TextEditingController nameController,
    required TextEditingController phoneController,
    required TextEditingController emailController,
    required bool mounted,
    required Function(bool) setLoading,
    required Function(String) setFullPhone,
    required Function(VoidCallback) updateState,
  }) async {
    try {
      final user = _authService.getCurrentUser();
      if (user != null) {
        DocumentSnapshot doc = await _db.collection('users').doc(user.uid).get();
        if (doc.exists && mounted) {
          final userData = RegularUser.fromMap(doc.data() as Map<String, dynamic>);
          updateState(() {
            if (nameController.text.isEmpty) nameController.text = userData.name;
            if (userData.phone != null) {
              phoneController.text = userData.phone!.replaceFirst('+966', '');
              setFullPhone(userData.phone!);
            }
            if (userData.email.isNotEmpty) emailController.text = userData.email;
          });
        }
      }
    } catch (e) {
      debugPrint("❌خطأ في جلب البيانات:$e");
    } finally {
      setLoading(false);
    }
  }

  ///الداله اللي بتستخدم في صفحه البروفايل أو معلومات الحساب ///
  Future<void> saveProfile(RegularUser user) async {
    await _db.collection('users').doc(user.userId).set(
      user.toMap(updateTime: true),
      SetOptions(merge: true),
    );
  }

  Future<bool> isFieldTaken(String field, String value, String currentUid) async {
    final query = await _db.collection('users').where(field, isEqualTo: value).get();
    return query.docs.any((doc) => doc.id != currentUid);
  }

  Future<dynamic> getUserById(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // التحقق من نوع المستخدم بناءً على الحقل في Firestore
        if (data['userType'] == 'admin') {
          return Admin.fromMap(data);
        } else {
          return RegularUser.fromMap(data);
        }
      }
    } catch (e) {
      debugPrint("❌خطأ في جلب كائن المستخدم:$e");
    }
    return null;
  }

 /// لمراقبة بيانات المستخدم لحظياً ///
  Stream<dynamic> getUserStream(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }
}