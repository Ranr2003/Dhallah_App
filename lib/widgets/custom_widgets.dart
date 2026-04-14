// lib/widgets/custom_widgets.dart
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../screens/home_page.dart';
import '../screens/account_info_page.dart'; // تأكدي من المسار الصحيح لصفحة الملف


// ══════════════════════════════════════════════
// 1. Page Header
// ══════════════════════════════════════════════

// Displays a centered icon and title at the top of a report page.
class ReportPageHeader extends StatelessWidget {
  final IconData icon;
  final String label;

  const ReportPageHeader({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [Icon(icon, size: AppDimens.iconSizeLg, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: AppDimens.fontTitle,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}


// ══════════════════════════════════════════════
// 2. Field Label
// ══════════════════════════════════════════════

// Renders a bold label above a form field with consistent vertical spacing.
// Renders a bold label above a form field with consistent vertical spacing.
class FieldLabel extends StatelessWidget {
  final String text;

  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppDimens.spaceMd, bottom: 5),
      // استخدمنا SizedBox.expand أو عرض كامل لضمان السيطرة على المحاذاة
      child: Container(
        width: double.infinity, // يجبر الحاوية على أخذ عرض الشاشة كاملاً
        alignment: Alignment.centerRight, // يحاذي ما بداخله لليمين تماماً
        child: Text(
          text,
          textAlign: TextAlign.right, // تأكيد إضافي للمحاذاة داخل النص نفسه
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: AppDimens.fontMd,
            fontFamily: 'Tajawal', // تأكدي من إضافة الخط هنا أيضاً
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}


// ══════════════════════════════════════════════
// 3. Form Text Field
// ══════════════════════════════════════════════

// A styled TextFormField with built-in validation.
// Shows a specific error if [readOnly] is true (location field),
// or a generic required-field error otherwise.
class Textfield extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;

  const Textfield({
    super.key,
    required this.hint,
    required this.controller,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      textAlign: TextAlign.right,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(fontSize: AppDimens.fontMd, color: AppColors.textPrimary),

      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          if (readOnly) return 'يرجى تحديد الموقع من الخريطة';
          return 'هذا الحقل مطلوب';
        }
        return null;
      },

      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: AppDimens.fontSm, color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.fieldBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
      ),
    );
  }
}


// ══════════════════════════════════════════════
// 4. Location Picker Button
// ══════════════════════════════════════════════

// A text button with a pin icon that triggers the map picker screen.
class LocationPickerButton extends StatelessWidget {
  final VoidCallback onTap;

  const LocationPickerButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.location_on_outlined, size: 18, color: AppColors.primary),
        label: const Text(
          'تحديد الموقع من الخريطة',
          style: TextStyle(
            fontFamily: 'Tajawal',
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}


// ══════════════════════════════════════════════
// 5. Image Picker Row
// ══════════════════════════════════════════════

// Renders two equal-width buttons side by side for picking
// an image from the camera or the photo gallery.
class ImagePickerRow extends StatelessWidget {
  final VoidCallback onPickFromCamera;
  final VoidCallback onPickFromGallery;

  const ImagePickerRow({
    super.key,
    required this.onPickFromCamera,
    required this.onPickFromGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GradientButton(
            label: 'الكاميرا',
            icon: Icons.camera_alt_outlined,
            onTap: onPickFromCamera,
          ),
        ),
        const SizedBox(width: AppDimens.spaceSm),
        Expanded(
          child: GradientButton(
            label: 'ألبوم الصور',
            icon: Icons.photo_library_outlined,
            onTap: onPickFromGallery,
          ),
        ),
      ],
    );
  }
}


// ══════════════════════════════════════════════
// 6. Selected Image Preview
// ══════════════════════════════════════════════

// Shows a thumbnail of the picked image with a red remove button overlay.
// Handles both web (network) and mobile (file) image sources.
class SelectedImagePreview extends StatelessWidget {
  final XFile image;
  final VoidCallback onRemove;

  const SelectedImagePreview({
    super.key,
    required this.image,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppDimens.spaceMd),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
            child: kIsWeb
                ? Image.network(image.path, height: 80, width: 80, fit: BoxFit.cover)
                : Image.file(File(image.path), height: 80, width: 80, fit: BoxFit.cover),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}


// ══════════════════════════════════════════════
// 7. Image Required Error
// ══════════════════════════════════════════════

// Displays a small red error message when no image has been selected.
class ImageRequiredError extends StatelessWidget {
  final String message;

