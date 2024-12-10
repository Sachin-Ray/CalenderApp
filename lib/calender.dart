import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const CalendarApp());
}

class CalendarApp extends StatelessWidget {
  const CalendarApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Editable Calendar App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const CalendarPage(),
    );
  }
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, String> customNotes = {};

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      customNotes = prefs
              .getStringList('notes')
              ?.map((e) => e.split('|'))
              .where((e) => e.length == 2)
              .map((e) => MapEntry(DateTime.parse(e[0]), e[1]))
              .fold<Map<DateTime, String>>({}, (map, entry) {
            map[entry.key] = entry.value;
            return map;
          }) ??
          {};
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'notes',
      customNotes.entries
          .map((e) => '${e.key.toIso8601String()}|${e.value}')
          .toList(),
    );
  }

  Future<void> _addNote() async {
    final note = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text(
              'Add Note for ${_selectedDay?.toLocal().toString().split(' ')[0]}'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter note'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (note != null && _selectedDay != null) {
      setState(() {
        customNotes[_selectedDay!] = note;
      });
      await _savePreferences();
    }
  }

  String _getKhasiMonthName(int month) {
    const khasiMonths = [
      'Kyllalyngkot', // January
      'Rymphang', // February
      'Lber', // March
      'Iaiong', // April
      'Mei', // May
      'Jun', // June
      'Julai', // July
      'Ogust', // August
      'Setembar', // September
      'Oktobar', // October
      'Nowembar', // November
      'Nonprah' // December
    ];
    return khasiMonths[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editable Calendar App')),
      body: Column(
        children: [
          // Custom header to display the Khasi month name only
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(
                        _focusedDay.year,
                        _focusedDay.month - 1,
                        1,
                      );
                    });
                  },
                ),
                Text(
                  '${_getKhasiMonthName(_focusedDay.month)} ${_focusedDay.year}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(
                        _focusedDay.year,
                        _focusedDay.month + 1,
                        1,
                      );
                    });
                  },
                ),
              ],
            ),
          ),
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime(2000),
            lastDay: DateTime(2100),
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _addNote();
            },
            onFormatChanged: (format) {
              setState(() => _calendarFormat = format);
            },
            onPageChanged: (focusedDay) {
              setState(() => _focusedDay = focusedDay);
            },
            headerStyle: HeaderStyle(
              formatButtonVisible: false, // Hide the format button
              titleCentered: false, // Title is managed by custom header
              leftChevronVisible: false, // Hide left arrow
              rightChevronVisible: false, // Hide right arrow
              headerPadding: EdgeInsets.zero, // Optional: Remove any padding
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final text = customNotes[day] ?? '';
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(day.day.toString()),
                    if (text.isNotEmpty)
                      Text(
                        text,
                        style:
                            const TextStyle(fontSize: 10, color: Colors.blue),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
