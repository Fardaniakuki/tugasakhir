import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import '../login/login_screen.dart';

class PenilaianPage extends StatefulWidget {
  const PenilaianPage({super.key});

  @override
  State<PenilaianPage> createState() => _PenilaianPageState();
}

class _PenilaianPageState extends State<PenilaianPage> {
  List<Map<String, dynamic>> _siswaList = [];
  List<Map<String, dynamic>> _filteredSiswaList = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Filter tabs - hanya Belum dan Selesai
  int _selectedFilter = 0; // 0: Belum Dinilai, 1: Selesai Dinilai

  // Pagination
  int _currentPage = 1;
  int _totalItems = 0;
  final int _itemsPerPage = 10;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

  // Warna tema
  final Color _primaryColor = const Color(0xFF6B1B1B);
  final Color _primaryLight = const Color(0xFFFCE8E8);
  final Color _selesaiColor = const Color(0xFF2E7D32);
  final Color _neutralColor = const Color(0xFF757575);
  final Color _backgroundLight = const Color(0xFFF5F5F5);
  final Color _cardColor = Colors.white;
  final Color _borderSoft = const Color(0xFFEEEEEE);
  final Color _belumColor = const Color(0xFFED6C02);

  @override
  void initState() {
    super.initState();
    _fetchSiswaList(reset: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSiswaList({bool reset = false}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _siswaList.clear();
        _filteredSiswaList.clear();
        _hasMoreData = true;
      });
    } else {
      if (!_hasMoreData || _isLoadingMore) return;
      setState(() => _isLoadingMore = true);
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      _redirectToLogin();
      return;
    }

