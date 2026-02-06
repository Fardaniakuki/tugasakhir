import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

// ========== THEME CONFIGURATION ==========
class KalenderTheme {
  // Warna Utama
  static const Color primaryRed = Color(0xFFB41004);
  static const Color primaryDark = Color(0xFF8A0C03);
  
  // Background & Surface
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  
  // Text Colors
  static const Color textDark = Color(0xFF2D3748);
  static const Color textGrey = Color(0xFF718096);
  static const Color textLight = Color(0xFFA0AEC0);
  
  // Borders
  static const Color border = Color(0xFFE2E8F0);
  
  // Status Colors
  static const Color green = Color(0xFF38A169);
  static const Color orange = Color(0xFFDD6B20);
  static const Color blue = Color(0xFF3182CE);
  static const Color purple = Color(0xFF805AD5);
}

class SiswaKalender extends StatefulWidget {
  const SiswaKalender({super.key});

  @override
  State<SiswaKalender> createState() => _SiswaKalenderState();
}

class _SiswaKalenderState extends State<SiswaKalender> {
  DateTime _tanggalSekarang = DateTime.now();
  DateTime _tanggalTerpilih = DateTime.now();
  late List<List<DateTime?>> _hariKalender;
  late String _bulanSekarang;

  bool _sedangMemuat = true;
  List<KegiatanPkl> _semuaKegiatan = [];
  final Map<DateTime, List<KegiatanPkl>> _acara = {};
  bool _dateFormatInitialized = false;

  @override
  void initState() {
    super.initState();
    _initDateFormatting();
  }

  Future<void> _initDateFormatting() async {
    try {
      await initializeDateFormatting('id_ID', null);
    } catch (e) {
      debugPrint('Error initializing date formatting: $e');
    } finally {
      if (mounted) {
        setState(() {
          _dateFormatInitialized = true;
          _buatKalender();
        });
        _muatDataContoh();
      }
    }
  }

  Future<void> _muatDataContoh() async {
    setState(() => _sedangMemuat = true);
    await Future.delayed(const Duration(milliseconds: 800)); 

    final DateTime now = DateTime.now();
    final List<KegiatanPkl> contohKegiatan = [
      KegiatanPkl(
        id: 1,
        judul: 'Pembekalan PKL',
        deskripsi: 'Materi SOP dan K3.',
        jenis: 'Pembekalan',
        warna: KalenderTheme.orange,
        mulai: now.subtract(const Duration(days: 5)),
        selesai: now.subtract(const Duration(days: 5)),
      ),
      KegiatanPkl(
        id: 2,
        judul: 'Monitoring #1',
        deskripsi: 'Kunjungan Bpk. Budi Santoso.',
        jenis: 'Monitoring',
        warna: KalenderTheme.purple,
        mulai: now,
        selesai: now,
      ),
      KegiatanPkl(
        id: 3,
        judul: 'Monirtoring #2',
        deskripsi: 'Kunjungan Bpk. Budi Santoso.',
        jenis: 'Monitoring',
        warna: KalenderTheme.blue,
        mulai: now.add(const Duration(days: 2)),
        selesai: now.add(const Duration(days: 2)),
      ),
      KegiatanPkl(
        id: 4,
        judul: 'Monitoring Guru #3',
        deskripsi: 'Evaluasi pertengahan.',
        jenis: 'Monitoring',
        warna: KalenderTheme.purple,
        mulai: now.add(const Duration(days: 10)),
        selesai: now.add(const Duration(days: 10)),
      ),
      KegiatanPkl(
        id: 5,
        judul: 'Penjemputan PKL',
        deskripsi: 'Penarikan siswa dari industri.',
        jenis: 'Penjemputan',
        warna: KalenderTheme.green,
        mulai: now.add(const Duration(days: 25)),
        selesai: now.add(const Duration(days: 25)),
      ),
    ];

    if (mounted) {
      setState(() {
        _semuaKegiatan = contohKegiatan;
        _inisialisasiAcara();
        _sedangMemuat = false;
      });
    }
  }

  void _inisialisasiAcara() {
    _acara.clear();
    for (final k in _semuaKegiatan) {
      final DateTime key = DateTime(k.mulai.year, k.mulai.month, k.mulai.day);
      if (_acara.containsKey(key)) {
        _acara[key]!.add(k);
      } else {
        _acara[key] = [k];
      }
    }
  }

