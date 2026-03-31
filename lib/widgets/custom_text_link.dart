//custom_text_link.dart
//Rand
import 'package:flutter/material.dart';

class CustomTextLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final double fontSize;
  final Color color;

  const CustomTextLink({
    super.key,
    required this.text,
    required this.onTap,
    this.fontSize = 13,
    this.color = const Color(0xFFD2B4EC), // لونك المعتمد
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline, // الخط اللي تحته
          fontFamily: 'Cairo',
        ),
      ),
    );
  }
}