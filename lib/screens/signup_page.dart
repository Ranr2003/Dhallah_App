//Rand
import 'package:dhallah_app/services/authentication_serv.dart';
import 'package:flutter/material.dart';
import '../widgets/login_signup_background.dart';
import '../widgets/custom_button1.dart';
import'../Widgets/custom_text_field.dart';
import'../widgets/custom_text_link.dart';
import 'package:flutter/gestures.dart';
import '../screens/login_page.dart';
// استيراد السيرفس الخاصة بك

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final AuthenticationService _authService = AuthenticationService();

  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignUp() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("الرجاء تعبئة جميع الحقول")),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final user = await _authService.register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        confirmPassword: _confirmPasswordController.text.trim(),
      );

      if (user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم إنشاء الحساب بنجاح!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("خطأ في التسجيل: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoginSignupBackground(
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width > 600 ? 400 : MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD2B4EC).withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/logo.jpeg', height: 70, fit: BoxFit.contain),
                const SizedBox(height: 10),
                const Text(
                  "تسجيل الحساب",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                ),
                const Text(
                  "سجل معلوماتك ونكمل مشوارنا",
                  style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 25),

                // استخدام الـ InputField الموحد
                CustomInputField(
                  label: "الاسم الكامل",
                  hintText: "أدخل اسمك الثلاثي",
                  controller: _usernameController,
                ),
                const SizedBox(height: 15),
                CustomInputField(
                  label: "البريد الإلكتروني",
                  hintText: "example@mail.com",
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 15),
                CustomInputField(
                  label: "كلمة السر",
                  hintText: "أدخل كلمة السر",
                  controller: _passwordController,
                  isPass: true,
                ),
                const SizedBox(height: 15),
                CustomInputField(
                  label: "تأكيد كلمة السر",
                  hintText: "أعد كتابة كلمة السر",
                  controller: _confirmPasswordController,
                  isPass: true,
                ),

                const SizedBox(height: 25),

                WaterRippleButton(
                  text: "قم بالتسجيل",
                  onTap: _handleSignUp,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 20),

                // استخدام الـ TextLink الموحد
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomTextLink(
                      text: "  قم بتسجيل الدخول  ",
                      onTap: () => Navigator.pop(context),
                    ),
                    const Text("لديك حساب بالفعل؟ ", style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}