//ForgotPassword_page.dart
//Rand
import 'package:dhallah_app/screens/account_info_page.dart';
import 'package:dhallah_app/services/authentication_serv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/login_signup_background.dart';
import '../widgets/custom_button1.dart';
import'../Widgets/custom_text_field.dart';
import'../widgets/custom_text_link.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
// استورد ملفات الـ Widgets والـ Pages الخاصة بكِ هنا
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _usePhone = true; // نخليه افتراضي على الجوال مثل صورتك
  final AuthenticationService _authService = AuthenticationService();
  String _verificationId = "";

  String _phoneNumber = "";
  String? _phoneError;
  bool _isOtpSent = false;
  bool _isOtpError = false;
  List<String> _otpCode = ["", "", "", "", "", ""];
  Timer? _timer;
  int _start = 180;
  bool _isTimerActive = false;

  // --- الدالة التي كانت مفقودة وسببت الخطأ الثاني ---
  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError("يرجى إدخال البريد الإلكتروني");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // هذه هي الدالة الحقيقية التي ترسل الإيميل من فايربيس
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      setState(() => _isLoading = false);
      _showSuccessDialog("تم إرسال رابط استعادة كلمة المرور لبريدك. يرجى تفقد البريد الوارد (والرسائل غير المرغوب فيها).");
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      String errorMessage = "حدث خطأ أثناء الإرسال";

      if (e.code == 'user-not-found') {
        errorMessage = "هذا البريد غير مسجل لدينا.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "صيغة البريد الإلكتروني غير صحيحة.";
      }

      _showError(errorMessage);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError("حدث خطأ غير متوقع: $e");
    }
  }
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, textAlign: TextAlign.right),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
  void startTimer() {
    setState(() { _isTimerActive = true; _start = 180; });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_start == 0) { _isTimerActive = false; timer.cancel(); }
        else { _start--; }
      });
    });
  }

  void _handlePhoneReset() async {
    if (_phoneNumber.length != 9 || !_phoneNumber.startsWith('5')) {
      setState(() => _phoneError = "الرجاء التأكد من صحة رقم الجوال");
      return;
    }

    setState(() => _isLoading = true);

    // نستخدم الخدمة الحقيقية لإرسال الكود
    await _authService.verifyPhoneNumber(
      phoneNumber: "+966$_phoneNumber",
      onCodeSent: (id) {
        setState(() {
          _verificationId = id; // تخزين الـ ID الحقيقي من فايربيس
          _isOtpSent = true;
          _isLoading = false;
          startTimer();
        });
      },
      onError: (err) {
        setState(() {
          _phoneError = err;
          _isLoading = false;
        });
      },
    );
  }

// داخل ForgotPasswordScreen
// داخل ForgotPasswordScreen في ملف ForgotPassword_page.dart

  void _verifyOtpAndNavigate() async {
    String fullCode = _otpCode.join("");

    if (fullCode.length != 6) {
      setState(() => _isOtpError = true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. التحقق الفعلي مع فايربيس
      final user = await _authService.signInWithOTP(_verificationId, fullCode);

      if (user != null && mounted) {

        // --- التعديل المهم هنا يا رند ---
        // 2. حفظ طريقة الدخول في الشيرد بريفرنسز فوراً عند نجاح الكود
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('loginMethod', 'phone');
        // ---------------------------------

        // 3. الانتقال لصفحة البروفايل
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(
              userEmail: user.email ?? "",
              initialPhoneNumber: "+966$_phoneNumber",
              loginProvider: "phone", // نمررها يدوياً هنا أيضاً للتأكيد
              canEditPassword: true,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isOtpError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(String msg) {
    showDialog(context: context, builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      content: Text(msg, textAlign: TextAlign.right),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("حسناً"))],
    ));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isOtpComplete = _otpCode.every((digit) => digit.isNotEmpty);

    return LoginSignupBackground(
      // 1. استخدام LayoutBuilder لمعرفة حجم الشاشة المتاح
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            // 2. جعل الصفحة قابلة للسحب دائماً لضمان مرونة التصميم
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              // 3. إجبار المحتوى على أخذ طول الشاشة كاملاً على الأقل
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Column(
                  // 4. توسيط المحتوى عمودياً
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40), // مساحة علوية بسيطة
                    const Icon(Icons.lock_reset, size: 100, color: Color(0xFFB293CD)),
                    const Text(
                        "استعادة كلمة المرور",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFB293CD))
                    ),
                    const SizedBox(height: 10),
                    const Text(
                        "اختر الطريقة المناسبة لاستعادة حسابك",
                        style: TextStyle(fontSize: 13, color: Colors.grey)
                    ),
                    const SizedBox(height: 30),

                    if (!_isOtpSent)
                      Row(children: [
                        _buildTabButton("البريد الإلكتروني", !_usePhone, () => setState(() => _usePhone = false)),
                        const SizedBox(width: 10),
                        _buildTabButton("رقم الجوال", _usePhone, () => setState(() => _usePhone = true)),
                      ]),

                    const SizedBox(height: 30),

                    if (!_usePhone) ...[
                      CustomInputField(label: "البريد الإلكتروني", hintText: "أدخل بريدك المسجل", controller: _emailController),
                    ] else if (!_isOtpSent) ...[
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: IntlPhoneField(
                          initialCountryCode: 'SA',
                          onChanged: (phone) => _phoneNumber = phone.number,
                          decoration: InputDecoration(
                            labelText: 'رقم الجوال',
                            hintText: '5xxxxxxx',
                            fillColor: Colors.white.withOpacity(0.9),
                            filled: true,
                            errorText: _phoneError,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                    ] else ...[
                      const Text("أدخل رمز التحقق", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(6, (index) => _buildOTPBox(index))
                      ),
                      if (_isOtpError)
                        const Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: Text("الرمز خاطئ", style: TextStyle(color: Colors.redAccent))
                        ),
                      const SizedBox(height: 20),
                      _isTimerActive
                          ? Text("إعادة الإرسال خلال $_start ثانية")
                          : CustomTextLink(text: "إعادة إرسال الرمز؟", onTap: startTimer),
                    ],

                    const SizedBox(height: 30),

                    WaterRippleButton(
                      text: _isOtpSent ? "تحقق وتغيير كلمة السر" : (_usePhone ? "إرسال كود التحقق" : "إرسال الرابط"),
                      onTap: (_isOtpSent && !isOtpComplete) ? () {} : (_isOtpSent ? _verifyOtpAndNavigate : (_usePhone ? _handlePhoneReset : _sendResetLink)),
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 25),
                    CustomTextLink(text: "العودة لتسجيل الدخول", onTap: () => Navigator.pop(context)),
                    const SizedBox(height: 40), // مساحة سفلية
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOTPBox(int index) {
    return SizedBox(
      width: 45,
      child: TextField(
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: "",
          fillColor: Colors.white,
          filled: true,
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _isOtpError ? Colors.redAccent : Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _isOtpError ? Colors.redAccent : const Color(0xFFB293CD), width: 2)),
        ),
        onChanged: (value) {
          setState(() { _otpCode[index] = value; _isOtpError = false; });
          if (value.isNotEmpty && index < 5) FocusScope.of(context).nextFocus();
          if (value.isEmpty && index > 0) FocusScope.of(context).previousFocus();
        },
      ),
    );
  }

  Widget _buildTabButton(String title, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFB293CD) : Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(title, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFFB293CD), fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}