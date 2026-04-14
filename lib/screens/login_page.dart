// login_page.dart
// Rand
// ---------------------------------------------------------
// (أولا) استيراد المكتبوات والباكجيز
// ---------------------------------------------------------
import 'dart:async';
import 'package:dhallah_app/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ---------------------------------------------------------
// (ثانيا) استيراد الصفحات الأخرى لإستخدامها
// ---------------------------------------------------------
import '../services/authentication_serv.dart';
import '../services/database_serv.dart';
import '../widgets/Wavy_Background.dart';
//import '../widgets/custom_button1.dart';
import '../widgets/custom_widgets.dart';
//import '../widgets/custom_text_field.dart';
//import '../widgets/custom_text_link.dart';
import '../screens/signup_page.dart';
import '../screens/ForgotPassword_page.dart';
import '../screens/account_info_page.dart';
import '../screens/home_page.dart';

// ---------------------------------------------------------
//  (ثالثا) تعريف الويدجت الرئيسية والمتغيرات المطلوبة لبناء الصفحة والقيم المبدأية
// ---------------------------------------------------------
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthenticationService _authService = AuthenticationService();
  final DatabaseService _dbService = DatabaseService();

  bool _isLoading = false;
  bool isCodeSent = false;
  String _phoneNumber = "";
  String _fullPhoneNumber = "";
  String? _phoneError;
  String _verificationId = "";
  List<String> _otpCode = ["", "", "", "", "", ""];
  bool _isOtpError = false;
  Timer? _timer;
  int _start = 180;
  bool _isTimerActive = false;

// ---------------------------------------------------------
//  (رابعا) بعض الدوال المهمه مثل تنظيف و الؤقت و ارسال رابط الاستعاده والكود والانتقال  ورسائل  الخطأ
// ---------------------------------------------------------
  // تنظف
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // تحفظ طريقه الدخول
  Future<void> _saveLoginMethod(String method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loginMethod', method);
  }

  // توجيه المستخدم بحسب حاله اكتمال الملف الشخصي
  void _redirectUser(fb.User user, String provider, String emailOrPhone) async {
    bool isComplete = await _dbService.checkProfileCompletion(user.uid);
    if (mounted) {
      if (isComplete) {
        // إذا الحساب مكتمل يروح للهوم مباشرة
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
              (route) => false,
        );
      } else {
        // إذا جديد أو غير مكتمل يروح لصفحة إكمال البيانات
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(
              userEmail: emailOrPhone,
              loginProvider: provider,
              canEditPassword: false, // كلمه السر ممنوع يعدله
            ),
          ),
              (route) => false,
        );
      }
    }
  }
//  للتايمر
  void startTimer(StateSetter setSheetState) {
    _isTimerActive = true;
    _start = 180;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setSheetState(() {
        if (_start == 0) {
          _isTimerActive = false;
          timer.cancel();
        } else {
          _start--;
        }
      });
    });
  }
// ---------------------------------------------------------
//  (خامسا) التصميم والبناء
// ---------------------------------------------------------

