//Rand
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../widgets/login_signup_background.dart'; // تأكد من المسار الصحيح
import '../widgets/custom_button1.dart';
import'../Widgets/custom_text_field.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  final String userEmail;
  final String? initialPhoneNumber;
  final String loginProvider;
  final bool canEditPassword;

  const ProfilePage({
    super.key,
    required this.userEmail,
    this.initialPhoneNumber,
    required this.loginProvider,
    this.canEditPassword = false,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  final _nameController = TextEditingController();
  final _passController = TextEditingController();

  String _fullPhoneNumber = "";
  bool _isLoading = true;
  bool _isSaving = false; // لحالة تحميل زر الحفظ

  @override
  void initState() {
    super.initState();
    // إذا كان المزود هو البريد، نضع القيمة في كنترولر الإيميل، وإلا نتركه فارغاً ليجلب من Firestore
    _emailController = TextEditingController(
        text: widget.loginProvider == 'email' ? widget.userEmail : ""
    );

    _phoneController = TextEditingController(
        text: widget.initialPhoneNumber?.replaceFirst('+966', '') ?? ""
    );

    _fullPhoneNumber = widget.initialPhoneNumber ?? "";
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // البحث في الداتابيس باستخدام الرقم التعريفي الفريد
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          setState(() {
            _nameController.text = data['name'] ?? "";
            // عرض البيانات المخزنة مسبقاً
            if (data['phone'] != null) {
              _phoneController.text = data['phone'].replaceFirst('+966', '');
              _fullPhoneNumber = data['phone'];
            }
            if (data['email'] != null) {
              _emailController.text = data['email'];
            }
          });
        }
      }
    } catch (e) {
      debugPrint("خطأ في جلب البيانات: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- دالة حفظ البيانات في الفايربيس ---
  Future<void> _onSavePressed() async {
    setState(() => _isSaving = true);
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // 1. تحديث كلمة السر في Firebase Auth (إذا كان مسموحاً له بالتعديل)
      if (widget.canEditPassword && _passController.text.isNotEmpty) {
        // هذا السطر يغير كلمة السر الفعلية للمستخدم في نظام الحماية
        await FirebaseAuth.instance.currentUser!.updatePassword(_passController.text.trim());
      }

      // 2. تحديث البيانات في Firestore
      await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set({
        'name': _nameController.text.trim(),
        'phone': _fullPhoneNumber.trim(),
        'email': _emailController.text.trim(),
        'lastUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم تحديث كلمة السر والبيانات بنجاح ✅"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint("Error saving: $e");
      // تنبيه: الفايربيس قد يطلب تسجيل دخول حديث (Recent Login) لتغيير كلمة السر
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoginSignupBackground(
      child: Center(
        child: _isLoading
            ? const CircularProgressIndicator(color: Color(0xFF5A4A75))
            : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Column(
            children: [
              const Text("الملف الشخصي", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF5A4A75), fontFamily: 'Cairo')),
              const SizedBox(height: 40),

              // الاسم (مفتوح دائماً)
              CustomInputField(
                label: "الاسم الكامل",
                hintText: "أدخل اسمك هنا",
                controller: _nameController,
                fillColor: Colors.white.withOpacity(0.7),
              ),
              const SizedBox(height: 15),

              // الإيميل (مقفل إذا كان مسجل بالإيميل أو قوقل)
              CustomInputField(
                label: "البريد الإلكتروني",
                hintText: "example@mail.com",
                controller: _emailController,
                readOnly: widget.loginProvider == 'email' || widget.loginProvider == 'google',
                fillColor: (widget.loginProvider == 'email' || widget.loginProvider == 'google')
                    ? Colors.grey.withOpacity(0.3)
                    : Colors.white.withOpacity(0.7),
              ),
              const SizedBox(height: 15),

              // رقم الهاتف
              const Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(right: 8, bottom: 8),
                  child: Text("رقم الهاتف", style: TextStyle(color: Color(0xFF5A4A75), fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
              // مقفل إذا دخل بالجوال
              AbsorbPointer(
                absorbing: widget.loginProvider == 'phone',
                child: IntlPhoneField(
                  controller: _phoneController,
                  disableLengthCheck: true,
                  textAlign: TextAlign.left,
                  decoration: InputDecoration(
                    hintText: '5xxxxxxx',
                    fillColor: widget.loginProvider == 'phone' ? Colors.grey.withOpacity(0.3) : Colors.white.withOpacity(0.7),
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                  initialCountryCode: 'SA',
                  onChanged: (phone) {
                    _fullPhoneNumber = phone.completeNumber;
                  },
                ),
              ),
              const SizedBox(height: 15),

              // كلمة السر (مقفولة للتعديل المباشر كما طلبت)
              // ابحث عن حقل كلمة السر واستبدله بهذا المنطق
              CustomInputField(
                label: "كلمة السر الجديدة",
                hintText: widget.canEditPassword ? "أدخل كلمة السر الجديدة" : "التعديل متاح عبر الاستعادة فقط",
                controller: _passController,
                isPass: true,
                // التعديل: الخانة تفتح فقط إذا كان canEditPassword = true
                readOnly: !widget.canEditPassword,
                fillColor: widget.canEditPassword ? Colors.white.withOpacity(0.7) : Colors.grey.withOpacity(0.3),
              ),

              const SizedBox(height: 35),

              WaterRippleButton(
                  text: _isSaving ? "جاري الحفظ..." : "حفظ التعديلات",
                  width: 200,
                  height: 50,
                  onTap: _isSaving ? () {} : _onSavePressed
              ),

              const SizedBox(height: 30),
              _buildProviderStatus(),

              TextButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false);
                },
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text("تسجيل الخروج", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderStatus() {
    IconData icon;
    String providerName;

    if (widget.loginProvider == 'phone') {
      icon = Icons.phone_android;
      providerName = "رقم الجوال";
    } else if (widget.loginProvider == 'google') {
      icon = Icons.g_mobiledata;
      providerName = "حساب Google";
    } else {
      icon = Icons.email_outlined;
      providerName = "البريد الإلكتروني";
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: const Color(0xFF5A4A75), size: 20),
        const SizedBox(width: 8),
        Text("طريقة الدخول: $providerName", style: const TextStyle(fontSize: 13, color: Colors.grey, fontFamily: 'Cairo')),
      ],
    );
  }
}