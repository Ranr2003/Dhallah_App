import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/item_model.dart';
import '../models/report_model.dart';
import '../services/item_serv.dart';
import '../widgets/custom_widgets.dart';
import 'map_picker_page.dart';

class FoundReportPage extends StatefulWidget {
  const FoundReportPage({super.key});
  @override
  State<FoundReportPage> createState() => _FoundReportPageState();
}

class _FoundReportPageState extends State<FoundReportPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _typeController  = TextEditingController();
  final TextEditingController _descController  = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _featController  = TextEditingController();

  XFile? _selectedImage;
  PickedLocation? _pickedLocation;
  bool _isPublishing = false;
  final ItemService _itemService = ItemService();

  Future<void> _publishReport() async {
    if (!_formKey.currentState!.validate() || _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إكمال البيانات وإرفاق صورة'), backgroundColor: Colors.orange),
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

      final report = FoundItemReport(
          description: 'تم العثور على ${_typeController.text}',
          date: DateTime.now(),
          status: 'Active',
          userId: FirebaseAuth.instance.currentUser?.uid ?? '',
          item: item,
          itemFoundLocation: _placeController.text,
          coordinates: _pickedLocation!.coordinates
      );

      await _itemService.uploadFoundReport(report);

      // إغلاق الـ Pop-up
      if (mounted) Navigator.pop(context);

      // إظهار رسالة النجاح
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفع بلاغ المعثورات بنجاح!', style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
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
            const ReportPageHeader(icon: Icons.person_search_outlined, label: 'لقيت شيء وتدور على صاحبه؟'),
            const SizedBox(height: 20),
            FieldLabel('نوعه'),
            Textfield(hint: 'مثال: محفظة، بطاقة...', controller: _typeController),
            FieldLabel('الوصف'),
            Textfield(hint: 'الحجم، الحالة...', controller: _descController, maxLines: 2),
            FieldLabel('اللون'),
            Textfield(hint: 'مثال: فضي...', controller: _colorController),
            FieldLabel('المكان'),
            Textfield(hint: 'حدد الموقع من الخريطة', controller: _placeController, readOnly: true),
            LocationPickerButton(onTap: () async {
              final picked = await Navigator.push<PickedLocation>(context, MaterialPageRoute(builder: (_) => const MapPickerPage()));
              if (picked != null) setState(() { _pickedLocation = picked; _placeController.text = picked.fullAddress; });
            }),
            FieldLabel('صورة للغرض'),
            ImagePickerRow(onPickFromCamera: () async {
              final img = await ImagePicker().pickImage(source: ImageSource.camera);
              if (img != null) setState(() => _selectedImage = img);
            }, onPickFromGallery: () async {
              final img = await ImagePicker().pickImage(source: ImageSource.gallery);
              if (img != null) setState(() => _selectedImage = img);
            }),
            if (_selectedImage != null) SelectedImagePreview(image: _selectedImage!, onRemove: () => setState(() => _selectedImage = null)),
            FieldLabel('علامة فارقة'),
            Textfield(hint: 'مثال: ملصق...', controller: _featController),
            const SizedBox(height: 30),
            _isPublishing ? const Center(child: CircularProgressIndicator()) : FormActionButtons(onPublish: _publishReport, onCancel: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}