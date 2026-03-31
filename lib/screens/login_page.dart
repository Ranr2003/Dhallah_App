//login_page.dart
//Rand
import 'dart:async'; // ضروري جداً للتايمر
import 'package:dhallah_app/screens/account_info_page.dart';
import 'package:dhallah_app/services/authentication_serv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../widgets/login_signup_background.dart';
import '../widgets/custom_button1.dart';
import'../Widgets/custom_text_field.dart';
import'../widgets/custom_text_link.dart';
import 'package:flutter/gestures.dart';
import '../screens/signup_page.dart';
import '../screens/ForgotPassword_page.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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

  // --- متغيرات الجوال والتايمر والـ OTP ---
  bool isCodeSent = false;
  String _phoneNumber = "";
  String _fullPhoneNumber = ""; // لتخزين الرقم بالصيغة الدولية
  String? _phoneError;
  String _verificationId = ""; // مهم جداً لفايربيس
  List<String> _otpCode = ["", "", "", "", "", ""];
  bool _isOtpError = false;

  Timer? _timer;
  int _start = 180;
  bool _isTimerActive = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _timer?.cancel();
    super.dispose();
  }

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
                    const Text("تسجيل الدخول بالجوال", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF444444))),
                    const SizedBox(height: 10),
                    const Text("أدخل رقم جوالك لتصلك رسالة التأكيد", style: TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 30),
                    IntlPhoneField(
                      disableLengthCheck: true,
                      decoration: InputDecoration(
                        labelText: 'رقم الجوال',
                        hintText: '5xxxxxxx',
                        fillColor: const Color(0xFFFBF9FF),
                        filled: true,
                        errorText: _phoneError,
                        errorStyle: const TextStyle(fontSize: 10, height: 0.8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.redAccent)),
                      ),
                      initialCountryCode: 'SA',
                      onChanged: (phone) {
                        _phoneNumber = phone.number;
                        _fullPhoneNumber = phone.completeNumber; // يأخذ +966 تلقائياً
                        if(_phoneError != null) setSheetState(() => _phoneError = null);
                      },
                    ),
                  ] else ...[
                    const Text("رمز التحقق", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF444444))),
                    const SizedBox(height: 10),
                    Text("أدخل الرمز المرسل إلى $_fullPhoneNumber", style: const TextStyle(fontSize: 13, color: Colors.grey), textAlign: TextAlign.center),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) => _buildOTPBox(context, index, setSheetState)),
                    ),
                    if (_isOtpError) ...[
                      const SizedBox(height: 12),
                      const Text("رمز التحقق غير صحيح، حاول مرة أخرى", style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                    ],
                    const SizedBox(height: 20),
                    _isTimerActive
                        ? Text("إعادة الإرسال خلال ${(_start ~/ 60)}:${(_start % 60).toString().padLeft(2, '0')}",
                        style: const TextStyle(fontSize: 13, color: Colors.orangeAccent, fontWeight: FontWeight.bold))
                        : CustomTextLink(
                      text: "إعادة إرسال الرمز؟",
                      onTap: () {
                        // إعادة إرسال الرمز عبر فايربيس
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

                  Opacity(
                    opacity: (isCodeSent && !isOtpComplete) ? 0.5 : 1.0,
                    child: WaterRippleButton(
                      text: isCodeSent ? "تحقق ودخول" : "إرسال رمز التحقق",
                      onTap: (isCodeSent && !isOtpComplete) ? () {} : () async {
                        if (!isCodeSent) {
                          if (_phoneNumber.trim().isEmpty) {
                            setSheetState(() => _phoneError = "الرجاء إدخال رقم الجوال");
                          } else if (_phoneNumber.length != 9) {
                            setSheetState(() => _phoneError = "الرجاء التأكد من صحة رقم الجوال");
                          } else {
                            // الربط الحقيقي: إرسال الكود
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
                                onError: (error) {
                                  setSheetState(() => _phoneError = error);
                                }
                            );
                          }
                        } else {
                          // الربط الحقيقي: التحقق من الكود
                          String enteredCode = _otpCode.join("");
                          try {
                            final user = await _authService.signInWithOTP(_verificationId, enteredCode);
                            if (user != null) {
                              Navigator.pop(context);
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfilePage(
                                    userEmail: _fullPhoneNumber,
                                    loginProvider: "phone",
                                  ),
                                ),
                                    (route) => false,
                              );
                            }
                          } catch (e) {
                            setSheetState(() => _isOtpError = true);
                          }
                        }
                      },
                      width: double.infinity,
                      height: 55,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOTPBox(BuildContext context, int index, StateSetter setSheetState) {
    return SizedBox(
      width: 45,
      child: TextField(
        autofocus: index == 0,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF673AB7)),
        decoration: InputDecoration(
          counterText: "",
          fillColor: const Color(0xFFFBF9FF),
          filled: true,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _isOtpError ? Colors.redAccent : const Color(0xFFEEEEEE), width: _isOtpError ? 2 : 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _isOtpError ? Colors.redAccent : const Color(0xFF673AB7), width: 2),
          ),
        ),
        onChanged: (value) {
          setSheetState(() {
            _otpCode[index] = value;
            _isOtpError = false;
          });
          if (value.length == 1 && index < 5) {
            FocusScope.of(context).nextFocus();
          } else if (value.isEmpty && index > 0) {
            FocusScope.of(context).previousFocus();
          }
        },
      ),
    );
  }

  // --- دالة تسجيل الدخول بالإيميل (بقيت كما هي) ---
  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("الرجاء تعبئة جميع الحقول")));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = await _authService.login(_emailController.text.trim(), _passwordController.text.trim());
      if (user != null && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(
              userEmail: _emailController.text.trim(),
              loginProvider: "email",
            ),
          ),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception:", "")), backgroundColor: Colors.redAccent));
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
            width: MediaQuery.of(context).size.width > 600 ? 400 : MediaQuery.of(context).size.width * 0.85,
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
                Image.asset('resourses/DallahAppLogo2.png', height: 80, fit: BoxFit.contain),
                const SizedBox(height: 15),
                const Text("تسجيل الدخول", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF444444))),
                const Text("! هلابك من جديد ", style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 30),

                CustomInputField(label: "البريد الإلكتروني", hintText: "أدخل بريدك الإلكتروني", controller: _emailController, fillColor: const Color(0xFFFBF9FF), keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 18),
                CustomInputField(label: "كلمة السر", hintText: "أدخل كلمة السر", controller: _passwordController, isPass: true, fillColor: const Color(0xFFFBF9FF)),

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
                    _buildSocialIcon(FontAwesomeIcons.apple, Colors.black, "أبل", () {}),
                    _buildSocialIcon(FontAwesomeIcons.microsoft, const Color(0xFF00A4EF), "مايكروسوفت", () {}),
                    _buildSocialIcon(FontAwesomeIcons.google, const Color(0xFFDB4437), "قوقل", () async {
                      setState(() => _isLoading = true);

                      User? user = await _authService.signInWithGoogle();

                      setState(() => _isLoading = false);

                      if (user != null && mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfilePage(
                              userEmail: user.email ?? "",
                              loginProvider: "google",
                            ),
                          ),
                              (route) => false,
                        );
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("فشل تسجيل الدخول عبر قوقل")),
                        );
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF0F0F0)),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 5,
                    spreadRadius: 1
                )
              ],
            ),
            // هنا يتم فحص نوع الأيقونة وعرضها بشكل صحيح
            child: icon is IconData
                ? Icon(icon, color: color, size: 22)
                : FaIcon(icon, color: color, size: 22),
          ),
        ),
        const SizedBox(height: 6),
        Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)
        ),
      ],
    );
  }
}