import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../login/login_screen.dart';

class KoordinatorJadwal extends StatefulWidget {
  const KoordinatorJadwal({super.key});

  @override
  State<KoordinatorJadwal> createState() => _KoordinatorJadwalState();
}

class _KoordinatorJadwalState extends State<KoordinatorJadwal> {
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

  // ========== KONFIGURASI API ==========
  final int _tahunAjaranId = 1; // Sesuai dengan contoh API

  // ========== WARNA ==========
  static const Color _primaryColor = Color(0xFF641E20);
  static const Color _yellowColor = Color(0xFFFFB703);
  static const Color _greenColor = Color(0xFF4CAF50);
  static const Color _redColor = Color(0xFFF44336);
  static const Color _blueColor = Color(0xFF2196F3);
  static const Color _purpleColor = Color(0xFF9C27B0);
  static const Color _textSecondary = Color(0xFF666666);
  static const Color _borderColor = Color(0xFFE0E0E0);
  static const Color _pastDayColor =
      Color(0xFFF5F5F5); // Warna lebih terang untuk hari lewat
  static const Color _pastDayTextColor =
      Color(0xFF999999); // Teks abu-abu untuk hari lewat

  // ========== VARIABEL FILTER ==========
  String _selectedFilter = 'SEMUA';
  final List<String> _filterOptions = [
    'SEMUA',
    'Pembekalan',
    'Monitoring1',
    'Monitoring2',
    'Penjemputan'
  ];

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
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      _redirectToLogin();
      return;
    }

    await _fetchKegiatanPkl();
  }

  void _redirectToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    });
  }

  // ========== GENERATE KALENDER ==========
  void _generateCalendar() {
    _currentMonth = DateFormat('MMMM yyyy').format(_currentDate);
    _calendarDays = [];

    final firstDayOfMonth = DateTime(_currentDate.year, _currentDate.month, 1);
    final lastDayOfMonth =
        DateTime(_currentDate.year, _currentDate.month + 1, 0);
    final int startingWeekday = firstDayOfMonth.weekday % 7;

    final List<DateTime?> currentWeek = [];

    // Tambahkan hari dari bulan sebelumnya
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

    // Tambahkan hari dari bulan berikutnya
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

  // ========== API CALLS ==========
  Future<void> _fetchKegiatanPkl() async {
    setState(() {
      _isCheckingToken = false;
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        _redirectToLogin();
        return;
      }

      final response = await http.get(
        Uri.parse(
            '${dotenv.env['API_BASE_URL']}/api/kegiatan-pkl/tahun-ajaran/$_tahunAjaranId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        final List<KegiatanPkl> kegiatanList =
            responseData.map((item) => KegiatanPkl.fromJson(item)).toList();

        setState(() {
          _allKegiatan = kegiatanList;
          _initializeEvents();
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        _redirectToLogin();
      } else {
        throw Exception('Failed to load kegiatan PKL: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _createKegiatanPkl(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        _redirectToLogin();
        return;
      }

      final response = await http.post(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/kegiatan-pkl'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Refresh data setelah berhasil create
        await _fetchKegiatanPkl();
        if (!mounted) return;
        _showSuccessPopup('Kegiatan berhasil ditambahkan');
      } else if (response.statusCode == 401) {
        _redirectToLogin();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            'Failed to create kegiatan: ${errorData['message'] ?? response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorPopup('Gagal menambahkan kegiatan: $e');
    }
  }

  Future<void> _updateKegiatanPkl(int id, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        _redirectToLogin();
        return;
      }

      final response = await http.put(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/kegiatan-pkl/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        await _fetchKegiatanPkl();
        if (!mounted) return;
        _showSuccessPopup('Kegiatan berhasil diperbarui');
      } else if (response.statusCode == 401) {
        _redirectToLogin();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            'Failed to update kegiatan: ${errorData['message'] ?? response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorPopup('Gagal memperbarui kegiatan: $e');
    }
  }

  Future<void> _deleteKegiatanPkl(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        _redirectToLogin();
        return;
      }

      final response = await http.delete(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/kegiatan-pkl/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        await _fetchKegiatanPkl();
        if (!mounted) return;
        _showSuccessPopup('Kegiatan berhasil dihapus');
      } else if (response.statusCode == 401) {
        _redirectToLogin();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            'Failed to delete kegiatan: ${errorData['message'] ?? response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorPopup('Gagal menghapus kegiatan: $e');
    }
  }

  void _initializeEvents() {
    _events.clear();

    for (var kegiatan in _allKegiatan) {
      final dateKey = DateTime(
        kegiatan.tanggalMulai.year,
        kegiatan.tanggalMulai.month,
        kegiatan.tanggalMulai.day,
      );

      if (_events.containsKey(dateKey)) {
        _events[dateKey]!.add(kegiatan);
      } else {
        _events[dateKey] = [kegiatan];
      }
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

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _currentDate = now;
      _selectedDate = now;
      _generateCalendar();
    });
  }

  // ========== HELPER FUNCTIONS FOR POPUPS ==========
  void _showSuccessPopup(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _greenColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: _greenColor,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Berhasil!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: _textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorPopup(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _redColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: _redColor,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Terjadi Kesalahan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: _textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ========== FUNGSI CREATE KEGIATAN ==========
  void _showCreateKegiatanDialog() {
    String deskripsi = '';
    String jenisKegiatan = 'Pembekalan'; // Default sesuai API
    DateTime tanggalMulai = DateTime.now().add(const Duration(days: 1));
    DateTime tanggalSelesai = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: Colors.transparent,
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // HEADER
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: _primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.add_circle,
                              color: _primaryColor,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'BUAT KEGIATAN BARU',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: _primaryColor,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Tambahkan jadwal kegiatan PKL baru',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // TANGGAL MULAI
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                color: _primaryColor,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Tanggal Mulai',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () async {
                              final selectedDate = await showDatePicker(
                                context: context,
                                initialDate: tanggalMulai,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 730)),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: _primaryColor,
                                        onPrimary: Colors.white,
                                        surface: Colors.white,
                                        onSurface: Colors.black,
                                      ),
                                      dialogTheme: DialogThemeData(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        elevation: 10,
                                        backgroundColor: Colors.white,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (selectedDate != null) {
                                setState(() {
                                  tanggalMulai = selectedDate;
                                  if (tanggalSelesai.isBefore(selectedDate)) {
                                    tanggalSelesai = selectedDate;
                                  }
                                });
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _borderColor,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('EEEE, dd MMMM yyyy')
                                        .format(tanggalMulai),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.calendar_month,
                                    color: _primaryColor,
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // TANGGAL SELESAI
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: _primaryColor,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Tanggal Selesai',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () async {
                              final selectedDate = await showDatePicker(
                                context: context,
                                initialDate: tanggalSelesai,
                                firstDate: tanggalMulai,
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 730)),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: _primaryColor,
                                        onPrimary: Colors.white,
                                        surface: Colors.white,
                                        onSurface: Colors.black,
                                      ),
                                      dialogTheme: DialogThemeData(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        elevation: 10,
                                        backgroundColor: Colors.white,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (selectedDate != null) {
                                setState(() {
                                  tanggalSelesai = selectedDate;
                                });
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _borderColor,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('EEEE, dd MMMM yyyy')
                                        .format(tanggalSelesai),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.calendar_month,
                                    color: _primaryColor,
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // JENIS KEGIATAN
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.category_outlined,
                                color: _primaryColor,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Jenis Kegiatan',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _borderColor,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: jenisKegiatan,
                                isExpanded: true,
                                icon: const Padding(
                                  padding: EdgeInsets.only(right: 12),
                                  child: Icon(
                                    Icons.arrow_drop_down,
                                    color: _primaryColor,
                                    size: 24,
                                  ),
                                ),
                                dropdownColor: Colors.white,
                                elevation: 4,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                                items: _filterOptions
                                    .where((item) => item != 'SEMUA')
                                    .map((jenis) {
                                  Color itemColor;
                                  String label;

                                  switch (jenis) {
                                    case 'Pembekalan':
                                      itemColor = _primaryColor;
                                      label = 'Pembekalan';
                                      break;
                                    case 'Monitoring1':
                                      itemColor = _greenColor;
                                      label = 'Monitoring 1';
                                      break;
                                    case 'Monitoring2':
                                      itemColor = _blueColor;
                                      label = 'Monitoring 2';
                                      break;
                                    case 'Penjemputan':
                                      itemColor = _purpleColor;
                                      label = 'Penjemputan';
                                      break;
                                    default:
                                      itemColor = _primaryColor;
                                      label = jenis;
                                  }

                                  return DropdownMenuItem<String>(
                                    value: jenis,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            margin: const EdgeInsets.only(
                                                right: 12),
                                            decoration: BoxDecoration(
                                              color: itemColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          Text(
                                            label,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      jenisKegiatan = value;
                                    });
                                  }
                                },
                                selectedItemBuilder: (context) {
                                  return _filterOptions
                                      .where((item) => item != 'SEMUA')
                                      .map((jenis) {
                                    Color itemColor;
                                    String label;

                                    switch (jenis) {
                                      case 'Pembekalan':
                                        itemColor = _primaryColor;
                                        label = 'Pembekalan';
                                        break;
                                      case 'Monitoring1':
                                        itemColor = _greenColor;
                                        label = 'Monitoring 1';
                                        break;
                                      case 'Monitoring2':
                                        itemColor = _blueColor;
                                        label = 'Monitoring 2';
                                        break;
                                      case 'Penjemputan':
                                        itemColor = _purpleColor;
                                        label = 'Penjemputan';
                                        break;
                                    default:
                                      itemColor = _primaryColor;
                                      label = jenis;
                                    }

                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            margin: const EdgeInsets.only(
                                                right: 12),
                                            decoration: BoxDecoration(
                                              color: itemColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          Text(
                                            label,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // DESKRIPSI
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.description_outlined,
                                color: _primaryColor,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Deskripsi Kegiatan',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _borderColor,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextField(
                              maxLines: 4,
                              minLines: 3,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.all(16),
                                hintText: 'Masukkan deskripsi kegiatan...',
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                              ),
                              onChanged: (value) => deskripsi = value,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // TOMBOL ACTION
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _primaryColor,
                                side: const BorderSide(
                                  color: _primaryColor,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                backgroundColor: Colors.white,
                              ),
                              child: const Text(
                                'BATAL',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (deskripsi.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'Deskripsi tidak boleh kosong',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      backgroundColor: _redColor,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                if (tanggalSelesai.isBefore(tanggalMulai)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'Tanggal selesai harus setelah tanggal mulai',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      backgroundColor: _redColor,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final data = {
                                  'deskripsi': deskripsi,
                                  'jenis_kegiatan': jenisKegiatan,
                                  'tahun_ajaran_id': _tahunAjaranId,
                                  'tanggal_mulai': DateFormat('yyyy-MM-dd')
                                      .format(tanggalMulai),
                                  'tanggal_selesai': DateFormat('yyyy-MM-dd')
                                      .format(tanggalSelesai),
                                };

                                // Show loading
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => const Center(
                                    child: CircularProgressIndicator(
                                      color: _primaryColor,
                                    ),
                                  ),
                                );

                                await _createKegiatanPkl(data);

                                if (mounted) {
                                  Navigator.pop(context); // Close loading
                                  Navigator.pop(context); // Close dialog
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                elevation: 4,
                                shadowColor:
                                    _primaryColor.withValues(alpha: 0.4),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'SIMPAN',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ========== FUNGSI EDIT KEGIATAN ==========
  void _showEditKegiatanDialog(KegiatanPkl kegiatan) {
    String deskripsi = kegiatan.deskripsi;
    String jenisKegiatan = kegiatan.jenisKegiatan;
    DateTime tanggalMulai = kegiatan.tanggalMulai;
    DateTime tanggalSelesai = kegiatan.tanggalSelesai;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: Colors.transparent,
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // HEADER
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: _primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: _primaryColor,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'EDIT KEGIATAN',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: _primaryColor,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Ubah detail kegiatan PKL',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // TANGGAL MULAI
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                color: _primaryColor,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Tanggal Mulai',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () async {
                              final selectedDate = await showDatePicker(
                                context: context,
                                initialDate: tanggalMulai,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 730)),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: _primaryColor,
                                        onPrimary: Colors.white,
                                        surface: Colors.white,
                                        onSurface: Colors.black,
                                      ),
                                      dialogTheme: DialogThemeData(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        elevation: 10,
                                        backgroundColor: Colors.white,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (selectedDate != null) {
                                setState(() {
                                  tanggalMulai = selectedDate;
                                  if (tanggalSelesai.isBefore(selectedDate)) {
                                    tanggalSelesai = selectedDate;
                                  }
                                });
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _borderColor,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('EEEE, dd MMMM yyyy')
                                        .format(tanggalMulai),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.calendar_month,
                                    color: _primaryColor,
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // TANGGAL SELESAI
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: _primaryColor,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Tanggal Selesai',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () async {
                              final selectedDate = await showDatePicker(
                                context: context,
                                initialDate: tanggalSelesai,
                                firstDate: tanggalMulai,
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 730)),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: _primaryColor,
                                        onPrimary: Colors.white,
                                        surface: Colors.white,
                                        onSurface: Colors.black,
                                      ),
                                      dialogTheme: DialogThemeData(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        elevation: 10,
                                        backgroundColor: Colors.white,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (selectedDate != null) {
                                setState(() {
                                  tanggalSelesai = selectedDate;
                                });
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _borderColor,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('EEEE, dd MMMM yyyy')
                                        .format(tanggalSelesai),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.calendar_month,
                                    color: _primaryColor,
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // JENIS KEGIATAN (DIPERBAIKI)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.category_outlined,
                                color: _primaryColor,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Jenis Kegiatan',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _borderColor,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: jenisKegiatan,
                                isExpanded: true,
                                icon: const Padding(
                                  padding: EdgeInsets.only(right: 12),
                                  child: Icon(
                                    Icons.arrow_drop_down,
                                    color: _primaryColor,
                                    size: 24,
                                  ),
                                ),
                                dropdownColor: Colors.white,
                                elevation: 4,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                                items: _filterOptions
                                    .where((item) => item != 'SEMUA')
                                    .map((jenis) {
                                  Color itemColor;
                                  String label;

                                  switch (jenis) {
                                    case 'Pembekalan':
                                      itemColor = _primaryColor;
                                      label = 'Pembekalan';
                                      break;
                                    case 'Monitoring1':
                                      itemColor = _greenColor;
                                      label = 'Monitoring 1';
                                      break;
                                    case 'Monitoring2':
                                      itemColor = _blueColor;
                                      label = 'Monitoring 2';
                                      break;
                                    case 'Penjemputan':
                                      itemColor = _purpleColor;
                                      label = 'Penjemputan';
                                      break;
                                    default:
                                      itemColor = _primaryColor;
                                      label = jenis;
                                  }

                                  return DropdownMenuItem<String>(
                                    value: jenis,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            margin: const EdgeInsets.only(
                                                right: 12),
                                            decoration: BoxDecoration(
                                              color: itemColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          Text(
                                            label,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      jenisKegiatan = value;
                                    });
                                  }
                                },
                                selectedItemBuilder: (context) {
                                  return _filterOptions
                                      .where((item) => item != 'SEMUA')
                                      .map((jenis) {
                                    Color itemColor;
                                    String label;

                                    switch (jenis) {
                                      case 'Pembekalan':
                                        itemColor = _primaryColor;
                                        label = 'Pembekalan';
                                        break;
                                      case 'Monitoring1':
                                        itemColor = _greenColor;
                                        label = 'Monitoring 1';
                                        break;
                                      case 'Monitoring2':
                                        itemColor = _blueColor;
                                        label = 'Monitoring 2';
                                        break;
                                      case 'Penjemputan':
                                        itemColor = _purpleColor;
                                        label = 'Penjemputan';
                                        break;
                                    default:
                                      itemColor = _primaryColor;
                                      label = jenis;
                                    }

                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            margin: const EdgeInsets.only(
                                                right: 12),
                                            decoration: BoxDecoration(
                                              color: itemColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          Text(
                                            label,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // DESKRIPSI
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.description_outlined,
                                color: _primaryColor,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Deskripsi Kegiatan',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _borderColor,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextField(
                              maxLines: 4,
                              minLines: 3,
                              controller:
                                  TextEditingController(text: deskripsi),
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.all(16),
                                hintText: 'Masukkan deskripsi kegiatan...',
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                              ),
                              onChanged: (value) => deskripsi = value,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // TOMBOL ACTION
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _primaryColor,
                                side: const BorderSide(
                                  color: _primaryColor,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                backgroundColor: Colors.white,
                              ),
                              child: const Text(
                                'BATAL',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (deskripsi.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'Deskripsi tidak boleh kosong',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      backgroundColor: _redColor,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                if (tanggalSelesai.isBefore(tanggalMulai)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'Tanggal selesai harus setelah tanggal mulai',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      backgroundColor: _redColor,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final data = {
                                  'deskripsi': deskripsi,
                                  'jenis_kegiatan': jenisKegiatan,
                                  'tahun_ajaran_id': _tahunAjaranId,
                                  'tanggal_mulai': DateFormat('yyyy-MM-dd')
                                      .format(tanggalMulai),
                                  'tanggal_selesai': DateFormat('yyyy-MM-dd')
                                      .format(tanggalSelesai),
                                };

                                // Show loading
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => const Center(
                                    child: CircularProgressIndicator(
                                      color: _primaryColor,
                                    ),
                                  ),
                                );

                                await _updateKegiatanPkl(kegiatan.id, data);

                                if (mounted) {
                                  Navigator.pop(context); // Close loading
                                  Navigator.pop(context); // Close dialog
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                elevation: 4,
                                shadowColor:
                                    _primaryColor.withValues(alpha: 0.4),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'UPDATE',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

// ========== FUNGSI DELETE KEGIATAN ==========
  void _showDeleteConfirmationDialog(KegiatanPkl kegiatan) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: _primaryColor,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Konfirmasi Hapus',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Apakah Anda yakin ingin menghapus kegiatan:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: _textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _primaryColor.withValues(alpha: 0.1)),
                  ),
                  child: Text(
                    '"${kegiatan.deskripsi}"',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _primaryColor,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryColor,
                          side: const BorderSide(
                            color: _primaryColor,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.white,
                        ),
                        child: const Text(
                          'BATAL',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context); // Close confirmation dialog
                          
                          // Show loading
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                              child: CircularProgressIndicator(
                                color: _primaryColor,
                              ),
                            ),
                          );

                          try {
                            await _deleteKegiatanPkl(kegiatan.id);
                          } finally {
                            if (mounted) {
                              Navigator.pop(context); // Close loading
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 2,
                        ),
                        child: const Text(
                          'HAPUS',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
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
      },
    );
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

  // Fungsi untuk mengecek apakah hari sudah lewat
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return _greenColor;
      case 'completed':
        return _blueColor;
      case 'pending':
        return _yellowColor;
      default:
        return _primaryColor;
    }
  }

  String _formatDateForDisplay(DateTime date) {
    return DateFormat('EEEE, dd MMMM yyyy').format(date);
  }

  List<KegiatanPkl> _getKegiatanForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    final dayKegiatan = _events[dateKey] ?? [];

    if (_selectedFilter == 'SEMUA') {
      return dayKegiatan;
    }

    return dayKegiatan
        .where((kegiatan) => kegiatan.jenisKegiatan == _selectedFilter)
        .toList();
  }

  // Fungsi baru: Mendapatkan jadwal yang akan datang
  List<KegiatanPkl> _getUpcomingKegiatan() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Filter kegiatan yang tanggal mulai >= hari ini
    List<KegiatanPkl> upcomingKegiatan = _allKegiatan
        .where((kegiatan) => DateTime(kegiatan.tanggalMulai.year,
                kegiatan.tanggalMulai.month, kegiatan.tanggalMulai.day)
            .isAfter(
                today.subtract(const Duration(days: 1)))) // termasuk hari ini
        .toList();

    // Sort by tanggal mulai (ascending)
    upcomingKegiatan.sort((a, b) => a.tanggalMulai.compareTo(b.tanggalMulai));

    // Apply filter
    if (_selectedFilter != 'SEMUA') {
      upcomingKegiatan = upcomingKegiatan
          .where((kegiatan) => kegiatan.jenisKegiatan == _selectedFilter)
          .toList();
    }

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
          child: CircularProgressIndicator(
            color: _primaryColor,
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
              Text(
                _errorMessage,
                style: const TextStyle(color: _redColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchKegiatanPkl,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
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
      floatingActionButton: Container(
        margin: const EdgeInsets.only(top: 650), // FAB lebih ke atas
        child: FloatingActionButton(
          onPressed: _showCreateKegiatanDialog,
          backgroundColor: _primaryColor,
          elevation: 4,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchKegiatanPkl,
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
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kalender Kegiatan',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF641E20),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'PKL Tahun Ajaran 2026',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: _goToToday,
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: _primaryColor.withValues(
                                            alpha: 0.3)),
                                  ),
                                  child: const Icon(Icons.today,
                                      color: _primaryColor, size: 20),
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
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: _primaryColor.withValues(alpha: 0.2)),
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
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _greenColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: _greenColor.withValues(alpha: 0.2)),
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
                        color: Colors.black.withValues(alpha: 0.08),
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
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16), // ← Tambahkan ini
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _primaryColor.withValues(alpha: 0.05),
                                _primaryColor.withValues(alpha: 0.05)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: _primaryColor.withValues(alpha: 0.2)),
                          ),
                          child: Center(
                            child: Text(
                              _currentMonth.toUpperCase(),
                              style: const TextStyle(
                                color: _primaryColor,
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
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // HEADER HARI
                      Row(
                        children:
                            ['M', 'S', 'S', 'R', 'K', 'J', 'S'].map((day) {
                          return Expanded(
                            child: Center(
                              child: Text(
                                day,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: _textSecondary,
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
                                              date.year, date.month, 1);
                                          _generateCalendar();
                                        }
                                      });
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.all(4),
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: isPastDay
                                            ? _pastDayColor // Background abu-abu terang untuk hari lewat
                                            : isSelected
                                                ? _primaryColor
                                                : isToday
                                                    ? _yellowColor.withValues(
                                                        alpha: 0.15)
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
                                                  color: _primaryColor
                                                      .withValues(alpha: 0.3),
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
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                date.day.toString(),
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w800
                                                      : FontWeight.w600,
                                                  color: isPastDay
                                                      ? _pastDayTextColor // Teks abu-abu untuk hari lewat
                                                      : isSelected
                                                          ? Colors.white
                                                          : isCurrentMonth
                                                              ? Colors.black
                                                              : Colors
                                                                  .grey[400],
                                                ),
                                              ),
                                              // Tanda event untuk hari lewat juga
                                              if (hasEvent && isPastDay)
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                      top: 2),
                                                  width: 6,
                                                  height: 6,
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: _pastDayTextColor,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              // Tanda event untuk hari yang belum lewat
                                              if (hasEvent && !isPastDay)
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                      top: 2),
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

                // FILTER SECTION
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filter Jenis Kegiatan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF641E20),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _filterOptions.map((filter) {
                            final isSelected = _selectedFilter == filter;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedFilter = filter;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _getJenisColor(filter)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? _getJenisColor(filter)
                                        : _borderColor,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: _getJenisColor(filter)
                                                .withValues(alpha: 0.3),
                                            blurRadius: 6,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    if (filter != 'SEMUA')
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(right: 6),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.white
                                              : _getJenisColor(filter),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    Text(
                                      filter,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black,
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
                        color: Colors.black.withValues(alpha: 0.08),
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
                                _getKegiatanForDay(
                                            _selectedDate ?? DateTime.now())
                                        .isEmpty
                                    ? 'Menampilkan jadwal yang akan datang'
                                    : '${_getKegiatanForDay(_selectedDate ?? DateTime.now()).length} kegiatan pada hari ini',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _textSecondary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getDisplayedKegiatan().isEmpty
                                  ? Colors.grey.withValues(alpha: 0.1)
                                  : _greenColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _getDisplayedKegiatan().isEmpty
                                    ? Colors.grey.withValues(alpha: 0.3)
                                    : _greenColor.withValues(alpha: 0.3),
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

                      // LIST KEGIATAN (selalu ada, minimal jadwal yang akan datang)
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
                              Text(
                                _selectedFilter == 'SEMUA'
                                    ? 'Belum ada jadwal yang dijadwalkan'
                                    : 'Belum ada jadwal ${_selectedFilter.toLowerCase()}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
// Di bagian LIST KEGIATAN, ganti bagian ini:
                      else
                        Column(
                          children: _getDisplayedKegiatan().map((kegiatan) {
                            final isPastEvent =
                                kegiatan.tanggalMulai.isBefore(DateTime.now());

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isPastEvent
                                      ? Colors.grey[300]!
                                      : _getJenisColor(kegiatan.jenisKegiatan)
                                          .withValues(alpha: 0.3),
                                  width: isPastEvent ? 1 : 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
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
                                    // Bagian atas kartu (sama seperti sebelumnya)
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getJenisColor(
                                                    kegiatan.jenisKegiatan)
                                                .withValues(
                                                    alpha: isPastEvent
                                                        ? 0.05
                                                        : 0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: _getJenisColor(
                                                      kegiatan.jenisKegiatan)
                                                  .withValues(
                                                      alpha: isPastEvent
                                                          ? 0.1
                                                          : 0.3),
                                            ),
                                          ),
                                          child: Text(
                                            kegiatan.jenisKegiatan,
                                            style: TextStyle(
                                              color: isPastEvent
                                                  ? Colors.grey[600]
                                                  : _getJenisColor(
                                                      kegiatan.jenisKegiatan),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color:
                                                _getStatusColor(kegiatan.status)
                                                    .withValues(
                                                        alpha: isPastEvent
                                                            ? 0.05
                                                            : 0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: _getStatusColor(
                                                      kegiatan.status)
                                                  .withValues(
                                                      alpha: isPastEvent
                                                          ? 0.1
                                                          : 0.3),
                                            ),
                                          ),
                                          child: Text(
                                            isPastEvent
                                                ? 'Selesai'
                                                : kegiatan.status,
                                            style: TextStyle(
                                              color: isPastEvent
                                                  ? Colors.grey[600]
                                                  : _getStatusColor(
                                                      kegiatan.status),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      kegiatan.deskripsi,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: isPastEvent
                                            ? Colors.grey[700]
                                            : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today,
                                            size: 16,
                                            color: isPastEvent
                                                ? Colors.grey[500]
                                                : _textSecondary),
                                        const SizedBox(width: 6),
                                        Text(
                                          DateFormat('dd MMM yyyy')
                                              .format(kegiatan.tanggalMulai),
                                          style: TextStyle(
                                            color: isPastEvent
                                                ? Colors.grey[600]
                                                : _textSecondary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (kegiatan.tanggalSelesai !=
                                            kegiatan.tanggalMulai)
                                          Row(
                                            children: [
                                              const SizedBox(width: 8),
                                              Text('-',
                                                  style: TextStyle(
                                                      color: isPastEvent
                                                          ? Colors.grey[500]
                                                          : _textSecondary)),
                                              const SizedBox(width: 8),
                                              Text(
                                                DateFormat('dd MMM yyyy')
                                                    .format(kegiatan
                                                        .tanggalSelesai),
                                                style: TextStyle(
                                                  color: isPastEvent
                                                      ? Colors.grey[600]
                                                      : _textSecondary,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        if (isPastEvent)
                                          Container(
                                            margin:
                                                const EdgeInsets.only(left: 8),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Lewat',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // TOMBOL EDIT DAN HAPUS DENGAN WARNA PRIMARY
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () {
                                              _showEditKegiatanDialog(kegiatan);
                                            },
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: _primaryColor,
                                              side: BorderSide(
                                                color: _primaryColor.withValues(
                                                    alpha: 0.3),
                                                width: 1.5,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10),
                                              backgroundColor: _primaryColor
                                                  .withValues(alpha: 0.05),
                                            ),
                                            child: const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.edit, size: 16),
                                                SizedBox(width: 6),
                                                Text(
                                                  'EDIT',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () {
                                              _showDeleteConfirmationDialog(
                                                  kegiatan);
                                            },
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: _primaryColor,
                                              side: BorderSide(
                                                color: _primaryColor.withValues(
                                                    alpha: 0.3),
                                                width: 1.5,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10),
                                              backgroundColor: _primaryColor
                                                  .withValues(alpha: 0.05),
                                            ),
                                            child: const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.delete, size: 16),
                                                SizedBox(width: 6),
                                                Text(
                                                  'HAPUS',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
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

                const SizedBox(height: 80),
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
              color: Colors.black.withValues(alpha: 0.05),
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

  factory KegiatanPkl.fromJson(Map<String, dynamic> json) {
    return KegiatanPkl(
      id: json['id'],
      deskripsi: json['deskripsi'],
      jenisKegiatan: json['jenis_kegiatan'],
      tahunAjaranId: json['tahun_ajaran_id'],
      tanggalMulai: DateTime.parse(json['tanggal_mulai']),
      tanggalSelesai: DateTime.parse(json['tanggal_selesai']),
      status: json['status'],
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deskripsi': deskripsi,
      'jenis_kegiatan': jenisKegiatan,
      'tahun_ajaran_id': tahunAjaranId,
      'tanggal_mulai': tanggalMulai.toIso8601String(),
      'tanggal_selesai': tanggalSelesai.toIso8601String(),
      'status': status,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}