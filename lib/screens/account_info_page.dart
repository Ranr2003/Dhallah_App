//Rand
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/login_signup_background.dart'; // تأكد من المسار الصحيح
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _image; // لتخزين الصورة المختارة
  final ImagePicker _picker = ImagePicker();

  // دالة اختيار الصورة من المعرض
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoginSignupBackground(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              // قسم الصورة الشخصية (Avatar)
              // قسم الصورة الشخصية المحدث
              Stack(
                children: [
                  CircleAvatar(
                    radius: 65,
                    backgroundColor: const Color(0xFFD2B4EC).withOpacity(0.2),
                    child: ClipOval(
                      child: _image != null
                          ? Image.file(
                        _image!,
                        width: 130,
                        height: 130,
                        fit: BoxFit.cover,
                      )
                          : Image.asset(
                        'assets/images/df_Avtar.png',
                        width: 130,
                        height: 130,
                        fit: BoxFit.cover, // سيملأ الدائرة الآن لأنك قصصتِ الحواف الزائدة
                        errorBuilder: (context, error, stackTrace) {
                          // هذا الجزء يحميكِ من تعطل التطبيق إذا لم يجد الصورة
                          return const Icon(Icons.person, size: 60, color: Colors.grey);
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFD2B4EC),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const Text(
                "الملف الشخصي",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5A4A75),
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 25),

              // الحقول مع معلومات افتراضية
              _buildField("الاسم الكامل", "رند محمد"),
              const SizedBox(height: 15),
              _buildField("البريد الإلكتروني", "rand@example.com"),
              const SizedBox(height: 15),
              _buildField("رقم الهاتف", "+966 555 555 555"),
              const SizedBox(height: 15),
              _buildField("كلمة السر", "********", isPass: true),

              const SizedBox(height: 35),

              // زر حفظ التعديلات (شكلي)
              _buildSaveButton(),

              const SizedBox(height: 20),

              // زر تسجيل الخروج
              TextButton.icon(
                onPressed: () {
                  // العودة لصفحة تسجيل الدخول
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                        (route) => false,
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.redAccent, size: 18),
                label: const Text(
                  "تسجيل الخروج",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ودجت بناء الحقول مع قيم افتراضية
  Widget _buildField(String label, String initialValue, {bool isPass = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 5, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF666666)),
          ),
        ),
        TextField(
          obscureText: isPass,
          textAlign: TextAlign.right,
          controller: TextEditingController(text: initialValue),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            filled: true,
            fillColor: Colors.white.withOpacity(0.7),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFFD2B4EC), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // زر الحفظ
  Widget _buildSaveButton() {
    return Container(
      width: 200,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE9D7F7), Color(0xFFD2B4EC)],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD2B4EC).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          "حفظ التعديلات",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}