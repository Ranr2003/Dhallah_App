//Rand
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/login_signup_background.dart'; // تأكد من المسار الصحيح
import '../widgets/custom_button1.dart';
import'../Widgets/custom_text_field.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  final String userEmail;

  const ProfilePage({super.key, required this.userEmail});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _image;
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _emailController;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.userEmail);
  }

  // هذه هي الدالة التي كانت مفقودة وتسببت في الخطأ
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("خطأ في اختيار الصورة: $e");
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LoginSignupBackground(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 65,
                    backgroundColor: const Color(0xFFD2B4EC).withOpacity(0.2),
                    child: ClipOval(
                      child: _image != null
                          ? Image.file(_image!, width: 130, height: 130, fit: BoxFit.cover)
                          : Image.asset(
                        'assets/images/df_Avtar.png',
                        width: 130, height: 130, fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.person, size: 60, color: Colors.grey),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage, // الآن ستعمل بدون أخطاء
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Color(0xFFD2B4EC), shape: BoxShape.circle),
                        child: const Icon(Icons.edit, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const Text(
                "الملف الشخصي",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF5A4A75), fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 25),

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
                fillColor: Colors.white.withOpacity(0.7),
              ),
              const SizedBox(height: 15),

              CustomInputField(
                label: "رقم الهاتف",
                hintText: "+966 xxxxxxxxx",
                controller: _phoneController,
                fillColor: Colors.white.withOpacity(0.7),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 15),

              CustomInputField(
                label: "كلمة السر الجديدة",
                hintText: "أدخل كلمة سر قوية",
                controller: _passController,
                isPass: true,
                fillColor: Colors.white.withOpacity(0.7),
              ),

              const SizedBox(height: 35),

              WaterRippleButton(
                text: "حفظ التعديلات",
                width: 200,
                height: 50,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("تم حفظ التعديلات بنجاح")),
                  );
                },
              ),

              const SizedBox(height: 20),

              TextButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                        (route) => false,
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.redAccent, size: 18),
                label: const Text(
                  "تسجيل الخروج",
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}