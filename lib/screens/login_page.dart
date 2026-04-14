// login_page.dart
// Rand
// ---------------------------------------------------------
// (أولا) استيراد المكتبوات والباكجيز
// ---------------------------------------------------------
import 'dart:async';
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
import '../widgets/login_signup_background.dart';
import '../widgets/custom_button1.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_text_link.dart';
import '../screens/signup_page.dart';
import '../screens/ForgotPassword_page.dart';
import '../screens/account_info_page.dart';
import '../screens/home_page.dart';
import '../models/user_model.dart';
import 'admin_dashboard.dart';

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
  void _showBannedDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: const Row(
            children: [
              Icon(Icons.block_flipped, color: Colors.redAccent),
              SizedBox(width: 10),
              Text("تنبيه الحظر", style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            "نأسف، لقد تم حظر حسابك لمخالفة شروط الاستخدام. يرجى التواصل مع الإدارة للمزيد من التفاصيل.",
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          actions: [
            WaterRippleButton(
                text: "إغلاق",
                onTap: () => Navigator.pop(context),
                width: 100,
                height: 40
            ),
          ],
        ),
      ),
    );
  }
  // تحفظ طريقه الدخول
  Future<void> _saveLoginMethod(String method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loginMethod', method);
  }

// ---------------------------------------------------------
// تعديل دالة توجيه المستخدم لتشمل فحص الأدمن
// ---------------------------------------------------------
  void _redirectUser(fb.User user, String provider, String emailOrPhone) async {
    // 1. جلب بيانات المستخدم كاملة من الداتابيز
    var userData = await _dbService.getUserById(user.uid);

    if (mounted && userData != null) {

      // 🔥 فحص الحظر (باستخدام logout الموجودة في سيرفس رند)
      // نتحقق من الحقل isBanned الموجود في مودل RegularUser
      if (userData is RegularUser && userData.isBanned) {
        await _authService.logout(); // ✅ هنا التعديل من signOut إلى logout
        _showBannedDialog(context);   // إظهار نافذة الحظر
        return;
      }

      // 2. التحقق من الأدمن
      if (userData.userType == 'admin') {
        Admin adminUser = Admin(
          userId: userData.userId,
          name: userData.name,
          email: userData.email,
          adminLevel: (userData as dynamic).adminLevel ?? "General",
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => AdminDashboard(admin: adminUser)),
              (route) => false,
        );
        return;
      }

      // 3. التحقق من اكتمال البروفايل للمستخدم العادي
      bool isComplete = await _dbService.checkProfileCompletion(user.uid);
      if (isComplete) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
              (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(
              userEmail: emailOrPhone,
              loginProvider: provider,
              canEditPassword: false,
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
                      ),
                      initialCountryCode: 'SA',
                      onChanged: (phone) {
                        _phoneNumber = phone.number;
                        _fullPhoneNumber = phone.completeNumber;
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
                          String errorText = e.toString();
                          if (errorText.contains("محظور")) {
                            // إذا كان الحساب محظوراً، نغلق الشيت ونظهر الرسالة في الصفحة الرئيسية
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(errorText.replaceAll("Exception:", "").trim()),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          } else {
                            // إذا كان الخطأ مجرد رمز خطأ، نبقي الشيت مفتوحاً ونظهر خطأ الـ OTP
                            setSheetState(() => _isOtpError = true);
                          }
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
          // لو خطأ يحط الحدود بالاحمر
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _isOtpError ? Colors.redAccent : const Color(0xFFEEEEEE))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF673AB7), width: 2)),
        ),
        onChanged: (value) {
          setSheetState(() { _otpCode[index] = value; _isOtpError = false; });
          if (value.length == 1 && index < 5) FocusScope.of(context).nextFocus();
          if (value.isEmpty && index > 0) FocusScope.of(context).previousFocus();
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception:", "")), backgroundColor: Colors.redAccent));
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
            const Icon(Icons.auto_awesome_rounded, color: Color(0xFFB293CD), size: 60),
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
    return LoginSignupBackground(
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width > 600 ? 400 : MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 35),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(35),
              boxShadow: [BoxShadow(color: const Color(0xFFD2B4EC).withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('resourses/DallahAppLogo2.png', height: 80),
                const SizedBox(height: 15),
                const Text("تسجيل الدخول", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF444444))),
                const Text("! هلابك من جديد ", style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 30),

                CustomInputField(label: "البريد الإلكتروني", hintText: "أدخل بريدك الإلكتروني", controller: _emailController, fillColor: const Color(0xFFFBF9FF)),
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
                    _buildSocialIcon(FontAwesomeIcons.apple, Colors.black, "أبل", () => _showComingSoonDialog(context, "أبل")),
                    _buildSocialIcon(FontAwesomeIcons.microsoft, const Color(0xFF00A4EF), "مايكروسوفت", () => _showComingSoonDialog(context, "مايكروسوفت")),
                    _buildSocialIcon(FontAwesomeIcons.google, const Color(0xFFDB4437), "قوقل", () async {
                      try {
                        setState(() => _isLoading = true);
                        fb.User? user = await _authService.signInWithGoogle();
                        setState(() => _isLoading = false);
                        if (user != null) {
                          await _saveLoginMethod("google");
                          _redirectUser(user, "google", user.email ?? "");
                        }
                      } catch (e) {
                        setState(() => _isLoading = false);
                        if (mounted) {
                          // هنا نتأكد أن رسالة الحظر هي التي تظهر أولاً
                          String errorMessage = e.toString().replaceAll("Exception:", "").trim();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(errorMessage), backgroundColor: Colors.redAccent),
                          );
                        }
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