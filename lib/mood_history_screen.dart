import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:table_calendar/table_calendar.dart';
import 'database_helper.dart';
import 'app_theme.dart';

class MoodHistoryScreen extends StatefulWidget {
  const MoodHistoryScreen({Key? key}) : super(key: key);
  @override
  State<MoodHistoryScreen> createState() => _MoodHistoryScreenState();
}

class _MoodHistoryScreenState extends State<MoodHistoryScreen> {
  Map<DateTime, List<dynamic>> _events = {};
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  int _streakCount = 0;
  final GlobalKey _shareCardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _fetchMoodHistory();
  }

  Future<void> _fetchMoodHistory() async {
    final moodHistory = await DatabaseHelper.instance.queryAllRows();
    final Map<DateTime, List<dynamic>> tempEvents = {};

    for (final entry in moodHistory) {
      final date = DateTime.parse(entry[DatabaseHelper.columnDate] as String);
      final localKey = DateTime(date.year, date.month, date.day);
      final utcKey   = DateTime.utc(date.year, date.month, date.day);
      final mood = entry[DatabaseHelper.columnMood] as String;

      tempEvents.putIfAbsent(localKey, () => []).add(mood);
      tempEvents.putIfAbsent(utcKey, () => []).add(mood);
    }

    setState(() {
      _events = tempEvents;
      _streakCount = _calculateStreak(tempEvents);
    });
  }

  int _calculateStreak(Map<DateTime, List<dynamic>> events) {
    final localKeys = events.keys.where((d) => !d.isUtc).toSet();
    int streak = 0;
    DateTime day = DateTime(
      DateTime.now().year, DateTime.now().month, DateTime.now().day);

    while (localKeys.contains(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Map<String, int> _weekMoodCounts() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final counts = <String, int>{};
    for (final entry in _events.entries) {
      if (entry.key.isUtc) continue;
      if (entry.key.isBefore(cutoff)) continue;
      for (final mood in entry.value) {
        counts[mood as String] = (counts[mood] ?? 0) + 1;
      }
    }
    return counts;
  }

  Color _getMoodColor(String mood) => AppTheme.moodColor(mood);
  IconData _getMoodIcon(String mood) => AppTheme.moodIcon(mood);

  Color _getMoodTextColor(String mood) {
    switch (mood) {
      case 'Sad':  return Colors.white;
      case 'Sick': return Colors.white;
      default:     return Colors.black87;
    }
  }

  Color _getPredominantMoodColor(List<dynamic> moods) {
    final counts = <String, int>{};
    for (final m in moods) {
      counts[m as String] = (counts[m] ?? 0) + 1;
    }
    final top = counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    return _getMoodColor(top);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood History', style: AppTheme.appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _showShareSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_streakCount > 0) _buildStreakBanner(),
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.now(),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: (day) => _events[day] ?? [],
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) => setState(() => _calendarFormat = format),
            onPageChanged: (focusedDay) => _focusedDay = focusedDay,
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return const SizedBox.shrink();
                return Positioned(
                  right: 1, top: 1,
                  child: Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getPredominantMoodColor(events),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _selectedDay != null
                ? 'Moods on ${_selectedDay!.day}-${_selectedDay!.month}-${_selectedDay!.year}:'
                : 'Select a date to view moods',
            style: const TextStyle(
              color: AppTheme.accentOrange, fontSize: 16,
              fontWeight: FontWeight.bold, fontFamily: 'LuckiestGuy',
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                if (_selectedDay != null && (_events[_selectedDay!]?.isEmpty ?? true))
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No moods logged for this date.',
                        style: TextStyle(fontFamily: 'Poppins', color: Colors.white38)),
                    ),
                  ),
                if (_selectedDay != null && (_events[_selectedDay!]?.isNotEmpty ?? false))
                  ..._events[_selectedDay!]!.map((mood) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    tileColor: _getMoodColor(mood as String),
                    title: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_getMoodIcon(mood), color: _getMoodTextColor(mood)),
                          const SizedBox(width: 10),
                          Text(mood, style: TextStyle(color: _getMoodTextColor(mood))),
                        ],
                      ),
                    ),
                  )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: AppTheme.defaultCardRadius,
        border: Border.all(color: AppTheme.accentOrange, width: 1),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Text(
            '$_streakCount day streak',
            style: const TextStyle(
              fontFamily: 'LuckiestGuy', color: AppTheme.accentOrange, fontSize: 18),
          ),
        ],
      ),
    );
  }

  void _showShareSheet(BuildContext context) {
    final weekCounts = _weekMoodCounts();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              key: _shareCardKey,
              child: _buildShareCard(weekCounts),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _shareCard();
              },
              icon: const Icon(Icons.share),
              label: const Text('Share', style: TextStyle(fontFamily: 'LuckiestGuy')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareCard(Map<String, int> weekCounts) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 6));
    final dateRange =
        '${weekAgo.day} ${_monthAbbr(weekAgo.month)} – ${now.day} ${_monthAbbr(now.month)}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('My Mood Week',
            style: TextStyle(fontFamily: 'LuckiestGuy', fontSize: 20, color: AppTheme.accentOrange)),
          const SizedBox(height: 4),
          Text(dateRange,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white54)),
          const SizedBox(height: 16),
          if (weekCounts.isEmpty)
            const Text('No moods logged this week.',
              style: TextStyle(fontFamily: 'Poppins', color: Colors.white38))
          else
            Wrap(
              spacing: 8, runSpacing: 8,
              children: weekCounts.entries.map((e) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.moodColor(e.key),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${e.key}  ${e.value}×',
                  style: TextStyle(
                    fontFamily: 'LuckiestGuy', fontSize: 12,
                    color: _getMoodTextColor(e.key)),
                ),
              )).toList(),
            ),
          if (_streakCount > 0) ...[
            const SizedBox(height: 12),
            Text('🔥 $_streakCount day streak',
              style: const TextStyle(fontFamily: 'LuckiestGuy', fontSize: 14, color: AppTheme.accentOrange)),
          ],
          const SizedBox(height: 16),
          const Text('Tracked with MoodWeather',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Colors.white24)),
        ],
      ),
    );
  }

  Future<void> _shareCard() async {
    try {
      final boundary = _shareCardKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/mood_summary.png');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'My mood this week with MoodWeather! 🌤️',
      );
    } catch (_) {}
  }

  String _monthAbbr(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('About Mood History'),
        content: RichText(
          text: const TextSpan(
            style: TextStyle(color: Colors.white, fontFamily: 'LuckiestGuy', fontSize: 16),
            children: [
              TextSpan(text: '📅 Track your emotions, see patterns. Tap any date to revisit your moods.\n\n'),
              TextSpan(text: '🔍 Capped at '),
              TextSpan(text: '5', style: TextStyle(color: AppTheme.accentOrange)),
              TextSpan(text: ' moods a day.\n🧙 Think of it as a limit on emotional baggage!'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}
