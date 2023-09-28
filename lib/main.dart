import 'package:flutter/material.dart';
import 'weather_service.dart';
import 'database_helper.dart';
import 'mood_history_screen.dart';
import 'mood_prediction_screen.dart'; // Ensure this import is correct
import 'app_theme.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mood Weather',
      theme: AppTheme.themeData,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Map<String, dynamic>? _weatherDetails;
  String? _cityName;
  final WeatherService _weatherService = WeatherService();
  Set<String> _pressedButtons = {}; // To track which buttons are pressed
  bool _showWeatherDetails = false; // To control the visibility of the weather details
  Color? _currentMoodColor;




  @override
  void initState() {
    super.initState();
    DatabaseHelper.instance.cleanupMoods(); // Temporary cleanup
    _fetchWeatherDetails();
    _fetchCityName();
  }

  _fetchWeatherDetails() async {
    Map<String, dynamic> details = await _weatherService.fetchWeather();
    setState(() {
      _weatherDetails = details;
    });
  }

  _fetchCityName() async {
    String city = await _weatherService.fetchCityName();
    setState(() {
      _cityName = city;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mood Weather',
          style: TextStyle(color: Colors.orangeAccent, fontFamily: 'LuckiestGuy', fontSize: 24),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Mood Weather 🌦️'),
                    content: SingleChildScrollView( // Using SingleChildScrollView in case the content overflows
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          Text('Ever wondered how the weather affects your mood? Mood Weather is here to help you discover the connection!'),
                      SizedBox(height: 10),
                      Text('🌞 Record your daily mood and see how it aligns with the weather outside.'),
                            SizedBox(height: 10),
                            Text('📜 Dive into your history to reminisce about your past moods.'),
                            SizedBox(height: 10),
                      Text('💡 Check out our predictions to see how you might feel based on upcoming weather conditions.'),
                      SizedBox(height: 10),
                      Text('✨ Ever tried to control the weather with your mood? Give it a shot! If you are cheerful enough, maybe you can make it rain sunshine! 🌧️☀️ Just kidding... or are we? 😉'),

                      ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        child: Text( style: TextStyle(color: Colors.orangeAccent, fontFamily: 'LuckiestGuy', fontSize: 18),'Got it!'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),


      body: DecoratedBox(
        position: DecorationPosition.background,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFE0), Color(0x16777215)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (_showWeatherDetails && _weatherDetails != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 70.0),
                        // Adjust this value to your preference
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.network(
                              'http://openweathermap.org/img/w/${_weatherDetails!['icon']}.png',
                              width: 50,
                              height: 50,
                            ),
                            SizedBox(width: 10),
                            Text(
                              '${_weatherDetails!['condition']} | ${_weatherDetails!['temperature']}°C',
                              style: TextStyle(fontSize: 35,
                                  fontFamily: 'LuckiestGuy',
                                  color: _currentMoodColor ?? Colors.black),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 20),
                    Text(
                      'How do you feel today?',
                      style: TextStyle(fontSize: 24, fontFamily: 'LuckiestGuy'),
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _moodButton('Happy',
                                Icons.sentiment_very_satisfied),
                            SizedBox(width: 10),
                            _moodButton('Excited',
                                Icons.sentiment_very_satisfied_rounded),
                            SizedBox(width: 10),
                            _moodButton('Sad',
                                Icons.sentiment_very_dissatisfied),
                          ],
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _moodButton('Relaxed',
                                Icons.sentiment_satisfied_alt_sharp),
                            SizedBox(width: 10),
                            _moodButton('Angry', Icons.sentiment_neutral_sharp),
                            SizedBox(width: 10),
                            _moodButton('Sick',
                                Icons.sentiment_very_dissatisfied_rounded),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 10,
                left: 10,
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.blue),
                    SizedBox(width: 5),
                    Text(
                      _cityName ?? 'Fetching location...',
                      style: TextStyle(fontSize: 16, fontFamily: 'LuckiestGuy'),
                    ),
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MoodHistoryScreen()), // Ensure this line is correct
              );
            },
            child: Icon(Icons.history),
            heroTag: null,
          ),
          SizedBox(height: 20),
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MoodPredictionScreen()),
              );
            },
            child: Icon(Icons.lightbulb_outline),
            heroTag: null,
          ),
        ],
      ),
    );
  }

  Widget _moodButton(String mood, IconData icon) {
    Color? moodColor;
    switch (mood) {
      case 'Happy':
        moodColor = Colors.green[200];
        break;
      case 'Relaxed':
        moodColor = Colors.blue[200];
        break;
      case 'Sad':
        moodColor = Colors.grey[400];
        break;
      case 'Excited':
        moodColor = Colors.orange[200];
        break;
      case 'Angry':
        moodColor = Colors.red[200];
        break;
      case 'Sick':
        moodColor = Colors.purple[200];
        break;
    }

    return GestureDetector(
      onTapDown: (details) {
        setState(() {
          _pressedButtons.add(mood);
        });
      },
      onTapUp: (details) async {
        setState(() {
          _pressedButtons.remove(mood);
          _currentMoodColor = moodColor;
          _showWeatherDetails = true;
        });
        Map<String, dynamic> weatherDetails = await _weatherService
            .fetchWeather();
        setState(() {
          _weatherDetails = weatherDetails;
        });
        await DatabaseHelper.instance.insert({
          DatabaseHelper.columnMood: mood,
          DatabaseHelper.columnWeather: weatherDetails['condition'],
          DatabaseHelper.columnDate: DateTime.now().toIso8601String(),
        });
        int moodCount = await DatabaseHelper.instance.getMoodCountForDay(
            DateTime.now());
        while (moodCount > 5) {
          await DatabaseHelper.instance.deleteOldestMoodForDay(DateTime.now());
          moodCount =
          await DatabaseHelper.instance.getMoodCountForDay(DateTime.now());
        }
      },
      onTapCancel: () {
        setState(() {
          _pressedButtons.remove(mood);
        });
      },
      child: Transform.scale(
        scale: _pressedButtons.contains(mood) ? 0.9 : 1.0,
        child: Card(
          elevation: 5.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Container(
            width: 90,
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.0),
              color: _pressedButtons.contains(mood)
                  ? Colors.grey[300]
                  : moodColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.orangeAccent.withOpacity(0.2),
                  spreadRadius: 3,
                  blurRadius: 5,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(icon, color: Colors.black, size: 30),
                SizedBox(height: 5),
                Text(mood, style: TextStyle(
                    color: Colors.black, fontFamily: 'LuckiestGuy')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}