    try {
      final queryParams = {
        'page': _currentPage.toString(),
        'limit': _itemsPerPage.toString(),
        if (_searchQuery.isNotEmpty) 'search': _searchQuery,
        if (_selectedFilter == 0) 'status': 'belum_dinilai',
        if (_selectedFilter == 1) 'status': 'sudah_dinilai',
      };

      final uri = Uri.parse(
              '${dotenv.env['API_BASE_URL']}/api/penilaian/pembimbing/students')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          if (reset) {
            _siswaList = List<Map<String, dynamic>>.from(data['data'] ?? []);
          } else {
            _siswaList
                .addAll(List<Map<String, dynamic>>.from(data['data'] ?? []));
          }

          _totalItems = data['total'] ?? 0;
          _hasMoreData = _siswaList.length < _totalItems;
          _currentPage++;
          _applySearchFilter();
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else if (response.statusCode == 401) {
        _redirectToLogin();
      } else {
        throw Exception('Gagal memuat data siswa');
      }
    } catch (e) {
      print('Error fetching siswa list: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
        _showSnackBar('Gagal memuat data siswa', isError: true);
      }
    }
  }

  void _applySearchFilter() {
    if (_searchQuery.isEmpty) {
      _filteredSiswaList = List.from(_siswaList);
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredSiswaList = _siswaList.where((siswa) {
        final nama = (siswa['siswa_username'] ?? '').toLowerCase();
        final industri = (siswa['industri_nama'] ?? '').toLowerCase();
        return nama.contains(query) || industri.contains(query);
      }).toList();
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

  void _filterSiswa(String query) {
    setState(() {
      _searchQuery = query;
      _applySearchFilter();
    });
    _fetchSiswaList(reset: true);
  }

  void _changeFilter(int index) {
    setState(() {
      _selectedFilter = index;
    });
    _fetchSiswaList(reset: true);
  }

  String _getStatusLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'sudah_dinilai':
        return 'Selesai';
      case 'belum_dinilai':
        return 'Belum Dinilai';
      default:
        return '-';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'sudah_dinilai':
        return _selesaiColor;
      case 'belum_dinilai':
        return _belumColor;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'sudah_dinilai':
        return Icons.check_circle_rounded;
      case 'belum_dinilai':
        return Icons.pending_actions_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundLight,
      body: _isLoading && _siswaList.isEmpty
          ? _buildSkeletonLoading()
          : RefreshIndicator(
              onRefresh: () => _fetchSiswaList(reset: true),
              color: _primaryColor,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 50, 20, 25),
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryColor.withValues(alpha: 0.3),
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
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: const Icon(
                                  Icons.assignment_turned_in_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Penilaian PKL',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$_totalItems siswa bimbingan',
                                      style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.9),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              children: [
                                _buildFilterChip('Belum Dinilai', 0),
                                _buildFilterChip('Selesai', 1),
                              ],
                            ),
                          ),
                          const SizedBox(height: 15),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: _filterSiswa,
                              decoration: InputDecoration(
                                hintText: 'Cari nama siswa',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                prefixIcon: Icon(Icons.search_rounded,
                                    color: _primaryColor),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(Icons.close_rounded,
                                            color: _neutralColor),
                                        onPressed: () {
                                          _searchController.clear();
                                          _filterSiswa('');
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
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: _filteredSiswaList.isEmpty
                        ? SliverFillRemaining(
                            child: Center(
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
                                          color: Colors.grey
                                              .withValues(alpha: 0.2),
                                          blurRadius: 20,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _selectedFilter == 0
                                          ? Icons.inbox_rounded
                                          : Icons.check_circle_outline_rounded,
                                      size: 50,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'Tidak ada siswa yang cocok'
                                        : _selectedFilter == 0
                                            ? 'Belum ada siswa yang perlu dinilai'
                                            : 'Belum ada siswa yang selesai',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (_searchQuery.isNotEmpty)
                                    TextButton(
                                      onPressed: () {
                                        _searchController.clear();
                                        _filterSiswa('');
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: _primaryColor,
                                      ),
                                      child: const Text('Reset Pencarian'),
                                    ),
                                ],
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index >= _filteredSiswaList.length - 2 &&
                                    _hasMoreData &&
                                    !_isLoadingMore) {
                                  _fetchSiswaList();
                                }
                                final siswa = _filteredSiswaList[index];
                                return _buildSiswaCard(siswa);
                              },
                              childCount: _filteredSiswaList.length,
                            ),
                          ),
                  ),
                  if (_isLoadingMore)
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: _primaryColor,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _selectedFilter == index;
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _changeFilter(index),
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? _primaryColor : Colors.white,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSiswaCard(Map<String, dynamic> siswa) {
    final status = siswa['penilaian_status'];
    final statusLabel = _getStatusLabel(status);
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final isSelesai = status == 'sudah_dinilai';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToPenilaianDetail(siswa),
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _borderSoft),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
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
                          colors: isSelesai
                              ? [
                                  _selesaiColor.withValues(alpha: 0.2),
                                  _selesaiColor.withValues(alpha: 0.1)
                                ]
                              : [
                                  _primaryColor.withValues(alpha: 0.2),
                                  _primaryColor.withValues(alpha: 0.1)
                                ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(siswa['siswa_username'] ?? 'S'),
                          style: TextStyle(
                            color: isSelesai ? _selesaiColor : _primaryColor,
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
                            siswa['siswa_username'] ?? 'Tanpa Nama',
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
                              siswa['kelas_nama'] ?? '-',
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusIcon,
                            size: 12,
                            color: statusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Container(height: 1, color: _borderSoft),
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
                        siswa['industri_nama'] ?? 'Industri tidak diketahui',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _primaryColor,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelesai
                            ? _selesaiColor.withValues(alpha: 0.1)
                            : _primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isSelesai ? 'Lihat Nilai' : 'Beri Penilaian',
                            style: TextStyle(
                              color: isSelesai ? _selesaiColor : _primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            isSelesai
                                ? Icons.visibility_rounded
                                : Icons.edit_rounded,
                            size: 14,
                            color: isSelesai ? _selesaiColor : _primaryColor,
                          ),
                        ],
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

  String _getInitials(String name) {
    if (name.isEmpty) return 'S';
    final parts = name.split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  void _navigateToPenilaianDetail(Map<String, dynamic> siswa) {
    final isSelesai = siswa['penilaian_status'] == 'sudah_dinilai';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PenilaianDetailScreen(
          siswaData: siswa,
          applicationId: siswa['application_id'],
          readOnly: isSelesai,
        ),
      ),
    ).then((shouldRefresh) {
      if (shouldRefresh == true) {
        _fetchSiswaList(reset: true);
      }
    });
  }

  Widget _buildSkeletonLoading() {
    return Container(
      color: _backgroundLight,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 25),
              color: _primaryColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 150,
                            height: 24,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 100,
                            height: 16,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                childCount: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ==================== HALAMAN DETAIL PENILAIAN ====================

class PenilaianDetailScreen extends StatefulWidget {
  final Map<String, dynamic> siswaData;
  final int applicationId;
  final bool readOnly;

  const PenilaianDetailScreen({
    super.key,
    required this.siswaData,
    required this.applicationId,
    this.readOnly = false,
  });

  @override
  State<PenilaianDetailScreen> createState() => _PenilaianDetailScreenState();
}

class _PenilaianDetailScreenState extends State<PenilaianDetailScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isGeneratingAssessment = false;
  List<Map<String, dynamic>> _formItems = [];
  List<Map<String, dynamic>> _nilaiItems = [];
  final TextEditingController _catatanController = TextEditingController();
  String _status = 'belum_dinilai';

  // Controllers untuk setiap item nilai
  final List<TextEditingController> _skorControllers = [];
  final List<TextEditingController> _deskripsiControllers = [];

  // Fungsi untuk mendapatkan predikat berdasarkan nilai (OTOMATIS, TANPA DROPDOWN)
  String _getPredikatFromNilai(int nilai) {
    if (nilai >= 86 && nilai <= 100) {
      return 'Sangat Baik';
    } else if (nilai >= 75 && nilai <= 85) {
      return 'Baik';
    } else if (nilai >= 60 && nilai <= 74) {
      return 'Cukup';
    } else {
      return 'Perlu Peningkatan';
    }
  }

  // Untuk hasil PKL (dari rata-rata nilai)
  String _getHasilPKL(double average) {
    if (average >= 90) return 'Amat Baik';
    if (average >= 80) return 'Baik';
    if (average >= 70) return 'Cukup';
    return 'Perlu Peningkatan';
  }

  final Color _primaryColor = const Color(0xFF6B1B1B);
  final Color _primaryLight = const Color(0xFFFCE8E8);
  final Color _selesaiColor = const Color(0xFF2E7D32);
  final Color _borderSoft = const Color(0xFFEEEEEE);
  final Color _backgroundLight = const Color(0xFFF5F5F5);
  final Color _neutralColor = const Color(0xFF757575);
  final Color _errorColor = const Color(0xFFD32F2F);

  @override
  void initState() {
    super.initState();
    _fetchPenilaianData();
  }

  @override
  void dispose() {
    _catatanController.dispose();
    for (var controller in _skorControllers) {
      controller.dispose();
    }
    for (var controller in _deskripsiControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchPenilaianData() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      _redirectToLogin();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            '${dotenv.env['API_BASE_URL']}/api/penilaian/applications/${widget.applicationId}'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _formItems =
              List<Map<String, dynamic>>.from(data['form_items'] ?? []);

          final items = data['items'] as List? ?? [];
          _nilaiItems = List<Map<String, dynamic>>.from(items);

          _status = data['status'] ?? 'belum_dinilai';
          _catatanController.text = data['catatan_akhir'] ?? '';

          _initializeControllers();
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        _redirectToLogin();
      } else {
        throw Exception('Gagal memuat data penilaian');
      }
    } catch (e) {
      print('Error fetching penilaian data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Gagal memuat data penilaian', isError: true);
      }
    }
  }

  void _initializeControllers() {
    _skorControllers.clear();
    _deskripsiControllers.clear();

    for (var formItem in _formItems) {
      final formItemId = formItem['id'];

      final existingItem = _nilaiItems.firstWhere(
        (item) => item['form_item_id'] == formItemId,
        orElse: () => {},
      );

      final skorController = TextEditingController(
        text: existingItem['skor']?.toString() ?? '',
      );
      
      _skorControllers.add(skorController);

      // Untuk deskripsi, jika ada data existing gunakan itu, jika tidak kosongkan dulu
      final deskripsiController = TextEditingController(
        text: existingItem['deskripsi'] ?? '',
      );
      _deskripsiControllers.add(deskripsiController);
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

  bool _validateInputs() {
    for (var i = 0; i < _skorControllers.length; i++) {
      final skorText = _skorControllers[i].text;
      if (skorText.isEmpty) {
        _showSnackBar('Harap isi semua nilai', isError: true);
        return false;
      }

      final skor = int.tryParse(skorText);
      if (skor == null) {
        _showSnackBar('Nilai harus berupa angka', isError: true);
        return false;
      }
      
      if (skor < 0 || skor > 100) {
        _showSnackBar('Nilai harus antara 0 - 100', isError: true);
        return false;
      }
    }
    return true;
  }

  // Fungsi untuk memformat input nilai (mencegah lebih dari 3 digit dan range 0-100)
  String _formatNilaiInput(String value) {
    if (value.isEmpty) return '';
    
    // Hanya ambil angka
    final String filtered = value.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (filtered.isEmpty) return '';
    
    // Konversi ke integer
    int? number = int.tryParse(filtered);
    if (number == null) return '';
    
    // Batasi maksimal 100
    if (number > 100) {
      number = 100;
    }
    
    // Batasi minimal 0
    if (number < 0) {
      number = 0;
    }
    
    return number.toString();
  }

  // ==================== FUNGSI SIMPAN DRAFT ====================
  Future<void> _simpanDraft() async {
    print('=== SIMPAN DRAFT DIPANGGIL ===');
    if (!_validateInputs()) return;

    setState(() => _isSaving = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      _redirectToLogin();
      return;
    }

    try {
      final List<Map<String, dynamic>> items = [];
      for (var i = 0; i < _formItems.length; i++) {
        items.add({
          'form_item_id': _formItems[i]['id'],
          'skor': int.parse(_skorControllers[i].text),
          'deskripsi': _deskripsiControllers[i].text,
        });
      }

      final body = {
        'catatan_akhir': _catatanController.text,
        'items': items,
      };

      final response = await http.put(
        Uri.parse(
            '${dotenv.env['API_BASE_URL']}/api/penilaian/applications/${widget.applicationId}/draft'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _status = data['status'] ?? 'draft';
        });
        _showSnackBar('Draft berhasil disimpan');
        
        await _fetchPenilaianData();
        Navigator.pop(context, true);
      } else if (response.statusCode == 409) {
        _showSnackBar('Tidak bisa menyimpan draft karena sudah final', isError: true);
      } else {
        throw Exception('Gagal menyimpan draft: ${response.statusCode}');
      }
    } catch (e) {
      print('Error saving draft: $e');
      _showSnackBar('Gagal menyimpan draft', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ==================== FUNGSI SELESAIKAN ====================
  Future<void> _selesaiKan() async {
    print('=== SELESAIKAN DIPANGGIL ===');
    if (!_validateInputs()) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text(
            'Setelah diselesaikan, nilai tidak dapat diubah lagi. Lanjutkan?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: _neutralColor,
            ),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _selesaiColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Ya, Selesaikan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      _redirectToLogin();
      return;
    }

    try {
      // LANGKAH 1: Simpan draft terlebih dahulu
      final List<Map<String, dynamic>> items = [];
      for (var i = 0; i < _formItems.length; i++) {
        items.add({
          'form_item_id': _formItems[i]['id'],
          'skor': int.parse(_skorControllers[i].text),
          'deskripsi': _deskripsiControllers[i].text,
        });
      }

      final draftBody = {
        'catatan_akhir': _catatanController.text,
        'items': items,
      };
      
      final draftResponse = await http.put(
        Uri.parse(
            '${dotenv.env['API_BASE_URL']}/api/penilaian/applications/${widget.applicationId}/draft'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(draftBody),
      );

      if (draftResponse.statusCode != 200) {
        throw Exception('Gagal menyimpan draft: ${draftResponse.statusCode}');
      }

      // LANGKAH 2: Finalisasi
      final finalizeResponse = await http.post(
        Uri.parse(
            '${dotenv.env['API_BASE_URL']}/api/penilaian/applications/${widget.applicationId}/finalize'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (finalizeResponse.statusCode == 200) {
        setState(() => _status = 'sudah_dinilai');
        _showSnackBar('Penilaian berhasil diselesaikan');
        _showDocumentGenerationDialog();
      } else if (finalizeResponse.statusCode == 409) {
        _showSnackBar('Penilaian sudah pernah difinalisasi', isError: true);
        _fetchPenilaianData();
      } else {
        throw Exception(
            'Gagal menyelesaikan penilaian: ${finalizeResponse.statusCode}');
      }
    } catch (e) {
      print('Error finalizing: $e');
      _showSnackBar('Gagal menyelesaikan penilaian: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _showDocumentGenerationDialog() async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Penilaian Selesai'),
        content: const Text(
            'Penilaian berhasil diselesaikan. Apakah Anda ingin membuat form penilaian?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text('Nanti Saja'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _generateFormPenilaian();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Buat Form Penilaian'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateFormPenilaian() async {
    setState(() => _isGeneratingAssessment = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      _redirectToLogin();
      return;
    }

    try {
      final now = DateTime.now();
      final formattedDate = _formatDateIndonesian(now);

      final Map<String, dynamic> requestBody = {
        'school_info': {
          'alamat_jalan': 'Jalan Perusahaan No. 20',
          'email': 'smkn2singosari@yahoo.co.id',
          'kab_kota': 'Kab. Malang',
          'kecamatan': 'Singosari',
          'kelurahan': 'Tunjungtirto',
          'kode_pos': '65153',
          'logo_url':
              'https://upload.wikimedia.org/wikipedia/commons/7/74/Coat_of_arms_of_East_Java.svg',
          'nama_sekolah': 'SMK NEGERI 2 SINGOSARI',
          'provinsi': 'Jawa Timur',
          'telepon': '(0341) 4345127',
          'website': 'www.smkn2singosari.sch.id',
        },
        'siswa': {
          'nama': widget.siswaData['siswa_username'] ?? '',
          'nisn': widget.siswaData['nisn'] ?? '0012345678',
          'kelas': widget.siswaData['kelas_nama'] ?? '',
          'konsentrasi_keahlian':
              widget.siswaData['konsentrasi'] ?? 'Desain Komunikasi Visual',
          'tempat_pkl': widget.siswaData['industri_nama'] ?? '',
          'tanggal_mulai': _formatDateIndonesian(
              DateTime.now().subtract(const Duration(days: 180))),
          'tanggal_selesai': formattedDate,
          'nama_instruktur': 'Bapak / Ibu Pimpinan',
          'nama_pembimbing': 'Guru Mapel PKL',
        },
        'nilai': {
          'skor_1': int.tryParse(_skorControllers[0].text) ?? 0,
          'desc_1': _deskripsiControllers[0].text,
          'skor_2': int.tryParse(_skorControllers[1].text) ?? 0,
          'desc_2': _deskripsiControllers[1].text,
          'skor_3': int.tryParse(_skorControllers[2].text) ?? 0,
          'desc_3': _deskripsiControllers[2].text,
          'skor_4': int.tryParse(_skorControllers[3].text) ?? 0,
          'desc_4': _deskripsiControllers[3].text,
        },
        'sakit': 2,
        'izin': 1,
        'alpa': 0,
        'tempat_tanggal': 'Singosari, $formattedDate',
      };

      final response = await http.post(
        Uri.parse('${dotenv.env['SERTIF']}/api/v1/letters/penilaian'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _showSnackBar('Form penilaian berhasil dibuat');
        await _downloadFile(data['file_url'], data['filename']);
      } else {
        throw Exception('Gagal generate form penilaian');
      }
    } catch (e) {
      print('Error generating assessment: $e');
      _showSnackBar('Gagal generate form penilaian', isError: true);
    } finally {
      if (mounted) setState(() => _isGeneratingAssessment = false);
    }
  }

  Future<void> _downloadFile(String fileUrl, String filename) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      _redirectToLogin();
      return;
    }

    try {
      _showSnackBar('Mengunduh file...');

      final response = await http.get(
        Uri.parse('${dotenv.env['SERTIF']}$fileUrl'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$filename');
        await file.writeAsBytes(response.bodyBytes);

        _showSnackBar('File berhasil diunduh: $filename');
        await OpenFile.open(file.path);
      } else {
        throw Exception('Gagal mengunduh file');
      }
    } catch (e) {
      print('Error downloading file: $e');
      _showSnackBar('Gagal mengunduh file', isError: true);
    }
  }

  String _formatDateIndonesian(DateTime date) {
    const months = [
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  double _hitungRataRata() {
    if (_skorControllers.isEmpty) return 0;

    double total = 0;
    int validCount = 0;

    for (var controller in _skorControllers) {
      final skor = int.tryParse(controller.text);
      if (skor != null && skor >= 0 && skor <= 100) {
        total += skor;
        validCount++;
      }
    }

    return validCount > 0 ? total / validCount : 0;
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'S';
    final parts = name.split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bool isSelesai = _status == 'sudah_dinilai' || widget.readOnly;

    return Scaffold(
      backgroundColor: _backgroundLight,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          isSelesai ? 'Detail Penilaian' : 'Form Penilaian',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        actions: [
          if (isSelesai)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                if (value == 'penilaian') {
                  _generateFormPenilaian();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'penilaian',
                  child: Row(
                    children: [
                      Icon(Icons.assignment, size: 20),
                      SizedBox(width: 8),
                      Text('Generate Form Penilaian'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: _primaryColor,
              ),
            )
          : Stack(
              children: [
                GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.1),
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
                                        colors: isSelesai
                                            ? [
                                                _selesaiColor.withValues(
                                                    alpha: 0.2),
                                                _selesaiColor.withValues(
                                                    alpha: 0.1)
                                              ]
                                            : [
                                                _primaryColor.withValues(
                                                    alpha: 0.2),
                                                _primaryColor.withValues(
                                                    alpha: 0.1)
                                              ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _getInitials(widget
                                                .siswaData['siswa_username'] ??
                                            ''),
                                        style: TextStyle(
                                          color: isSelesai
                                              ? _selesaiColor
                                              : _primaryColor,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 28,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.siswaData['siswa_username'] ??
                                              '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _primaryLight,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            widget.siswaData['kelas_nama'] ??
                                                '-',
                                            style: TextStyle(
                                              color: _primaryColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelesai
                                          ? _selesaiColor.withValues(alpha: 0.1)
                                          : const Color(0xFFED6C02)
                                              .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isSelesai
                                              ? Icons.check_circle_rounded
                                              : Icons.pending_actions_rounded,
                                          size: 14,
                                          color: isSelesai
                                              ? _selesaiColor
                                              : const Color(0xFFED6C02),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isSelesai
                                              ? 'Selesai'
                                              : 'Belum Dinilai',
                                          style: TextStyle(
                                            color: isSelesai
                                                ? _selesaiColor
                                                : const Color(0xFFED6C02),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
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
                                  Icon(
                                    Icons.business_center_rounded,
                                    size: 18,
                                    color: _neutralColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      widget.siswaData['industri_nama'] ?? '',
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _primaryColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Kompetensi yang Dinilai',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Form Penilaian Items - DENGAN PEMBATASAN NILAI 0-100
                        ...List.generate(_formItems.length, (index) {
                          final formItem = _formItems[index];
                          final nomor = index + 1;
                          
                          // Mendapatkan error state untuk field ini
                          String? errorText;
                          if (_skorControllers[index].text.isNotEmpty) {
                            final skor = int.tryParse(_skorControllers[index].text);
                            if (skor == null) {
                              errorText = 'Harus angka';
                            } else if (skor < 0 || skor > 100) {
                              errorText = '0-100';
                            }
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: errorText != null 
                                    ? _errorColor.withValues(alpha: 0.3)
                                    : _borderSoft,
                                width: errorText != null ? 1.5 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withValues(alpha: 0.05),
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
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: _primaryColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$nomor',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Kompetensi $nomor',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _backgroundLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    formItem['tujuan_pembelajaran'] ?? '',
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Kolom Nilai
                                      Expanded(
                                        flex: 2,
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
                                            SizedBox(
                                              height: 52,
                                              child: TextFormField(
                                                controller:
                                                    _skorControllers[index],
                                                keyboardType:
                                                    const TextInputType.numberWithOptions(
                                                      signed: false,
                                                      decimal: false,
                                                    ),
                                                enabled: !isSelesai,
                                                readOnly: isSelesai,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight:
                                                        FontWeight.w600),
                                                decoration: InputDecoration(
                                                  hintText: '0-100',
                                                  hintStyle: TextStyle(
                                                      color: Colors.grey[400],
                                                      fontSize: 14),
                                                  errorText: errorText,
                                                  errorStyle: const TextStyle(
                                                    fontSize: 10,
                                                    height: 0.8,
                                                  ),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    borderSide: BorderSide(
                                                        color: _borderSoft),
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    borderSide: BorderSide(
                                                        color: errorText != null 
                                                            ? _errorColor 
                                                            : _borderSoft),
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    borderSide: BorderSide(
                                                        color: errorText != null 
                                                            ? _errorColor 
                                                            : _primaryColor,
                                                        width: 2),
                                                  ),
                                                  filled: isSelesai,
                                                  fillColor: _backgroundLight,
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                    horizontal: 12,
                                                    vertical: 12,
                                                  ),
                                                  isDense: true,
                                                ),
                                                onChanged: (value) {
                                                  // FORMAT DAN BATASI NILAI 0-100
                                                  final String formattedValue = _formatNilaiInput(value);
                                                  
                                                  // Update controller jika berbeda
                                                  if (_skorControllers[index].text != formattedValue) {
                                                    _skorControllers[index].text = formattedValue;
                                                    // Pindahkan kursor ke akhir
                                                    _skorControllers[index].selection = TextSelection.fromPosition(
                                                      TextPosition(offset: formattedValue.length),
                                                    );
                                                  }
                                                  
                                                  // UPDATE OTOMATIS DESKRIPSI
                                                  if (formattedValue.isNotEmpty) {
                                                    final skor = int.tryParse(formattedValue);
                                                    if (skor != null && skor >= 0 && skor <= 100) {
                                                      final predikat = _getPredikatFromNilai(skor);
                                                      if (_deskripsiControllers[index].text != predikat) {
                                                        _deskripsiControllers[index].text = predikat;
                                                      }
                                                    }
                                                  } else {
                                                    if (_deskripsiControllers[index].text.isNotEmpty) {
                                                      _deskripsiControllers[index].text = '';
                                                    }
                                                  }
                                                  
                                                  // Trigger rebuild
                                                  setState(() {});
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      
                                      // Kolom Predikat (READ ONLY, OTOMATIS TERISI)
                                      Expanded(
                                        flex: 4,
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
                                              height: 52,
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 12, vertical: 12),
                                              decoration: BoxDecoration(
                                                color: isSelesai 
                                                    ? _backgroundLight 
                                                    : (_deskripsiControllers[index].text.isNotEmpty 
                                                        ? _primaryLight 
                                                        : Colors.grey[50]),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                    color: errorText != null 
                                                        ? _errorColor.withValues(alpha: 0.5)
                                                        : _borderSoft),
                                              ),
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  _deskripsiControllers[index]
                                                          .text
                                                          .isNotEmpty
                                                      ? _deskripsiControllers[
                                                              index]
                                                          .text
                                                      : (isSelesai ? '-' : 'Otomatis terisi'),
                                                  style: TextStyle(
                                                    color: _deskripsiControllers[index]
                                                            .text
                                                            .isNotEmpty
                                                        ? _primaryColor
                                                        : Colors.grey[500],
                                                    fontWeight: _deskripsiControllers[index]
                                                            .text
                                                            .isNotEmpty
                                                        ? FontWeight.w600
                                                        : FontWeight.w400,
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            // Tampilkan pesan error jika nilai tidak valid
                                            if (errorText != null)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 4, left: 4),
                                                child: Text(
                                                  'Nilai $errorText',
                                                  style: TextStyle(
                                                    color: _errorColor,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w500,
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
                        }),

                        const SizedBox(height: 16),

                        // Catatan Akhir
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _borderSoft),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.05),
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
                              TextField(
                                controller: _catatanController,
                                enabled: !isSelesai,
                                readOnly: isSelesai,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  hintText: isSelesai
                                      ? 'Tidak ada catatan'
                                      : 'Masukkan catatan akhir',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: _borderSoft),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: _borderSoft),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide:
                                        BorderSide(color: _primaryColor),
                                  ),
                                  filled: isSelesai,
                                  fillColor: _backgroundLight,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Rata-rata Nilai Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _primaryColor,
                                _primaryColor.withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryColor.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Rata-rata Nilai',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Hasil PKL: ${_getHasilPKL(_hitungRataRata())}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  _hitungRataRata().toStringAsFixed(1),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 24,
                                    color: _primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Tombol Generate Dokumen (untuk mode selesai)
                        if (isSelesai) ...[
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isGeneratingAssessment
                                      ? null
                                      : _generateFormPenilaian,
                                  icon: _isGeneratingAssessment
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.assignment),
                                  label: Text(
                                    _isGeneratingAssessment
                                        ? 'Memproses...'
                                        : 'Generate Form Penilaian',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _selesaiColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),

                // ===== BOTTOM BUTTONS =====
                if (!isSelesai)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // TOMBOL SIMPAN DRAFT
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _simpanDraft,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: _primaryColor,
                                side:
                                    BorderSide(color: _primaryColor, width: 2),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Simpan Draf',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // TOMBOL SELESAIKAN
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _selesaiKan,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selesaiColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      'Selesaikan',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
extension ColorExtension on Color {
  Color withValues({double? alpha}) {
    if (alpha != null) {
      return withAlpha((alpha * 255).round());
    }
    return this;
  }
}
