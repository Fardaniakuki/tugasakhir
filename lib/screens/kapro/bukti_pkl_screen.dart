// bukti_pkl_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';

class BuktiPklScreen extends StatefulWidget {
  final ScrollController? scrollController;

  const BuktiPklScreen({
    super.key,
    this.scrollController,
  });

  @override
  State<BuktiPklScreen> createState() => _BuktiPklScreenState();
}

class _BuktiPklScreenState extends State<BuktiPklScreen>
    with AutomaticKeepAliveClientMixin {
  final Color _primaryRed = const Color(0xFF6B1B1B);
  final Color _bgSoft = const Color(0xFFF6EEEE);
  final Color _secondaryColor = Colors.white;
  final Color _textPrimary = Colors.black;
  final Color _textSecondary = const Color(0xFF666666);
  final Color _borderColor = const Color(0xFFE0E0E0);
  final Color _green = const Color(0xFF4CAF50);
  final Color _orange = const Color(0xFFFF9800);
  final Color _red = const Color(0xFFF44336);

  List<Map<String, dynamic>> _buktiPklData = [];
  List<Map<String, dynamic>> _filteredData = [];
  String _filterStatus = 'Semua';
  final TextEditingController _searchController = TextEditingController();

  String? _accessToken;
  bool _isLoading = true;
  bool _isError = false;
  String _errorMessage = '';

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  final int _itemsPerPage = 10;

  // Filter options
  final List<String> _statusOptions = [
    'Semua',
    'Diterima',
    'Menunggu Verifikasi',
    'Perlu Revisi',
    'Ditolak'
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
      _isError = false;
    });

    await _getAccessToken();

    if (_accessToken != null) {
      await _fetchApprovedApplications();
    } else {
      setState(() {
        _isError = true;
        _errorMessage = 'Token tidak ditemukan. Silakan login ulang.';
        _isLoading = false;
      });
    }
  }

  Future<void> _getAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _accessToken = prefs.getString('access_token');
      });
      print('Access Token: $_accessToken');
    } catch (e) {
      print('Error getting access token: $e');
    }
  }

  Future<void> _fetchApprovedApplications({int page = 1}) async {
    if (_accessToken == null || _accessToken!.isEmpty) {
      setState(() {
        _isError = true;
        _errorMessage = 'Token tidak valid. Silakan login ulang.';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            '${dotenv.env['API_BASE_URL']}/api/pkl/applications?status=Approved&page=$page&limit=$_itemsPerPage'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        final List<dynamic> applications = responseData['data'] ?? [];

        _totalItems = responseData['total'] ?? applications.length;
        _totalPages = (_totalItems / _itemsPerPage).ceil();
        _currentPage = page;

        setState(() {
          _buktiPklData = applications.map((item) {
            return _mapApiResponseToModel(item);
          }).toList();
          _filteredData = _buktiPklData;
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _isError = true;
          _errorMessage = 'Sesi telah berakhir. Silakan login ulang.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isError = true;
          _errorMessage = 'Gagal memuat data: ${response.statusCode}';
          _isLoading = false;
        });
        _loadDummyData();
      }
    } catch (e) {
      print('Error fetching approved applications: $e');
      setState(() {
        _isError = true;
        _errorMessage = 'Terjadi kesalahan: $e';
        _isLoading = false;
      });
      _loadDummyData();
    }
  }

  Future<void> _generateSuratPermohonan(int applicationId) async {
    if (_accessToken == null || _accessToken!.isEmpty) {
      _showSnackBar('Token tidak ditemukan', isError: true);
      return;
    }

    try {
      _showSnackBar('Menggenerate surat permohonan...');

      final response = await http.post(
        Uri.parse(
            '${dotenv.env['API_BASE_URL']}/api/pkl/$applicationId/generate-surat'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({}),
      );

      print('Generate surat response: ${response.statusCode}');
      print('Generate surat body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final String filename = responseData['filename'] ?? '';
        final String fileUrl = responseData['file_url'] ?? '';

        // Build full URL untuk download
        final String fullUrl = 'https://sertif.gedanggoreng.com$fileUrl';

        // Tampilkan dialog sukses dengan preview
        _showSuccessDialogSuratPermohonan(filename, fullUrl);

        _showSnackBar('Surat berhasil digenerate');
      } else {
        _showSnackBar('Gagal mengenerate surat: ${response.statusCode}',
            isError: true);
      }
    } catch (e) {
      print('Error generating surat: $e');
      _showSnackBar('Error: $e', isError: true);
    }
  }

  // ==================== FUNGSI PREVIEW FILE DI BROWSER ====================
  Future<void> _previewFile(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);

      // Tanyakan ke user apakah ingin preview atau langsung download
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Buka Dokumen',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.open_in_browser, color: Colors.blue),
                ),
                title: const Text(
                  'Lihat di Browser',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                subtitle: const Text(
                  'Lihat file langsung di browser',
                  style: TextStyle(fontSize: 13),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _launchInBrowser(url);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.download, color: Colors.green),
                ),
                title: const Text(
                  'Download',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                subtitle: const Text(
                  'Simpan file ke perangkat',
                  style: TextStyle(fontSize: 13),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _launchInBrowser(url); // Browser akan handle download
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  // Fungsi untuk meluncurkan URL di browser
  Future<void> _launchInBrowser(Uri url) async {
    try {
      // Pastikan URL memiliki scheme
      Uri finalUrl = url;
      if (!finalUrl.hasScheme) {
        finalUrl = Uri.parse('https://${url.toString()}');
      }

      print('Mencoba membuka URL: $finalUrl');

      // Cek apakah bisa di-launch
      final bool canLaunch = await canLaunchUrl(finalUrl);

      if (canLaunch) {
        // Coba buka di browser eksternal (Chrome)
        final bool launched = await launchUrl(
          finalUrl,
          mode: LaunchMode.externalApplication,
          webViewConfiguration: const WebViewConfiguration(
            enableJavaScript: true,
            enableDomStorage: true,
          ),
        );

        if (!launched) {
          // Fallback ke mode default
          await launchUrl(
            finalUrl,
            mode: LaunchMode.platformDefault,
          );
        }
      } else {
        // Fallback: coba buka dengan mode platformDefault
        await launchUrl(
          finalUrl,
          mode: LaunchMode.platformDefault,
        );
      }
    } catch (e) {
      print('Error launching URL: $e');

      // Ultimate fallback
      try {
        await launchUrl(
          url,
          mode: LaunchMode.platformDefault,
        );
      } catch (e2) {
        _showSnackBar('Gagal membuka browser: $e', isError: true);
      }
    }
  }

  // Dialog sukses generate surat
  void _showSuccessDialogSuratPermohonan(String filename, String downloadUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryRed, _primaryRed.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Berhasil!',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Surat Permohonan telah dibuat',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _borderColor, width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.insert_drive_file,
                              color: Colors.blue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'File PDF',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  filename,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Siap untuk dibuka',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF4CAF50),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: const BoxDecoration(
                  border: Border(
                      top: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Nanti Saja',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _previewFile(downloadUrl);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.remove_red_eye, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Tinjau',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
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

  Map<String, dynamic> _mapApiResponseToModel(dynamic item) {
    final application = item['application'] ?? {};

    List<String> dokumenUrls = [];
    if (application['dokumen_urls'] != null &&
        application['dokumen_urls'] is List) {
      dokumenUrls = List<String>.from(application['dokumen_urls']);
    }

    String fileType = 'pdf';
    final String firstUrl = dokumenUrls.isNotEmpty ? dokumenUrls.first : '';
    if (firstUrl.isNotEmpty) {
      if (firstUrl.toLowerCase().endsWith('.jpg') ||
          firstUrl.toLowerCase().endsWith('.jpeg') ||
          firstUrl.toLowerCase().endsWith('.png')) {
        fileType = 'image';
      }
    }

    final String status = application['status'] ?? 'Menunggu Verifikasi';

    return {
      'id': application['id']?.toString() ?? '',
      'application_id': application['id'],
      'nama': item['siswa_username'] ?? 'Siswa',
      'kelas': item['kelas_nama'] ?? 'XII -',
      'industri': item['industri_nama'] ?? 'Industri',
      'industri_alamat': '-',
      'industri_kontak': '-',
      'status': _mapStatus(status),
      'tanggal_kirim': _formatDate(application['tanggal_permohonan']),
      'tanggal_verifikasi': application['decided_at'] != null
          ? _formatDate(application['decided_at'])
          : null,
      'verifikator': application['processed_by']?.toString(),
      'catatan': application['kaprog_note'] ?? application['catatan'] ?? '',
      'statusColor': _getStatusColor(status),
      'file_urls': dokumenUrls,
      'file_type': fileType,
      'file_size': _estimateFileSize(dokumenUrls.length),
      'is_approved': status == 'Approved',
      'tanggal_mulai': application['tanggal_mulai'],
      'tanggal_selesai': application['tanggal_selesai'],
      'siswa_nisn': item['siswa_nisn'],
      'jurusan_nama': item['jurusan_nama'],
    };
  }

  String _mapStatus(String status) {
    switch (status) {
      case 'Approved':
        return 'Diterima';
      case 'Pending':
        return 'Menunggu Verifikasi';
      case 'Revision':
        return 'Perlu Revisi';
      case 'Rejected':
        return 'Ditolak';
      default:
        return 'Menunggu Verifikasi';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return _green;
      case 'Pending':
      case 'Revision':
        return _orange;
      case 'Rejected':
        return _red;
      default:
        return _orange;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final DateTime date = DateTime.parse(dateString);
      return '${date.day} ${_getMonthName(date.month)} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _getMonthName(int month) {
    const months = [
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
    return months[month - 1];
  }

  String _estimateFileSize(int fileCount) {
    if (fileCount == 0) return '0 MB';
    if (fileCount == 1) return '~1.5 MB';
    if (fileCount == 2) return '~3 MB';
    return '~${fileCount * 1.5} MB';
  }

  void _loadDummyData() {
    setState(() {
      _buktiPklData = [
        {
          'id': 'PKL001',
          'application_id': 150,
          'nama': 'Anastasya Dyah',
          'kelas': 'XII TKJ 4',
          'industri': 'PT. Universal Big Data',
          'industri_alamat': '-',
          'industri_kontak': '-',
          'status': 'Diterima',
          'tanggal_kirim': '22 Feb 2026',
          'tanggal_verifikasi': '22 Feb 2026',
          'verifikator': '39',
          'catatan': 'woke',
          'statusColor': _green,
          'file_urls': [
            'https://cdn.gedanggoreng.com/uploads/pkl_dokumen/238_0ed297a5-6e05-452b-b60b-0ca5aba20f51_0.jpg',
            'https://cdn.gedanggoreng.com/uploads/pkl_dokumen/238_0ed297a5-6e05-452b-b60b-0ca5aba20f51_1.jpg',
            'https://cdn.gedanggoreng.com/uploads/pkl_dokumen/238_0ed297a5-6e05-452b-b60b-0ca5aba20f51_2.jpg'
          ],
          'file_type': 'image',
          'file_size': '~4.5 MB',
          'is_approved': true,
          'tanggal_mulai': '2026-02-24',
          'tanggal_selesai': '2026-02-28',
          'siswa_nisn': '9999999912',
          'jurusan_nama': 'Teknik Komputer dan Jaringan',
        },
      ];
      _filteredData = _buktiPklData;
      _isLoading = false;
    });
  }

  void _filterByStatus(String status) {
    setState(() {
      _filterStatus = status;
      if (status == 'Semua') {
        _filteredData = _buktiPklData;
      } else {
        _filteredData =
            _buktiPklData.where((item) => item['status'] == status).toList();
      }
    });
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      _fetchApprovedApplications(page: page);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        backgroundColor: isError ? _red : _green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showFileDetail(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _secondaryColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Detail Dokumen',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: _primaryRed,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 28),
                      color: _textPrimary,
                    ),
                  ],
                ),
              ),

              // SCROLLABLE CONTENT
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Student Info Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: _primaryRed.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color:
                                            _primaryRed.withValues(alpha: 0.3)),
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    color: _primaryRed,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['nama'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        data['kelas'],
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _textSecondary,
                                        ),
                                      ),
                                      if (data['siswa_nisn'] != null &&
                                          data['siswa_nisn'] != '-') ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'NISN: ${data['siswa_nisn']}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _textSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: (data['statusColor'] as Color?)
                                            ?.withValues(alpha: 0.1) ??
                                        _orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: (data['statusColor'] as Color?)
                                                ?.withValues(alpha: 0.3) ??
                                            _orange.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    data['status'],
                                    style: TextStyle(
                                      color: data['statusColor'] ?? _orange,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Industry Info
                            Row(
                              children: [
                                Icon(Icons.apartment,
                                    size: 18, color: _textSecondary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    data['industri'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            if (data['jurusan_nama'] != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.school,
                                      size: 18, color: _textSecondary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Jurusan: ${data['jurusan_nama']}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            if (data['tanggal_mulai'] != null &&
                                data['tanggal_selesai'] != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.date_range,
                                      size: 18, color: _textSecondary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Periode: ${_formatDate(data['tanggal_mulai'])} - ${_formatDate(data['tanggal_selesai'])}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // File Information
                      const Text(
                        'Informasi Dokumen',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _borderColor),
                        ),
                        child: Column(
                          children: [
                            _infoRow(
                                'Jenis File', data['file_type'].toUpperCase()),
                            const SizedBox(height: 12),
                            _infoRow('Estimasi Ukuran', data['file_size']),
                            const SizedBox(height: 12),
                            _infoRow('Jumlah File',
                                '${(data['file_urls'] as List?)?.length ?? 0} file'),
                            const SizedBox(height: 12),
                            _infoRow('Tanggal Kirim', data['tanggal_kirim']),
                            if (data['tanggal_verifikasi'] != null) ...[
                              const SizedBox(height: 12),
                              _infoRow('Tanggal Verifikasi',
                                  data['tanggal_verifikasi']),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Catatan
                      if (data['catatan'] != null && data['catatan'].isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Catatan',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _borderColor),
                              ),
                              child: Text(
                                data['catatan'],
                                style: TextStyle(
                                  fontSize: 15,
                                  color: _textPrimary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),

                      // File URLs Preview
                      if (data['file_urls'] != null &&
                          (data['file_urls'] as List).isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'File Dokumen',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...List.generate((data['file_urls'] as List).length,
                                (index) {
                              final url = (data['file_urls'] as List)[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _borderColor),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      data['file_type'] == 'image'
                                          ? Icons.image
                                          : Icons.picture_as_pdf,
                                      color: _primaryRed,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'File ${index + 1}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            url.split('/').last,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: _textSecondary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => _previewFile(url),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _primaryRed,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      child: const Text(
                                        'TINJAU',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 24),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (data['file_urls'] != null &&
                              (data['file_urls'] as List).isNotEmpty) {
                            _previewFile((data['file_urls'] as List).first);
                          } else {
                            _showSnackBar('Tidak ada file untuk dibuka',
                                isError: true);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryRed,
                          side: BorderSide(color: _primaryRed),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.remove_red_eye, size: 20),
                        label: const Text(
                          'PRATINJAU',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: data['application_id'] != null
                            ? () =>
                                _generateSuratPermohonan(data['application_id'])
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: data['application_id'] != null
                              ? _primaryRed
                              : Colors.grey[400],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.description, size: 20),
                        label: const Text(
                          'BUAT SURAT',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _performSearch() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isNotEmpty) {
      setState(() {
        _filteredData = _buktiPklData.where((item) {
          return item['nama'].toLowerCase().contains(query) ||
              item['kelas'].toLowerCase().contains(query) ||
              item['industri'].toLowerCase().contains(query);
        }).toList();
      });
    } else {
      _filterByStatus(_filterStatus);
    }
  }

  Future<void> _refreshData() async {
    await _fetchApprovedApplications(page: 1);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: _bgSoft,
      body: _isLoading
          ? _buildLoadingIndicator()
          : _isError
              ? _buildErrorWidget()
              : RefreshIndicator(
                  onRefresh: _refreshData,
                  backgroundColor: Colors.white,
                  color: _primaryRed,
                  child: SingleChildScrollView(
                    controller: widget.scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _headerCard(),
                        const SizedBox(height: 16),
                        _filterSection(),
                        const SizedBox(height: 20),
                        _statisticsSection(),
                        const SizedBox(height: 20),
                        _documentList(),
                        if (_totalPages > 1) _buildPagination(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: _primaryRed,
          ),
          const SizedBox(height: 16),
          Text(
            'Memuat data...',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: _red,
            ),
            const SizedBox(height: 16),
            Text(
              'Terjadi Kesalahan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializeData,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('COBA LAGI'),
            ),
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
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bukti PKL',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF6B1B1B),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Siswa yang telah disetujui PKL-nya',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B1B1B),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusOptions.map((status) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    text: status,
                    isSelected: _filterStatus == status,
                    onTap: () => _filterByStatus(status),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          _searchField(),
        ],
      ),
    );
  }

  // ignore: non_constant_identifier_names
  Widget _FilterChip({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _primaryRed : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _primaryRed),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : _primaryRed,
          ),
        ),
      ),
    );
  }

  Widget _searchField() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.search, color: Colors.grey[600], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration.collapsed(
                hintText: 'Cari nama siswa, kelas, atau industri...',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              onChanged: (value) => _performSearch(),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _performSearch();
                });
              },
              icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
            ),
        ],
      ),
    );
  }

  Widget _statisticsSection() {
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
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StatItem('Total Disetujui', _totalItems.toString(),
              Icons.check_circle, _green),
        ],
      ),
    );
  }

  // ignore: non_constant_identifier_names
  Widget _StatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 24, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _documentList() {
    if (_filteredData.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Tidak ada data siswa yang disetujui',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _filterStatus == 'Semua'
                  ? 'Belum ada siswa yang disetujui PKL-nya'
                  : 'Tidak ada data dengan status "$_filterStatus"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daftar Siswa Disetujui',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _primaryRed,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _primaryRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _primaryRed.withValues(alpha: 0.2)),
                ),
                child: Text(
                  '${_filteredData.length} siswa',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _primaryRed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._filteredData.map((data) => _DocumentCard(
                data: data,
                onTap: () => _showFileDetail(data),
                onGenerateSurat: () {
                  if (data['application_id'] != null) {
                    _generateSuratPermohonan(data['application_id']);
                  }
                },
              )),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed:
                _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
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
          Text(
            'Halaman $_currentPage dari $_totalPages',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          IconButton(
            onPressed: _currentPage < _totalPages
                ? () => _goToPage(_currentPage + 1)
                : null,
            icon: Icon(
              Icons.chevron_right,
              color:
                  _currentPage < _totalPages ? _primaryRed : Colors.grey[400],
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
}

class _DocumentCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  final VoidCallback onGenerateSurat;

  const _DocumentCard({
    required this.data,
    required this.onTap,
    required this.onGenerateSurat,
  });

  static const Color _primaryRed = Color(0xFF6B1B1B);

  @override
  Widget build(BuildContext context) {
    final fileCount = (data['file_urls'] as List?)?.length ?? 0;

    // Get status color with fallback
    final statusColor = data['statusColor'] as Color? ?? Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _primaryRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: _primaryRed.withValues(alpha: 0.3)),
                      ),
                      child: Icon(
                        fileCount > 0
                            ? Icons.insert_drive_file
                            : Icons.file_present,
                        color: _primaryRed,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['nama'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              data['kelas'],
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        data['status'],
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Industry Info
                Row(
                  children: [
                    Icon(Icons.apartment, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        data['industri'],
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // File Info
                Row(
                  children: [
                    Icon(
                      Icons.description,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$fileCount file • ${data['file_size']}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Text(
                      data['tanggal_kirim'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),

                // Periode Info
                if (data['tanggal_mulai'] != null &&
                    data['tanggal_selesai'] != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.date_range, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${data['tanggal_mulai']} s/d ${data['tanggal_selesai']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // Catatan Preview
                if (data['catatan'] != null && data['catatan'].isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.note, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            data['catatan'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Action Buttons - HAPUS TOMBOL PREVIEW, HANYA DETAIL DAN BUAT SURAT
                const SizedBox(height: 16),
                Row(
                  children: [
                    // HAPUS TOMBOL PREVIEW - SEKARANG HANYA 2 TOMBOL
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onTap,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryRed,
                          side: const BorderSide(color: _primaryRed),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text(
                          'DETAIL',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onGenerateSurat,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        icon: const Icon(Icons.description, size: 16),
                        label: const Text(
                          'BUAT SURAT',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
