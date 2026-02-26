import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IndustriDetailScreen extends StatefulWidget {
  final int industriId;

  const IndustriDetailScreen({
    super.key,
    required this.industriId, 
    required String industriNama,
  });

  @override
  State<IndustriDetailScreen> createState() => _IndustriDetailScreenState();
}

class _IndustriDetailScreenState extends State<IndustriDetailScreen> {
  static const Color _primaryRed = Color(0xFF6B1B1B);
  static const Color _green = Color(0xFF4CAF50);

  bool _isLoading = true;
  Map<String, dynamic>? _industriData;
  List<dynamic> _allSiswaList = []; // Menyimpan semua data siswa
  final TextEditingController _kuotaController = TextEditingController();
  
  // Filter dan Pagination
  String _selectedFilter = 'Semua';
  final List<String> _filterOptions = ['Semua', 'Menunggu', 'Diterima', 'Ditolak'];
  
  // Pagination untuk filtered data
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  int _totalFilteredItems = 0;
  int _totalFilteredPages = 1;

  @override
  void initState() {
    super.initState();
    _loadIndustriData();
  }

  Future<void> _loadIndustriData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) return;

      // 1. Pertama, ambil data statistik dari preview
      final previewResponse = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/pkl/industri/preview'),
        headers: {'Authorization': 'Bearer $token'},
      );

      Map<String, dynamic> previewData = {};

      if (previewResponse.statusCode == 200) {
        final data = jsonDecode(previewResponse.body);

        if (data['data'] != null && data['data'] is List) {
          final industriList = data['data'] as List;
          final matchedIndustri = industriList.firstWhere(
            (industri) => industri['industri_id'] == widget.industriId,
            orElse: () => null,
          );

          if (matchedIndustri != null) {
            previewData = Map<String, dynamic>.from(matchedIndustri);
          }
        }
      }

      // 2. Coba ambil data detail dari endpoint admin/umum
      Map<String, dynamic> detailData = {};

      try {
        final detailResponse = await http.get(
          Uri.parse(
              '${dotenv.env['API_BASE_URL']}/api/industri/${widget.industriId}'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (detailResponse.statusCode == 200) {
          final data = jsonDecode(detailResponse.body);
          if (data['success'] == true && data['data'] != null) {
            detailData = Map<String, dynamic>.from(data['data']);
          } else if (data is Map && data.containsKey('nama')) {
            // Jika data langsung tersedia tanpa wrapper
            detailData = Map<String, dynamic>.from(data);
          }
        }
      } catch (e) {
        print('Warning: Detail endpoint not accessible: $e');
        // Lanjutkan hanya dengan preview data
      }

      // 3. Gabungkan kedua data
      final Map<String, dynamic> combinedData = {};
      combinedData.addAll(detailData);
      previewData.forEach((key, value) {
        if (!combinedData.containsKey(key) || combinedData[key] == null) {
          combinedData[key] = value;
        }
      });
      combinedData['industri_id'] = widget.industriId;

      setState(() {
        _industriData = combinedData;
      });

      // 4. Load SEMUA data siswa di industri ini (tanpa pagination dari API)
      await _loadAllSiswaData();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading industri data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAllSiswaData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) return;

      // Ambil semua data tanpa pagination dari API
      // Asumsi endpoint mendukung parameter tanpa pagination
      final siswaResponse = await http.get(
        Uri.parse(
            '${dotenv.env['API_BASE_URL']}/api/pkl/applications?industri_id=${widget.industriId}&all=true'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (siswaResponse.statusCode == 200) {
        final data = jsonDecode(siswaResponse.body);
        if (data['data'] != null && data['data'] is List) {
          setState(() {
            _allSiswaList = data['data'] as List;
            _updatePaginationInfo(); // Update info pagination setelah data dimuat
          });
        }
      }
    } catch (e) {
      print('Error loading all siswa data: $e');
    }
  }

  // Helper untuk mendapatkan data yang sudah difilter
  List<dynamic> get _filteredSiswaList {
    List<dynamic> filteredList;
    
    if (_selectedFilter == 'Semua') {
      filteredList = _allSiswaList;
    } else {
      filteredList = _allSiswaList.where((siswa) {
        final status = siswa['application']?['status']?.toString().toLowerCase() ?? '';
        switch (_selectedFilter) {
          case 'Menunggu':
            return status == 'pending' || status.contains('menunggu');
          case 'Diterima':
            return status == 'approved' || status == 'active' || status.contains('diterima');
          case 'Ditolak':
            return status == 'rejected' || status.contains('ditolak');
          default:
            return true;
        }
      }).toList();
    }
    
    return filteredList;
  }

  // Mendapatkan data untuk halaman saat ini
  List<dynamic> get _currentPageData {
    final filteredList = _filteredSiswaList;
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    
    return filteredList.sublist(
      startIndex.clamp(0, filteredList.length),
      endIndex.clamp(0, filteredList.length),
    );
  }

  void _updatePaginationInfo() {
    final filteredList = _filteredSiswaList;
    
    setState(() {
      _totalFilteredItems = filteredList.length;
      _totalFilteredPages = (_totalFilteredItems / _itemsPerPage).ceil();
      if (_totalFilteredPages == 0) _totalFilteredPages = 1;
      
      // Pastikan current page tidak melebihi total pages
      if (_currentPage > _totalFilteredPages) {
        _currentPage = _totalFilteredPages;
      }
    });
  }

  int _getJumlahSiswaAktif() {
    return _allSiswaList.where((siswa) {
      final status = siswa['application']?['status'] ?? '';
      return status == 'Approved' || status == 'Active';
    }).length;
  }

  void _changePage(int page) {
    if (page < 1 || page > _totalFilteredPages) return;
    
    setState(() {
      _currentPage = page;
    });
  }

  Widget _buildPaginationControls() {
    // Hanya tampilkan pagination jika filtered data lebih dari items per page
    if (_totalFilteredItems <= _itemsPerPage) return const SizedBox();
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          // Info halaman
          Text(
            'Halaman $_currentPage dari $_totalFilteredPages (Total: $_totalFilteredItems)',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          
          // Tombol pagination
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Tombol Previous
              IconButton(
                onPressed: _currentPage > 1
                    ? () => _changePage(_currentPage - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
                style: IconButton.styleFrom(
                  backgroundColor: _primaryRed.withValues(alpha:0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                disabledColor: Colors.grey,
              ),
              
              const SizedBox(width: 8),
              
              // Number buttons - hanya tampilkan jika lebih dari 1 halaman
              if (_totalFilteredPages > 1)
                Wrap(
                  spacing: 4,
                  children: [
                    // First page (tampilkan jika halaman aktif > 3)
                    if (_currentPage > 3)
                      _buildPageButton(1),
                    
                    // Dots (tampilkan jika halaman aktif > 4)
                    if (_currentPage > 4)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text('...', style: TextStyle(color: Colors.grey)),
                      ),
                    
                    // Pages around current page
                    for (int i = max(1, _currentPage - 2); i <= min(_totalFilteredPages, _currentPage + 2); i++)
                      _buildPageButton(i),
                    
                    // Dots (tampilkan jika halaman aktif < totalPages - 3)
                    if (_currentPage < _totalFilteredPages - 3)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text('...', style: TextStyle(color: Colors.grey)),
                      ),
                    
                    // Last page (tampilkan jika halaman aktif < totalPages - 2)
                    if (_currentPage < _totalFilteredPages - 2)
                      _buildPageButton(_totalFilteredPages),
                  ],
                ),
              
              const SizedBox(width: 8),
              
              // Tombol Next
              IconButton(
                onPressed: _currentPage < _totalFilteredPages
                    ? () => _changePage(_currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
                style: IconButton.styleFrom(
                  backgroundColor: _primaryRed.withValues(alpha:0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                disabledColor: Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildPageButton(int page) {
    final isCurrent = page == _currentPage;
    return GestureDetector(
      onTap: () => _changePage(page),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isCurrent ? _primaryRed : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCurrent ? _primaryRed : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          '$page',
          style: TextStyle(
            color: isCurrent ? Colors.white : Colors.grey[700],
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
  
  int max(int a, int b) => a > b ? a : b;
  int min(int a, int b) => a < b ? a : b;

  @override
  void didUpdateWidget(covariant IndustriDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update pagination info setiap kali filter berubah
    _updatePaginationInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _primaryRed,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Detail Industri',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? _buildSkeletonLoading()
          : _industriData == null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildSkeletonLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card Skeleton (disederhanakan tanpa total kuota dan slot)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 14,
                  offset: Offset(0, 6),
                  color: Colors.black12,
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 70,
                      width: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 24,
                            width: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 18,
                            width: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Biodata Skeleton
          _buildSectionSkeleton(),
          _buildInfoRowSkeleton(),
          _buildInfoRowSkeleton(),
          _buildInfoRowSkeleton(),

          const SizedBox(height: 20),

          // Statistik Skeleton
          _buildSectionSkeleton(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItemSkeleton(),
              const SizedBox(width: 16),
              _buildStatItemSkeleton(),
              const SizedBox(width: 16),
              _buildStatItemSkeleton(),
            ],
          ),

          const SizedBox(height: 20),

          // Siswa Mengajukan PKL Skeleton
          _buildSectionSkeleton(),
          const SizedBox(height: 16),
          for (int i = 0; i < 3; i++) _buildSiswaItemSkeleton(),
        ],
      ),
    );
  }

  Widget _buildSectionSkeleton() {
    return Container(
      height: 24,
      width: 150,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  Widget _buildInfoRowSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            offset: Offset(0, 4),
            color: Colors.black12,
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 20,
            width: 100,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItemSkeleton() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Container(
              height: 24,
              width: 24,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 24,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 14,
              width: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSiswaItemSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            offset: Offset(0, 4),
            color: Colors.black12,
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 18,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 14,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 30,
            width: 80,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
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
          const Icon(Icons.error_outline, size: 60, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            'Data industri tidak ditemukan',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryRed,
            ),
            child: const Text('Kembali'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final kuotaSiswa =
        _industriData?['kuota_siswa'] ?? _industriData?['kuota'] ?? 0;
    final remainingSlots =
        _industriData?['remaining_slots'] ?? _industriData?['sisa_kuota'] ?? 0;
    final jumlahSiswaAktif = _getJumlahSiswaAktif();

    return RefreshIndicator(
      onRefresh: _loadIndustriData,
      color: _primaryRed,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headerCard(),
            const SizedBox(height: 20),
            _sectionTitle('Biodata Industri'),
            _biodata(),
            const SizedBox(height: 20),
            _sectionTitle('Statistik Kuota'),
            _statistikCard(kuotaSiswa, remainingSlots, jumlahSiswaAktif),
            const SizedBox(height: 20),
            _sectionTitle('Siswa Mengajukan PKL'),
            _filterChips(),
            const SizedBox(height: 12),
            _siswaListWidget(),
            _buildPaginationControls(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _filterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filterOptions.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                  _currentPage = 1; // Reset ke halaman 1 saat filter berubah
                  _updatePaginationInfo();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? _primaryRed : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? _primaryRed : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _headerCard() {
    final nama = _industriData?['nama'] ?? 'Industri';
    final bidang = _industriData?['bidang'] ?? '-';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            offset: Offset(0, 6),
            color: Colors.black12,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 70,
                width: 70,
                decoration: BoxDecoration(
                  color: _primaryRed.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _primaryRed.withValues(alpha:0.3), width: 2),
                ),
                child: const Icon(
                  Icons.apartment,
                  color: _primaryRed,
                  size: 36,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bidang,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _biodata() {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow('Alamat', _industriData?['alamat'] ?? '-'),
          const Divider(height: 20),
          _infoRow('Telepon', _industriData?['no_telp'] ?? '-'),
          const Divider(height: 20),
          _infoRow('Email', _industriData?['email'] ?? '-'),
          const Divider(height: 20),
          _infoRow('PIC', _industriData?['pic'] ?? '-'),
          const Divider(height: 20),
          _infoRow('Telp PIC', _industriData?['pic_telp'] ?? '-'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _statistikCard(int totalKuota, int sisaKuota, int jumlahSiswa) {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Kuota',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _primaryRed,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _statItem(
                  Icons.people_outline,
                  '$totalKuota',
                  'Total Kuota',
                  _primaryRed,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _statItem(
                  Icons.people,
                  '$jumlahSiswa',
                  'Siswa Aktif',
                  _green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _statItem(
                  sisaKuota > 0 ? Icons.event_available : Icons.event_busy,
                  '$sisaKuota',
                  'Slot Tersedia',
                  sisaKuota > 0 ? _green : Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (sisaKuota == 0)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withValues(alpha:0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kuota sudah penuh. Pertimbangkan untuk menambah kuota.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[800],
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

  Widget _statItem(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha:0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _siswaListWidget() {
    final currentData = _currentPageData;
    
    if (currentData.isEmpty) {
      return _card(
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Icon(
                  _selectedFilter == 'Semua' 
                    ? Icons.people_outline 
                    : Icons.filter_alt_outlined,
                  size: 60, 
                  color: Colors.grey[400]
                ),
                const SizedBox(height: 16),
                Text(
                  _selectedFilter == 'Semua' 
                    ? 'Belum ada siswa yang mengajukan PKL di industri ini'
                    : 'Tidak ada siswa dengan status "$_selectedFilter"',
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: currentData.asMap().entries.map((entry) {
        final index = entry.key;
        final siswa = entry.value;
        final siswaName = siswa['siswa_username'] ?? 'Siswa';
        final kelasName = siswa['kelas_nama'] ?? '-';
        final status = siswa['application']?['status'] ?? 'Pending';

        Color statusColor;
        String statusText;
        IconData statusIcon;

        switch (status) {
          case 'Approved':
          case 'Active':
            statusColor = Colors.green;
            statusText = 'Diterima';
            statusIcon = Icons.check_circle;
            break;
          case 'Completed':
            statusColor = Colors.blue;
            statusText = 'Selesai';
            statusIcon = Icons.done_all;
            break;
          case 'Rejected':
            statusColor = Colors.red;
            statusText = 'Ditolak';
            statusIcon = Icons.cancel;
            break;
          default:
            statusColor = Colors.orange;
            statusText = 'Menunggu';
            statusIcon = Icons.access_time;
        }

        return Container(
          margin: EdgeInsets.only(bottom: index < currentData.length - 1 ? 12 : 0),
          child: _card(
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withValues(alpha:0.1),
                  child: Icon(
                    Icons.person,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        siswaName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        kelasName,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha:0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
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
        );
      }).toList(),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: _primaryRed,
        ),
      ),
    );
  }

  Widget _card(Widget child) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            offset: Offset(0, 4),
            color: Colors.black12,
          )
        ],
      ),
      child: child,
    );
  }

  @override
  void dispose() {
    _kuotaController.dispose();
    super.dispose();
  }
}