// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tes_flutter/screens/login/login_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
}

class SiswaRekap extends StatefulWidget {
  const SiswaRekap(
      {super.key,
      required void Function() onQuickActionPressed,
      required Future<void> Function() onAjukanIjin});
  @override
  State<SiswaRekap> createState() => _SiswaRekapState();
}

class _SiswaRekapState extends State<SiswaRekap>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: RekapTheme.background,
      appBar: AppBar(
        backgroundColor: RekapTheme.surface,
        elevation: 0,
        title: const Text('Perizinan',
            style: TextStyle(
                color: RekapTheme.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 20)),
        centerTitle: false,
      ),
      body: const SiswaSiaContent(),
    );
  }
}

class SiswaSiaContent extends StatefulWidget {
  const SiswaSiaContent({super.key});
  @override
  State<SiswaSiaContent> createState() => _SiswaSiaContentState();
}

class _SiswaSiaContentState extends State<SiswaSiaContent> {
  List<dynamic> _siaData = [];
  bool _isLoading = true;
  String _filterStatus = 'Semua';
  final List<String> _statusOptions = [
    'Semua',
    'Disetujui',
    'Menunggu',
    'Ditolak'
  ];

  @override
  void initState() {
    super.initState();
    _loadIzinData();
  }

  Future<void> _loadIzinData({String? status}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      await dotenv.load();
      final baseUrl =
          dotenv.env['API_BASE_URL'] ?? 'https://api.gedanggoreng.com';
      String url = '$baseUrl/api/izin/me';
      if (status != null && status != 'Semua') {
        final statusMap = {
          'Disetujui': 'approved',
          'Menunggu': 'pending',
          'Ditolak': 'rejected'
        };
        final apiStatus = statusMap[status];
        if (apiStatus != null) url = '$url?status=$apiStatus';
      }
      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      });
      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);
        List<dynamic> izinList = [];
        if (responseData is List) {
          izinList = responseData;
        } else if (responseData is Map && responseData.containsKey('data')) {
          if (responseData['data'] is List) izinList = responseData['data'];
        }
        setState(() {
          _siaData = izinList;
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        _redirectToLogin();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    // Reset filter ke Semua saat refresh
    setState(() {
      _filterStatus = 'Semua';
    });
    await _loadIzinData();
  }

  void _redirectToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false);
      }
    });
  }

  void _showDetailIzin(Map<String, dynamic> izinData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25), topRight: Radius.circular(25))),
      builder: (BuildContext context) {
        return DetailIzinScreen(izinData: izinData);
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = RekapTheme.orange;
    String statusDisplay = 'Menunggu';
    final statusLower = status.toLowerCase();
    if (statusLower.contains('disetujui') || statusLower.contains('approved')) {
      color = RekapTheme.green;
      statusDisplay = 'Disetujui';
    } else if (statusLower.contains('ditolak') ||
        statusLower.contains('rejected')) {
      color = RekapTheme.red;
      statusDisplay = 'Ditolak';
      // ignore: duplicate_ignore
      // ignore: curly_braces_in_flow_control_structures
    } else if (statusLower.contains('pending')) statusDisplay = 'Menunggu';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Text(statusDisplay,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  String _formatTanggal(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      final bulan = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember'
      ];
      return '${date.day} ${bulan[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return '-';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final bulan = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des'
      ];
      return '${dateTime.day} ${bulan[dateTime.month - 1]} ${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = _siaData.where((item) {
      if (_filterStatus == 'Semua') return true;
      final status = item['status']?.toString() ?? '';
      final statusLower = status.toLowerCase();
      if (_filterStatus == 'Disetujui') {
        return statusLower.contains('disetujui') ||
            statusLower.contains('approved');
      } else if (_filterStatus == 'Menunggu')
        return statusLower.contains('menunggu') ||
            statusLower.contains('pending');
      else if (_filterStatus == 'Ditolak')
        return statusLower.contains('ditolak') ||
            statusLower.contains('rejected');
      return true;
    }).toList();
    final totalDisetujui = _siaData.where((e) {
      final status = e['status']?.toString().toLowerCase() ?? '';
      return status.contains('disetujui') || status.contains('approved');
    }).length;

    return RefreshIndicator(
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
                  Row(children: [
                    Expanded(
                        child: _buildSummaryCard(
                            'Total Izin',
                            _siaData.length.toString(),
                            Icons.folder_copy_outlined,
                            RekapTheme.blue)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildSummaryCard(
                            'Disetujui',
                            totalDisetujui.toString(),
                            Icons.check_circle_outlined,
                            RekapTheme.green)),
                  ]),
                  const SizedBox(height: 24),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _statusOptions
                          .map((status) => _buildFilterChip(status))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (filteredData.isEmpty)
                    _buildEmptyState()
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredData.length,
                      separatorBuilder: (ctx, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) =>
                          _buildSiaCard(filteredData[index]),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildLoading() => const Center(
      child: CircularProgressIndicator(color: RekapTheme.primaryRed));

  Widget _buildEmptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            children: [
              Icon(Icons.filter_list_off, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'Tidak ada data ditemukan',
                style: TextStyle(
                    color: Colors.grey[500], fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                'Geser dari atas untuk refresh',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
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
          _loadIzinData(status: status == 'Semua' ? null : status);
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? RekapTheme.primaryRed : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isSelected ? RekapTheme.primaryRed : RekapTheme.border),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: RekapTheme.primaryRed.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ]
                : [],
          ),
          child: Text(status,
              style: TextStyle(
                  color: isSelected ? Colors.white : RekapTheme.textGrey,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RekapTheme.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: RekapTheme.textDark)),
          Text(title,
              style: const TextStyle(fontSize: 12, color: RekapTheme.textGrey)),
        ]),
      ]),
    );
  }

  Widget _buildSiaCard(Map<String, dynamic> data) {
    final status = data['status']?.toString() ?? 'Pending';
    final jenis = data['jenis']?.toString() ?? 'Izin';
    final keterangan = data['keterangan']?.toString() ?? '-';
    final tanggal = data['tanggal']?.toString();
    final createdAt = data['created_at']?.toString();
    final decidedAt = data['decided_at']?.toString();
    final rejectionReason = data['rejection_reason']?.toString();
    final buktiFotoUrls = data['bukti_foto_urls'] is List
        ? data['bukti_foto_urls'] as List<dynamic>
        : [];
    final isPending = status.toLowerCase().contains('menunggu') ||
        status.toLowerCase().contains('pending');
    final isDitolak = status.toLowerCase().contains('ditolak') ||
        status.toLowerCase().contains('rejected');

    return GestureDetector(
      onTap: () => _showDetailIzin(data),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: RekapTheme.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: RekapTheme.background,
                  borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Icon(
                  jenis.toLowerCase().contains('sakit')
                      ? Icons.medical_services_outlined
                      : jenis.toLowerCase().contains('alpha')
                          ? Icons.warning_amber_rounded
                          : Icons.assignment_outlined,
                  size: 14,
                  color: RekapTheme.textDark,
                ),
                const SizedBox(width: 6),
                Text(jenis,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: RekapTheme.textDark)),
              ]),
            ),
            _buildStatusBadge(status),
          ]),
          const SizedBox(height: 12),
          Text('Tanggal: ${_formatTanggal(tanggal)}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: RekapTheme.textDark)),
          const SizedBox(height: 4),
          Text('Alasan: $keterangan',
              style: const TextStyle(color: RekapTheme.textGrey, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          if (buktiFotoUrls.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.image, size: 12, color: RekapTheme.blue),
              const SizedBox(width: 4),
              Text('${buktiFotoUrls.length} foto terlampir',
                  style: const TextStyle(
                      color: RekapTheme.blue,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ]),
          ],
          if (isDitolak && rejectionReason != null) ...[
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: RekapTheme.border)),
            Row(children: [
              const Icon(Icons.info_outline, size: 14, color: RekapTheme.red),
              const SizedBox(width: 6),
              Expanded(
                  child: Text('Alasan Ditolak: $rejectionReason',
                      style: const TextStyle(
                          color: RekapTheme.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w500))),
            ]),
          ],
          const SizedBox(height: 8),
          Text('Diajukan: ${_formatDateTime(createdAt)}',
              style: const TextStyle(color: RekapTheme.textGrey, fontSize: 11)),
          if (decidedAt != null) ...[
            const SizedBox(height: 4),
            Text('Diputuskan: ${_formatDateTime(decidedAt)}',
                style:
                    const TextStyle(color: RekapTheme.textGrey, fontSize: 11)),
          ],
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Klik untuk detail →',
                style: TextStyle(
                    color: RekapTheme.primaryRed,
                    fontSize: 10,
                    fontStyle: FontStyle.italic)),
            if (isPending)
              Row(children: [
                _buildActionButton(Icons.edit_outlined, 'Edit', RekapTheme.blue,
                    () => _showEditIzinBottomSheet(data)),
                const SizedBox(width: 8),
                _buildActionButton(Icons.delete_outline, 'Hapus',
                    RekapTheme.red, () => _showDeleteBottomSheet(data['id'])),
              ]),
          ]),
        ]),
      ),
    );
  }

  Widget _buildActionButton(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Row(children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  void _showEditIzinBottomSheet(Map<String, dynamic> izinData) {
    final jenisController = TextEditingController(text: izinData['jenis']);
    final keteranganController =
        TextEditingController(text: izinData['keterangan']);
    final tanggal = izinData['tanggal']?.toString();
    final List<XFile> selectedImages = [];
    final bool isPending = (izinData['status']?.toString().toLowerCase() ?? '')
        .contains('pending');

    // Periksa status izin - hanya bisa edit jika pending
    if (!isPending) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Hanya izin dengan status "Menunggu" yang dapat diedit'),
          backgroundColor: RekapTheme.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25), topRight: Radius.circular(25))),
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 16),
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Row(children: [
                  Icon(Icons.edit_rounded, color: RekapTheme.blue, size: 24),
                  SizedBox(width: 12),
                  Text('Edit Pengajuan Izin',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: RekapTheme.textDark)),
                ])),
            const SizedBox(height: 8),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('Tanggal: ${_formatTanggal(tanggal)}',
                    style: const TextStyle(
                        color: RekapTheme.textGrey, fontSize: 14))),
            const SizedBox(height: 24),

            // Informasi penting
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: RekapTheme.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: RekapTheme.orange.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: RekapTheme.orange, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Semua data termasuk foto akan diganti',
                      style: TextStyle(
                        color: RekapTheme.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Jenis Izin *',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: RekapTheme.textDark)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                            color: RekapTheme.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: RekapTheme.border)),
                        child: TextField(
                          controller: jenisController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            hintText: 'Misal: Sakit, Izin, Alpha',
                          ),
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ])),
            const SizedBox(height: 20),

            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Keterangan *',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: RekapTheme.textDark)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                            color: RekapTheme.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: RekapTheme.border)),
                        child: TextField(
                          controller: keteranganController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            hintText: 'Tuliskan alasan pengajuan izin',
                          ),
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ])),
            const SizedBox(height: 24),

            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Bukti Foto Baru *',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: RekapTheme.textDark)),
                      const SizedBox(height: 8),
                      const Text(
                          'Upload 1-3 foto baru (akan menggantikan semua foto lama)',
                          style: TextStyle(
                              color: RekapTheme.textGrey, fontSize: 12)),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                            child: ElevatedButton.icon(
                          onPressed: () async {
                            final picker = ImagePicker();
                            final images = await picker.pickMultiImage(
                                maxWidth: 1080,
                                maxHeight: 1080,
                                imageQuality: 85);
                            if (images.isNotEmpty) {
                              setState(() {
                                if (selectedImages.length + images.length <=
                                    3) {
                                  selectedImages.addAll(images);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Maksimal 3 foto'),
                                          backgroundColor: Colors.red));
                                }
                              });
                            }
                          },
                          icon: const Icon(Icons.photo_library_outlined,
                              size: 20),
                          label: const Text('Pilih Foto'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                RekapTheme.primaryRed.withValues(alpha: 0.1),
                            foregroundColor: RekapTheme.primaryRed,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                    color: RekapTheme.primaryRed
                                        .withValues(alpha: 0.3))),
                          ),
                        )),
                        if (selectedImages.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () =>
                                setState(() => selectedImages.clear()),
                            icon: const Icon(Icons.delete_outline, size: 20),
                            label: const Text('Hapus Semua'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: RekapTheme.red.withValues(alpha: 0.1),
                              foregroundColor: RekapTheme.red,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                      color: RekapTheme.red.withValues(alpha: 0.3))),
                            ),
                          ),
                        ],
                      ]),
                    ])),

            if (selectedImages.isNotEmpty) ...[
              const SizedBox(height: 20),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Foto Terpilih (${selectedImages.length}/3)',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: RekapTheme.textDark)),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                              children:
                                  selectedImages.asMap().entries.map((entry) {
                            final index = entry.key;
                            final image = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Stack(children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.grey[100]),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(File(image.path),
                                        fit: BoxFit.cover),
                                  ),
                                ),
                                Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => setState(
                                          () => selectedImages.removeAt(index)),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                            color: Colors.red.withValues(alpha: 0.9),
                                            shape: BoxShape.circle),
                                        child: const Icon(Icons.close,
                                            size: 16, color: Colors.white),
                                      ),
                                    )),
                              ]),
                            );
                          }).toList()),
                        ),
                      ])),
            ],

            const SizedBox(height: 32),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(children: [
                  Expanded(
                      child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: RekapTheme.border),
                    ),
                    child: const Text('Batal',
                        style: TextStyle(
                            color: RekapTheme.textGrey,
                            fontWeight: FontWeight.w600)),
                  )),
                  const SizedBox(width: 16),
                  Expanded(
                      child: ElevatedButton(
                    onPressed: () => _updateIzin(
                            izinData['id'],
                            jenisController.text,
                            keteranganController.text,
                            selectedImages)
                        .then((success) {
                      if (success) {
                        Navigator.pop(context);
                        _refreshData(); // Gunakan refreshData setelah edit
                      }
                    }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RekapTheme.primaryRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Simpan Perubahan',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  )),
                ])),
            const SizedBox(height: 24),
          ]),
        );
      }),
    );
  }

  Future<bool> _updateIzin(
      int id, String jenis, String keterangan, List<XFile> images) async {
    if (jenis.isEmpty || keterangan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Harap isi semua field'), backgroundColor: Colors.red));
      return false;
    }
    if (images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Harap upload minimal 1 foto'),
          backgroundColor: Colors.red));
      return false;
    }

    if (images.length > 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Maksimal 3 foto'), backgroundColor: Colors.red));
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sesi telah berakhir, silakan login kembali'),
          backgroundColor: Colors.red));
      return false;
    }

    // Tampilkan loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: RekapTheme.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: RekapTheme.primaryRed),
            SizedBox(height: 20),
            Text(
              'Menyimpan perubahan...',
              style: TextStyle(color: RekapTheme.textDark),
            ),
          ],
        ),
      ),
    );

    try {
      await dotenv.load();
      final baseUrl =
          dotenv.env['API_BASE_URL'] ?? 'https://api.gedanggoreng.com';
      final url = Uri.parse('$baseUrl/api/izin/$id');

      final request = http.MultipartRequest('PUT', url);
      request.headers['Authorization'] = 'Bearer $token';

      // Tambahkan text fields
      request.fields['jenis'] = jenis;
      request.fields['keterangan'] = keterangan;

      // Tambahkan files
      for (final image in images) {
        try {
          final file = await http.MultipartFile.fromPath('files', image.path);
          request.files.add(file);
        } catch (e) {
          print('Error adding file: $e');
          if (context.mounted) {
            Navigator.pop(context); // Tutup loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gagal mengupload foto'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return false;
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Tutup loading dialog
      if (context.mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Response: $responseData');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
        return true;
      } else {
        print('Error response: ${response.statusCode} - ${response.body}');

        String errorMessage = 'Gagal memperbarui izin';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map && errorData.containsKey('detail')) {
            errorMessage = errorData['detail'].toString();
          } else if (errorData is Map && errorData.containsKey('message')) {
            errorMessage = errorData['message'].toString();
          }
        } catch (e) {
          errorMessage = 'Status: ${response.statusCode} - ${response.body}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } catch (e) {
      print('Error: $e');
      if (context.mounted) {
        Navigator.pop(context); // Tutup loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan, periksa koneksi internet Anda'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  void _showDeleteBottomSheet(int id) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25), topRight: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 32),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
                color: RekapTheme.red.withValues(alpha: 0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.delete_forever_rounded,
                color: RekapTheme.red, size: 40),
          ),
          const SizedBox(height: 24),
          const Text('Hapus Pengajuan Izin?',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: RekapTheme.textDark)),
          const SizedBox(height: 12),
          const Text(
              'Tindakan ini tidak dapat dibatalkan. Data pengajuan akan dihapus secara permanen.',
              style: TextStyle(color: RekapTheme.textGrey, fontSize: 14),
              textAlign: TextAlign.center),
          const SizedBox(height: 32),
          Row(children: [
            Expanded(
                child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                side: const BorderSide(color: RekapTheme.border),
              ),
              child: const Text('Batal',
                  style: TextStyle(
                      color: RekapTheme.textGrey, fontWeight: FontWeight.w600)),
            )),
            const SizedBox(width: 16),
            Expanded(
                child: ElevatedButton(
              onPressed: () => _deleteIzin(id).then((success) {
                if (success) {
                  Navigator.pop(context);
                  _refreshData(); // Gunakan refreshData setelah delete
                }
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: RekapTheme.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Hapus',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            )),
          ]),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Future<bool> _deleteIzin(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return false;
    try {
      await dotenv.load();
      final baseUrl =
          dotenv.env['API_BASE_URL'] ?? 'https://api.gedanggoreng.com';
      final response = await http.delete(Uri.parse('$baseUrl/api/izin/$id'),
          headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Izin berhasil dihapus'),
            backgroundColor: Colors.green));
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Gagal: ${response.body}'),
            backgroundColor: Colors.red));
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Terjadi kesalahan'), backgroundColor: Colors.red));
      return false;
    }
  }
}

class DetailIzinScreen extends StatefulWidget {
  final Map<String, dynamic> izinData;
  const DetailIzinScreen({super.key, required this.izinData});
  @override
  State<DetailIzinScreen> createState() => _DetailIzinScreenState();
}

class _DetailIzinScreenState extends State<DetailIzinScreen> {
  void _showImagePreview(int index, List<dynamic> buktiFotoUrls) {
    showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.9),
        builder: (context) => ImagePreviewDialog(
            imageUrls: buktiFotoUrls.cast<String>(), initialIndex: index));
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.izinData['status']?.toString() ?? 'Pending';
    final jenis = widget.izinData['jenis']?.toString() ?? 'Izin';
    final keterangan = widget.izinData['keterangan']?.toString() ?? '-';
    final tanggal = widget.izinData['tanggal']?.toString();
    final createdAt = widget.izinData['created_at']?.toString();
    final decidedAt = widget.izinData['decided_at']?.toString();
    final rejectionReason = widget.izinData['rejection_reason']?.toString();
    final note = widget.izinData['note']?.toString();
    final buktiFotoUrls = widget.izinData['bukti_foto_urls'] is List
        ? (widget.izinData['bukti_foto_urls'] as List<dynamic>)
        : [];
    final isDitolak = status.toLowerCase().contains('ditolak') ||
        status.toLowerCase().contains('rejected');
    final isDisetujui = status.toLowerCase().contains('disetujui') ||
        status.toLowerCase().contains('approved');
    Color statusColor = RekapTheme.orange;
    String statusDisplay = 'Menunggu';
    IconData statusIcon = Icons.access_time;
    if (isDisetujui) {
      statusColor = RekapTheme.green;
      statusDisplay = 'Disetujui';
      statusIcon = Icons.check_circle;
    } else if (isDitolak) {
      statusColor = RekapTheme.red;
      statusDisplay = 'Ditolak';
      statusIcon = Icons.cancel;
    }
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
                topLeft: Radius.circular(25), topRight: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, -5))
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
                              borderRadius: BorderRadius.circular(10)))),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Detail Pengajuan Izin',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: RekapTheme.textDark)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: statusColor.withValues(alpha: 0.3),
                                  width: 1)),
                          child: Row(children: [
                            Icon(statusIcon, size: 16, color: statusColor),
                            const SizedBox(width: 6),
                            Text(statusDisplay,
                                style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12))
                          ]),
                        ),
                      ]),
                  const SizedBox(height: 30),
                  _buildDetailSection(
                      'Informasi Pengajuan', Icons.info_outline, [
                    _buildDetailItem('Jenis Pengajuan', jenis),
                    _buildDetailItem(
                        'Tanggal Izin', _formatTanggalDetail(tanggal)),
                    _buildDetailItem(
                        'Waktu Pengajuan', _formatDateTimeDetail(createdAt)),
                    if (decidedAt != null)
                      _buildDetailItem(
                          'Waktu Diputuskan', _formatDateTimeDetail(decidedAt)),
                  ]),
                  const SizedBox(height: 24),
                  _buildDetailSection('Alasan Pengajuan', Icons.description,
                      [_buildDetailItem('Keterangan', keterangan)]),
                  if (note != null && note.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildDetailSection('Catatan', Icons.notes,
                        [_buildDetailItem('Catatan Tambahan', note)]),
                  ],
                  if (isDitolak && rejectionReason != null) ...[
                    const SizedBox(height: 24),
                    _buildDetailSection(
                        'Informasi Penolakan',
                        Icons.warning_amber_rounded,
                        [_buildDetailItem('Alasan Penolakan', rejectionReason)],
                        backgroundColor: RekapTheme.red.withValues(alpha: 0.05),
                        borderColor: RekapTheme.red.withValues(alpha: 0.2)),
                  ],
                  if (buktiFotoUrls.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildDetailSection('Bukti Foto', Icons.photo_library, [
                      const SizedBox(height: 12),
                      if (buktiFotoUrls.length == 1)
                        _buildSingleImagePreview(
                            buktiFotoUrls.first, 0, buktiFotoUrls)
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 1),
                          itemCount: buktiFotoUrls.length,
                          itemBuilder: (context, index) {
                            final imageUrl =
                                buktiFotoUrls[index]?.toString() ?? '';
                            return _buildImageThumbnail(
                                imageUrl, index, buktiFotoUrls);
                          },
                        ),
                      const SizedBox(height: 12),
                      const Text('Klik gambar untuk melihat lebih besar',
                          style: TextStyle(
                              color: RekapTheme.textGrey,
                              fontSize: 12,
                              fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center),
                    ]),
                  ],
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: RekapTheme.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: RekapTheme.border)),
                    child: const Row(children: [
                      Icon(Icons.info_outline,
                          color: RekapTheme.blue, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('Informasi',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: RekapTheme.textDark,
                                    fontSize: 14)),
                            SizedBox(height: 4),
                            Text(
                                'Silakan hubungi guru pembimbing atau administrator jika ada pertanyaan terkait pengajuan ini.',
                                style: TextStyle(
                                    color: RekapTheme.textGrey, fontSize: 12)),
                          ])),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: RekapTheme.primaryRed,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2),
                    child: const Text('Tutup Detail',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSingleImagePreview(
      String imageUrl, int index, List<dynamic> buktiFotoUrls) {
    return GestureDetector(
      onTap: () => _showImagePreview(index, buktiFotoUrls),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12), color: Colors.grey[100]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(children: [
            if (imageUrl.isNotEmpty)
              Image.network(imageUrl,
                  width: double.infinity, height: 200, fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                    child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null));
              }, errorBuilder: (context, error, stackTrace) {
                return Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      Icon(Icons.broken_image,
                          size: 40, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text('Gagal memuat gambar',
                          style: TextStyle(color: Colors.grey[500])),
                    ]));
              })
            else
              Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    Icon(Icons.broken_image, size: 40, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text('Tidak ada gambar',
                        style: TextStyle(color: Colors.grey[500])),
                  ])),
            Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20)),
                    child: const Icon(Icons.zoom_in,
                        color: Colors.white, size: 16))),
          ]),
        ),
      ),
    );
  }

  Widget _buildImageThumbnail(
      String imageUrl, int index, List<dynamic> buktiFotoUrls) {
    return GestureDetector(
      onTap: () => _showImagePreview(index, buktiFotoUrls),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8), color: Colors.grey[100]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(children: [
            if (imageUrl.isNotEmpty)
              Image.network(imageUrl,
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
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null));
              }, errorBuilder: (context, error, stackTrace) {
                return Center(
                    child: Icon(Icons.broken_image, color: Colors.grey[400]));
              })
            else
              Center(child: Icon(Icons.broken_image, color: Colors.grey[400])),
            Positioned.fill(
                child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.black.withValues(alpha: 0.1),
                            width: 1)))),
            Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(15)),
                    child: const Icon(Icons.zoom_in,
                        color: Colors.white, size: 12))),
          ]),
        ),
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
        border: Border.all(
            color: borderColor ?? RekapTheme.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: RekapTheme.primaryRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: RekapTheme.primaryRed, size: 20)),
          const SizedBox(width: 12),
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: RekapTheme.textDark)),
        ]),
        const SizedBox(height: 16),
        ...children,
      ]),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                color: RekapTheme.textGrey,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 15,
                color: RekapTheme.textDark,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }

  String _formatTanggalDetail(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      final hari = [
        'Senin',
        'Selasa',
        'Rabu',
        'Kamis',
        'Jumat',
        'Sabtu',
        'Minggu'
      ];
      final bulan = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember'
      ];
      return '${hari[date.weekday - 1]}, ${date.day} ${bulan[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatDateTimeDetail(String? dateTimeString) {
    if (dateTimeString == null) return '-';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final hari = [
        'Senin',
        'Selasa',
        'Rabu',
        'Kamis',
        'Jumat',
        'Sabtu',
        'Minggu'
      ];
      final bulan = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember'
      ];
      return '${hari[dateTime.weekday - 1]}, ${dateTime.day} ${bulan[dateTime.month - 1]} ${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} WIB';
    } catch (e) {
      return dateTimeString;
    }
  }
}

class ImagePreviewDialog extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  const ImagePreviewDialog(
      {super.key, required this.imageUrls, required this.initialIndex});
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
      child: Stack(children: [
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
                    child: Image.network(imageUrl, fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                          child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null));
                    }, errorBuilder: (context, error, stackTrace) {
                      return const Center(
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                            Icon(Icons.broken_image,
                                size: 60, color: Colors.white),
                            SizedBox(height: 16),
                            Text('Gagal memuat gambar',
                                style: TextStyle(color: Colors.white)),
                          ]));
                    }),
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
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.close,
                        color: Colors.white, size: 24)))),
        Positioned(
            top: 40,
            left: 20,
            child: GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Fitur download akan segera tersedia'),
                        backgroundColor: Colors.green)),
                child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.download,
                        color: Colors.white, size: 24)))),
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
                            onTap: () => _pageController.animateToPage(index,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut),
                            child: Container(
                                width: 8,
                                height: 8,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentIndex == index
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.5))),
                          )))),
        if (widget.imageUrls.length > 1)
          Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                  child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20)),
                child: Text('${_currentIndex + 1} / ${widget.imageUrls.length}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ))),
      ]),
    );
  }
}
