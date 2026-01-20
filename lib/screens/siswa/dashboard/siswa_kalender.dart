import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await initializeDateFormatting('id_ID', null);
  } catch (e) {
    print('Failed to initialize Indonesian locale: $e');
  }

  runApp(const SiswaKalender());
}

class SiswaKalender extends StatelessWidget {
  const SiswaKalender({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kalender PKL',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'Arial',
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'),
        Locale('en', 'US'),
      ],
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
  // ========== VARIABEL UTAMA ==========
  DateTime _currentDate = DateTime.now();
  DateTime? _selectedDate;
  late List<List<DateTime?>> _calendarDays;
  late String _currentMonth;
  final DateTime _pklStartDate = DateTime.now().add(const Duration(days: 10));
  final DateTime _pklEndDate = DateTime.now().add(const Duration(days: 90));

  // ========== WARNA YANG DIPERBAIKI ==========
  static const Color _primaryColor = Color(0xFF9f0712); // Merah PKL
  static const Color _secondaryColor = Color(0xFFE6E3E3);
  static const Color _accentColor = Color(0xFFA8DADC);
  static const Color _darkColor = Color(0xFF641E20);
  static const Color _yellowColor = Color(0xFFFFD166);
  static const Color _greenColor = Color(0xFF06D6A0); // Hijau cerah
  static const Color _redColor = Color(0xFF9f0712); // Merah sama dengan PKL
  static const Color _blackColor = Colors.black;
  static const Color _whiteColor = Colors.white;
  static const Color _creamColor = Color(0xFFF5F5DC);

  // ========== SHADOWS ==========
  static const BoxShadow _heavyShadow = BoxShadow(
    color: Colors.black,
    offset: Offset(6, 6),
    blurRadius: 0,
  );

  static const BoxShadow _mediumShadow = BoxShadow(
    color: Colors.black,
    offset: Offset(4, 4),
    blurRadius: 0,
  );


  // ========== DATA JADWAL ==========
  final Map<DateTime, List<Map<String, dynamic>>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _generateCalendar();
    _initializeEvents();
  }

  // ========== GENERATE KALENDER ==========
  void _generateCalendar() {
    try {
      _currentMonth = DateFormat('MMMM yyyy', 'id_ID').format(_currentDate);
    } catch (e) {
      _currentMonth = DateFormat('MMMM yyyy').format(_currentDate);
    }

    _calendarDays = [];

    final firstDayOfMonth = DateTime(_currentDate.year, _currentDate.month, 1);
    final lastDayOfMonth =
        DateTime(_currentDate.year, _currentDate.month + 1, 0);

    final int startingWeekday = firstDayOfMonth.weekday % 7;

    final List<DateTime?> currentWeek = [];

    // Tambahkan hari dari bulan sebelumnya (transparan)
    if (startingWeekday > 0) {
      final previousMonthLastDay =
          DateTime(_currentDate.year, _currentDate.month, 0);
      for (int i = startingWeekday - 1; i >= 0; i--) {
        final previousDate = DateTime(previousMonthLastDay.year,
            previousMonthLastDay.month, previousMonthLastDay.day - i);
        currentWeek.add(previousDate);
      }
    }

    // Tambahkan hari dari bulan ini
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(_currentDate.year, _currentDate.month, day);
      currentWeek.add(date);

      if (currentWeek.length == 7) {
        _calendarDays.add(List.from(currentWeek));
        currentWeek.clear();
      }
    }

