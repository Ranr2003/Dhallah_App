// lib/screens/lost_report_page.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/item_model.dart';
import '../models/report_model.dart';
import '../services/item_serv.dart';
import '../utils/app_theme.dart';
import '../widgets/custom_widgets.dart';
import 'map_picker_page.dart';


/// Main widget - creates state class only
class LostReportPage extends StatefulWidget {
  const LostReportPage({super.key});
  @override
  State<LostReportPage> createState() => _LostReportPageState();
}

class _LostReportPageState extends State<LostReportPage> {

  /// Form key for field validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// Controllers for all text input fields
  final TextEditingController _typeController  = TextEditingController();
  final TextEditingController _descController  = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _featController  = TextEditingController();

  /// UI state management
  XFile? _selectedImage;           // Selected image file
  PickedLocation? _pickedLocation; // Selected map location
  bool _isPublishing = false;      // Show loading spinner
  bool _showImageError = false;    // Show image required error

  /// Firebase service for data upload
  final ItemService _itemService = ItemService();

  /// Called once when page opens - setup listeners
  @override
  void initState() {
    super.initState();
    // Update UI when user types in any field
    _typeController.addListener(() => setState(() {}));
    _descController.addListener(() => setState(() {}));
    _colorController.addListener(() => setState(() {}));
    _placeController.addListener(() => setState(() {}));
    _featController.addListener(() => setState(() {}));
  }

  /// Called once when page closes - cleanup memory
  @override
  void dispose() {
    _typeController.dispose();
    _descController.dispose();
    _colorController.dispose();
    _placeController.dispose();
    _featController.dispose();
    super.dispose();
  }

  /// Select image from camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    final image = await ImagePicker().pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _showImageError = false;  // Hide error when image selected
      });
    }
  }

  /// Remove selected image and clear preview
  void _removeImage() {
    setState(() => _selectedImage = null);
  }

  /// Open map screen and wait for location selection
  Future<void> _pickLocation() async {
    final picked = await Navigator.push<PickedLocation>(
      context,
      MaterialPageRoute(builder: (_) => const MapPickerPage()),
    );
    if (picked != null) {
      setState(() {
        _pickedLocation = picked;
        _placeController.text = picked.fullAddress;
      });
    }
  }

  /// Main function - validates form and uploads report to Firebase
  Future<void> _publishReport() async {

    // 1. Check all form fields are valid
    if (!_formKey.currentState!.validate()) return;

    // 2. Create Item object for validation
    final item = Item(
      category: _typeController.text.trim(),
      description: _descController.text.trim(),
      color: _colorController.text.trim(),
      uniqueFeatures: _featController.text.trim(),
      imageURL: _selectedImage?.path ?? '',
    );

    // 3. Validate item data completeness
    if (!item.validateItem) {
      if (_selectedImage == null) {
        setState(() => _showImageError = true);
      }
      return;
    }

    // 4. Show loading spinner
    setState(() => _isPublishing = true);

    try {
      // 5. Create complete LostItemReport
      final report = LostItemReport(
        description: 'بلاغ عن مفقود: ${_typeController.text.trim()}',
        date: DateTime.now(),
        status: 'Active',
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        item: item,
        lastKnownLocation: _placeController.text.trim(),
        coordinates: _pickedLocation!.coordinates,
      );

      // 6. Upload to Firebase (includes image upload)
      await _itemService.uploadLostReport(report);

      // 7. Success - show message and go back
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم نشر بلاغك بنجاح!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);

    } catch (e) {
      // Show error message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ أثناء النشر: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      // Always hide loading (success or error)
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  /// Builds the entire UI - called automatically on setState()
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingH),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// Header with icon and title
            const SizedBox(height: 10),
            const ReportPageHeader(
              icon: Icons.search_rounded,
              label: 'ضيعت شيء وتدور عليه؟',
            ),
            const SizedBox(height: AppDimens.spaceLg),

            /// 1. Item type field
            FieldLabel('نوعه'),
            Textfield(hint: 'مثال: محفظة، جوال، بطاقة...', controller: _typeController),

            /// 2. Item description (multi-line)
            FieldLabel('الوصف'),
            Textfield(hint: 'الحجم، حالة الشيء، أي تفاصيل مهمة...', controller: _descController, maxLines: 2),

            /// 3. Item color field
            FieldLabel('اللون'),
            Textfield(hint: 'مثال: أسود، فضي...', controller: _colorController),

            /// 4. Location fields (read-only + picker button)
            FieldLabel('المكان'),
            Textfield(hint: 'أين فُقد؟ حدد الموقع من الخريطة', controller: _placeController, readOnly: true),
            LocationPickerButton(onTap: _pickLocation),

            /// 5. Image picker buttons
            FieldLabel('صورة للغرض'),
            ImagePickerRow(
              onPickFromCamera: () => _pickImage(ImageSource.camera),
              onPickFromGallery: () => _pickImage(ImageSource.gallery),
            ),

            /// Image error message (conditional)
            if (_showImageError)
              const ImageRequiredError(message: 'يرجى إرفاق صورة للغرض المفقود'),

            /// Image preview with remove button (conditional)
            if (_selectedImage != null)
              SelectedImagePreview(image: _selectedImage!, onRemove: _removeImage),

            /// 6. Unique features field
            FieldLabel('علامات فارقة'),
            Textfield(hint: 'مثال: خدش، ملصق، قطعة مكسورة...', controller: _featController),

            const SizedBox(height: 35),

            /// Action buttons or loading spinner
            if (_isPublishing)
            /// Show spinner while uploading
              const Center(child: CircularProgressIndicator(color: AppColors.primary))
            else
            /// Publish and Cancel buttons
              FormActionButtons(
                onPublish: _publishReport,
                onCancel: () => Navigator.pop(context),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}