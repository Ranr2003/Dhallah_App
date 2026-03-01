import 'package:flutter/material.dart';

class CustomInputField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final bool isPass;
  final TextInputType keyboardType;
  final Color? fillColor;
  final bool readOnly;

  const CustomInputField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    this.isPass = false,
    this.keyboardType = TextInputType.text,
    this.fillColor,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      // تم التعديل هنا ليكون العنوان في اليمين تماماً
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          textAlign: TextAlign.right, // لضمان اتجاه النص العربي
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
            fontSize: 14,
            color: Color(0xFF5A4A75),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPass,
          keyboardType: keyboardType,
          readOnly: readOnly,
          textAlign: TextAlign.right, // النص داخل الحقل يبدأ من اليمين
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
            filled: true,
            fillColor: fillColor ?? Colors.white.withOpacity(0.7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          ),
        ),
      ],
    );
  }
}