import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class KelolaPerizinanTabScreen extends StatefulWidget {
  const KelolaPerizinanTabScreen({super.key, required scrollController});

  @override
  State<KelolaPerizinanTabScreen> createState() =>
      _KelolaPerizinanTabScreenState();
}

class _KelolaPerizinanTabScreenState extends State<KelolaPerizinanTabScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final Color _primaryRed = const Color(0xFF6B1B1B);
  final Color _bgSoft = const Color(0xFFF6EEEE);
  late TabController _tabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Tambahkan listener untuk update UI saat tab berubah
    _tabController.addListener(() {
      setState(() {}); // Panggil setState untuk rebuild header
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
    return Scaffold(
      backgroundColor: _bgSoft,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 180.0,
            backgroundColor: _bgSoft,
            pinned: true,
            floating: true,
            flexibleSpace: FlexibleSpaceBar(background: _headerCard()),
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
                      fontWeight: FontWeight.w700, fontSize: 14),
                  unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 14),
                  tabs: const [
                    Tab(text: 'Sakit dan Izin'),
                    Tab(text: 'Pengajuan Pindah')
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            KelolaSiaContent(primaryRed: _primaryRed),
            KelolaPengajuanPklContent(primaryRed: _primaryRed),
          ],
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
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Kelola Perizinan',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF6B1B1B))),
          const SizedBox(height: 8),
          Text(
            // Perbaikan: Sesuaikan teks dengan tab yang aktif
            _tabController.index == 0
                ? 'Kelola Sakit dan Izin siswa PKL'
                : 'Kelola pengajuan pindah PKL',
            style: const TextStyle(
                fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class KelolaSiaContent extends StatefulWidget {
  final Color primaryRed;
  const KelolaSiaContent({super.key, required this.primaryRed});

  @override
  State<KelolaSiaContent> createState() => _KelolaSiaContentState();
}

class _KelolaSiaContentState extends State<KelolaSiaContent>
    with SingleTickerProviderStateMixin {
  late TabController _siaTabController;
  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'Semua';
  List<dynamic> _izinData = [];
  List<dynamic> _filteredIzinData = [];
  bool _isLoading = false;
  final Map<int, String> _kelasCache = {};

  final List<Map<String, dynamic>> _dummyIzinData = [
    {
      'id': 1,
      'siswa_id': 78,
      'siswa_nama': 'Ahmad Rizki',
      'tanggal': '2024-03-15',
      'jenis': 'Sakit',
      'keterangan': 'Demam tinggi, ada surat dokter',
      'status': 'pending',
      'bukti_foto_urls': [
        'https://cdn.gedanggoreng.com/uploads/izin/sample1.jpg'
      ],
    },
    {
      'id': 2,
      'siswa_id': 190,
      'siswa_nama': 'Siti Nurhaliza',
      'tanggal': '2024-03-14',
      'jenis': 'Izin',
      'keterangan': 'Menghadiri acara keluarga penting',
      'status': 'approved',
      'bukti_foto_urls': [],
    },
    {
      'id': 3,
      'siswa_id': 166,
      'siswa_nama': 'Budi Santoso',
      'tanggal': '2024-03-13',
      'jenis': 'Sakit',
      'keterangan': 'Pusing dan mual',
      'status': 'rejected',
      'rejection_reason': 'Bukti tidak jelas',
      'bukti_foto_urls': [],
    },
  ];

  @override
  void initState() {
    super.initState();
    _siaTabController = TabController(length: 2, vsync: this);
    _siaTabController.addListener(() => _filterData());
    _fetchIzinData();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<String?> _fetchKelas(int kelasId) async {
    try {
      if (_kelasCache.containsKey(kelasId)) return _kelasCache[kelasId];

      final token = await _getToken();
      if (token == null) return null;

      final baseUrl =
          dotenv.env['API_BASE_URL'] ?? 'https://api.gedanggoreng.com';
      final response = await http.get(
        Uri.parse('$baseUrl/api/kelas/$kelasId'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final kelasNama = data['data']['nama'] ?? 'Tidak Diketahui';
          _kelasCache[kelasId] = kelasNama;
          return kelasNama;
        }
      }
    } catch (e) {
      print('Error fetching kelas: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> _fetchSiswaDetail(int siswaId) async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final baseUrl =
          dotenv.env['API_BASE_URL'] ?? 'https://api.gedanggoreng.com';
      final response = await http.get(
        Uri.parse('$baseUrl/api/siswa/$siswaId'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final siswaData = data['data'] as Map<String, dynamic>;
          final kelasId = siswaData['kelas_id'];
          if (kelasId != null) {
            final kelasNama = await _fetchKelas(kelasId);
            siswaData['kelas'] = kelasNama ?? 'Tidak Diketahui';
          }
          siswaData['nama_lengkap'] = siswaData['nama_lengkap'] ??
              siswaData['username'] ??
              'Siswa $siswaId';
          return siswaData;
        }
      }
    } catch (e) {
      print('Error fetching siswa detail: $e');
    }
    return null;
  }

  Future<void> _fetchIzinData({String? status}) async {
    setState(() {
      _isLoading = true;
      _kelasCache.clear();
    });

    try {
      final token = await _getToken();

      if (token != null) {
        final baseUrl =
            dotenv.env['API_BASE_URL'] ?? 'https://api.gedanggoreng.com';
        final url = status != null && status != 'Semua'
            ? '$baseUrl/api/izin/pembimbing?status=${status.toLowerCase()}'
            : '$baseUrl/api/izin/pembimbing';

        final response = await http.get(Uri.parse(url), headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        });

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is List && data.isNotEmpty) {
            final List<dynamic> processedData = [];
            for (var izin in data) {
              if (izin['siswa_id'] != null) {
                final siswaDetail = await _fetchSiswaDetail(izin['siswa_id']);
                if (siswaDetail != null) {
                  izin['siswa_data'] = siswaDetail;
                  izin['siswa_nama'] = siswaDetail['nama_lengkap'];
                }
              }
              processedData.add(izin);
            }
            setState(() {
              _izinData = processedData;
            });
          } else {
            setState(() {
              _izinData = _dummyIzinData;
            });
          }
        } else {
          setState(() {
            _izinData = _dummyIzinData;
          });
        }
      } else {
        setState(() {
          _izinData = _dummyIzinData;
        });
      }
    } catch (e) {
      setState(() {
        _izinData = _dummyIzinData;
      });
    } finally {
      _filterData();
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _decideIzin(int id, String status,
      {String? rejectionReason}) async {
    bool success = false;
    String message = '';

    try {
      final token = await _getToken();
      if (token == null) {
        _showSnackBar('Gagal: Token tidak ditemukan', isError: true);
        return;
      }

      final baseUrl =
          dotenv.env['API_BASE_URL'] ?? 'https://api.gedanggoreng.com';
      final url = '$baseUrl/api/izin/$id/decide';

      final Map<String, String> body = {'status': status};
      if (status == 'rejected' && rejectionReason != null) {
        body['rejection_reason'] = rejectionReason;
      }

      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final index = _izinData.indexWhere((item) => item['id'] == id);
        if (index != -1) {
          setState(() {
            _izinData[index]['status'] = status;
            if (status == 'rejected') {
              _izinData[index]['rejection_reason'] = rejectionReason;
            }
            _izinData[index]['decided_at'] = DateTime.now().toIso8601String();
          });
          _filterData();
        }
        success = true;
        message = status == 'approved'
            ? 'Izin berhasil disetujui'
            : 'Izin berhasil ditolak';
      } else {
        throw Exception('Failed to update status: ${response.statusCode}');
      }
    } catch (e) {
      success = false;
      message = 'Gagal memperbarui status: $e';
    }

    if (success) {
      _showSuccessAnimation(
        status == 'approved' ? 'Izin Disetujui' : 'Izin Ditolak',
        message,
        isSuccess: status == 'approved',
      );
    } else {
      _showSnackBar(message, isError: true);
    }
  }

  void _showApproveDialog(dynamic data) {
    final siswaNama = data['siswa_nama'] ??
        data['siswa_data']?['nama_lengkap'] ??
        'Siswa ${data['siswa_id']}';
    final kelas = data['siswa_data']?['kelas'] ?? '-';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.green.shade50, Colors.white]),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle),
                child: const Icon(Icons.check_circle,
                    color: Colors.green, size: 48),
              ),
              Text('Setujui Izin',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.green.shade800)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(siswaNama,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.school, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text('Kelas: $kelas',
                            style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text('Tanggal: ${data['tanggal']}',
                            style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Apakah Anda yakin ingin menyetujui izin ini?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey)),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey,
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('Batal',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _decideIzin(data['id'], 'approved');
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 2),
                      child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check, size: 20),
                            SizedBox(width: 8),
                            Text('Setujui',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                          ]),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRejectDialog(dynamic data) {
    final TextEditingController alasanController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tolak Izin'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data['siswa_nama'] ?? 'Siswa',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Tanggal: ${data['tanggal']}',
                  style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 12),
              const Text('Alasan:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: alasanController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Alasan penolakan...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(8),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = alasanController.text.trim();
              if (reason.length < 10) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Minimal 10 karakter')),
                );
                return;
              }
              Navigator.pop(context);
              _decideIzin(data['id'], 'rejected', rejectionReason: reason);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
              child: Text(message,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white))),
        ]),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessAnimation(String title, String message,
      {bool isSuccess = true}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation1, animation2) => const SizedBox(),
      transitionBuilder: (context, animation1, animation2, child) {
        return ScaleTransition(
          scale:
              CurvedAnimation(parent: animation1, curve: Curves.fastOutSlowIn),
          child: FadeTransition(
            opacity: animation1,
            child: _SuccessDialog(
                title: title,
                message: message,
                isSuccess: isSuccess,
                onClose: () => Navigator.pop(context)),
          ),
        );
      },
    );
  }

  void _showImagePreview(List<String> imageUrls) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black87,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.black,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Bukti Foto',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600)),
                    IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  itemCount: imageUrls.length,
                  itemBuilder: (context, index) => InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: Image.network(imageUrls[index],
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey[800],
                              child: const Center(
                                  child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                    Icon(Icons.broken_image,
                                        color: Colors.grey, size: 48),
                                    SizedBox(height: 12),
                                    Text('Gagal memuat gambar',
                                        style: TextStyle(color: Colors.grey)),
                                  ])),
                            )),
                  ),
                ),
              ),
              if (imageUrls.length > 1)
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.black,
                  child: Text(
                      'Gambar ${imageUrls.length} - Geser untuk melihat lainnya',
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 12)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _translateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu';
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return const Color(0xFFFF9800);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
        return Icons.access_time;
      default:
        return Icons.help_outline;
    }
  }

  void _filterData() {
    List<dynamic> filtered = _izinData;

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((item) {
        final siswaNama = (item['siswa_nama'] ?? '').toString().toLowerCase();
        final keterangan = (item['keterangan'] ?? '').toString().toLowerCase();
        final kelas =
            (item['siswa_data']?['kelas'] ?? '').toString().toLowerCase();

        return siswaNama.contains(query) ||
            keterangan.contains(query) ||
            kelas.contains(query);
      }).toList();
    }

    if (_filterStatus != 'Semua') {
      filtered = filtered
          .where((item) =>
              _filterStatus ==
              _translateStatus(item['status']?.toString() ?? ''))
          .toList();
    }

    if (_siaTabController.index == 0) {
      filtered = filtered
          .where((item) => item['jenis']?.toString().toLowerCase() == 'sakit')
          .toList();
    } else {
      filtered = filtered
          .where((item) => item['jenis']?.toString().toLowerCase() == 'izin')
          .toList();
    }

    setState(() {
      _filteredIzinData = filtered;
    });
  }

  Map<String, int> _calculateStatistics() {
    final total = _izinData.length;
    final sakit = _izinData
        .where((item) => item['jenis']?.toString().toLowerCase() == 'sakit')
        .length;
    final izin = _izinData
        .where((item) => item['jenis']?.toString().toLowerCase() == 'izin')
        .length;
    final pending = _izinData
        .where((item) => item['status']?.toString().toLowerCase() == 'pending')
        .length;

    return {'total': total, 'sakit': sakit, 'izin': izin, 'pending': pending};
  }

  Widget _buildIzinCard(dynamic data, bool isPending) {
    final status = _translateStatus(data['status']?.toString() ?? '');
    final jenis = data['jenis']?.toString() ?? '';
    final tanggal = data['tanggal']?.toString() ?? '';
    final keterangan = data['keterangan']?.toString() ?? '';
    final siswaNama = data['siswa_nama'] ??
        data['siswa_data']?['nama_lengkap'] ??
        'Siswa ${data['siswa_id']}';
    final kelas = data['siswa_data']?['kelas'] ?? '-';
    final fotoUrls =
        (data['bukti_foto_urls'] as List<dynamic>?)?.cast<String>() ?? [];
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: jenis.toLowerCase() == 'sakit'
                        ? Colors.orange.withValues(alpha: 0.1)
                        : Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    jenis.toLowerCase() == 'sakit'
                        ? Icons.healing
                        : Icons.person_pin_circle,
                    color: jenis.toLowerCase() == 'sakit'
                        ? Colors.orange
                        : Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(siswaNama,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text('Kelas: $kelas',
                          style: const TextStyle(
                              fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text('Tanggal: $tanggal',
                          style: const TextStyle(
                              fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(status,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (keterangan.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Alasan:',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(keterangan,
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black87)),
                ],
              ),
            if (fotoUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Bukti Foto:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: fotoUrls
                      .map((url) => GestureDetector(
                            onTap: () => _showImagePreview(fotoUrls),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(url,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                          width: 80,
                                          height: 80,
                                          color: Colors.grey[200],
                                          child: const Center(
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2)));
                                    },
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                                width: 80,
                                                height: 80,
                                                color: Colors.grey[200],
                                                child: const Icon(
                                                    Icons.broken_image,
                                                    color: Colors.grey))),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRejectDialog(data),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12)),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('TOLAK',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showApproveDialog(data),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12)),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('SETUJUI',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ] else if (status == 'Ditolak' &&
                data['rejection_reason'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: Colors.red.withValues(alpha: 0.1))),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Alasan Penolakan:',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.red)),
                      const SizedBox(height: 4),
                      Text(data['rejection_reason'],
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black87)),
                    ]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _siaTabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStatistics();
    final pendingData = _filteredIzinData
        .where((item) => item['status']?.toString().toLowerCase() == 'pending')
        .toList();
    final processedData = _filteredIzinData
        .where((item) => item['status']?.toString().toLowerCase() != 'pending')
        .toList();

    return RefreshIndicator(
      onRefresh: () => _fetchIzinData(),
      color: widget.primaryRed,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(children: [
          const SizedBox(height: 16),
          _filterSection(),
          const SizedBox(height: 20),
          _statisticsSection(stats),
          const SizedBox(height: 20),
          _tabSection(pendingData, processedData),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _filterSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Status Perizinan',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B1B1B))),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  ['Semua', 'Menunggu', 'Disetujui', 'Ditolak'].map((status) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _filterStatus = status;
                      });
                      _filterData();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _filterStatus == status
                            ? widget.primaryRed
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: widget.primaryRed),
                      ),
                      child: Text(status,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _filterStatus == status
                                  ? Colors.white
                                  : widget.primaryRed)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.grey[300]!, width: 1),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.search, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => _filterData(),
                    decoration: const InputDecoration.collapsed(
                        hintText: 'Cari nama siswa atau kelas...',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 13)),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      _searchController.clear();
                      _filterData();
                    },
                    icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statisticsSection(Map<String, int> stats) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem('Total', stats['total'].toString(), Icons.list_alt,
              widget.primaryRed),
          _buildStatItem(
              'Sakit', stats['sakit'].toString(), Icons.healing, Colors.orange),
          _buildStatItem('Izin', stats['izin'].toString(),
              Icons.person_pin_circle, Colors.blue),
          _buildStatItem('Menunggu', stats['pending'].toString(),
              Icons.access_time, const Color(0xFFFF9800)),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String title, String value, IconData icon, Color color) {
    return Column(children: [
      Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, size: 20, color: color)),
      const SizedBox(height: 8),
      Text(value,
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black)),
      Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    ]);
  }

  Widget _tabSection(List<dynamic> pendingData, List<dynamic> processedData) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(22),
                    topRight: Radius.circular(22)),
                border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
            child: Row(children: [
              _buildTabButton('Sakit', 0),
              const SizedBox(width: 12),
              _buildTabButton('Izin', 1)
            ]),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(minHeight: 400),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredIzinData.isEmpty
                    ? _buildEmptyState()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            if (pendingData.isNotEmpty) ...[
                              const Text('Menunggu Persetujuan',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF6B1B1B))),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFFF9800)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: const Color(0xFFFF9800)
                                            .withValues(alpha: 0.3))),
                                child: Text(
                                    '${pendingData.length} izin menunggu',
                                    style: const TextStyle(
                                        color: Color(0xFFFF9800),
                                        fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(height: 16),
                              ...pendingData
                                  .map((data) => _buildIzinCard(data, true)),
                              const SizedBox(height: 24),
                            ],
                            if (processedData.isNotEmpty) ...[
                              const Text('Sudah Diproses',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF6B1B1B))),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: Colors.green
                                            .withValues(alpha: 0.3))),
                                child: Text(
                                    '${processedData.length} izin diproses',
                                    style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(height: 16),
                              ...processedData
                                  .map((data) => _buildIzinCard(data, false)),
                            ],
                          ]),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    final isSelected = _siaTabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _siaTabController.animateTo(index);
          _filterData();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: isSelected ? widget.primaryRed : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isSelected ? widget.primaryRed : Colors.transparent)),
          child: Center(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : Colors.grey[600]))),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(
          _siaTabController.index == 0
              ? Icons.healing
              : Icons.person_pin_circle,
          size: 64,
          color: Colors.grey[300]),
      const SizedBox(height: 16),
      const Text('Tidak ada data',
          style: TextStyle(
              fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Text(
          _siaTabController.index == 0
              ? 'Belum ada pengajuan izin sakit'
              : 'Belum ada pengajuan izin biasa',
          style: const TextStyle(fontSize: 14, color: Colors.grey)),
      const SizedBox(height: 24),
    ]);
  }
}

