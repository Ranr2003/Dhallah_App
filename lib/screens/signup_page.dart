// signup_page.dart

// ---------------------------------------------------------
// (أولا) استيراد والباكجيز
// ---------------------------------------------------------
import 'package:flutter/material.dart';
// ---------------------------------------------------------
// (ثانيا) استيراد الصفحات الأخرى لإستخدامها
// ---------------------------------------------------------
import '../services/authentication_serv.dart';
import '../screens/login_page.dart';
import '../widgets/Wavy_Background.dart';
import '../widgets/custom_widgets.dart';
import '../utils/app_theme.dart';

// ---------------------------------------------------------
//  (ثالثا) تعريف الويدجت الرئيسية والمتغيرات المطلوبة لبناء الصفحة والقيم المبدأية
// ---------------------------------------------------------
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

// ---------------------------------------------------------
//   (رابعا) بعض الدوال المهمه مثل تنظيف و التسجيل
// ---------------------------------------------------------
  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignUp() async {
    if (_emailController.text.isEmpty ||_passwordController.text.isEmpty || _usernameController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("الرجاء تعبئة جميع الحقول")),
      );
      return;
    }
    setState(() {_isLoading = true;});
    try {
      final user = await _authService.register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        confirmPassword: _confirmPasswordController.text.trim(),
      );
      // اذا نجح التسجيل نوجهه لصفحه الدخول ونقول له برساله النجاح يفعل الايميل
      if (user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "تم إنشاء الحساب! تفقد بريدك الإلكتروني لتفعيل الحساب."),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception:", "")),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

// ---------------------------------------------------------
//  (خامسا) البناء للصفحه
// ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return WavyBackground(
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery
                .of(context).size.width > 600 ? 400 : MediaQuery
                .of(context).size.width * 0.85,
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingH, vertical: 30),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppDimens.radiusSheet),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowColor.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('resourses/DallahAppLogo2.png', height: 70, fit: BoxFit.contain),
                const SizedBox(height: AppDimens.spaceSm),
                const Text("تسجيل الحساب",
                  style: TextStyle(
                      fontSize: AppDimens.fontAppBar,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontFamily: 'Tajawal'
                  ),
                ),
                const Text("سجل معلوماتك ونكمل مشوارنا",
                  style: TextStyle(
                      fontSize: AppDimens.fontMd,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Tajawal'
                  ),
                ),
                const SizedBox(height: AppDimens.spaceLg),
                CustomInputField(
                  label: "الاسم الكامل",
                  hintText: "أدخل اسمك الثلاثي",
                  controller: _usernameController,
                  fillColor: AppColors.fieldBg,
                ),
                const SizedBox(height: AppDimens.spaceMd),
                CustomInputField(
                  label: "البريد الإلكتروني",
                  hintText: "example@mail.com",
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  fillColor: AppColors.fieldBg,
                ),
                const SizedBox(height: AppDimens.spaceMd),
                CustomInputField(
                  label: "كلمة السر",
                  hintText: "أدخل كلمة السر",
                  controller: _passwordController,
                  isPass: true,
                  fillColor: AppColors.fieldBg,
                ),
                const SizedBox(height: AppDimens.spaceMd),
                CustomInputField(
                  label: "تأكيد كلمة السر",
                  hintText: "أعد كتابة كلمة السر",
                  controller: _confirmPasswordController,
                  isPass: true,
                  fillColor: AppColors.fieldBg,
                ),
                const SizedBox(height: AppDimens.spaceLg),

                WaterRippleButton(
                  text: "قم بالتسجيل",
                  onTap: _handleSignUp,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomTextLink(
                      text: "  قم بتسجيل الدخول  ",
                      onTap: () => Navigator.pop(context),
                    ),
                    const Text("لديك حساب بالفعل؟ ",
                        style: TextStyle(color: AppColors.textSecondary,
                            fontSize: AppDimens.fontMd)
                    ),
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