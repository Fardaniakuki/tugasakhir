// laporan_siswa_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LaporanSiswaScreen extends StatefulWidget {
  final int kelasId;
  final String namaKelas;

  const LaporanSiswaScreen({
    super.key,
    required this.kelasId,
    required this.namaKelas,
  });

  @override
  State<LaporanSiswaScreen> createState() => _LaporanSiswaScreenState();
}

class _LaporanSiswaScreenState extends State<LaporanSiswaScreen> {
  List<dynamic> _siswaList = [];
  bool _isLoading = true;
  String _searchQuery = '';
  
  // Neo Brutalism Colors
  final Color _primaryColor = const Color(0xFFE71543);
  final Color _secondaryColor = const Color(0xFFE6E3E3);
  final Color _accentColor = const Color(0xFFA8DADC);
  final Color _darkColor = const Color(0xFF1D3557);
  final Color _yellowColor = const Color(0xFFFFB703);
  final Color _blackColor = Colors.black;
  
  static const BoxShadow _heavyShadow = BoxShadow(
    color: Colors.black,
    offset: Offset(6, 6),
    blurRadius: 0,
  );
  

  @override
  void initState() {
    super.initState();
    _loadSiswaData();
  }

  Future<void> _loadSiswaData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/siswa?kelas_id=${widget.kelasId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _siswaList = data['data']['data'] ?? [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading siswa data: $e');
      setState(() => _isLoading = false);
    }
  }

  List<dynamic> _getFilteredSiswa() {
    if (_searchQuery.isEmpty) return _siswaList;
    
    return _siswaList.where((siswa) {
      final nama = siswa['nama_lengkap']?.toString().toLowerCase() ?? '';
      final nis = siswa['nis']?.toString().toLowerCase() ?? '';
      return nama.contains(_searchQuery.toLowerCase()) ||
             nis.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredSiswa = _getFilteredSiswa();

    return Scaffold(
      backgroundColor: _darkColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _primaryColor,
                border: Border.all(color: _blackColor, width: 3),
                boxShadow: const [_heavyShadow],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _yellowColor,
                        border: Border.all(color: _blackColor, width: 3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'LAPORAN SISWA',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kelas ${widget.namaKelas}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
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
                      color: _secondaryColor,
                      border: Border.all(color: _blackColor, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_siswaList.length} SISWA',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _blackColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _secondaryColor,
                border: Border.all(color: _blackColor, width: 3),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [_heavyShadow],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: _darkColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                      decoration: InputDecoration(
                        hintText: 'Cari siswa berdasarkan nama atau NIS...',
                        hintStyle: TextStyle(
                          color: _darkColor.withValues(alpha: 0.6),
                        ),
                        border: InputBorder.none,
                      ),
                      style: TextStyle(
                        color: _blackColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Container utama
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 24),
                decoration: BoxDecoration(
                  color: _secondaryColor,
                  border: Border.all(color: _blackColor, width: 4),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                  boxShadow: const [_heavyShadow],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _isLoading
                      ? _buildLoadingSkeleton()
                      : filteredSiswa.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: filteredSiswa.length,
                              itemBuilder: (context, index) {
                                final siswa = filteredSiswa[index];
                                return _buildSiswaCard(siswa);
                              },
                            ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSiswaCard(Map<String, dynamic> siswa) {
    final pklStatus = siswa['pkl_status']?.toString().toLowerCase() ?? 'none';
    final statusColor = _getPKLStatusColor(pklStatus);
    final statusText = _getPKLStatusText(pklStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _secondaryColor,
        border: Border.all(color: _blackColor, width: 4),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [_heavyShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header dengan status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor,
              border: Border(
                bottom: BorderSide(color: _blackColor, width: 4),
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _blackColor, width: 3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    color: _primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Nama dan NIS
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        siswa['nama_lengkap'] ?? 'Nama Tidak Tersedia',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'NIS: ${siswa['nis'] ?? '-'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _blackColor, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Detail informasi
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info dasar
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _accentColor,
                    border: Border.all(color: _blackColor, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildInfoItem(
                        icon: Icons.call,
                        label: 'Telepon',
                        value: siswa['nomor_telepon'] ?? '-',
                        color: _primaryColor,
                      ),
                      Container(
                        width: 2,
                        height: 40,
                        color: _blackColor,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      _buildInfoItem(
                        icon: Icons.email,
                        label: 'Email',
                        value: siswa['email'] ?? '-',
                        color: const Color(0xFF06D6A0),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Alamat
                if (siswa['alamat'] != null && siswa['alamat'].isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: _blackColor, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB703),
                            border: Border.all(color: _blackColor, width: 2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on,
                            size: 18,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ALAMAT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: _darkColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                siswa['alamat'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _blackColor,
                                  fontWeight: FontWeight.w600,
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
                
                const SizedBox(height: 16),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: _primaryColor,
                          border: Border.all(color: _blackColor, width: 3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextButton(
                          onPressed: () {
                            _showSiswaDetail(siswa);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          child: const Text(
                            'LIHAT DETAIL',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _yellowColor,
                        border: Border.all(color: _blackColor, width: 3),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () {
                          _showQuickActions(siswa);
                        },
                        icon: Icon(
                          Icons.more_vert,
                          color: _blackColor,
                          size: 24,
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
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: _darkColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: _blackColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getPKLStatusColor(String status) {
    switch (status) {
      case 'approved':
      case 'disetujui':
        return const Color(0xFF06D6A0);
      case 'rejected':
      case 'ditolak':
        return const Color(0xFFE63946);
      case 'pending':
      case 'menunggu':
        return const Color(0xFFFFB703);
      default:
        return _primaryColor;
    }
  }

  String _getPKLStatusText(String status) {
    switch (status) {
      case 'approved':
      case 'disetujui':
        return 'PKL AKTIF';
      case 'rejected':
      case 'ditolak':
        return 'DITOLAK';
      case 'pending':
      case 'menunggu':
        return 'MENUNGGU';
      default:
        return 'BELUM PKL';
    }
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _secondaryColor,
            border: Border.all(color: _blackColor, width: 3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 200,
                height: 24,
                color: _blackColor.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 16,
                color: _blackColor.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 8),
              Container(
                width: 150,
                height: 16,
                color: _blackColor.withValues(alpha: 0.2),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _primaryColor,
                border: Border.all(color: _blackColor, width: 4),
                shape: BoxShape.circle,
                boxShadow: const [_heavyShadow],
              ),
              child: Icon(
                Icons.people_outline,
                size: 50,
                color: _secondaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'TIDAK ADA DATA SISWA',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: _blackColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Tidak ditemukan siswa pada kelas ini',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: _darkColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSiswaDetail(Map<String, dynamic> siswa) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _secondaryColor,
            border: Border.all(color: _blackColor, width: 4),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [_heavyShadow],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _primaryColor,
                  border: Border.all(color: _blackColor, width: 3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: _secondaryColor,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'DETAIL SISWA',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _blackColor,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 20),
              // Tambahkan detail siswa di sini
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _primaryColor,
                  border: Border.all(color: _blackColor, width: 3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: const Text(
                    'TUTUP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickActions(Map<String, dynamic> siswa) {
    // Implement quick actions
  }
}