import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/location_service.dart';
import '../services/maps_service.dart';
import '../services/fuel_calculator.dart';
import '../services/supabase_service.dart';
import '../models/trip.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/fuel_info_card.dart';
import '../utils/constants.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final LocationService _locationService = LocationService();
  final MapsService _mapsService = MapsService();
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _searchController = TextEditingController();

  GoogleMapController? _mapController;
  Position? _currentPosition;
  LatLng? _destination;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<Map<String, dynamic>> _suggestions = [];

  double _distanceKm = 0;
  double _fuelLiters = 0;
  double _fuelCost = 0;
  String _durationText = '';
  String _originAddress = '';
  String _destinationAddress = '';

  double _fuelEfficiency = AppConstants.defaultFuelEfficiency;
  double _fuelPrice = AppConstants.defaultFuelPrice;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initLocation();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _fuelEfficiency = prefs.getDouble('fuel_efficiency') ?? AppConstants.defaultFuelEfficiency;
        _fuelPrice = prefs.getDouble('fuel_price') ?? AppConstants.defaultFuelPrice;
      });
    }
  }

  Future<void> _initLocation() async {
    final pos = await _locationService.getCurrentPosition();
    if (pos != null) {
      if (!mounted) return;
      setState(() {
        _currentPosition = pos;
        _markers.add(
          Marker(
            markerId: const MarkerId('current'),
            position: LatLng(pos.latitude, pos.longitude),
            infoWindow: const InfoWindow(title: 'You are here'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          ),
        );
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 14),
      );
    }
  }

  Future<void> _onSearchChanged(String query) async {
    if (query.length < 3) {
      if (mounted) {
        setState(() => _suggestions = []);
      }
      return;
    }
    final results = await _mapsService.searchPlaces(query);
    if (mounted) {
      setState(() => _suggestions = results);
    }
  }

  Future<void> _selectSuggestion(Map<String, dynamic> prediction) async {
    final placeId = prediction['place_id'];
    final description = prediction['description'] as String;

    setState(() {
      _searchController.text = description;
      _suggestions = [];
      _isLoading = true;
    });

    final latLng = await _mapsService.getPlaceLatLng(placeId);
    if (!mounted) return;
    
    if (latLng == null || _currentPosition == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _destination = latLng;
      _destinationAddress = description;
    });

    await _calculateRoute();
  }

  Future<void> _calculateRoute() async {
    if (_currentPosition == null || _destination == null) return;

    setState(() => _isLoading = true);

    final origin = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    final result = await _mapsService.getDirections(
      origin: origin,
      destination: _destination!,
    );

    if (!mounted) return;

    if (result == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not calculate route')),
      );
      return;
    }

    final distanceMeters = result['distance_meters'] as int;
    _distanceKm = distanceMeters / 1000.0;
    _durationText = result['duration_text'] as String;
    _originAddress = result['start_address'] as String;
    _destinationAddress = result['end_address'] as String;

    _fuelLiters = FuelCalculator.calculateFuelNeeded(
      distanceKm: _distanceKm,
      fuelEfficiencyKmPerLiter: _fuelEfficiency,
    );
    _fuelCost = FuelCalculator.calculateFuelCost(
      fuelLiters: _fuelLiters,
      pricePerLiter: _fuelPrice,
    );

    // Decode polyline - PolylinePoints.decodePolyline is static
    final points = PolylinePoints.decodePolyline(result['polyline'] as String);
    final polylineCoordinates = points
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('current'),
          position: origin,
          infoWindow: const InfoWindow(title: 'Start'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
        Marker(
          markerId: const MarkerId('destination'),
          position: _destination!,
          infoWindow: InfoWindow(title: _destinationAddress),
        ),
      };
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: polylineCoordinates,
          color: const Color(0xFF1E88E5),
          width: 5,
        ),
      };
      _isLoading = false;
    });

    // Fit bounds
    final bounds = _boundsFromLatLngList([origin, _destination!]);
    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double x0 = list.first.latitude, x1 = list.first.latitude;
    double y0 = list.first.longitude, y1 = list.first.longitude;
    for (final latLng in list) {
      if (latLng.latitude > x1) x1 = latLng.latitude;
      if (latLng.latitude < x0) x0 = latLng.latitude;
      if (latLng.longitude > y1) y1 = latLng.longitude;
      if (latLng.longitude < y0) y0 = latLng.longitude;
    }
    return LatLngBounds(southwest: LatLng(x0, y0), northeast: LatLng(x1, y1));
  }

  Future<void> _saveTrip() async {
    if (_distanceKm == 0) return;

    final trip = Trip(
      origin: _originAddress.isNotEmpty ? _originAddress : 'Current Location',
      destination: _destinationAddress,
      distanceKm: _distanceKm,
      fuelNeededLiters: _fuelLiters,
      fuelCost: _fuelCost,
      fuelEfficiency: _fuelEfficiency,
      fuelPrice: _fuelPrice,
      createdAt: DateTime.now(),
    );

    try {
      await _supabaseService.saveTrip(trip);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving trip: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : const LatLng(16.8661, 96.1951), // Yangon default
              zoom: 14,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // Search bar + suggestions
          SafeArea(
            child: Column(
              children: [
                SearchBarWidget(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  onClear: () {
                    _searchController.clear();
                    setState(() {
                      _suggestions = [];
                      _destination = null;
                      _polylines = {};
                      _distanceKm = 0;
                    });
                  },
                ),
                if (_suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final item = _suggestions[index];
                        return ListTile(
                          leading: const Icon(Icons.location_on, color: Color(0xFF1E88E5)),
                          title: Text(
                            item['description'] ?? '',
                            style: const TextStyle(fontSize: 14),
                          ),
                          onTap: () => _selectSuggestion(item),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Fuel info card
          if (_distanceKm > 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 90,
              child: FuelInfoCard(
                distanceKm: _distanceKm,
                fuelLiters: _fuelLiters,
                fuelCost: _fuelCost,
                durationText: _durationText,
              ),
            ),

          // Floating buttons
          Positioned(
            right: 16,
            bottom: 24,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'my_location',
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _initLocation,
                  child: const Icon(Icons.my_location, color: Color(0xFF1E88E5)),
                ),
                const SizedBox(height: 12),
                if (_distanceKm > 0)
                  FloatingActionButton.extended(
                    heroTag: 'save',
                    backgroundColor: const Color(0xFF1E88E5),
                    onPressed: _saveTrip,
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: const Text('Save Trip', style: TextStyle(color: Colors.white)),
                  ),
              ],
            ),
          ),

          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