// شيت لما يدخل برقم الجوال اللي تطلع من تحت
  void _showPhoneLoginSheet() {
    isCodeSent = false;
    _phoneError = null;
    _otpCode = ["", "", "", "", "", ""];
    _isOtpError = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          bool isOtpComplete = _otpCode.every((digit) => digit.isNotEmpty);

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 20),

                  if (!isCodeSent) ...[
                    const Text("تسجيل الدخول بالجوال", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkgray)),
                    const SizedBox(height: 10),
                    const Text("أدخل رقم جوالك لتصلك رسالة التأكيد", style: TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 30),
                    CustomPhoneField(
                      errorText: _phoneError,
                      onChanged: (fullNumber) {
                        // هنا نحدث القيمتين لضمان استمرار عمل الـ Logic القديم
                        _fullPhoneNumber = fullNumber;
                        _phoneNumber = fullNumber.replaceFirst('+966', '');
                        if(_phoneError != null) setSheetState(() => _phoneError = null);
                      },
                    ),
                  ] else ...[
                    const Text("رمز التحقق", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkgray)),
                    const SizedBox(height: 10),
                    Text("أدخل الرمز المرسل إلى $_fullPhoneNumber", style: const TextStyle(fontSize: 13, color: Colors.grey), textAlign: TextAlign.center),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) => CustomOTPField(
                        index: index,
                        otpCode: _otpCode,
                        isError: _isOtpError,
                        onChanged: () { // احذفي كلمة value من هنا
                          setSheetState(() {
                            _isOtpError = false;
                          });
                        },
                      ),),
                    ),
                    if (_isOtpError) ...[
                      const SizedBox(height: 12),
                      const Text("رمز التحقق غير صحيح، حاول مرة أخرى", style: TextStyle(color: AppColors.error, fontSize: 11)),
                    ],
                    const SizedBox(height: 20),
                    _isTimerActive
                        ? Text("إعادة الإرسال خلال ${(_start ~/ 60)}:${(_start % 60).toString().padLeft(2, '0')}",
                        style: const TextStyle(fontSize: 13, color: Colors.orangeAccent, fontWeight: FontWeight.bold))
                        : CustomTextLink(
                      text: "إعادة إرسال الرمز؟",
                      onTap: () {
                        _authService.verifyPhoneNumber(
                          phoneNumber: _fullPhoneNumber,
                          onCodeSent: (id) => setSheetState(() => _verificationId = id),
                          onError: (err) => setSheetState(() => _phoneError = err),
                        );
                        startTimer(setSheetState);
                      },
                    ),
                  ],

                  const SizedBox(height: 30),

                  WaterRippleButton(
                    text: isCodeSent ? "تحقق ودخول" : "إرسال رمز التحقق",
                    onTap: (isCodeSent && !isOtpComplete) ? () {} : () async {
                      if (!isCodeSent) {
                        if (_phoneNumber.trim().isEmpty) {
                          setSheetState(() => _phoneError = "الرجاء إدخال رقم الجوال");
                        } else {
                          await _authService.verifyPhoneNumber(
                              phoneNumber: _fullPhoneNumber,
                              onCodeSent: (id) {
                                setSheetState(() {
                                  _verificationId = id;
                                  isCodeSent = true;
                                  _phoneError = null;
                                  startTimer(setSheetState);
                                });
                              },
                              onError: (error) => setSheetState(() => _phoneError = error)
                          );
                        }
                      } else {
                        String enteredCode = _otpCode.join("");
                        try {
                          final user = await _authService.signInWithOTP(_verificationId, enteredCode);
                          if (user != null) {
                            await _saveLoginMethod("phone");
                            if (mounted) Navigator.pop(context);
                            _redirectUser(user, "phone", _fullPhoneNumber);
                          }
                        } catch (e) {
                          setSheetState(() => _isOtpError = true);
                        }
                      }
                    },
                    width: double.infinity,
                    height: 55,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("الرجاء تعبئة جميع الحقول")));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = await _authService.login(_emailController.text.trim(), _passwordController.text.trim());
      if (user != null) {
        await _saveLoginMethod("email");
        _redirectUser(user, "email", _emailController.text.trim());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception:", "")), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
// الرساله لما نضغط زر ابل ومايكروسوفت
  void _showComingSoonDialog(BuildContext context, String provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 60),
            const SizedBox(height: 20),
            const Text("! قريبًا", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 15),
            Text("خدمة تسجيل الدخول بواسطة $provider قيد التطوير حالياً.", textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 30),
            WaterRippleButton(text: "حسناً", onTap: () => Navigator.pop(context), width: double.infinity, height: 50),
          ],
        ),
      ),
    );
  }
// الشكل للصفحه
  @override
  Widget build(BuildContext context) {
    return WavyBackground(
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width > 600 ? 400 : MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 35),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(35),
              boxShadow: [BoxShadow(color:AppColors.purble.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('resourses/DallahAppLogo2.png', height: 80),
                const SizedBox(height: 15),
                const Text("تسجيل الدخول", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color:AppColors.darkgray)),
                const Text("! هلابك من جديد ", style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 30),

                CustomInputField(label: "البريد الإلكتروني", hintText: "أدخل بريدك الإلكتروني", controller: _emailController, fillColor: AppColors.fieldBg ),
                const SizedBox(height: 18),
                CustomInputField(label: "كلمة السر", hintText: "أدخل كلمة السر", controller: _passwordController, isPass: true, fillColor: AppColors.fieldBg ),

                const SizedBox(height: 30),
                WaterRippleButton(text: "دخول", onTap: _handleLogin, isLoading: _isLoading, width: double.infinity, height: 55),

                const SizedBox(height: 25),
                const Row(children: [
                  Expanded(child: Divider(thickness: 1, color: Color(0xFFEEEEEE))),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("أو سجل الدخول عبر", style: TextStyle(color: Colors.grey, fontSize: 12))),
                  Expanded(child: Divider(thickness: 1, color: Color(0xFFEEEEEE))),
                ]),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSocialIcon(FontAwesomeIcons.apple,Colors.black, "أبل", () => _showComingSoonDialog(context, "أبل")),
                    _buildSocialIcon(FontAwesomeIcons.microsoft, const Color(0xFF00A4EF), "مايكروسوفت", () => _showComingSoonDialog(context, "مايكروسوفت")),
                    _buildSocialIcon(FontAwesomeIcons.google, const Color(0xFFDB4437), "قوقل", () async {
                      setState(() => _isLoading = true);
                      fb.User? user = await _authService.signInWithGoogle();
                      setState(() => _isLoading = false);
                      if (user != null) {
                        await _saveLoginMethod("google");
                        _redirectUser(user, "google", user.email ?? "");
                      }
                    }),
                    _buildSocialIcon(Icons.phone_android, const Color(0xFF673AB7), "رقم الجوال", _showPhoneLoginSheet),
                  ],
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomTextLink(text: "  قم بتسجيل حساب جديد  ", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpPage()))),
                    const Text("ليس لديك حساب ؟   ", style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 12),
                CustomTextLink(text: "نسيت كلمة السر؟", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialIcon(dynamic icon, Color color, String label, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFF0F0F0)), color: Colors.white),
            child: icon is IconData ? Icon(icon, color: color, size: 22) : FaIcon(icon, color: color, size: 22),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }
}