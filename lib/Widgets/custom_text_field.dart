import 'package:flutter/material.dart';

class CustomInputField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final bool isPass;
  final Color fillColor;
  final TextInputType keyboardType;
  final String? Function(String?)? validator; // للتحقق من الأخطاء

  const CustomInputField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    this.isPass = false,
    this.fillColor = const Color(0xFFFBF9FF), // لون افتراضي
    this.keyboardType = TextInputType.text,   // نوع البيانات
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 5, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF444444)),
          ),
        ),
        TextFormField( // استخدمنا TextFormField لدعم الـ Validator
          controller: controller,
          obscureText: isPass,
          textAlign: TextAlign.right,
          keyboardType: keyboardType,
          validator: validator, // هنا تظهر رسالة الخطأ لو البيانات غير مطابقة
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            filled: true,
            fillColor: fillColor, // اللون اللي تحدده لكل ملف
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFFD2B4EC), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}