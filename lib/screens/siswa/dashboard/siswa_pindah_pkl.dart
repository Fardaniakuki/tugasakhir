import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RekapTheme {
  static const Color primaryRed = Color(0xFF9f0712);
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color textDark = Color(0xFF2D3748);
  static const Color textGrey = Color(0xFF718096);
  static const Color border = Color(0xFFE2E8F0);
  static const Color green = Color(0xFF38A169);
  static const Color orange = Color(0xFFDD6B20);
  static const Color red = Color(0xFFE53E3E);
  static const Color blue = Color(0xFF3182CE);
  
  // ignore: always_declare_return_types
  static get purple => null;
}

class PindahPKLPage extends StatefulWidget {
  const PindahPKLPage({super.key, required Color primaryColor, required Future<void> Function() onAjukanPindahPressed});
  
  @override
  State<PindahPKLPage> createState() => _PindahPKLPageState();
}

class _PindahPKLPageState extends State<PindahPKLPage> {
  List<dynamic> _pengajuanData = [];
  bool _isLoading = true;
  String _filterStatus = 'Semua';
  final List<String> _statusOptions = ['Semua', 'Menunggu', 'Disetujui', 'Ditolak'];
  
  @override
  void initState() {
    super.initState();
    _loadPengajuanData();
  }

  Future<void> _loadPengajuanData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      if (token == null) return;
      
      await dotenv.load();
      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://api.gedanggoreng.com';
      
