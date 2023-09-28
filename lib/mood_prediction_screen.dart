import 'package:flutter/material.dart';
import 'weather_service.dart';
import 'database_helper.dart';

class MoodPredictionScreen extends StatefulWidget {
  @override
  _MoodPredictionScreenState createState() => _MoodPredictionScreenState();
}

class _MoodPredictionScreenState extends State<MoodPredictionScreen> {
  List<Map<String, dynamic>>? _predictions;
  double? _accuracy;
  int _tapCount = 0;
  bool _showAccuracy = false;

  @override
  void initState() {
    super.initState();
    _fetchPredictionsAndAccuracy();
  }

  _fetchPredictionsAndAccuracy() async {
    final results = await predictMoodBasedOnWeather();
    setState(() {
      _predictions = results['predictions'];
      _accuracy = results['accuracy'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            setState(() {
              _tapCount++;
              if (_tapCount == 7) {
                _showAccuracy = true;
              }
            });
          },
          child: Text('Mood Prediction', style: TextStyle(color: Colors.orangeAccent, fontFamily: 'LuckiestGuy', fontSize: 24)),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("Mood Prediction"),
                    content: Text(
                        "🔮 The app predicts how you might feel for the next 5 days based on the upcoming weather. \n\n"
                            "📈 Our advanced prediction models might not always be spot-on initially.\n\n🧠 But hey, even weather forecasts have their cloudy days! Stick with us, and you might just be blown away✨"
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

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Commented out the 'Predicted Mood for the Week'
            // Text(
            //   'Predicted Mood for the Week: ${_predictions?.first['mood'] ?? 'Fetching...'}',
            //   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            // ),
            // SizedBox(height: 20),
            if (_showAccuracy)
              Text(
                'Prediction Accuracy: ${_accuracy?.toInt() ?? 0}%',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _predictions?.length ?? 0,
                itemBuilder: (context, index) {
                  DateTime date = DateTime.parse(_predictions![index]['date']);
                  String formattedDate = "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
                  String mood = _predictions![index]['mood'];
                  return ListTile(
                    tileColor: _getMoodColor(mood),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(formattedDate, style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(mood),
                        _getMoodIcon(mood),
                      ],
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Icon _getMoodIcon(String mood) {
    switch (mood) {
      case 'Happy':
        return Icon(Icons.sentiment_very_satisfied, color: Colors.green);
      case 'Relaxed':
        return Icon(Icons.sentiment_satisfied, color: Colors.blue);
      case 'Sad':
        return Icon(Icons.sentiment_dissatisfied, color: Colors.grey);
      case 'Excited':
        return Icon(Icons.sentiment_very_satisfied, color: Colors.orange);
      case 'Angry':
        return Icon(Icons.sentiment_very_dissatisfied, color: Colors.red);
      case 'Sick':
        return Icon(Icons.sentiment_neutral, color: Colors.purple);
      default:
        return Icon(Icons.sentiment_neutral, color: Colors.grey);
    }
  }

  Color? _getMoodColor(String mood) {
    switch (mood) {
      case 'Happy':
        return Colors.green[200];
      case 'Relaxed':
        return Colors.blue[200];
      case 'Sad':
        return Colors.grey[400];
      case 'Excited':
        return Colors.orange[200];
      case 'Angry':
        return Colors.red[200];
      case 'Sick':
        return Colors.purple[200];
      default:
        return Colors.grey[300];
    }
  }

  Future<Map<String, dynamic>> predictMoodBasedOnWeather() async {
    List<Map<String, dynamic>> forecast = await WeatherService().fetch5DayForecast();
    List<Map<String, dynamic>> moodHistory = await DatabaseHelper.instance.queryAllRows();

    // Filter the mood history to consider only the last 90 days
    DateTime ninetyDaysAgo = DateTime.now().subtract(Duration(days: 90));
    moodHistory = moodHistory.where((entry) {
      DateTime entryDate = DateTime.parse(entry['date']);
      return entryDate.isAfter(ninetyDaysAgo);
    }).toList();

    // Count the occurrences of each mood for each weather condition
    Map<String, Map<String, int>> moodWeatherCount = {};
    for (var entry in moodHistory) {
      String mood = entry['mood'];
      String weather = entry['weather'];

      if (moodWeatherCount[weather] == null) {
        moodWeatherCount[weather] = {};
      }
      if (moodWeatherCount[weather]![mood] == null) {
        moodWeatherCount[weather]![mood] = 1;
      } else {
        moodWeatherCount[weather]![mood] = moodWeatherCount[weather]![mood]! + 1;
      }
    }

    // Aggregate weather data for each day
    Map<String, List<String>> dailyWeather = {};
    for (var entry in forecast) {
      String date = entry['dt_txt'].split(" ")[0];
      String weather = entry['weather'][0]['main'];
      if (dailyWeather[date] == null) {
        dailyWeather[date] = [];
      }
      dailyWeather[date]!.add(weather);
    }

    // Predict the mood for each day based on the most frequent weather condition for that day
    List<Map<String, dynamic>> predictions = [];
    for (var date in dailyWeather.keys) {
      String mostFrequentWeather = dailyWeather[date]!.fold<Map<String, int>>({}, (acc, e) {
        if (acc[e] == null) {
          acc[e] = 1;
        } else {
          acc[e] = acc[e]! + 1;
        }
        return acc;
      }).entries.reduce((a, b) => a.value > b.value ? a : b).key;

      String mood;
      if (moodWeatherCount[mostFrequentWeather] != null) {
        mood = moodWeatherCount[mostFrequentWeather]!.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      } else {
        mood = 'Neutral'; // Default mood if no historical data for that weather condition
      }
      predictions.add({'date': date, 'mood': mood});
    }

    // Calculate accuracy
    int matchCount = 0;
    for (int i = 0; i < moodHistory.length && i < predictions.length; i++) {
      if (moodHistory[i]['mood'] == predictions[i]['mood']) {
        matchCount++;
      }
    }
    double accuracy = matchCount / (moodHistory.length > 0 ? moodHistory.length : 1);
    accuracy = (accuracy * 100).roundToDouble(); // Round to nearest whole number

    return {
      'predictions': predictions,
      'accuracy': accuracy,
    };
  }

}
