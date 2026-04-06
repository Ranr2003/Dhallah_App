// account_info_page.dart
// تم التحديث بواسطة رند بدعم Gemini (منطق الربط الذكي وتوحيد الـ UID)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../widgets/login_signup_background.dart';
import '../widgets/custom_button1.dart';
import '../widgets/custom_text_field.dart';
import '../services/authentication_serv.dart'; // تأكدي من استيراد ملف الخدمة
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
  final AuthenticationService _authService = AuthenticationService();

  String _fullPhoneNumber = "";
  bool _isLoading = true;
  bool _isSaving = false;
  String _verificationId = "";

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

  // --- دالة الحفظ النهائية في Firestore ---
  Future<void> _finalSave() async {
    setState(() => _isSaving = true);
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

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
      _showError("حدث خطأ أثناء الحفظ: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- دالة الحفظ الذكية ---
  // --- دالة الحفظ الذكية المحدثة (رند & Gemini) ---
  Future<void> _onSavePressed() async {
    final String enteredEmail = _emailController.text.trim();
    final String enteredName = _nameController.text.trim();

    // 1. التحقق من الحقول الفارغة
    if (enteredName.isEmpty || _fullPhoneNumber.trim().isEmpty) {
      _showError("الرجاء إدخال الاسم ورقم الجوال أولاً");
      return;
    }

    setState(() => _isSaving = true);

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // 2. فحص هل الإيميل مستخدم بالفعل (في حال كان الحقل متاحاً للتعديل)
      // فقط إذا كان المستخدم داخل بالجوال (isEmailLocked = false) أو غير إيميله بطريقة ما
      if (widget.loginProvider == 'phone' && enteredEmail.isNotEmpty) {
        final emailCheck = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: enteredEmail)
            .get();

        // إذا وجدنا إيميل مطابق لمستخدم آخر (UID مختلف)
        if (emailCheck.docs.isNotEmpty && emailCheck.docs.first.id != currentUser.uid) {
          _showError("عذراً، هذا البريد الإلكتروني مسجل بالفعل بحساب آخر!");
          return;
        }
      }

      // 3. فحص رقم الجوال والتعامل مع الربط (OTP)
      bool isPhoneChanged = _fullPhoneNumber.trim() != (currentUser.phoneNumber ?? "");

      // إذا كان المستخدم داخل بالإيميل وغير الرقم -> نطلب تحقق للربط
      if (widget.loginProvider != 'phone' && isPhoneChanged) {

        // فحص أولي للجوال في Firestore
        final phoneCheck = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: _fullPhoneNumber.trim())
            .get();

        if (phoneCheck.docs.isNotEmpty && phoneCheck.docs.first.id != currentUser.uid) {
          _showError("عذراً، رقم الجوال هذا مرتبط بحساب آخر بالفعل!");
          return;
        }

        // إذا الرقم سليم، نبدأ عملية الـ OTP
        _startPhoneVerification();
      } else {
        // 4. الحفظ النهائي إذا كان كل شيء سليماً (الاسم، الإيميل، أو رقم لم يتغير)
        await _finalSave();
      }
    } catch (e) {
      _showError("حدث خطأ أثناء الفحص: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- دالة إرسال الكود للربط ---
  void _startPhoneVerification() async {
    setState(() => _isSaving = true);
    await _authService.verifyPhoneNumber(
      phoneNumber: _fullPhoneNumber,
      onCodeSent: (id) {
        setState(() {
          _isSaving = false;
          _verificationId = id;
        });
        _showOtpDialog();
      },
      onError: (err) {
        setState(() => _isSaving = false);
        _showError(err);
      },
    );
  }

  // --- نافذة إدخال كود الـ OTP ---
  // --- نافذة إدخال كود الـ OTP (تحديث الشكل فقط) ---
  void _showOtpDialog() {
    // نحتفظ بنفس المنطق الأصلي: قائمة من الـ Controllers
    final List<TextEditingController> otpControllers = List.generate(6, (index) => TextEditingController());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // لجعل الحواف العلوية تظهر بشكل دائري خلفية بيضاء
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          // استخدام نفس الـ Decoration الموحد للنافذة
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // خط السحب العلوي للجمالية
              Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 25),

              const Text("تحقق من الرقم لربط الحساب",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF444444))),
              const SizedBox(height: 10),
              Text("أدخل الرمز المرسل إلى $_fullPhoneNumber",
                  style: const TextStyle(fontSize: 13, color: Colors.grey), textAlign: TextAlign.center),
              const SizedBox(height: 30),

              // صف مربعات الـ OTP الموحدة شكلياً
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) => SizedBox(
                  width: 45,
                  child: TextField(
                    // نحتفظ بالـ Controller الأصلي
                    controller: otpControllers[index],
                    autofocus: index == 0,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    // استخدام نفس الـ Style الموحد للنص
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF673AB7)),
                    // تطبيق نفس الـ Decoration الموحد للمربعات (بدون منطق تغيير اللون للخطأ)
                    decoration: InputDecoration(
                      counterText: "",
                      fillColor: const Color(0xFFFBF9FF),
                      filled: true,
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFEEEEEE))
                      ),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF673AB7), width: 2)
                      ),
                    ),
                    onChanged: (value) {
                      // التنقل التلقائي للأمام عند الكتابة
                      if (value.length == 1 && index < 5) FocusScope.of(context).nextFocus();
                      // التنقل التلقائي للخلف عند الحذف
                      if (value.isEmpty && index > 0) FocusScope.of(context).previousFocus();
                    },
                  ),
                )),
              ),

              const SizedBox(height: 35),

              WaterRippleButton(
                text: "تأكيد وربط الحساب",
                // نحتفظ بنفس منطق الحفظ الأصلي
                onTap: () async {
                  String smsCode = otpControllers.map((e) => e.text).join();
                  try {
                    await _authService.linkPhoneNumber(_verificationId, smsCode);
                    if (mounted) Navigator.pop(context); // إغلاق الشيت
                    await _finalSave(); // الحفظ النهائي في Firestore
                  } catch (e) {
                    // نحتفظ بنفس منطق إظهار الخطأ الأصلي عبر SnackBar
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("كود التحقق غير صحيح")));
                  }
                },
                width: double.infinity,
                height: 55,
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
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
    // تعريف حالات القفل بناءً على طريقة الدخول
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

                // حقل الاسم
                CustomInputField(
                  label: "الاسم الكامل",
                  hintText: "أدخل اسمك هنا",
                  controller: _nameController,
                  fillColor: Colors.white.withOpacity(0.7),
                ),
                const SizedBox(height: 15),

                // حقل الإيميل (مقفل إذا دخل بالإيميل أو جوجل)
                CustomInputField(
                  label: "البريد الإلكتروني",
                  hintText: "example@mail.com",
                  controller: _emailController,
                  readOnly: isEmailLocked,
                  fillColor: isEmailLocked ? Colors.grey.withOpacity(0.2) : Colors.white.withOpacity(0.7),
                ),
                const SizedBox(height: 15),

                // حقل رقم الهاتف
                const Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 8, bottom: 8),
                    child: Text("رقم الهاتف",
                        style: TextStyle(color: Color(0xFF5A4A75), fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),

                // قفل الحقل وتغيير لونه إذا كان الدخول بالجوال
                AbsorbPointer(
                  absorbing: isPhoneLocked,
                  child: IntlPhoneField(
                    controller: _phoneController,
                    disableLengthCheck: true,
                    textAlign: TextAlign.left,
                    decoration: InputDecoration(
                      hintText: '5xxxxxxx',
                      fillColor: isPhoneLocked
                          ? Colors.grey.withOpacity(0.2)
                          : Colors.white.withOpacity(0.7),
                      filled: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none),
                    ),
                    initialCountryCode: 'SA',
                    onChanged: (phone) => _fullPhoneNumber = phone.completeNumber,
                  ),
                ),
                const SizedBox(height: 15),

                // حقل كلمة السر
                CustomInputField(
                  label: "كلمة السر الجديدة",
                  hintText: widget.canEditPassword ? "أدخل كلمة السر الجديدة" : "التعديل متاح عبر الاستعادة فقط",
                  controller: _passController,
                  isPass: true,
                  readOnly: !widget.canEditPassword,
                  fillColor: widget.canEditPassword ? Colors.white.withOpacity(0.7) : Colors.grey.withOpacity(0.2),
                ),

                const SizedBox(height: 35),

                // زر الحفظ
                WaterRippleButton(
                    text: _isSaving ? "جاري الحفظ..." : "حفظ التعديلات",
                    width: 200,
                    height: 50,
                    onTap: _isSaving ? () {} : _onSavePressed
                ),

                const SizedBox(height: 30),
                _buildProviderStatus(),

                // زر تسجيل الخروج
                TextButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (mounted) {
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false);
                    }
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