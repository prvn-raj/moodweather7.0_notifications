const Map<String, Map<String, int>> seedMoodDistributions = {
  'Clear':        {'Happy': 40, 'Excited': 20, 'Relaxed': 30, 'Sad': 5,  'Angry': 3,  'Sick': 2},
  'Clouds':       {'Happy': 25, 'Excited': 10, 'Relaxed': 35, 'Sad': 15, 'Angry': 8,  'Sick': 7},
  'Rain':         {'Happy': 10, 'Excited': 5,  'Relaxed': 25, 'Sad': 35, 'Angry': 15, 'Sick': 10},
  'Drizzle':      {'Happy': 15, 'Excited': 5,  'Relaxed': 30, 'Sad': 30, 'Angry': 10, 'Sick': 10},
  'Thunderstorm': {'Happy': 8,  'Excited': 12, 'Relaxed': 15, 'Sad': 30, 'Angry': 25, 'Sick': 10},
  'Snow':         {'Happy': 20, 'Excited': 25, 'Relaxed': 20, 'Sad': 20, 'Angry': 5,  'Sick': 10},
  'Mist':         {'Happy': 15, 'Excited': 5,  'Relaxed': 30, 'Sad': 25, 'Angry': 10, 'Sick': 15},
  'Fog':          {'Happy': 12, 'Excited': 5,  'Relaxed': 28, 'Sad': 28, 'Angry': 12, 'Sick': 15},
  'Haze':         {'Happy': 15, 'Excited': 8,  'Relaxed': 27, 'Sad': 25, 'Angry': 10, 'Sick': 15},
  'Smoke':        {'Happy': 8,  'Excited': 5,  'Relaxed': 20, 'Sad': 30, 'Angry': 15, 'Sick': 22},
};

const Map<String, int> defaultSeedDistribution = {
  'Happy': 25, 'Excited': 15, 'Relaxed': 25, 'Sad': 15, 'Angry': 10, 'Sick': 10,
};

Map<String, int> getSeedDistribution(String weatherCondition) {
  return seedMoodDistributions[weatherCondition] ?? defaultSeedDistribution;
}