class _SuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final bool isSuccess;
  final VoidCallback onClose;

  const _SuccessDialog(
      {required this.title,
      required this.message,
      required this.isSuccess,
      required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 10))
            ]),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: 100,
            height: 100,
            decoration: BoxDecoration(
                color: isSuccess ? Colors.green.shade50 : Colors.red.shade50,
                shape: BoxShape.circle),
            child: Icon(isSuccess ? Icons.check_circle : Icons.cancel,
                color: isSuccess ? Colors.green : Colors.red, size: 60),
          ),
          const SizedBox(height: 24),
          Text(title,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color:
                      isSuccess ? Colors.green.shade800 : Colors.red.shade800)),
          const SizedBox(height: 16),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: onClose,
            style: ElevatedButton.styleFrom(
                backgroundColor: isSuccess ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                elevation: 2),
            child: const Text('OK',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ),
        ]),
      ),
    );
  }
}

class KelolaPengajuanPklContent extends StatefulWidget {
  final Color primaryRed;
  const KelolaPengajuanPklContent({super.key, required this.primaryRed});

  @override
  State<KelolaPengajuanPklContent> createState() =>
      _KelolaPengajuanPklContentState();
}

class _KelolaPengajuanPklContentState extends State<KelolaPengajuanPklContent>
    with AutomaticKeepAliveClientMixin {
  List<dynamic> _pengajuanPklData = [];
  List<dynamic> _filteredData = [];
  String _filterStatus = 'Semua';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;

  final List<String> _statusOptions = [
    'Semua',
    'Menunggu',
    'Disetujui',
    'Ditolak'
  ];

  @override
  void initState() {
    super.initState();
    _fetchPengajuanPklData();
  }

  @override
  bool get wantKeepAlive => true;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> _fetchPengajuanPklData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _getToken();

      if (token != null) {
        final baseUrl =
            dotenv.env['API_BASE_URL'] ?? 'https://api.gedanggoreng.com';
        final response = await http.get(
          Uri.parse('$baseUrl/api/pindah-pkl/pembimbing'),
          headers: {
            'accept': 'application/json',
            'Authorization': 'Bearer $token'
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['items'] != null && data['items'] is List) {
            final List<dynamic> processedData = [];

            for (var item in data['items']) {
              // Process each item to match the expected format
              final processedItem = {
                'id': item['id'],
                'status': _translateStatus(item['status'] ?? 'pending'),
                'siswa_nama': item['siswa_nama'] ?? 'Siswa Tidak Diketahui',
                'industri_lama': item['industri_lama_nama'] ?? 'Industri Lama',
                'industri_baru': item['industri_baru_nama'] ?? 'Industri Baru',
                'tanggal_diajukan': _formatDate(item['created_at']),
                'tipe': 'Pengajuan Pindah PKL',
                'status_api':
                    item['status'], // Keep original status for API calls
              };

              processedData.add(processedItem);
            }

            setState(() {
              _pengajuanPklData = processedData;
              _filteredData = processedData;
            });
          } else {
            // Fallback jika format tidak sesuai
            _showSnackBar('Format data tidak sesuai', isError: true);
          }
        } else {
          _showSnackBar('Gagal mengambil data: ${response.statusCode}',
              isError: true);
        }
      } else {
        _showSnackBar('Token tidak ditemukan', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _decidePindahPkl(int id, String status,
      {String? catatan}) async {
    bool success = false;
    String message = '';

    try {
      final token = await _getToken();
      if (token == null) {
        _showSnackBar('Gagal: Token tidak ditemukan', isError: true);
        return;
      }

      final baseUrl =
          dotenv.env['API_BASE_URL'] ?? 'https://api.gedanggoreng.com';
      final url = '$baseUrl/api/pindah-pkl/$id/pembimbing';

      final Map<String, String> body = {
        'status': status,
        if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
      };

      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        // Hapus item yang sudah diproses dari list
        setState(() {
          _pengajuanPklData.removeWhere((item) => item['id'] == id);
          _filteredData.removeWhere((item) => item['id'] == id);
        });

        success = true;
        message = status == 'approved'
            ? 'Pengajuan pindah PKL berhasil disetujui'
            : 'Pengajuan pindah PKL berhasil ditolak';
      } else {
        throw Exception('Failed to update status: ${response.statusCode}');
      }
    } catch (e) {
      success = false;
      message = 'Gagal memperbarui status: $e';
    }

    if (success) {
      _showSuccessAnimation(
        status == 'approved' ? 'Disetujui' : 'Ditolak',
        message,
        isSuccess: status == 'approved',
      );
    } else {
      _showSnackBar(message, isError: true);
    }
  }

  String _translateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending_pembimbing':
      case 'pending':
        return 'Menunggu';
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '-';

    try {
      final date = DateTime.parse(dateString);
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      return '$day-$month-$year';
    } catch (e) {
      return '-';
    }
  }

  void _showApproveDialog(dynamic data) {
    final siswaNama = data['siswa_nama'];
    final industriLama = data['industri_lama'];
    final industriBaru = data['industri_baru'];
    final tanggal = data['tanggal_diajukan'];
    final TextEditingController catatanController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.green.shade50, Colors.white],
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 48,
                      ),
                    ),
                    Text(
                      'Setujui Pengajuan Pindah PKL',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.green.shade800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              siswaNama,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.business,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Dari: $industriLama',
                                    style:
                                        TextStyle(color: Colors.grey.shade600),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.business_outlined,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Ke: $industriBaru',
                                    style:
                                        TextStyle(color: Colors.grey.shade600),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  'Tanggal: $tanggal',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Catatan Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Catatan (Opsional)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: catatanController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText: 'Masukkan catatan jika diperlukan...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Footer dengan Buttons
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey,
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _decidePindahPkl(
                            data['id'],
                            'approved',
                            catatan: catatanController.text.trim(),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 2,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Setujui',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
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
    );
  }

  void _showRejectDialog(dynamic data) {
    final siswaNama = data['siswa_nama'];
    final industriLama = data['industri_lama'];
    final industriBaru = data['industri_baru'];
    final tanggal = data['tanggal_diajukan'];
    final TextEditingController alasanController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.red.shade50, Colors.white]),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        shape: BoxShape.circle),
                    child:
                        const Icon(Icons.cancel, color: Colors.red, size: 48),
                  ),
                  Text('Tolak Pengajuan Pindah PKL',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.red.shade800)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(siswaNama,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.business,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('Dari: $industriLama',
                                  style:
                                      TextStyle(color: Colors.grey.shade600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.business_outlined,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('Ke: $industriBaru',
                                  style:
                                      TextStyle(color: Colors.grey.shade600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text('Tanggal: $tanggal',
                                style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Alasan Penolakan',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade800)),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(
                          minHeight: 100,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: TextField(
                          controller: alasanController,
                          maxLines: 3,
                          minLines: 3,
                          decoration: const InputDecoration(
                              hintText: 'Masukkan alasan penolakan...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Minimal 10 karakter',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey,
                              side: const BorderSide(color: Colors.grey),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16)),
                          child: const Text('Batal',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final reason = alasanController.text.trim();
                            if (reason.length < 10) {
                              _showSnackBar(
                                  'Alasan penolakan minimal 10 karakter',
                                  isError: true);
                              return;
                            }
                            Navigator.pop(context);
                            _decidePindahPkl(data['id'], 'rejected',
                                catatan: reason);
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 2),
                          child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.close, size: 20),
                                SizedBox(width: 8),
                                Text('Tolak',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600)),
                              ]),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
              child: Text(message,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white))),
        ]),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessAnimation(String title, String message,
      {bool isSuccess = true}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation1, animation2) => const SizedBox(),
      transitionBuilder: (context, animation1, animation2, child) {
        return ScaleTransition(
          scale:
              CurvedAnimation(parent: animation1, curve: Curves.fastOutSlowIn),
          child: FadeTransition(
            opacity: animation1,
            child: _SuccessDialog(
                title: title,
                message: message,
                isSuccess: isSuccess,
                onClose: () => Navigator.pop(context)),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Menunggu':
        return const Color(0xFFFF9800);
      case 'Disetujui':
        return Colors.green;
      case 'Ditolak':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _filterByStatus(String status) {
    setState(() {
      _filterStatus = status;
      _filteredData = status == 'Semua'
          ? _pengajuanPklData
          : _pengajuanPklData
              .where((item) => item['status'] == status)
              .toList();
    });
  }

  void _performSearch() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredData = query.isEmpty
          ? _pengajuanPklData
          : _pengajuanPklData.where((item) {
              final siswaNama =
                  (item['siswa_nama'] ?? '').toString().toLowerCase();
              final industriLama =
                  (item['industri_lama'] ?? '').toString().toLowerCase();
              final industriBaru =
                  (item['industri_baru'] ?? '').toString().toLowerCase();

              return siswaNama.contains(query) ||
                  industriLama.contains(query) ||
                  industriBaru.contains(query);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return RefreshIndicator(
      onRefresh: () async {
        await _fetchPengajuanPklData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(children: [
          const SizedBox(height: 16),
          _filterSection(),
          const SizedBox(height: 20),
          _statisticsSection(),
          const SizedBox(height: 20),
          _documentList(),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _filterSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Status Pengajuan',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B1B1B))),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusOptions.map((status) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _filterByStatus(status),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _filterStatus == status
                            ? widget.primaryRed
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: widget.primaryRed),
                      ),
                      child: Text(status,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _filterStatus == status
                                  ? Colors.white
                                  : widget.primaryRed)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.grey[300]!, width: 1),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.search, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => _performSearch(),
                    decoration: const InputDecoration.collapsed(
                        hintText: 'Cari nama siswa atau industri...',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 13)),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      _searchController.clear();
                      _performSearch();
                    },
                    icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statisticsSection() {
    final menungguCount =
        _pengajuanPklData.where((item) => item['status'] == 'Menunggu').length;
    final disetujuiCount =
        _pengajuanPklData.where((item) => item['status'] == 'Disetujui').length;
    final ditolakCount =
        _pengajuanPklData.where((item) => item['status'] == 'Ditolak').length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem('Total', _pengajuanPklData.length.toString(),
              Icons.list_alt, widget.primaryRed),
          _buildStatItem('Menunggu', menungguCount.toString(),
              Icons.access_time, const Color(0xFFFF9800)),
          _buildStatItem('Disetujui', disetujuiCount.toString(),
              Icons.check_circle, Colors.green),
          _buildStatItem(
              'Ditolak', ditolakCount.toString(), Icons.cancel, Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String title, String value, IconData icon, Color color) {
    return Column(children: [
      Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, size: 20, color: color)),
      const SizedBox(height: 8),
      Text(value,
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black)),
      Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    ]);
  }

  Widget _documentList() {
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.grey[200]!)),
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
            border: Border.all(color: Colors.grey[200]!)),
        child: Column(children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Tidak ada data pengajuan',
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
              _filterStatus == 'Semua'
                  ? 'Belum ada pengajuan pindah PKL dari siswa'
                  : 'Tidak ada pengajuan dengan status "$_filterStatus"',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ]),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Daftar Pengajuan Pindah PKL',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B1B1B))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: widget.primaryRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: widget.primaryRed.withValues(alpha: 0.2))),
            child: Text('${_filteredData.length} pengajuan',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.primaryRed)),
          ),
        ]),
        const SizedBox(height: 16),
        ..._filteredData.map((data) => _buildDocumentCard(data)),
      ]),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> data) {
    final statusColor = _getStatusColor(data['status']);
    final isPending = data['status'] == 'Menunggu';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showDetailDialog(data),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                      color: widget.primaryRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: widget.primaryRed.withValues(alpha: 0.3))),
                  child: const Icon(Icons.swap_horiz,
                      color: Color(0xFF6B1B1B), size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['siswa_nama'],
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.business,
                                size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(data['industri_lama'],
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.grey[700]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.arrow_forward,
                                size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(data['industri_baru'],
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.grey[700]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ]),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: statusColor.withValues(alpha: 0.3))),
                  child: Text(data['status'],
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text('Diajukan: ${data['tanggal_diajukan']}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ]),
              const SizedBox(height: 16),
              if (isPending)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showRejectDialog(data),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12)),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('TOLAK',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showApproveDialog(data),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12)),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('SETUJUI',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                )
              else
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: () => _showDetailDialog(data),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: widget.primaryRed,
                        side: BorderSide(color: widget.primaryRed),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10)),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('LIHAT DETAIL',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  void _showDetailDialog(Map<String, dynamic> data) {
    final isPending = data['status'] == 'Menunggu';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.85,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Detail Pengajuan Pindah PKL',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B1B1B))),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 28)),
            ]),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.grey[300]!)),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                        color: widget.primaryRed
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: const Icon(Icons.person,
                                        color: Color(0xFF6B1B1B), size: 24)),
                                const SizedBox(width: 16),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(data['siswa_nama'],
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis),
                                    ])),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                      color: _getStatusColor(data['status'])
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: _getStatusColor(data['status'])
                                              .withValues(alpha: 0.3))),
                                  child: Text(data['status'],
                                      style: TextStyle(
                                          color:
                                              _getStatusColor(data['status']),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12)),
                                ),
                              ]),
                            ]),
                      ),
                      const SizedBox(height: 24),
                      const Text('Informasi Pindah PKL',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[300]!)),
                        child: Column(children: [
                          _infoRow('Industri Asal', data['industri_lama']),
                          const SizedBox(height: 12),
                          _infoRow('Industri Tujuan', data['industri_baru']),
                          const SizedBox(height: 12),
                          _infoRow(
                              'Tanggal Diajukan', data['tanggal_diajukan']),
                          const SizedBox(height: 12),
                          _infoRow('Status', data['status']),
                        ]),
                      ),
                      const SizedBox(height: 24),
                    ]),
              ),
            ),
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectDialog(data),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    icon: const Icon(Icons.close, size: 20),
                    label: const Text('TOLAK',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showApproveDialog(data),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    icon: const Icon(Icons.check, size: 20),
                    label: const Text('SETUJUI',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ),
              ]),
            ],
          ]),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
          width: 120,
          child: Text('$label:',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666)))),
      const SizedBox(width: 8),
      Expanded(
          child: Text(value,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
    ]);
  }
}
