// progress_siswa_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressSiswaScreen extends StatefulWidget {
  final int kelasId;
  final String namaKelas;

  const ProgressSiswaScreen({
    super.key,
    required this.kelasId,
    required this.namaKelas,
  });

  @override
  State<ProgressSiswaScreen> createState() => _ProgressSiswaScreenState();
}

class _ProgressSiswaScreenState extends State<ProgressSiswaScreen> {
  List<dynamic> _pklProgressList = [];
  bool _isLoading = true;
  String _selectedFilter = 'semua';
  
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
    _loadPKLProgress();
  }

  Future<void> _loadPKLProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/pkl/progress/kelas/${widget.kelasId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _pklProgressList = data['data'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading PKL progress: $e');
      setState(() => _isLoading = false);
    }
  }

  List<dynamic> _getFilteredProgress() {
    if (_selectedFilter == 'semua') return _pklProgressList;
    
    return _pklProgressList.where((progress) {
      final status = progress['status']?.toString().toLowerCase() ?? '';
      return status == _selectedFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredProgress = _getFilteredProgress();

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
                          'PROGRESS SISWA',
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
                      '${_pklProgressList.length} DATA',
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

            // Filter chips
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _secondaryColor,
                border: Border.all(color: _blackColor, width: 3),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [_heavyShadow],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('SEMUA', 'semua'),
                    const SizedBox(width: 8),
                    _buildFilterChip('PKL AKTIF', 'approved'),
                    const SizedBox(width: 8),
                    _buildFilterChip('MENUNGGU', 'pending'),
                    const SizedBox(width: 8),
                    _buildFilterChip('DITOLAK', 'rejected'),
                    const SizedBox(width: 8),
                    _buildFilterChip('SELESAI', 'completed'),
                  ],
                ),
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
                      : filteredProgress.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: filteredProgress.length,
                              itemBuilder: (context, index) {
                                final progress = filteredProgress[index];
                                return _buildProgressCard(progress);
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

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor : _secondaryColor,
          border: Border.all(
            color: _blackColor,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : _blackColor,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(Map<String, dynamic> progress) {
    final status = progress['status']?.toString().toLowerCase() ?? '';
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);
    final progressPercent = progress['progress_percent'] ?? 0;
    
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
          // Header
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        progress['siswa_nama'] ?? 'Nama Siswa',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        progress['industri_nama'] ?? 'Industri',
                        style: TextStyle(
                          fontSize: 12,
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
          
          // Progress bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PROGRESS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _darkColor,
                      ),
                    ),
                    Text(
                      '$progressPercent%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: _blackColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: _secondaryColor,
                    border: Border.all(color: _blackColor, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Stack(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * (progressPercent / 100),
                        height: 16,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Informasi tambahan
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _accentColor,
                    border: Border.all(color: _blackColor, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildProgressInfo(
                        icon: Icons.calendar_today,
                        label: 'Mulai',
                        value: _formatDate(progress['tanggal_mulai']),
                      ),
                      Container(
                        width: 2,
                        height: 40,
                        color: _blackColor,
                      ),
                      _buildProgressInfo(
                        icon: Icons.calendar_today,
                        label: 'Selesai',
                        value: _formatDate(progress['tanggal_selesai']),
                      ),
                      Container(
                        width: 2,
                        height: 40,
                        color: _blackColor,
                      ),
                      _buildProgressInfo(
                        icon: Icons.person,
                        label: 'Pembimbing',
                        value: progress['pembimbing_nama'] ?? '-',
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
                            _showDetailProgress(progress);
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
                          // Implement action
                        },
                        icon: Icon(
                          Icons.assessment,
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

  Widget _buildProgressInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            size: 16,
            color: _darkColor,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: _darkColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: _blackColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
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
      case 'completed':
      case 'selesai':
        return const Color(0xFFA8DADC);
      default:
        return _primaryColor;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'approved':
      case 'disetujui':
        return 'AKTIF';
      case 'rejected':
      case 'ditolak':
        return 'DITOLAK';
      case 'pending':
      case 'menunggu':
        return 'MENUNGGU';
      case 'completed':
      case 'selesai':
        return 'SELESAI';
      default:
        return 'TIDAK ADA';
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}';
    } catch (e) {
      return '-';
    }
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      itemCount: 3,
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
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 12,
                color: _blackColor.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 8),
              Container(
                width: 150,
                height: 12,
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
                Icons.trending_up,
                size: 50,
                color: _secondaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'BELUM ADA DATA PROGRESS',
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
                'Siswa di kelas ini belum memiliki data progress PKL',
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

  void _showDetailProgress(Map<String, dynamic> progress) {
    // Implement detail view
  }
}