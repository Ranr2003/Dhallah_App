//custom_button1.dart
//Rand
import 'package:flutter/material.dart';

class WaterRippleButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool isLoading;
  // أضفنا هذه المتغيرات للتحكم في الحجم
  final double width;
  final double height;

  const WaterRippleButton({
    super.key,
    required this.text,
    required this.onTap,
    this.isLoading = false,
    this.width = double.infinity, // القيمة الافتراضية عرض كامل الشاشة
    this.height = 55,             // القيمة الافتراضية للطول
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,  // نستخدم المتغير هنا
      height: height, // نستخدم المتغير هنا
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [Color(0xFFE9D7F7), Color(0xFFD2B4EC)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD2B4EC).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            splashFactory: InkRipple.splashFactory,
            splashColor: Colors.white.withOpacity(0.4),
            highlightColor: Colors.transparent,
            onTap: isLoading ? null : onTap,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}