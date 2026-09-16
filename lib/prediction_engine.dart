import 'dart:math' as math;
import 'seed_data.dart';
import 'supabase_service.dart';

const List<String> _moods = ['Happy', 'Excited', 'Sad', 'Relaxed', 'Angry', 'Sick'];

// Seed distributions act as a weak Bayesian prior: they always contribute this
// many "pseudo-observations" per mood bucket, regardless of how much real crowd
// data exists. This replaces a hard on/off switch at 20 crowd samples with a
// smooth transition -- a bucket with 25 real samples is barely more confident
// than pure seed data, while one with 500 is dominated by real evidence.
const double _priorStrength = 12.0;

// A user's own history is a stronger signal about how THEY feel than an
// anonymous stranger's submission, so it's weighted up relative to crowd counts.
const double _personalWeightMultiplier = 2.5;

// One-sided z-score for the Wilson score interval (~85% confidence level).
const double _wilsonZ = 1.44;

Future<Map<String, dynamic>> predictMood({
  required String weatherCondition,
  required String tempRange,
  required String city,
  required List<Map<String, dynamic>> personalHistory,
}) async {
  // getCrowdDistribution() itself withholds data below 20 samples (privacy:
  // avoids near-identifiable small clusters), returning {} in that case.
  final crowdData = await SupabaseService.instance.getCrowdDistribution(
    city, weatherCondition, tempRange,
  );
  final int crowdCount = crowdData.values.fold(0, (a, b) => a + b);
  final bool usedSeedData = crowdCount == 0;

  final seedDist = getSeedDistribution(weatherCondition);
  final double seedTotal = seedDist.values.fold(0, (a, b) => a + b).toDouble();

  final personalEntries = personalHistory
      .where((e) => e['weather'] == weatherCondition)
      .toList();
  final int personalCount = personalEntries.length;
  final personalDist = _countMoods(personalEntries);
  final bool basedOnPersonal = personalCount >= 5;

  // Combine the prior (seed, scaled to a fixed pseudo-count), crowd evidence,
  // and personal evidence (weighted up) into one set of effective counts.
  final Map<String, double> effectiveCounts = {};
  for (final mood in _moods) {
    final priorShare = seedTotal > 0 ? (seedDist[mood] ?? 0) / seedTotal : 1 / _moods.length;
    effectiveCounts[mood] = priorShare * _priorStrength +
        (crowdData[mood] ?? 0).toDouble() +
        (personalDist[mood] ?? 0) * _personalWeightMultiplier;
  }

  final double effectiveTotal = effectiveCounts.values.fold(0.0, (a, b) => a + b);
  final Map<String, double> blended =
      effectiveCounts.map((mood, count) => MapEntry(mood, count / effectiveTotal));

  final predictedMood = blended.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  final topShare = blended[predictedMood] ?? 0;

  // Wilson score lower bound: a statistically grounded confidence measure that
  // accounts for sample size, not just raw share -- "60% of 5 observations" is
  // correctly treated as far less confident than "60% of 200 observations".
  final double n = effectiveTotal;
  final double wilsonLowerBound = n > 0
      ? (topShare + _wilsonZ * _wilsonZ / (2 * n) -
              _wilsonZ *
                  math.sqrt((topShare * (1 - topShare) + _wilsonZ * _wilsonZ / (4 * n)) / n)) /
          (1 + _wilsonZ * _wilsonZ / n)
      : 0;

  String confidence;
  if (wilsonLowerBound > 0.40) {
    confidence = 'high';
  } else if (wilsonLowerBound > 0.25) {
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
