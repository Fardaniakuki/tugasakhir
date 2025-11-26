import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SiswaDashboard extends StatefulWidget {
  const SiswaDashboard({super.key});

  @override
  State<SiswaDashboard> createState() => _SiswaDashboardState();
}

class _SiswaDashboardState extends State<SiswaDashboard> {
  // Data siswa
  String _namaSiswa = 'Loading...';
  String _kelasSiswa = 'Loading...';
  bool _isLoading = true;
  bool _hasError = false;

  // Data PKL
  Map<String, dynamic>? _pklData;
  List<dynamic> _pklApplications = [];
  Map<String, dynamic>? _industriData;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      await _loadProfileData();
      await _loadPklApplications();
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _hasError = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _namaSiswa = prefs.getString('user_name') ?? 'Nama Tidak Tersedia';
      _kelasSiswa = prefs.getString('user_kelas') ?? 'Kelas Tidak Tersedia';
    });
  }

  Future<void> _loadPklApplications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/pkl/applications/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['data'] != null && data['data'] is List && data['data'].isNotEmpty) {
          setState(() {
            _pklApplications = data['data'];
            _pklApplications.sort((a, b) => b['id'].compareTo(a['id']));
            _pklData = _pklApplications.first;
          });

          if (_pklData?['industri_id'] != null) {
            await _loadIndustriData(_pklData!['industri_id']);
          }
        }
      }
    } catch (e) {
      print('Error loading PKL applications: $e');
    }
  }

  Future<void> _loadIndustriData(int industriId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/industri/$industriId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _industriData = data['data'];
        });
      }
    } catch (e) {
      print('Error fetching industry: $e');
    }
  }

  String _getIndustriName() {
    if (_industriData == null) return 'Loading...';
    return _industriData!['nama'] ?? 'Nama tidak tersedia';
  }

  String _getIndustriBidang() {
    if (_industriData == null) return '';
    return _industriData!['bidang'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingSkeleton();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        color: const Color(0xFF641E20),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Modern App Bar
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: const Color(0xFF641E20),
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF641E20),
                        Color(0xFF8B2A2C),
                        Color(0xFFA03335),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.2),
                                      Colors.white.withOpacity(0.1),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(Icons.person, color: Colors.white, size: 30),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _namaSiswa,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _kelasSiswa,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  onPressed: _loadAllData,
                                  icon: const Icon(Icons.refresh, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _pklData != null ? 'PKL Aktif' : 'Belum PKL',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Status PKL Card
                    _buildModernStatusCard(),
                    const SizedBox(height: 20),

                    // Industri Card jika ada
                    if (_pklData != null && _industriData != null) 
                      _buildModernIndustriCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernStatusCard() {
    final hasApplication = _pklData != null;
    final status = _pklData?['status']?.toString() ?? 'Belum Mengajukan';
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.white.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative elements
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor.withOpacity(0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Status PKL',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (hasApplication) ...[
                  _buildModernInfoItem(
                    Icons.calendar_today_rounded,
                    'Tanggal Pengajuan',
                    _formatDate(_pklData!['tanggal_permohonan']?.toString()),
                    Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  _buildModernInfoItem(
                    Icons.business_rounded,
                    'Tempat PKL',
                    _getIndustriName(),
                    Colors.purple,
                  ),
                  
                  if (_pklData!['catatan'] != null && _pklData!['catatan'].toString().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildModernInfoItem(
                      Icons.note_rounded,
                      'Catatan',
                      _pklData!['catatan'].toString(),
                      Colors.orange,
                    ),
                  ],

                  // Status Message
                  const SizedBox(height: 20),
                  _buildStatusBanner(status),
                ] else ...[
                  const SizedBox(height: 30),
                  _buildEmptyState(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernIndustriCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF641E20),
            Color(0xFF8B2A2C),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF641E20).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.business_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Tempat PKL',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Company Info
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(Icons.factory_rounded, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getIndustriName(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_getIndustriBidang().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              _getIndustriBidang(),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Company Details
                if (_industriData?['alamat'] != null)
                  _buildIndustriDetail('Alamat', _industriData!['alamat']),
                if (_industriData?['pic'] != null)
                  _buildIndustriDetail('PIC', _industriData!['pic']),
                if (_industriData?['no_telp'] != null)
                  _buildIndustriDetail('Telepon', _industriData!['no_telp']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoItem(IconData icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndustriDetail(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$title:',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(String status) {
    final Map<String, Map<String, dynamic>> statusConfig = {
      'pending': {
        'icon': Icons.access_time_rounded,
        'color': Colors.orange,
        'message': 'Pengajuan sedang dalam proses review oleh sekolah'
      },
      'approved': {
        'icon': Icons.check_circle_rounded,
        'color': Colors.green,
        'message': 'Selamat! Pengajuan PKL Anda telah disetujui'
      },
      'rejected': {
        'icon': Icons.cancel_rounded,
        'color': Colors.red,
        'message': 'Pengajuan ditolak. Silakan ajukan kembali'
      },
    };

    final config = statusConfig[status.toLowerCase()] ?? {
      'icon': Icons.help_rounded,
      'color': Colors.grey,
      'message': 'Status tidak dikenali'
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            config['color']!.withOpacity(0.1),
            config['color']!.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: config['color']!.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: config['color']!.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(config['icon'] as IconData, color: config['color'], size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              config['message'] as String,
              style: TextStyle(
                color: config['color'],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.grey[200]!,
                Colors.grey[100]!,
            ],
          ),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.work_outline_rounded, size: 40, color: Colors.grey[400]),
        ),
        const SizedBox(height: 16),
        const Text(
          'Belum Ada Pengajuan PKL',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Ajukan PKL sekarang untuk memulai\nprogram praktik kerja industri',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSkeleton() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Color(0xFF641E20),
            flexibleSpace: SizedBox(),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(child: CircularProgressIndicator(color: Color(0xFF641E20))),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(child: CircularProgressIndicator(color: Color(0xFF641E20))),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(Icons.error_outline_rounded, size: 50, color: Colors.grey[400]),
            ),
            const SizedBox(height: 20),
            const Text(
              'Gagal Memuat Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Periksa koneksi internet Anda',
              style: TextStyle(
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadAllData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF641E20),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  // Utility functions
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      case 'active': return Colors.blue;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return 'Menunggu';
      case 'approved': return 'Disetujui';
      case 'rejected': return 'Ditolak';
      case 'active': return 'Aktif';
      default: return 'Belum';
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}