// lib/screens/map_picker_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../utils/app_theme.dart';
import '../widgets/custom_widgets.dart';

class PickedLocation {
  final LatLng coordinates;
  final String autoAddress;
  final String extraDetails;

  const PickedLocation({
    required this.coordinates,
    required this.autoAddress,
    required this.extraDetails,
  });

  String get fullAddress => extraDetails.isNotEmpty ? '$autoAddress — $extraDetails' : autoAddress;
}

class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key});
  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  LatLng _selectedCoordinates = const LatLng(24.7136, 46.6753);
  String _readableAddress = 'حرّك الخريطة لتحديد الموقع';
  String? _detectedCountryCode;
  bool _isFetchingAddress = false;
  final TextEditingController _additionalDetailsController = TextEditingController();
  final MapController _flutterMapController = MapController();

  @override
  void initState() {
    super.initState();
    _determineInitialUserLocation();
  }

  @override
  void dispose() {
    _additionalDetailsController.dispose();
    _flutterMapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('تحديد الموقع'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: kPrimaryGradient)),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                FlutterMap(
                  mapController: _flutterMapController,
                  options: MapOptions(
                    initialCenter: _selectedCoordinates,
                    initialZoom: 15.0,
                    onPositionChanged: (cameraPosition, hasGesture) {
                      if (hasGesture) {
                        _selectedCoordinates = cameraPosition.center;
                      }
                    },
                    onMapEvent: (mapEvent) {
                      if (mapEvent is MapEventMoveEnd) {
                        _convertCoordinatesToAddress(_selectedCoordinates);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.dhallah.app',
                    ),
                  ],
                ),
                const IgnorePointer(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 35),
                    child: Icon(Icons.location_pin, color: AppColors.mapPin, size: 48),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -5))],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _isFetchingAddress
                          ? const LinearProgressIndicator(minHeight: 2, color: AppColors.primary)
                          : Text(
                        _readableAddress,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary, fontFamily: 'Tajawal'),
                        textAlign: TextAlign.right,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: TextField(
                    controller: _additionalDetailsController,
                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'تفاصيل إضافية (المبنى، الدور، علامة مميزة...)',
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint),
                      prefixIcon: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                      filled: true,
                      fillColor: AppColors.fieldBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                WaterRippleButton(
                  text: 'تأكيد الموقع الحالي',
                  onTap: _validateAndReturnLocation,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _determineInitialUserLocation() async {
    bool enabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();

    if (enabled && perm != LocationPermission.deniedForever) {
      try {
        Position pos = await Geolocator.getCurrentPosition();
        LatLng latLng = LatLng(pos.latitude, pos.longitude);
        _flutterMapController.move(latLng, 15.0);
        setState(() => _selectedCoordinates = latLng);
        _convertCoordinatesToAddress(latLng);
      } catch (_) {
        _convertCoordinatesToAddress(_selectedCoordinates);
      }
    }
  }

  Future<void> _convertCoordinatesToAddress(LatLng location) async {
    if (!mounted) return;
    setState(() => _isFetchingAddress = true);

    try {
      final res = await http.get(
          Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=${location.latitude}&lon=${location.longitude}&format=json&accept-language=ar'),
          headers: {'User-Agent': 'DhallahApp/1.0'}
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final addr = data['address'] as Map<String, dynamic>?;

        setState(() {
          _detectedCountryCode = addr?['country_code']?.toString().toLowerCase();
          final List<String> parts = [
            if (addr?['road'] != null) addr!['road'],
            if (addr?['neighbourhood'] != null) addr!['neighbourhood'],
            if (addr?['city'] != null || addr?['town'] != null) (addr?['city'] ?? addr?['town']),
          ];

          _readableAddress = parts.isNotEmpty ? parts.take(2).join('، ') : 'موقع غير محدد';
        });
      }
    } catch (e) {
      setState(() => _readableAddress = 'تأكد من اتصالك بالإنترنت');
    } finally {
      if (mounted) setState(() => _isFetchingAddress = false);
    }
  }

  void _validateAndReturnLocation() {
    if (_isFetchingAddress) return;
    if (_detectedCountryCode != 'sa') {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('يجب اختيار موقع داخل السعودية 🇸🇦', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Tajawal')),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating
          )
      );
      return;
    }
    Navigator.pop(
      context,
      PickedLocation(
          coordinates: _selectedCoordinates,
          autoAddress: _readableAddress,
          extraDetails: _additionalDetailsController.text.trim()
      ),
    );
  }
}