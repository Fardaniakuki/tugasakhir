import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SiswaKalender extends StatefulWidget {
  const SiswaKalender({super.key});

  @override
  State<SiswaKalender> createState() => _SiswaKalenderState();
}

class _SiswaKalenderState extends State<SiswaKalender> {
  // ========== VARIABEL UTAMA ==========
  DateTime _currentDate = DateTime.now();
  DateTime? _selectedDate;
  late List<List<DateTime?>> _calendarDays;
  late String _currentMonth;

  // ========== STATE MANAGEMENT ==========
  bool _isLoading = true;
  bool _isCheckingToken = true;
  String _errorMessage = '';
  List<KegiatanPkl> _allKegiatan = [];
  final Map<DateTime, List<KegiatanPkl>> _events = {};

  // ========== WARNA SISWA ==========
  static const Color _primaryColor = Color(0xFF9f0712); // Merah siswa
  static const Color _yellowColor = Color(0xFFFFB703);
  static const Color _greenColor = Color(0xFF4CAF50);
  static const Color _redColor = Color(0xFFF44336);
  static const Color _blueColor = Color(0xFF2196F3);
  static const Color _purpleColor = Color(0xFF9C27B0);
  static const Color _textSecondary = Color(0xFF666666);
  static const Color _borderColor = Color(0xFFE0E0E0);
  static const Color _pastDayColor = Color(0xFFF5F5F5);
  static const Color _pastDayTextColor = Color(0xFF999999);
  static const Color _textPrimary = Color(0xFF333333);

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _generateCalendar();
    _checkTokenAndLoadData();
  }

  // ========== CHECK TOKEN & LOAD DATA ==========
  Future<void> _checkTokenAndLoadData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.getString('access_token');

    // Untuk demo, kita anggap token selalu ada
    // Jika ingin simulasi login, bisa uncomment kode berikut:
    /*
    if (token == null || token.isEmpty) {
      _redirectToLogin();
      return;
    }
    */

    await Future.delayed(const Duration(milliseconds: 500)); // Simulasi loading
    await _loadDummyData();
  }


  // ========== LOAD DATA DUMMY ==========
  Future<void> _loadDummyData() async {
    setState(() {
      _isCheckingToken = false;
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Simulasi loading
      await Future.delayed(const Duration(seconds: 1));

      // Data dummy kegiatan PKL
      final dummyKegiatan = [
        KegiatanPkl(
          id: 1,
          deskripsi: 'Pembekalan awal PKL untuk semua siswa kelas XII. Materi meliputi tata tertib perusahaan, keselamatan kerja, dan etika kerja.',
          jenisKegiatan: 'Pembekalan',
          tahunAjaranId: 1,
          tanggalMulai: DateTime.now().subtract(const Duration(days: 5)),
          tanggalSelesai: DateTime.now().subtract(const Duration(days: 3)),
          status: 'active',
          createdBy: 1,
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          updatedAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
        KegiatanPkl(
          id: 2,
          deskripsi: 'Monitoring pertama kemajuan siswa di tempat PKL. Pembimbing akan mengunjungi perusahaan mitra.',
          jenisKegiatan: 'Monitoring1',
          tahunAjaranId: 1,
          tanggalMulai: DateTime.now().add(const Duration(days: 2)),
          tanggalSelesai: DateTime.now().add(const Duration(days: 2)),
          status: 'active',
          createdBy: 1,
          createdAt: DateTime.now().subtract(const Duration(days: 8)),
          updatedAt: DateTime.now().subtract(const Duration(days: 8)),
        ),
        KegiatanPkl(
          id: 3,
          deskripsi: 'Kegiatan monitoring kedua untuk evaluasi perkembangan siswa. Fokus pada pencapaian kompetensi.',
          jenisKegiatan: 'Monitoring2',
          tahunAjaranId: 1,
          tanggalMulai: DateTime.now().add(const Duration(days: 15)),
          tanggalSelesai: DateTime.now().add(const Duration(days: 15)),
          status: 'active',
          createdBy: 1,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          updatedAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        KegiatanPkl(
          id: 4,
          deskripsi: 'Penjemputan siswa dari tempat PKL dan pembekalan akhir sebelum presentasi.',
          jenisKegiatan: 'Penjemputan',
          tahunAjaranId: 1,
          tanggalMulai: DateTime.now().add(const Duration(days: 30)),
          tanggalSelesai: DateTime.now().add(const Duration(days: 30)),
          status: 'active',
          createdBy: 1,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          updatedAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        KegiatanPkl(
          id: 5,
          deskripsi: 'Workshop pembuatan laporan PKL dan persiapan presentasi akhir.',
          jenisKegiatan: 'Pembekalan',
          tahunAjaranId: 1,
          tanggalMulai: DateTime.now().add(const Duration(days: 25)),
          tanggalSelesai: DateTime.now().add(const Duration(days: 26)),
          status: 'active',
          createdBy: 1,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        KegiatanPkl(
          id: 6,
          deskripsi: 'Presentasi hasil PKL di depan penguji dan pembimbing.',
          jenisKegiatan: 'Monitoring2',
          tahunAjaranId: 1,
          tanggalMulai: DateTime.now().add(const Duration(days: 35)),
          tanggalSelesai: DateTime.now().add(const Duration(days: 36)),
          status: 'active',
          createdBy: 1,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];

      setState(() {
        _allKegiatan = dummyKegiatan;
        _initializeEvents();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }

  void _initializeEvents() {
    _events.clear();

    for (var kegiatan in _allKegiatan) {
      // Tambahkan event untuk setiap hari dalam rentang tanggal
      DateTime currentDate = kegiatan.tanggalMulai;
      final endDate = kegiatan.tanggalSelesai;

      while (!currentDate.isAfter(endDate)) {
        final dateKey = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
        );

        if (_events.containsKey(dateKey)) {
          _events[dateKey]!.add(kegiatan);
        } else {
          _events[dateKey] = [kegiatan];
        }

        currentDate = currentDate.add(const Duration(days: 1));
      }
    }
  }

  // ========== GENERATE KALENDER ==========
  void _generateCalendar() {
    _currentMonth = DateFormat('MMMM yyyy').format(_currentDate);
    _calendarDays = [];

    final firstDayOfMonth = DateTime(_currentDate.year, _currentDate.month, 1);
    final lastDayOfMonth = DateTime(_currentDate.year, _currentDate.month + 1, 0);
    final int startingWeekday = firstDayOfMonth.weekday % 7;

    final List<DateTime?> currentWeek = [];

    // Tambahkan hari dari bulan sebelumnya
    if (startingWeekday > 0) {
      final previousMonthLastDay = DateTime(_currentDate.year, _currentDate.month, 0);
      for (int i = startingWeekday - 1; i >= 0; i--) {
        final previousDate = DateTime(
          previousMonthLastDay.year,
          previousMonthLastDay.month,
          previousMonthLastDay.day - i,
        );
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

    // Tambahkan hari dari bulan berikutnya
    if (currentWeek.isNotEmpty) {
      int nextMonthDay = 1;
      while (currentWeek.length < 7) {
        final nextDate = DateTime(_currentDate.year, _currentDate.month + 1, nextMonthDay);
        currentWeek.add(nextDate);
        nextMonthDay++;
      }
      _calendarDays.add(currentWeek);
    }
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

  // ========== HELPER FUNCTIONS ==========
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

  bool _isCurrentMonth(DateTime date) {
    return date.year == _currentDate.year && date.month == _currentDate.month;
  }

  bool _hasEvent(DateTime date) {
    return _events.containsKey(DateTime(date.year, date.month, date.day));
  }

  bool _isPastDay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDate = DateTime(date.year, date.month, date.day);
    return checkDate.isBefore(today);
  }

  Color _getJenisColor(String jenis) {
    switch (jenis) {
      case 'Pembekalan':
        return _primaryColor;
      case 'Monitoring1':
        return _greenColor;
      case 'Monitoring2':
        return _blueColor;
      case 'Penjemputan':
        return _purpleColor;
      default:
        return _primaryColor;
    }
  }

  String _getJenisIcon(String jenis) {
    switch (jenis) {
      case 'Pembekalan':
        return '📚';
      case 'Monitoring1':
        return '📋';
      case 'Monitoring2':
        return '📊';
      case 'Penjemputan':
        return '🚌';
      default:
        return '📅';
    }
  }

  String _formatDateForDisplay(DateTime date) {
    return DateFormat('EEEE, dd MMMM yyyy').format(date);
  }

  String _formatDateShort(DateTime date) {
    return DateFormat('dd MMM').format(date);
  }

  List<KegiatanPkl> _getKegiatanForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return _events[dateKey] ?? [];
  }

  // Fungsi untuk mendapatkan jadwal yang akan datang
  List<KegiatanPkl> _getUpcomingKegiatan() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Filter kegiatan yang tanggal selesai >= hari ini
    final List<KegiatanPkl> upcomingKegiatan = _allKegiatan
        .where((kegiatan) => !kegiatan.tanggalSelesai.isBefore(today))
        .toList();

    // Sort by tanggal mulai (ascending)
    upcomingKegiatan.sort((a, b) => a.tanggalMulai.compareTo(b.tanggalMulai));

    return upcomingKegiatan;
  }

  // Fungsi untuk mendapatkan kegiatan pada hari terpilih atau jadwal terdekat
  List<KegiatanPkl> _getDisplayedKegiatan() {
    final dayKegiatan = _getKegiatanForDay(_selectedDate ?? DateTime.now());

    // Jika ada kegiatan pada hari terpilih, tampilkan
    if (dayKegiatan.isNotEmpty) {
      return dayKegiatan;
    }

    // Jika tidak ada, tampilkan jadwal yang akan datang
    return _getUpcomingKegiatan();
  }

  // ========== BUILD WIDGET ==========
  @override
  Widget build(BuildContext context) {
    if (_isCheckingToken) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primaryColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              color: _primaryColor,
            ),
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: _primaryColor,
              ),
              SizedBox(height: 16),
              Text(
                'Memuat jadwal...',
                style: TextStyle(
                  color: _primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: _redColor, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Terjadi kesalahan',
                style: TextStyle(
                  color: _redColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDummyData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDummyData,
          backgroundColor: Colors.white,
          color: _primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // HEADER
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kalender PKL',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF9f0712),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Jadwal Kegiatan Siswa',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                    
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _primaryColor.withValues(alpha:0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _primaryColor.withValues(alpha:0.2),
                              ),
                            ),
                            child: Text(
                              '${_allKegiatan.length} Total Kegiatan',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _greenColor.withValues(alpha:0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _greenColor.withValues(alpha:0.2),
                              ),
                            ),
                            child: Text(
                              '${_getUpcomingKegiatan().length} Akan Datang',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _greenColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // KONTROL BULAN
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNavButton(
                        icon: Icons.chevron_left,
                        onPressed: _goToPreviousMonth,
                      ),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _primaryColor.withValues(alpha:0.05),
                                _primaryColor.withValues(alpha:0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _primaryColor.withValues(alpha:0.2),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _currentMonth.toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF9f0712),
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      _buildNavButton(
                        icon: Icons.chevron_right,
                        onPressed: _goToNextMonth,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // KALENDER
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // HEADER HARI
                      Row(
                        children: ['M', 'S', 'S', 'R', 'K', 'J', 'S'].map((day) {
                          return Expanded(
                            child: Center(
                              child: Text(
                                day,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF666666),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),

                      // HARI-HARI
                      Column(
                        children: _calendarDays.map((week) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: week.map((date) {
                                if (date == null) {
                                  return Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.all(4),
                                      height: 50,
                                    ),
                                  );
                                }

                                final isCurrentMonth = _isCurrentMonth(date);
                                final hasEvent = _hasEvent(date);
                                final isToday = _isToday(date);
                                final isSelected = _isSelected(date);
                                final isPastDay = _isPastDay(date);

                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedDate = date;
                                        if (!isCurrentMonth) {
                                          _currentDate = DateTime(
                                            date.year,
                                            date.month,
                                            1,
                                          );
                                          _generateCalendar();
                                        }
                                      });
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.all(4),
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: isPastDay
                                            ? _pastDayColor
                                            : isSelected
                                                ? _primaryColor
                                                : isToday
                                                    ? _yellowColor.withValues(alpha:0.15)
                                                    : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isPastDay
                                              ? Colors.grey[200]!
                                              : isSelected
                                                  ? _primaryColor
                                                  : isToday
                                                      ? _yellowColor
                                                      : Colors.grey[200]!,
                                          width: isPastDay
                                              ? 1
                                              : isSelected
                                                  ? 2
                                                  : (isToday ? 1.5 : 1),
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: _primaryColor.withValues(alpha:0.3),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // ANGKA TANGGAL
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                date.day.toString(),
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w800
                                                      : FontWeight.w600,
                                                  color: isPastDay
                                                      ? _pastDayTextColor
                                                      : isSelected
                                                          ? Colors.white
                                                          : isCurrentMonth
                                                              ? Colors.black
                                                              : Colors.grey[400],
                                                ),
                                              ),
                                              if (hasEvent && isPastDay)
                                                Container(
                                                  margin: const EdgeInsets.only(top: 2),
                                                  width: 6,
                                                  height: 6,
                                                  decoration: const BoxDecoration(
                                                    color: _pastDayTextColor,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              if (hasEvent && !isPastDay)
                                                Container(
                                                  margin: const EdgeInsets.only(top: 2),
                                                  width: 6,
                                                  height: 6,
                                                  decoration: BoxDecoration(
                                                    color: isSelected
                                                        ? Colors.white
                                                        : _primaryColor,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                            ],
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

                const SizedBox(height: 20),


                // DETAIL HARI TERPILIH
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedDate != null
                                    ? _formatDateForDisplay(_selectedDate!)
                                    : 'Pilih Tanggal',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getKegiatanForDay(_selectedDate ?? DateTime.now()).isEmpty
                                    ? 'Menampilkan jadwal yang akan datang'
                                    : '${_getKegiatanForDay(_selectedDate ?? DateTime.now()).length} kegiatan pada hari ini',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF666666),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getDisplayedKegiatan().isEmpty
                                  ? Colors.grey.withValues(alpha:0.1)
                                  : _greenColor.withValues(alpha:0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _getDisplayedKegiatan().isEmpty
                                    ? Colors.grey.withValues(alpha:0.3)
                                    : _greenColor.withValues(alpha:0.3),
                              ),
                            ),
                            child: Text(
                              '${_getDisplayedKegiatan().length} Kegiatan',
                              style: TextStyle(
                                color: _getDisplayedKegiatan().isEmpty
                                    ? Colors.grey
                                    : _greenColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // LIST KEGIATAN
                      if (_getDisplayedKegiatan().isEmpty)
                        Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _borderColor),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.event_available,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Tidak ada jadwal kegiatan',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Belum ada jadwal kegiatan untuk ditampilkan',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: _getDisplayedKegiatan().map((kegiatan) {
                            final isTodayEvent = _isToday(kegiatan.tanggalMulai);
                            final isPastEvent = _isPastDay(kegiatan.tanggalMulai);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isPastEvent
                                      ? Colors.grey[300]!
                                      : isTodayEvent
                                          ? _primaryColor.withValues(alpha:0.5)
                                          : _getJenisColor(kegiatan.jenisKegiatan)
                                              .withValues(alpha:0.3),
                                  width: isPastEvent ? 1 : 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha:0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // HEADER KEGIATAN
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: _getJenisColor(kegiatan.jenisKegiatan)
                                                .withValues(alpha:isPastEvent ? 0.05 : 0.1),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: _getJenisColor(kegiatan.jenisKegiatan)
                                                  .withValues(alpha:isPastEvent ? 0.1 : 0.3),
                                            ),
                                          ),
                                          child: Text(
                                            _getJenisIcon(kegiatan.jenisKegiatan),
                                            style: const TextStyle(fontSize: 16),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                kegiatan.jenisKegiatan,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: isPastEvent
                                                      ? Colors.grey[600]
                                                      : _getJenisColor(kegiatan.jenisKegiatan),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.calendar_today,
                                                    size: 12,
                                                    color: isPastEvent
                                                        ? Colors.grey[500]
                                                        : _textSecondary,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    _formatDateShort(kegiatan.tanggalMulai),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: isPastEvent
                                                          ? Colors.grey[600]
                                                          : _textSecondary,
                                                    ),
                                                  ),
                                                  if (kegiatan.tanggalSelesai !=
                                                      kegiatan.tanggalMulai)
                                                    Row(
                                                      children: [
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          '- ${_formatDateShort(kegiatan.tanggalSelesai)}',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: isPastEvent
                                                                ? Colors.grey[600]
                                                                : _textSecondary,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isTodayEvent)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _primaryColor.withValues(alpha:0.1),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: _primaryColor.withValues(alpha:0.3),
                                              ),
                                            ),
                                            child: const Text(
                                              'HARI INI',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF9f0712),
                                              ),
                                            ),
                                          ),
                                        if (isPastEvent)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'LEWAT',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // DESKRIPSI
                                    Text(
                                      kegiatan.deskripsi,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: isPastEvent
                                            ? Colors.grey[700]
                                            : _textPrimary,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // DETAIL WAKTU
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.grey[200]!),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'MULAI',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: _textSecondary,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                DateFormat('dd MMM yyyy')
                                                    .format(kegiatan.tanggalMulai),
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: isPastEvent
                                                      ? Colors.grey[600]
                                                      : _textPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            height: 30,
                                            width: 1,
                                            color: Colors.grey[300],
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              const Text(
                                                'SELESAI',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: _textSecondary,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                DateFormat('dd MMM yyyy')
                                                    .format(kegiatan.tanggalSelesai),
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: isPastEvent
                                                      ? Colors.grey[600]
                                                      : _textPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            height: 30,
                                            width: 1,
                                            color: Colors.grey[300],
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              const Text(
                                                'STATUS',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: _textSecondary,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                kegiatan.status == 'active'
                                                    ? 'AKTIF'
                                                    : 'SELESAI',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: kegiatan.status == 'active'
                                                      ? _greenColor
                                                      : Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(icon, color: _primaryColor, size: 22),
        ),
      ),
    );
  }
}

// ========== MODEL KEGIATAN PKL ==========
class KegiatanPkl {
  final int id;
  final String deskripsi;
  final String jenisKegiatan;
  final int tahunAjaranId;
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final String status;
  final int createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  KegiatanPkl({
    required this.id,
    required this.deskripsi,
    required this.jenisKegiatan,
    required this.tahunAjaranId,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });
}