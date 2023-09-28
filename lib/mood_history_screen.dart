import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'package:table_calendar/table_calendar.dart';

class MoodHistoryScreen extends StatefulWidget {
  @override
  _MoodHistoryScreenState createState() => _MoodHistoryScreenState();
}

class _MoodHistoryScreenState extends State<MoodHistoryScreen> {
  Map<DateTime, List<dynamic>> _events = {};
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _fetchMoodHistory();
  }

  _fetchMoodHistory() async {
    List<Map<String, dynamic>> moodHistory = await DatabaseHelper.instance.queryAllRows();
    Map<DateTime, List<dynamic>> tempEvents = {};

    for (var entry in moodHistory) {
      DateTime date = DateTime.parse(entry[DatabaseHelper.columnDate]);
      DateTime dateKey = DateTime(date.year, date.month, date.day); // Stripping time component for mood list
      DateTime utcDateKey = DateTime.utc(date.year, date.month, date.day); // Stripping time component for predominant mood
      if (tempEvents[dateKey] == null) tempEvents[dateKey] = [];
      tempEvents[dateKey]!.add(entry[DatabaseHelper.columnMood]);
      if (tempEvents[utcDateKey] == null) tempEvents[utcDateKey] = [];
      tempEvents[utcDateKey]!.add(entry[DatabaseHelper.columnMood]);
    }

    setState(() {
      _events = tempEvents;
    });
  }

  Color getMoodColor(String mood) {
    switch (mood) {
      case 'Happy':
        return Colors.green[200]!;
      case 'Relaxed':
        return Colors.blue[200]!;
      case 'Sad':
        return Colors.grey[400]!;
      case 'Excited':
        return Colors.orange[200]!;
      case 'Angry':
        return Colors.red[200]!;
      case 'Sick':
        return Colors.purple[200]!;
      default:
        return Colors.grey;
    }
  }

  IconData getMoodIcon(String mood) {
    switch (mood) {
      case 'Happy':
        return Icons.sentiment_very_satisfied;
      case 'Relaxed':
        return Icons.sentiment_satisfied_alt_sharp;
      case 'Sad':
        return Icons.sentiment_very_dissatisfied;
      case 'Excited':
        return Icons.sentiment_very_satisfied_rounded;
      case 'Angry':
        return Icons.sentiment_neutral_sharp;
      case 'Sick':
        return Icons.sentiment_very_dissatisfied_rounded;
      default:
        return Icons.sentiment_satisfied; // Default icon
    }
  }


  Color getMoodTextColor(String mood) {
    switch (mood) {
      case 'Happy':
        return Colors.black87;
      case 'Relaxed':
        return Colors.black87;
      case 'Sad':
        return Colors.white;
      case 'Excited':
        return Colors.black87;
      case 'Angry':
        return Colors.black87;
      case 'Sick':
        return Colors.white;
      default:
        return Colors.black54; // Default text color
    }
  }

  Color getPredominantMoodColor(List<dynamic> moods) {
    Map<String, int> moodCount = {};
    for (var mood in moods) {
      if (!moodCount.containsKey(mood)) {
        moodCount[mood] = 1;
      } else {
        moodCount[mood] = moodCount[mood]! + 1;
      }
    }
    String predominantMood = moodCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    return getMoodColor(predominantMood);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mood History',
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
                    title: Text('About Mood History'),
                    content: RichText(
                      text: TextSpan(
                        style: TextStyle(color: Colors.white, fontFamily: 'LuckiestGuy', fontSize: 16),
                        children: <TextSpan>[
                          TextSpan(text: "📅 Track your emotions, see patterns. This section lets you travel back in time and revisit your moods.\n\n"),
                          TextSpan(text: "🔍 And hey, we know emotions can be a rollercoaster, but we've capped it at "),
                          TextSpan(
                            text: '5',
                            style: TextStyle(color: Colors.orangeAccent),
                          ),
                          TextSpan(text: " moods a day. \n🧙 Think of it as a 'limit on emotional baggage'!"),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        child: Text('Got it!'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  )
                  ;
                },
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.now(),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: (day) => _events[day] ?? [],
            onDaySelected: (selectedDay, focusedDay) {
              DateTime dateKey = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
              setState(() {
                _selectedDay = dateKey;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  return Positioned(
                    right: 1,
                    top: 1,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: getPredominantMoodColor(events),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          SizedBox(height: 20),
          Text(
            _selectedDay != null
                ? 'Moods on ${_selectedDay!.day}-${_selectedDay!.month}-${_selectedDay!.year}:'
                : 'Select a date to view moods',
            style: TextStyle(color: Colors.orangeAccent, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'LuckiestGuy'),
          ),
          SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: [
                if (_selectedDay != null && (_events[_selectedDay!] == null || _events[_selectedDay!]!.isEmpty))
                  Center(child: Text("No moods to display for this date.")),
                if (_selectedDay != null && _events[_selectedDay!] != null)
                  ..._events[_selectedDay!]!.map((mood) => ListTile(
                    contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16.0),
                    title: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(getMoodIcon(mood), color: getMoodTextColor(mood)),
                          SizedBox(width: 10),
                          Text(
                            mood,
                            style: TextStyle(color: getMoodTextColor(mood)),
                          ),
                        ],
                      ),
                    ),
                    tileColor: getMoodColor(mood),
                  )).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
