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
      title: 'Neo Brutalism Calendar',
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
  final PageController _pageController = PageController();
  final List<DateTime> _weeks = [];

  // Neo Brutalism Colors
  static const Color _primaryColor = Color(0xFFE63946); // Merah cerah
  static const Color _secondaryColor = Color(0xFFF1FAEE); // Putih krem
  static const Color _accentColor = Color(0xFFA8DADC); // Biru muda
  static const Color _darkColor = Color(0xFF1D3557); // Biru tua
  static const Color _yellowColor = Color(0xFFFFB703); // Kuning cerah
  static const Color _blackColor = Colors.black;

  // Neo Brutalism Shadows
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

  static const BoxShadow _lightShadow = BoxShadow(
    color: Colors.black,
    offset: Offset(2, 2),
    blurRadius: 0,
  );

  static String _getCurrentMonth() {
    const months = [
      'JANUARI', 'FEBRUARI', 'MARET', 'APRIL', 'MEI', 'JUNI',
      'JULI', 'AGUSTUS', 'SEPTEMBER', 'OKTOBER', 'NOVEMBER', 'DESEMBER'
    ];
    return months[DateTime.now().month - 1];
  }

  List<String> _getMonthList() {
    return [
      'JANUARI', 'FEBRUARI', 'MARET', 'APRIL', 'MEI', 'JUNI',
      'JULI', 'AGUSTUS', 'SEPTEMBER', 'OKTOBER', 'NOVEMBER', 'DESEMBER'
    ];
  }

  // Generate weeks for the page view (2 years: 1 year back and 1 year forward)
  void _generateWeeks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Cari hari Minggu terdekat (0 = Minggu, 1 = Senin, ..., 6 = Sabtu)
    // DateTime.weekday: 1 = Senin, 7 = Minggu
    final daysFromSunday = (today.weekday % 7); // Konversi: 0=Minggu, 1=Senin, dst
    
    // Mulai dari hari Minggu di minggu ini
    final thisWeekSunday = today.subtract(Duration(days: daysFromSunday));
    
    // Generate 104 minggu (2 tahun), dimulai dari 52 minggu yang lalu
    final startDate = thisWeekSunday.subtract(const Duration(days: 52 * 7));
    
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

  // Get initial page index (middle of the 104 weeks)
  int _getInitialPageIndex() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Cari hari Minggu di minggu ini
    final daysFromSunday = (today.weekday % 7);
    final thisWeekSunday = today.subtract(Duration(days: daysFromSunday));
    
    // Cari index dari minggu ini
    if (_weeks.isEmpty) return 52;
    
    for (int i = 0; i < _weeks.length; i++) {
      final weekStart = _weeks[i];
      final weekEnd = weekStart.add(const Duration(days: 6));
      
      if ((thisWeekSunday.isAfter(weekStart) || thisWeekSunday.isAtSameMomentAs(weekStart)) &&
          (thisWeekSunday.isBefore(weekEnd) || thisWeekSunday.isAtSameMomentAs(weekEnd))) {
        return i;
      }
    }
    
    return 52; // Default ke tengah
  }

  // Show month picker dialog in Neo Brutalism style
  void _showMonthPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _secondaryColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 420,
          decoration: BoxDecoration(
            color: _secondaryColor,
            border: Border.all(color: _blackColor, width: 3),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: const [_heavyShadow],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _primaryColor,
                  border: Border.all(color: _blackColor, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'PILIH BULAN',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.8,
                  ),
                  itemCount: _getMonthList().length,
                  itemBuilder: (context, index) {
                    final month = _getMonthList()[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _selectedMonth = month;
                          // Cari tanggal pertama di bulan yang dipilih
                          final monthIndex = _getMonthList().indexOf(month) + 1;
                          final currentYear = DateTime.now().year;
                          final firstDayOfMonth = DateTime(currentYear, monthIndex, 1);
                          
                          // Cari minggu yang mengandung tanggal 1
                          for (int i = 0; i < _weeks.length; i++) {
                            final weekStart = _weeks[i];
                            final weekEnd = weekStart.add(const Duration(days: 6));
                            
                            if ((firstDayOfMonth.isAfter(weekStart) || firstDayOfMonth.isAtSameMomentAs(weekStart)) &&
                                (firstDayOfMonth.isBefore(weekEnd) || firstDayOfMonth.isAtSameMomentAs(weekEnd))) {
                              _pageController.animateToPage(
                                i,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                              break;
                            }
                          }
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedMonth == month ? _yellowColor : _accentColor,
                          border: Border.all(
                            color: _blackColor,
                            width: _selectedMonth == month ? 3 : 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [_mediumShadow],
                        ),
                        child: Center(
                          child: Text(
                            month,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: _blackColor,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    border: Border.all(color: _blackColor, width: 3),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [_mediumShadow],
                  ),
                  child: const Center(
                    child: Text(
                      'TUTUP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.2,
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
  void initState() {
    super.initState();
    _generateWeeks();
    
    // Tunggu sampai layout selesai untuk mendapatkan index halaman yang benar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialPage = _getInitialPageIndex();
      _pageController.animateToPage(
        initialPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
    
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
    // Hitung lebar responsif untuk kalender
    final screenWidth = MediaQuery.of(context).size.width;
    const padding = 16.0 * 2; // Padding kiri + kanan
    const containerPadding = 20.0 * 2; // Padding container kalender
    final availableWidth = screenWidth - padding - containerPadding;
    
    // Hitung lebar kolom yang pas untuk 7 hari
    final columnWidth = (availableWidth - 20) / 7; // Kurangi spacing 20

    return Scaffold(
      backgroundColor: _secondaryColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        elevation: 0,
        title: const Text(
          'KALENDER PKL',
          style: TextStyle(
            color: _secondaryColor,
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        shape: const Border(
          bottom: BorderSide(color: Colors.black, width: 3),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _yellowColor,
              border: Border.all(color: _blackColor, width: 3),
              boxShadow: const [_mediumShadow],
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search,
              color: _blackColor,
              size: 22,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==== CALENDAR CONTAINER NEO BRUTALISM ====
            Container(
              decoration: BoxDecoration(
                color: _accentColor,
                border: Border.all(color: _blackColor, width: 4),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [_heavyShadow],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // ==== HEADER INSIDE CONTAINER ====
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _secondaryColor,
                          border: Border.all(color: _blackColor, width: 3),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [_lightShadow],
                        ),
                        child: const Text(
                          'MULAI TANGGAL',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: _blackColor,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      // CUSTOM MONTH SELECTOR NEO BRUTALISM
                      GestureDetector(
                        onTap: _showMonthPicker,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _yellowColor,
                            border: Border.all(color: _blackColor, width: 3),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [_mediumShadow],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedMonth,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: _blackColor,
                                  fontSize: 12,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: _secondaryColor,
                                  border: Border.all(color: _blackColor, width: 2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.calendar_today,
                                  size: 12,
                                  color: _blackColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ==== WEEK DAYS HEADER NEO BRUTALISM - RESPONSIVE ====
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    decoration: BoxDecoration(
                      color: _secondaryColor,
                      border: Border.all(color: _blackColor, width: 3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (index) {
                        final dayNames = ['MIN', 'SEN', 'SEL', 'RAB', 'KAM', 'JUM', 'SAB'];
                        return Container(
                          width: columnWidth - 2, // Kurangi sedikit untuk spacing
                          height: 30,
                          decoration: BoxDecoration(
                            color: _darkColor,
                            border: Border.all(color: _blackColor, width: 2),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black,
                                offset: Offset(1, 1),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              dayNames[index],
                              style: const TextStyle(
                                color: _secondaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ==== SCROLLABLE WEEKS NEO BRUTALISM - RESPONSIVE ====
                  SizedBox(
                    height: columnWidth + 20, // Tinggi responsif sesuai lebar
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _weeks.length,
                      itemBuilder: (context, pageIndex) {
                        final weekStart = _weeks[pageIndex];
                        final weekDates = _getWeekDates(weekStart);
                        
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(7, (index) {
                              final date = weekDates[index];
                              final day = date.day;
                              final month = date.month;
                              final year = date.year;
                              
                              final isSelected = _selectedDate.day == day && 
                                                _selectedDate.month == month && 
                                                _selectedDate.year == year;
                              final isToday = date.day == DateTime.now().day && 
                                             date.month == DateTime.now().month && 
                                             date.year == DateTime.now().year;

                              return GestureDetector(
                                onTap: () => setState(() {
                                  _selectedDate = date;
                                  _selectedMonth = _getMonthList()[date.month - 1];
                                }),
                                child: SizedBox(
                                  width: columnWidth - 4,
                                  child: Column(
                                    children: [
                                      // HARI SINGKAT DI ATAS
                                      Container(
                                        width: columnWidth - 4,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: _secondaryColor,
                                          border: Border.all(color: _blackColor, width: 1),
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(6),
                                            topRight: Radius.circular(6),
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            ['M', 'S', 'S', 'R', 'K', 'J', 'S'][index],
                                            style: const TextStyle(
                                              color: _darkColor,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // TANGGAL BOX
                                      Container(
                                        width: columnWidth - 4,
                                        height: columnWidth - 4,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: isSelected 
                                              ? _primaryColor 
                                              : (isToday ? _yellowColor : _secondaryColor),
                                          border: Border.all(
                                            color: _blackColor,
                                            width: isSelected ? 3 : 2,
                                          ),
                                          borderRadius: const BorderRadius.only(
                                            bottomLeft: Radius.circular(8),
                                            bottomRight: Radius.circular(8),
                                          ),
                                          boxShadow: isSelected 
                                              ? const [_mediumShadow]
                                              : const [_lightShadow],
                                        ),
                                        child: Center(
                                          child: Text(
                                            day.toString(),
                                            style: TextStyle(
                                              color: isSelected 
                                                  ? Colors.white 
                                                  : _blackColor,
                                              fontWeight: FontWeight.w900,
                                              fontSize: columnWidth < 35 ? 12 : 14,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _primaryColor,
                border: Border.all(color: _blackColor, width: 4),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [_heavyShadow],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      'JADWAL PKL',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        overflow: TextOverflow.ellipsis,
                      ),
                      maxLines: 1,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: _yellowColor,
                      border: Border.all(color: _blackColor, width: 3),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [_lightShadow],
                    ),
                    child: Text(
                      '${_selectedDate.day} ${_getMonthAbbreviation(_selectedDate.month)} ${_selectedDate.year}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: _blackColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ==== APPOINTMENT CARDS NEO BRUTALISM ====
            const Column(
              children: [
                AppointmentCardNeo(
                  title: 'RAPAT PERENCANAAN PKL',
                  time: '08:00 - 11:50',
                  color: Color(0xFFA8DADC), // Biru muda
                  accentColor: Color(0xFF1D3557), // Biru tua
                  left: '2 HARI LAGI',
                  progress: 0.8,
                  icon: Icons.group,
                ),
                SizedBox(height: 12),
                AppointmentCardNeo(
                  title: 'PENGENALAN INDUSTRI',
                  time: '12:15 - 13:10',
                  color: Color(0xFFFFB703), // Kuning
                  accentColor: Color(0xFFE63946), // Merah
                  left: '1 MINGGU LAGI',
                  progress: 0.6,
                  icon: Icons.factory,
                ),
                SizedBox(height: 12),
                AppointmentCardNeo(
                  title: 'CEK PROGRES PROYEK',
                  time: '13:30 - 16:30',
                  color: Color(0xFFF1FAEE), // Putih krem
                  accentColor: Color(0xFF06D6A0), // Hijau
                  left: '3 MINGGU LAGI',
                  progress: 0.3,
                  icon: Icons.assignment,
                ),
                SizedBox(height: 12),
                AppointmentCardNeo(
                  title: 'KONSULTASI PEMBIMBING',
                  time: '08:00 - 08:40',
                  color: Color(0xFFE63946), // Merah
                  accentColor: Color(0xFFF1FAEE), // Putih
                  left: '',
                  progress: 0.0,
                  icon: Icons.school,
                ),
                SizedBox(height: 12),
                AppointmentCardNeo(
                  title: 'EVALUASI MINGGUAN',
                  time: '10:00 - 10:35',
                  color: Color(0xFF1D3557), // Biru tua
                  accentColor: Color(0xFFFFB703), // Kuning
                  left: '',
                  progress: 0.0,
                  icon: Icons.assessment,
                ),
              ],
            ),
            const SizedBox(height: 20), // Tambah padding bawah
          ],
        ),
      ),
    );
  }

  String _getMonthAbbreviation(int month) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MEI', 'JUN', 'JUL', 'AGU', 'SEP', 'OKT', 'NOV', 'DES'];
    return months[month - 1];
  }
}

// ==== COMPONENT CARD NEO BRUTALISM ====
class AppointmentCardNeo extends StatelessWidget {
  final String title;
  final String time;
  final String left;
  final double progress;
  final Color color;
  final Color accentColor;
  final IconData icon;

  const AppointmentCardNeo({
    super.key,
    required this.title,
    required this.time,
    required this.color,
    required this.accentColor,
    required this.left,
    required this.progress,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black, width: 4),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ICON CONTAINER
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accentColor,
              border: Border.all(color: Colors.black, width: 3),
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(3, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          
          // CONTENT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TITLE
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Colors.black,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                
                // TIME
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    time,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // PROGRESS AND COUNTDOWN
                if (left.isNotEmpty)
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE63946),
                                border: Border.all(color: Colors.black, width: 2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                left,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF06D6A0),
                              border: Border.all(color: Colors.black, width: 2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${(progress * 100).toInt()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // PROGRESS BAR
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}