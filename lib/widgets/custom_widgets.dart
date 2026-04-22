// lib/widgets/custom_widgets.dart
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/chat_list_page.dart';
import '../utils/app_theme.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../screens/home_page.dart';
import '../screens/account_info_page.dart'; // تأكدي من المسار الصحيح لصفحة الملف

// FOUND & LOST REPORTS PAGE
// 1. Page Header
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
                      children: [
                        Icon(icon,
                            size: AppDimens.iconSizeLg,
                            color: AppColors.primary
                        ), const SizedBox(height: 12),
                        Text(label,
                          style: const TextStyle(
                              fontFamily:'Tajawal',
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
// 2. Field Label
class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
             padding: const EdgeInsets.only(top: AppDimens.spaceMd, bottom: 5),
             child: Container(
                       width: double.infinity,
                       alignment: Alignment.centerRight,
                       child: Text(text,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                               fontFamily: 'Tajawal',
                               fontWeight: FontWeight.bold,
                               fontSize: AppDimens.fontMd,
                               color: AppColors.textPrimary,
                            ),
                       ),
             ),
    );
  }
}
// 3. Form Text Field
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
    return Directionality(
        textDirection: TextDirection.rtl,
        child: TextFormField(
               controller: controller,
               autovalidateMode: AutovalidateMode.onUserInteraction,
               maxLines: maxLines,
               textAlign: TextAlign.right,
               readOnly: readOnly,
               onTap: onTap,
               style: const TextStyle(
                   fontSize: AppDimens.fontMd,
                   color: AppColors.textPrimary
               ),
               validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                         if (readOnly) return 'يرجى تحديد الموقع من الخريطة';
                        return 'هذا الحقل مطلوب';
                    }
                    return null;
               },
               decoration: InputDecoration(
                             hintText: hint,
                             hintStyle: const TextStyle(
                                 fontSize: AppDimens.fontSm,
                                 color: AppColors.textHint
                             ),
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
                           errorStyle: const TextStyle(
                               color: AppColors.error,
                              fontFamily: 'Tajawal',
                              fontSize: 12,
                             ),
               ),
        ),
    );
  }
}
// 4. Location Picker Button
class LocationPickerButton extends StatelessWidget {
  final VoidCallback onTap;
  const LocationPickerButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
               alignment: Alignment.centerRight,
               child: TextButton.icon(
                             onPressed: onTap,
                             icon: const Icon(Icons.location_on_outlined,
                                 size: 18,
                                 color: AppColors.primary
                             ),
                             label: const Text('تحديد الموقع من الخريطة',
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
// 5. Image Picker Row
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
                              child: WaterRippleButton(
                                    text: 'ألبوم الصور',
                                    icon: Icons.photo_library_outlined,
                                    onTap: onPickFromGallery,
                                    height:40,
                              ),
                        ), const SizedBox(width: AppDimens.spaceSm),
                        Expanded(
                              child: WaterRippleButton(
                                   text: 'الكاميرا',
                                   icon: Icons.camera_alt_outlined,
                                   onTap: onPickFromCamera,
                                   height:40,
                              ),
                        ),
              ],
    );
  }
}
// 6. Selected Image Preview
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
                                child: kIsWeb ?
                                         Image.network(image.path,
                                             height: 80,
                                             width: 80,
                                             fit: BoxFit.cover
                                         ) : Image.file(File(image.path),
                                             height: 80,
                                             width: 80,
                                             fit: BoxFit.cover
                                         ),
                           ),
                          GestureDetector(
                             onTap: onRemove,
                             child: Container(
                                      margin: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                           color: AppColors.error,
                                           shape: BoxShape.circle,
                                      ),
                                     child: const Icon(Icons.close,
                                         color: Colors.white,
                                         size: 18
                                     ),
                             ),
                          ),
                      ],
              ),
    );
  }
}
// 7. Image Required Error
class ImageRequiredError extends StatelessWidget {
  final String message;
  const ImageRequiredError({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
             padding: const EdgeInsets.only(top: 6, right: 12),
             child: Text(message,
                   style: const TextStyle(
                       color: AppColors.error,
                       fontSize: AppDimens.fontSm
                   ),
             ),
    );
  }
}
// 8. Publish and Cancel buttons
class PublishAndCancelButtons extends StatelessWidget {
  final VoidCallback onPublish;
  final VoidCallback onCancel;

