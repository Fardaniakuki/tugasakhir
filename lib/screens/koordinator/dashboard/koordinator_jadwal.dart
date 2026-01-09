import 'package:flutter/material.dart';

class KoordinatorJadwal extends StatefulWidget {
  const KoordinatorJadwal({super.key});

  @override
  State<KoordinatorJadwal> createState() => _KoordinatorJadwalState();
}

class _KoordinatorJadwalState extends State<KoordinatorJadwal> {
  DateTime _selectedDate = DateTime.now();
  String _selectedMonth = _getCurrentMonth();
  final PageController _pageController = PageController();
  final List<DateTime> _weeks = [];
  String _selectedFilter = 'SEMUA'; // Filter untuk jenis jadwal

  // Neo Brutalism Colors
  static const Color _primaryColor = Color(0xFFE63946); // Merah cerah
  static const Color _secondaryColor = Color(0xFFF1FAEE); // Putih krem
  static const Color _accentColor = Color(0xFFA8DADC); // Biru muda
  static const Color _darkColor = Color(0xFF1D3557); // Biru tua
  static const Color _yellowColor = Color(0xFFFFB703); // Kuning cerah
  static const Color _greenColor = Color(0xFF06D6A0); // Hijau cerah
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

  List<String> _getFilterOptions() {
    return ['SEMUA', 'PEMBEKALAN', 'MONITORING', 'PENJEMPUTAN', 'RAPAT', 'KONSULTASI'];
  }

  void _generateWeeks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final daysFromSunday = (today.weekday % 7);
    final thisWeekSunday = today.subtract(Duration(days: daysFromSunday));
    final startDate = thisWeekSunday.subtract(const Duration(days: 52 * 7));
    
