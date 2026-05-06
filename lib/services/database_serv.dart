//database_serv.dart // اضفته من برانش ليلى
//Rand

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_messaging/firebase_messaging.dart'; // نحتاجها لجلب التوكن
import '../models/user_model.dart';


class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // هذه الدالة ستكون البديل لـ _saveUserData التي كانت في ملف المصادقة
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

        // 2. حماية حالة الحظر (المحظور يبقى محظوراً ولا يتم تصفير حالته عند الدخول)
        if (existingData['isBanned'] == true) {
          newData['isBanned'] = true;
        }

        if (existingData['name'] != null && existingData['name'].toString().isNotEmpty) {
          newData.remove('name'); // نحذف الاسم من البيانات الجديدة لكي لا يمسح القديم في الـ merge
        }
        // 2. الحماية الجديدة: لا تسمح للدخول الجديد بمسح حالة "اكتمال الملف"
        // إذا كانت القيمة في قاعدة البيانات true، احذفها من الماب الجديد لكي لا نغيرها لـ false
        if (existingData['isProfileComplete'] == true) {
          newData.remove('isProfileComplete');
        }

        await docRef.set(newData, SetOptions(merge: true));
      } else {
        // إذا مستخدم جديد كلياً
        await docRef.set(user.toMap(), SetOptions(merge: true));
      }
    } catch (e) {
      throw "خطأ في حفظ بيانات المستخدم في القاعدة: $e";
    }
  }
// ─────────────────────────────────────────────────────────────────────────
  // [جديد] دوال الـ Token انتقلت هنا للحفاظ على التجريد
  // ─────────────────────────────────────────────────────────────────────────

  // حفظ التوكن فقط إذا كان غير موجود
  Future<void> saveFcmTokenIfNeeded(String uid) async {
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

  // تحديث التوكن (تُستخدم عند التجديد أو الحفظ الإجباري)
  Future<void> updateFcmToken(String uid, String token) async {
    await _db.collection('users').doc(uid).set({
      'fcmToken': token,
      'lastTokenUpdate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // حذف التوكن (عند تسجيل الخروج)
  // داخل ملف database_serv.dart
  Future<void> deleteFcmToken(String uid) async {
    try {
      await _db.collection('users').doc(uid).update({
        'fcmToken': FieldValue.delete(),
        'lastTokenUpdate': FieldValue.serverTimestamp(), // اختياري لتسجيل وقت الخروج
      });
      print("FCM Token deleted from Firestore");
    } catch (e) {
      print("Error deleting FCM token: $e");
      // لا نرفع خطأ هنا (throw) لكي لا يتوقف تسجيل الخروج إذا فشل حذف التوكن
    }
  }

  /// دالة مهمتها فقط إخبارنا: هل هذا المستخدم أكمل ملفه أم لا؟
  Future<bool> checkProfileCompletion(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final userData = RegularUser.fromMap(doc.data() as Map<String, dynamic>);
        return userData.isProfileComplete;
      }
      return false; // إذا لم يجد السجل نعتبره غير مكتمل
    } catch (e) {
      return false; // في حال حدوث خطأ، نوجهه لإكمال البيانات للأمان
    }
  }
// 1. خوارزمية الجلب (نفس كودك بالضبط)
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
      fb.User? user = fb.FirebaseAuth.instance.currentUser;
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
      debugPrint("خطأ في جلب البيانات: $e");
    } finally {
      setLoading(false);
    }
  }

  Future<void> saveProfile(RegularUser user) async {
    await _db.collection('users').doc(user.userId).set(
      user.toMap(),
      SetOptions(merge: true),
    );
  }

  // 2. خوارزمية الفحص (هل القيمة مستخدمة من شخص آخر؟)
  Future<bool> isFieldTaken(String field, String value, String currentUid) async {
    final query = await _db.collection('users').where(field, isEqualTo: value).get();
    // نرجع true فقط إذا وجدنا شخصاً آخر (UID مختلف) يستخدم نفس القيمة
    return query.docs.any((doc) => doc.id != currentUid);
  }
  /// الدالة المحدثة: تجلب المستخدم وتحدد نوعه تلقائياً
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
      debugPrint("خطأ في جلب كائن المستخدم: $e");
    }
    return null;
  }
// دالة تعيد Stream لمراقبة بيانات المستخدم لحظياً
  Stream<dynamic> getUserStream(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }
}