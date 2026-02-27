// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class KelolaPerizinanTabScreen extends StatefulWidget {
  final ScrollController? scrollController;
  
  const KelolaPerizinanTabScreen({
    super.key,
    this.scrollController,
  });

  @override
  State<KelolaPerizinanTabScreen> createState() => _KelolaPerizinanTabScreenState();
}

class _KelolaPerizinanTabScreenState extends State<KelolaPerizinanTabScreen> 
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  final Color _primaryRed = const Color(0xFF6B1B1B);
  final Color _bgSoft = const Color(0xFFF6EEEE);
  final Color _secondaryColor = Colors.white;
  final Color _textPrimary = Colors.black;
  final Color _textSecondary = const Color(0xFF666666);
  final Color _borderColor = const Color(0xFFE0E0E0);
  final Color _green = const Color(0xFF4CAF50);
  final Color _orange = const Color(0xFFFF9800);
  final Color _red = const Color(0xFFF44336);
  final Color _blue = const Color(0xFF2196F3);
  final Color _purple = const Color(0xFF9C27B0); // Untuk status opened
  
  late TabController _tabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _tabController.addListener(() {
      setState(() {
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return DefaultTabController(
      length: 1,
      child: Scaffold(
        backgroundColor: _bgSoft,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 180.0,
                backgroundColor: _bgSoft,
                pinned: true,
                floating: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: _headerCard(),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48.0),
                  child: Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: _primaryRed,
                      labelColor: _primaryRed,
                      unselectedLabelColor: Colors.grey,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      tabs: const [
                        Tab(text: 'Permasalahan Siswa'),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              // TAB 1: Permasalahan Siswa dengan API
              PermasalahanSiswaContent(
                primaryRed: _primaryRed,
                bgSoft: _bgSoft,
                secondaryColor: _secondaryColor,
                textPrimary: _textPrimary,
                textSecondary: _textSecondary,
                borderColor: _borderColor,
                green: _green,
                orange: _orange,
                red: _red,
                blue: _blue,
                purple: _purple,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 40, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Permasalahan Siswa',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF6B1B1B),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Pantau permasalahan siswa selama PKL',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================
// TAB: PERMASALAHAN SISWA DENGAN API
// ==============================================

class PermasalahanSiswaContent extends StatefulWidget {
  final Color primaryRed;
  final Color bgSoft;
  final Color secondaryColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderColor;
  final Color green;
  final Color orange;
  final Color red;
  final Color blue;
  final Color purple;

  const PermasalahanSiswaContent({
    super.key,
    required this.primaryRed,
    required this.bgSoft,
    required this.secondaryColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
    required this.green,
    required this.orange,
    required this.red,
    required this.blue,
    required this.purple,
  });

  @override
  State<PermasalahanSiswaContent> createState() => _PermasalahanSiswaContentState();
}

class _PermasalahanSiswaContentState extends State<PermasalahanSiswaContent> 
    with AutomaticKeepAliveClientMixin {
  
  // Data dari API
  List<Map<String, dynamic>> _permasalahanData = [];
  List<Map<String, dynamic>> _filteredData = [];
  
  final TextEditingController _searchController = TextEditingController();
  
  // Loading states
  bool _isLoading = false;
  
  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  final int _itemsPerPage = 10;
  
  // Filter
  String? _filterStatus;

  // Kategori display mapping
  final Map<String, String> _kategoriDisplay = {
    'kedisiplinan': 'Kedisiplinan',
    'absensi': 'Absensi',
    'performa': 'Performa',
    'lainnya': 'Lainnya',
  };

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchStudentIssues();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============== API METHODS ==============

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  String _getBaseUrl() {
    return dotenv.env['API_BASE_URL'] ?? 'https://api.gedanggoreng.com';
  }

  // GET /api/student-issues/wali-kelas
  Future<void> _fetchStudentIssues({int page = 1, String? status}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _getToken();
      if (token == null) {
        _showSnackBar('Token tidak ditemukan', isError: true);
        setState(() => _isLoading = false);
        return;
      }

      final baseUrl = _getBaseUrl();
      var uri = Uri.parse('$baseUrl/api/student-issues/wali-kelas');
      
      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': _itemsPerPage.toString(),
      };
      
      if (status != null && status != 'Semua' && status != 'semua') {
        // Konversi display status ke API status
        String apiStatus = status;
        if (status == 'Menunggu') {
          apiStatus = 'opened';
        } else if (status == 'Diproses') apiStatus = 'in_progress';
        else if (status == 'Selesai') apiStatus = 'resolved';
        
        queryParams['status'] = apiStatus;
      }
      
      if (_searchController.text.isNotEmpty) {
        queryParams['search'] = _searchController.text.trim();
      }
      
      uri = uri.replace(queryParameters: queryParams);

      print('📡 Fetching issues from: $uri');
      
      final response = await http.get(
        uri,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        
        if (jsonResponse.containsKey('items') && jsonResponse['items'] is List) {
          final List<dynamic> items = jsonResponse['items'];
          
          setState(() {
            _permasalahanData = items.map((item) {
              final siswa = item['siswa'] ?? {};
              final pembimbing = item['pembimbing'];
              
              // Format tanggal
              final String formattedDate = _formatDate(item['created_at']);
              
              return {
                'id': item['id'].toString(),
                'judul': item['judul'] ?? 'Tidak ada judul',
                'deskripsi': item['deskripsi'] ?? '',
                'kategori': item['kategori'] ?? 'lainnya',
                'status': item['status'] ?? 'opened',
                'tindak_lanjut': item['tindak_lanjut'],
                'created_at': item['created_at'],
                'resolved_at': item['resolved_at'],
                'siswa_id': siswa['id'],
                'siswa_nama': siswa['nama'] ?? 'Siswa Tidak Diketahui',
                'siswa_nisn': siswa['nisn'] ?? '-',
                'pembimbing_nama': pembimbing?['nama'],
                // Format untuk tampilan card (sesuai dengan dummy)
                'nama': siswa['nama'] ?? 'Siswa Tidak Diketahui',
                'kelas': '-', // Kelas tidak ada di response, bisa ditambahkan nanti jika ada
                'industri': '-', // Industri tidak ada di response
                'jenis': _kategoriDisplay[item['kategori']] ?? item['kategori'] ?? 'Lainnya',
                'tanggal': formattedDate,
              };
            }).toList();
            
            _filteredData = List.from(_permasalahanData);
            
            // Set pagination info
            if (jsonResponse.containsKey('pagination')) {
              final pagination = jsonResponse['pagination'];
              _totalPages = pagination['total_pages'] ?? 1;
              _currentPage = pagination['page'] ?? 1;
            }
          });
          
          print('✅ Loaded ${_permasalahanData.length} issues');
        } else {
          setState(() {
            _permasalahanData = [];
            _filteredData = [];
          });
          print('⚠️ No items found in response');
        }
      } else if (response.statusCode == 401) {
        _showSnackBar('Sesi habis, silakan login ulang', isError: true);
      } else {
        _showSnackBar('Gagal mengambil data: ${response.statusCode}', isError: true);
        print('❌ Error response: ${response.body}');
      }
    } catch (e) {
      print('❌ Error fetching issues: $e');
      _showSnackBar('Error: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Format tanggal
  String _formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  // Translate status API ke display
  String _translateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'opened':
        return 'Menunggu';
      case 'in_progress':
        return 'Diproses';
      case 'resolved':
        return 'Selesai';
      default:
        return status;
    }
  }

  // Get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'opened':
        return widget.purple;
      case 'in_progress':
        return widget.blue;
      case 'resolved':
        return widget.green;
      default:
        return Colors.grey;
    }
  }

  // Get status icon
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'opened':
        return Icons.access_time;
      case 'in_progress':
        return Icons.autorenew;
      case 'resolved':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  // Search
  void _performSearch() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _filteredData = List.from(_permasalahanData);
      });
    } else {
      final query = _searchController.text.toLowerCase().trim();
      setState(() {
        _filteredData = _permasalahanData.where((item) {
          return item['nama'].toLowerCase().contains(query) ||
                 item['judul'].toLowerCase().contains(query) ||
                 item['deskripsi'].toLowerCase().contains(query) ||
                 (item['jenis'] ?? '').toLowerCase().contains(query);
        }).toList();
      });
    }
  }

  // Filter by status
  void _filterByStatus(String? status) {
    setState(() {
      _filterStatus = status;
      _currentPage = 1; // Reset ke halaman 1
      _fetchStudentIssues(page: 1, status: status);
    });
  }

  // Snackbar helper
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? widget.red : widget.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Refresh data
  Future<void> _refreshData() async {
    await _fetchStudentIssues(page: _currentPage, status: _filterStatus);
  }

  // Show detail dialog
  void _showDetailDialog(Map<String, dynamic> data) {
    final status = _translateStatus(data['status']);
    final statusColor = _getStatusColor(data['status']);
    final statusIcon = _getStatusIcon(data['status']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: widget.secondaryColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Detail Permasalahan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: widget.primaryRed,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 28),
                      color: widget.textPrimary,
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card dengan status
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: widget.borderColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha:0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: statusColor.withValues(alpha:0.3)),
                              ),
                              child: Icon(
                                statusIcon,
                                color: statusColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['nama'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha:0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: statusColor.withValues(alpha:0.3),
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
                                          status,
                                          style: TextStyle(
                                            color: statusColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
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
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'Informasi Permasalahan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: widget.borderColor),
                        ),
                        child: Column(
                          children: [
                            _infoRow('Judul', data['judul']),
                            const SizedBox(height: 12),
                            _infoRow('Permasalahan', data['jenis']),
                            const SizedBox(height: 12),
                            _infoRow('Tanggal Laporan', data['tanggal']),
                            if (data['pembimbing_nama'] != null) ...[
                              const SizedBox(height: 12),
                              _infoRow('Pembimbing', data['pembimbing_nama']),
                            ],
                            if (data['tindak_lanjut'] != null) ...[
                              const SizedBox(height: 12),
                              _infoRow('Tindak Lanjut', data['tindak_lanjut']),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    'Deskripsi:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: widget.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    data['deskripsi'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
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
                ),
              ),
              
              // HANYA TOMBOL TUTUP - READ ONLY UNTUK WALI KELAS
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.primaryRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'TUTUP',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
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

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: widget.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return RefreshIndicator(
      onRefresh: _refreshData,
      backgroundColor: Colors.white,
      color: widget.primaryRed,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 16),
            _searchAndFilterSection(),
            const SizedBox(height: 20),
            _problemList(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _searchAndFilterSection() {
    final statusOptions = ['Semua', 'Menunggu', 'Diproses', 'Selesai'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey[200]!),
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
          // Status Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: statusOptions.map((status) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _filterByStatus(status),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _filterStatus == status
                            ? widget.primaryRed
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: widget.primaryRed),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _filterStatus == status
                              ? Colors.white
                              : widget.primaryRed,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Search Field
          _searchField(),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha:0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.search, color: Colors.grey[600], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration.collapsed(
                hintText: 'Cari nama siswa, judul, atau kategori...',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              onChanged: (value) => _performSearch(),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _performSearch();
                });
              },
              icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
            ),
        ],
      ),
    );
  }

  Widget _problemList() {
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_filteredData.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(Icons.warning_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Tidak ada data permasalahan',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Belum ada laporan permasalahan dari siswa',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daftar Permasalahan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: widget.primaryRed,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.primaryRed.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: widget.primaryRed.withValues(alpha:0.2)),
                ),
                child: Text(
                  '${_filteredData.length} masalah',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.primaryRed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._filteredData.map((data) => _ProblemCard(
            data: data,
            onTap: () => _showDetailDialog(data),
            primaryRed: widget.primaryRed,
            purple: widget.purple,
            blue: widget.blue,
            green: widget.green,
          )),

          // Pagination
          if (_totalPages > 1) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Previous button
                InkWell(
                  onTap: _currentPage > 1
                      ? () {
                          setState(() {
                            _currentPage--;
                            _fetchStudentIssues(page: _currentPage, status: _filterStatus);
                          });
                        }
                      : null,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _currentPage > 1
                          ? widget.primaryRed
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Page indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E5E5)),
                  ),
                  child: Text(
                    '$_currentPage',
                    style: const TextStyle(
                      color: Color(0xFF6B1B1B),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                if (_totalPages > 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      '/ $_totalPages',
                      style: const TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 14,
                      ),
                    ),
                  ),

                const SizedBox(width: 10),

                // Next button
                InkWell(
                  onTap: _currentPage < _totalPages
                      ? () {
                          setState(() {
                            _currentPage++;
                            _fetchStudentIssues(page: _currentPage, status: _filterStatus);
                          });
                        }
                      : null,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _currentPage < _totalPages
                          ? widget.primaryRed
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ==============================================
// WIDGET CARD PERMASALAHAN
// ==============================================

class _ProblemCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  final Color primaryRed;
  final Color purple;
  final Color blue;
  final Color green;

  const _ProblemCard({
    required this.data,
    required this.onTap,
    required this.primaryRed,
    required this.purple,
    required this.blue,
    required this.green,
  });

  String _translateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'opened':
        return 'Menunggu';
      case 'in_progress':
        return 'Diproses';
      case 'resolved':
        return 'Selesai';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'opened':
        return purple;
      case 'in_progress':
        return blue;
      case 'resolved':
        return green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'opened':
        return Icons.access_time;
      case 'in_progress':
        return Icons.autorenew;
      case 'resolved':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _translateStatus(data['status']);
    final statusColor = _getStatusColor(data['status']);
    final statusIcon = _getStatusIcon(data['status']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: primaryRed.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: primaryRed.withValues(alpha:0.3)),
                      ),
                      child: Icon(
                        statusIcon,
                        color: statusColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['nama'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha:0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: statusColor.withValues(alpha:0.3)),
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
                                  status,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
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
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Icon(Icons.title, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        data['judul'],
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    Icon(Icons.category, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        data['jenis'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      data['tanggal'],
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: onTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryRed,
                      side: BorderSide(color: primaryRed),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text(
                      'LIHAT DETAIL',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}