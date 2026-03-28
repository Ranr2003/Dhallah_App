// lib/screens/map_picker_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../utils/app_theme.dart';


// ════════════════════════════════════════════════════════
// Data Model: PickedLocation
// Holds the result returned to the previous screen after
// the user confirms a location on the map.
// ════════════════════════════════════════════════════════
class PickedLocation {

  final LatLng coordinates;
  final String autoAddress;
  final String extraDetails;

  const PickedLocation({
    required this.coordinates,
    required this.autoAddress,
    required this.extraDetails,
  });

  // Combines autoAddress and extraDetails into one readable string.
  // Returns only autoAddress if extraDetails is empty.
  String get fullAddress {
    if (extraDetails.isNotEmpty) {
      return '$autoAddress — $extraDetails';
    }
    return autoAddress;
  }
}


// ════════════════════════════════════════════════════════
// MapPickerPage — StatefulWidget entry point.
// Delegates all logic and UI to _MapPickerPageState.
// ════════════════════════════════════════════════════════
class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}


class _MapPickerPageState extends State<MapPickerPage> {

  // Default location: Riyadh, Saudi Arabia
  LatLng _selectedLocation = const LatLng(24.7136, 46.6753);

  String  _autoAddress     = 'حرّك الخريطة لتحديد الموقع';
  String? _countryCode;
  bool    _isLoadingAddress = false;

  final TextEditingController _extraDetailsController = TextEditingController();
  final MapController _mapController = MapController();


  // Runs once when the page opens.
  // Immediately attempts to move the map to the user's current location.
  @override
  void initState() {
    super.initState();
    _goToCurrentLocation();
  }


  // Cleans up controllers when the page is removed from the widget tree.
  @override
  void dispose() {
    _extraDetailsController.dispose();
    super.dispose();
  }


  // Returns true only if the selected location is inside Saudi Arabia.
  // Used to block confirmation for out-of-kingdom locations.
  bool _isInsideSaudiArabia() {
    return _countryCode == 'sa';
  }


  // Validates the selected location and returns a [PickedLocation] to the
  // previous screen. Shows a SnackBar if the location is outside Saudi Arabia
  // or if the address is still loading.
  void _onConfirm() {
    if (_isLoadingAddress) return;

    if (!_isInsideSaudiArabia()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('عذراً، يجب اختيار موقع داخل المملكة العربية السعودية 🇸🇦'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      PickedLocation(
        coordinates:  _selectedLocation,
        autoAddress:  _autoAddress,
        extraDetails: _extraDetailsController.text.trim(),
      ),
    );
  }


  // Requests location permission, then moves the map to the device's
  // current GPS position. Falls back to the default Riyadh location
  // if the service is disabled or permission is denied.
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
      setState(() => _selectedLocation = currentLocation);
      _fetchAddress(currentLocation);

    } catch (e) {
      _fetchAddress(_selectedLocation);
    }
  }


  // Performs reverse geocoding using the Nominatim OpenStreetMap API.
  // Converts [location] coordinates into a human-readable Arabic address
  // and updates [_autoAddress] and [_countryCode].
  // Called every time the map stops moving.
  Future<void> _fetchAddress(LatLng location) async {

    setState(() {
      _isLoadingAddress = true;
      _countryCode      = null;
    });

    try {

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
          if (address['road']          != null) parts.add(address['road']);
          if (address['neighbourhood'] != null) parts.add(address['neighbourhood']);
          if (address['suburb']        != null) parts.add(address['suburb']);

          String? city = address['city'] ?? address['town'] ?? address['village'];
          if (city != null) parts.add(city);

          if (parts.isNotEmpty) {
            _autoAddress = parts.take(3).join('، ');
          } else {
            _autoAddress = data['display_name']?.split(',').take(2).join('،') ?? 'موقع غير محدد';
          }
        });

      } else {
        setState(() => _autoAddress = 'تعذّر تحديد العنوان');
      }

    } catch (e) {
      setState(() => _autoAddress = 'تأكد من اتصالك بالإنترنت');

    } finally {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }


  // Builds the main screen layout:
  // a full-screen map with a center pin overlay, and a bottom card.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تحديد الموقع على الخريطة'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
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

  // Builds the interactive FlutterMap widget.
  // Updates [_selectedLocation] while dragging and fetches a new address
  // once the map comes to a stop (MapEventMoveEnd).
  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _selectedLocation,
        initialZoom:   15.0,
        minZoom:       5.0,
        maxZoom:       18.0,
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
          urlTemplate:         'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.dhallah.app',
        ),
      ],
    );
  }

  // Builds the bottom card containing:
  // the resolved address, an optional details text field, and the confirm button.
  // Shows a LinearProgressIndicator while the address is loading.
  Widget _buildBottomCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusSheet),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.primary, size: 24),
              const SizedBox(width: AppDimens.spaceSm),
              Expanded(
                child: _isLoadingAddress
                    ? const LinearProgressIndicator(
                  color:           AppColors.primary,
                  backgroundColor: AppColors.secondary,
                  minHeight:       2,
                )
                    : Text(
                  _autoAddress,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize:   14,
                    color:      AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.right,
                  maxLines:  2,
                  overflow:  TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spaceMd),

          Directionality(
            textDirection: TextDirection.rtl,
            child: TextField(
              controller: _extraDetailsController,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText:  'تفاصيل إضافية (مثال: الجامعة، مبنى C الدور الثاني...)',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint),
                filled:    true,
                fillColor: AppColors.fieldBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                  borderSide:   BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimens.spaceMd),

          SizedBox(
            width:  double.infinity,
            height: AppDimens.buttonHeight,
            child: ElevatedButton(
              onPressed: _onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                ),
              ),
              child: const Text(
                'تأكيد هذا الموقع',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

        ],
      ),
    );
  }
}


// ════════════════════════════════════════════════════════
// A stateless pin icon fixed at the center of the screen.
// Wrapped in IgnorePointer so it doesn't block map gestures.
// ════════════════════════════════════════════════════════
class _CenterPin extends StatelessWidget {
  const _CenterPin();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 35),
          child: Icon(Icons.location_pin, color: AppColors.mapPin, size: 45),
        ),
      ),
    );
  }
}