  const ImageRequiredError({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, right: 12),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.error, fontSize: AppDimens.fontSm),
      ),
    );
  }
}


// ══════════════════════════════════════════════
// 8. Form Action Buttons
// ══════════════════════════════════════════════

// Renders the Publish and Cancel buttons side by side at the bottom of the form.
class FormActionButtons extends StatelessWidget {
  final VoidCallback onPublish;
  final VoidCallback onCancel;

  const FormActionButtons({
    super.key,
    required this.onPublish,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GradientButton(
            label: 'انشر البلاغ',
            icon: Icons.add_circle_outline_rounded,
            onTap: onPublish,
          ),
        ),
        const SizedBox(width: AppDimens.spaceMd),
        Expanded(
          child: GradientButton(
            label: 'إلغاء',
            icon: Icons.close_rounded,
            onTap: onCancel,
          ),
        ),
      ],
    );
  }
}


// ══════════════════════════════════════════════
// 9. Gradient Button
// ══════════════════════════════════════════════

// A reusable full-width button with a gradient background, an icon, and a label.
// Used as the primary action button throughout the app.
class GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const GradientButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          gradient: kPrimaryGradient,
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: AppDimens.fontLg,
              ),
            ),
            const SizedBox(width: 6),
            Icon(icon, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// 10. Water Ripple Button (نسخة مشروع دلة النهائية)
// ══════════════════════════════════════════════

class WaterRippleButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool isLoading;
  final double width;
  final double height;

  const WaterRippleButton({
    super.key,
    required this.text,
    required this.onTap,
    this.isLoading = false,
    this.width = double.infinity,
    this.height = AppDimens.buttonHeight, // استخدمنا الطول الموحد من الثيم
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        // استخدام التدرج الموحد المعرف في ملف الثيم
        gradient: kPrimaryGradient,
        // استخدام انحناء الزوايا المتوسط من AppDimens
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor, // استخدمنا لون الظل المخصص في الثيم
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
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
                  fontSize: AppDimens.fontXl, // حجم خط مناسب للأزرار
                  fontFamily: 'Tajawal', // استخدمنا الخط المعتمد في الثيم
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
// ══════════════════════════════════════════════
// 11. Custom Input Field (نسخة مشروع دلة النهائية)
// ══════════════════════════════════════════════

/// A standardized text input field used across the "Dhallah" app.
/// It includes a label above the field and follows the global theme constraints.
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
      // محاذاة العناصر لليمين بما يتناسب مع اللغة العربية
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 1. عنوان الحقل (Field Label)
        Text(
          label,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal', // تم التوحيد مع الثيم الأساسي
            fontSize: AppDimens.fontLg,
            color: AppColors.textPrimary,
          ),
        ),

        // مسافة موحدة بين العنوان والحقل من ملف AppDimens
        const SizedBox(height: AppDimens.spaceSm),

        // 2. حقل الإدخال (Text Field)
        TextField(
          controller: controller,
          obscureText: isPass,
          keyboardType: keyboardType,
          readOnly: readOnly,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: AppDimens.fontMd,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              fontSize: AppDimens.fontSm,
              color: AppColors.textHint,
            ),
            filled: true,
            // استخدام لون الخلفية من الثيم إلا إذا تم تمرير لون مخصص
            fillColor: fillColor ?? AppColors.fieldBg,

            // إعدادات الحدود (Borders) باستخدام زوايا AppDimens الموحدة (12.0)
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),

            // هوامش داخلية متناسقة
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
// ══════════════════════════════════════════════
// 12. Custom Text Link (نسخة مشروع دلة النهائية)
// ══════════════════════════════════════════════

/// A clickable text link with an underline, used for navigation or small actions.
class CustomTextLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final double? fontSize;
  final Color? color;

  const CustomTextLink({
    super.key,
    required this.text,
    required this.onTap,
    this.fontSize,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(
          // استخدام لون الـ Primary من الثيم كافتراضي أو اللون الممرر
          color: color ?? AppColors.primary,
          // استخدام حجم الخط المتوسط من الثيم كافتراضي
          fontSize: fontSize ?? AppDimens.fontMd,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
          decorationColor: color ?? AppColors.primary, // لون الخط السفلي
          fontFamily: 'Tajawal', // توحيد الخط مع بقية المشروع
        ),
      ),
    );
  }
}
// ══════════════════════════════════════════════
// 13. Custom Phone Field (نسخة مشروع دلة النهائية)
// ══════════════════════════════════════════════
/// A standardized phone input field with country picker for "Dhallah" app.
class CustomPhoneField extends StatelessWidget {
  final TextEditingController? controller;
  final Function(String fullNumber) onChanged;
  final String? errorText;
  final bool readOnly;

