// lib/screens/kaprog/review_penilaian_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../login/login_screen.dart';

class ReviewPenilaianScreen extends StatefulWidget {
  final ScrollController? scrollController;
  final String token;
  final String baseUrl;

  const ReviewPenilaianScreen({
    super.key,
    this.scrollController,
    required this.token,
    required this.baseUrl,
  });

  @override
  State<ReviewPenilaianScreen> createState() => _ReviewPenilaianScreenState();
}

class _ReviewPenilaianScreenState extends State<ReviewPenilaianScreen> {
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isExporting = false;
  String? _errorMessage;

  // Data
  List<dynamic> _penilaianList = [];
  int _totalData = 0;
  int _currentPage = 1;
  bool _hasMorePages = true;

  // Filter - hanya Kelas dan Industri
  int? _selectedKelasId;
  int? _selectedIndustriId;
  String? _selectedKelasNama;
  String? _selectedIndustriNama;
  String _searchQuery = '';

  // Data untuk dropdown - diambil dari response
  final Map<int, String> _kelasMap = {};
  final Map<int, String> _industriMap = {};
  final Map<int, List<int>> _industriByKelas = {};

  // List untuk dropdown
  List<Map<String, dynamic>> _kelasList = [];
  List<Map<String, dynamic>> _industriList = [];
  List<Map<String, dynamic>> _filteredIndustriList = [];

  // Cache untuk nama guru
  final Map<int, String> _guruCache = {};

  // Controller
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  late ScrollController _internalScrollController;

  bool _showFilters = false;

  // Warna
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
    _internalScrollController = ScrollController();

    print('🚀 ReviewPenilaianScreen initState');
    print('🔑 Token: ${widget.token.substring(0, 10)}...');

    _loadPenilaian(reset: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    _internalScrollController.dispose();
    super.dispose();
  }

  // Fungsi untuk mendapatkan predikat berdasarkan nilai rata-rata
  String _getPredikatFromRataRata(double rataRata) {
    if (rataRata >= 86) return 'Sangat Baik';
    if (rataRata >= 75) return 'Baik';
    return 'Kurang';
  }

  // Ekstrak unique kelas dan industri dari data penilaian
  void _extractUniqueValues() {
    _kelasMap.clear();
    _industriMap.clear();
    _industriByKelas.clear();

    for (var item in _penilaianList) {
      // Kelas
      final kelasId = item['kelas_id'];
      final kelasNama = item['kelas_nama'];
      if (kelasId != null && kelasNama != null && kelasNama.isNotEmpty) {
        _kelasMap[kelasId] = kelasNama;
      }

      // Industri
      final industriId = item['industri_id'];
      final industriNama = item['industri_nama'];
      if (industriId != null && industriNama != null && industriNama.isNotEmpty) {
        _industriMap[industriId] = industriNama;
      }

      // Mapping industri per kelas
      if (kelasId != null && industriId != null) {
        if (!_industriByKelas.containsKey(kelasId)) {
          _industriByKelas[kelasId] = [];
        }
        if (!_industriByKelas[kelasId]!.contains(industriId)) {
          _industriByKelas[kelasId]!.add(industriId);
        }
      }
    }

    // Update list kelas
    final Set<String> kelasSet = {};
    final Map<String, int> kelasIdMap = {};

    for (var item in _penilaianList) {
      final kelas = item['kelas_nama']?.toString();
      final kelasId = item['kelas_id'];
      if (kelas != null && kelas.isNotEmpty && kelasId != null) {
        kelasSet.add(kelas);
        kelasIdMap[kelas] = kelasId;
      }
    }

    final kelasList = kelasSet.toList()..sort();

    final List<Map<String, dynamic>> newKelasList = [];
    for (var kelas in kelasList) {
      newKelasList.add({
        'nama': kelas,
        'id': kelasIdMap[kelas],
      });
    }

    // Update list industri (semua industri)
    final Set<String> industriSet = {};
    final Map<String, int> industriIdMap = {};

    for (var item in _penilaianList) {
      final industri = item['industri_nama']?.toString();
      final industriId = item['industri_id'];
      if (industri != null && industri.isNotEmpty && industriId != null) {
        industriSet.add(industri);
        industriIdMap[industri] = industriId;
      }
    }

    final industriList = industriSet.toList()..sort();

    final List<Map<String, dynamic>> newIndustriList = [];
    for (var industri in industriList) {
      newIndustriList.add({
        'nama': industri,
        'id': industriIdMap[industri],
      });
    }

    setState(() {
      _kelasList = newKelasList;
      _industriList = newIndustriList;
      _filteredIndustriList = List.from(newIndustriList);
    });
  }