  void _buatKalender() {
    try {
      _bulanSekarang = DateFormat('MMMM yyyy', 'id_ID').format(_tanggalSekarang);
    } catch (_) {
      _bulanSekarang = DateFormat('MMMM yyyy').format(_tanggalSekarang);
    }
    
    _hariKalender = [];
    final DateTime firstDay = DateTime(_tanggalSekarang.year, _tanggalSekarang.month, 1);
    final DateTime lastDay = DateTime(_tanggalSekarang.year, _tanggalSekarang.month + 1, 0);
    final int weekdayOffset = firstDay.weekday % 7; 
    
    final List<DateTime?> minggu = [];
    for (int i = 0; i < weekdayOffset; i++) {
      minggu.add(null);
    }
    
    for (int i = 1; i <= lastDay.day; i++) {
      minggu.add(DateTime(_tanggalSekarang.year, _tanggalSekarang.month, i));
      if (minggu.length == 7) {
        _hariKalender.add(List.from(minggu));
        minggu.clear();
      }
    }
    
    if (minggu.isNotEmpty) {
      while (minggu.length < 7) {
        minggu.add(null);
      }
      _hariKalender.add(minggu);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_dateFormatInitialized || _sedangMemuat) {
      return const Scaffold(
        backgroundColor: KalenderTheme.background,
        body: Center(child: CircularProgressIndicator(color: KalenderTheme.primaryRed)),
      );
    }

    // Logic: Tampilkan kegiatan hari ini, jika kosong tampilkan yang akan datang
    final DateTime todayKey = DateTime(_tanggalTerpilih.year, _tanggalTerpilih.month, _tanggalTerpilih.day);
    List<KegiatanPkl> displayEvents = _acara[todayKey] ?? [];
    bool isUpcoming = false;

    if (displayEvents.isEmpty) {
      displayEvents = _semuaKegiatan.where((k) => k.mulai.isAfter(_tanggalTerpilih)).toList();
      displayEvents.sort((a, b) => a.mulai.compareTo(b.mulai));
      if (displayEvents.length > 5) {
        displayEvents = displayEvents.sublist(0, 5);
      }
      isUpcoming = true;
    }

    return Scaffold(
      backgroundColor: KalenderTheme.background,
      body: Stack(
        children: [
          // 1. BACKGROUND HEADER (Fixed)
          Positioned(
            top: 0, left: 0, right: 0,
            height: 250, 
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [KalenderTheme.primaryRed, KalenderTheme.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
            ),
          ),

          // 2. MAIN LAYOUT
          SafeArea(
            child: Column(
              children: [
                // === BAGIAN ATAS (TIDAK SCROLL) ===
                _buildHeaderContent(),
                
                // Kalender Card (Tetap diam di atas)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildCalendarCard(),
                ),
                
                const SizedBox(height: 16),
                
                // Stats Singkat
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildQuickStats(),
                ),

                const SizedBox(height: 20),

                // === BAGIAN BAWAH (LIST BISA SCROLL) ===
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: KalenderTheme.background,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Judul Section List
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 4, height: 20,
                                decoration: BoxDecoration(
                                  color: KalenderTheme.primaryRed,
                                  borderRadius: BorderRadius.circular(2)
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                isUpcoming ? 'Agenda Mendatang' : 'Agenda Tanggal Ini',
                                style: const TextStyle(
                                  fontSize: 16, 
                                  fontWeight: FontWeight.bold, 
                                  color: KalenderTheme.textDark
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // List Agenda
                        Expanded(
                          child: displayEvents.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                physics: const BouncingScrollPhysics(),
                                itemCount: displayEvents.length,
                                itemBuilder: (context, index) {
                                  return _buildTimelineItem(
                                    displayEvents[index], 
                                    isFirst: index == 0, 
                                    isLast: index == displayEvents.length - 1
                                  );
                                },
                              ),
                        ),
                      ],
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

  // --- WIDGETS KOMPONEN ---

  // 1. Header (Judul Saja, Tanpa Navigasi)
  Widget _buildHeaderContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kalender Kegiatan',
                style: TextStyle(
                  fontSize: 22, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Jadwal & Agenda PKL',
                style: TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),
          // Icon Dekoratif
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_month_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // 2. Calendar Card (Dengan Navigasi Bulan di Dalamnya)
  Widget _buildCalendarCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: KalenderTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // NAVIGASI BULAN (DIPINDAH KE SINI)
          _buildMonthNavigator(),
          
          const SizedBox(height: 8),
          
          // HEADER HARI
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['M', 'S', 'S', 'R', 'K', 'J', 'S'].map((day) => 
              SizedBox(
                width: 32,
                child: Center(
                  child: Text(day, style: const TextStyle(fontWeight: FontWeight.bold, color: KalenderTheme.textGrey, fontSize: 11)),
                ),
              )
            ).toList(),
          ),
          
          const SizedBox(height: 8),
          const Divider(height: 1, color: KalenderTheme.border),
          const SizedBox(height: 8),
          
          // GRID TANGGAL
          Column(
            children: _hariKalender.map((week) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: week.map((date) => _buildDayCell(date)).toList(),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Widget Navigasi Bulan (Style Gelap untuk Background Putih)
  Widget _buildMonthNavigator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: const Icon(Icons.chevron_left_rounded, color: KalenderTheme.textDark),
          onPressed: () {
            setState(() {
              _tanggalSekarang = DateTime(_tanggalSekarang.year, _tanggalSekarang.month - 1);
              _buatKalender();
            });
          },
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: KalenderTheme.background,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _bulanSekarang.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: KalenderTheme.primaryRed, letterSpacing: 0.5),
          ),
        ),
        IconButton(
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: const Icon(Icons.chevron_right_rounded, color: KalenderTheme.textDark),
          onPressed: () {
            setState(() {
              _tanggalSekarang = DateTime(_tanggalSekarang.year, _tanggalSekarang.month + 1);
              _buatKalender();
            });
          },
        ),
      ],
    );
  }

