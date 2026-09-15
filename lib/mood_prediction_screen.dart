import 'package:flutter/material.dart';
import 'weather_service.dart';
import 'database_helper.dart';
import 'prediction_engine.dart';
import 'supabase_service.dart';
import 'app_theme.dart';

class MoodPredictionScreen extends StatefulWidget {
  final String? cityName;
  const MoodPredictionScreen({Key? key, this.cityName}) : super(key: key);

  @override
  State<MoodPredictionScreen> createState() => _MoodPredictionScreenState();
}

class _MoodPredictionScreenState extends State<MoodPredictionScreen> {
  List<Map<String, dynamic>>? _predictions;
  String? _city;
  int _totalCrowdCount = 0;
  bool _anyUsedSeedData = false;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPredictions();
  }

  Future<void> _loadPredictions() async {
    try {
      final forecast = await WeatherService().fetch5DayForecast();
      final history = await DatabaseHelper.instance.queryLast90Days();
      final city = widget.cityName ?? await WeatherService().fetchCityName();

      // Group forecast entries by date
      final Map<String, List<Map<String, dynamic>>> byDate = {};
      for (final entry in forecast) {
        final date = (entry['dt_txt'] as String).split(' ')[0];
        byDate.putIfAbsent(date, () => []).add(entry);
      }

      final List<Map<String, dynamic>> predictions = [];
      int totalCrowd = 0;
      bool anySeed = false;

      for (final date in byDate.keys) {
        final entries = byDate[date]!;

        // Dominant weather condition for the day
        final condCount = <String, int>{};
        for (final e in entries) {
          final c = e['weather'][0]['main'] as String;
          condCount[c] = (condCount[c] ?? 0) + 1;
        }
        final condition = condCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;

        // Average temp for the day
        final avgTemp = entries
            .map((e) => (e['main']['temp'] as num).toDouble())
            .reduce((a, b) => a + b) / entries.length;
        final tempRange = SupabaseService.tempRangeBucket(avgTemp);

        // Icon from the middle-of-day entry (or first)
        final iconEntry = entries.firstWhere(
          (e) => (e['dt_txt'] as String).contains('12:00'),
          orElse: () => entries.first,
        );
        final iconCode = iconEntry['weather'][0]['icon'] as String;

        final result = await predictMood(
          weatherCondition: condition,
          tempRange: tempRange,
          city: city,
          personalHistory: history,
        );

        totalCrowd += result['crowdCount'] as int;
        if (result['usedSeedData'] == true) anySeed = true;

        predictions.add({
          'date': date,
          'condition': condition,
          'iconCode': iconCode,
          'avgTemp': avgTemp,
          ...result,
        });
      }

      setState(() {
        _predictions = predictions;
        _city = city;
        _totalCrowdCount = totalCrowd;
        _anyUsedSeedData = anySeed;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Unable to load forecast. Check your connection.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Forecast', style: AppTheme.appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentOrange))
          : _error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_error!, textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: 'Poppins', color: Colors.white54)),
                ))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildSourceLabel(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: _predictions?.length ?? 0,
            itemBuilder: (context, i) => _buildForecastCard(_predictions![i]),
          ),
        ),
      ],
    );
  }

  Widget _buildSourceLabel() {
    final text = _anyUsedSeedData
        ? 'Based on general weather patterns'
        : 'Powered by $_totalCrowdCount people in ${_city ?? 'your area'}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          color: _anyUsedSeedData ? Colors.white38 : AppTheme.accentOrange,
          fontStyle: _anyUsedSeedData ? FontStyle.italic : FontStyle.normal,
        ),
      ),
    );
  }

  Widget _buildForecastCard(Map<String, dynamic> p) {
    final date = DateTime.parse(p['date'] as String);
    final mood = p['mood'] as String;
    final confidence = p['confidence'] as String;
    final crowdCount = p['crowdCount'] as int;
    final usedSeed = p['usedSeedData'] as bool;
    final condition = p['condition'] as String;
    final iconCode = p['iconCode'] as String;

    final dayLabel = _dayLabel(date);
    final dateLabel = '${date.day.toString().padLeft(2, '0')} ${_monthAbbr(date.month)}';

    return Card(
      color: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Date column
            SizedBox(
              width: 52,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dayLabel, style: const TextStyle(
                    fontFamily: 'LuckiestGuy', fontSize: 13, color: AppTheme.accentOrange)),
                  Text(dateLabel, style: const TextStyle(
                    fontFamily: 'Poppins', fontSize: 11, color: Colors.white54)),
                ],
              ),
            ),
            // Weather icon
            Image.network(
              'http://openweathermap.org/img/w/$iconCode.png',
              width: 40, height: 40,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.cloud, color: Colors.white38, size: 36),
            ),
            const SizedBox(width: 8),
            // Mood name
            Expanded(
              child: Text(
                mood,
                style: TextStyle(
                  fontFamily: 'LuckiestGuy',
                  fontSize: 18,
                  color: AppTheme.moodColor(mood),
                ),
              ),
            ),
            // Right column: confidence badge + source
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _confidenceBadge(confidence),
                const SizedBox(height: 4),
                if (!usedSeed && crowdCount > 0)
                  Text('$crowdCount people',
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Colors.white38))
                else
                  Text(condition,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 10,
                      color: Colors.white38, fontStyle: FontStyle.italic)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _confidenceBadge(String confidence) {
    Color color;
    switch (confidence) {
      case 'high':   color = AppTheme.confidenceHigh; break;
      case 'medium': color = AppTheme.confidenceMedium; break;
      default:       color = AppTheme.confidenceLow;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(
        confidence.toUpperCase(),
        style: const TextStyle(fontFamily: 'Poppins', fontSize: 10,
          fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  String _dayLabel(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[d.weekday - 1];
  }

  String _monthAbbr(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mood Forecast'),
        content: const Text(
          '🔮 Predicts how you might feel for the next 5 days based on upcoming weather.\n\n'
          '🌍 Blends crowd data from people in your city with your own mood history.\n\n'
          '📊 Confidence reflects how strongly the pattern holds — high means strong agreement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!',
              style: TextStyle(color: AppTheme.accentOrange, fontFamily: 'LuckiestGuy', fontSize: 18)),
          ),
        ],
      ),
    );
  }
}
