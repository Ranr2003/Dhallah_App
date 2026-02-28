import '../widgets/login_signup_background.dart';
import '../widgets/custom_button1.dart';
import'../Widgets/custom_text_field.dart';
import'../widgets/custom_text_link.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى إدخال البريد الإلكتروني")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) _showSuccessDialog();
    } on FirebaseAuthException catch (e) {
      String errorMessage = "حدث خطأ غير متوقع";
      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        errorMessage = "هذا البريد الإلكتروني غير مسجل لدينا أو غير صحيح";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage, textAlign: TextAlign.right)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("تم الإرسال", textAlign: TextAlign.right),
        content: const Text("إذا كان الحساب موجوداً، فستصلك رسالة بالرابط.", textAlign: TextAlign.right),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("حسناً")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoginSignupBackground(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_reset, size: 100, color: Color(0xFFB293CD)),
                    const SizedBox(height: 20),
                    const Text(
                      "استعادة كلمة المرور",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFB293CD)),
                    ),
                    const SizedBox(height: 40),

                    // استخدام الحقل الموحد مع الـ hintText (تعديلك المفضل)
                    CustomInputField(
                      label: "البريد الإلكتروني",
                      hintText: "أدخل بريدك المسجل لدينا",
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      fillColor: Colors.white.withOpacity(0.9), // حافظنا على شفافية الصفحة
                    ),

                    const SizedBox(height: 30),

                    // الزر المائي الموحد
                    WaterRippleButton(
                      text: "إرسال الرابط",
                      onTap: _sendResetLink,
                      isLoading: _isLoading,
                    ),

                    const SizedBox(height: 25),

                    // التعديل المطلوب: العودة للدخول باستخدام التكست لينك
                    CustomTextLink(
                      text: "العودة لتسجيل الدخول",
                      fontSize: 14,
                      onTap: () => Navigator.pop(context),
                    ),

                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}