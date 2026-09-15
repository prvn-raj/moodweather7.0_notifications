import 'package:supabase_flutter/supabase_flutter.dart';
import 'device_id_service.dart';

class SupabaseService {
  // TODO: Replace with your Supabase project URL and anon key
  static const _supabaseUrl = 'YOUR_SUPABASE_URL';
  static const _supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  SupabaseService._privateConstructor();
  static final SupabaseService instance = SupabaseService._privateConstructor();

  static Future<void> initialize() async {
    await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  }

  SupabaseClient get _client => Supabase.instance.client;

  static String tempRangeBucket(double celsius) {
    if (celsius < 10) return 'below10';
    if (celsius < 20) return '10-20';
    if (celsius < 30) return '20-30';
    return 'above30';
  }

  Future<void> submitMood(
    String mood,
    String weatherCondition,
    String tempRange,
    String city,
    String country,
  ) async {
    try {
      final hashedId = await DeviceIdService.instance.getHashedDeviceId();
      final today = DateTime.now().toIso8601String().split('T')[0];

      // Rate limit: max 5 submissions per device per day
      final existing = await _client
          .from('crowd_moods')
          .select('id')
          .eq('device_id', hashedId)
          .gte('created_at', '${today}T00:00:00Z')
          .lte('created_at', '${today}T23:59:59Z');

      if ((existing as List).length >= 5) return;

      await _client.from('crowd_moods').insert({
        'device_id': hashedId,
        'mood': mood,
        'weather_condition': weatherCondition,
        'temp_range': tempRange,
        'city': city.trim().toLowerCase(),
        'country': country,
      });
    } catch (_) {
      // Network failures must never break the local mood-logging flow
    }
  }

  Future<Map<String, int>> getCrowdDistribution(
    String city,
    String weatherCondition,
    String tempRange,
  ) async {
    try {
      final result = await _client
          .from('mood_aggregates')
          .select()
          .eq('city', city.trim().toLowerCase())
          .eq('weather_condition', weatherCondition)
          .eq('temp_range', tempRange)
          .maybeSingle();

      if (result == null) return {};
      final total = (result['total_count'] as int? ?? 0);
      if (total < 20) return {};

      return {
        'Happy':   result['happy_count']   as int? ?? 0,
        'Excited': result['excited_count'] as int? ?? 0,
        'Sad':     result['sad_count']     as int? ?? 0,
        'Relaxed': result['relaxed_count'] as int? ?? 0,
        'Angry':   result['angry_count']   as int? ?? 0,
        'Sick':    result['sick_count']    as int? ?? 0,
      };
    } catch (_) {
      return {};
    }
  }
}
