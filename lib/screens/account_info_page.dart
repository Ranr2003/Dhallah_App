// account_info_page.dart
// Rand

// ---------------------------------------------------------
// (أولا) استيراد المكتبات والباكجيز
// ---------------------------------------------------------
import 'package:firebase_auth/firebase_auth.dart' as fb;      // للمصادقة
import 'package:flutter/material.dart';                 // لواجهات فلاتر
import 'package:intl_phone_field/intl_phone_field.dart';// لحقل الهاتف الدولي العلم والمفتاح
// ---------------------------------------------------------
// (ثانيا) استيراد الصفحات الأخرى لإستخدامها
// ---------------------------------------------------------
import '../models/user_model.dart';
import '../widgets/login_signup_background.dart';       // للخلفية
import '../widgets/custom_button1.dart';                //
import '../widgets/custom_text_field.dart';
import '../services/authentication_serv.dart';// تأكدي من استيراد ملف الخدمة
import '../services/database_serv.dart';
import 'login_page.dart';
import 'home_page.dart';

// ---------------------------------------------------------
//  (ثالثا) تعريف الويدجت الرئيسية والمتغيرات المطلوبة لبناء الصفحة والقيم المبدأية
// ---------------------------------------------------------
class ProfilePage extends StatefulWidget {
  final String userEmail;
  final String? initialPhoneNumber;
  final String? initialName;
  final String loginProvider;
  final bool canEditPassword; // لتحديد ما اذا كان مسموحا بتعديل كلمه المرور أم لا
// كونستركتور
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

  // تهيئه كل حقل بالبيانات الأوليه
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
        text: widget.initialPhoneNumber?.replaceFirst('+966', '') ?? "" //يقص المفتاح
    );
    _fullPhoneNumber = widget.initialPhoneNumber ?? "";
   //استدعيت خوارزميه الجلب من ملف الداتا بيس
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
// ---------------------------------------------------------
//  (رابعا) عمليات الحفظ والجلب والمنطق لها صله بملف الداتا بيس وملف المصادقه ويوزر مودل
// ---------------------------------------------------------

  // الحفظ النهائي في الفاير ستور
  Future<void> _finalSave() async {
    setState(() => _isSaving = true);
    try {
      fb.User? currentUser = fb.FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // 1. في حال كان المستخدم طالب تغيير الكلمه وسامحين له نحفظها هنا بشكل نهائي في المصادقه
      if (widget.canEditPassword && _passController.text.trim().isNotEmpty) {
        if (_passController.text.trim().length < 6) {
          _showError("كلمة المرور يجب أن تكون 6 خانات على الأقل");
          return;
        }
        await currentUser.updatePassword(_passController.text.trim());
        debugPrint("تم تحديث كلمة المرور في Auth بنجاح"); //رساله تطلع لي انا
      }

      // 2.تحديث البيانات وحفظها في الفاير ستور
      final updatedUser = RegularUser(
        userId: currentUser.uid,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _fullPhoneNumber.trim(),
        isProfileComplete: true,
        provider: widget.loginProvider,
      );

      await _dbService.saveProfile(updatedUser); // استدعاء دالة الحفظ

       // 3. رساله النجاح ثم الانتظار قليلا وبعدها التوجه تلقائيا للهوم
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("تم تحديث البيانات وكلمة المرور بنجاح "),
              backgroundColor: Colors.green
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
      // هنا في حطيت أبرز رسائل الخطأ من المصادقه بالفير بيس وخليتها بالعربي حتى تكون مفهومه اكثر
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        _showError("لأمانك، يرجى تسجيل الخروج والدخول مجدداً لتغيير كلمة السر");
      } else {
        _showError("خطأ في تغيير كلمة السر: ${e.message}");
      }
      // هنا لو صار خطأ في عمليه الحفظ النهائي
    } catch (e) {
      _showError("حدث خطأ غير متوقع: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // الحفظ مع التدقيق على المعلومات المدخلة وصلاحيتها قبل الإعتماد في الفاير ستور
  Future<void> _onSavePressed() async {
    final String enteredEmail = _emailController.text.trim();
    final String enteredName = _nameController.text.trim();

    // 1. نتأكد انه مافي شيئ فاضي
    if (enteredName.isEmpty || _fullPhoneNumber.trim().isEmpty) {
      _showError("الرجاء إدخال الاسم ورقم الجوال أولاً"); // اذا فيه فراغ خله يرجع يعبي
      return;
    }
    setState(() => _isSaving = true);

    try {
      fb.User? currentUser = fb.FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // 2. لما دخلت بالجوال --> نتأكد انه الايميل ماقد استخدم
      if (widget.loginProvider == 'phone' && enteredEmail.isNotEmpty) {
        bool isTaken = await _dbService.isFieldTaken('email', enteredEmail, currentUser.uid);

        if (isTaken) {
          _showError("عذراً، هذا البريد الإلكتروني مسجل بالفعل بحساب آخر!");
          return;
        }
      }

      // حفظت قيمه تعلمني لو رقم الجوال تغير أو لا
      bool isPhoneChanged = _fullPhoneNumber.trim() != (currentUser.phoneNumber ?? "");

      // 3. لما دخلت بالإيميل --> نتأكد انه الرقم ماقد استخدم
      if (widget.loginProvider != 'phone' && isPhoneChanged) {
        bool isTaken = await _dbService.isFieldTaken('phone', _fullPhoneNumber.trim(), currentUser.uid);

        if (isTaken) {
          _showError("عذراً، رقم الجوال هذا مرتبط بحساب آخر بالفعل!");
          return;
        }
        _startPhoneVerification();
      } else {
        // 4. الحفظ النهائي إذا كان كل شيء تمام
        await _finalSave();
      }
    } catch (e) {
      _showError("حدث خطأ أثناء الفحص: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

// ---------------------------------------------------------
//  (خامسا) التحقق وصفحاته
// ---------------------------------------------------------

  // داله ارسال الكود عشان عمليه ربط الجوال .1
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

  // تصميم شكل نافذه ارخال كود التجقق .2
  void _showOtpDialog() {
    // صممت ليست به 6 اماكن لان كود التحقق يتكون منها
    final List<TextEditingController> otpControllers = List.generate(6, (index) => TextEditingController());
    // تصميم شكل الشيت اللي راح تظهر من الاسفل
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // نحسب حساب انه النافذه بالاسفل فممكن احتاج مساحه اكبر عشان اكتب الكود لو طلعت لوحه المفاتيح
      builder: (context) => Padding(
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
              // خط علوي للديكور
              Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 25),
              const Text("تحقق من الرقم لربط الحساب",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF444444))),
              const SizedBox(height: 10),
              Text("أدخل الرمز المرسل إلى $_fullPhoneNumber",
                  style: const TextStyle(fontSize: 13, color: Colors.grey), textAlign: TextAlign.center),
              const SizedBox(height: 30),

              // تصميم شكل الست بوكسات اللي فيها بندخل الارقام
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) => SizedBox(
                  width: 45,
                  child: TextField(
                    // سويت متغير عشان اخذ من اللست رقم لحال
                    controller: otpControllers[index],
                    autofocus: index == 0,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    // الخط ولونه داخل البوكس
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF673AB7)),
                    decoration: InputDecoration(
                      counterText: "",
                      fillColor: const Color(0xFFFBF9FF),
                      filled: true,
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFEEEEEE))
                      ),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF673AB7), width: 2)
                      ),
                    ),
                    onChanged: (value) {
                      // نمشي للي بعده اذا دخلت رقم
                      if (value.length == 1 && index < 5) FocusScope.of(context).nextFocus();
                      // نرجع للي قبله اذا حذفت رقم
                      if (value.isEmpty && index > 0) FocusScope.of(context).previousFocus();
                    },
                  ),
                )),
              ),

              const SizedBox(height: 35),

              WaterRippleButton(
                text: "تأكيد وربط الحساب",
                onTap: () async {
                  String smsCode = otpControllers.map((e) => e.text).join(); //جمعت الارقام من كل بوكس
                  try {
                    await _authService.linkPhoneNumber(_verificationId, smsCode); //ارسلنا الكود للفاير بيس عشان تربط الرقم
                    if (mounted) Navigator.pop(context); // نسكر الشيت
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
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
      setState(() => _isSaving = false);
    }
  }

// داله للتنظيف حتى لا تستهلك الذاكره
  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    _passController.dispose();
    super.dispose();
  }
