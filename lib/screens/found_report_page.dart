// lib/screens/found_report_page.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import '../models/item_model.dart';
import '../models/report_model.dart';
import '../services/item_serv.dart';
import '../widgets/custom_widgets.dart';
import 'map_picker_page.dart';
import '../utils/app_theme.dart';
import '../services/authentication_serv.dart';

class FoundReportPage extends StatefulWidget {
  const FoundReportPage({super.key});
  @override
  State<FoundReportPage> createState() => _FoundReportPageState();
}

class _FoundReportPageState extends State<FoundReportPage> {
  final ReportService _itemService = ReportService();
  final AuthenticationService _authService = AuthenticationService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _typeController  = TextEditingController();
  final TextEditingController _descController  = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _featController  = TextEditingController();
  XFile? _selectedImage;
  PickedLocation? _pickedLocation;
  bool _isPublishing = false;
  bool _showImageError = false;

  @override
  void dispose() {
    _typeController.dispose();
    _descController.dispose();
    _colorController.dispose();
    _placeController.dispose();
    _featController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const ReportPageHeader(
                icon: Icons.person_search_outlined,
                label: 'لقيت شيء وتدور على صاحبه؟',
              ),
              const SizedBox(height: 25),
              const FieldLabel('نوعه'),
              Textfield(hint: 'مثال: محفظة، جوال، بطاقة...', controller: _typeController),
              const FieldLabel('الوصف'),
              Textfield(hint: 'الحجم، حالة الشيء، أي تفاصيل مهمة...', controller: _descController, maxLines: 2),
              const FieldLabel('اللون'),
              Textfield(hint: 'مثال: أسود، فضي...', controller: _colorController),
              const FieldLabel('المكان'),
              Textfield(hint: 'أين عُثر عليه؟ حدد الموقع من الخريطة', controller: _placeController, readOnly: true),
              LocationPickerButton(onTap: _pickLocation),
              const FieldLabel('صورة للغرض'),
              ImagePickerRow(
                onPickFromCamera: () => _pickImage(ImageSource.camera),
                onPickFromGallery: () => _pickImage(ImageSource.gallery),
              ),
              if (_showImageError && _selectedImage == null)
                const ImageRequiredError(message: 'يرجى إرفاق صورة للغرض'),
              if (_selectedImage != null)
                SelectedImagePreview(
                  image: _selectedImage!,
                  onRemove: () => setState(() => _selectedImage = null),
                ),
              const FieldLabel('علامة فارقة'),
              Textfield(hint: 'مثال: خدش، ملصق، قطعة مكسورة...', controller: _featController),
              const SizedBox(height: 40),
              _isPublishing
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : PublishAndCancelButtons(
                onPublish: _publishReport,
                onCancel: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
        _showImageError = false;
      });
    }
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<PickedLocation>(
      context,
      MaterialPageRoute(builder: (context) => const MapPickerPage()),
    );
    if (result != null) {
      setState(() {
        _pickedLocation = result;
        _placeController.text = result.fullAddress;
      });
    }
  }

  Future<void> _publishReport() async {
    setState(() => _showImageError = _selectedImage == null);

    bool isFormValid = _formKey.currentState?.validate() ?? false;
    bool hasLocation = _pickedLocation != null;
    bool hasImage = _selectedImage != null;

    if (!isFormValid || !hasLocation || !hasImage) {
      if (!hasLocation && isFormValid && hasImage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى تحديد الموقع من الخريطة', textAlign: TextAlign.right), backgroundColor: AppColors.error),
        );
      }
      return;
    }

    setState(() => _isPublishing = true);
    try {
      final item = Item(
        category: _typeController.text.trim(),
        description: _descController.text.trim(),
        color: _colorController.text.trim(),
        uniqueFeatures: _featController.text.trim(),
        imageURL: '',
      );
      final report = Report(
        type: "found",
        userId: _authService.currentUserId,
        item: item,
        locationName: _placeController.text.trim(),
        coordinates: _pickedLocation!.coordinates,
        createdAt: DateTime.now(),
      );

      await _itemService.submitReport(report, _selectedImage);
      _showNotice(isSuccess: true);
    } catch (e) {
      _showNotice(isSuccess: false, error: e.toString());
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  void _showNotice({required bool isSuccess, String? error}) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      autoHide: const Duration(seconds: 3),
      dialogBorderRadius: BorderRadius.circular(20),
      onDismissCallback: (_) { if (isSuccess) Navigator.pop(context); },
      body: Column(
        children: [
          const SizedBox(height: 15),
          Icon(isSuccess ? Icons.check_circle_rounded : Icons.cancel_outlined,
              color: isSuccess ? AppColors.primary : AppColors.error, size: 60),
          const SizedBox(height: 10),
          Text(isSuccess ? 'تم بنجاح' : 'فشل النشر',
              style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Text(isSuccess ? 'تم رفع بلاغ المعثورات بنجاح!' : 'حدث خطأ: $error',
                textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14)),
          ),
          const SizedBox(height: 25),
        ],
      ),
    ).show();
  }
}