import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../utils/constants.dart';

class MapsService {
  Future<Map<String, dynamic>?> getDirections({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final url =
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=driving'
        '&key=${AppConstants.googleMapsApiKey}';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return null;

    final data = json.decode(response.body);
    if (data['status'] != 'OK') return null;

    final route = data['routes'][0];
    final leg = route['legs'][0];

    return {
      'distance_meters': leg['distance']['value'] as int,
      'distance_text': leg['distance']['text'] as String,
      'duration_text': leg['duration']['text'] as String,
      'polyline': route['overview_polyline']['points'] as String,
      'start_address': leg['start_address'] as String,
      'end_address': leg['end_address'] as String,
    };
  }

  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    if (query.trim().isEmpty) return [];

    final url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(query)}'
        '&key=${AppConstants.googleMapsApiKey}';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return [];

    final data = json.decode(response.body);
    if (data['status'] != 'OK') return [];

    return List<Map<String, dynamic>>.from(data['predictions']);
  }

  Future<LatLng?> getPlaceLatLng(String placeId) async {
    final url =
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&fields=geometry'
        '&key=${AppConstants.googleMapsApiKey}';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return null;

    final data = json.decode(response.body);
    if (data['status'] != 'OK') return null;

    final location = data['result']['geometry']['location'];
    return LatLng(location['lat'], location['lng']);
  }
}