// ---------------------------------------------------------
//  (سادسا) التصميم وشكل الصفحه
// ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // تعريف حالات القفل بناءً على طريقة الدخول
    bool isEmailLocked = widget.loginProvider == 'email' || widget.loginProvider == 'google';
    bool isPhoneLocked = widget.loginProvider == 'phone';
    //شكل صفحه الملف الشخصي
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // سهم لما نضغطه يوجهني للهوم
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF5A4A75)),
          onPressed: () => Navigator.pushAndRemoveUntil(
              context, MaterialPageRoute(builder: (context) => const HomePage()), (route) => false),
        ),
      ),
      body: LoginSignupBackground(
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator(color: Color(0xFF5A4A75))
              : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
            child: Column(
              children: [
                const Text("الملف الشخصي",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF5A4A75))),
                const SizedBox(height: 40),

                CustomInputField(
                  label: "الاسم الكامل",
                  hintText: "أدخل اسمك هنا",
                  controller: _nameController,
                  fillColor: Colors.white.withOpacity(0.7),
                ),
                const SizedBox(height: 15),

                CustomInputField(
                  label: "البريد الإلكتروني",
                  hintText: "example@mail.com",
                  controller: _emailController,
                  readOnly: isEmailLocked, //نقفله اذا داخلين بالايميل او قوقل
                  fillColor: isEmailLocked ? Colors.grey.withOpacity(0.2) : Colors.white.withOpacity(0.7),
                ),
                const SizedBox(height: 15),

                // عشان رقم الجوال له نوع فيلد غير فاحتجنا نسوي الليبل بشكل منفصل وننسقه
                const Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 8, bottom: 8),
                    child: Text("رقم الهاتف",
                        style: TextStyle(color: Color(0xFF5A4A75), fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
                AbsorbPointer(
                  absorbing: isPhoneLocked,
                  child: IntlPhoneField(
                    controller: _phoneController,
                    disableLengthCheck: true,
                    textAlign: TextAlign.left,
                    decoration: InputDecoration(
                      hintText: '5xxxxxxx',
                      fillColor: isPhoneLocked
                          ? Colors.grey.withOpacity(0.2)
                          : Colors.white.withOpacity(0.7),
                      filled: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none),
                    ),
                    initialCountryCode: 'SA',
                    onChanged: (phone) => _fullPhoneNumber = phone.completeNumber,
                  ),
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
                  fillColor: widget.canEditPassword ? Colors.white.withOpacity(0.7) : Colors.grey.withOpacity(0.2),
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
                    await fb.FirebaseAuth.instance.signOut();
                    if (mounted) {
                      //لما اطلع يودين لصفحه الدخول
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false);
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  label: const Text("تسجيل الخروج", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  //لاظهار طريقه الدخول المستخدمه
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
        Icon(icon, color: const Color(0xFF5A4A75), size: 20),
        const SizedBox(width: 8),
        Text("طريقة الدخول: $providerName", style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }
}