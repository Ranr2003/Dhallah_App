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

  String get fullAddress {
    if (extraDetails.isNotEmpty) {
      return '$autoAddress — $extraDetails';
    }
    return autoAddress;
  }
}

class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key});
  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  LatLng _selectedLocation = const LatLng(24.7136, 46.6753);
  String _autoAddress = 'حرّك الخريطة لتحديد الموقع';
  String? _countryCode;
  bool _isLoadingAddress = false;
  final TextEditingController _extraDetailsController = TextEditingController();
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _goToCurrentLocation();
  }

  @override
  void dispose() {
    _extraDetailsController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    if (_isLoadingAddress) return;
    if (!(_countryCode == 'sa') ) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Directionality(
                textDirection: TextDirection.rtl,
                 child: Text('عذراً، يجب اختيار موقع داخل المملكة العربية السعودية 🇸🇦',
                         style: TextStyle(
                            fontFamily: 'Tajawal'
                         ),
                 ),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.pop(context,
                 PickedLocation(
                    coordinates: _selectedLocation,
                    autoAddress: _autoAddress,
                    extraDetails: _extraDetailsController.text.trim(),
                 ),
    );
  }

  Future<void> _goToCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _fetchAddress(_selectedLocation);
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _fetchAddress(_selectedLocation);
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      LatLng currentLocation = LatLng(position.latitude, position.longitude);
      _mapController.move(currentLocation, 15.0);
      setState(() {
        _selectedLocation = currentLocation;
      });

      _fetchAddress(currentLocation);
    } catch (e) {
      _fetchAddress(_selectedLocation);
    }
  }


  Future<void> _fetchAddress(LatLng location) async {
    setState(() {
      _isLoadingAddress = true;
      _countryCode = null;
    });

    try {
      // بناء رابط الـ API
      Uri url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
            '?lat=${location.latitude}'
            '&lon=${location.longitude}'
            '&format=json'
            '&accept-language=ar',
      );
      http.Response response = await http.get(
        url,
        headers: {'User-Agent': 'DhallahApp/1.0'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);

        // لو الـ API رجّع خطأ (مثلاً موقع في البحر)
        if (data['error'] != null) {
          setState(() {
            _autoAddress = 'موقع خارج النطاق';
            _countryCode = 'unknown';
          });
          return;
        }

        Map<String, dynamic> address = data['address'];

        setState(() {
          _countryCode = address['country_code']?.toString().toLowerCase();
          List<String> parts = [];
          if (address['road'] != null)          parts.add(address['road']);
          if (address['neighbourhood'] != null) parts.add(address['neighbourhood']);
          if (address['suburb'] != null)        parts.add(address['suburb']);

          String? city = address['city'] ?? address['town'] ?? address['village'];
          if (city != null) parts.add(city);

          if (parts.isNotEmpty) {
            _autoAddress = parts.take(3).join('، ');
          } else {

            _autoAddress =
                data['display_name']?.split(',').take(2).join('،') ?? 'موقع غير محدد';
            }
        });
      } else {
        setState(() => _autoAddress = 'تعذّر تحديد العنوان');
      }
    } catch (e) {
      setState(() => _autoAddress = 'تأكد من اتصالك بالإنترنت');
    } finally {
      if (mounted) {
        setState(() => _isLoadingAddress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
             appBar: AppBar(
                     title: Text('تحديد الموقع على الخريطة'),
                     foregroundColor: Colors.white,
                     centerTitle: true,
                     automaticallyImplyLeading: false,
                     flexibleSpace: Container(
                           decoration: BoxDecoration(
                                 gradient: kPrimaryGradient,
                           ),
                     ),
                     actions: [
                                IconButton(
                                      icon: Icon(Icons.arrow_forward_ios_rounded),
                                      color: Colors.white,
                                      onPressed: () => Navigator.of(context).pop(),
                                ),
                     ],
             ),
             body: Column(
                          children: [
                                   Expanded(
                                      child: Stack(
                                              children: [
                                                         _buildMap(),
                                                          const _CenterPin(),
                                              ],
                                      ),
                                   ),
                                   _buildBottomCard(),
                          ],
             ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
             mapController: _mapController,
             options: MapOptions(
                          initialCenter: _selectedLocation,
                          initialZoom: 15.0,
                          minZoom: 5.0,
                          maxZoom: 18.0,
                          onPositionChanged: (position, hasGesture) {
                                 if (hasGesture) {
                                   _selectedLocation = position.center;
                                 }
                          },
                          onMapEvent: (event) {
                               if (event is MapEventMoveEnd) {
                                      _fetchAddress(_selectedLocation);
                               }
                          },
             ),
             children: [
                   TileLayer(
                       urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                       userAgentPackageName: 'com.dhallah.app',
                   ),
             ],
    );
  }

  Widget _buildBottomCard() {
    return Container(
             padding: EdgeInsets.all(20),
             decoration: BoxDecoration(
                    color: AppColors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10
                      )
                    ],
                    borderRadius: BorderRadius.vertical(
                           top: Radius.circular(AppDimens.radiusSheet),
                    ),
             ),
             child: Column(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                                   Row(
                                      textDirection: TextDirection.rtl,
                                      children: [
                                           Icon(Icons.location_on,
                                               color: AppColors.primary,
                                               size: 24
                                           ), SizedBox(width: AppDimens.spaceSm),
                                           Expanded(
                                               child: _isLoadingAddress ?  LinearProgressIndicator(
                                                                                 color: AppColors.primary,
                                                                                 backgroundColor: AppColors.secondary,
                                                                                 minHeight: 2,
                                                                          ) : Text(
                                                                               _autoAddress,
                                                                               style: TextStyle(
                                                                                        fontWeight: FontWeight.bold,
                                                                                        fontSize: 14,
                                                                                        color: AppColors.textPrimary,
                                                                               ),
                                                                               textAlign: TextAlign.right,
                                                                               maxLines: 2,
                                                                               overflow: TextOverflow.ellipsis,
                                                                          ),
                                           ),
                                      ],
                                   ), SizedBox(height: AppDimens.spaceMd),
                                   Directionality(
                                      textDirection: TextDirection.rtl,
                                      child: TextField(
                                          controller: _extraDetailsController,
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: AppColors.textPrimary
                                          ),
                                          decoration: InputDecoration(
                                                           hintText: 'تفاصيل إضافية (مثال: الجامعة، مبنى C الدور الثاني...)',
                                                           hintStyle: TextStyle(
                                                               fontSize: 13,
                                                               color: AppColors.textHint
                                                           ),
                                                           filled: true,
                                                           fillColor: AppColors.fieldBg,
                                                           contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12,
                                                            ),
                                                           border: OutlineInputBorder(
                                                                   borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                                                                   borderSide: BorderSide.none,
                                                           ),
                                          ),
                                     ),
                                   ), SizedBox(height: AppDimens.spaceMd),
                                  WaterRippleButton(
                           text: 'تأكيد هذا الموقع',
                           onTap: _onConfirm,
                         ),

                       ],
             ),
    );
  }
}

class _CenterPin extends StatelessWidget {
  const _CenterPin();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
             child: Center(
                      child: Padding(
                          padding: const EdgeInsets.only(bottom: 35),
                          child: Icon(Icons.location_pin,
                                 color: AppColors.mapPin,
                                 size: 45,
                          ),
                      ),
             ),
    );
  }
}