    // Tambahkan hari dari bulan berikutnya (transparan)
    if (currentWeek.isNotEmpty) {
      int nextMonthDay = 1;
      while (currentWeek.length < 7) {
        final nextDate =
            DateTime(_currentDate.year, _currentDate.month + 1, nextMonthDay);
        currentWeek.add(nextDate);
        nextMonthDay++;
      }
      _calendarDays.add(currentWeek);
    }
  }

  // ========== INISIALISASI EVENT ==========
  void _initializeEvents() {
    final now = DateTime.now();

    // Event hari ini (hijau)
    final today = DateTime(now.year, now.month, now.day);
    _events[today] = [
      {
        'deskripsi':
            'Pembekalan awal untuk siswa PKL mengenai tata tertib dan prosedur keselamatan kerja di lingkungan perusahaan.',
        'jenis_kegiatan': 'PEMBEKALAN AWAL',
        'tanggal_mulai': today,
        'tanggal_selesai': today,
        'color': _greenColor,
        'icon': Icons.school,
        'lokasi': 'AULA UTAMA LT. 3',
        'waktu': '08:00 - 12:00',
      }
    ];

    // Event besok (hijau)
    final tomorrow = today.add(const Duration(days: 1));
    _events[tomorrow] = [
      {
        'deskripsi':
            'Pengenalan lengkap mengenai struktur organisasi perusahaan dan pembagian tugas proyek untuk siswa PKL.',
        'jenis_kegiatan': 'ORIENTASI PERUSAHAAN',
        'tanggal_mulai': tomorrow,
        'tanggal_selesai': tomorrow,
        'color': _greenColor,
        'icon': Icons.business,
        'lokasi': 'KANTOR PUSAT',
        'waktu': '09:00 - 16:00',
      }
    ];

    // Event untuk 3 hari lagi (merah)
    final day3 = today.add(const Duration(days: 3));
    _events[day3] = [
      {
        'deskripsi':
            'Presentasi progress mingguan proyek PKL dihadapan pembimbing dan tim. Sesi konsultasi teknis.',
        'jenis_kegiatan': 'PRESENTASI PROGRESS',
        'tanggal_mulai': day3,
        'tanggal_selesai': day3,
        'color': _redColor,
        'icon': Icons.present_to_all,
        'lokasi': 'RUANG MEETING 301',
        'waktu': '13:00 - 15:00',
      }
    ];

    // Event untuk 5 hari lagi (hijau)
    final day5 = today.add(const Duration(days: 5));
    _events[day5] = [
      {
        'deskripsi':
            'Evaluasi menyeluruh terhadap kinerja individu dan pencapaian target bulanan.',
        'jenis_kegiatan': 'EVALUASI KINERJA',
        'tanggal_mulai': day5,
        'tanggal_selesai': day5,
        'color': _greenColor,
        'icon': Icons.assessment,
        'lokasi': 'RUANG HRD',
        'waktu': '10:00 - 12:00',
      }
    ];

    // Event untuk 7 hari lagi (merah)
    final day7 = today.add(const Duration(days: 7));
    _events[day7] = [
      {
        'deskripsi':
            'Pelatihan intensif penggunaan software internal perusahaan termasuk sistem ERP dan tools monitoring.',
        'jenis_kegiatan': 'PELATIHAN SOFTWARE',
        'tanggal_mulai': day7,
        'tanggal_selesai': day7,
        'color': _redColor,
        'icon': Icons.computer,
        'lokasi': 'LAB KOMPUTER',
        'waktu': '09:00 - 17:00',
      }
    ];

    // Event hari terakhir PKL (merah)
    _events[_pklEndDate] = [
      {
        'deskripsi':
            'Acara penutupan dan presentasi final hasil PKL. Penyerahan sertifikat kelulusan.',
        'jenis_kegiatan': 'PENUTUPAN PKL',
        'tanggal_mulai': _pklEndDate,
        'tanggal_selesai': _pklEndDate,
        'color': _redColor,
        'icon': Icons.celebration,
        'lokasi': 'AUDITORIUM UTAMA',
        'waktu': '09:00 - 16:00',
      }
    ];

    // Event dengan multiple jadwal di hari yang sama
    final multiDay = today.add(const Duration(days: 2));
    _events[multiDay] = [
      {
        'deskripsi':
            'Meeting koordinasi tim proyek untuk membahas rencana kerja minggu ini.',
        'jenis_kegiatan': 'MEETING TIM',
        'tanggal_mulai': multiDay,
        'tanggal_selesai': multiDay,
        'color': _greenColor,
        'icon': Icons.group,
        'lokasi': 'MEETING ROOM A',
        'waktu': '10:00 - 11:30',
      },
    ];
  }

  // ========== FUNGSI NAVIGASI ==========
  void _goToPreviousMonth() {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month - 1, 1);
      _generateCalendar();
    });
  }

  void _goToNextMonth() {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month + 1, 1);
      _generateCalendar();
    });
  }

  // ========== FUNGSI HELPER ==========
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isSelected(DateTime date) {
    return _selectedDate != null &&
        _selectedDate!.year == date.year &&
        _selectedDate!.month == date.month &&
        _selectedDate!.day == date.day;
  }

  bool _isPKLPeriod(DateTime date) {
    return (date.isAfter(_pklStartDate.subtract(const Duration(days: 1))) &&
        date.isBefore(_pklEndDate.add(const Duration(days: 1))));
  }

  bool _isCurrentMonth(DateTime date) {
    return date.year == _currentDate.year && date.month == _currentDate.month;
  }

  bool _hasEvent(DateTime date) {
    return _events.containsKey(DateTime(date.year, date.month, date.day));
  }

  Color _getEventColor(DateTime date) {
    final events = _events[DateTime(date.year, date.month, date.day)];
    if (events != null && events.isNotEmpty) {
      return events.first['color'] as Color;
    }
    return _redColor;
  }

  String _getDayName(int weekday) {
    const days = ['M', 'S', 'S', 'R', 'K', 'J', 'S'];
    return days[weekday % 7];
  }


  String _getMonthAbbreviation(int month) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MEI',
      'JUN',
      'JUL',
      'AGU',
      'SEP',
      'OKT',
      'NOV',
      'DES'
    ];
    return months[month - 1];
  }

  String _formatDateForDisplay(DateTime date) {
    try {
      return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return DateFormat('EEEE, dd MMMM yyyy').format(date);
    }
  }

  // ========== FUNGSI UNTUK WARNA BERDASARKAN JADWAL ==========
  Color _getDateBackgroundColor(DateTime date) {
    if (_isSelected(date)) return _primaryColor;
    if (_isToday(date)) return _yellowColor;
    if (_isPKLPeriod(date)) return _creamColor;
    return _whiteColor;
  }

  Color _getDateTextColor(DateTime date) {
    if (_isSelected(date)) return _whiteColor;
    if (_isToday(date)) return _blackColor;
    if (!_isCurrentMonth(date)) return Colors.black.withValues(alpha:0.3);
    return _blackColor;
  }

  // ========== SHOW MONTH PICKER ==========
  void _showMonthPicker() {
    final months = List.generate(12, (index) => index + 1);
    final currentYear = _currentDate.year;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: _secondaryColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: _blackColor, width: 4),
            boxShadow: const [_heavyShadow],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: _primaryColor,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(26)),
                  border: Border(
                      bottom: BorderSide(color: Colors.black, width: 4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _currentDate = DateTime(
                              _currentDate.year - 1, _currentDate.month, 1);
                          _generateCalendar();
                        });
                      },
                      icon: Container(
                        decoration: BoxDecoration(
                          color: _accentColor,
                          border: Border.all(color: _blackColor, width: 2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.keyboard_arrow_left, size: 30),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                      decoration: BoxDecoration(
                        color: _yellowColor,
                        border: Border.all(color: _blackColor, width: 3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        currentYear.toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: _blackColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _currentDate = DateTime(
                              _currentDate.year + 1, _currentDate.month, 1);
                          _generateCalendar();
                        });
                      },
                      icon: Container(
                        decoration: BoxDecoration(
                          color: _accentColor,
                          border: Border.all(color: _blackColor, width: 2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.keyboard_arrow_right, size: 30),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: months.length,
                    itemBuilder: (context, index) {
                      final month = months[index];
                      final isCurrentMonth = month == _currentDate.month;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentDate = DateTime(currentYear, month, 1);
                            _generateCalendar();
                            Navigator.pop(context);
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                isCurrentMonth ? _primaryColor : _accentColor,
                            border: Border.all(
                              color: _blackColor,
                              width: isCurrentMonth ? 4 : 3,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: const [_mediumShadow],
                          ),
                          child: Center(
                            child: Text(
                              _getMonthAbbreviation(month),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color:
                                    isCurrentMonth ? _whiteColor : _blackColor,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    border: Border.all(color: _blackColor, width: 3),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [_mediumShadow],
                  ),
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'TUTUP',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _whiteColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final columnWidth = (screenWidth - 56) / 7;

    return Scaffold(
      backgroundColor: _darkColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HEADER SIMPLE TANPA CONTAINER PUTIH
            Container(
              margin: const EdgeInsets.only(top: 40, left: 16, right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: _primaryColor,
                border: Border.all(color: _blackColor, width: 3),
                boxShadow: const [_heavyShadow],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text(
                  'KALENDER PKL',
                  style: TextStyle(
                    color: _whiteColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ========== KONTROL BULAN ==========
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _whiteColor,
                border: Border.all(color: _blackColor, width: 4),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [_heavyShadow],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // TOMBOL PREVIOUS
                  _buildNavButton(
                    icon: Icons.chevron_left,
                    onPressed: _goToPreviousMonth,
                    color: const Color.fromARGB(255, 255, 255, 255),
                  ),

                  const SizedBox(width: 20),

                  // BULAN DAN TAHUN
                  Expanded(
                    child: GestureDetector(
                      onTap: _showMonthPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _darkColor,
                          border: Border.all(color: _blackColor, width: 3),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Center(
                          child: Text(
                            _currentMonth.toUpperCase(),
                            style: const TextStyle(
                              color: _whiteColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  // TOMBOL NEXT
                  _buildNavButton(
                    icon: Icons.chevron_right,
                    onPressed: _goToNextMonth,
                    color: const Color.fromARGB(255, 255, 255, 255),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ========== KALENDER ==========
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _whiteColor,
                border: Border.all(color: _blackColor, width: 4),
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [_heavyShadow],
              ),
              child: Column(
                children: [
                  // HEADER HARI
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _darkColor,
                      border: Border.all(color: _blackColor, width: 3),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: List.generate(7, (index) {
                        return Expanded(
                          child: Center(
                            child: Text(
                              _getDayName(index),
                              style: const TextStyle(
                                color: _whiteColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // HARI-HARI
                  Column(
                    children: _calendarDays.map((week) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: week.map((date) {
                            if (date == null) {
                              return Expanded(
                                child: Container(
                                  margin: const EdgeInsets.all(2),
                                  height: columnWidth,
                                ),
                              );
                            }

                            final isCurrentMonth = _isCurrentMonth(date);
                            final hasEvent = _hasEvent(date);

                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedDate = date;
                                    // Jika tanggal yang dipilih bukan dari bulan saat ini,
                                    // pindah ke bulan tersebut
                                    if (!isCurrentMonth) {
                                      _currentDate =
                                          DateTime(date.year, date.month, 1);
                                      _generateCalendar();
                                    }
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.all(2),
                                  height: columnWidth,
                                  decoration: BoxDecoration(
                                    color: _getDateBackgroundColor(date),
                                    border: Border.all(
                                      color: _blackColor,
                                      width: _isSelected(date) ? 3 : 2,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: _isSelected(date)
                                        ? const [_mediumShadow]
                                        : null,
                                  ),
                                  child: Stack(
                                    children: [
                                      // ANGKA TANGGAL
                                      Opacity(
                                        opacity: isCurrentMonth ? 1.0 : 0.4,
                                        child: Center(
                                          child: Text(
                                            date.day.toString(),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              color: _getDateTextColor(date),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // TITIK MERAH JIKA ADA JADWAL
                                      if (hasEvent)
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: _isSelected(date)
                                                  ? _whiteColor
                                                  : _getEventColor(date),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color: _blackColor, width: 1),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ========== HEADER JADWAL ==========
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: _primaryColor,
                border: Border.all(color: _blackColor, width: 4),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [_heavyShadow],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _selectedDate != null &&
                              _events.containsKey(DateTime(_selectedDate!.year,
                                  _selectedDate!.month, _selectedDate!.day))
                          ? '${_events[DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day)]!.length} JADWAL'
                          : 'JADWAL HARIAN',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(
                      color: _yellowColor,
                      border: Border.all(color: _blackColor, width: 3),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [_mediumShadow],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 16, color: _blackColor),
                        const SizedBox(width: 8),
                        Text(
                          _selectedDate != null
                              ? '${_selectedDate!.day} ${_getMonthAbbreviation(_selectedDate!.month)}'
                              : _getFormattedDateShort(DateTime.now()),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: _blackColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ========== DAFTAR JADWAL ==========
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _selectedDate != null &&
                      _events.containsKey(DateTime(_selectedDate!.year,
                          _selectedDate!.month, _selectedDate!.day))
                  ? Column(
                      children: _events[DateTime(_selectedDate!.year,
                              _selectedDate!.month, _selectedDate!.day)]!
                          .map((event) => _buildEventCard(event))
                          .toList(),
                    )
                  : _buildNoEvents(),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ========== WIDGET BUILDER ==========
  Widget _buildNavButton(
      {required IconData icon, required VoidCallback onPressed, Color? color}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color ?? _accentColor,
          border: Border.all(color: _blackColor, width: 3),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [_mediumShadow],
        ),
        child: Center(
          child: Icon(icon, color: _blackColor, size: 24),
        ),
      ),
    );
  }
Widget _buildEventCard(Map<String, dynamic> event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _whiteColor,
        border: Border.all(color: _blackColor, width: 4),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [_heavyShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // HEADER
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: event['color'] as Color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: const Border(
                  bottom: BorderSide(color: Colors.black, width: 3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _whiteColor,
                    border: Border.all(color: _blackColor, width: 3),
                    shape: BoxShape.circle,
                    boxShadow: const [BoxShadow(
                      color: Colors.black,
                      offset: Offset(3, 3),
                      blurRadius: 0,
                    )],
                  ),
                  child: Icon(
                    event['icon'] as IconData,
                    color: event['color'] as Color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event['jenis_kegiatan'] as String,
                        style: const TextStyle(
                          color: _whiteColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _whiteColor,
                          border: Border.all(color: _blackColor, width: 2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _formatDateForDisplay(event['tanggal_mulai'] as DateTime),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: event['color'] as Color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // DETAIL - SINGLE COLOR CONTAINER
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: event['color'] as Color,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // DESKRIPSI
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _whiteColor,
                    border: Border.all(color: _blackColor, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DESKRIPSI',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: event['color'] as Color,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        event['deskripsi'] as String,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _blackColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                // WAKTU
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: _whiteColor,
                    border: Border.all(color: _blackColor, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WAKTU',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: event['color'] as Color,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        event['waktu'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: _blackColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // PERIODE
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _whiteColor,
                    border: Border.all(color: _blackColor, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PERIODE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: event['color'] as Color,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DateFormat('dd MMM yyyy').format(event['tanggal_mulai'] as DateTime),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: _blackColor,
                        ),
                      ),
                      if (event['tanggal_mulai'] != event['tanggal_selesai'])
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            's/d ${DateFormat('dd MMM yyyy').format(event['tanggal_selesai'] as DateTime)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _darkColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // HELPER UNTUK INFO SECTION

  // HELPER UNTUK INFO ROW

  Widget _buildNoEvents() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        color: _whiteColor,
        border: Border.all(color: _blackColor, width: 4),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [_heavyShadow],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _secondaryColor,
                border: Border.all(color: _blackColor, width: 4),
                shape: BoxShape.circle,
                boxShadow: const [_heavyShadow],
              ),
              child: const Icon(
                Icons.event_note,
                size: 40,
                color: _darkColor,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: _yellowColor,
                border: Border.all(color: _blackColor, width: 3),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Text(
                'TIDAK ADA JADWAL',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: _blackColor,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== HELPER FUNCTIONS ==========
  String _getFormattedDateShort(DateTime date) {
    try {
      return DateFormat('dd MMM', 'id_ID').format(date);
    } catch (e) {
      return DateFormat('dd MMM').format(date);
    }
  }
}
