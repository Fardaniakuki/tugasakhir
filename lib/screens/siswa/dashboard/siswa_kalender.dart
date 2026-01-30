import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Pastikan ini diimpor
import 'package:shared_preferences/shared_preferences.dart';

class SiswaKalender extends StatefulWidget {
  const SiswaKalender({super.key});

  @override
  State<SiswaKalender> createState() => _SiswaKalenderState();
}

class _SiswaKalenderState extends State<SiswaKalender> {
  // ========== VARIABEL UTAMA ==========
  DateTime _tanggalSekarang = DateTime.now();
  DateTime? _tanggalTerpilih;
  late List<List<DateTime?>> _hariKalender;
  late String _bulanSekarang;

  // ========== MANAJEMEN STATE ==========
  bool _sedangMemuat = true;
  bool _sedangMemeriksaToken = true;
  String _pesanError = '';
  List<KegiatanPkl> _semuaKegiatan = [];
  final Map<DateTime, List<KegiatanPkl>> _acara = {};

  // ========== WARNA SISWA ==========
  static const Color _warnaUtama = Color(0xFF9f0712); // Merah siswa
  static const Color _warnaKuning = Color(0xFFFFB703);
  static const Color _warnaHijau = Color(0xFF4CAF50);
  static const Color _warnaMerah = Color(0xFFF44336);
  static const Color _warnaBiru = Color(0xFF2196F3);
  static const Color _warnaUngu = Color(0xFF9C27B0);
  static const Color _teksSekunder = Color(0xFF666666);
  static const Color _warnaBatas = Color(0xFFE0E0E0);
  static const Color _warnaHariLalu = Color(0xFFF5F5F5);
  static const Color _warnaTeksHariLalu = Color(0xFF999999);
  static const Color _teksPrimer = Color(0xFF333333);

  bool _dateFormatInitialized = false;

  @override
  void initState() {
    super.initState();
    _initDateFormatting();
    _tanggalTerpilih = DateTime.now();
  }

  // ========== INISIALISASI DATE FORMATTING ==========
  Future<void> _initDateFormatting() async {
    try {
      // Inisialisasi date formatting untuk locale Indonesia
      await initializeDateFormatting('id_ID', null);
      setState(() {
        _dateFormatInitialized = true;
      });
      _buatKalender();
      _periksaTokenDanMuatData();
    } catch (e) {
      print('Error initializing date formatting: $e');
      // Fallback ke locale default jika ada error
      setState(() {
        _dateFormatInitialized = true;
      });
      _buatKalender();
      _periksaTokenDanMuatData();
    }
  }

  // ========== PERIKSA TOKEN & MUAT DATA ==========
  Future<void> _periksaTokenDanMuatData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.getString('access_token');