      // Cek apakah ada pengajuan aktif
      final activeResponse = await http.get(
        Uri.parse('$baseUrl/api/pindah-pkl/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      // Load history
      final historyResponse = await http.get(
        Uri.parse('$baseUrl/api/pindah-pkl/history'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      final List<dynamic> allData = [];
      
      // Tambahkan pengajuan aktif jika ada
      if (activeResponse.statusCode == 200) {
        final activeData = jsonDecode(activeResponse.body);
        if (activeData != null) {
          allData.add(activeData);
        }
      }
      
      // Tambahkan history
      if (historyResponse.statusCode == 200) {
        final historyData = jsonDecode(historyResponse.body);
        if (historyData is List) {
          allData.addAll(historyData);
        }
      }
      
      setState(() {
        _pengajuanData = allData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _filterStatus = 'Semua';
    });
    await _loadPengajuanData();
  }

  Widget _buildStatusBadge(String status) {
    Color color = RekapTheme.orange;
    String statusDisplay = 'Menunggu';
    final statusLower = status.toLowerCase();
    
    if (statusLower.contains('approved') || statusLower.contains('disetujui')) {
      color = RekapTheme.green;
      statusDisplay = 'Disetujui';
    } else if (statusLower.contains('rejected') || statusLower.contains('ditolak')) {
      color = RekapTheme.red;
      statusDisplay = 'Ditolak';
    } else if (statusLower.contains('pending_pembimbing')) {
      color = RekapTheme.orange;
      statusDisplay = 'Menunggu Pembimbing';
    } else if (statusLower.contains('pending_kaprog')) {
      color = RekapTheme.orange;
      statusDisplay = 'Menunggu Kaprog';
    } else if (statusLower.contains('pending_koordinator')) {
      color = RekapTheme.orange;
      statusDisplay = 'Menunggu Koordinator';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha:0.2)),
      ),
      child: Text(
        statusDisplay,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return '-';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${dateTime.day} ${bulan[dateTime.month - 1]} ${dateTime.year}';
    } catch (e) {
      return dateTimeString;
    }
  }

  Widget _buildPengajuanCard(Map<String, dynamic> data) {
    final status = data['status']?.toString() ?? 'pending';
    final industriLama = data['industri_lama']?['nama']?.toString() ?? '-';
    final industriBaru = data['industri_baru']?['nama']?.toString() ?? '-';
    final alasan = data['alasan']?.toString() ?? '-';
    final createdAt = data['created_at']?.toString();
    final catatanPembimbing = data['pembimbing_catatan']?.toString();
    final catatanKaprog = data['kaprog_catatan']?.toString();
    final catatanKoordinator = data['koordinator_catatan']?.toString();
    final buktiPendukung = data['bukti_pendukung'] as List<dynamic>? ?? [];

    return GestureDetector(
      onTap: () => _showDetailPengajuan(data),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: RekapTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: RekapTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: RekapTheme.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.swap_horiz_outlined,
                        size: 14,
                        color: RekapTheme.textDark,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Pindah PKL',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: RekapTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: 12),
            
            // Industri Lama
            Text(
              'Dari: $industriLama',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: RekapTheme.textDark,
              ),
            ),
            
            // Industri Baru
            Text(
              'Ke: $industriBaru',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: RekapTheme.textDark,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Alasan
            Text(
              'Alasan: $alasan',
              style: const TextStyle(
                color: RekapTheme.textGrey,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            if (buktiPendukung.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.image, size: 12, color: RekapTheme.blue),
                  const SizedBox(width: 4),
                  Text(
                    '${buktiPendukung.length} file terlampir',
                    style: const TextStyle(
                      color: RekapTheme.blue,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            
            // Catatan jika ada
            if (catatanPembimbing != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: RekapTheme.orange),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Catatan Pembimbing: $catatanPembimbing',
                      style: const TextStyle(
                        color: RekapTheme.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            
            if (catatanKaprog != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: RekapTheme.orange),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Catatan Kaprog: $catatanKaprog',
                      style: const TextStyle(
                        color: RekapTheme.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            
            if (catatanKoordinator != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: RekapTheme.orange),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Catatan Koordinator: $catatanKoordinator',
                      style: const TextStyle(
                        color: RekapTheme.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 8),
            
            // Waktu
            Text(
              'Diajukan: ${_formatDateTime(createdAt)}',
              style: const TextStyle(
                color: RekapTheme.textGrey,
                fontSize: 11,
              ),
            ),
            
            const SizedBox(height: 8),
            
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Klik untuk detail →',
                  style: TextStyle(
                    color: RekapTheme.primaryRed,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailPengajuan(Map<String, dynamic> data) {
    final status = data['status']?.toString() ?? 'pending';
    final industriLama = data['industri_lama']?['nama']?.toString() ?? '-';
    final industriBaru = data['industri_baru']?['nama']?.toString() ?? '-';
    final alasan = data['alasan']?.toString() ?? '-';
    final createdAt = data['created_at']?.toString();
    final updatedAt = data['updated_at']?.toString();
    final catatanPembimbing = data['pembimbing_catatan']?.toString();
    final catatanKaprog = data['kaprog_catatan']?.toString();
    final catatanKoordinator = data['koordinator_catatan']?.toString();
    final buktiPendukung = data['bukti_pendukung'] as List<dynamic>? ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 60,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Detail Pengajuan',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: RekapTheme.textDark,
                            ),
                          ),
                          _buildStatusBadge(status),
                        ],
                      ),
                      const SizedBox(height: 30),
                      
                      // Informasi Pengajuan
                      _buildDetailSection(
                        'Informasi Pengajuan',
                        Icons.info_outline,
                        [
                          _buildDetailItem('Industri Asal', industriLama),
                          _buildDetailItem('Industri Tujuan', industriBaru),
                          _buildDetailItem('Tanggal Pengajuan', _formatDateTimeDetail(createdAt)),
                          if (updatedAt != null) 
                            _buildDetailItem('Terakhir Diupdate', _formatDateTimeDetail(updatedAt)),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Alasan
                      _buildDetailSection(
                        'Alasan Pindah',
                        Icons.description,
                        [
                          _buildDetailItem('Alasan', alasan),
                        ],
                      ),
                      
                      // Catatan jika ada
                      if (catatanPembimbing != null) ...[
                        const SizedBox(height: 24),
                        _buildDetailSection(
                          'Catatan Pembimbing',
                          Icons.notes,
                          [
                            _buildDetailItem('Catatan', catatanPembimbing),
                          ],
                          backgroundColor: RekapTheme.blue.withValues(alpha:0.05),
                          borderColor: RekapTheme.blue.withValues(alpha:0.2),
                        ),
                      ],
                      
                      if (catatanKaprog != null) ...[
                        const SizedBox(height: 24),
                        _buildDetailSection(
                          'Catatan Kaprog',
                          Icons.notes,
                          [
                            _buildDetailItem('Catatan', catatanKaprog),
                          ],
                          backgroundColor: RekapTheme.orange.withValues(alpha: 0.05),
                          borderColor: RekapTheme.orange.withValues(alpha:0.2),
                        ),
                      ],
                      
                      if (catatanKoordinator != null) ...[
                        const SizedBox(height: 24),
                        _buildDetailSection(
                          'Catatan Koordinator',
                          Icons.notes,
                          [
                            _buildDetailItem('Catatan', catatanKoordinator),
                          ],
                          backgroundColor: RekapTheme.purple.withValues(alpha:0.05),
                          borderColor: RekapTheme.purple.withValues(alpha:0.2),
                        ),
                      ],
                      
                      // Bukti Pendukung
                      if (buktiPendukung.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildDetailSection(
                          'Bukti Pendukung',
                          Icons.photo_library,
                          [
                            const SizedBox(height: 12),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 1,
                              ),
                              itemCount: buktiPendukung.length,
                              itemBuilder: (context, index) {
                                final imageUrl = buktiPendukung[index]?.toString() ?? '';
                                return _buildImageThumbnail(imageUrl, index, buktiPendukung.cast<String>());
                              },
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Klik gambar untuk melihat lebih besar',
                              style: TextStyle(
                                color: RekapTheme.textGrey,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ],
                      
                      const SizedBox(height: 32),
                      
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: RekapTheme.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: RekapTheme.border),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: RekapTheme.blue, size: 24),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Informasi',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: RekapTheme.textDark,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Silakan hubungi guru pembimbing jika ada pertanyaan terkait pengajuan ini.',
                                    style: TextStyle(
                                      color: RekapTheme.textGrey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RekapTheme.primaryRed,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Tutup Detail',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildImageThumbnail(String imageUrl, int index, List<String> buktiFotoUrls) {
    return GestureDetector(
      onTap: () => _showImagePreview(index, buktiFotoUrls),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[100],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              if (imageUrl.isNotEmpty)
                Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        color: RekapTheme.primaryRed,
                        strokeWidth: 2,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(Icons.broken_image, color: Colors.grey[400]),
                    );
                  },
                )
              else
                Center(
                  child: Icon(Icons.broken_image, color: Colors.grey[400]),
                ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.black.withValues(alpha:0.1),
                      width: 1,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha:0.6),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.zoom_in,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImagePreview(int index, List<String> imageUrls) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha:0.9),
      builder: (context) => ImagePreviewDialog(
        imageUrls: imageUrls,
        initialIndex: index,
      ),
    );
  }

  Widget _buildDetailSection(String title, IconData icon, List<Widget> children,
      {Color? backgroundColor, Color? borderColor}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? RekapTheme.border.withValues(alpha:0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: RekapTheme.primaryRed.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: RekapTheme.primaryRed, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: RekapTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: RekapTheme.textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              color: RekapTheme.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTimeDetail(String? dateTimeString) {
    if (dateTimeString == null) return '-';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
      final bulan = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
      return '${hari[dateTime.weekday - 1]}, ${dateTime.day} ${bulan[dateTime.month - 1]} ${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} WIB';
    } catch (e) {
      return dateTimeString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = _pengajuanData.where((item) {
      if (_filterStatus == 'Semua') return true;
      final status = item['status']?.toString() ?? '';
      final statusLower = status.toLowerCase();
      
      if (_filterStatus == 'Disetujui') {
        return statusLower.contains('approved') || statusLower.contains('disetujui');
      } else if (_filterStatus == 'Menunggu') {
        return statusLower.contains('pending');
      } else if (_filterStatus == 'Ditolak') {
        return statusLower.contains('rejected') || statusLower.contains('ditolak');
      }
      return true;
    }).toList();

    final totalMenunggu = _pengajuanData.where((e) {
      final status = e['status']?.toString().toLowerCase() ?? '';
      return status.contains('pending');
    }).length;

    return Scaffold(
      backgroundColor: RekapTheme.background,
      appBar: AppBar(
        backgroundColor: RekapTheme.surface,
        elevation: 0,
        title: const Text(
          'Pengajuan Pindah PKL',
          style: TextStyle(
            color: RekapTheme.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: RekapTheme.primaryRed,
        backgroundColor: RekapTheme.surface,
        strokeWidth: 2.5,
        triggerMode: RefreshIndicatorTriggerMode.anywhere,
        displacement: 40,
        edgeOffset: 0,
        child: _isLoading
            ? _buildLoading()
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            'Pengajuan',
                            _pengajuanData.length.toString(),
                            Icons.swap_horiz_outlined,
                            RekapTheme.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            'Menunggu',
                            totalMenunggu.toString(),
                            Icons.access_time_outlined,
                            RekapTheme.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _statusOptions.map((status) => _buildFilterChip(status)).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Daftar Pengajuan
                    if (filteredData.isEmpty)
                      _buildEmptyState()
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredData.length,
                        separatorBuilder: (ctx, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _buildPengajuanCard(filteredData[index]),
                      ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLoading() => const Center(
        child: CircularProgressIndicator(color: RekapTheme.primaryRed),
      );

  Widget _buildEmptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            children: [
              Icon(Icons.filter_list_off, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'Belum mengajukan pindah PKL',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Geser dari atas untuk refresh',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
              
            ],
          ),
        ),
      );

  Widget _buildFilterChip(String status) {
    final bool isSelected = _filterStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          setState(() => _filterStatus = status);
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? RekapTheme.primaryRed : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? RekapTheme.primaryRed : RekapTheme.border,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: RekapTheme.primaryRed.withValues(alpha:0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            status,
            style: TextStyle(
              color: isSelected ? Colors.white : RekapTheme.textGrey,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RekapTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: RekapTheme.textDark,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: RekapTheme.textGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}

class ImagePreviewDialog extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const ImagePreviewDialog({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<ImagePreviewDialog> createState() => _ImagePreviewDialogState();
}

class _ImagePreviewDialogState extends State<ImagePreviewDialog> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              final imageUrl = widget.imageUrls[index];
              return GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  color: Colors.black,
                  child: Center(
                    child: InteractiveViewer(
                      panEnabled: true,
                      minScale: 0.5,
                      maxScale: 3,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, size: 60, color: Colors.white),
                                SizedBox(height: 16),
                                Text(
                                  'Gagal memuat gambar',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 40,
            right: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha:0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 24),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: GestureDetector(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fitur download akan segera tersedia'),
                  backgroundColor: Colors.green,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha:0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.download, color: Colors.white, size: 24),
              ),
            ),
          ),
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.imageUrls.length,
                  (index) => GestureDetector(
                    onTap: () => _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                    child: Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentIndex == index
                            ? Colors.white
                            : Colors.white.withValues(alpha:0.5),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha:0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.imageUrls.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}