  const CustomPhoneField({
    super.key,
    this.controller,
    required this.onChanged,
    this.errorText,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: readOnly,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: IntlPhoneField(
          controller: controller,
          enabled: !readOnly, // ✅ يقفل الحقل
          disableLengthCheck: true,
          textAlign: TextAlign.left,
          initialCountryCode: 'SA',
          onChanged: (phone) {
            if (!readOnly) { // ✅ يمنع التغيير
              onChanged(phone.completeNumber);
            }
          },
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: AppDimens.fontLg,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: '5xxxxxxx',
            errorText: errorText,
            filled: true,
            fillColor: readOnly
                ? AppColors.secondary.withOpacity(0.3)
                : AppColors.fieldBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}
// ══════════════════════════════════════════════
// 14. Custom OTP Field (نسخة مشروع دلة النهائية)
// ══════════════════════════════════════════════
class CustomOTPField extends StatelessWidget {
  final int index;
  final List<String> otpCode;
  final bool isError;
  final VoidCallback onChanged;

  const CustomOTPField({
    super.key,
    required this.index,
    required this.otpCode,
    required this.isError,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 45,
      child: TextField(
        autofocus: index == 0,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryDark, // لون أغمق قليلاً للوضوح
          fontFamily: 'Tajawal',
        ),
        decoration: InputDecoration(
          counterText: "",
          fillColor: AppColors.fieldBg,
          filled: true,
          // استخدام ألوان Status & Feedback من الثيم
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isError ? AppColors.error : const Color(0xFFEEEEEE),
              width: isError ? 1.5 : 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        onChanged: (value) {
          otpCode[index] = value;
          onChanged();
          if (value.length == 1 && index < 5) FocusScope.of(context).nextFocus();
          if (value.isEmpty && index > 0) FocusScope.of(context).previousFocus();
        },
      ),
    );
  }
}


class CustomFloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap; // اختياري لو تبغين تسوين شي إضافي

  const CustomFloatingNavBar({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  // دالة ذكية للانتقال بحركة Slide (من اليمين لليسار)
  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0); // يبدأ من اليمين
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: AppDimens.paddingH,
      right: AppDimens.paddingH,
      bottom: AppDimens.paddingH,
      child: Container(
        height: 65,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
          boxShadow: const [
            BoxShadow(color: AppColors.shadowColor, blurRadius: 20, offset: Offset(0, 4))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // أيقونة الرسائل (تجاهلناها حالياً)
            _buildNavItem(context, index: 0, icon: Icons.chat_bubble_outline_rounded),

            // أيقونة الرئيسية (البيت)
            _buildNavItem(context, index: 1, icon: Icons.home_rounded),

            // أيقونة الملف الشخصي (الشخص)
            _buildNavItem(context, index: 2, icon: Icons.person_outline_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, {required int index, required IconData icon}) {
    bool isSelected = currentIndex == index;

    return InkWell(
      onTap: () async {
        if (isSelected) return; // إذا ضغطت على نفس الصفحة لا تفعل شيئاً

        if (onTap != null) onTap!(index);

        // منطق التنقل الموحد
        if (index == 1) {
          // العودة للرئيسية (يفضل pop إذا كانت موجودة في الذاكرة أو push للهوم)
          _navigateTo(context, const HomePage());
        } else if (index == 2) {
        final user = FirebaseAuth.instance.currentUser;

        // 1. نجلب الطريقة المخزنة في الجهاز (إيميل، جوال، أو قوقل)
        final prefs = await SharedPreferences.getInstance();
        String? savedMethod = prefs.getString('loginMethod');

        // 2. إذا لم يجد الطريقة المخزنة، نحاول التخمين (كملاذ أخير)
        String finalProvider = savedMethod ??
        (user?.providerData.any((p) => p.providerId == 'password') == true ? 'email' : 'phone');

        // 3. نرسل البيانات الحقيقية
        _navigateTo(context, ProfilePage(
        userEmail: user?.email ?? user?.phoneNumber ?? "",
        loginProvider: finalProvider, // هنا القيمة بتكون صحيحة بناءً على الـ Session
        ));
        }
      },
      borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        )
            : null,
        child: Icon(
          icon,
          size: 26,
          color: isSelected ? AppColors.primaryDark : AppColors.primary,
        ),
      ),
    );
  }
}