    // Untuk demo, kita anggap token selalu ada
    await Future.delayed(const Duration(milliseconds: 500));
    await _muatDataContoh();
  }

  // ========== FUNGSI UNTUK MENGECEK STATUS KEGIATAN ==========
  String _dapatkanStatusKegiatan(KegiatanPkl kegiatan) {
    final sekarang = DateTime.now();
    final hariIni = DateTime(sekarang.year, sekarang.month, sekarang.day);
    final tanggalSelesai = DateTime(
      kegiatan.tanggalSelesai.year,
      kegiatan.tanggalSelesai.month,
      kegiatan.tanggalSelesai.day,
    );
    
    // Jika tanggal selesai sudah lewat dari hari ini, statusnya "selesai"
    if (tanggalSelesai.isBefore(hariIni)) {
      return 'selesai';
    }
    
    // Jika tanggal mulai belum tiba, statusnya "akan datang"
    final tanggalMulai = DateTime(
      kegiatan.tanggalMulai.year,
      kegiatan.tanggalMulai.month,
      kegiatan.tanggalMulai.day,
    );
    if (tanggalMulai.isAfter(hariIni)) {
      return 'akan datang';
    }
    
    // Jika sedang berlangsung (antara tanggal mulai dan selesai)
    return 'aktif';
  }

  // ========== MUAT DATA CONTOH ==========
  Future<void> _muatDataContoh() async {
    setState(() {
      _sedangMemeriksaToken = false;
      _sedangMemuat = true;
      _pesanError = '';
    });

    try {
      // Simulasi loading
      await Future.delayed(const Duration(seconds: 1));

      // Data contoh kegiatan PKL dengan tanggal yang lebih realistis
      final contohKegiatan = [
        KegiatanPkl(
          id: 1,
          deskripsi: 'Pembekalan awal PKL untuk semua siswa kelas XII. Materi meliputi tata tertib perusahaan, keselamatan kerja, dan etika kerja.',
          jenisKegiatan: 'Pembekalan',
          tahunAjaranId: 1,
          tanggalMulai: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day - 10),
          tanggalSelesai: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day - 8),
          dibuatOleh: 1,
          dibuatPada: DateTime.now().subtract(const Duration(days: 20)),
          diperbaruiPada: DateTime.now().subtract(const Duration(days: 20)),
        ),
        KegiatanPkl(
          id: 2,
          deskripsi: 'Monitoring pertama kemajuan siswa di tempat PKL. Pembimbing akan mengunjungi perusahaan mitra.',
          jenisKegiatan: 'Monitoring 1',
          tahunAjaranId: 1,
          tanggalMulai: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day + 2),
          tanggalSelesai: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day + 2),
          dibuatOleh: 1,
          dibuatPada: DateTime.now().subtract(const Duration(days: 15)),
          diperbaruiPada: DateTime.now().subtract(const Duration(days: 15)),
        ),
        KegiatanPkl(
          id: 3,
          deskripsi: 'Kegiatan monitoring kedua untuk evaluasi perkembangan siswa. Fokus pada pencapaian kompetensi.',
          jenisKegiatan: 'Monitoring 2',
          tahunAjaranId: 1,
          tanggalMulai: DateTime(DateTime.now().year, DateTime.now().month + 1, 5),
          tanggalSelesai: DateTime(DateTime.now().year, DateTime.now().month + 1, 5),
          dibuatOleh: 1,
          dibuatPada: DateTime.now().subtract(const Duration(days: 10)),
          diperbaruiPada: DateTime.now().subtract(const Duration(days: 10)),
        ),
        KegiatanPkl(
          id: 4,
          deskripsi: 'Penjemputan siswa dari tempat PKL dan pembekalan akhir sebelum presentasi.',
          jenisKegiatan: 'Penjemputan',
          tahunAjaranId: 1,
          tanggalMulai: DateTime(DateTime.now().year, DateTime.now().month + 1, 25),
          tanggalSelesai: DateTime(DateTime.now().year, DateTime.now().month + 1, 25),
          dibuatOleh: 1,
          dibuatPada: DateTime.now().subtract(const Duration(days: 5)),
          diperbaruiPada: DateTime.now().subtract(const Duration(days: 5)),
        ),
        KegiatanPkl(
          id: 5,
          deskripsi: 'Workshop pembuatan laporan PKL dan persiapan presentasi akhir.',
          jenisKegiatan: 'Workshop Laporan',
          tahunAjaranId: 1,
          tanggalMulai: DateTime(DateTime.now().year, DateTime.now().month + 1, 20),
          tanggalSelesai: DateTime(DateTime.now().year, DateTime.now().month + 1, 21),
          dibuatOleh: 1,
          dibuatPada: DateTime.now().subtract(const Duration(days: 3)),
          diperbaruiPada: DateTime.now().subtract(const Duration(days: 3)),
        ),
        KegiatanPkl(
          id: 6,
          deskripsi: 'Presentasi hasil PKL di depan penguji dan pembimbing.',
          jenisKegiatan: 'Presentasi Akhir',
          tahunAjaranId: 1,
          tanggalMulai: DateTime(DateTime.now().year, DateTime.now().month + 2, 1),
          tanggalSelesai: DateTime(DateTime.now().year, DateTime.now().month + 2, 2),
          dibuatOleh: 1,
          dibuatPada: DateTime.now().subtract(const Duration(days: 1)),
          diperbaruiPada: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];

      setState(() {
        _semuaKegiatan = contohKegiatan;
        _inisialisasiAcara();
        _sedangMemuat = false;
      });
    } catch (e) {
      setState(() {
        _pesanError = 'Error memuat data: $e';
        _sedangMemuat = false;
      });
    }
  }

  void _inisialisasiAcara() {
    _acara.clear();

    for (var kegiatan in _semuaKegiatan) {
      // Tambahkan acara untuk setiap hari dalam rentang tanggal
      DateTime tanggalSekarang = kegiatan.tanggalMulai;
      final tanggalAkhir = kegiatan.tanggalSelesai;

      while (!tanggalSekarang.isAfter(tanggalAkhir)) {
        final kunciTanggal = DateTime(
          tanggalSekarang.year,
          tanggalSekarang.month,
          tanggalSekarang.day,
        );

        if (_acara.containsKey(kunciTanggal)) {
          _acara[kunciTanggal]!.add(kegiatan);
        } else {
          _acara[kunciTanggal] = [kegiatan];
        }

        tanggalSekarang = tanggalSekarang.add(const Duration(days: 1));
      }
    }
  }

  // ========== BUAT KALENDER ==========
  void _buatKalender() {
    // Set locale ke Indonesia untuk format bulan
    try {
      _bulanSekarang = DateFormat('MMMM yyyy', 'id_ID').format(_tanggalSekarang);
    } catch (e) {
      // Fallback ke locale default jika ada error
      _bulanSekarang = DateFormat('MMMM yyyy').format(_tanggalSekarang);
    }
    
    _hariKalender = [];

    final hariPertamaBulan = DateTime(_tanggalSekarang.year, _tanggalSekarang.month, 1);
    final hariTerakhirBulan = DateTime(_tanggalSekarang.year, _tanggalSekarang.month + 1, 0);
    final int hariAwalMinggu = hariPertamaBulan.weekday % 7;

    final List<DateTime?> mingguSekarang = [];

    // Tambahkan hari dari bulan sebelumnya
    if (hariAwalMinggu > 0) {
      final hariTerakhirBulanSebelumnya = DateTime(_tanggalSekarang.year, _tanggalSekarang.month, 0);
      for (int i = hariAwalMinggu - 1; i >= 0; i--) {
        final tanggalSebelumnya = DateTime(
          hariTerakhirBulanSebelumnya.year,
          hariTerakhirBulanSebelumnya.month,
          hariTerakhirBulanSebelumnya.day - i,
        );
        mingguSekarang.add(tanggalSebelumnya);
      }
    }

    // Tambahkan hari dari bulan ini
    for (int hari = 1; hari <= hariTerakhirBulan.day; hari++) {
      final tanggal = DateTime(_tanggalSekarang.year, _tanggalSekarang.month, hari);
      mingguSekarang.add(tanggal);

      if (mingguSekarang.length == 7) {
        _hariKalender.add(List.from(mingguSekarang));
        mingguSekarang.clear();
      }
    }

    // Tambahkan hari dari bulan berikutnya
    if (mingguSekarang.isNotEmpty) {
      int hariBulanBerikutnya = 1;
      while (mingguSekarang.length < 7) {
        final tanggalBerikutnya = DateTime(_tanggalSekarang.year, _tanggalSekarang.month + 1, hariBulanBerikutnya);
        mingguSekarang.add(tanggalBerikutnya);
        hariBulanBerikutnya++;
      }
      _hariKalender.add(mingguSekarang);
    }
  }

  // ========== FUNGSI NAVIGASI ==========
  void _keBulanSebelumnya() {
    setState(() {
      _tanggalSekarang = DateTime(_tanggalSekarang.year, _tanggalSekarang.month - 1, 1);
      _buatKalender();
    });
  }

  void _keBulanBerikutnya() {
    setState(() {
      _tanggalSekarang = DateTime(_tanggalSekarang.year, _tanggalSekarang.month + 1, 1);
      _buatKalender();
    });
  }

  // ========== FUNGSI BANTUAN ==========
  bool _adalahHariIni(DateTime tanggal) {
    final sekarang = DateTime.now();
    return tanggal.year == sekarang.year &&
        tanggal.month == sekarang.month &&
        tanggal.day == sekarang.day;
  }

  bool _adalahTerpilih(DateTime tanggal) {
    return _tanggalTerpilih != null &&
        _tanggalTerpilih!.year == tanggal.year &&
        _tanggalTerpilih!.month == tanggal.month &&
        _tanggalTerpilih!.day == tanggal.day;
  }

  bool _adalahBulanSekarang(DateTime tanggal) {
    return tanggal.year == _tanggalSekarang.year && tanggal.month == _tanggalSekarang.month;
  }

  bool _punyaAcara(DateTime tanggal) {
    return _acara.containsKey(DateTime(tanggal.year, tanggal.month, tanggal.day));
  }

  bool _adalahHariLalu(DateTime tanggal) {
    final sekarang = DateTime.now();
    final hariIni = DateTime(sekarang.year, sekarang.month, sekarang.day);
    final tanggalPeriksa = DateTime(tanggal.year, tanggal.month, tanggal.day);
    return tanggalPeriksa.isBefore(hariIni);
  }

  Color _dapatkanWarnaJenis(String jenis) {
    switch (jenis) {
      case 'Pembekalan':
        return _warnaUtama;
      case 'Monitoring 1':
        return _warnaHijau;
      case 'Monitoring 2':
        return _warnaBiru;
      case 'Penjemputan':
        return _warnaUngu;
      case 'Workshop Laporan':
        return _warnaKuning;
      case 'Presentasi Akhir':
        return _warnaMerah;
      default:
        return _warnaUtama;
    }
  }

  Color _dapatkanWarnaStatus(String status) {
    switch (status) {
      case 'aktif':
        return _warnaHijau;
      case 'akan datang':
        return _warnaBiru;
      case 'selesai':
        return Colors.grey;
      default:
        return _warnaUtama;
    }
  }

  String _dapatkanIkonJenis(String jenis) {
    switch (jenis) {
      case 'Pembekalan':
        return '📚';
      case 'Monitoring 1':
        return '📋';
      case 'Monitoring 2':
        return '📊';
      case 'Penjemputan':
        return '🚌';
      case 'Workshop Laporan':
        return '📝';
      case 'Presentasi Akhir':
        return '🎤';
      default:
        return '📅';
    }
  }

  String _formatTanggalUntukTampilan(DateTime tanggal) {
    try {
      return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(tanggal);
    } catch (e) {
      // Fallback ke locale default jika ada error
      return DateFormat('EEEE, dd MMMM yyyy').format(tanggal);
    }
  }

  String _formatTanggalPendek(DateTime tanggal) {
    try {
      return DateFormat('dd MMM', 'id_ID').format(tanggal);
    } catch (e) {
      // Fallback ke locale default jika ada error
      return DateFormat('dd MMM').format(tanggal);
    }
  }

  String _formatTanggalTanpaLocale(DateTime tanggal) {
    return DateFormat('dd MMM yyyy').format(tanggal);
  }

  List<KegiatanPkl> _dapatkanKegiatanUntukHari(DateTime hari) {
    final kunciTanggal = DateTime(hari.year, hari.month, hari.day);
    return _acara[kunciTanggal] ?? [];
  }

  // Fungsi untuk mendapatkan jadwal yang akan datang
  List<KegiatanPkl> _dapatkanKegiatanMendatang() {
    final sekarang = DateTime.now();
    final hariIni = DateTime(sekarang.year, sekarang.month, sekarang.day);

    // Filter kegiatan yang tanggal selesai >= hari ini
    final List<KegiatanPkl> kegiatanMendatang = _semuaKegiatan
        .where((kegiatan) => !kegiatan.tanggalSelesai.isBefore(hariIni))
        .toList();

    // Urutkan berdasarkan tanggal mulai (menaik)
    kegiatanMendatang.sort((a, b) => a.tanggalMulai.compareTo(b.tanggalMulai));

    return kegiatanMendatang;
  }

  // Fungsi untuk mendapatkan kegiatan pada hari terpilih atau jadwal terdekat
  List<KegiatanPkl> _dapatkanKegiatanYangDitampilkan() {
    final kegiatanHari = _dapatkanKegiatanUntukHari(_tanggalTerpilih ?? DateTime.now());

    // Jika ada kegiatan pada hari terpilih, tampilkan
    if (kegiatanHari.isNotEmpty) {
      return kegiatanHari;
    }

    // Jika tidak ada, tampilkan jadwal yang akan datang
    return _dapatkanKegiatanMendatang();
  }

  // ========== MEMBANGUN WIDGET ==========
  @override
  Widget build(BuildContext context) {
    // Tampilkan loading jika date formatting belum diinisialisasi
    if (!_dateFormatInitialized) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _warnaUtama, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              color: _warnaUtama,
            ),
          ),
        ),
      );
    }

    if (_sedangMemeriksaToken) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _warnaUtama, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              color: _warnaUtama,
            ),
          ),
        ),
      );
    }

    if (_sedangMemuat) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: _warnaUtama,
              ),
              SizedBox(height: 16),
              Text(
                'Memuat jadwal...',
                style: TextStyle(
                  color: _warnaUtama,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_pesanError.isNotEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: _warnaMerah, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Terjadi kesalahan',
                style: TextStyle(
                  color: _warnaMerah,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _pesanError,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _teksSekunder),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _muatDataContoh,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _warnaUtama,
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
          onRefresh: _muatDataContoh,
          backgroundColor: Colors.white,
          color: _warnaUtama,
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
                    border: Border.all(color: _warnaBatas),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
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
                              color: _warnaUtama.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _warnaUtama.withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              '${_semuaKegiatan.length} Total Kegiatan',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _warnaUtama,
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
                              color: _warnaHijau.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _warnaHijau.withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              '${_dapatkanKegiatanMendatang().length} Akan Datang',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _warnaHijau,
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
                    border: Border.all(color: _warnaBatas),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _bangunTombolNavigasi(
                        ikon: Icons.chevron_left,
                        onPressed: _keBulanSebelumnya,
                      ),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _warnaUtama.withOpacity(0.05),
                                _warnaUtama.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _warnaUtama.withOpacity(0.2),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _bulanSekarang.toUpperCase(),
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
                      _bangunTombolNavigasi(
                        ikon: Icons.chevron_right,
                        onPressed: _keBulanBerikutnya,
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
                    border: Border.all(color: _warnaBatas),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // HEADER HARI (Minggu sampai Sabtu)
                      Row(
                        children: ['M', 'S', 'S', 'R', 'K', 'J', 'S'].map((hari) {
                          return Expanded(
                            child: Center(
                              child: Text(
                                hari,
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
                        children: _hariKalender.map((minggu) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: minggu.map((tanggal) {
                                if (tanggal == null) {
                                  return Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.all(4),
                                      height: 50,
                                    ),
                                  );
                                }

                                final adalahBulanSekarang = _adalahBulanSekarang(tanggal);
                                final punyaAcara = _punyaAcara(tanggal);
                                final adalahHariIni = _adalahHariIni(tanggal);
                                final adalahTerpilih = _adalahTerpilih(tanggal);
                                final adalahHariLalu = _adalahHariLalu(tanggal);

                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _tanggalTerpilih = tanggal;
                                        if (!adalahBulanSekarang) {
                                          _tanggalSekarang = DateTime(
                                            tanggal.year,
                                            tanggal.month,
                                            1,
                                          );
                                          _buatKalender();
                                        }
                                      });
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.all(4),
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: adalahHariLalu
                                            ? _warnaHariLalu
                                            : adalahTerpilih
                                                ? _warnaUtama
                                                : adalahHariIni
                                                    ? _warnaKuning.withOpacity(0.15)
                                                    : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: adalahHariLalu
                                              ? Colors.grey[200]!
                                              : adalahTerpilih
                                                  ? _warnaUtama
                                                  : adalahHariIni
                                                      ? _warnaKuning
                                                      : Colors.grey[200]!,
                                          width: adalahHariLalu
                                              ? 1
                                              : adalahTerpilih
                                                  ? 2
                                                  : (adalahHariIni ? 1.5 : 1),
                                        ),
                                        boxShadow: adalahTerpilih
                                            ? [
                                                BoxShadow(
                                                  color: _warnaUtama.withOpacity(0.3),
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
                                                tanggal.day.toString(),
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: adalahTerpilih
                                                      ? FontWeight.w800
                                                      : FontWeight.w600,
                                                  color: adalahHariLalu
                                                      ? _warnaTeksHariLalu
                                                      : adalahTerpilih
                                                          ? Colors.white
                                                          : adalahBulanSekarang
                                                              ? Colors.black
                                                              : Colors.grey[400],
                                                ),
                                              ),
                                              if (punyaAcara && adalahHariLalu)
                                                Container(
                                                  margin: const EdgeInsets.only(top: 2),
                                                  width: 6,
                                                  height: 6,
                                                  decoration: const BoxDecoration(
                                                    color: _warnaTeksHariLalu,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              if (punyaAcara && !adalahHariLalu)
                                                Container(
                                                  margin: const EdgeInsets.only(top: 2),
                                                  width: 6,
                                                  height: 6,
                                                  decoration: BoxDecoration(
                                                    color: adalahTerpilih
                                                        ? Colors.white
                                                        : _warnaUtama,
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
                    border: Border.all(color: _warnaBatas),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
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
                                _tanggalTerpilih != null
                                    ? _formatTanggalUntukTampilan(_tanggalTerpilih!)
                                    : 'Pilih Tanggal',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _dapatkanKegiatanUntukHari(_tanggalTerpilih ?? DateTime.now()).isEmpty
                                    ? 'Menampilkan jadwal yang akan datang'
                                    : '${_dapatkanKegiatanUntukHari(_tanggalTerpilih ?? DateTime.now()).length} kegiatan pada hari ini',
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
                              color: _dapatkanKegiatanYangDitampilkan().isEmpty
                                  ? Colors.grey.withOpacity(0.1)
                                  : _warnaHijau.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _dapatkanKegiatanYangDitampilkan().isEmpty
                                    ? Colors.grey.withOpacity(0.3)
                                    : _warnaHijau.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              '${_dapatkanKegiatanYangDitampilkan().length} Kegiatan',
                              style: TextStyle(
                                color: _dapatkanKegiatanYangDitampilkan().isEmpty
                                    ? Colors.grey
                                    : _warnaHijau,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // DAFTAR KEGIATAN
                      if (_dapatkanKegiatanYangDitampilkan().isEmpty)
                        Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _warnaBatas),
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
                          children: _dapatkanKegiatanYangDitampilkan().map((kegiatan) {
                            final statusKegiatan = _dapatkanStatusKegiatan(kegiatan);
                            final adalahAcaraHariIni = _adalahHariIni(kegiatan.tanggalMulai);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: statusKegiatan == 'selesai'
                                      ? Colors.grey[300]!
                                      : adalahAcaraHariIni
                                          ? _warnaUtama.withOpacity(0.5)
                                          : _dapatkanWarnaJenis(kegiatan.jenisKegiatan)
                                              .withOpacity(0.3),
                                  width: statusKegiatan == 'selesai' ? 1 : 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
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
                                            color: _dapatkanWarnaJenis(kegiatan.jenisKegiatan)
                                                .withOpacity(statusKegiatan == 'selesai' ? 0.05 : 0.1),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: _dapatkanWarnaJenis(kegiatan.jenisKegiatan)
                                                  .withOpacity(statusKegiatan == 'selesai' ? 0.1 : 0.3),
                                            ),
                                          ),
                                          child: Text(
                                            _dapatkanIkonJenis(kegiatan.jenisKegiatan),
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
                                                  color: statusKegiatan == 'selesai'
                                                      ? Colors.grey[600]
                                                      : _dapatkanWarnaJenis(kegiatan.jenisKegiatan),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.calendar_today,
                                                    size: 12,
                                                    color: statusKegiatan == 'selesai'
                                                        ? Colors.grey[500]
                                                        : _teksSekunder,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    _formatTanggalPendek(kegiatan.tanggalMulai),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: statusKegiatan == 'selesai'
                                                          ? Colors.grey[600]
                                                          : _teksSekunder,
                                                    ),
                                                  ),
                                                  if (kegiatan.tanggalSelesai !=
                                                      kegiatan.tanggalMulai)
                                                    Row(
                                                      children: [
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          ' - ${_formatTanggalPendek(kegiatan.tanggalSelesai)}',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: statusKegiatan == 'selesai'
                                                                ? Colors.grey[600]
                                                                : _teksSekunder,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (adalahAcaraHariIni && statusKegiatan != 'selesai')
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _warnaUtama.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: _warnaUtama.withOpacity(0.3),
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
                                        if (statusKegiatan == 'selesai')
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
                                        color: statusKegiatan == 'selesai'
                                            ? Colors.grey[700]
                                            : _teksPrimer,
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
                                                  color: _teksSekunder,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _formatTanggalTanpaLocale(kegiatan.tanggalMulai),
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: statusKegiatan == 'selesai'
                                                      ? Colors.grey[600]
                                                      : _teksPrimer,
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
                                                  color: _teksSekunder,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _formatTanggalTanpaLocale(kegiatan.tanggalSelesai),
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: statusKegiatan == 'selesai'
                                                      ? Colors.grey[600]
                                                      : _teksPrimer,
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
                                                  color: _teksSekunder,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                statusKegiatan.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: _dapatkanWarnaStatus(statusKegiatan),
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

  Widget _bangunTombolNavigasi({
    required IconData ikon,
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
          border: Border.all(color: _warnaBatas),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(ikon, color: _warnaUtama, size: 22),
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
  final int dibuatOleh;
  final DateTime dibuatPada;
  final DateTime diperbaruiPada;

  KegiatanPkl({
    required this.id,
    required this.deskripsi,
    required this.jenisKegiatan,
    required this.tahunAjaranId,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.dibuatOleh,
    required this.dibuatPada,
    required this.diperbaruiPada,
  });
}