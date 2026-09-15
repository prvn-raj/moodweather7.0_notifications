import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'weather_service.dart';
import 'database_helper.dart';
import 'mood_history_screen.dart';
import 'mood_prediction_screen.dart';
import 'app_theme.dart';
import 'notification_service.dart';
import 'supabase_service.dart';
import 'onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const MyApp());
}

Future<bool> _checkOnboardingSeen() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_seen') ?? false;
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mood Weather',
      theme: AppTheme.themeData,
      home: FutureBuilder<bool>(
        future: _checkOnboardingSeen(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              backgroundColor: AppTheme.background,
              body: Center(
                child: CircularProgressIndicator(color: AppTheme.accentOrange),
              ),
            );
          }
          if (snapshot.data!) return const MyHomePage();
          return OnboardingScreen(
            onComplete: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MyHomePage()),
            ),
          );
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Map<String, dynamic>? _weatherDetails;
  final WeatherService _weatherService = WeatherService();
  final Set<String> _pressedButtons = {};
  bool _showWeatherDetails = false;
  Color? _currentMoodColor;
  Map<String, int> _crowdDistribution = {};
  int _crowdTotal = 0;
  late NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService();
    _notificationService.scheduleMorningNotification();
    _notificationService.scheduleEveningNotification();
    DatabaseHelper.instance.cleanupMoods();
    _fetchWeatherAndCrowd();
  }

  Future<void> _fetchWeatherAndCrowd() async {
    try {
      final details = await _weatherService.fetchWeather();
      setState(() => _weatherDetails = details);

      final temp = double.tryParse(details['temperature'] as String) ?? 20.0;
      final tempRange = SupabaseService.tempRangeBucket(temp);
      final city = details['city'] as String;
      final condition = details['condition'] as String;

      final crowd = await SupabaseService.instance.getCrowdDistribution(city, condition, tempRange);
      final total = crowd.values.fold(0, (a, b) => a + b);
      setState(() {
        _crowdDistribution = crowd;
        _crowdTotal = total;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final city = _weatherDetails?['city'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Weather', style: AppTheme.appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: DecoratedBox(
        position: DecorationPosition.background,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A2E), AppTheme.background],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_weatherDetails != null && _showWeatherDetails)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network(
                                'http://openweathermap.org/img/w/${_weatherDetails!['icon']}.png',
                                width: 50, height: 50,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${_weatherDetails!['condition']} | ${_weatherDetails!['temperature']}°C',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontFamily: 'LuckiestGuy',
                                  color: _currentMoodColor ?? Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_weatherDetails != null)
                        _buildCrowdBanner(city),
                      const SizedBox(height: 16),
                      const Text(
                        'How do you feel today?',
                        style: TextStyle(fontSize: 22, fontFamily: 'LuckiestGuy'),
                      ),
                      const SizedBox(height: 20),
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _moodButton('Happy',   Icons.sentiment_very_satisfied),
                              const SizedBox(width: 10),
                              _moodButton('Excited', Icons.sentiment_very_satisfied_rounded),
                              const SizedBox(width: 10),
                              _moodButton('Sad',     Icons.sentiment_very_dissatisfied),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _moodButton('Relaxed', Icons.sentiment_satisfied_alt_sharp),
                              const SizedBox(width: 10),
                              _moodButton('Angry',   Icons.sentiment_neutral_sharp),
                              const SizedBox(width: 10),
                              _moodButton('Sick',    Icons.sentiment_very_dissatisfied_rounded),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
              if (city != null)
                Positioned(
                  bottom: 10, left: 10,
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.blue, size: 16),
                      const SizedBox(width: 4),
                      Text(city, style: const TextStyle(fontSize: 14, fontFamily: 'LuckiestGuy')),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const MoodHistoryScreen()),
            ),
            heroTag: 'history',
            child: const Icon(Icons.history),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MoodPredictionScreen(
                  cityName: _weatherDetails?['city'] as String?,
                ),
              ),
            ),
            heroTag: 'predict',
            child: const Icon(Icons.lightbulb_outline),
          ),
        ],
      ),
    );
  }

  Widget _buildCrowdBanner(String? city) {
    if (_crowdTotal < 20 || _crowdDistribution.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: AppTheme.defaultCardRadius,
          border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.25)),
        ),
        child: const Text(
          'Not enough local data yet — be the first!',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white38),
        ),
      );
    }

    final topMood = _crowdDistribution.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    final condition = _weatherDetails?['condition'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: AppTheme.defaultCardRadius,
        border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(AppTheme.moodIcon(topMood), color: AppTheme.moodColor(topMood), size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '$_crowdTotal people in ${city ?? 'your area'} feel $topMood in $condition weather',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _moodButton(String mood, IconData icon) {
    final moodColor = AppTheme.moodColor(mood);
    final isPressed = _pressedButtons.contains(mood);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressedButtons.add(mood)),
      onTapCancel: () => setState(() => _pressedButtons.remove(mood)),
      onTapUp: (_) async {
        setState(() {
          _pressedButtons.remove(mood);
          _currentMoodColor = moodColor;
          _showWeatherDetails = true;
        });

        final weatherDetails = await _weatherService.fetchWeather();
        setState(() => _weatherDetails = weatherDetails);

        await DatabaseHelper.instance.insert({
          DatabaseHelper.columnMood:    mood,
          DatabaseHelper.columnWeather: weatherDetails['condition'],
          DatabaseHelper.columnDate:    DateTime.now().toIso8601String(),
        });

        int count = await DatabaseHelper.instance.getMoodCountForDay(DateTime.now());
        while (count > 5) {
          await DatabaseHelper.instance.deleteOldestMoodForDay(DateTime.now());
          count = await DatabaseHelper.instance.getMoodCountForDay(DateTime.now());
        }

        // Fire-and-forget anonymous crowd upload
        final temp = double.tryParse(weatherDetails['temperature'] as String) ?? 20.0;
        SupabaseService.instance.submitMood(
          mood,
          weatherDetails['condition'] as String,
          SupabaseService.tempRangeBucket(temp),
          weatherDetails['city'] as String,
          weatherDetails['country'] as String,
        );
      },
      child: Transform.scale(
        scale: isPressed ? 0.9 : 1.0,
        child: Card(
          elevation: 5.0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          child: Container(
            width: 90,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.0),
              color: isPressed ? Colors.grey[300] : moodColor,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentOrange.withValues(alpha: 0.2),
                  spreadRadius: 3, blurRadius: 5, offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(icon, color: Colors.black, size: 30),
                const SizedBox(height: 5),
                Text(mood, style: const TextStyle(color: Colors.black, fontFamily: 'LuckiestGuy')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mood Weather 🌦️'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ever wondered how the weather affects your mood? Mood Weather is here to help you discover the connection!'),
              SizedBox(height: 10),
              Text('🌞 Record your daily mood and see how it aligns with the weather outside.'),
              SizedBox(height: 10),
              Text('📜 Dive into your history to see your patterns on the calendar.'),
              SizedBox(height: 10),
              Text('💡 Check 5-day mood forecasts powered by people in your area.'),
              SizedBox(height: 10),
              Text('🔒 Your mood is shared anonymously — only weather + city. No account needed.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Got it!',
              style: TextStyle(color: AppTheme.accentOrange, fontFamily: 'LuckiestGuy', fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}
