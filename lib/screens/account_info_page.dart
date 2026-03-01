//Rand
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/login_signup_background.dart'; // تأكد من المسار الصحيح
import '../widgets/custom_button1.dart';
import'../Widgets/custom_text_field.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  final String userEmail;
  final String loginProvider; // 'google', 'phone', أو 'email'
  final bool canEditPassword;

  const ProfilePage({
    super.key,
    required this.userEmail,
    required this.loginProvider,
    this.canEditPassword = false,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _emailController;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passController = TextEditingController();

  // القيم الأصلية للمقارنة (تأكدي من جلبها من قاعدة البيانات لاحقاً)
  late String _initialName = "رند خالد";
  late String _initialPhone = "593426953";

  bool _showNoChangeError = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.userEmail);
    _nameController.text = _initialName;
    _phoneController.text = _initialPhone;
  }

  // التحقق من وجود تغييرات حقيقية
  bool _checkIfDataChanged() {
    return _nameController.text != _initialName ||
        _phoneController.text != _initialPhone ||
        _passController.text.isNotEmpty;
  }

  void _onSavePressed() {
    if (!_checkIfDataChanged()) {
      setState(() => _showNoChangeError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("لم يتم إجراء أي تغييرات لحفظها")),
      );
    } else {
      setState(() => _showNoChangeError = false);
      // هنا تضعين كود التحديث في Firebase
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم حفظ التعديلات بنجاح")),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LoginSignupBackground(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Column(
            children: [
              // العنوان العلوي بدون صورة
              const Text(
                "الملف الشخصي",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5A4A75),
                    fontFamily: 'Cairo'
                ),
              ),
              const SizedBox(height: 40),

              // حقل الاسم
              _buildInputWrapper(
                isError: _showNoChangeError && _nameController.text == _initialName,
                child: CustomInputField(
                  label: "الاسم الكامل",
                  hintText: "أدخل اسمك هنا",
                  controller: _nameController,
                  fillColor: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 15),

              // حقل البريد - مقفل إذا دخل بالإيميل أو جوجل
              CustomInputField(
                label: "البريد الإلكتروني",
                hintText: "example@mail.com",
                controller: _emailController,
                readOnly: widget.loginProvider == 'email' || widget.loginProvider == 'google',
                fillColor: (widget.loginProvider == 'email' || widget.loginProvider == 'google')
                    ? Colors.grey.withOpacity(0.2)
                    : Colors.white.withOpacity(0.7),
              ),
              const SizedBox(height: 15),

              // حقل الجوال - مقفل إذا دخل بالجوال
              _buildInputWrapper(
                isError: _showNoChangeError && _phoneController.text == _initialPhone,
                child: CustomInputField(
                  label: "رقم الهاتف",
                  hintText: "+966 xxxxxxxxx",
                  controller: _phoneController,
                  readOnly: widget.loginProvider == 'phone',
                  fillColor: widget.loginProvider == 'phone'
                      ? Colors.grey.withOpacity(0.2)
                      : Colors.white.withOpacity(0.7),
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(height: 15),

              // حقل كلمة السر
              AbsorbPointer(
                absorbing: !widget.canEditPassword,
                child: _buildInputWrapper(
                  isError: _showNoChangeError && _passController.text.isEmpty,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: widget.canEditPassword
                          ? Border.all(color: Colors.green, width: 2)
                          : null,
                    ),
                    child: CustomInputField(
                      label: "كلمة السر الجديدة",
                      hintText: widget.canEditPassword
                          ? "أدخل كلمة سر قوية"
                          : "تعديل كلمة السر متاح عبر الاستعادة فقط",
                      controller: _passController,
                      isPass: true,
                      fillColor: widget.canEditPassword
                          ? Colors.white.withOpacity(0.9)
                          : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 35),

              WaterRippleButton(
                text: "حفظ التعديلات",
                width: 200,
                height: 50,
                onTap: _onSavePressed,
              ),

              const SizedBox(height: 30),

              // وسيلة الدخول (مكانها الجديد قبل الخروج)
              _buildProviderStatus(),

              const SizedBox(height: 10),

              TextButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                        (route) => false,
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.redAccent, size: 18),
                label: const Text(
                  "تسجيل الخروج",
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // حاوية الحدود الحمراء للتنبيه
  Widget _buildInputWrapper({required Widget child, required bool isError}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isError ? Colors.redAccent : Colors.transparent,
          width: 2,
        ),
      ),
      child: child,
    );
  }

  // عرض وسيلة الدخول
  Widget _buildProviderStatus() {
    IconData icon;
    String text;

    switch (widget.loginProvider) {
      case 'google':
        icon = Icons.g_mobiledata; text = "طريقة الدخول: حساب Google";
        break;
      case 'phone':
        icon = Icons.phone_android; text = "طريقة الدخول: رقم الجوال";
        break;
      default:
        icon = Icons.email_outlined; text = "طريقة الدخول: البريد الإلكتروني";
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: const Color(0xFF5A4A75), size: 20),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 13, color: Colors.grey, fontFamily: 'Cairo'),
        ),
      ],
    );
  }
}