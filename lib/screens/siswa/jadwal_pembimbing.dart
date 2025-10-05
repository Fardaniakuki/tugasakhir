import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class JadwalPembimbingScreen extends StatefulWidget {
  const JadwalPembimbingScreen({super.key});

  @override
  State<JadwalPembimbingScreen> createState() => _JadwalPembimbingScreenState();
}

class _JadwalPembimbingScreenState extends State<JadwalPembimbingScreen> {
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;

  final Map<DateTime, List<Map<String, String>>> _events = {
    DateTime.utc(2025, 9, 9): [
      {
        'jam': '08:00 AM',
        'judul': 'Executive team meeting',
        'lokasi': 'Small meeting room'
      },
    ],
    DateTime.utc(2025, 9, 11): [
      {
        'jam': '09:00 AM',
        'judul': 'Review first draft',
        'lokasi': 'My house'
      },
    ],
    DateTime.utc(2025, 9, 13): [
      {
        'jam': '10:00 AM',
        'judul': 'New product design',
        'lokasi': 'Design department'
      },
    ],
    DateTime.utc(2025, 9, 15): [
      {
        'jam': '11:00 AM',
        'judul': 'Offer new product',
        'lokasi': 'Design department'
      },
      {
        'jam': '11:00 AM',
        'judul': 'Have lunch customers',
        'lokasi': 'Restaurant'
      },
    ],
  };

  /// Ambil event sesuai tanggal terpilih
  List<Map<String, String>> get _eventsToShow {
    final day = selectedDay ?? focusedDay;

    final selectedEvents = _events[DateTime.utc(
      day.year,
      day.month,
      day.day,
    )];

    return selectedEvents ?? [];
  }

  final List<Color> eventColors = [
    Colors.green,
    Colors.orange,
    Colors.pink,
    Colors.blue,
    Colors.purple,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121421),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121421),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white), // 🔹 ubah warna tombol back
        title: const Text(
          'Penjadwalan',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Kalender
          TableCalendar(
            firstDay: DateTime.utc(2025, 1, 1),
            lastDay: DateTime.utc(2025, 12, 31),
            focusedDay: focusedDay,
            selectedDayPredicate: (day) => isSameDay(selectedDay, day),
            onDaySelected: (sDay, fDay) {
              setState(() {
                selectedDay = sDay;
                focusedDay = fDay;
              });
            },
            eventLoader: (day) =>
                _events[DateTime.utc(day.year, day.month, day.day)] ?? [],
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: Colors.white70),
              weekendStyle: TextStyle(color: Colors.white70),
            ),
            calendarStyle: const CalendarStyle(
              defaultTextStyle: TextStyle(color: Colors.white),
              weekendTextStyle: TextStyle(color: Colors.white),
              outsideTextStyle: TextStyle(color: Colors.grey),
              todayDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),

          // 🔹 Garis pemisah
          const Divider(
            color: Colors.white24,
            thickness: 1,
            height: 20,
            indent: 16,
            endIndent: 16,
          ),

          // Timeline
          Expanded(
            child: _eventsToShow.isEmpty
                ? const Center(
                    child: Text(
                      'Tidak ada jadwal hari ini',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _eventsToShow.length,
                    itemBuilder: (context, index) {
                      final e = _eventsToShow[index];
                      final color = eventColors[index % eventColors.length];

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Jam di kiri
                          SizedBox(
                            width: 70,
                            child: Text(
                              e['jam'] ?? '',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Card event di kanan
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e['judul'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    e['lokasi'] ?? '',
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
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