  // Fungsi untuk update filtered industri berdasarkan kelas yang dipilih
  void _updateFilteredIndustri() {
    if (_selectedKelasId == null) {
      // Jika tidak ada kelas yang dipilih, tampilkan semua industri
      setState(() {
        _filteredIndustriList = List.from(_industriList);
        // Reset industri yang dipilih jika tidak sesuai
        if (_selectedIndustriId != null) {
          bool industriValid = false;
          for (var industri in _industriList) {
            if (industri['id'] == _selectedIndustriId) {
              industriValid = true;
              break;
            }
          }
          if (!industriValid) {
            _selectedIndustriId = null;
            _selectedIndustriNama = null;
          }
        }
      });
    } else {
      // Filter industri berdasarkan kelas yang dipilih
      final industriIdsForKelas = _industriByKelas[_selectedKelasId] ?? [];

      final List<Map<String, dynamic>> filtered = [];

      for (var industriId in industriIdsForKelas) {
        final industriNama = _industriMap[industriId];
        if (industriNama != null) {
          filtered.add({
            'id': industriId,
            'nama': industriNama,
          });
        }
      }

      // Sort filtered industri by name
      filtered
          .sort((a, b) => (a['nama'] as String).compareTo(b['nama'] as String));

      setState(() {
        _filteredIndustriList = filtered;

        // Reset selected industri jika tidak ada di filtered list
        if (_selectedIndustriId != null) {
          bool isValid = false;
          for (var industri in filtered) {
            if (industri['id'] == _selectedIndustriId) {
              isValid = true;
              break;
            }
          }
          if (!isValid) {
            _selectedIndustriId = null;
            _selectedIndustriNama = null;
          }
        }
      });
    }
  }

  // Ambil nama guru
  Future<String> _getGuruName(int guruId) async {
    if (_guruCache.containsKey(guruId)) {
      return _guruCache[guruId]!;
    }

    try {
      final response = await http.get(
        Uri.parse('${widget.baseUrl}/api/guru/$guruId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final guruName = data['data']['nama'] ?? 'Guru $guruId';
          _guruCache[guruId] = guruName;
          return guruName;
        }
      }
    } catch (e) {
      print('❌ Error loading guru: $e');
    }
    return 'Guru ID: $guruId';
  }

