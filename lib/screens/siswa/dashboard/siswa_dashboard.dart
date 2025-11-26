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

      await Future.wait([
        _loadProfileData(),
        _loadPklData(),
        _loadRecentActivities(),
        _loadUpcomingDeadlines(),
      ]);
    } catch (e) {
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

  Future<void> _loadPklData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/siswa/pkl/status'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _pklData = data['data'];
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadRecentActivities() async {
    // Implement fetch recent activities
  }

  Future<void> _loadUpcomingDeadlines() async {
    // Implement fetch deadlines
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
      backgroundColor: const Color(0xFFF5F5F5),
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildPklStatusCard(),
              const SizedBox(height: 16),
              _buildQuickActions(),
              const SizedBox(height: 16),
              _buildRecentActivities(),
              const SizedBox(height: 16),
              _buildUpcomingDeadlines(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 HEADER PROFIL
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF641E20),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white, size: 30),
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
          IconButton(
            onPressed: _loadAllData,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // 🔹 STATUS PKL CARD
  Widget _buildPklStatusCard() {
    final status = _pklData?['status'] ?? 'Belum Mengajukan';
    final Color statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
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
                  color: Color(0xFF641E20),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_pklData != null) ...[
            _buildPklInfoRow('🏢', 'Tempat PKL', _pklData!['tempat_pkl'] ?? '-'),
            _buildPklInfoRow('👨‍🏫', 'Pembimbing Sekolah', _pklData!['pembimbing_sekolah'] ?? '-'),
            _buildPklInfoRow('👨‍💼', 'Pembimbing Industri', _pklData!['pembimbing_industri'] ?? '-'),
            _buildPklInfoRow('📅', 'Periode', '${_pklData!['periode_mulai']} - ${_pklData!['periode_selesai']}'),
            
            if (_pklData!['progress'] != null) ...[
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Progress PKL',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (_pklData!['progress'] ?? 0) / 100,
                    backgroundColor: Colors.grey[200],
                    color: const Color(0xFF641E20),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_pklData!['progress']}% selesai',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ] else ...[
            const Center(
              child: Column(
                children: [
                  Icon(Icons.work_outline, size: 50, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'Belum ada pengajuan PKL',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Ajukan PKL sekarang untuk memulai',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPklInfoRow(String emoji, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'aktif':
        return Colors.green;
      case 'menunggu':
        return Colors.orange;
      case 'ditolak':
        return Colors.red;
      case 'selesai':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // 🔹 LAYANAN CEPAT (DIPERBAIKI)
  Widget _buildQuickActions() {
    final List<Map<String, dynamic>> actions = [
      {
        'icon': Icons.add_circle_outline,
        'label': 'Ajukan\nPKL',
        'color': const Color(0xFF2563EB),
        'onTap': () => _navigateToPengajuanPkl(),
      },
      {
        'icon': Icons.upload_outlined,
        'label': 'Upload\nDokumen',
        'color': const Color(0xFF059669),
        'onTap': () => _navigateToUpload(),
      },
      {
        'icon': Icons.assignment_outlined,
        'label': 'Laporan\nHarian',
        'color': const Color(0xFFEA580C),
        'onTap': () => _navigateToLaporan(),
      },
      {
        'icon': Icons.calendar_today_outlined,
        'label': 'Jadwal\nMonitoring',
        'color': const Color(0xFF7C3AED),
        'onTap': () => _navigateToJadwal(),
      },
      {
        'icon': Icons.assignment_turned_in_outlined,
        'label': 'Log\nAktivitas',
        'color': const Color(0xFFDC2626),
        'onTap': () => _navigateToLogAktivitas(),
      },
      {
        'icon': Icons.work_outline,
        'label': 'Tempat\nPKL',
        'color': const Color(0xFF0891B2),
        'onTap': () => _navigateToTempatPkl(),
      },
      {
        'icon': Icons.description_outlined,
        'label': 'Dokumen\nPKL',
        'color': const Color(0xFF92400E),
        'onTap': () => _navigateToDokumen(),
      },
      {
        'icon': Icons.help_outline,
        'label': 'Bantuan',
        'color': const Color(0xFF6B7280),
        'onTap': () => _navigateToBantuan(),
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Layanan Cepat',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF641E20),
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              return _buildActionItem(
                action['icon'] as IconData,
                action['label'] as String,
                action['color'] as Color,
                action['onTap'] as Function,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label, Color color, Function onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onTap(),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 AKTIVITAS TERBARU
  Widget _buildRecentActivities() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aktivitas Terbaru',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF641E20),
            ),
          ),
          const SizedBox(height: 12),
          // Implement recent activities list
          _buildPlaceholderContent('Daftar aktivitas akan muncul di sini'),
        ],
      ),
    );
  }

  // 🔹 DEADLINE MENDEKAT
  Widget _buildUpcomingDeadlines() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Deadline Mendekat',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF641E20),
            ),
          ),
          const SizedBox(height: 12),
          _buildPlaceholderContent('Daftar deadline akan muncul di sini'),
        ],
      ),
    );
  }

  Widget _buildPlaceholderContent(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 50, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              text,
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Skeleton untuk header
            Container(
              height: 200,
              color: const Color(0xFF641E20),
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
            const SizedBox(height: 16),
            // Skeleton untuk cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: List.generate(3, (index) => 
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  )
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Gagal memuat data',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Periksa koneksi internet Anda'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadAllData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF641E20),
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  // Navigation methods
  void _navigateToPengajuanPkl() => ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigasi ke Pengajuan PKL')),
    );

  void _navigateToUpload() => ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigasi ke Upload Dokumen')),
    );

  void _navigateToLaporan() => ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigasi ke Laporan Harian')),
    );

  void _navigateToJadwal() {
   
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigasi ke Jadwal Monitoring')),
    );
  }

  void _navigateToLogAktivitas() {
   
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigasi ke Log Aktivitas')),
    );
  }

  void _navigateToTempatPkl() {
   
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigasi ke Tempat PKL')),
    );
  }

  void _navigateToDokumen() {
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigasi ke Dokumen PKL')),
    );
  }

  void _navigateToBantuan() {
   
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigasi ke Bantuan')),
    );
  }
}