import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ajukan_pkl_dialog.dart';

class SiswaDashboard extends StatefulWidget {
  const SiswaDashboard({super.key});

  @override
  State<SiswaDashboard> createState() => _SiswaDashboardState();
}

class _SiswaDashboardState extends State<SiswaDashboard> {
  String _namaSiswa = 'Loading...';
  String _kelasSiswa = 'Loading...';
  int? _kelasId;
  bool _isLoading = true;
  bool _hasError = false;

  Map<String, dynamic>? _pklData;
  List<dynamic> _pklApplications = [];
  Map<String, dynamic>? _industriData;
  Map<String, dynamic>? _pembimbingData;
  Map<String, dynamic>? _processedByData;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      await _loadProfileData();
      await _loadPklApplications();
    } catch (e) {
      setState(() => _hasError = true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final userName = prefs.getString('user_name');
    
    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/siswa?search=$userName'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && 
            data['data'] != null && 
            data['data']['data'] != null && 
            data['data']['data'].isNotEmpty) {
          
          final List<dynamic> siswaList = data['data']['data'];
          
          final matchedSiswa = siswaList.firstWhere(
            (siswa) => siswa['nama_lengkap'] == userName,
            orElse: () => siswaList.first
          );
          
          final kelasId = matchedSiswa['kelas_id'];
          
          await prefs.setInt('user_kelas_id', kelasId);
          
          setState(() {
            _namaSiswa = userName ?? 'Nama Tidak Tersedia';
            _kelasSiswa = prefs.getString('user_kelas') ?? 'Kelas Tidak Tersedia';
            _kelasId = kelasId;
          });
          return;
        }
      }
    } catch (e) {
      print('Error loading profile from API: $e');
    }
    
    final kelasIdFromPrefs = prefs.getInt('user_kelas_id');
    setState(() {
      _namaSiswa = userName ?? 'Nama Tidak Tersedia';
      _kelasSiswa = prefs.getString('user_kelas') ?? 'Kelas Tidak Tersedia';
      _kelasId = kelasIdFromPrefs;
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
        if (data['data'] != null && data['data'].isNotEmpty) {
          setState(() {
            _pklApplications = data['data'];
            _pklApplications.sort((a, b) => b['id'].compareTo(a['id']));
            _pklData = _pklApplications.first;
          });

          if (_pklData?['industri_id'] != null) {
            await _loadIndustriData(_pklData!['industri_id']);
          }
          if (_pklData?['pembimbing_guru_id'] != null) {
            await _loadPembimbingData(_pklData!['pembimbing_guru_id']);
          }
          if (_pklData?['processed_by'] != null) {
            await _loadProcessedByData(_pklData!['processed_by']);
          }
        }
      }
    } catch (_) {}
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
        final data = jsonDecode(response.body);
        setState(() => _industriData = data['data']);
      }
    } catch (_) {}
  }

  Future<void> _loadPembimbingData(int? guruId) async {
    if (guruId == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/guru/$guruId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _pembimbingData = data['data']);
      }
    } catch (_) {}
  }

  Future<void> _loadProcessedByData(int? guruId) async {
    if (guruId == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/guru/$guruId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _processedByData = data['data']);
      }
    } catch (_) {}
  }

  // Fungsi untuk mengajukan PKL
  Future<void> _ajukanPKL() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (_kelasId == null) {
        await _loadProfileData();
      }

      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AjukanPKLDialog(
          token: token,
          kelasId: _kelasId,
        ),
      );

      if (result != null) {
        final response = await http.post(
          Uri.parse('${dotenv.env['API_BASE_URL']}/api/pkl/applications'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'catatan': result['catatan'],
            'industri_id': result['industri_id'],
          }),
        );

        if (response.statusCode == 201) {
          await _loadAllData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pengajuan PKL berhasil dikirim')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal mengajukan PKL: ${response.body}')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Terjadi kesalahan saat mengajukan PKL')),
        );
      }
    }
  }

  // Fungsi untuk membuka halaman riwayat
  void _bukaRiwayat() {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) => const RiwayatPKLPage()),
    // );
  }

  // Fungsi untuk membuka halaman industri
  void _bukaIndustri() {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) => const ListIndustriPage()),
    // );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'disetujui':
      case 'approved':
        return Colors.green;
      case 'ditolak':
      case 'rejected':
        return Colors.red;
      case 'menunggu':
      case 'pending':
        return Colors.orange;
      default:
        return Colors.orange;
    }
  }

  String _formatTanggal(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-.-';
    
    try {
      final date = DateTime.parse(dateString);
      final bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 
                    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      
      return '${date.day} ${bulan[date.month - 1]} ${date.year}';
    } catch (e) {
      return '-.-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Column(
                children: [
                  Container(
                    height: 280,
                    color: Colors.white,
                  ),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFD9D9D9),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            _isLoading
                ? _buildSkeletonLoading()
                : _hasError
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 50, color: Colors.black),
                            const SizedBox(height: 16),
                            const Text('Terjadi kesalahan', style: TextStyle(fontSize: 16)),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _loadAllData,
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAllData,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          children: [
                            const SizedBox(height: 12),
                            _buildProfileCard(),
                            const SizedBox(height: 20),
                            _buildQuickActions(),
                            const SizedBox(height: 20),
                            _buildPKLStatusCard(),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 12),
        _buildProfileCardSkeleton(),
        const SizedBox(height: 20),
        _buildQuickActionsSkeleton(),
        const SizedBox(height: 20),
        _buildPKLStatusCardSkeleton(),
      ],
    );
  }

  Widget _buildProfileCardSkeleton() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 0.5,
                        height: 20,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.3,
                        height: 16,
                        color: Colors.grey[300],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 60, height: 14, color: Colors.grey[300]),
                      const SizedBox(height: 4),
                      Container(width: 100, height: 16, color: Colors.grey[300]),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 60, height: 14, color: Colors.grey[300]),
                      const SizedBox(height: 4),
                      Container(width: 100, height: 16, color: Colors.grey[300]),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 100, height: 20, color: Colors.grey[300]),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _menuButtonSkeleton(),
              _menuButtonSkeleton(),
              _menuButtonSkeleton(),
              _menuButtonSkeleton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _menuButtonSkeleton() {
    return Column(
      children: [
        const CircleAvatar(
          radius: 23,
          backgroundColor: Colors.grey,
        ),
        const SizedBox(height: 6),
        Container(width: 40, height: 12, color: Colors.grey[300]),
      ],
    );
  }

  Widget _buildPKLStatusCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(width: 100, height: 20, color: Colors.grey[300]),
              Container(width: 80, height: 30, color: Colors.grey[300]),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.grey[300]),
          const SizedBox(height: 16),
          _infoRowSkeleton(),
          _infoRowSkeleton(),
          _infoRowSkeleton(),
          _infoRowSkeleton(),
          _infoRowSkeleton(),
          _infoRowSkeleton(),
        ],
      ),
    );
  }

  Widget _infoRowSkeleton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const CircleAvatar(radius: 10, backgroundColor: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Container(height: 16, color: Colors.grey[300]),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.black,
                  child: Icon(Icons.person, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_namaSiswa,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(_kelasSiswa,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
            
            if (_pklData != null) ...[
              const SizedBox(height: 12),
              Container(
                height: 1,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 12),
              _buildDateSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateSection() {
    return Row(
      children: [
        Expanded(
          child: _buildDateItem('Mulai', _formatTanggal(_pklData!['tanggal_mulai'])),
        ),
        Container(
          width: 1,
          height: 40,
          color: Colors.grey[300],
        ),
        Expanded(
          child: _buildDateItem('Selesai', _formatTanggal(_pklData!['tanggal_selesai'])),
        ),
      ],
    );
  }

  Widget _buildDateItem(String label, String date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          date,
          style: TextStyle(
            fontSize: date == '-.-' ? 20 : 18,
            fontWeight: FontWeight.w600,
            color: date == '-.-' ? Colors.grey[500] : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Aksi Cepat',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _menuButton(Icons.assignment_outlined, 'Ajukan', _ajukanPKL),
              _menuButton(Icons.history, 'Riwayat', _bukaRiwayat),
              _menuButton(Icons.factory_rounded, 'Industri', _bukaIndustri),
              _menuButton(Icons.help_outline, 'Bantuan', () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _menuButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            radius: 23,
            child: Icon(icon, color: Colors.black),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black)),
        ],
      ),
    );
  }

  Widget _buildPKLStatusCard() {
    if (_pklData == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: _cardStyle(),
        child: Column(
          children: [
            const Icon(Icons.info_outline, size: 35, color: Colors.black54),
            const SizedBox(height: 10),
            const Text('Belum ada pengajuan PKL'),
            const SizedBox(height: 10),
            ElevatedButton(
                onPressed: _ajukanPKL, 
                child: const Text('Ajukan PKL Sekarang'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardStyle(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusHeader(_pklData!['status']),
          const Divider(height: 22),
          _infoRow(Icons.factory, 'Nama Industri', _industriData?['nama']),
          _infoRow(Icons.date_range, 'Tanggal Permohonan',
              _formatTanggal(_pklData!['tanggal_permohonan'])),
          _infoRow(Icons.note_alt_outlined, 'Catatan', _pklData!['catatan']),
          _infoRow(Icons.person_pin_outlined, 'Pembimbing', 
              _pembimbingData?['nama'] ?? '-'),
          _infoRow(Icons.verified_user_outlined, 'Diproses Oleh',
              _processedByData?['nama'] ?? '-'),
        ],
      ),
    );
  }

  BoxDecoration _cardStyle() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
            color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
      ],
    );
  }

  Widget _buildStatusHeader(String status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Status PKL',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _statusColor(status).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: _statusColor(status),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        )
      ],
    );
  }

  Widget _infoRow(IconData icon, String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black54),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$title : ${value ?? '-'}',
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}