  Widget _buildDayCell(DateTime? date) {
    if (date == null) return const SizedBox(width: 32, height: 32);

    final bool isSelected = _isSameDay(date, _tanggalTerpilih);
    final bool isToday = _isSameDay(date, DateTime.now());
    final bool hasEvent = _acara.containsKey(DateTime(date.year, date.month, date.day));

    return GestureDetector(
      onTap: () => setState(() => _tanggalTerpilih = date),
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: isSelected ? KalenderTheme.primaryRed : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isToday && !isSelected ? Border.all(color: KalenderTheme.primaryRed, width: 1) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : (isToday ? KalenderTheme.primaryRed : KalenderTheme.textDark),
                fontSize: 13,
              ),
            ),
            if (hasEvent && !isSelected)
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 4, height: 4,
                decoration: const BoxDecoration(color: KalenderTheme.orange, shape: BoxShape.circle),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(child: _buildStatItem('Total', '${_semuaKegiatan.length}', Icons.assignment, KalenderTheme.blue)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatItem('Bulan Ini', '${_acara.length}', Icons.calendar_month, KalenderTheme.purple)),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: KalenderTheme.textDark)),
              Text(label, style: const TextStyle(fontSize: 10, color: KalenderTheme.textGrey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(KegiatanPkl event, {required bool isFirst, required bool isLast}) {
    final String dayStr = DateFormat('dd').format(event.mulai);
    final String monthStr = DateFormat('MMM').format(event.mulai);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Badge
          SizedBox(
            width: 45,
            child: Column(
              children: [
                Text(dayStr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: KalenderTheme.textDark)),
                Text(monthStr, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: KalenderTheme.textGrey)),
              ],
            ),
          ),
          
          // Timeline Line
          Column(
            children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  color: event.warna,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [BoxShadow(color: event.warna.withValues(alpha: 0.4), blurRadius: 4)]
                ),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: isLast ? Colors.transparent : KalenderTheme.border,
                ),
              ),
            ],
          ),
          
          const SizedBox(width: 12),

          // Card Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: event.warna.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          event.jenis.toUpperCase(),
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: event.warna),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.judul,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: KalenderTheme.textDark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.deskripsi,
                    style: const TextStyle(fontSize: 12, color: KalenderTheme.textGrey, height: 1.3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: KalenderTheme.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.event_available_rounded, size: 32, color: KalenderTheme.textLight),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tidak ada agenda',
              style: TextStyle(color: KalenderTheme.textGrey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pilih tanggal lain atau cek agenda mendatang.',
              textAlign: TextAlign.center,
              style: TextStyle(color: KalenderTheme.textLight, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// ========== MODEL DATA ==========
class KegiatanPkl {
  final int id;
  final String judul;
  final String deskripsi;
  final String jenis;
  final Color warna;
  final DateTime mulai;
  final DateTime selesai;

  KegiatanPkl({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.jenis,
    required this.warna,
    required this.mulai,
    required this.selesai,
  });
}