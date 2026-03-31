//database_serv.dart
//Rand
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  // المرجع الأساسي لقاعدة البيانات (بديل للـ ConnectionString)
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. إضافة سجل (Insert)
  Future<bool> insertRecord(String collection, Map<String, dynamic> data) async {
    try {
      await _db.collection(collection).add(data);
      return true;
    } catch (e) {
      print("Error inserting record: $e");
      return false;
    }
  }

  // 2. تحديث سجل (Update)
  Future<bool> updateRecord(String collection, String id, Map<String, dynamic> data) async {
    try {
      await _db.collection(collection).doc(id).update(data);
      return true;
    } catch (e) {
      return false;
    }
  }

  // 3. حذف سجل (Delete)
  Future<bool> deleteRecord(String collection, String id) async {
    try {
      await _db.collection(collection).doc(id).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

// 4. البحث عن مستخدم بواسطة الإيميل
  Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    // بدلاً من '==' نستخدم المعامل المدمج isEqualTo
    final query = await _db
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    return query.docs.isNotEmpty ? query.docs.first.data() : null;
  }

// 5. هل الإيميل مسجل مسبقاً؟
  Future<bool> isEmailRegistered(String email) async {
    final query = await _db
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    return query.docs.isNotEmpty;
  }

  // 6. حفظ بيانات المستخدم (بعد التسجيل)
  Future<bool> saveUserRecord(String uid, Map<String, dynamic> userData) async {
    try {
      await _db.collection('users').doc(uid).set(userData);
      return true;
    } catch (e) {
      return false;
    }
  }

  // 7. حفظ الأغراض المفقودة والموجودة
  Future<bool> saveLostItem(Map<String, dynamic> data) async => await insertRecord('lostItems', data);
  Future<bool> saveFoundItem(Map<String, dynamic> data) async => await insertRecord('foundItems', data);

  // 8. جلب قوائم الأغراض
  Future<List<Map<String, dynamic>>> findPotentialLostItems() async {
    final snapshot = await _db.collection('lostItems').get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<List<Map<String, dynamic>>> findPotentialFoundItems() async {
    final snapshot = await _db.collection('foundItems').get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}