    _weeks.clear();
    for (int i = 0; i < 104; i++) {
      final weekStart = startDate.add(Duration(days: i * 7));
      _weeks.add(weekStart);
    }
  }

  List<DateTime> _getWeekDates(DateTime weekStart) {
    return List.generate(7, (index) => weekStart.add(Duration(days: index)));
  }

  int _getInitialPageIndex() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final daysFromSunday = (today.weekday % 7);
    final thisWeekSunday = today.subtract(Duration(days: daysFromSunday));
    
    if (_weeks.isEmpty) return 52;
    
    for (int i = 0; i < _weeks.length; i++) {
      final weekStart = _weeks[i];
      final weekEnd = weekStart.add(const Duration(days: 6));
      
      if ((thisWeekSunday.isAfter(weekStart) || thisWeekSunday.isAtSameMomentAs(weekStart)) &&
          (thisWeekSunday.isBefore(weekEnd) || thisWeekSunday.isAtSameMomentAs(weekEnd))) {
        return i;
      }
    }
    
    return 52;
  }

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
                          final monthIndex = _getMonthList().indexOf(month) + 1;
                          final currentYear = DateTime.now().year;
                          final firstDayOfMonth = DateTime(currentYear, monthIndex, 1);
                          
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

  String _getMonthAbbreviation(int month) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MEI', 'JUN', 'JUL', 'AGU', 'SEP', 'OKT', 'NOV', 'DES'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const padding = 16.0 * 2;
    const containerPadding = 20.0 * 2;
    final availableWidth = screenWidth - padding - containerPadding;
    final columnWidth = (availableWidth - 20) / 7;

    return Scaffold(
      backgroundColor: _secondaryColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // HEADER BARU - JADWAL KOORDINASI
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _darkColor,
                border: Border.all(color: _blackColor, width: 5),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(8, 8),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _yellowColor,
                      border: Border.all(color: _blackColor, width: 3),
                      shape: BoxShape.circle,
                      boxShadow: const [_mediumShadow],
                    ),
                    child: const Icon(
                      Icons.calendar_month,
                      size: 32,
                      color: _blackColor,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KOORDINASI',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: _yellowColor,
                            letterSpacing: -0.5,
                            shadows: [
                              Shadow(
                                color: _blackColor.withValues(alpha: 0.5),
                                offset: const Offset(2, 2),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Manajemen Jadwal PKL & Kegiatan Koordinasi',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _accentColor,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // Kalender
            Container(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: _accentColor,
                  border: Border.all(color: _blackColor, width: 4),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [_heavyShadow],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
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
                            'TANGGAL TERPILIH',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: _blackColor,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
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
                            width: columnWidth - 2,
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

                    SizedBox(
                      height: columnWidth + 20,
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
            ),

            // FILTER JADWAL (BARU)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _secondaryColor,
                  border: Border.all(color: _blackColor, width: 4),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [_mediumShadow],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _darkColor,
                            border: Border.all(color: _blackColor, width: 3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.filter_alt, size: 16, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'FILTER JADWAL',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _yellowColor,
                            border: Border.all(color: _blackColor, width: 3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'TOTAL: 5 JADWAL',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: _blackColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _getFilterOptions().map((filter) {
                          final bool isSelected = _selectedFilter == filter;
                          Color bgColor;
                          Color textColor;
                          
                          switch(filter) {
                            case 'SEMUA':
                              bgColor = _darkColor;
                              textColor = Colors.white;
                              break;
                            case 'PEMBEKALAN':
                              bgColor = _primaryColor;
                              textColor = Colors.white;
                              break;
                            case 'MONITORING':
                              bgColor = _greenColor;
                              textColor = _blackColor;
                              break;
                            case 'PENJEMPUTAN':
                              bgColor = _accentColor;
                              textColor = _blackColor;
                              break;
                            case 'RAPAT':
                              bgColor = _yellowColor;
                              textColor = _blackColor;
                              break;
                            case 'KONSULTASI':
                              bgColor = Colors.purple;
                              textColor = Colors.white;
                              break;
                            default:
                              bgColor = _darkColor;
                              textColor = Colors.white;
                          }
                          
                          return GestureDetector(
                            onTap: () => setState(() => _selectedFilter = filter),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? bgColor : _secondaryColor,
                                border: Border.all(
                                  color: _blackColor,
                                  width: isSelected ? 3 : 2,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: isSelected ? const [_lightShadow] : null,
                              ),
                              child: Row(
                                children: [
                                  if (isSelected) 
                                    const Icon(Icons.check_circle, size: 14, color: Colors.white),
                                  if (isSelected) const SizedBox(width: 6),
                                  Text(
                                    filter,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: isSelected ? textColor : _blackColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Header Jadwal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _darkColor,
                  border: Border.all(color: _blackColor, width: 4),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [_heavyShadow],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        _selectedFilter == 'SEMUA' 
                            ? 'SEMUA JADWAL KOORDINATOR'
                            : 'JADWAL $_selectedFilter',
                        style: const TextStyle(
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            ),

            const SizedBox(height: 16),

            // Semua Jadwal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Jadwal Pembekalan
                  if (_selectedFilter == 'SEMUA' || _selectedFilter == 'PEMBEKALAN')
                    _buildJadwalCard(
                      title: 'PEMBEKALAN PKL XII RPL',
                      waktu: '08:00 - 12:00',
                      tempat: 'AULA UTAMA',
                      jenis: 'PEMBEKALAN',
                      jenisColor: _primaryColor,
                      status: 'AKTIF',
                      peserta: '42 Siswa',
                      pembicara: 'Budi Santoso, S.Kom',
                      tanggal: '15 Jan 2024',
                    ),
                  if (_selectedFilter == 'SEMUA' || _selectedFilter == 'PEMBEKALAN')
                    const SizedBox(height: 12),

                  // Jadwal Monitoring
                  if (_selectedFilter == 'SEMUA' || _selectedFilter == 'MONITORING')
                    _buildJadwalCard(
                      title: 'MONITORING PT. TECHNO INOVASI',
                      waktu: '09:00 - 15:00',
                      tempat: 'JL. SUDIRMAN NO. 123',
                      jenis: 'MONITORING',
                      jenisColor: _greenColor,
                      status: 'TERJADWAL',
                      peserta: '8 Siswa RPL',
                      pembimbing: 'Dra. Sri Rahayu',
                      tanggal: '22 Jan 2024',
                    ),
                  if (_selectedFilter == 'SEMUA' || _selectedFilter == 'MONITORING')
                    const SizedBox(height: 12),

                  // Jadwal Penjemputan
                  if (_selectedFilter == 'SEMUA' || _selectedFilter == 'PENJEMPUTAN')
                    _buildJadwalCard(
                      title: 'PENJEMPUTAN SISWA PKL',
                      waktu: '14:00 - 16:00',
                      tempat: 'LOKASI INDUSTRI',
                      jenis: 'PENJEMPUTAN',
                      jenisColor: _accentColor,
                      status: 'DALAM PROSES',
                      peserta: '12 Siswa',
                      sopir: 'Pak Agus',
                      tanggal: '25 Jan 2024',
                    ),
                  if (_selectedFilter == 'SEMUA' || _selectedFilter == 'PENJEMPUTAN')
                    const SizedBox(height: 12),

                  // Jadwal Rapat
                  if (_selectedFilter == 'SEMUA' || _selectedFilter == 'RAPAT')
                    _buildJadwalCard(
                      title: 'RAPAT KOORDINASI PKL',
                      waktu: '13:00 - 15:00',
                      tempat: 'RUANG RAPAT',
                      jenis: 'RAPAT',
                      jenisColor: _yellowColor,
                      status: 'SELESAI',
                      peserta: '5 Guru Pembimbing',
                      agenda: 'Evaluasi Mingguan',
                      tanggal: '18 Jan 2024',
                    ),
                  if (_selectedFilter == 'SEMUA' || _selectedFilter == 'RAPAT')
                    const SizedBox(height: 12),

                  // Jadwal Konsultasi
                  if (_selectedFilter == 'SEMUA' || _selectedFilter == 'KONSULTASI')
                    _buildJadwalCard(
                      title: 'KONSULTASI DENGAN INDUSTRI',
                      waktu: '10:00 - 11:30',
                      tempat: 'PT. DIGITAL KREASI',
                      jenis: 'KONSULTASI',
                      jenisColor: _darkColor,
                      status: 'TERJADWAL',
                      peserta: 'Koordinator PKL',
                      agenda: 'Penyesuaian Jadwal',
                      tanggal: '28 Jan 2024',
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJadwalCard({
    required String title,
    required String waktu,
    required String tempat,
    required String jenis,
    required Color jenisColor,
    required String status,
    required String peserta,
    required String tanggal,
    String? pembicara,
    String? pembimbing,
    String? sopir,
    String? agenda,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _blackColor, width: 4),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [_heavyShadow],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: jenisColor,
                    border: Border.all(color: _blackColor, width: 2),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [_lightShadow],
                  ),
                  child: Text(
                    jenis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: status == 'AKTIF' ? _greenColor : 
                           status == 'TERJADWAL' ? _yellowColor : 
                           status == 'DALAM PROSES' ? _accentColor : _darkColor,
                    border: Border.all(color: _blackColor, width: 2),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [_lightShadow],
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: _blackColor,
                letterSpacing: -0.5,
              ),
            ),
            
            const SizedBox(height: 12),
            
            _buildDetailRow(Icons.calendar_today, 'TANGGAL', tanggal),
            _buildDetailRow(Icons.access_time, 'WAKTU', waktu),
            _buildDetailRow(Icons.location_on, 'LOKASI', tempat),
            _buildDetailRow(Icons.people, 'PESERTA', peserta),
            
            if (pembicara != null) 
              _buildDetailRow(Icons.person, 'PEMBICARA', pembicara),
            
            if (pembimbing != null) 
              _buildDetailRow(Icons.school, 'PEMBIMBING', pembimbing),
            
            if (sopir != null) 
              _buildDetailRow(Icons.drive_eta, 'SOPIR', sopir),
            
            if (agenda != null) 
              _buildDetailRow(Icons.list_alt, 'AGENDA', agenda),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _accentColor,
                      border: Border.all(color: _blackColor, width: 3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextButton.icon(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        foregroundColor: _blackColor,
                      ),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text(
                        'EDIT',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      border: Border.all(color: _blackColor, width: 3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextButton.icon(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text(
                        'HAPUS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _yellowColor,
                      border: Border.all(color: _blackColor, width: 3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextButton.icon(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        foregroundColor: _blackColor,
                      ),
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text(
                        'CETAK',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _darkColor,
              border: Border.all(color: _blackColor, width: 2),
              shape: BoxShape.circle,
              boxShadow: const [_lightShadow],
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: _darkColor,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _blackColor,
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