import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import '../../utils/pimpinan_storage.dart';
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
  bool _hasIndustriData = false;
  List<Map<String, dynamic>> _formItems = [];
  List<Map<String, dynamic>> _nilaiItems = [];
  final TextEditingController _catatanController = TextEditingController();
  String _status = 'belum_dinilai';

  // Controllers untuk setiap item nilai
  final List<TextEditingController> _skorControllers = [];
  final List<TextEditingController> _deskripsiControllers = [];

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

  // Fungsi untuk mendapatkan predikat berdasarkan nilai (OTOMATIS, TANPA DROPDOWN)
  String _getPredikatFromNilai(int nilai) {
    if (nilai >= 86 && nilai <= 100) {
      return 'Sangat Baik';
    } else if (nilai >= 75 && nilai <= 85) {
      return 'Baik';
    } else if (nilai >= 60 && nilai <= 74) {
      return 'Cukup';
    } else {
      return 'Cukup';
    }
  }

  // Untuk hasil PKL (dari rata-rata nilai)
  String _getHasilPKL(double average) {
    if (average >= 90) return 'Amat Baik';
    if (average >= 80) return 'Baik';
    if (average >= 70) return 'Cukup';
    return 'Cukup';
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

        // Data penilaian
        setState(() {
          _formItems =
              List<Map<String, dynamic>>.from(data['form_items'] ?? []);

          final items = data['items'] as List? ?? [];
          _nilaiItems = List<Map<String, dynamic>>.from(items);

          _status = data['status'] ?? 'belum_dinilai';
          _catatanController.text = data['catatan_akhir'] ?? '';

          _initializeControllers();
        });

        // CEK DATA INDUSTRI (PIMPINAN & PEMBIMBING)
        final industriData =
            await PimpinanStorage.ambilDataIndustri(widget.applicationId);

        setState(() {
          _hasIndustriData = industriData != null;
          _isLoading = false;
        });

        // Debug print
        if (_hasIndustriData) {
          print('✅ Data industri ditemukan:');
          print('   - Pimpinan: ${industriData!['pimpinan']?['nama']}');
          print(
              '   - Pembimbing: ${industriData['pembimbing_industri']?['nama']}');
        } else {
          print(
              '⚠️ Belum ada data industri untuk aplikasi ${widget.applicationId}');
        }
      } else if (response.statusCode == 401) {
        _redirectToLogin();
      } else {
        throw Exception('Gagal memuat data penilaian');
      }
    } catch (e) {
      print('Error fetching penilaian data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasIndustriData = false;
        });
        _showSnackBar('Gagal memuat data penilaian', isError: true);
      }
    }
  }

  Future<void> _cekDataDanSelesaikan() async {
    if (!_validateInputs()) return;

    setState(() => _isSaving = true);

    try {
      // CEK APAKAH DATA PIMPINAN & PEMBIMBING SUDAH ADA
      final existingData =
          await PimpinanStorage.ambilDataIndustri(widget.applicationId);

      if (existingData == null) {
        // Jika BELUM ada data
        setState(() => _isSaving = false);

        // Tampilkan dialog peringatan
        final bool? inputData = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Data Belum Lengkap'),
            content: const Text(
                'Anda harus mengisi data pimpinan dan pembimbing industri terlebih dahulu sebelum menyelesaikan penilaian.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                ),
                child: const Text('Input Sekarang'),
              ),
            ],
          ),
        );

        if (inputData == true) {
          // Arahkan ke input data
          await _simpanDataIndustriLengkap();
          // Setelah input, coba lagi (rekursif)
          _cekDataDanSelesaikan();
        }
        return;
      }

      // Jika SUDAH ada data, langsung finalisasi
      await _selesaiKan();
    } catch (e) {
      print('Error: $e');
      _showSnackBar('Terjadi kesalahan', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _tampilkanDialogInputData() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Data Industri Belum Lengkap'),
        content: const Text(
            'Anda harus mengisi data pimpinan dan pembimbing industri sebelum menyelesaikan penilaian.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
            ),
            child: const Text('Input Data Sekarang'),
          ),
        ],
      ),
    );

    if (result == true) {
      // Panggil method input data yang sudah ada
      await _simpanDataIndustriLengkap();
      return true;
    }

    return false;
  }

