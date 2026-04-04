import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/item_model.dart';
import '../models/report_model.dart';
import '../services/item_serv.dart';
import '../widgets/custom_widgets.dart';
import 'map_picker_page.dart';

class LostReportPage extends StatefulWidget {
  const LostReportPage({super.key});
  @override
  State<LostReportPage> createState() => _LostReportPageState();
}

class _LostReportPageState extends State<LostReportPage> {
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
  final ItemService _itemService = ItemService();

  Future<void> _pickImage(ImageSource source) async {
    final image = await ImagePicker().pickImage(source: source);
    if (image != null) setState(() { _selectedImage = image; _showImageError = false; });
  }

  Future<void> _pickLocation() async {
    final picked = await Navigator.push<PickedLocation>(context, MaterialPageRoute(builder: (_) => const MapPickerPage()));
    if (picked != null) setState(() { _pickedLocation = picked; _placeController.text = picked.fullAddress; });
  }

  Future<void> _publishReport() async {
    if (!_formKey.currentState!.validate() || _pickedLocation == null || _selectedImage == null) {
      if (_selectedImage == null) setState(() => _showImageError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إكمال جميع البيانات والصورة'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isPublishing = true);

    try {
      final item = Item(
          category: _typeController.text,
          description: _descController.text,
          color: _colorController.text,
          uniqueFeatures: _featController.text,
          imageURL: _selectedImage?.path ?? ''
      );

      final report = LostItemReport(
          description: 'بلاغ عن مفقود: ${_typeController.text}',
          date: DateTime.now(),
          status: 'Active',
          userId: FirebaseAuth.instance.currentUser?.uid ?? '',
          item: item,
          lastKnownLocation: _placeController.text,
          coordinates: _pickedLocation!.coordinates
      );

      await _itemService.uploadLostReport(report);

      // إغلاق الـ Pop-up أولاً
      if (mounted) Navigator.pop(context);

      // إظهار رسالة النجاح على مستوى الـ Scaffold الرئيسي
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفع بلاغك بنجاح!', style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating, // لجعلها تظهر بشكل عائم فوق الـ NavBar
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء النشر: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ReportPageHeader(icon: Icons.search_rounded, label: 'ضيعت شيء وتدور عليه؟'),
            const SizedBox(height: 20),
            FieldLabel('نوعه'),
            Textfield(hint: 'مثال: محفظة، جوال...', controller: _typeController),
            FieldLabel('الوصف'),
            Textfield(hint: 'الحجم، الحالة...', controller: _descController, maxLines: 2),
            FieldLabel('اللون'),
            Textfield(hint: 'مثال: أسود...', controller: _colorController),
            FieldLabel('المكان'),
            Textfield(hint: 'حدد الموقع من الخريطة', controller: _placeController, readOnly: true),
            LocationPickerButton(onTap: _pickLocation),
            FieldLabel('صورة للغرض'),
            ImagePickerRow(onPickFromCamera: () => _pickImage(ImageSource.camera), onPickFromGallery: () => _pickImage(ImageSource.gallery)),
            if (_selectedImage != null) SelectedImagePreview(image: _selectedImage!, onRemove: () => setState(() => _selectedImage = null)),
            FieldLabel('علامات فارقة'),
            Textfield(hint: 'مثال: خدش، ملصق...', controller: _featController),
            const SizedBox(height: 30),
            _isPublishing ? const Center(child: CircularProgressIndicator()) : FormActionButtons(onPublish: _publishReport, onCancel: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}