  // Load data penilaian
  Future<void> _loadPenilaian({bool reset = false}) async {
    if (reset) {
      setState(() {
        _currentPage = 1;
        _penilaianList = [];
        _hasMorePages = true;
      });
    }

    if (!_hasMorePages && !reset) return;

    setState(() {
      if (_currentPage == 1) {
        _isLoading = true;
      } else {
        _isLoadingMore = true;
      }
      _errorMessage = null;
    });

    try {
      final queryParams = <String, String>{
        'page': _currentPage.toString(),
        'limit': '20',
      };

      if (_selectedKelasId != null) {
        queryParams['kelas_id'] = _selectedKelasId.toString();
      }

      if (_selectedIndustriId != null) {
        queryParams['industri_id'] = _selectedIndustriId.toString();
      }

      if (_searchQuery.isNotEmpty) {
        queryParams['search'] = _searchQuery;
      }

      final uri = Uri.parse('${widget.baseUrl}/api/penilaian/review')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data.containsKey('data')) {
          final newItems = data['data'] as List? ?? [];

          setState(() {
            if (_currentPage == 1) {
              _penilaianList = newItems;
            } else {
              _penilaianList.addAll(newItems);
            }
            _totalData = data['total'] ?? 0;
            _hasMorePages = (_penilaianList.length < _totalData);

            // Extract unique values untuk dropdown
            _extractUniqueValues();
            // Update filtered industri berdasarkan kelas yang dipilih
            _updateFilteredIndustri();
          });

          // Load nama guru untuk items baru
          _loadGuruNamesForItems(newItems);
        }
      } else if (response.statusCode == 401) {
        _redirectToLogin();
      } else {
        setState(() {
          _errorMessage = 'Gagal memuat data (${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  // Fungsi format tanggal untuk CSV
  String _formatDateCSV(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';

    try {
      final date = DateTime.parse(dateString);

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

      return '${date.day} ${bulan[date.month - 1]} ${date.year}';
    } catch (e) {
      return '-';
    }
  }

  // Load nama guru untuk items
  Future<void> _loadGuruNamesForItems(List<dynamic> items) async {
    final List<int> guruIds = [];

    for (var item in items) {
      final guruId = item['pembimbing_guru_id'];
      if (guruId != null && !_guruCache.containsKey(guruId)) {
        guruIds.add(guruId);
      }
    }

    for (var guruId in guruIds) {
      await _getGuruName(guruId);
    }

    if (mounted) setState(() {});
  }

  void _loadMore() {
    if (_hasMorePages && !_isLoadingMore && !_isLoading) {
      setState(() => _currentPage++);
      _loadPenilaian();
    }
  }

  void _filterReview(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
      _loadPenilaian(reset: true);
    });
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  // Fungsi apply filters
  void _applyFilters() {
    setState(() {
      _showFilters = false;
    });
    _loadPenilaian(reset: true);
  }

  // Fungsi reset filters
  void _resetFilters() {
    setState(() {
      _selectedKelasId = null;
      _selectedIndustriId = null;
      _selectedKelasNama = null;
      _selectedIndustriNama = null;
      _showFilters = false;
      _filteredIndustriList = List.from(_industriList);
    });
    _loadPenilaian(reset: true);
  }

  // Handler untuk perubahan kelas
  void _onKelasChanged(int? kelasId) {
    setState(() {
      _selectedKelasId = kelasId;

      // Cari nama kelas
      if (kelasId != null) {
        _selectedKelasNama = _kelasMap[kelasId];
      } else {
        _selectedKelasNama = null;
      }

      // Update filtered industri berdasarkan kelas yang dipilih
      _updateFilteredIndustri();
    });

    // Jangan langsung apply filter, biarkan user memilih industri dulu
  }

  // Handler untuk perubahan industri
  void _onIndustriChanged(int? industriId) {
    setState(() {
      _selectedIndustriId = industriId;

      // Cari nama industri
      if (industriId != null) {
        _selectedIndustriNama = _industriMap[industriId];
      } else {
        _selectedIndustriNama = null;
      }
    });

    // Apply filter setelah industri dipilih
    _applyFilters();
  }

  // Export ke CSV
  Future<void> _exportToCSV() async {
    if (_penilaianList.isEmpty) {
      _tampilkanSnackBar('Tidak ada data untuk diekspor', isError: true);
      return;
    }

    setState(() => _isExporting = true);

    try {
      // Buat CSV header dengan tambahan Sakit, Izin, Alpa, dan Predikat
      String csv = 'No,Nama Siswa,NISN,Kelas,Konsentrasi Keahlian,Industri,'
          'Pembimbing,Sakit,Izin,Alpa,Total Skor,Rata-rata,Predikat,Tanggal Finalisasi\n';

      for (var i = 0; i < _penilaianList.length; i++) {
        final item = _penilaianList[i];
        final guruId = item['pembimbing_guru_id'];
        String guruName = 'Guru ID: $guruId';

        // Coba dapatkan nama guru dari cache
        if (guruId != null && _guruCache.containsKey(guruId)) {
          guruName = _guruCache[guruId]!;
        }

        // Hitung rata-rata dan predikat
        final double rataRata =
            double.tryParse(item['rata_rata']?.toString() ?? '0') ?? 0;
        final String predikat = _getPredikatFromRataRata(rataRata);

        csv += '${i + 1},';
        csv += '"${item['siswa_username'] ?? ''}",';
        csv += '"${item['siswa_nisn'] ?? ''}",';
        csv += '"${item['kelas_nama'] ?? ''}",';
        csv += '"${item['jurusan_nama'] ?? ''}",';
        csv += '"${item['industri_nama'] ?? ''}",';
        csv += '"$guruName",';
        csv += '0,'; // Sakit (default 0)
        csv += '0,'; // Izin (default 0)
        csv += '0,'; // Alpa (default 0)
        csv += '${item['total_skor'] ?? 0},';
        csv += '"${rataRata.toStringAsFixed(2)}",';
        csv += '"$predikat",';

        // Gunakan fungsi format tanggal CSV
        final tgl = item['finalized_at'] != null
            ? _formatDateCSV(item['finalized_at'])
            : '-';
        csv += '"$tgl"\n';
      }

      // Simpan file
      final tempDir = await getTemporaryDirectory();
      final String fileName =
          'review-penilaian-${DateFormat('yyyyMMdd-HHmmss').format(DateTime.now())}.csv';
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsString(csv, encoding: utf8);

      // Bagikan file
      await Share.shareXFiles(
        [XFile(tempFile.path, mimeType: 'text/csv')],
        text:
            'Tinjau Penilaian PKL - ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
      );

      if (mounted) _tampilkanSnackBar('Berkas CSV berhasil diekspor');
    } catch (e) {
      if (mounted) _tampilkanSnackBar('Gagal mengekspor: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _tampilkanSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _redirectToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  String _formatDateIndonesian(String? dateString) {
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

  String _getInitials(String name) {
    if (name.isEmpty) return 'S';
    final parts = name.split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Color _getScoreTextColor(double score) {
    if (score >= 90) return _successColor;
    if (score >= 75) return _warningColor;
    return Colors.red;
  }

  double _hitungRataRataKeseluruhan() {
    if (_penilaianList.isEmpty) return 0;
    double total = 0;
    int count = 0;
    for (var item in _penilaianList) {
      final rataRata = double.tryParse(item['rata_rata']?.toString() ?? '0');
      if (rataRata != null) {
        total += rataRata;
        count++;
      }
    }
    return count == 0 ? 0 : total / count;
  }

  @override
  Widget build(BuildContext context) {
    // Tambahkan bottom padding untuk menghindari bottombar
    final bottomPadding = MediaQuery.of(context).padding.bottom + 80;

    return Scaffold(
      backgroundColor: _backgroundLight,
      body: Column(
        children: [
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
                        Icons.rate_review_rounded,
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
                            'Tinjau Penilaian',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tinjau Hasil PKL',
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
                Row(
                  children: [
                    Expanded(
                      child: Container(
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
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: _filterReview,
                                decoration: InputDecoration(
                                  hintText: 'Cari siswa, kelas, industri...',
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                  prefixIcon: Icon(Icons.search_rounded,
                                      color: _primaryColor),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear,
                                              color: Colors.grey),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() => _searchQuery = '');
                                            _loadPenilaian(reset: true);
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
                            Container(
                              height: 46,
                              width: 1,
                              color: _borderSoft,
                            ),
                            IconButton(
                              icon: Icon(
                                _showFilters
                                    ? Icons.filter_alt_off_rounded
                                    : Icons.filter_alt_rounded,
                                color: _primaryColor,
                              ),
                              onPressed: _toggleFilters,
                              tooltip: 'Filter',
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
          Expanded(
            child: _isLoading && _penilaianList.isEmpty
                ? _buildSkeletonLoading()
                : RefreshIndicator(
                    onRefresh: () => _loadPenilaian(reset: true),
                    color: _primaryColor,
                    child: CustomScrollView(
                      controller: _internalScrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        if (_showFilters) ...[
                          SliverToBoxAdapter(
                            child: _buildFilterSection(),
                          ),
                        ],
                        SliverToBoxAdapter(
                          child: _buildStatsCard(),
                        ),
                        SliverToBoxAdapter(
                          child: _buildExportButton(),
                        ),

                        _errorMessage != null
                            ? SliverFillRemaining(child: _buildErrorState())
                            : _penilaianList.isEmpty
                                ? SliverFillRemaining(child: _buildEmptyState())
                                : SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        if (index == _penilaianList.length) {
                                          if (_hasMorePages) {
                                            _loadMore();
                                            return const Padding(
                                              padding: EdgeInsets.all(16),
                                              child: Center(
                                                  child:
                                                      CircularProgressIndicator()),
                                            );
                                          }
                                          return const SizedBox.shrink();
                                        }

                                        final item = _penilaianList[index];
                                        return _buildPenilaianCard(item);
                                      },
                                      childCount: _penilaianList.length +
                                          (_hasMorePages ? 1 : 0),
                                    ),
                                  ),

                        // Tambahkan bottom padding
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

  // Filter section dengan kelas dulu baru industri
  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: _primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.filter_alt_rounded,
                  color: _primaryColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Filter',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _primaryColor,
                ),
              ),
              const Spacer(),
              // Tampilkan info filter aktif
              if (_selectedKelasId != null || _selectedIndustriId != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(_selectedKelasId != null ? 1 : 0) + (_selectedIndustriId != null ? 1 : 0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Dropdown Kelas (URUTAN PERTAMA)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _selectedKelasId != null
                    ? _primaryColor
                    : Colors.grey.shade300,
              ),
            ),
            child: DropdownButtonFormField<int?>(
              value: _selectedKelasId,
              decoration: InputDecoration(
                labelText: 'Kelas',
                labelStyle: TextStyle(
                  color: _selectedKelasId != null
                      ? _primaryColor
                      : Colors.grey.shade600,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                prefixIcon: Icon(
                  Icons.class_rounded,
                  size: 18,
                  color: _selectedKelasId != null
                      ? _primaryColor
                      : Colors.grey.shade400,
                ),
              ),
              icon: Icon(
                Icons.arrow_drop_down_rounded,
                color: _primaryColor,
              ),
              dropdownColor: Colors.white,
              isExpanded: true,
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Row(
                    children: [
                      Icon(
                        Icons.clear_all_rounded,
                        size: 16,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Semua Kelas',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                ..._kelasList.map((k) {
                  final kelasId = k['id'];
                  final kelasNama = k['nama'] ?? '';

                  return DropdownMenuItem<int?>(
                    value: kelasId,
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: _primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            kelasNama,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        // Tampilkan jumlah industri untuk kelas ini
                        if (_industriByKelas.containsKey(kelasId))
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: _primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_industriByKelas[kelasId]?.length ?? 0} Industri',
                              style: TextStyle(
                                fontSize: 8,
                                color: _primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
              onChanged: _onKelasChanged,
            ),
          ),
          const SizedBox(height: 12),

          // Dropdown Industri (URUTAN KEDUA, tergantung kelas yang dipilih)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _selectedIndustriId != null
                    ? _primaryColor
                    : Colors.grey.shade300,
              ),
            ),
            child: DropdownButtonFormField<int?>(
              value: _selectedIndustriId,
              decoration: InputDecoration(
                labelText: _selectedKelasId == null
                    ? 'Pilih Kelas Terlebih Dahulu'
                    : 'Industri',
                labelStyle: TextStyle(
                  color: _selectedIndustriId != null
                      ? _primaryColor
                      : Colors.grey.shade600,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                prefixIcon: Icon(
                  Icons.business_center_rounded,
                  size: 18,
                  color: _selectedIndustriId != null
                      ? _primaryColor
                      : Colors.grey.shade400,
                ),
              ),
              icon: Icon(
                Icons.arrow_drop_down_rounded,
                color: _primaryColor,
              ),
              dropdownColor: Colors.white,
              isExpanded: true,
              // Disable jika belum pilih kelas
              items: _selectedKelasId == null
                  ? [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Pilih kelas terlebih dahulu',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontStyle: FontStyle.italic,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]
                  : [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Row(
                          children: [
                            Icon(
                              Icons.clear_all_rounded,
                              size: 16,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Semua Industri',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ..._filteredIndustriList.map((i) {
                        final industriId = i['id'];
                        final industriNama = i['nama'] ?? '';

                        return DropdownMenuItem<int?>(
                          value: industriId,
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: _primaryColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  industriNama,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
              onChanged: _selectedKelasId == null ? null : _onIndustriChanged,
            ),
          ),
          const SizedBox(height: 12),

          // Informasi jumlah data dan tombol reset
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: _primaryColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${_penilaianList.length} data ditampilkan',
                    style: TextStyle(
                      fontSize: 12,
                      color: _primaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_selectedKelasId != null || _selectedIndustriId != null)
                  TextButton(
                    onPressed: _resetFilters,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(40, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Reset',
                      style: TextStyle(
                        color: _primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Info tambahan
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 14,
                  color: _primaryColor,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Pilih kelas terlebih dahulu, baru pilih industri',
                    style: TextStyle(
                      fontSize: 10,
                      color: _primaryColor,
                      fontWeight: FontWeight.w500,
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

  Widget _buildStatsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(
              icon: Icons.assessment,
              value: '$_totalData',
              label: 'Total Data',
            ),
            Container(
              height: 40,
              width: 1,
              color: Colors.white.withOpacity(0.3),
            ),
            _buildStatItem(
              icon: Icons.filter_list,
              value: _selectedKelasId != null || _selectedIndustriId != null
                  ? 'Aktif'
                  : 'Semua',
              label: 'Filter',
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
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: _isExporting || _penilaianList.isEmpty ? null : _exportToCSV,
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
          _isExporting ? 'MENGEKSPOR...' : 'EKSPOR',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildPenilaianCard(dynamic item) {
    final double rataRata =
        double.tryParse(item['rata_rata']?.toString() ?? '0') ?? 0;
    final Color scoreColor = _getScoreTextColor(rataRata);
    final String predikat = _getPredikatFromRataRata(rataRata);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDetailPenilaian(item['application_id']),
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _borderSoft),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _primaryColor.withOpacity(0.2),
                            _primaryColor.withOpacity(0.1)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(item['siswa_username'] ?? 'S'),
                          style: TextStyle(
                            color: _primaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['siswa_username'] ?? 'Tanpa Nama',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item['kelas_nama'] ?? '-',
                              style: TextStyle(
                                color: _primaryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(height: 1, color: _borderSoft),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Industri',
                            style: TextStyle(
                              fontSize: 11,
                              color: _neutralColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['industri_nama'] ?? '-',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: _primaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: scoreColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: scoreColor.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Rata-rata',
                            style: TextStyle(
                              fontSize: 9,
                              color: scoreColor,
                            ),
                          ),
                          Text(
                            rataRata.toStringAsFixed(1),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: scoreColor,
                            ),
                          ),
                          Text(
                            predikat,
                            style: TextStyle(
                              fontSize: 8,
                              color: scoreColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: _neutralColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Selesai: ${_formatDateIndonesian(item['finalized_at'])}',
                      style: TextStyle(
                        fontSize: 11,
                        color: _neutralColor,
                      ),
                    ),
                    const Spacer(),
                    FutureBuilder<String>(
                      future: _getGuruName(item['pembimbing_guru_id'] ?? 0),
                      builder: (context, snapshot) {
                        final guruName = snapshot.data ?? 'Memuat...';
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                size: 10,
                                color: _primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                guruName.length > 15
                                    ? '${guruName.substring(0, 12)}...'
                                    : guruName,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  color: _primaryColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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

  Future<void> _showDetailPenilaian(int applicationId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final response = await http.get(
        Uri.parse('${widget.baseUrl}/api/penilaian/review/$applicationId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (response.statusCode == 200) {
        jsonDecode(response.body);

        // Ambil data siswa dari list yang sudah ada
        final siswaItem = _penilaianList.firstWhere(
          (e) => e['application_id'] == applicationId,
          orElse: () => {},
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReviewKaprogDetailScreen(
              applicationId: applicationId,
              reviewData: siswaItem,
              token: widget.token,
              baseUrl: widget.baseUrl,
            ),
          ),
        );
      } else {
        _tampilkanSnackBar('Gagal memuat detail', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _tampilkanSnackBar('Gagal memuat detail', isError: true);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada data penilaian',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Belum ada penilaian yang difinalisasi',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _loadPenilaian(reset: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('REFRESH'),
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
            size: 80,
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
            onPressed: () => _loadPenilaian(reset: true),
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

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==================== HALAMAN DETAIL REVIEW UNTUK KAPROG ====================
class ReviewKaprogDetailScreen extends StatefulWidget {
  final int applicationId;
  final Map<String, dynamic> reviewData;
  final String token;
  final String baseUrl;

  const ReviewKaprogDetailScreen({
    super.key,
    required this.applicationId,
    required this.reviewData,
    required this.token,
    required this.baseUrl,
  });

  @override
  State<ReviewKaprogDetailScreen> createState() =>
      _ReviewKaprogDetailScreenState();
}

class _ReviewKaprogDetailScreenState extends State<ReviewKaprogDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _detailData;
  List<Map<String, dynamic>> _formItems = [];
  List<Map<String, dynamic>> _nilaiItems = [];

  late Map<String, dynamic> _siswaData;

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

  String _formatDateIndonesian(String? dateString) {
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

  // Fungsi helper deskripsi
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

  Future<void> _fetchDetailData() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse(
            '${widget.baseUrl}/api/penilaian/review/${widget.applicationId}'),
        headers: {
          'accept': 'application/json',
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

  String _getDeskripsiKompetensi(int nomorKompetensi, int skor) {
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

  @override
  Widget build(BuildContext context) {
    final String siswaUsername = _siswaData['siswa_username'] ?? '-';
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
          'Detail Penilaian',
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
                  // Card Informasi Siswa
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
                                        fontSize: 11, color: _neutralColor),
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
                                        fontSize: 11, color: _neutralColor),
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
                            Icon(Icons.business_center_rounded,
                                size: 16, color: _neutralColor),
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

                  // Card Form Penilaian
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
                                      fontSize: 11, color: _neutralColor),
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

                  // Detail Nilai Kompetensi dengan Deskripsi
                  if (_formItems.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'Detail Nilai',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_formItems.length, (index) {
                      final formItem = _formItems[index];
                      final nomor = index + 1;

                      final nilaiItem = _nilaiItems.firstWhere(
                        (item) => item['form_item_id'] == formItem['id'],
                        orElse: () => {},
                      );

                      final int skor = nilaiItem['skor'] ?? 0;
                      final String predikat = nilaiItem['deskripsi'] ?? '-';

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

                            // Deskripsi Capaian
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
                                          _getDeskripsiKompetensi(nomor, skor),
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

                  // Catatan Akhir
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
                              Icon(Icons.note_alt_rounded,
                                  size: 20, color: _primaryColor),
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

                  // Ringkasan Total Skor
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
                                      color: Colors.white70, fontSize: 12),
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
                                width: 1, height: 40, color: Colors.white30),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Rata-rata',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12),
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
                        const Divider(height: 1, color: Colors.white30),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 14, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text(
                              'Selesai: ${_formatDateIndonesian(finalizedAt)}',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
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