// Tambahkan method ini di dalam class _PenilaianDetailScreenState
  Future<void> _tampilkanRingkasanData({
    required Map<String, String> pimpinan,
    required Map<String, String> pembimbing,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Berhasil Disimpan'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info siswa
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Siswa: ${widget.siswaData['siswa_username'] ?? '-'}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Data Pimpinan
              const Text(
                '✓ Pimpinan Industri:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Nama: ${pimpinan['nama']}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.badge_outlined,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${pimpinan['jenis_nomor']}: ${pimpinan['nip']?.isEmpty ?? true ? '-' : pimpinan['nip']}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.work_outline,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Jabatan: ${pimpinan['jabatan']}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Data Pembimbing Industri
              const Text(
                '✓ Pembimbing Industri:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Nama: ${pembimbing['nama']}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.badge_outlined,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${pembimbing['jenis_nomor']}: ${pembimbing['nip']?.isEmpty ?? true ? '-' : pembimbing['nip']}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.work_outline,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Jabatan: ${pembimbing['jabatan']}',
                            style: const TextStyle(fontSize: 13),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _simpanDataIndustriLengkap() async {
    // Tahap 1: Input Pimpinan Industri (dengan jenis nomor)
    final pimpinan = await _dialogInputPimpinan();
    if (pimpinan == null) return;

    // Tahap 2: Input Pembimbing Industri (dengan jenis nomor)
    final pembimbing = await _dialogInputPembimbingIndustri();
    if (pembimbing == null) return;

    // Simpan ke SharedPreferences dengan menyertakan jenis nomor
    await PimpinanStorage.simpanDataIndustri(
      applicationId: widget.applicationId,
      namaPimpinan: pimpinan['nama'] ?? '',
      jenisNomorPimpinan: pimpinan['jenis_nomor'] ?? 'NIP', // TAMBAHKAN INI
      nipPimpinan: pimpinan['nip'] ?? '',
      jabatanPimpinan: pimpinan['jabatan'] ?? '',
      namaPembimbingIndustri: pembimbing['nama'] ?? '',
      jenisNomorPembimbing: pembimbing['jenis_nomor'] ?? 'NIP', // TAMBAHKAN INI
      nipPembimbingIndustri: pembimbing['nip'] ?? '',
      jabatanPembimbingIndustri: pembimbing['jabatan'] ?? '',
      dataSiswa: widget.siswaData,
    );

    // Update state
    setState(() {
      _hasIndustriData = true;
    });

    // Tampilkan ringkasan data dengan jenis nomor
    await _tampilkanRingkasanData(
      pimpinan: pimpinan,
      pembimbing: pembimbing,
    );

    _showSnackBar('Data pimpinan dan pembimbing industri tersimpan',
        backgroundColor: Colors.green);
  }

// Dialog 1: Input Pimpinan Industri dengan JENIS NOMOR manual
  Future<Map<String, String>?> _dialogInputPimpinan() async {
    final namaCtrl = TextEditingController();
    final jenisNomorCtrl = TextEditingController(text: 'NIP'); // Default NIP
    final nipCtrl = TextEditingController();
    final jabatanCtrl = TextEditingController();

    // State untuk error message
    String? nipError;

    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.business_center,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pimpinan Industri',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Masukkan data pimpinan perusahaan',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nama dengan garis bawah
                        const Text(
                          'Nama Pimpinan',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF6B1B1B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                          ),
                          child: TextField(
                            controller: namaCtrl,
                            decoration: InputDecoration(
                              hintText: 'Masukkan nama pimpinan',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              prefixIcon: Icon(Icons.person_outline,
                                  color: _primaryColor),
                              border: InputBorder.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // JENIS NOMOR - Input Manual (NIP/NIK/NP/dll)
                        const Text(
                          'Jenis Nomor',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF6B1B1B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                          ),
                          child: TextField(
                            controller: jenisNomorCtrl,
                            decoration: InputDecoration(
                              hintText: 'Contoh: NIP, NIK, NP',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              prefixIcon: Icon(Icons.badge_outlined,
                                  color: _primaryColor),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ketik manual (NIP / NIK / NP / dll)',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Nomor (NIP/NIK)
                        Row(
                          children: [
                            const Text(
                              'Nomor',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xFF6B1B1B),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Opsional',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Maks. 18 digit',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: nipError != null
                                    ? Colors.red.shade300
                                    : Colors.grey.shade300,
                                width: nipError != null ? 2 : 1,
                              ),
                            ),
                          ),
                          child: TextField(
                            controller: nipCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(18),
                            ],
                            decoration: InputDecoration(
                              hintText: 'Masukkan nomor (maksimal 18 digit)',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              prefixIcon: Icon(
                                Icons.numbers_rounded,
                                color: nipError != null
                                    ? Colors.red
                                    : _primaryColor,
                              ),
                              suffixIcon: nipCtrl.text.length >= 15
                                  ? Text(
                                      '${nipCtrl.text.length}/18',
                                      style: TextStyle(
                                        color: nipCtrl.text.length == 18
                                            ? Colors.green
                                            : Colors.orange,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    )
                                  : null,
                              border: InputBorder.none,
                              errorText: nipError,
                              errorStyle: const TextStyle(
                                fontSize: 11,
                                height: 0.8,
                              ),
                            ),
                            onChanged: (value) {
                              // Validasi real-time (hanya cek maksimal digit)
                              setState(() {
                                if (value.length > 18) {
                                  nipError = 'Maksimal 18 digit';
                                } else {
                                  nipError = null;
                                }
                              });
                            },
                          ),
                        ),
                        if (nipCtrl.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 12),
                            child: Text(
                              '${nipCtrl.text.length}/18 digit',
                              style: TextStyle(
                                fontSize: 11,
                                color: nipCtrl.text.length == 18
                                    ? Colors.green
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                        const SizedBox(height: 20),

                        // Jabatan dengan garis bawah
                        const Text(
                          'Jabatan',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF6B1B1B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                          ),
                          child: TextField(
                            controller: jabatanCtrl,
                            decoration: InputDecoration(
                              hintText: 'Masukkan jabatan pimpinan',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              prefixIcon: Icon(Icons.work_outline,
                                  color: _primaryColor),
                              border: InputBorder.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Garis pemisah horizontal
                        Divider(
                          color: Colors.grey.shade200,
                          thickness: 1,
                          height: 1,
                        ),

                        const SizedBox(height: 20),

                        // Info
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _primaryColor.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: _primaryColor.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: 18, color: _primaryColor),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Nomor bersifat opsional. Jika tidak diisi akan ditampilkan tanda "-" pada sertifikat.',
                                  style: TextStyle(
                                    fontSize: 12,
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
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Validasi Nama
                            if (namaCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Nama pimpinan harus diisi'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            // Validasi Jenis Nomor
                            if (jenisNomorCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Jenis nomor harus diisi'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            // Validasi Nomor (hanya cek maksimal 18 digit, tidak wajib)
                            final nip = nipCtrl.text.trim();
                            if (nip.length > 18) {
                              setState(() {
                                nipError = 'Maksimal 18 digit';
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Nomor maksimal 18 digit'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            // Validasi Jabatan
                            if (jabatanCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Jabatan harus diisi'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            Navigator.pop(context, {
                              'nama': namaCtrl.text.trim(),
                              'jenis_nomor': jenisNomorCtrl.text.trim(),
                              'nip': nipCtrl.text.trim().isEmpty
                                  ? '-'
                                  : nipCtrl.text.trim(),
                              'jabatan': jabatanCtrl.text.trim(),
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Lanjut'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Tambahkan method helper untuk TextField yang konsisten
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isRequired,
    Color accentColor = const Color(0xFF6B1B1B),
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              prefixIcon: Icon(icon, color: accentColor, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

// Dialog 2: Input Pembimbing Industri dengan JENIS NOMOR manual
  Future<Map<String, String>?> _dialogInputPembimbingIndustri() async {
    final namaCtrl = TextEditingController();
    final jenisNomorCtrl = TextEditingController(text: 'NIP'); // Default NIP
    final nipCtrl = TextEditingController();
    final jabatanCtrl = TextEditingController();

    // State untuk error message
    String? nipError;

    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade700, Colors.green.shade600],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.people_alt,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pembimbing Industri',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Masukkan data pembimbing lapangan',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nama dengan garis bawah
                        const Text(
                          'Nama Pembimbing',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                          ),
                          child: TextField(
                            controller: namaCtrl,
                            decoration: InputDecoration(
                              hintText: 'Masukkan nama pembimbing',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              prefixIcon: Icon(Icons.person_outline,
                                  color: Colors.green.shade700),
                              border: InputBorder.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // JENIS NOMOR - Input Manual (NIP/NIK/NP/dll)
                        const Text(
                          'Jenis Nomor',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                          ),
                          child: TextField(
                            controller: jenisNomorCtrl,
                            decoration: InputDecoration(
                              hintText: 'Contoh: NIP, NIK, NP',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              prefixIcon: Icon(Icons.badge_outlined,
                                  color: Colors.green.shade700),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ketik manual (NIP / NIK / NP / dll)',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Nomor (NIP/NIK)
                        Row(
                          children: [
                            const Text(
                              'Nomor',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Opsional',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Maks. 18 digit',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: nipError != null
                                    ? Colors.red.shade300
                                    : Colors.grey.shade300,
                                width: nipError != null ? 2 : 1,
                              ),
                            ),
                          ),
                          child: TextField(
                            controller: nipCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(18),
                            ],
                            decoration: InputDecoration(
                              hintText: 'Masukkan nomor (maksimal 18 digit)',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              prefixIcon: Icon(
                                Icons.numbers_rounded,
                                color: nipError != null
                                    ? Colors.red
                                    : Colors.green.shade700,
                              ),
                              suffixIcon: nipCtrl.text.length >= 15
                                  ? Text(
                                      '${nipCtrl.text.length}/18',
                                      style: TextStyle(
                                        color: nipCtrl.text.length == 18
                                            ? Colors.green
                                            : Colors.orange,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    )
                                  : null,
                              border: InputBorder.none,
                              errorText: nipError,
                              errorStyle: const TextStyle(
                                fontSize: 11,
                                height: 0.8,
                              ),
                            ),
                            onChanged: (value) {
                              // Validasi real-time (hanya cek maksimal digit)
                              setState(() {
                                if (value.length > 18) {
                                  nipError = 'Maksimal 18 digit';
                                } else {
                                  nipError = null;
                                }
                              });
                            },
                          ),
                        ),
                        if (nipCtrl.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 12),
                            child: Text(
                              '${nipCtrl.text.length}/18 digit',
                              style: TextStyle(
                                fontSize: 11,
                                color: nipCtrl.text.length == 18
                                    ? Colors.green
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                        const SizedBox(height: 20),

                        // Jabatan dengan garis bawah
                        const Text(
                          'Jabatan',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                          ),
                          child: TextField(
                            controller: jabatanCtrl,
                            decoration: InputDecoration(
                              hintText: 'Masukkan jabatan pembimbing',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              prefixIcon: Icon(Icons.work_outline,
                                  color: Colors.green.shade700),
                              border: InputBorder.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Garis pemisah horizontal
                        Divider(
                          color: Colors.grey.shade200,
                          thickness: 1,
                          height: 1,
                        ),

                        const SizedBox(height: 20),

                        // Info
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: 18, color: Colors.green.shade700),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Nomor bersifat opsional. Jika tidak diisi akan ditampilkan tanda "-" pada sertifikat.',
                                  style: TextStyle(
                                    fontSize: 12,
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
                ),

                // Footer dengan garis atas
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Validasi Nama
                            if (namaCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Nama pembimbing harus diisi'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            // Validasi Jenis Nomor
                            if (jenisNomorCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Jenis nomor harus diisi'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            // Validasi Nomor (hanya cek maksimal 18 digit, tidak wajib)
                            final nip = nipCtrl.text.trim();
                            if (nip.length > 18) {
                              setState(() {
                                nipError = 'Maksimal 18 digit';
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Nomor maksimal 18 digit'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            // Validasi Jabatan
                            if (jabatanCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Jabatan harus diisi'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            Navigator.pop(context, {
                              'nama': namaCtrl.text.trim(),
                              'jenis_nomor': jenisNomorCtrl.text.trim(),
                              'nip': nipCtrl.text.trim().isEmpty
                                  ? '-'
                                  : nipCtrl.text.trim(),
                              'jabatan': jabatanCtrl.text.trim(),
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Simpan'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

// Cari fungsi _showSnackBar di bagian atas (sekitar baris 100-110)
  void _showSnackBar(String message,
      {bool isError = false, Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            backgroundColor ?? (isError ? Colors.red : _primaryColor),
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
        _showSnackBar('Berhasil disimpan');

        await _fetchPenilaianData();
        Navigator.pop(context, true);
      } else if (response.statusCode == 409) {
        _showSnackBar('Tidak bisa menyimpan karena sudah final', isError: true);
      } else {
        throw Exception('Gagal menyimpan : ${response.statusCode}');
      }
    } catch (e) {
      print('Error saving draft: $e');
      _showSnackBar('Gagal menyimpan ', isError: true);
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
      // Ambil nama pembimbing dari shared preferences (yang login)
      final namaPembimbing = prefs.getString('user_name') ?? 'Guru Mapel PKL';

      // Ambil NIP pembimbing dari API guru
      String nipPembimbing = '-';
      String jabatanPembimbing = 'Guru Pembimbing PKL';

      try {
        // Cari data guru berdasarkan user yang login
        final userId = prefs.getInt('user_id');
        if (userId != null) {
          final guruResponse = await http.get(
            Uri.parse(
                '${dotenv.env['API_BASE_URL']}/api/guru?user_id=$userId&limit=1'),
            headers: {
              'accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );

          if (guruResponse.statusCode == 200) {
            final guruData = jsonDecode(guruResponse.body);
            if (guruData['success'] == true &&
                guruData['data']['data'].isNotEmpty) {
              final guru = guruData['data']['data'][0];
              nipPembimbing = guru['nip'] ?? '-';
              // Bisa juga ambil jabatan jika ada di data guru
              jabatanPembimbing = guru['jabatan'] ?? 'Guru Pembimbing PKL';
            }
          }
        }
      } catch (e) {
        print('Error fetching guru data: $e');
      }

      // Ambil nama industri siswa
      final String industriSiswa = widget.siswaData['industri_nama'] ?? '';
      String namaInstruktur = '';
      String jabatanInstruktur = '';
      String nipInstruktur = '';

      // Cari PIC dari industri siswa
      if (industriSiswa.isNotEmpty) {
        // Ambil data industri
        final industriList = await _fetchIndustriData();

        // Cari industri yang sesuai
        final matchedIndustri = industriList.firstWhere(
          (industri) =>
              industri['nama']?.toString().toLowerCase() ==
              industriSiswa.toLowerCase(),
          orElse: () => {},
        );

        if (matchedIndustri.isNotEmpty) {
          namaInstruktur = matchedIndustri['pic'] ?? '';
          jabatanInstruktur =
              matchedIndustri['jabatan'] ?? 'Pembimbing Industri';
          nipInstruktur =
              matchedIndustri['nip'] ?? matchedIndustri['pic_telp'] ?? '-';
        }
      }

      // Jika masih kosong, gunakan default
      if (namaInstruktur.isEmpty) {
        namaInstruktur = 'Instruktur PKL';
        jabatanInstruktur = 'Pembimbing Industri';
        nipInstruktur = '-';
      }

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
              widget.siswaData['konsentrasi'] ?? 'Rekayasa Perangkat Lunak',
          'tempat_pkl': widget.siswaData['industri_nama'] ?? '',
          'tanggal_mulai': _formatDateIndonesian(
              DateTime.now().subtract(const Duration(days: 180))),
          'tanggal_selesai': formattedDate,
          'nama_instruktur': namaInstruktur,
          'jabatan_instruktur': jabatanInstruktur,
          'nip_instruktur': nipInstruktur,
          'nama_pembimbing': namaPembimbing,
          'jabatan_pembimbing': jabatanPembimbing,
          'nip_pembimbing': nipPembimbing,
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
        'sakit': 0,
        'izin': 0,
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
        throw Exception('Gagal cetak formulir penilaian');
      }
    } catch (e) {
      print('Error generating assessment: $e');
      _showSnackBar('Gagal cetak formulir penilaian', isError: true);
    } finally {
      if (mounted) setState(() => _isGeneratingAssessment = false);
    }
  }

  Future<Map<String, String>?> _showInputNamesDialog() async {
    final TextEditingController instrukturController = TextEditingController();
    final TextEditingController pembimbingController = TextEditingController();
    List<Map<String, dynamic>> industriList = [];
    bool isLoadingIndustri = true;
    String? selectedIndustri;

    // Ambil nama industri siswa
    final String industriSiswa = widget.siswaData['industri_nama'] ?? '';

    // Ambil nama pembimbing dari SharedPreferences untuk default
    final prefs = await SharedPreferences.getInstance();
    final defaultPembimbing = prefs.getString('user_name') ?? '';

    // Ambil data industri
    industriList = await _fetchIndustriData();
    isLoadingIndustri = false;

    // Cari industri yang sesuai dengan industri siswa
    if (industriSiswa.isNotEmpty) {
      final matchedIndustri = industriList.firstWhere(
        (industri) =>
            industri['nama']?.toString().toLowerCase() ==
            industriSiswa.toLowerCase(),
        orElse: () => {},
      );

      if (matchedIndustri.isNotEmpty) {
        selectedIndustri = matchedIndustri['nama'];
        // Otomatis isi nama instruktur dengan PIC
        instrukturController.text = matchedIndustri['pic'] ?? '';
      }
    }

    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.edit_document,
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
                                'Cetak Formulir Penilaian',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: _primaryColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Konfirmasi data penandatangan',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Info Industri
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _primaryColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _primaryColor.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.business, color: _primaryColor, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Industri',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  industriSiswa.isNotEmpty
                                      ? industriSiswa
                                      : 'Tidak diketahui',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Input Nama Instruktur
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 18,
                              color: _primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Nama Instruktur (PIC Industri)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            if (instrukturController.text.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _selesaiColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Otomatis',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _selesaiColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (isLoadingIndustri)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _borderSoft),
                            ),
                            child: TextField(
                              controller: instrukturController,
                              readOnly: instrukturController.text.isNotEmpty,
                              style: TextStyle(
                                color: instrukturController.text.isNotEmpty
                                    ? _primaryColor
                                    : Colors.black,
                                fontWeight: instrukturController.text.isNotEmpty
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Masukkan nama instruktur',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                suffixIcon: instrukturController.text.isNotEmpty
                                    ? Icon(
                                        Icons.check_circle,
                                        color: _selesaiColor,
                                        size: 20,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        if (!isLoadingIndustri && industriList.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Wrap(
                              spacing: 8,
                              children: [
                                if (instrukturController.text.isEmpty)
                                  ...industriList
                                      .where((i) =>
                                          i['pic'] != null &&
                                          i['pic'].toString().isNotEmpty)
                                      .take(3)
                                      .map((industri) {
                                    return ActionChip(
                                      label: Text(
                                        industri['pic'],
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          instrukturController.text =
                                              industri['pic'].toString();
                                        });
                                      },
                                      backgroundColor: Colors.grey[100],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    );
                                  }),
                                if (instrukturController.text.isNotEmpty)
                                  ActionChip(
                                    label: const Text('Ganti'),
                                    onPressed: () {
                                      setState(() {
                                        instrukturController.clear();
                                      });
                                    },
                                    backgroundColor: Colors.grey[100],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Input Nama Pembimbing
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.school_rounded,
                              size: 18,
                              color: _primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Nama Pembimbing Sekolah',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _borderSoft),
                          ),
                          child: TextField(
                            controller: pembimbingController
                              ..text = defaultPembimbing,
                            decoration: InputDecoration(
                              hintText: 'Masukkan nama pembimbing',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            child: Text(
                              'Batal',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // Validasi
                              if (instrukturController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                        'Nama instruktur harus diisi'),
                                    backgroundColor: _errorColor,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                                return;
                              }

                              if (pembimbingController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                        'Nama pembimbing harus diisi'),
                                    backgroundColor: _errorColor,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                                return;
                              }

                              Navigator.pop(context, {
                                'instruktur': instrukturController.text.trim(),
                                'pembimbing': pembimbingController.text.trim(),
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Cetak',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
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
      },
    );
  }

// Tambahkan fungsi dialog input instruktur
  Future<String> _showInputInstrukturDialog() async {
    final TextEditingController controller = TextEditingController();
    String result = '';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Input Nama Instruktur'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Masukkan nama instruktur/ pembimbing industri:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _primaryColor, width: 2),
                  ),
                ),
                autofocus: true,
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  result = controller.text.trim();
                  Navigator.pop(context);
                } else {
                  _showSnackBar('Nama instruktur tidak boleh kosong',
                      isError: true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    return result;
  }

  Future<List<Map<String, dynamic>>> _fetchIndustriData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      _redirectToLogin();
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/industri?limit=100'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data']['data'] ?? []);
      } else {
        print('Gagal mengambil data industri: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching industri data: $e');
      return [];
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
      _showSnackBar('Mengunduh berkas...');

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
        throw Exception('Gagal mengunduh berkas');
      }
    } catch (e) {
      print('Error downloading file: $e');
      _showSnackBar('Gagal mengunduh berkas', isError: true);
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

  // Fungsi untuk mendapatkan deskripsi berdasarkan nomor kompetensi
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
                      Text('Cetak Formulir Penilaian'),
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

                        // Form Penilaian Items - DENGAN DESKRIPSI DI BAWAHNYA
                        ...List.generate(_formItems.length, (index) {
                          final formItem = _formItems[index];
                          final nomor = index + 1;

                          // Mendapatkan error state untuk field ini
                          String? errorText;
                          if (_skorControllers[index].text.isNotEmpty) {
                            final skor =
                                int.tryParse(_skorControllers[index].text);
                            if (skor == null) {
                              errorText = 'Harus angka';
                            } else if (skor < 0 || skor > 100) {
                              errorText = '0-100';
                            }
                          }

                          final int skorValue =
                              int.tryParse(_skorControllers[index].text) ?? 0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
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
                                // Header Kompetensi
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

                                // Tujuan Pembelajaran
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

                                // Nilai dan Predikat
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
                                                    const TextInputType
                                                        .numberWithOptions(
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
                                                  final String formattedValue =
                                                      _formatNilaiInput(value);

                                                  // Update controller jika berbeda
                                                  if (_skorControllers[index]
                                                          .text !=
                                                      formattedValue) {
                                                    _skorControllers[index]
                                                        .text = formattedValue;
                                                    // Pindahkan kursor ke akhir
                                                    _skorControllers[index]
                                                            .selection =
                                                        TextSelection
                                                            .fromPosition(
                                                      TextPosition(
                                                          offset: formattedValue
                                                              .length),
                                                    );
                                                  }

                                                  // UPDATE OTOMATIS DESKRIPSI
                                                  if (formattedValue
                                                      .isNotEmpty) {
                                                    final skor = int.tryParse(
                                                        formattedValue);
                                                    if (skor != null &&
                                                        skor >= 0 &&
                                                        skor <= 100) {
                                                      final predikat =
                                                          _getPredikatFromNilai(
                                                              skor);
                                                      if (_deskripsiControllers[
                                                                  index]
                                                              .text !=
                                                          predikat) {
                                                        _deskripsiControllers[
                                                                index]
                                                            .text = predikat;
                                                      }
                                                    }
                                                  } else {
                                                    if (_deskripsiControllers[
                                                            index]
                                                        .text
                                                        .isNotEmpty) {
                                                      _deskripsiControllers[
                                                              index]
                                                          .text = '';
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 12),
                                              decoration: BoxDecoration(
                                                color: isSelesai
                                                    ? _backgroundLight
                                                    : (_deskripsiControllers[
                                                                index]
                                                            .text
                                                            .isNotEmpty
                                                        ? _primaryLight
                                                        : Colors.grey[50]),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                    color: errorText != null
                                                        ? _errorColor
                                                            .withValues(
                                                                alpha: 0.5)
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
                                                      : (isSelesai
                                                          ? '-'
                                                          : 'Otomatis terisi'),
                                                  style: TextStyle(
                                                    color:
                                                        _deskripsiControllers[
                                                                    index]
                                                                .text
                                                                .isNotEmpty
                                                            ? _primaryColor
                                                            : Colors.grey[500],
                                                    fontWeight:
                                                        _deskripsiControllers[
                                                                    index]
                                                                .text
                                                                .isNotEmpty
                                                            ? FontWeight.w600
                                                            : FontWeight.w400,
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            // Tampilkan pesan error jika nilai tidak valid
                                            if (errorText != null)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 4, left: 4),
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
                                const SizedBox(height: 16),

                                // ===== DESKRIPSI CAPAIAN (DITAMBAHKAN DI BAWAH SETIAP KOMPETENSI) =====
                                if (_skorControllers[index].text.isNotEmpty &&
                                    skorValue > 0)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color:
                                          _primaryColor.withValues(alpha: 0.03),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: _primaryColor.withValues(
                                              alpha: 0.2)),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.description_rounded,
                                          size: 16,
                                          color: _primaryColor.withValues(
                                              alpha: 0.7),
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
                                                _getDeskripsiKompetensi(
                                                    nomor, skorValue),
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
                        // ===== Rata-rata Nilai Card =====
                        const SizedBox(height: 20),
// ===== DATA PIMPINAN & PEMBIMBING INDUSTRI =====
                        FutureBuilder<Map<String, dynamic>?>(
                          future: PimpinanStorage.ambilDataIndustri(
                              widget.applicationId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final industriData = snapshot.data;
                            if (industriData == null) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border:
                                      Border.all(color: Colors.orange.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded,
                                        color: Colors.orange.shade700),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Data pimpinan dan pembimbing industri belum dimasukkan',
                                        style: TextStyle(
                                          color: Colors.orange.shade800,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final pimpinan = industriData['pimpinan'] ?? {};
                            final pembimbing =
                                industriData['pembimbing_industri'] ?? {};

                            return Container(
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
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _primaryColor.withValues(
                                              alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Icon(Icons.business_center,
                                            color: _primaryColor, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Data Industri',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Pimpinan Industri
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _backgroundLight,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: _borderSoft),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.person,
                                                size: 16, color: _primaryColor),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Pimpinan Industri',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                                color: _primaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              flex: 1,
                                              child: Text('Nama',
                                                  style: TextStyle(
                                                      color: _neutralColor,
                                                      fontSize: 12)),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                pimpinan['nama'] ?? '-',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Expanded(
                                              flex: 1,
                                              child: Text(
                                                pimpinan['jenis_nomor'] ??
                                                    'NIP', // <--- INI YANG DIPERBAIKI
                                                style: TextStyle(
                                                    color: _neutralColor,
                                                    fontSize: 12),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                pimpinan['nip']?.isNotEmpty ==
                                                        true
                                                    ? pimpinan['nip']
                                                    : '-',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Expanded(
                                              flex: 1,
                                              child: Text('Jabatan',
                                                  style: TextStyle(
                                                      color: _neutralColor,
                                                      fontSize: 12)),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                pimpinan['jabatan'] ?? '-',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Pembimbing Industri
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _backgroundLight,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: _borderSoft),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.people,
                                                size: 16,
                                                color: Colors.green.shade700),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Pembimbing Industri',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                                color: Colors.green.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              flex: 1,
                                              child: Text('Nama',
                                                  style: TextStyle(
                                                      color: _neutralColor,
                                                      fontSize: 12)),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                pembimbing['nama'] ?? '-',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Expanded(
                                              flex: 1,
                                              child: Text(
                                                pembimbing['jenis_nomor'] ??
                                                    'NIP', // <--- INI YANG DIPERBAIKI
                                                style: TextStyle(
                                                    color: _neutralColor,
                                                    fontSize: 12),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                pembimbing['nip']?.isNotEmpty ==
                                                        true
                                                    ? pembimbing['nip']
                                                    : '-',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Expanded(
                                              flex: 1,
                                              child: Text('Jabatan',
                                                  style: TextStyle(
                                                      color: _neutralColor,
                                                      fontSize: 12)),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                pembimbing['jabatan'] ?? '-',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.access_time,
                                            size: 14,
                                            color: Colors.blue.shade700),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            'Terakhir diperbarui: ${_formatDateIndonesian(DateTime.parse(industriData['waktu_simpan'] ?? DateTime.now().toIso8601String()))}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.blue.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),

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
                                        : 'Cetak Formulir Penilaian',
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
// Di bagian BOTTOM BUTTONS, ganti dengan ini:

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
                          Expanded(
                            child: _hasIndustriData
                                // Jika SUDAH ada data industri → Tombol Simpan & Selesaikan
                                ? ElevatedButton.icon(
                                    onPressed: _isSaving
                                        ? null
                                        : _cekDataDanSelesaikan,
                                    icon: _isSaving
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          )
                                        : const Icon(Icons.save_alt_rounded),
                                    label: const Text(
                                      'Simpan & Selesaikan',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  )
                                // Jika BELUM ada data industri → Tombol Input Data Industri
                                : ElevatedButton.icon(
                                    onPressed: _simpanDataIndustriLengkap,
                                    icon:
                                        const Icon(Icons.add_business_rounded),
                                    label: const Text(
                                      'Masukkan Data Industri',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
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
