// account_info_page.dart
// Updated by Gemini for Rand - Dhallah Project

import 'package:flutter/material.dart';

// ---------------------------------------------------------
// (ثانيا) استيراد الملفات الضرورية
// ---------------------------------------------------------
import '../models/user_model.dart';
import '../widgets/Wavy_Background.dart';
import '../widgets/custom_widgets.dart'; // الويدجتس الموحدة
import '../services/authentication_serv.dart';
import '../services/database_serv.dart';
import '../utils/app_theme.dart'; // الثيم الموحد
import 'login_page.dart';
import 'home_page.dart';

class ProfilePage extends StatefulWidget {
  final String userEmail;
  final String? initialPhoneNumber;
  final String? initialName;
  final String loginProvider;
  final bool canEditPassword;

  const ProfilePage({
    super.key,
    required this.userEmail,
    this.initialPhoneNumber,
    this.initialName,
    required this.loginProvider,
    this.canEditPassword = false,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  final _nameController = TextEditingController();
  final _passController = TextEditingController();
  final AuthenticationService _authService = AuthenticationService();
  final DatabaseService _dbService = DatabaseService();

  String _fullPhoneNumber = "";
  bool _isLoading = true;
  bool _isSaving = false;
  String _verificationId = "";
  List<String> _otpCode = ["", "", "", "", "", ""];

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
        text: widget.loginProvider == 'email' || widget.loginProvider == 'google'
            ? widget.userEmail
            : ""
    );
    _nameController.text = widget.initialName ?? "";
    _phoneController = TextEditingController(
        text: widget.initialPhoneNumber?.replaceFirst('+966', '') ?? ""
    );
    _fullPhoneNumber = widget.initialPhoneNumber ?? "";

    _dbService.loadUserData(
      nameController: _nameController,
      phoneController: _phoneController,
      emailController: _emailController,
      mounted: mounted,
      setLoading: (val) => setState(() => _isLoading = val),
      setFullPhone: (val) => _fullPhoneNumber = val,
      updateState: setState,
    );
  }

