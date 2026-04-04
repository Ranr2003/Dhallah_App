// account_info_page.dart
// تم التحديث بواسطة رند (منطق رسائل الخطأ الذكي بناءً على طريقة الدخول)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../widgets/login_signup_background.dart';
import '../widgets/custom_button1.dart';
import '../widgets/custom_text_field.dart';
import 'login_page.dart';
import 'home_page.dart';

class ProfilePage extends StatefulWidget {
  final String userEmail;
  final String? initialPhoneNumber;
  final String? initialName;
  final String loginProvider;
  final bool canEditPassword;

  const ProfilePage({
    super.key,
    required this.userEmail,
    this.initialPhoneNumber,
    this.initialName,
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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
        text: widget.loginProvider == 'email' || widget.loginProvider == 'google'
            ? widget.userEmail
            : ""
    );
    _nameController.text = widget.initialName ?? "";
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
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && mounted) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          setState(() {
            if (_nameController.text.isEmpty) _nameController.text = data['name'] ?? "";
            if (data['phone'] != null) {
              _phoneController.text = data['phone'].replaceFirst('+966', '');
              _fullPhoneNumber = data['phone'];
            }
            if (data['email'] != null) _emailController.text = data['email'];
          });
        }
      }
    } catch (e) {
      debugPrint("خطأ في جلب البيانات: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onSavePressed() async {
    if (_nameController.text.trim().isEmpty || _fullPhoneNumber.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("الرجاء إدخال الاسم ورقم الجوال أولاً"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // --- 1. إجراء الفحوصات ---
      final phoneCheck = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: _fullPhoneNumber.trim())
          .get();

      final emailCheck = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: _emailController.text.trim())
          .get();

      // --- 2. منطق الرسائل الذكي حسب طريقة الدخول ---

      if (widget.loginProvider == 'phone') {
        // إذا داخل بالجوال، الأولوية لفحص الإيميل لأنه الحقل المتاح للتغيير
        if (emailCheck.docs.isNotEmpty && emailCheck.docs.first.id != currentUser.uid) {
          _showError("عذراً، هذا البريد الإلكتروني مسجل بالفعل بحساب آخر!");
          return;
        }
      } else {
        // إذا داخل بالإيميل أو جوجل، الأولوية لفحص الجوال لأنه الحقل المتاح للتغيير
        if (phoneCheck.docs.isNotEmpty && phoneCheck.docs.first.id != currentUser.uid) {
          _showError("عذراً، رقم الجوال هذا مرتبط بحساب آخر بالفعل!");
          return;
        }
        // فحص ثانوي للإيميل في حال تمكن من تغييره بطريقة ما
        if (emailCheck.docs.isNotEmpty && emailCheck.docs.first.id != currentUser.uid) {
          _showError("عذراً، هذا البريد الإلكتروني مسجل بالفعل بحساب آخر!");
          return;
        }
      }

      // --- 3. حفظ البيانات ---
      if (widget.canEditPassword && _passController.text.isNotEmpty) {
        await currentUser.updatePassword(_passController.text.trim());
      }

      await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set({
        'name': _nameController.text.trim(),
        'phone': _fullPhoneNumber.trim(),
        'email': _emailController.text.trim(),
        'isProfileComplete': true,
        'lastUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم تحديث البيانات بنجاح ✅"), backgroundColor: Colors.green),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
              (route) => false,
        );
      }
    } catch (e) {
      _showError("حدث خطأ: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isEmailLocked = widget.loginProvider == 'email' || widget.loginProvider == 'google';
    bool isPhoneLocked = widget.loginProvider == 'phone';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF5A4A75)),
          onPressed: () => Navigator.pushAndRemoveUntil(
              context, MaterialPageRoute(builder: (context) => const HomePage()), (route) => false),
        ),
      ),
      body: LoginSignupBackground(
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator(color: Color(0xFF5A4A75))
              : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
            child: Column(
              children: [
                const Text("الملف الشخصي",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF5A4A75))),
                const SizedBox(height: 40),

                CustomInputField(
                  label: "الاسم الكامل",
                  hintText: "أدخل اسمك هنا",
                  controller: _nameController,
                  fillColor: Colors.white.withOpacity(0.7),
                ),
                const SizedBox(height: 15),

                CustomInputField(
                  label: "البريد الإلكتروني",
                  hintText: "example@mail.com",
                  controller: _emailController,
                  readOnly: isEmailLocked,
                  fillColor: isEmailLocked ? Colors.grey.withOpacity(0.2) : Colors.white.withOpacity(0.7),
                ),
                const SizedBox(height: 15),

                const Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 8, bottom: 8),
                    child: Text("رقم الهاتف",
                        style: TextStyle(color: Color(0xFF5A4A75), fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
                AbsorbPointer(
                  absorbing: isPhoneLocked,
                  child: IntlPhoneField(
                    controller: _phoneController,
                    disableLengthCheck: true,
                    textAlign: TextAlign.left,
                    decoration: InputDecoration(
                      hintText: '5xxxxxxx',
                      fillColor: isPhoneLocked ? Colors.grey.withOpacity(0.2) : Colors.white.withOpacity(0.7),
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                    initialCountryCode: 'SA',
                    onChanged: (phone) => _fullPhoneNumber = phone.completeNumber,
                  ),
                ),
                const SizedBox(height: 15),

                CustomInputField(
                  label: "كلمة السر الجديدة",
                  hintText: widget.canEditPassword ? "أدخل كلمة السر الجديدة" : "التعديل متاح عبر الاستعادة فقط",
                  controller: _passController,
                  isPass: true,
                  readOnly: !widget.canEditPassword,
                  fillColor: widget.canEditPassword ? Colors.white.withOpacity(0.7) : Colors.grey.withOpacity(0.2),
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
        Text("طريقة الدخول: $providerName", style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }
}