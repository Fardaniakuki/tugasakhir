// kelola_rekap_nilai_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login/login_screen.dart';

class KelolaRekapNilaiScreen extends StatefulWidget {
  final ScrollController scrollController;
  final String token;
  final String baseUrl;

  const KelolaRekapNilaiScreen({
    super.key,
    required this.scrollController,
    required this.token,
    required this.baseUrl,
  });

  @override
  State<KelolaRekapNilaiScreen> createState() => _KelolaRekapNilaiScreenState();
}

class _KelolaRekapNilaiScreenState extends State<KelolaRekapNilaiScreen> {
  bool _isLoading = true;
  bool _isExporting = false;
  String? _errorMessage;

  // Data siswa
  List<dynamic> _siswaList = [];
  List<dynamic> _allData = [];
  int _totalData = 0;

  // Data guru
  String? _guruNama;
  String? _guruKode;

  // Cache untuk nama pembimbing
  final Map<int, String> _pembimbingCache = {};
  bool _isLoadingPembimbing = false;

  // Kelas wali - FIXED: XII RPL 1
  final String _kelasWali = 'XII RPL 1';

  // Filter
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  // Warna tema
  final Color _primaryColor = const Color(0xFF641E20);
  final Color _successColor = const Color(0xFF2E7D32);
  final Color _warningColor = const Color(0xFFED6C02);
  final Color _neutralColor = const Color(0xFF757575);
  final Color _backgroundLight = const Color(0xFFF5F5F5);
  final Color _borderSoft = const Color(0xFFEEEEEE);

  @override
  void initState() {
    super.initState();
    print('📥 Menggunakan kelas: $_kelasWali');
    _getGuruData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // ==================== FUNGSI SORTIR NAMA ====================
  List<dynamic> _sortSiswaByName(List<dynamic> list) {
    final List<dynamic> sortedList = List.from(list);
    sortedList.sort((a, b) {
      final String namaA = (a['siswa_username'] ?? '').toString().toLowerCase();
      final String namaB = (b['siswa_username'] ?? '').toString().toLowerCase();
      return namaA.compareTo(namaB);
    });
    return sortedList;
  }

  // ==================== AMBIL DATA GURU ====================
  Future<void> _getGuruData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Ambil data guru dari shared preferences
      final prefs = await SharedPreferences.getInstance();
      final kodeGuru = prefs.getString('kode_guru');
      final guruId = prefs.getInt('guru_id');

      print('👤 Kode Guru from prefs: $kodeGuru');
      print('👤 Guru ID from prefs: $guruId');
      print('🏫 Kelas wali: $_kelasWali');

      // Jika punya guruId, ambil data guru dari API
      if (guruId != null) {
        await _fetchGuruDataFromApi(guruId);
      } else {
        // Fallback: default name
        setState(() {
          _guruNama = 'Rr. Henning Gratyanis Anggraeni, S.Pd.';
        });
      }
    } catch (e) {
      print('❌ Error getting guru data: $e');
      setState(() {
        _guruNama = 'Rr. Henning Gratyanis Anggraeni, S.Pd.';
      });
    }

