//Rand
import 'package:dhallah_app/screens/account_info_page.dart';
import 'package:dhallah_app/services/authentication_serv.dart';
import 'package:flutter/material.dart';
import '../widgets/login_signup_background.dart';
import '../widgets/custom_button1.dart';
import'../Widgets/custom_text_field.dart';
import'../widgets/custom_text_link.dart';
import 'package:flutter/gestures.dart';
import '../screens/signup_page.dart';
import '../screens/ForgotPassword_page.dart';
// استيراد السيرفس الخاصة بك
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthenticationService _authService = AuthenticationService();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("الرجاء تعبئة جميع الحقول")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(userEmail: _emailController.text.trim()),
          ),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception:", "")),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoginSignupBackground(
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width > 600
                ? 400
                : MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 35),
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
                Image.asset('assets/images/logo.jpeg', height: 80, fit: BoxFit.contain),
                const SizedBox(height: 15),
                const Text(
                  "تسجيل الدخول",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF444444)),
                ),
                const Text(
                  "! هلابك من جديد ",
                  style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 30),

                // استخدام الـ Widget الجديد للحقول
                CustomInputField(
                  label: "البريد الإلكتروني",
                  hintText: "أدخل بريدك الإلكتروني",
                  controller: _emailController,
                  fillColor: const Color(0xFFFBF9FF), // حافظنا على نفس اللون
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 18),
                CustomInputField(
                  label: "كلمة السر",
                  hintText: "أدخل كلمة السر",
                  controller: _passwordController,
                  isPass: true,
                  fillColor: const Color(0xFFFBF9FF),
                ),

                const SizedBox(height: 30),

                WaterRippleButton(
                  text: "دخول",
                  onTap: _handleLogin,
                  isLoading: _isLoading,
                  width: double.infinity,
                  height: 55,
                ),

                const SizedBox(height: 20),

                // استخدام الـ Widget الجديد للروابط
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomTextLink(
                      text: "  قم بتسجيل حساب جديد  ",
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpPage()));
                      },
                    ),
                    const Text("ليس لديك حساب ؟   ", style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 12),
                CustomTextLink(
                  text: "نسيت كلمة السر؟",
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()));
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}