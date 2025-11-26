import 'package:flutter/material.dart';

void main() {
  runApp(const SiswaKalender());
}

class SiswaKalender extends StatelessWidget {
  const SiswaKalender({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Calendar UI',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'Arial',
      ),
      home: const CalendarHomePage(),
    );
  }
}

class CalendarHomePage extends StatefulWidget {
  const CalendarHomePage({super.key});

  @override
  State<CalendarHomePage> createState() => _CalendarHomePageState();
}

class _CalendarHomePageState extends State<CalendarHomePage> {
  DateTime _selectedDate = DateTime.now();
  String _selectedMonth = _getCurrentMonth();
  final PageController _pageController = PageController(initialPage: _getInitialPage());
  final List<DateTime> _weeks = [];

  static String _getCurrentMonth() {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[DateTime.now().month - 1];
  }

  static int _getInitialPage() {
    return 52;
  }

  List<String> _getMonthList() {
    return [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
  }

  // Generate weeks for the page view (2 years: 1 year back and 1 year forward)
  void _generateWeeks() {
    final now = DateTime.now();
    final startDate = DateTime(now.year - 1, now.month, now.day);
    
    _weeks.clear();
    for (int i = 0; i < 104; i++) {
      final weekStart = startDate.add(Duration(days: i * 7));
      _weeks.add(weekStart);
    }
  }

  // Generate dates for a specific week (7 days starting from Sunday)
  List<DateTime> _getWeekDates(DateTime weekStart) {
    return List.generate(7, (index) => weekStart.add(Duration(days: index)));
  }

  // Show month picker dialog
  void _showMonthPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 400,
          child: Column(
            children: [
              const Text(
                'Pilih Bulan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.0,
                  ),
                  itemCount: _getMonthList().length,
                  itemBuilder: (context, index) {
                    final month = _getMonthList()[index];
                    return ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _selectedMonth = month;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedMonth == month 
                            ? Colors.indigo 
                            : Colors.grey[100],
                        foregroundColor: _selectedMonth == month 
                            ? Colors.white 
                            : Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        month,
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _generateWeeks();
    _pageController.addListener(_onPageChanged);
  }

  void _onPageChanged() {
    final currentPage = _pageController.page?.round() ?? 0;
    if (currentPage < _weeks.length) {
      final weekStart = _weeks[currentPage];
      setState(() {
        _selectedMonth = _getMonthList()[weekStart.month - 1];
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Janji Temu',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: const [
          Icon(Icons.search, color: Colors.black54),
          SizedBox(width: 8),
          Icon(Icons.settings_outlined, color: Colors.black54),
          SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==== CALENDAR CONTAINER ====
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ==== HEADER INSIDE CONTAINER ====
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Mulai tanggal dan waktu',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      // CUSTOM MONTH SELECTOR
                      GestureDetector(
                        onTap: _showMonthPicker,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedMonth,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ==== WEEK DAYS HEADER ====
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(7, (index) {
                      return SizedBox(
                        width: 40,
                        child: Column(
                          children: [
                            Container(
                              width: 40,
                              height: 24,
                              alignment: Alignment.center,
                              child: Text(
                                ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'][index],
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],
                        ),
                      );
                    }),
                  ),

                  // ==== SCROLLABLE WEEKS ====
                  SizedBox(
                    height: 60,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _weeks.length,
                      itemBuilder: (context, pageIndex) {
                        final weekStart = _weeks[pageIndex];
                        final weekDates = _getWeekDates(weekStart);
                        
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: List.generate(7, (index) {
                            final date = weekDates[index];
                            final day = date.day;
                            final isSelected = _selectedDate.day == day && 
                                              _selectedDate.month == date.month && 
                                              _selectedDate.year == date.year;
                            final isToday = date.day == DateTime.now().day && 
                                           date.month == DateTime.now().month && 
                                           date.year == DateTime.now().year;

                            return GestureDetector(
                              onTap: () => setState(() {
                                _selectedDate = date;
                                _selectedMonth = _getMonthList()[date.month - 1];
                              }),
                              child: SizedBox(
                                width: 40,
                                child: Column(
                                  children: [
                                    // TANGGAL
                                    Container(
                                      width: 40,
                                      height: 36,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isSelected 
                                            ? Colors.green 
                                            : (isToday ? Colors.blue.withValues(alpha: 0.2) : Colors.transparent),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        day.toString(),
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : (isToday ? Colors.blue : Colors.black),
                                          fontWeight: isSelected ? FontWeight.bold : (isToday ? FontWeight.bold : FontWeight.normal),
                                        ),
                                      ),
                                    ),
                                    // BULAN (jika minggu lintas bulan)
                                    if (index == 0 || day == 1) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        _getMonthAbbreviation(date.month),
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Text(
              'Janji Temu - $_selectedDate ${_selectedMonth.substring(0, 3)} ${_selectedDate.year}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),

            // ==== APPOINTMENT CARDS ====
            const Wrap(
              runSpacing: 12,
              children: [
                AppointmentCard(
                  title: 'Rapat perencanaan',
                  time: '08:00 - 11:50',
                  color: Colors.white,
                  accentColor: Colors.green,
                  left: '2 hari lagi',
                  progress: 0.8,
                ),
                AppointmentCard(
                  title: 'Makan siang',
                  time: '12:15 - 13:10',
                  color: Color(0xFFEDE9FB),
                  accentColor: Colors.purple,
                  left: '1 minggu lagi',
                  progress: 0.6,
                ),
                AppointmentCard(
                  title: 'Cek proyek',
                  time: '13:30 - 16:30',
                  color: Color(0xFFE7F3FA),
                  accentColor: Colors.lightBlue,
                  left: '3 minggu lagi',
                  progress: 0.3,
                ),
                AppointmentCard(
                  title: 'Rapat tim marketing',
                  time: '08:00 - 08:40',
                  color: Colors.white,
                  accentColor: Colors.teal,
                  left: '',
                  progress: 0.0,
                ),
                AppointmentCard(
                  title: 'Coffee break dan snack',
                  time: '10:00 - 10:35',
                  color: Colors.white,
                  accentColor: Colors.deepPurple,
                  left: '',
                  progress: 0.0,
                ),
              ],
            ),
          ],
        ),
      ),

      // ==== BOTTOM BAR ====
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.wb_sunny_outlined, color: Colors.black54),
            Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black,
              ),
              padding: const EdgeInsets.all(12),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
            const Icon(Icons.share_outlined, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  String _getMonthAbbreviation(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return months[month - 1];
  }
}

// ==== COMPONENT CARD ====
class AppointmentCard extends StatelessWidget {
  final String title;
  final String time;
  final String left;
  final double progress;
  final Color color;
  final Color accentColor;

  const AppointmentCard({
    super.key,
    required this.title,
    required this.time,
    required this.color,
    required this.accentColor,
    required this.left,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: accentColor.withValues(alpha: 0.1),
            child: Icon(Icons.event, color: accentColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 6),
                if (left.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        left,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                if (left.isNotEmpty)
                  Container(
                    height: 5,
                    margin: const EdgeInsets.only(top: 4),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}