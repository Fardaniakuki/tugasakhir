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
  });

  @override
  State<IndustriDetailScreen> createState() => _IndustriDetailScreenState();
}

class _IndustriDetailScreenState extends State<IndustriDetailScreen> {
  static const Color _primaryRed = Color(0xFF6B1B1B);
  static const Color _bgSoft = Color(0xFFF6EEEE);
  static const Color _green = Color(0xFF4CAF50);
  static const Color _orange = Color(0xFFFF9800);
  static const Color _blue = Color(0xFF2196F3);
  static const Color _red = Color(0xFFF44336);

  bool _isLoading = true;
  Map<String, dynamic>? _industriData;
  List<dynamic> _siswaList = [];
  
  // Filter & Pagination variables
  String _currentFilter = 'Semua';
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  int _totalPages = 1;
  int _totalItems = 0;
  
  // Available filters
  final List<String> _filters = [
    'Semua',
    'Aktif',
    'Menunggu',
    'Ditolak'
  ];

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
      // Prioritaskan data detail, lalu isi dengan data preview jika detail kosong
      final Map<String, dynamic> combinedData = {};

      // Mulai dari data detail
      combinedData.addAll(detailData);

      // Tambahkan data dari preview yang tidak ada di detail
      previewData.forEach((key, value) {
        if (!combinedData.containsKey(key) || combinedData[key] == null) {
          combinedData[key] = value;
        }
      });

      // Pastikan ada industri_id
      combinedData['industri_id'] = widget.industriId;

      setState(() {
        _industriData = combinedData;
      });

      // 4. Load data siswa di industri ini
      await _fetchSiswaData();

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

