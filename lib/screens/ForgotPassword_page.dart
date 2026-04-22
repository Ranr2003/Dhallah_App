//ForgotPassword_page.dart
//Rand - Updated with Custom Widgets

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

// ---------------------------------------------------------
// (ثانيا) استيراد الملفات الضرورية
// ---------------------------------------------------------
import '../screens/account_info_page.dart';
import '../services/authentication_serv.dart';
import '../services/database_serv.dart';
import '../widgets/Wavy_Background.dart';
import '../widgets/custom_widgets.dart';
import '../utils/app_theme.dart'; // تأكدي من استيراد ملف الثيم

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _usePhone = true;
  final AuthenticationService _authService = AuthenticationService();
  final DatabaseService _dbService = DatabaseService();
  String _verificationId = "";

  String _fullPhoneNumber = ""; // نستخدم الرقم الكامل الآن
  String? _phoneError;
  bool _isOtpSent = false;
  bool _isOtpError = false;
  List<String> _otpCode = ["", "", "", "", "", ""];
  Timer? _timer;
  int _start = 180;
  bool _isTimerActive = false;

// ---------------------------------------------------------
//  (رابعا) بعض الدوال المهمه مثل تنظيف و الؤقت و ارسال رابط الاستعاده والكود والانتقال  ورسائل  الخطأ
// ---------------------------------------------------------
  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError("يرجى إدخال البريد الإلكتروني");
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      setState(() => _isLoading = false);
      _showSuccessDialog(
          "تم إرسال رابط استعادة كلمة المرور لبريدك. يرجى تفقد البريد الوارد (والرسائل غير المرغوب فيها).");
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      if (e.code == 'user-not-found') {
        _showError("هذا البريد غير مسجل لدينا.");
      } else if (e.code == 'invalid-email') {
        _showError("صيغة البريد الإلكتروني غير صحيحة.");
      } else {
        _showError("حدث خطأ أثناء الإرسال: ${e.message}");
      }
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
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void startTimer() {
    setState(() {
      _isTimerActive = true;
      _start = 180;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_start == 0) {
          _isTimerActive = false;
          timer.cancel();
        }
        else {
          _start--;
        }
      });
    });
  }

  // تحديث دالة إرسال الكود لتستخدم الرقم الكامل
  void _handlePhoneReset() async {
    if (_fullPhoneNumber.isEmpty || !_fullPhoneNumber.startsWith('+9665')) {
      setState(() => _phoneError = "الرجاء التأكد من صحة رقم الجوال");
      return;
    }
    setState(() => _isLoading = true);
    bool isRegistered = await _dbService.isFieldTaken(
        'phone', _fullPhoneNumber, "no-uid");

    if (!isRegistered) {
      setState(() {
        _isLoading = false;
        _phoneError = "هذا الرقم غير مسجل لدينا، يرجى إنشاء حساب أولاً.";
      });
      return;
    }
    await _authService.verifyPhoneNumber(
      phoneNumber: _fullPhoneNumber,
      onCodeSent: (id) {
        setState(() {
          _verificationId = id;
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

  void _verifyOtpAndNavigate() async {
    // ندخل برقم الجوال فلازم نتحقق اول عشان يتيح لنا الانتقال لصفحه الملف لتعديل كلمه السر
    String fullCode = _otpCode.join("");
    if (fullCode.length != 6) {
      setState(() => _isOtpError = true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithOTP(_verificationId, fullCode);
      if (user != null && mounted) {
        final prefs = await SharedPreferences
            .getInstance(); // حفظنا طريقه الدخول
        await prefs.setString('loginMethod', 'phone');
        // الانتقال للملف الشخصي
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ProfilePage(
                  userEmail: user.email ?? "",
                  initialPhoneNumber: "+966$_fullPhoneNumber",
                  loginProvider: "phone",
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
    showDialog(context: context, builder: (context) =>
        AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15)),
          content: Text(msg, textAlign: TextAlign.right),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context),
                child: const Text("حسناً"))
          ],
        ));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _timer?.cancel();
    super.dispose();
  }

// ---------------------------------------------------------
//  (خامسا) البناء للصفحه و استقبال الكود
// ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    bool isOtpComplete = _otpCode.every((digit) => digit.isNotEmpty);

    return WavyBackground(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingH),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    const Icon(Icons.lock_reset, size: AppDimens.iconSizeXl,
                        color: AppColors.primary),
                    const Text(
                        "استعادة كلمة المرور",
                        style: TextStyle(fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontFamily: 'Tajawal')
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "اختر الطريقة المناسبة لاستعادة حسابك",
                      style: TextStyle(
                          fontSize: AppDimens.fontMd,
                          color: AppColors.textSecondary,
                          fontFamily: 'Tajawal'
                      ),
                    ),
                    const SizedBox(height: 30),

                    if (!_isOtpSent)
                      Row(children: [
                        _buildTabButton("البريد الإلكتروني", !_usePhone, () =>
                            setState(() => _usePhone = false)),
                        const SizedBox(width: 10),
                        _buildTabButton("رقم الجوال", _usePhone, () =>
                            setState(() => _usePhone = true)),
                      ]),
                    const SizedBox(height: 30),

                    if (!_usePhone) ...[
                      CustomInputField(
                        label: "البريد الإلكتروني",
                        hintText: "أدخل بريدك المسجل",
                        controller: _emailController,
                        fillColor: AppColors.fieldBg, // توحيد اللون
                      )
                    ] else
                      if (!_isOtpSent) ...[
                        // استخدام الويدجت الموحدة لرقم الجوال
                        CustomPhoneField(
                          errorText: _phoneError,
                          onChanged: (fullNumber) {
                            setState(() {
                              _fullPhoneNumber = fullNumber;
                              _phoneError = null;
                            });
                          },
                        ),
                      ] else
                        ...[
                          const Text("أدخل رمز التحقق", style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Tajawal',
                              color: AppColors.textPrimary // توحيد اللون
                          )
                          ),
                          const SizedBox(height: 20),
                          // استخدام الويدجت الموحدة للـ OTP
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(6, (index) =>
                                  CustomOTPField(
                                    index: index,
                                    otpCode: _otpCode,
                                    isError: _isOtpError,
                                    onChanged: () =>
                                        setState(() => _isOtpError = false),
                                  ))
                          ),
                          if (_isOtpError)
                            const Padding(
                                padding: EdgeInsets.only(top: 10),
                                child: Text("الرمز خاطئ",
                                    style: TextStyle(color: AppColors.error))
                            ),
                          const SizedBox(height: 20),
                          _isTimerActive
                              ? Text("إعادة الإرسال خلال $_start ثانية",
                              style: const TextStyle(
                                  color: AppColors.primaryDark))
                              : CustomTextLink(
                              text: "إعادة إرسال الرمز؟", onTap: startTimer),
                        ],

                    const SizedBox(height: 30),

                    WaterRippleButton(
                      text: _isOtpSent ? "تحقق وتغيير كلمة السر" : (_usePhone
                          ? "إرسال كود التحقق"
                          : "إرسال الرابط"),
                      onTap: (_isOtpSent && !isOtpComplete)
                          ? () {}
                          : (_isOtpSent ? _verifyOtpAndNavigate : (_usePhone
                          ? _handlePhoneReset
                          : _sendResetLink)),
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 25),
                    CustomTextLink(text: "العودة لتسجيل الدخول",
                        onTap: () => Navigator.pop(context)),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
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
            color: isSelected ? AppColors.primary : AppColors.secondary
                .withOpacity(0.5),
            borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          ),
          child: Text(title, textAlign: TextAlign.center, style: TextStyle(
              color: isSelected ? AppColors.white : AppColors.primary,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal'
           )
          ),
        ),
      ),
    );
  }
}