    _fetchSiswaList();
  }

  // ==================== FETCH GURU DATA FROM API ====================
  Future<void> _fetchGuruDataFromApi(int guruId) async {
    try {
      final uri = Uri.parse('${widget.baseUrl}/api/guru/$guruId');

      print('📡 Fetching guru data from: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      print('📡 Guru API Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final guruData = data['data'];
          setState(() {
            _guruNama =
                guruData['nama'] ?? 'Rr. Henning Gratyanis Anggraeni, S.Pd.';
            _guruKode = guruData['kode_guru'] ?? _guruKode;
          });
          print('✅ Guru name fetched: $_guruNama');
        } else {
          setState(() {
            _guruNama = 'Rr. Henning Gratyanis Anggraeni, S.Pd.';
          });
        }
      } else if (response.statusCode == 401) {
        _redirectToLogin();
      } else {
        print('❌ Failed to fetch guru data: ${response.statusCode}');
        setState(() {
          _guruNama = 'Rr. Henning Gratyanis Anggraeni, S.Pd.';
        });
      }
    } catch (e) {
      print('❌ Error fetching guru data: $e');
      setState(() {
        _guruNama = 'Rr. Henning Gratyanis Anggraeni, S.Pd.';
      });
    }
  }

  // ==================== FETCH NAMA PEMBIMBING ====================
  Future<String> _getNamaPembimbing(int? pembimbingGuruId) async {
    if (pembimbingGuruId == null) return '-';

    // Cek di cache dulu
    if (_pembimbingCache.containsKey(pembimbingGuruId)) {
      return _pembimbingCache[pembimbingGuruId]!;
    }

    // Jika belum ada di cache, fetch dari API
    try {
      final uri = Uri.parse('${widget.baseUrl}/api/guru/$pembimbingGuruId');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final nama = data['data']['nama'] ?? 'Guru ID: $pembimbingGuruId';
          // Simpan ke cache
          setState(() {
            _pembimbingCache[pembimbingGuruId] = nama;
          });
          return nama;
        }
      }
    } catch (e) {
      print('❌ Error fetching pembimbing $pembimbingGuruId: $e');
    }

    return 'Guru ID: $pembimbingGuruId';
  }

  // ==================== FUNGSI FORMAT TANGGAL ====================
  String _formatDateIndonesian(String? dateString, {required bool forCSV}) {
    if (dateString == null || dateString.isEmpty) return '-';

    try {
      final date = DateTime.parse(dateString);
      const List<String> bulan = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember'
      ];
      return '${date.day} ${bulan[date.month - 1]} ${date.year}';
    } catch (e) {
      return '-';
    }
  }

  // ==================== FUNGSI FETCH DATA SISWA ====================
  Future<void> _fetchSiswaList() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Ambil semua data review
      final queryParams = <String, String>{};
      if (_searchQuery.isNotEmpty) {
        queryParams['search'] = _searchQuery;
      }

      final uri = Uri.parse('${widget.baseUrl}/api/penilaian/review')
          .replace(queryParameters: queryParams);

      print('📡 Fetching data from: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _allData = data['data'] ?? [];

        // Filter berdasarkan kelas wali (XII RPL 1)
        List<dynamic> filteredData = _allData.where((item) {
          final kelasNama = item['kelas_nama']?.toString() ?? '';
          // Cek apakah mengandung "XII RPL 1" (case insensitive)
          return kelasNama.contains('XII RPL 1') ||
              kelasNama.contains('XII RPL 1') ||
              kelasNama == 'XII RPL 1';
        }).toList();

        print(
            '🔍 Data untuk kelas $_kelasWali sebelum sorting: ${filteredData.length} dari ${_allData.length} total');

        // Filter berdasarkan search query
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          filteredData = filteredData.where((item) {
            final nama = (item['siswa_username'] ?? '').toLowerCase();
            return nama.contains(query);
          }).toList();
        }

        // SORTIR BERDASARKAN ABJAD NAMA SISWA
        final List<dynamic> sortedData = _sortSiswaByName(filteredData);

        setState(() {
          _siswaList = sortedData; // Gunakan data yang sudah di-sort
          _totalData = _siswaList.length;
          _isLoading = false;
        });

        print('✅ Setelah sorting: ${_siswaList.length} data');
        print(
            '📋 Urutan pertama: ${_siswaList.isNotEmpty ? _siswaList.first['siswa_username'] : 'Tidak ada data'}');
        print(
            '📋 Urutan terakhir: ${_siswaList.isNotEmpty ? _siswaList.last['siswa_username'] : 'Tidak ada data'}');

        // Load semua nama pembimbing
        _loadAllPembimbingNames();
      } else if (response.statusCode == 401) {
        _redirectToLogin();
      } else {
        setState(() {
          _errorMessage = 'Gagal memuat data (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        _errorMessage = 'Gagal memuat data: $e';
        _isLoading = false;
      });
    }
  }

  // ==================== LOAD SEMUA NAMA PEMBIMBING ====================
  Future<void> _loadAllPembimbingNames() async {
    if (_siswaList.isEmpty) return;

    setState(() {
      _isLoadingPembimbing = true;
    });

    // Kumpulkan semua ID pembimbing yang unik
    final Set<int> pembimbingIds = {};
    for (var item in _siswaList) {
      final id = item['pembimbing_guru_id'];
      if (id != null && id is int) {
        pembimbingIds.add(id);
      }
    }

    print('📚 Loading ${pembimbingIds.length} unique pembimbing names...');

    // Fetch semua nama pembimbing
    for (int id in pembimbingIds) {
      if (!_pembimbingCache.containsKey(id)) {
        await _getNamaPembimbing(id);
      }
    }

    setState(() {
      _isLoadingPembimbing = false;
    });

    print('✅ All pembimbing names loaded');
  }

  void _filterSiswa(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
      _fetchSiswaList();
    });
  }

  void _redirectToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _tampilkanSnackBar(String message,
      {bool isError = false, bool isInfo = false}) {
    Color backgroundColor = isError ? Colors.red : _primaryColor;
    if (isInfo) backgroundColor = Colors.orange;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

// ==================== FUNGSI EXPORT CSV ====================
  Future<void> _exportToCSV() async {
    if (_siswaList.isEmpty) {
      _tampilkanSnackBar('Tidak ada data untuk diekspor', isError: true);
      return;
    }

    setState(() => _isExporting = true);

    try {
      // Buat CSV header dengan format lengkap + kolom PREDIKAT
      String csv =
          'No,Nama Siswa,NISN,Kelas,Konsentrasi Keahlian,Industri,Pembimbing,Sakit,Izin,Alpa,Total Skor,Rata-rata,Predikat,Tanggal Finalisasi\n';

      for (var i = 0; i < _siswaList.length; i++) {
        final item = _siswaList[i];

        // Ambil nama pembimbing dari cache
        final pembimbingId = item['pembimbing_guru_id'];
        String namaPembimbing;

        if (pembimbingId != null) {
          namaPembimbing = _pembimbingCache[pembimbingId] ??
              await _getNamaPembimbing(pembimbingId);
        } else {
          namaPembimbing = '-';
        }

        // Hitung rata-rata dan dapatkan predikat
        final double rataRata =
            double.tryParse(item['rata_rata']?.toString() ?? '0') ?? 0;
        final String predikat = _getPredikatFromRataRata(rataRata);

        csv += '${i + 1},';
        csv += '"${item['siswa_username'] ?? ''}",';
        csv += '"${item['siswa_nisn'] ?? ''}",';
        csv += '"$_kelasWali",'; // Gunakan kelas yang sudah ditentukan
        csv += '"${item['jurusan_nama'] ?? ''}",';
        csv += '"${item['industri_nama'] ?? ''}",';
        csv += '"$namaPembimbing",';
        csv += '0,'; // Sakit (default 0)
        csv += '0,'; // Izin (default 0)
        csv += '0,'; // Alpa (default 0)
        csv += '${item['total_skor'] ?? 0},';
        csv += '"${rataRata.toStringAsFixed(1)}",';
        csv += '"$predikat",'; // KOLOM PREDIKAT BARU

        // PERBAIKAN: Format tanggal menjadi Hari, Tanggal Bulan Tahun
        final tgl = item['finalized_at'] != null
            ? _formatDateIndonesian(item['finalized_at'], forCSV: true)
            : '-';
        csv += '"$tgl"\n';
      }

      // Simpan file
      final tempDir = await getTemporaryDirectory();
      final String fileName =
          'rekap-nilai-XII-RPL-1-${DateFormat('yyyyMMdd-HHmmss').format(DateTime.now())}.csv';
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsString(csv, encoding: utf8);

      // Bagikan file
      await Share.shareXFiles(
        [XFile(tempFile.path, mimeType: 'text/csv')],
        text:
            'Rekap Nilai Kelas XII RPL 1 - ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
      );

      _tampilkanSnackBar('Berkas CSV berhasil diekspor');
    } catch (e) {
      _tampilkanSnackBar('Gagal mengekspor: $e', isError: true);
    } finally {
      setState(() => _isExporting = false);
    }
  }

// ==================== FUNGSI UNTUK MENDAPATKAN PREDIKAT ====================
  String _getPredikatFromRataRata(double rataRata) {
    if (rataRata >= 86) {
      return 'Sangat Baik';
    } else if (rataRata >= 75) {
      return 'Baik';
    } else {
      return 'Kurang';
    }
  }

// ==================== FUNGSI FORMAT TANGGAL UNTUK CSV ====================

  String _getInitials(String name) {
    if (name.isEmpty) return 'S';
    final parts = name.split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  double _hitungRataRataKeseluruhan() {
    if (_siswaList.isEmpty) return 0;
    double total = 0;
    int count = 0;
    for (var item in _siswaList) {
      final rataRata = double.tryParse(item['rata_rata']?.toString() ?? '0');
      if (rataRata != null) {
        total += rataRata;
        count++;
      }
    }
    return count == 0 ? 0 : total / count;
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return _successColor;
    if (score >= 75) return _warningColor;
    return Colors.red;
  }

  // ==================== FUNGSI NAVIGASI KE DETAIL ====================
  void _navigateToDetail(dynamic item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RekapDetailScreen(
          applicationId: item['application_id'],
          reviewData: item,
          baseUrl: widget.baseUrl,
          token: widget.token,
        ),
      ),
    );
  }

  // ==================== BUILD NAMA PEMBIMBING WIDGET ====================
  Widget _buildNamaPembimbing(dynamic item) {
    final pembimbingId = item['pembimbing_guru_id'];

    if (pembimbingId == null) {
      return Text(
        '-',
        style: TextStyle(fontSize: 11, color: _neutralColor),
      );
    }

    // Jika nama sudah ada di cache
    if (_pembimbingCache.containsKey(pembimbingId)) {
      return Text(
        _pembimbingCache[pembimbingId]!,
        style: TextStyle(fontSize: 11, color: _neutralColor),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    // Jika belum, tampilkan loading dan fetch
    Future.microtask(() => _getNamaPembimbing(pembimbingId));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _primaryColor,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'Memuat...',
          style: TextStyle(fontSize: 11, color: _neutralColor),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 80;

    return Scaffold(
      backgroundColor: _backgroundLight,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: BoxDecoration(
              color: _primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.assignment_turned_in_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rekap Nilai',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Wali Kelas - XII RPL 1',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterSiswa,
                    decoration: InputDecoration(
                      hintText: 'Cari nama siswa...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon:
                          Icon(Icons.search_rounded, color: _primaryColor),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                                _fetchSiswaList();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _errorMessage != null
                    ? _buildErrorState()
                    : RefreshIndicator(
                        onRefresh: _fetchSiswaList,
                        color: _primaryColor,
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            // Stats Card
                            SliverToBoxAdapter(
                              child: _buildStatsCard(),
                            ),

                            // Export Button
                            SliverToBoxAdapter(
                              child: _buildExportButton(),
                            ),

                            // Info Card
                            SliverToBoxAdapter(
                              child: _buildInfoCard(),
                            ),

                            // Loading indicator untuk pembimbing
                            if (_isLoadingPembimbing)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.1),
                                            blurRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: _primaryColor,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Memuat nama pembimbing...',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: _neutralColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // Daftar Siswa (sudah di-sort berdasarkan abjad)
                            if (_siswaList.isEmpty)
                              SliverFillRemaining(
                                child: _buildEmptyState(),
                              )
                            else
                              SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final item = _siswaList[index];
                                    return _buildSiswaCard(item);
                                  },
                                  childCount: _siswaList.length,
                                ),
                              ),

                            // Bottom Padding
                            SliverToBoxAdapter(
                              child: SizedBox(height: bottomPadding),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_primaryColor, _primaryColor.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              icon: Icons.people,
              value: '$_totalData',
              label: 'Total Siswa',
            ),
            Container(
              height: 40,
              width: 1,
              color: Colors.white.withOpacity(0.3),
            ),
            _buildStatItem(
              icon: Icons.class_,
              value: 'XII RPL 1',
              label: 'Kelas',
            ),
            Container(
              height: 40,
              width: 1,
              color: Colors.white.withOpacity(0.3),
            ),
            _buildStatItem(
              icon: Icons.star,
              value: _hitungRataRataKeseluruhan().toStringAsFixed(2),
              label: 'Rata-rata',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        onPressed: _isExporting || _siswaList.isEmpty ? null : _exportToCSV,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
        icon: _isExporting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.download),
        label: Text(
          _isExporting ? 'MENGEKSPOR...' : 'EKSPOR CSV',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: _primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Informasi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _backgroundLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderSoft),
            ),
            child: Column(
              children: [
                _buildInfoRow(Icons.people, 'Total Siswa', '$_totalData siswa'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),
                _buildInfoRow(Icons.class_, 'Kelas', 'XII RPL 1'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),
                _buildInfoRow(Icons.person, 'Wali Kelas',
                    _guruNama ?? 'Rr. Henning Gratyanis Anggraeni, S.Pd.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _neutralColor),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: _neutralColor,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildSiswaCard(dynamic item) {
    final double rataRata =
        double.tryParse(item['rata_rata']?.toString() ?? '0') ?? 0;
    final Color scoreColor = _getScoreColor(rataRata);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToDetail(
              item), // Menambahkan onTap untuk navigasi ke detail
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderSoft),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _primaryColor.withOpacity(0.2),
                            _primaryColor.withOpacity(0.1)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(item['siswa_username'] ?? 'S'),
                          style: TextStyle(
                            color: _primaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['siswa_username'] ?? '-',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'NISN: ${item['siswa_nisn'] ?? '-'}',
                            style: TextStyle(
                              fontSize: 11,
                              color: _neutralColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: scoreColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: scoreColor.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            rataRata.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: scoreColor,
                            ),
                          ),
                          Text(
                            'rata',
                            style: TextStyle(
                              fontSize: 8,
                              color: scoreColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(color: _borderSoft, height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.business_center_rounded,
                        size: 14, color: _neutralColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item['industri_nama'] ?? '-',
                        style: TextStyle(
                          fontSize: 12,
                          color: _primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.person_outline_rounded,
                        size: 14, color: _neutralColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pembimbing:',
                            style: TextStyle(
                              fontSize: 11,
                              color: _neutralColor,
                            ),
                          ),
                          _buildNamaPembimbing(item),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 12, color: _neutralColor),
                    const SizedBox(width: 4),
                    Text(
                      'Selesai: ${_formatDateIndonesian(item['finalized_at'], forCSV: true)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: _neutralColor,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Total: ${item['total_skor'] ?? 0}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                // Menambahkan indikator bahwa card bisa ditekan
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 14,
                      color: _primaryColor.withOpacity(0.5),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'Ketuk untuk detail',
                      style: TextStyle(
                        fontSize: 9,
                        color: _primaryColor.withOpacity(0.5),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: _primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Memuat data siswa...',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Icon(
              Icons.assignment_outlined,
              size: 50,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'Tidak ada siswa yang cocok'
                : 'Belum ada data siswa di kelas XII RPL 1',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Coba kata kunci lain'
                : 'Belum ada penilaian yang difinalisasi',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          if (_searchQuery.isNotEmpty)
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
                _fetchSiswaList();
              },
              style: TextButton.styleFrom(
                foregroundColor: _primaryColor,
              ),
              child: const Text('Reset Pencarian'),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Terjadi Kesalahan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage ?? 'Gagal memuat data',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _fetchSiswaList,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('COBA LAGI'),
          ),
        ],
      ),
    );
  }
}

// ==================== HALAMAN DETAIL REKAP NILAI ====================
class RekapDetailScreen extends StatefulWidget {
  final int applicationId;
  final Map<String, dynamic> reviewData;
  final String baseUrl;
  final String token;

  const RekapDetailScreen({
    super.key,
    required this.applicationId,
    required this.reviewData,
    required this.baseUrl,
    required this.token,
  });

  @override
  State<RekapDetailScreen> createState() => _RekapDetailScreenState();
}

class _RekapDetailScreenState extends State<RekapDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _detailData;
  List<Map<String, dynamic>> _formItems = [];
  List<Map<String, dynamic>> _nilaiItems = [];

  late Map<String, dynamic> _siswaData;

  // Warna tema
  final Color _primaryColor = const Color(0xFF641E20);
  final Color _primaryLight = const Color(0xFFFCE8E8);
  final Color _successColor = const Color(0xFF2E7D32);
  final Color _warningColor = const Color(0xFFED6C02);
  final Color _neutralColor = const Color(0xFF757575);
  final Color _backgroundLight = const Color(0xFFF5F5F5);
  final Color _borderSoft = const Color(0xFFEEEEEE);

  @override
  void initState() {
    super.initState();
    _siswaData = widget.reviewData;
    _fetchDetailData();
  }

// ==================== FUNGSI FORMAT TANGGAL ====================
  String _formatDateIndonesian(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';

    try {
      final date = DateTime.parse(dateString);

      // Daftar hari dalam bahasa Indonesia
      const List<String> hari = [
        'Senin',
        'Selasa',
        'Rabu',
        'Kamis',
        'Jumat',
        'Sabtu',
        'Minggu'
      ];

      // Daftar bulan dalam bahasa Indonesia
      const List<String> bulan = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember'
      ];

      // Mendapatkan nama hari (weekday di Dart: 1 = Senin, 7 = Minggu)
      // Tapi DateTime.weekday di Flutter: 1 = Monday, 7 = Sunday
      // Jadi perlu dikonversi
      final int dayIndex = date.weekday - 1; // 0 = Senin, 6 = Minggu

      return '${hari[dayIndex]}, ${date.day} ${bulan[date.month - 1]} ${date.year}';
    } catch (e) {
      return '-';
    }
  }

  // ==================== FUNGSI HELPER DESKRIPSI ====================
  String _getPredikatFromSkor(int skor) {
    if (skor >= 86) return 'Sangat Baik';
    if (skor >= 75) return 'Baik';
    return 'Kurang';
  }

  String _getSoftSkillDescription(int skor) {
    final predikat = _getPredikatFromSkor(skor);
    if (predikat == 'Sangat Baik') {
      return 'Peserta didik mampu menerapkan soft skill yang dimiliki dengan menunjukkan integritas (jujur, disiplin, komitmen, dan tanggung jawab), memiliki etos kerja, menunjukkan kemandirian, menunjukkan kerja sama, dan menunjukkan kepedulian sosial dan lingkungan dengan predikat sangat baik.';
    } else if (predikat == 'Baik') {
      return 'Peserta didik mampu menerapkan soft skill yang dimiliki dengan menunjukkan integritas (jujur, disiplin, komitmen, dan tanggung jawab), memiliki etos kerja, menunjukkan kemandirian, menunjukkan kerja sama, dan menunjukkan kepedulian sosial dan lingkungan dengan predikat baik.';
    } else {
      return 'Peserta didik mampu menerapkan soft skill yang dimiliki dengan menunjukkan integritas (jujur, disiplin, komitmen, dan tanggung jawab), memiliki etos kerja, menunjukkan kemandirian, menunjukkan kerja sama, dan menunjukkan kepedulian sosial dan lingkungan dengan predikat kurang.';
    }
  }

  String _getNormaK3LHDescription(int skor) {
    final predikat = _getPredikatFromSkor(skor);
    if (predikat == 'Sangat Baik') {
      return 'Peserta didik mampu menerapkan norma, Prosedur Operasional Standar (POS), dan Kesehatan, Keselamatan Kerja, dan Lingkungan Hidup (K3LH) yang ditunjukkan dengan menggunakan APD dengan tertib dan benar, serta melaksanakan pekerjaan sesuai POS dengan predikat sangat baik.';
    } else if (predikat == 'Baik') {
      return 'Peserta didik mampu menerapkan norma, Prosedur Operasional Standar (POS), dan Kesehatan, Keselamatan Kerja, dan Lingkungan Hidup (K3LH) yang ditunjukkan dengan menggunakan APD dengan tertib dan benar, serta melaksanakan pekerjaan sesuai POS dengan predikat baik.';
    } else {
      return 'Peserta didik mampu menerapkan norma, Prosedur Operasional Standar (POS), dan Kesehatan, Keselamatan Kerja, dan Lingkungan Hidup (K3LH) yang ditunjukkan dengan menggunakan APD dengan tertib dan benar, serta melaksanakan pekerjaan sesuai POS dengan predikat kurang.';
    }
  }

  String _getKompetensiTeknisDescription(int skor) {
    final predikat = _getPredikatFromSkor(skor);
    if (predikat == 'Sangat Baik') {
      return 'Peserta didik mampu menerapkan kompetensi teknis yang sudah dipelajari di sekolah dan/atau baru dipelajari di dunia kerja (tempat PKL) dengan predikat sangat baik.';
    } else if (predikat == 'Baik') {
      return 'Peserta didik mampu menerapkan kompetensi teknis yang sudah dipelajari di sekolah dan/atau baru dipelajari di dunia kerja (tempat PKL) dengan predikat baik.';
    } else {
      return 'Peserta didik mampu menerapkan kompetensi teknis yang sudah dipelajari di sekolah dan/atau baru dipelajari di dunia kerja (tempat PKL) dengan predikat kurang.';
    }
  }

  String _getAlurBisnisDescription(int skor) {
    final predikat = _getPredikatFromSkor(skor);
    if (predikat == 'Sangat Baik') {
      return 'Peserta didik mampu memahami alur bisnis dunia kerja tempat PKL dan wawasan wirausaha dengan predikat sangat baik.';
    } else if (predikat == 'Baik') {
      return 'Peserta didik mampu memahami alur bisnis dunia kerja tempat PKL dan wawasan wirausaha dengan predikat baik.';
    } else {
      return 'Peserta didik mampu memahami alur bisnis dunia kerja tempat PKL dan wawasan wirausaha dengan predikat kurang.';
    }
  }

  // ==================== FUNGSI FETCH DATA ====================
  Future<void> _fetchDetailData() async {
    setState(() => _isLoading = true);

    try {
      final url =
          '${widget.baseUrl}/api/penilaian/review/${widget.applicationId}';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _detailData = data;
          _formItems =
              List<Map<String, dynamic>>.from(data['form_items'] ?? []);
          _nilaiItems = List<Map<String, dynamic>>.from(data['items'] ?? []);
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        _redirectToLogin();
      } else {
        throw Exception('Gagal memuat detail review');
      }
    } catch (e) {
      print('Error fetching detail: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Gagal memuat detail review', isError: true);
      }
    }
  }

  // ==================== FUNGSI UTILITY ====================
  void _redirectToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : _primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'S';
    final parts = name.split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return _successColor;
    if (score >= 75) return _warningColor;
    return Colors.red;
  }

  // ==================== BUILD WIDGET ====================
  @override
  Widget build(BuildContext context) {
    final String siswaUsername = _siswaData['siswa_username'] ?? '-';
    final String nisn = _siswaData['siswa_nisn'] ?? '-';
    final String kelasNama = _siswaData['kelas_nama'] ?? '-';
    final String jurusanNama = _siswaData['jurusan_nama'] ?? '-';
    final String industriNama = _siswaData['industri_nama'] ?? '-';

    final String formNama = _detailData?['form_nama'] ?? '-';
    final int totalSkor = _detailData?['total_skor'] ?? 0;
    final double rataRata =
        double.tryParse(_detailData?['rata_rata']?.toString() ?? '0') ?? 0;
    final String catatanAkhir = _detailData?['catatan_akhir'] ?? '-';
    final String finalizedAt =
        _detailData?['finalized_at'] ?? _siswaData['finalized_at'] ?? '';

    return Scaffold(
      backgroundColor: _backgroundLight,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Detail Penilaian Siswa',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: _primaryColor),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== CARD INFORMASI SISWA =====
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    _primaryColor.withOpacity(0.2),
                                    _primaryColor.withOpacity(0.1)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  _getInitials(siswaUsername),
                                  style: TextStyle(
                                    color: _primaryColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 28,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    siswaUsername,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'NISN: $nisn',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _neutralColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Kelas',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _neutralColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    kelasNama,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Konsentrasi Keahlian',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _neutralColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    jurusanNama,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.business_center_rounded,
                              size: 16,
                              color: _neutralColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                industriNama,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ===== CARD FORM PENILAIAN =====
                  if (formNama != '-')
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _borderSoft),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.assignment_rounded,
                              color: _primaryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Form Penilaian',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _neutralColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  formNama,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (formNama != '-') const SizedBox(height: 20),

                  // ===== DETAIL NILAI KOMPETENSI =====
                  if (_formItems.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'Detail Nilai Kompetensi',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // LOOPING UNTUK SETIAP KOMPETENSI
                    ...List.generate(_formItems.length, (index) {
                      final formItem = _formItems[index];
                      final nomor = index + 1;

                      final nilaiItem = _nilaiItems.firstWhere(
                        (item) => item['form_item_id'] == formItem['id'],
                        orElse: () => {},
                      );

                      final int skor = nilaiItem['skor'] ?? 0;
                      final String predikat = nilaiItem['deskripsi'] ?? '-';

                      // Fungsi untuk mendapatkan deskripsi berdasarkan nomor kompetensi
                      String getDeskripsiKompetensi(
                          int nomorKompetensi, int skor) {
                        if (nomorKompetensi == 1) {
                          return _getSoftSkillDescription(skor);
                        } else if (nomorKompetensi == 2) {
                          return _getNormaK3LHDescription(skor);
                        } else if (nomorKompetensi == 3) {
                          return _getKompetensiTeknisDescription(skor);
                        } else if (nomorKompetensi == 4) {
                          return _getAlurBisnisDescription(skor);
                        }
                        return '';
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _borderSoft),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Kompetensi
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: _primaryColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$nomor',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Kompetensi $nomor',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Tujuan Pembelajaran
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _backgroundLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _borderSoft),
                              ),
                              child: Text(
                                formItem['tujuan_pembelajaran'] ?? '-',
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Nilai dan Predikat
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Nilai',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _backgroundLight,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border:
                                              Border.all(color: _borderSoft),
                                        ),
                                        child: Text(
                                          skor.toString(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 18,
                                            color:
                                                _getScoreColor(skor.toDouble()),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Predikat',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _backgroundLight,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border:
                                              Border.all(color: _borderSoft),
                                        ),
                                        child: Text(
                                          predikat,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: _primaryColor,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // ===== DESKRIPSI CAPAIAN =====
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _primaryColor.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: _primaryColor.withOpacity(0.2)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.description_rounded,
                                    size: 16,
                                    color: _primaryColor.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Deskripsi Capaian:',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: _primaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          getDeskripsiKompetensi(nomor, skor),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[800],
                                            height: 1.4,
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
                    }),
                    const SizedBox(height: 16),
                  ],

                  // ===== CATATAN AKHIR =====
                  if (catatanAkhir != '-')
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _borderSoft),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.note_alt_rounded,
                                size: 20,
                                color: _primaryColor,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Catatan Akhir',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _backgroundLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _borderSoft),
                            ),
                            child: Text(
                              catatanAkhir,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (catatanAkhir != '-') const SizedBox(height: 16),

                  // ===== RINGKASAN TOTAL SKOR =====
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _primaryColor,
                          _primaryColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total Skor',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  totalSkor.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 24,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white30,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Rata-rata',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  rataRata.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 24,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(
                          height: 1,
                          color: Colors.white30,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Selesai: ${_formatDateIndonesian(finalizedAt)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