  const PublishAndCancelButtons({
    super.key,
    required this.onPublish,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
            children: [
                   Expanded(
                     child: WaterRippleButton(
                              text: 'انشر البلاغ',
                              icon: Icons.add_circle_outline_rounded,
                              onTap: onPublish,
                              height:40,
                     ),
                   ), const SizedBox(width: AppDimens.spaceSm),
                  Expanded(
                     child: WaterRippleButton(
                              text: 'إلغاء',
                              icon: Icons.close_rounded,
                              onTap: onCancel,
                              height:40,
                     ),
                  ),
            ],
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
  final IconData? icon;

  const WaterRippleButton({
    super.key,
    required this.text,
    required this.onTap,
    this.isLoading = false,
    this.width = double.infinity,
    this.height = AppDimens.buttonHeight,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                            gradient: kPrimaryGradient,
                            borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                            boxShadow: const [BoxShadow(
                                     color: AppColors.shadowColor,
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
                                          child: isLoading ? const SizedBox(
                                                                     width: 24,
                                                                     height: 24,
                                                                     child: CircularProgressIndicator(
                                                                           color: Colors.white,
                                                                           strokeWidth: 2,
                                                                     ),
                                                              ) : Row(
                                                                   mainAxisAlignment: MainAxisAlignment.center,
                                                                   children: [
                                                                        if (icon != null) ...[
                                                                           Icon(icon,
                                                                               color: Colors.white,
                                                                               size: 20
                                                                           ), const SizedBox(width: 8),],
                                                                           Text(text,
                                                                             style: const TextStyle(
                                                                                color: Colors.white,
                                                                                fontWeight: FontWeight.bold,
                                                                                fontSize: AppDimens.fontLg,
                                                                                fontFamily: 'Tajawal',
                                                                             ),
                                                                           ),
                                                                   ],
                                                              )
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
        if (index == 0) {
          // --- التعديل هنا: تفعيل الانتقال لصفحة الرسائل ---
          _navigateTo(context, const ChatListPage());
        }
        else if (index == 1) {
          _navigateTo(context, const HomePage());
        }
        else if (index == 2) {
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

class InfoRow extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool isRtl;
  final Color? color;

  const InfoRow({
    super.key,
    required this.text,
    required this.icon,
    this.isRtl = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = color ?? Colors.grey;
    return Padding(
             padding: const EdgeInsets.only(bottom: 3),
             child: Row(
                      mainAxisAlignment: isRtl ? MainAxisAlignment.end : MainAxisAlignment.start,
                      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                      children: [
                          Icon(icon,
                             size: 15,
                             color: displayColor,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(text,
                               textAlign: isRtl ? TextAlign.right : TextAlign.left,
                               maxLines: 1,
                               overflow: TextOverflow.ellipsis,
                               style: TextStyle(
                                 fontFamily: 'Tajawal',
                                 fontSize: 12,
                                 color: displayColor,
                               ),
                            ),
                          ),
                      ],
             ),
    );
  }
}
// ══════════════════════════════════════════════
//  Message Tile (قائمة الرسائل في الصفحة الرئيسية)
// ══════════════════════════════════════════════

class MessageTile extends StatelessWidget {
  final String name;
  final String message;
  final String? count;
  final VoidCallback onTap;

  const MessageTile({
    super.key,
    required this.name,
    required this.message,
    required this.onTap,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector( // 3. غلفي الـ Container بـ GestureDetector
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            // عدد الرسائل غير المقروءة
            if (count != null && count != "0")
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.primary, // اللون البنفسجي
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count!, // الرقم القادم من الفايربيس
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const Spacer(),
            // النصوص (الاسم والرسالة) بمحاذاة اليمين
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppDimens.fontXl,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppDimens.fontMd,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            // أيقونة المستخدم (شخص مع علامة استفهام كما في التصميم)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.textPrimary.withOpacity(0.6), width: 1.5),
              ),
              child: const Icon(Icons.person_search_outlined, size: 28, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
// ══════════════════════════════════════════════
//  Chat Input Field (حقل إدخال الرسالة)
// ══════════════════════════════════════════════

class ChatInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const ChatInputField({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            const Icon(Icons.mic_none_rounded, color: AppColors.textHint),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.fieldBg,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    hintText: "اكتب رسالتك...",
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: AppColors.textHint, fontSize: AppDimens.fontMd),
                    filled: false,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.attach_file, color: AppColors.textHint),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onSend,
              child: const CircleAvatar(
                backgroundColor: AppColors.textPrimary,
                radius: 20,
                child: Icon(Icons.send, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ══════════════════════════════════════════════
//  Chat Message Bubble (فقاعة الرسالة)
// ══════════════════════════════════════════════

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isSender;
  final String time;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isSender,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSender ? Alignment.centerLeft : Alignment.centerRight,
      child: Column(
        crossAxisAlignment: isSender ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              // لون الفقاعة: أزرق فاتح للمرسل، أبيض للمستقبل حسب التصميم
              color: isSender ? const Color(0xFFCDE2FD) : AppColors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isSender ? 0 : 20),
                bottomRight: Radius.circular(isSender ? 20 : 0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontFamily: 'Tajawal',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Text(
              time,
              style: const TextStyle(fontSize: 10, color: AppColors.textHint, fontFamily: 'Tajawal'),
            ),
          ),
        ],
      ),
    );
  }
}
// ══════════════════════════════════════════════
//  Chat Avatar (صورة المستخدم الدائرية)
// ══════════════════════════════════════════════

class ChatAvatar extends StatelessWidget {
  final String imageUrl;
  const ChatAvatar({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
      ),
      child: CircleAvatar(
        radius: 35,
        backgroundColor: AppColors.fieldBg,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.person, color: AppColors.textHint, size: 35),
          ),
        ),
      ),
    );
  }
}