  Future<void> _fetchSiswaData({int page = 1}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      if (token == null) return;

      final String url = '${dotenv.env['API_BASE_URL']}/api/pkl/applications?industri_id=${widget.industriId}&page=$page&limit=$_itemsPerPage';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['data'] != null && data['data'] is List) {
          final siswaData = data['data'] as List;
          
          // Filter data berdasarkan status
          List<dynamic> filteredData = siswaData;
          if (_currentFilter != 'Semua') {
            filteredData = siswaData.where((siswa) {
              final status = siswa['application']?['status'] ?? '';
              return _getStatusText(status) == _currentFilter;
            }).toList();
          }
          
          // Update pagination info
          final totalItems = data['total'] ?? data['meta']?['total'] ?? filteredData.length;
          final totalPages = (totalItems / _itemsPerPage).ceil();
          
          setState(() {
            _siswaList = filteredData;
            _currentPage = page;
            _totalItems = totalItems;
            _totalPages = totalPages > 0 ? totalPages : 1;
          });
        }
      }
    } catch (e) {
      print('Error fetching siswa data: $e');
    }
  }

  int _getJumlahSiswaAktif() {
    return _siswaList.where((siswa) {
      final status = siswa['application']?['status'] ?? '';
      return status == 'Approved' || status == 'Active';
    }).length;
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'Approved':
      case 'Active':
        return 'Aktif';
      case 'Rejected':
        return 'Ditolak';
      case 'Pending':
        return 'Menunggu';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
      case 'Active':
        return _green;
      case 'Completed':
        return _blue;
      case 'Rejected':
        return _red;
      case 'Pending':
        return _orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Approved':
      case 'Active':
        return Icons.check_circle;
      case 'Completed':
        return Icons.done_all;
      case 'Rejected':
        return Icons.cancel;
      case 'Pending':
        return Icons.access_time;
      default:
        return Icons.help_outline;
    }
  }

  // =================== SKELETON LOADING WIDGETS ===================
  Widget _buildSkeletonLoading() {
    return Scaffold(
      backgroundColor: _bgSoft,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Skeleton Header Card
            _skeletonCard(
              height: 200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _skeletonCircle(size: 70),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _skeletonText(width: 200, height: 24),
                            const SizedBox(height: 8),
                            _skeletonText(width: 150, height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _bgSoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _skeletonText(width: 60, height: 32),
                        _skeletonText(width: 1, height: 40),
                        _skeletonText(width: 60, height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Skeleton Biodata Section
            _skeletonSectionTitle(),
            _skeletonCard(
              height: 280,
              child: Column(
                children: [
                  _skeletonInfoRow(),
                  const Divider(height: 20),
                  _skeletonInfoRow(),
                  const Divider(height: 20),
                  _skeletonInfoRow(),
                  const Divider(height: 20),
                  _skeletonInfoRow(),
                  const Divider(height: 20),
                  _skeletonInfoRow(),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Skeleton Statistik Section
            _skeletonSectionTitle(),
            _skeletonCard(
              height: 180,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _skeletonText(width: 120, height: 20),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _skeletonStatItem(),
                      const SizedBox(width: 16),
                      _skeletonStatItem(),
                      const SizedBox(width: 16),
                      _skeletonStatItem(),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Skeleton Siswa Section
            _skeletonSectionTitle(),
            _skeletonCard(
              height: 120,
              child: Row(
                children: [
                  _skeletonCircle(size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _skeletonText(width: 150, height: 20),
                        const SizedBox(height: 8),
                        _skeletonText(width: 100, height: 16),
                      ],
                    ),
                  ),
                  _skeletonText(width: 80, height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _skeletonCard({required double height, required Widget child}) {
    return Container(
      height: height,
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

  Widget _skeletonText({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _skeletonCircle({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _skeletonSectionTitle() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: 150,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _skeletonInfoRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _skeletonText(width: 100, height: 16),
        const SizedBox(width: 12),
        Expanded(
          child: _skeletonText(width: double.infinity, height: 16),
        ),
      ],
    );
  }

  Widget _skeletonStatItem() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            _skeletonCircle(size: 24),
            const SizedBox(height: 8),
            _skeletonText(width: 40, height: 24),
            const SizedBox(height: 4),
            _skeletonText(width: 60, height: 11),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildSkeletonLoading();
    }

    if (_industriData == null) {
      return Scaffold(
        backgroundColor: _bgSoft,
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
        body: Center(
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
        ),
      );
    }

    final kuotaSiswa =
        _industriData?['kuota_siswa'] ?? _industriData?['kuota'] ?? 0;
    final remainingSlots =
        _industriData?['remaining_slots'] ?? _industriData?['sisa_kuota'] ?? 0;
    final jumlahSiswaAktif = _getJumlahSiswaAktif();

    return Scaffold(
      backgroundColor: _bgSoft,
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
      body: RefreshIndicator(
        onRefresh: _loadIndustriData,
        color: _primaryRed,
        child: SingleChildScrollView(
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
              _sectionTitle('Siswa PKL'),
              _siswaFilterBar(),
              _siswaListWidget(),
              _siswaPaginationControls(),
              const SizedBox(height: 20),
            ],
          ),
        ),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Industri
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              color: _primaryRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _primaryRed.withValues(alpha: 0.3), width: 2),
            ),
            child: const Icon(
              Icons.apartment,
              color: _primaryRed,
              size: 36,
            ),
          ),
          const SizedBox(width: 16),

          // Nama dan Bidang
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  style: const TextStyle(
                    fontSize: 20,
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
          _infoRow('Pembimbing Industri', _industriData?['pic'] ?? '-'),
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
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
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
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
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

  Widget _siswaFilterBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isActive = _currentFilter == filter;
          
          return Container(
            margin: EdgeInsets.only(
              left: index == 0 ? 0 : 8,
              right: index == _filters.length - 1 ? 0 : 8,
            ),
            child: FilterChip(
              label: Text(
                filter,
                style: TextStyle(
                  color: isActive ? Colors.white : _primaryRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
              selected: isActive,
              selectedColor: _primaryRed,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isActive ? _primaryRed : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _currentFilter = filter;
                    _currentPage = 1; // Reset ke halaman 1 saat ganti filter
                  });
                  _fetchSiswaData(page: 1);
                }
              },
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _siswaListWidget() {
    if (_siswaList.isEmpty) {
      return _card(
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Icon(Icons.people_outline, size: 60, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  _currentFilter == 'Semua' 
                    ? 'Belum ada siswa PKL di industri ini'
                    : 'Tidak ada siswa dengan status "$_currentFilter"',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _card(
      Column(
        children: [
          // Header dengan jumlah siswa
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: $_totalItems siswa',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _primaryRed,
                  ),
                ),
                if (_currentFilter != 'Semua')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(_currentFilter).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(_currentFilter).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _currentFilter,
                      style: TextStyle(
                        color: _getStatusColor(_currentFilter),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // List siswa
          Column(
            children: _siswaList.asMap().entries.map((entry) {
              final index = entry.key;
              final siswa = entry.value;
              final siswaName = siswa['siswa_username'] ?? 'Siswa';
              final kelasName = siswa['kelas_nama'] ?? '-';
              final status = siswa['application']?['status'] ?? 'Pending';
              final statusText = _getStatusText(status);
              final statusColor = _getStatusColor(status);
              final statusIcon = _getStatusIcon(status);

              return Container(
                margin: EdgeInsets.only(bottom: index < _siswaList.length - 1 ? 12 : 0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: statusColor.withValues(alpha: 0.1),
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
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
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
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _siswaPaginationControls() {
    if (_totalPages <= 1) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous Button
          IconButton(
            onPressed: _currentPage > 1
                ? () {
                    final newPage = _currentPage - 1;
                    _fetchSiswaData(page: newPage);
                  }
                : null,
            icon: Icon(
              Icons.chevron_left,
              color: _currentPage > 1 ? _primaryRed : Colors.grey[400],
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: _currentPage > 1
                      ? _primaryRed.withValues(alpha: 0.3)
                      : Colors.grey[300]!,
                ),
              ),
            ),
          ),

          // Page Numbers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: _buildPageNumbers(),
            ),
          ),

          // Next Button
          IconButton(
            onPressed: _currentPage < _totalPages
                ? () {
                    final newPage = _currentPage + 1;
                    _fetchSiswaData(page: newPage);
                  }
                : null,
            icon: Icon(
              Icons.chevron_right,
              color: _currentPage < _totalPages ? _primaryRed : Colors.grey[400],
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: _currentPage < _totalPages
                      ? _primaryRed.withValues(alpha: 0.3)
                      : Colors.grey[300]!,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers() {
    final List<Widget> pageWidgets = [];
    const int maxVisiblePages = 5;
    
    // Tentukan halaman awal dan akhir
    int startPage = _currentPage - 2;
    int endPage = _currentPage + 2;
    
    if (startPage < 1) {
      endPage += (1 - startPage);
      startPage = 1;
    }
    
    if (endPage > _totalPages) {
      startPage -= (endPage - _totalPages);
      endPage = _totalPages;
      if (startPage < 1) startPage = 1;
    }
    
    // Batasi agar tidak melebihi maxVisiblePages
    if (endPage - startPage + 1 > maxVisiblePages) {
      if (_currentPage - startPage > endPage - _currentPage) {
        startPage = endPage - maxVisiblePages + 1;
      } else {
        endPage = startPage + maxVisiblePages - 1;
      }
    }
    
    // Tombol untuk halaman pertama jika tidak terlihat
    if (startPage > 1) {
      pageWidgets.add(
        _buildPageButton(1, isActive: false),
      );
      if (startPage > 2) {
        pageWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('...', style: TextStyle(color: Colors.grey[600])),
          ),
        );
      }
    }
    
    // Tombol untuk halaman-halaman
    for (int i = startPage; i <= endPage; i++) {
      pageWidgets.add(
        _buildPageButton(i, isActive: i == _currentPage),
      );
    }
    
    // Tombol untuk halaman terakhir jika tidak terlihat
    if (endPage < _totalPages) {
      if (endPage < _totalPages - 1) {
        pageWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('...', style: TextStyle(color: Colors.grey[600])),
          ),
        );
      }
      pageWidgets.add(
        _buildPageButton(_totalPages, isActive: false),
      );
    }
    
    return pageWidgets;
  }

  Widget _buildPageButton(int page, {required bool isActive}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: isActive ? _primaryRed : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            color: isActive ? _primaryRed : Colors.grey[300]!,
          ),
        ),
        child: InkWell(
          onTap: () => _fetchSiswaData(page: page),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            child: Text(
              '$page',
              style: TextStyle(
                color: isActive ? Colors.white : _primaryRed,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
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
}