  Future<void> _finalSave() async {
    setState(() => _isSaving = true);
    try {
      // التعديل 1: بدلاً من استدعاء Firebase مباشرة، نستخدم الدالة الجاهزة عندك في السيرفس
      final String currentUid = _authService.currentUserId;
      if (currentUid == 'unknown') return;

      if (widget.canEditPassword && _passController.text.trim().isNotEmpty) {
        if (_passController.text.trim().length < 6) {
          _showError("كلمة المرور يجب أن تكون 6 خانات على الأقل");
          return;
        }
        // التعديل 2: نستخدم الدالة التي أضفناها للسيرفس لتغيير الباسوورد
        await _authService.updatePassword(_passController.text.trim());
      }

      // المنطق كما هو دون تغيير
      final updatedUser = RegularUser(
        userId: currentUid,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _fullPhoneNumber.trim(),
        isProfileComplete: true,
        provider: widget.loginProvider,
      );

      await _dbService.saveProfile(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("تم تحديث البيانات بنجاح"),
              backgroundColor: AppColors.success
          ),
        );
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
                  (route) => false,
            );
          }
        });
      }
    } catch (e) {
      // هنا اختصرنا التعامل مع الخطأ لأن السيرفس سترسل رسالة الخطأ جاهزة
      _showError(e.toString().contains('requires-recent-login')
          ? "لأمانك، يرجى تسجيل الخروج والدخول مجدداً لتغيير كلمة السر"
          : "حدث خطأ: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _onSavePressed() async {
    final String currentUid = _authService.currentUserId;

    if (currentUid == 'unknown' || currentUid.isEmpty) {
      _showGuestWarning(context); // إظهار الرسالة الجميلة
      return; // التوقف هنا وعدم إكمال عملية الحفظ
    }
    final String enteredEmail = _emailController.text.trim();
    final String enteredName = _nameController.text.trim();

    if (enteredName.isEmpty || _fullPhoneNumber.trim().isEmpty) {
      _showError("الرجاء إدخال الاسم ورقم الجوال أولاً");
      return;
    }
    setState(() => _isSaving = true);

    try {
      final String currentUid = _authService.currentUserId;
      if (currentUid == 'unknown') return;

      if (widget.loginProvider == 'phone' && enteredEmail.isNotEmpty) {
        bool isTaken = await _dbService.isFieldTaken('email', enteredEmail, currentUid);
        if (isTaken) {
          _showError("عذراً، هذا البريد الإلكتروني مسجل بالفعل!");
          return;
        }
      }

      bool isPhoneChanged = _fullPhoneNumber.trim() != (_authService.currentPhone ?? "");

      if (widget.loginProvider != 'phone' && isPhoneChanged) {
        bool isTaken = await _dbService.isFieldTaken('phone', _fullPhoneNumber.trim(), currentUid);
        if (isTaken) {
          _showError("عذراً، رقم الجوال هذا مرتبط بحساب آخر!");
          return;
        }
        _startPhoneVerification();
      } else {
        await _finalSave();
      }
    } catch (e) {
      _showError("حدث خطأ أثناء الفحص: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _startPhoneVerification() async {
    setState(() => _isSaving = true);
    await _authService.verifyPhoneNumber(
      phoneNumber: _fullPhoneNumber,
      onCodeSent: (id) {
        setState(() {
          _isSaving = false;
          _verificationId = id;
        });
        _showOtpDialog();
      },
      onError: (err) {
        setState(() => _isSaving = false);
        _showError(err);
      },
    );
  }

  void _showOtpDialog() {
    _otpCode = ["", "", "", "", "", ""];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusSheet)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 25),
                const Text("تحقق من الرقم لربط الحساب",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 10),
                Text("أدخل الرمز المرسل إلى $_fullPhoneNumber",
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), textAlign: TextAlign.center),
                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) => CustomOTPField(
                    index: index,
                    otpCode: _otpCode,
                    isError: false,
                    onChanged: () => setSheetState(() {}),
                  )),
                ),

                const SizedBox(height: 35),

                WaterRippleButton(
                  text: "تأكيد وربط الحساب",
                  onTap: () async {
                    String smsCode = _otpCode.join();
                    try {
                      await _authService.linkPhoneNumber(_verificationId, smsCode);
                      if (mounted) Navigator.pop(context);
                      await _finalSave();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("كود التحقق غير صحيح")));
                    }
                  },
                  width: double.infinity,
                  height: 55,
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String provider = widget.loginProvider.toLowerCase().trim();

    // "حزام أمان" إضافي: لو القيمة فاضية، نبحث عنها في الـ SharedPreferences داخل الـ build (اختياري)
    // لكن الاعتماد على ما يرسله الناف بار بعد تعديله كافي.

    bool isEmailLocked = provider == 'email' || provider == 'google' || provider == 'password';
    bool isPhoneLocked = provider == 'phone';

    print("Final Check - Provider: $provider | EmailLocked: $isEmailLocked | PhoneLocked: $isPhoneLocked");
    return Scaffold(
      extendBodyBehindAppBar: true,
      // نصيحة: بما أننا أضفنا ناف بار، يفضل حذف زر الرجوع من الـ AppBar
      // لأن التنقل سيكون عبر الناف بار، أو إبقاؤه حسب رغبتك.
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // حذف سهم الرجوع الافتراضي لتجنب الازدحام
      ),
      body: WavyBackground(
        child: Stack( // أضفنا Stack هنا
          children: [
            Center(
              child: _isLoading
                  ? const CircularProgressIndicator(color: AppColors.primary)
                  : SingleChildScrollView(
                // أضفنا padding سفلية (100) عشان المحتوى ما يختفي تحت الناف بار
                padding: const EdgeInsets.fromLTRB(AppDimens.paddingH, 80, AppDimens.paddingH, 120),
                child: Column(
                  children: [
                    const Text("الملف الشخصي",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontFamily: 'Tajawal')),
                    const SizedBox(height: 40),

                    CustomInputField(
                      label: "الاسم الكامل",
                      hintText: "أدخل اسمك هنا",
                      controller: _nameController,
                      fillColor: AppColors.white.withOpacity(0.7),
                    ),
                    const SizedBox(height: 15),

                    CustomInputField(
                      label: "البريد الإلكتروني",
                      hintText: "example@mail.com",
                      controller: _emailController,
                      readOnly: isEmailLocked,
                      fillColor: isEmailLocked ? AppColors.secondary.withOpacity(0.3) : AppColors.white.withOpacity(0.7),
                    ),
                    const SizedBox(height: 15),

                    const Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.only(right: 8, bottom: 8),
                        child: Text("رقم الجوال",
                            style: TextStyle(fontWeight: FontWeight.bold,
                              fontFamily: 'Tajawal',
                              fontSize: AppDimens.fontLg,
                              color: AppColors.textPrimary,)),
                      ),
                    ),
                    CustomPhoneField(
                      controller: _phoneController,
                      readOnly: isPhoneLocked,
                      onChanged: (fullNumber) => _fullPhoneNumber = fullNumber,
                    ),
                    const SizedBox(height: 15),

                    CustomInputField(
                      label: "كلمة السر الجديدة",
                      hintText: widget.canEditPassword
                          ? "أدخل كلمة السر الجديدة"
                          : "التعديل متاح عبر الاستعادة فقط",
                      controller: _passController,
                      isPass: true,
                      readOnly: !widget.canEditPassword,
                      fillColor: widget.canEditPassword ? AppColors.white.withOpacity(0.7) : AppColors.secondary.withOpacity(0.3),
                    ),

                    const SizedBox(height: 35),

                    WaterRippleButton(
                        text: _isSaving ? "جاري الحفظ..." : "حفظ التعديلات",
                        width: 200,
                        height: 50,
                        onTap: _isSaving ? () {} : _onSavePressed
                    ),

                    const SizedBox(height: 30),
                    _buildProviderStatus(),

                    TextButton.icon(
                      onPressed: () async {
                        await _authService.logout();
                        if (mounted) {
                          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false);
                        }
                      },
                      icon: const Icon(Icons.logout, color: AppColors.error),
                      label: const Text("تسجيل الخروج", style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                    ),
                  ],
                ),
              ),
            ),

            // إستدعاء الناف بار الموحد
            // استدعاء الودجت الموحد الجديد في الهوم
            CustomFloatingNavBar(
              currentIndex: 2, // رقم 1 يمثل الهوم
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderStatus() {
    IconData icon;
    String providerName;

    if (widget.loginProvider == 'phone') {
      icon = Icons.phone_android;
      providerName = "رقم الجوال";
    } else if (widget.loginProvider == 'google') {
      icon = Icons.g_mobiledata;
      providerName = "حساب Google";
    } else {
      icon = Icons.email_outlined;
      providerName = "البريد الإلكتروني";
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: AppColors.primaryDark, size: 20),
        const SizedBox(width: 8),
        Text("طريقة الدخول: $providerName", style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      ],
    );
  }
  void _showGuestWarning(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary, // اللون البنفسجي الأساسي
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: const Row(
            children: [
              Icon(Icons.lock_person_outlined, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "عذراً، يجب تسجيل الدخول أولاً لتتمكن من حفظ بياناتك الشخصية",
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}