import 'seed_data.dart';
import 'supabase_service.dart';

Future<Map<String, dynamic>> predictMood({
  required String weatherCondition,
  required String tempRange,
  required String city,
  required List<Map<String, dynamic>> personalHistory,
}) async {
  // Get crowd data; falls back to empty map if < 20 samples or error
  final crowdRaw = await SupabaseService.instance.getCrowdDistribution(
    city, weatherCondition, tempRange,
  );

  final bool usedSeedData = crowdRaw.isEmpty;
  final Map<String, int> crowdData = usedSeedData
      ? getSeedDistribution(weatherCondition)
      : crowdRaw;

  final int crowdCount = usedSeedData
      ? 0
      : crowdData.values.fold(0, (a, b) => a + b);

  // Filter personal history for this weather condition
  final personalEntries = personalHistory
      .where((e) => e['weather'] == weatherCondition)
      .toList();
  final int personalCount = personalEntries.length;

  Map<String, double> blended;
  bool basedOnPersonal = false;

  if (personalCount >= 10) {
    basedOnPersonal = true;
    final personalDist = _countMoods(personalEntries);
    final personalPct = _normalize(personalDist);
    final crowdPct = _normalize(crowdData);

    blended = {};
    for (final mood in crowdPct.keys) {
      blended[mood] = (personalPct[mood] ?? 0) * 0.5 + (crowdPct[mood] ?? 0) * 0.5;
    }
  } else {
    blended = _normalize(crowdData);
  }

  final predictedMood = blended.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  final topShare = blended[predictedMood] ?? 0;

  String confidence;
  if (topShare > 0.5) {
    confidence = 'high';
  } else if (topShare > 0.3) {
    confidence = 'medium';
  } else {
    confidence = 'low';
  }

  return {
    'mood': predictedMood,
    'confidence': confidence,
    'crowdCount': crowdCount,
    'basedOnPersonal': basedOnPersonal,
    'usedSeedData': usedSeedData,
    'distribution': blended,
  };
}

Map<String, int> _countMoods(List<Map<String, dynamic>> entries) {
  final counts = <String, int>{};
  for (final e in entries) {
    final mood = e['mood'] as String;
    counts[mood] = (counts[mood] ?? 0) + 1;
  }
  return counts;
}

Map<String, double> _normalize(Map<String, int> counts) {
  final total = counts.values.fold(0, (a, b) => a + b);
  if (total == 0) return {};
  return counts.map((k, v) => MapEntry(k, v / total));
}
