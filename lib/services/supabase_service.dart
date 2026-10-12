import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trip.dart';
import '../utils/constants.dart';

class SupabaseService {
  // Use a getter to avoid accessing the instance before initialization
  SupabaseClient get _client => Supabase.instance.client;

  static Future<void> init() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }

  Future<void> saveTrip(Trip trip) async {
    await _client.from('trips').insert(trip.toJson());
  }

  Future<List<Trip>> getTripHistory() async {
    try {
      final response = await _client
          .from('trips')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => Trip.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> deleteTrip(String id) async {
    await _client.from('trips').delete().eq('id', id);
  }
}
