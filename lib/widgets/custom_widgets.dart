// lib/widgets/custom_widgets.dart
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/app_theme.dart';


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
            fontFamily: 'Cairo', // تأكدي من إضافة الخط هنا أيضاً
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
            fontFamily: 'Cairo',
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