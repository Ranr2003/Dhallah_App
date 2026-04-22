// lib/screens/lost_report_page.dart
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

class LostReportPage extends StatefulWidget {
  const LostReportPage({super.key});
  @override
  State<LostReportPage> createState() => _LostReportPageState();
}

class _LostReportPageState extends State<LostReportPage> {
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

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
        _showImageError = false;
      });
    }
  }

  Future<void> _pickLocation() async {
    final PickedLocation? result = await Navigator.push<PickedLocation>(context, MaterialPageRoute(builder: (context) => const MapPickerPage()),);
    if (result != null) {
      setState(() {
        _pickedLocation = result;
        _placeController.text = result.fullAddress;
      });
    }
  }

  void _showNotice({
    required DialogType type,
    required String title,
    required String desc,
    required IconData iconData,
    required Color iconColor,
    VoidCallback? onOk,
  }) {
    AwesomeDialog(
       context: context,
       dialogType: DialogType.noHeader,
       animType: AnimType.scale,
       autoHide: const Duration(seconds: 3),
       dialogBorderRadius: BorderRadius.circular(20),
       btnOk: const SizedBox.shrink(),
       body: Column(
                children: [
                       const SizedBox(height: 15),
                       Icon(iconData,
                           color: iconColor,
                           size: 60
                       ),
                       const SizedBox(height: 10),
                       Text(title,
                         style: const TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18
                         ),
                       ),
                       const SizedBox(height: 8),
                       Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Text(desc,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                            fontFamily: 'Tajawal',
                                            fontSize: 14
                            ),
                          ),
                       ), const SizedBox(height: 25),
                ],
      ),
      onDismissCallback: (typeOfDismiss) {if (type == DialogType.success && onOk != null) onOk();},
    ).show();
  }

  Future<void> _publishReport() async {
    setState(() {
      _showImageError = _selectedImage == null;
    });
    bool isFormValid = _formKey.currentState?.validate() ?? false;
    bool hasLocation = _pickedLocation != null;
    bool hasImage = _selectedImage != null;
    if (!isFormValid || !hasLocation || !hasImage) return;
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
        type: "lost",
        userId: _authService.currentUserId,
        item: item,
        locationName: _placeController.text.trim(),
        coordinates: _pickedLocation!.coordinates,
        createdAt: DateTime.now(),
      );
      await _itemService.submitReport(report, _selectedImage);
      if (!mounted) return;
      _showNotice(
        type: DialogType.success,
        title: 'تم بنجاح',
        desc: 'تم رفع بلاغ المفقودات بنجاح',
        iconData: Icons.check_circle_rounded,
        iconColor: AppColors.primary,
        onOk: () => Navigator.pop(context),
      );
    } catch (e) {
      if (!mounted) return;
      _showNotice(
        type: DialogType.error,
        title: 'فشل النشر',
        desc: 'حدث خطأ: $e',
        iconData: Icons.cancel_outlined,
        iconColor: AppColors.error,
      );
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
                         crossAxisAlignment: CrossAxisAlignment.end,
                         children: [
                           const ReportPageHeader(
                                   icon: Icons.search_rounded,
                                   label: 'ضيعت شيء وتدور عليه؟',
                           ),
                           const SizedBox(height: 20),
                           FieldLabel('نوعه'),
                           Textfield(hint: 'مثال: محفظة، جوال، بطاقة...', controller: _typeController),
                           FieldLabel('الوصف'),
                           Textfield(hint: 'الحجم، حالة الشيء، أي تفاصيل مهمة...', controller: _descController, maxLines: 2),
                           FieldLabel('اللون'),
                           Textfield(hint: 'مثال: أسود، فضي...', controller: _colorController),
                           FieldLabel('المكان'),
                           Textfield(hint: 'أين فُقد؟ حدد الموقع من الخريطة', controller: _placeController, readOnly: true),
                           LocationPickerButton(onTap: _pickLocation),
                           FieldLabel('صورة للغرض'),
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
                          FieldLabel('علامات فارقة'),
                          Textfield(hint: 'مثال: خدش، ملصق، قطعة مكسورة...', controller: _featController),
                          const SizedBox(height: 30),
                          _isPublishing ? const Center(child: CircularProgressIndicator(color: AppColors.primary)) : PublishAndCancelButtons(
                                                                                                                      onPublish: _publishReport,
                                                                                                                      onCancel: () => Navigator.pop(context)),
                         ],
               ),
      ),
    );
  }
}