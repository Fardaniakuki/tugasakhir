// ignore_for_file: curly_braces_in_flow_control_structures, empty_catches

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import '../../login/login_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
// Tambahkan ini di bagian atas file bersama import lainnya
import '../../../utils/pimpinan_storage.dart';

// Untuk web
class SiswaSelection {
  final int applicationId;
  final String nama;
  final String kelas;
  final String jurusan;
  final String industri;
  final int? industriId;
  final String nisn;
  final double rataRata;
  final String tanggalSelesai;

  // Field untuk data PIC Industri
  String? picNama;
  String? picNip;
  String? picJabatan; // TAMBAHKAN FIELD INI

  // Field untuk data detail
  List<Map<String, dynamic>>? formItems;
  List<Map<String, dynamic>>? nilaiItems;
  Map<String, dynamic>? detailData;
  Map<String, dynamic>? industriData;

  bool isSelected;

  SiswaSelection({
    required this.applicationId,
    required this.nama,
    required this.kelas,
    required this.jurusan,
    required this.industri,
    this.industriId,
    required this.nisn,
    required this.rataRata,
    required this.tanggalSelesai,
    this.formItems,
    this.nilaiItems,
    this.detailData,
    this.industriData,
    this.picNama,
    this.picNip,
    this.picJabatan, // TAMBAHKAN DI SINI
    this.isSelected = false,
  });
}

class KoordinatorReviewPenilaian extends StatefulWidget {
  const KoordinatorReviewPenilaian(
      {super.key, required ScrollController scrollController});

  @override
  State<KoordinatorReviewPenilaian> createState() =>
      _KoordinatorReviewPenilaianState();
}

class _KoordinatorReviewPenilaianState extends State<KoordinatorReviewPenilaian>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _reviewList = [];
  List<Map<String, dynamic>> _filteredReviewList = [];
  bool _isLoadingReview = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Filter
  int? _selectedKelasId;
  int? _selectedIndustriId;
  String? _selectedKelasNama; // Untuk menyimpan nama kelas yang dipilih
// Untuk menyimpan nama industri yang dipilih

  // Data untuk dropdown filter
  List<Map<String, dynamic>> _kelasList = [];
  List<Map<String, dynamic>> _industriList = [];

  bool _showFilters = false;

  // Mode selection untuk generate sertifikat
  bool _isSelectionMode = false;
  bool _selectAll = false;
  final List<SiswaSelection> _selectedSiswa = [];

  // Pagination Review
  int _currentPageReview = 1;
  int _totalItemsReview = 0;
  final int _itemsPerPage = 10;
  bool _isLoadingMoreReview = false;
  bool _hasMoreDataReview = true;

  // Data Form Penilaian
  List<Map<String, dynamic>> _formsList = [];
  List<Map<String, dynamic>> _filteredFormsList = [];
  bool _isLoadingForms = true;
  String _searchFormQuery = '';
  final TextEditingController _searchFormController = TextEditingController();

  // Pagination Form
  int _currentPageForm = 1;
  int _totalItemsForm = 0;
  bool _isLoadingMoreForm = false;
  bool _hasMoreDataForm = true;

  // Warna tema
  final Color _primaryColor = const Color(0xFF641E20);
  final Color _primaryLight = const Color(0xFFFCE8E8);
  final Color _successColor = const Color(0xFF2E7D32);
  final Color _warningColor = const Color(0xFFED6C02);
  final Color _neutralColor = const Color(0xFF757575);
  final Color _backgroundLight = const Color(0xFFF5F5F5);
  final Color _borderSoft = const Color(0xFFEEEEEE);
  final Color _cardColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);

    _fetchReviewList(reset: true);
    _fetchFormsList(reset: true);
    _fetchFilterOptions();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      FocusScope.of(context).unfocus();
    }

    // Keluar dari mode selection saat pindah tab
    if (_isSelectionMode) {
      setState(() {
        _isSelectionMode = false;
        _selectedSiswa.clear();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFormController.dispose();
    super.dispose();
  }

  // ==================== FUNGSI FORMAT TANGGAL ====================
  String _formatDateIndonesian(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';

    try {
      final date = DateTime.parse(dateString);

      const List<String> bulan = [
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
      return '-';
    }
  }

  // ==================== FUNGSI FILTER OPTIONS ====================
  Future<void> _fetchFilterOptions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) return;

    try {
      // Ambil data jurusan
      final jurusanResponse = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/master/jurusan'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (jurusanResponse.statusCode == 200) {
        jsonDecode(jurusanResponse.body);
        setState(() {});
      }
    } catch (e) {
      print('Error fetching filter options: $e');
    }
  }

  Future<void> _generateAndZipCertificates(
      List<SiswaSelection> selectedList, BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      _redirectToLogin();
      return;
    }

    try {
      _showSnackBar('Memulai proses membuat sertifikat...');

      // Prepare all certificates data
      final List<Map<String, dynamic>> certificatesData = [];
      int success = 0;
      int failed = 0;

      for (var i = 0; i < selectedList.length; i++) {
        final siswa = selectedList[i];
        _updateProgressDialog(context, i + 1, selectedList.length, siswa.nama);

        try {
          // Fetch detail data if not already fetched
          if (siswa.detailData == null) {
            final detailData = await _fetchSiswaDetailData(siswa.applicationId);
            if (detailData != null) {
              siswa.detailData = detailData;
              siswa.formItems = List<Map<String, dynamic>>.from(
                  detailData['form_items'] ?? []);
              siswa.nilaiItems =
                  List<Map<String, dynamic>>.from(detailData['items'] ?? []);

              // Ambil data industri untuk mendapatkan PIC
              final industriId = detailData['industri_id'];
              if (industriId != null) {
                final industriData = await _fetchIndustriData(industriId);
                if (industriData != null) {
                  siswa.industriData = industriData;
                  siswa.picNama = industriData['pic'];
                  siswa.picNip = industriData['pic_telp'] ?? '-';
                }
              }
            }
          }

          if (siswa.formItems != null && siswa.formItems!.isNotEmpty) {
            final fileUrl = await _generateCertificateAndGetUrl(siswa);
            if (fileUrl != null) {
              certificatesData.add({
                'url': fileUrl,
                'filename': 'sertifikat_${siswa.nama.replaceAll(' ', '_')}.pdf',
                'siswa': siswa.nama,
              });
              success++;
            } else {
              failed++;
            }
          } else {
            print('No form items for ${siswa.nama}');
            failed++;
          }
        } catch (e) {
          print('Error generating for ${siswa.nama}: $e');
          failed++;
        }
      }

      // Close progress dialog
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (certificatesData.isEmpty) {
        _showSnackBar('Tidak ada sertifikat yang berhasil dibuat',
            isError: true);
        return;
      }

      // Show summary
      _showSnackBar(
        'Selesai: $success berhasil, $failed gagal. Memproses ZIP...',
        isError: failed > 0,
      );

      // Create ZIP file locally
      await _requestZipCreation(certificatesData, context);
    } catch (e) {
      print('Error in zip generation: $e');
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      _showSnackBar('Gagal membuat ZIP: $e', isError: true);
    }
  }

  Future<void> _requestZipCreation(
      List<Map<String, dynamic>> certificatesData, BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      _redirectToLogin();
      return;
    }

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Membuat Berkas ZIP'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                'Mengunduh dan menggabungkan ${certificatesData.length} sertifikat...',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );

      // Download all PDF files first
      final List<File> downloadedFiles = [];
      // ignore: unused_local_variable
      int successCount = 0;

      for (var i = 0; i < certificatesData.length; i++) {
        final cert = certificatesData[i];

        try {
          // Download PDF file
          final response = await http.get(
            Uri.parse('${dotenv.env['SERTIF']}${cert['url']}'),
            headers: {
              'accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );

          if (response.statusCode == 200) {
            final directory = await getTemporaryDirectory();
            final file = File('${directory.path}/${cert['filename']}');
            await file.writeAsBytes(response.bodyBytes);
            downloadedFiles.add(file);
            successCount++;
          }
        } catch (e) {
          print('Error downloading ${cert['filename']}: $e');
        }
      }

      if (downloadedFiles.isEmpty) {
        throw Exception('Tidak ada file yang berhasil diunduh');
      }

      // Buat ZIP file di folder Downloads Android
      String? downloadsPath;

      // Coba dapatkan path Downloads yang benar untuk Android
      if (Platform.isAndroid) {
        // Path untuk Android 10+ (Scoped Storage)
        downloadsPath = '/storage/emulated/0/Download';

        // Cek apakah folder ada
        final downloadsDir = Directory(downloadsPath);
        if (!await downloadsDir.exists()) {
          // Fallback ke path alternatif
          downloadsPath = '/sdcard/Download';
        }
      }

      // Jika tidak bisa menentukan path Downloads, gunakan getExternalStorageDirectory
      Directory? saveDir;
      if (downloadsPath != null && await Directory(downloadsPath).exists()) {
        saveDir = Directory(downloadsPath);
      } else {
        // Fallback ke external storage directory
        saveDir = await getExternalStorageDirectory();
        saveDir ??= await getApplicationDocumentsDirectory();
      }

      final zipFileName =
          'sertifikat_pkl_${DateTime.now().millisecondsSinceEpoch}.zip';
      final zipFilePath = '${saveDir.path}/$zipFileName';

      await _createZipFile(downloadedFiles, zipFilePath);

      // Clean up individual PDF files
      for (var file in downloadedFiles) {
        try {
          await file.delete();
        } catch (e) {
          print('Error deleting file: $e');
        }
      }

      // Close loading dialog
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Tampilkan dialog sukses dengan opsi untuk membuka file
      final shouldOpen = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unduhan Selesai'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Berkas ZIP berhasil dibuat!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.archive_rounded, color: _primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            zipFileName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ukuran: ${_getFileSize(zipFilePath)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Tutup'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.folder_open_rounded, size: 18),
              label: const Text('Buka Berkas'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );

      if (shouldOpen == true) {
        // Buka file ZIP menggunakan open_file
        final result = await OpenFile.open(zipFilePath);

        if (result.type != ResultType.done) {
          // Jika gagal membuka, beri tahu user lokasi file
          _showSnackBar(
            'File tersimpan di:\n${saveDir.path}/$zipFileName',
            isError: true,
            duration: const Duration(seconds: 5),
          );
        }
      } else {
        // Jika user memilih tutup, tetap tampilkan notifikasi
        _showSnackBar(
          'Berkas ZIP tersimpan di folder undah',
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      print('Error creating ZIP: $e');
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      _showSnackBar('Gagal membuat ZIP: $e', isError: true);
    }
  }

// Helper function untuk mendapatkan ukuran file
  String _getFileSize(String filePath) {
    try {
      final file = File(filePath);
      final bytes = file.lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (e) {
      return '?';
    }
  }

  Future<void> _createZipFile(List<File> files, String outputZipPath) async {
    try {
      // Create a new ZipEncoder
      final encoder = ZipEncoder();

      // Create an archive
      final archive = Archive();

      // Add each file to the archive
      for (var file in files) {
        final bytes = await file.readAsBytes();
        archive.addFile(
            ArchiveFile(file.uri.pathSegments.last, bytes.length, bytes));
      }

      // Encode the archive
      final zipData = encoder.encode(archive);

      if (zipData == null) {
        throw Exception('Failed to encode ZIP');
      }

      // Write to file
      final zipFile = File(outputZipPath);
      await zipFile.writeAsBytes(zipData);
    } catch (e) {
      print('Error in _createZipFile: $e');
      rethrow;
    }
  }

  // Method untuk download ke Chrome
  Future<void> _downloadToChrome(String fileUrl, String filename) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      _redirectToLogin();
      return;
    }

    try {
      // Buat URL download dengan parameter
      final baseUrl = '${dotenv.env['SERTIF']}$fileUrl';
      final uri = Uri.parse(baseUrl);

      // Tambahkan token sebagai query parameter untuk otentikasi
      final downloadUri = uri.replace(queryParameters: {
        'token': token,
        'download': 'true',
        'filename': filename,
      });

      print('Membuka URL di browser: $downloadUri');

      // Buka di browser eksternal (Chrome)
      final bool launched = await launchUrl(
        downloadUri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );

      if (!launched) {
        throw Exception('Gagal membuka browser');
      }

      // Beri sedikit jeda agar browser punya waktu membuka tab
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      print('Error opening browser: $e');
      throw Exception('Gagal membuka browser: $e');
    }
  }

  Future<void> _fetchReviewList({bool reset = false}) async {
    if (reset) {
      setState(() {
        _isLoadingReview = true;
        _currentPageReview = 1;
        _reviewList.clear();
        _filteredReviewList.clear();
        _hasMoreDataReview = true;
        _selectedSiswa.clear();
        _selectAll = false;
      });
    } else {
      if (!_hasMoreDataReview || _isLoadingMoreReview) return;
      setState(() => _isLoadingMoreReview = true);
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      _redirectToLogin();
      return;
    }

    try {
      final queryParams = {
        'page': _currentPageReview.toString(),
        'limit': _itemsPerPage.toString(),
        if (_searchQuery.isNotEmpty) 'search': _searchQuery,
        // HAPUS parameter jurusan_id
        if (_selectedKelasId != null) 'kelas_id': _selectedKelasId.toString(),
        if (_selectedIndustriId != null)
          'industri_id': _selectedIndustriId.toString(),
      };

      final uri =
          Uri.parse('${dotenv.env['API_BASE_URL']}/api/penilaian/review')
              .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          if (reset) {
            _reviewList = List<Map<String, dynamic>>.from(data['data'] ?? []);
          } else {
            _reviewList
                .addAll(List<Map<String, dynamic>>.from(data['data'] ?? []));
          }

          _totalItemsReview = data['total'] ?? 0;
          _hasMoreDataReview = _reviewList.length < _totalItemsReview;
          _currentPageReview++;
          _applySearchFilter();
          _isLoadingReview = false;
          _isLoadingMoreReview = false;
        });
      } else if (response.statusCode == 401) {
        _redirectToLogin();
      } else {
        throw Exception('Gagal memuat data review penilaian');
      }
    } catch (e) {
      print('Error fetching review list: $e');
      if (mounted) {
        setState(() {
          _isLoadingReview = false;
          _isLoadingMoreReview = false;
        });
        _showSnackBar('Gagal memuat data review penilaian', isError: true);
      }
    }
  }

  void _applySearchFilter() {
    if (_searchQuery.isEmpty) {
      _filteredReviewList = List.from(_reviewList);
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredReviewList = _reviewList.where((review) {
        final nama = (review['siswa_username'] ?? '').toLowerCase();
        final industri = (review['industri_nama'] ?? '').toLowerCase();
        final kelas = (review['kelas_nama'] ?? '').toLowerCase();
        return nama.contains(query) ||
            industri.contains(query) ||
            kelas.contains(query);
      }).toList();
    }

    _updateFilterOptionsFromData();

    if (_isSelectionMode) {
      _updateSelectedSiswaFromFiltered();
    }
  }

  void _updateSelectedSiswaFromFiltered() {
    final Map<int, SiswaSelection> selectedMap = {};
    for (var s in _selectedSiswa) {
      selectedMap[s.applicationId] = s;
    }

    _selectedSiswa.clear();
    for (var review in _filteredReviewList) {
      final appId = review['application_id'];
      final rataRata =
          double.tryParse(review['rata_rata']?.toString() ?? '0') ?? 0;

      // AMBIL INDUSTRI_ID DARI DATA REVIEW
      final industriId = review['industri_id'];

      if (selectedMap.containsKey(appId)) {
        final existing = selectedMap[appId]!;
        _selectedSiswa.add(SiswaSelection(
          applicationId: existing.applicationId,
          nama: existing.nama,
          kelas: existing.kelas,
          jurusan: existing.jurusan,
          industri: existing.industri,
          industriId: existing.industriId ?? industriId,
          nisn: existing.nisn,
          rataRata: existing.rataRata,
          tanggalSelesai: existing.tanggalSelesai,
          formItems: existing.formItems,
          nilaiItems: existing.nilaiItems,
          detailData: existing.detailData,
          industriData: existing.industriData,
          picNama: existing.picNama,
          picNip: existing.picNip,
          picJabatan: existing.picJabatan, // TAMBAHKAN INI
          isSelected: true,
        ));
      } else {
        _selectedSiswa.add(SiswaSelection(
          applicationId: appId,
          nama: review['siswa_username'] ?? '',
          kelas: review['kelas_nama'] ?? '',
          jurusan: review['jurusan_nama'] ?? '',
          industri: review['industri_nama'] ?? '',
          industriId: industriId,
          nisn: review['siswa_nisn'] ?? '0123456789',
          rataRata: rataRata,
          tanggalSelesai: review['finalized_at'] ?? '',
          formItems: null,
          nilaiItems: null,
          detailData: null,
          industriData: null,
          picNama: null,
          picNip: null,
          picJabatan: null, // TAMBAHKAN INI
          isSelected: false,
        ));
      }
    }

    // Debug print
    print('📋 _selectedSiswa setelah update:');
    for (var s in _selectedSiswa) {
      print('   - ${s.nama}: industriId = ${s.industriId}');
    }
  }

  void _filterReview(String query) {
    setState(() {
      _searchQuery = query;
      _applySearchFilter();
    });
    _fetchReviewList(reset: true);
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  void _applyFilters() {
    // Konversi _selectedKelasNama ke _selectedKelasId (jika ada)
    if (_selectedKelasNama != null) {
      // Cari di data review untuk mendapatkan kelas_id
      final reviewWithKelas = _reviewList.firstWhere(
        (r) => r['kelas_nama'] == _selectedKelasNama,
        orElse: () => {},
      );
      if (reviewWithKelas.isNotEmpty) {
        _selectedKelasId = reviewWithKelas['kelas_id'];
      }
    } else {
      _selectedKelasId = null;
    }

    setState(() {
      _showFilters = false;
    });

    // Fetch ulang dengan filter baru
    _fetchReviewList(reset: true);
  }

  void _resetFilters() {
    setState(() {
      _selectedKelasId = null;
      _selectedIndustriId = null;
      _selectedKelasNama = null;
      _showFilters = false;

      // Reset industri list ke semua industri unik
      _industriList = _getUniqueIndustriesFromData();
    });

    // Reset filter dan refresh data
    _fetchReviewList(reset: true);
  }

  // ==================== FUNGSI SELECTION MODE ====================
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (_isSelectionMode) {
        _selectedSiswa.clear();
        _selectAll = false;
        _updateSelectedSiswaFromFiltered();
      } else {
        _selectedSiswa.clear();
        _selectAll = false;
      }
    });
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      for (var siswa in _selectedSiswa) {
        siswa.isSelected = _selectAll;
      }
    });
  }

  void _toggleSiswaSelection(int index, bool? value) {
    setState(() {
      if (index >= 0 && index < _selectedSiswa.length) {
        _selectedSiswa[index].isSelected = value ?? false;

        // Check if all are selected
        _selectAll = _selectedSiswa.every((s) => s.isSelected);
      }
    });
  }

  int _getSelectedCount() {
    return _selectedSiswa.where((s) => s.isSelected).length;
  }

  // ==================== FUNGSI GENERATE SERTIFIKAT MASSAL ====================
  String _getJurusanFromKelas(String? kelasNama) {
    if (kelasNama == null) return 'rpl';

    final kelasLower = kelasNama.toLowerCase();
    if (kelasLower.contains('dkv')) return 'dkv';
    if (kelasLower.contains('rpl')) return 'rpl';
    if (kelasLower.contains('tkj')) return 'tkj';
    if (kelasLower.contains('av')) return 'av';
    if (kelasLower.contains('bc')) return 'bc';
    if (kelasLower.contains('mt')) return 'mt';
    if (kelasLower.contains('an')) return 'an';
    if (kelasLower.contains('ei')) return 'ei';

    return 'rpl';
  }

  String _getHasilPKL(double average) {
    if (average >= 90) return 'Amat Baik';
    if (average >= 80) return 'Baik';
    if (average >= 70) return 'Cukup';
    return 'Perlu Peningkatan';
  }

  String _formatDate(DateTime date) {
    const months = [
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _generateMultipleCertificates() async {
    final selectedList = _selectedSiswa.where((s) => s.isSelected).toList();

    if (selectedList.isEmpty) {
      _showSnackBar('Pilih minimal 1 siswa', isError: true);
      return;
    }

    // DEBUG: Lihat data siswa yang dipilih
    print('\n========== DEBUG DATA SISWA TERPILIH ==========');
    for (var siswa in selectedList) {
      print('Siswa: ${siswa.nama}');
      print('  - industriId: ${siswa.industriId}');
      print('  - industri: ${siswa.industri}');
      print('  - applicationId: ${siswa.applicationId}');
      print('  - nisn: ${siswa.nisn}');
      print('  - rataRata: ${siswa.rataRata}');
    }
    print('===============================================\n');

    final downloadMethod = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Pilih Metode Unduh',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Pilih cara mengunduh sertifikat:',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF757575),
              ),
            ),
            const SizedBox(height: 20),
            _buildModernMethodOption(
              icon: Icons.archive_rounded,
              title: 'Arsip ZIP',
              description: 'Semua sertifikat digabung dalam satu berkas ZIP',
              value: 'zip',
            ),
            const SizedBox(height: 16),
            _buildModernMethodOption(
              icon: Icons.open_in_browser_rounded,
              title: 'Buka di Peramban',
              description:
                  'Setiap sertifikat terbuka otomatis di tab baru peramban',
              value: 'browser',
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF757575),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.2,
                      ),
                    ),
                    backgroundColor: Colors.white,
                    elevation: 0,
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (downloadMethod == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Konfirmasi',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Anda akan membuat ${selectedList.length} sertifikat.',
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF641E20).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        downloadMethod == 'zip'
                            ? Icons.archive_rounded
                            : Icons.open_in_browser_rounded,
                        color: const Color(0xFF641E20),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            downloadMethod == 'zip'
                                ? 'Metode: Arsip ZIP'
                                : 'Metode: Buka di Peramban',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            downloadMethod == 'zip'
                                ? 'Semua sertifikat akan digabung dalam satu berkas ZIP'
                                : 'Setiap sertifikat akan terbuka di tab baru peramban',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF757575),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF641E20),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Buat Sertifikat',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Tampilkan progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildProgressDialog(0, selectedList.length),
    );

    int success = 0;
    int failed = 0;

    // Ambil data untuk semua siswa
    for (var i = 0; i < selectedList.length; i++) {
      final siswa = selectedList[i];
      _updateProgressDialog(context, i + 1, selectedList.length, siswa.nama);

      try {
        print(
            '\n🔍 ===== MEMPROSES SISWA ${i + 1}/${selectedList.length}: ${siswa.nama} =====');

        // Fetch detail data dari API penilaian/review/{applicationId}
        print(
            '📡 Fetching detail data untuk applicationId: ${siswa.applicationId}');
        final detailData = await _fetchSiswaDetailData(siswa.applicationId);

        if (detailData != null) {
          print('✅ Detail data berhasil diambil');
          siswa.detailData = detailData;
          siswa.formItems =
              List<Map<String, dynamic>>.from(detailData['form_items'] ?? []);
          siswa.nilaiItems =
              List<Map<String, dynamic>>.from(detailData['items'] ?? []);

          print('📊 Form items: ${siswa.formItems?.length ?? 0}');
          print('📊 Nilai items: ${siswa.nilaiItems?.length ?? 0}');

          // AMBIL INDUSTRI_ID DARI OBJEK SISWA (YANG SUDAH DISIMPAN DARI REVIEW LIST)
          print('🏢 industri_id dari objek siswa: ${siswa.industriId}');

          if (siswa.industriId != null) {
            // Fetch data industri menggunakan industri_id dari objek siswa
            print('📡 Fetching data industri untuk ID: ${siswa.industriId}');
            final industriData = await _fetchIndustriData(siswa.industriId!);

            if (industriData != null) {
              siswa.industriData = industriData;

              // Ambil PIC name
              siswa.picNama = industriData['pic'];
              if (siswa.picNama == null || siswa.picNama!.isEmpty) {
                siswa.picNama = industriData['nama'] ?? '-';
              }

              // Ambil NIP - coba beberapa field
              siswa.picNip = industriData['nip'] ??
                  industriData['nip_pimpinan'] ??
                  industriData['no_telp'] ??
                  '-';

              print('✅ Data PIC untuk ${siswa.nama}:');
              print('   - Nama PIC: ${siswa.picNama}');
              print('   - NIP/No: ${siswa.picNip}');
              print('   - Raw industriData: ${jsonEncode(industriData)}');
            } else {
              print(
                  '❌ Gagal fetch data industri untuk id: ${siswa.industriId}');
            }
          } else {
            print('❌ industri_id null di objek siswa');
          }
        } else {
          print(
              '❌ Gagal fetch detailData untuk application: ${siswa.applicationId}');
        }

        // Generate sertifikat
        if (siswa.formItems != null && siswa.formItems!.isNotEmpty) {
          if (downloadMethod == 'zip') {
            // Untuk ZIP, kita kumpulkan dulu (akan diproses setelah loop)
            success++;
          } else {
            // Untuk browser, langsung generate satu per satu
            print('📄 Generating certificate for ${siswa.nama}...');
            final fileUrl = await _generateCertificateAndGetUrl(siswa);
            if (fileUrl != null) {
              print('✅ Certificate generated, downloading...');
              await _downloadToChrome(
                  fileUrl, 'sertifikat_${siswa.nama.replaceAll(' ', '_')}.pdf');
              await Future.delayed(const Duration(seconds: 1));
              success++;
            } else {
              print('❌ Gagal generate certificate');
              failed++;
            }
          }
        } else {
          print('❌ Form items kosong untuk ${siswa.nama}');
          failed++;
        }
      } catch (e) {
        print('❌ Error processing ${siswa.nama}: $e');
        failed++;
      }
    }

    if (downloadMethod == 'zip') {
      // Generate ZIP
      if (Navigator.canPop(context)) {
        Navigator.pop(context); // Tutup progress dialog
      }
      await _generateAndZipCertificates(selectedList, context);
    } else {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      _showSnackBar(
        'Selesai: $success berhasil, $failed gagal',
        isError: failed > 0,
      );
    }

    setState(() {
      _isSelectionMode = false;
      _selectedSiswa.clear();
      _selectAll = false;
    });
  }

  Widget _buildModernMethodOption({
    required IconData icon,
    required String title,
    required String description,
    required String value,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pop(context, value),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEEEEE)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF641E20).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF641E20),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF641E20).withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF641E20),
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _generateCertificateAndGetUrl(SiswaSelection siswa) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      _redirectToLogin();
      return null;
    }

    try {
      if (siswa.formItems == null || siswa.formItems!.isEmpty) {
        throw Exception('Data kompetensi tidak tersedia');
      }

      final rataRata = siswa.rataRata;
      final hasilPKL = _getHasilPKL(rataRata);
      final jurusan = _getJurusanFromKelas(siswa.kelas);

      final now = DateTime.now();
      final formattedDate = _formatDate(now);
      final nomorSertifikat =
          '420/${now.day}${now.month}${now.year}/101.6.9.19/${now.year}';

      // Ambil deskripsi dari form items (maksimal 4 kompetensi)
      final String desc1 = siswa.formItems!.isNotEmpty
          ? siswa.formItems![0]['tujuan_pembelajaran'] ?? 'Kompetensi 1'
          : 'Kompetensi 1';
      final String desc2 = siswa.formItems!.length > 1
          ? siswa.formItems![1]['tujuan_pembelajaran'] ?? 'Kompetensi 2'
          : 'Kompetensi 2';
      final String desc3 = siswa.formItems!.length > 2
          ? siswa.formItems![2]['tujuan_pembelajaran'] ?? 'Kompetensi 3'
          : 'Kompetensi 3';
      final String desc4 = siswa.formItems!.length > 3
          ? siswa.formItems![3]['tujuan_pembelajaran'] ?? 'Kompetensi 4'
          : 'Kompetensi 4';

      // Hitung skor dari nilai items
      int skor1 = 0, skor2 = 0, skor3 = 0, skor4 = 0;

      for (var i = 0; i < siswa.formItems!.length; i++) {
        final formItem = siswa.formItems![i];
        final nilaiItem = siswa.nilaiItems!.firstWhere(
          (item) => item['form_item_id'] == formItem['id'],
          orElse: () => {},
        );

        final skor = nilaiItem['skor'] ?? 0;

        if (i == 0)
          skor1 = skor;
        else if (i == 1)
          skor2 = skor;
        else if (i == 2)
          skor3 = skor;
        else if (i == 3) skor4 = skor;
      }

      // FORMAT TANGGAL
      String tanggalMulai = '';
      String tanggalSelesai = '';

      if (siswa.detailData != null) {
        tanggalMulai = siswa.detailData!['tanggal_mulai'] ??
            siswa.detailData!['start_date'] ??
            siswa.detailData!['mulai'] ??
            '';

        tanggalSelesai = siswa.detailData!['tanggal_selesai'] ??
            siswa.detailData!['end_date'] ??
            siswa.detailData!['selesai'] ??
            siswa.tanggalSelesai;
      }

      if (tanggalMulai.isEmpty) {
        try {
          if (siswa.tanggalSelesai.isNotEmpty) {
            final dateSelesai =
                DateTime.parse(siswa.tanggalSelesai.split(' ')[0]);
            final dateMulai = dateSelesai.subtract(const Duration(days: 180));
            tanggalMulai = _formatDate(dateMulai);
          } else {
            tanggalMulai =
                _formatDate(DateTime.now().subtract(const Duration(days: 180)));
          }
        } catch (e) {
          tanggalMulai =
              _formatDate(DateTime.now().subtract(const Duration(days: 180)));
        }
      } else {
        try {
          final dateMulai = DateTime.parse(tanggalMulai);
          tanggalMulai = _formatDate(dateMulai);
        } catch (e) {
          print('⚠️ Gagal parse tanggalMulai: $e');
        }
      }

      if (tanggalSelesai.isNotEmpty) {
        try {
          final dateSelesai = DateTime.parse(tanggalSelesai.split(' ')[0]);
          tanggalSelesai = _formatDate(dateSelesai);
        } catch (e) {
          print('⚠️ Gagal parse tanggalSelesai: $e');
        }
      } else {
        tanggalSelesai = formattedDate;
      }

      // ===== DATA INDUSTRI (PIMPINAN + PEMBIMBING INDUSTRI) =====
      print('\n📋 ===== DATA INDUSTRI UNTUK ${siswa.nama} =====');

      String namaPimpinan = '';
      String nipPimpinan = '';
      String jabatanPimpinan = '';

      String namaPembimbingIndustri = '';
      String nipPembimbingIndustri = '';
      String jabatanPembimbingIndustri = '';
      // Tambahkan ini
      print('🔍 CEK SHAREDPREFERENCES UNTUK APLIKASI ${siswa.applicationId}:');
      final prefs = await SharedPreferences.getInstance();
      prefs.getKeys().forEach((key) {
        if (key.startsWith('industri_')) {
          print('   - Key: $key');
        }
      });

      // AMBIL HANYA DARI SHAREDPREFERENCES (INPUT PEMBIMBING)
      print('📡 Mencari data industri di SharedPreferences...');
      final industriData =
          await PimpinanStorage.ambilDataIndustri(siswa.applicationId);

      if (industriData != null) {
        // Data Pimpinan Industri
        namaPimpinan = industriData['pimpinan']?['nama'] ?? '';
        nipPimpinan = industriData['pimpinan']?['nip'] ?? '-';
        jabatanPimpinan = industriData['pimpinan']?['jabatan'] ?? '';

        // Data Pembimbing Industri
        namaPembimbingIndustri =
            industriData['pembimbing_industri']?['nama'] ?? '';
        nipPembimbingIndustri =
            industriData['pembimbing_industri']?['nip'] ?? '-';
        jabatanPembimbingIndustri =
            industriData['pembimbing_industri']?['jabatan'] ?? '';

        print('✅ Data industri ditemukan di SharedPreferences:');
        print('   - Pimpinan: $namaPimpinan ($jabatanPimpinan)');
        print(
            '   - Pembimbing Industri: $namaPembimbingIndustri ($jabatanPembimbingIndustri)');
        print('   - Waktu simpan: ${industriData['waktu_simpan']}');
      } else {
        // Jika tidak ada data di SharedPreferences
        print('❌ TIDAK ADA DATA INDUSTRI DI SHAREDPREFERENCES!');
        print(
            '❌ Pembimbing belum menginput data untuk aplikasi ID: ${siswa.applicationId}');

        // Throw exception agar proses generate gagal
        throw Exception(
            'Data pimpinan dan pembimbing industri belum diinput oleh pembimbing');
      }

      // ===== DATA PEMBIMBING SEKOLAH (KOORDINATOR) =====
      print('\n📋 ===== DATA PEMBIMBING SEKOLAH =====');

      String namaPembimbingSekolah = '';
      String nipPembimbingSekolah = '';
      String jabatanPembimbingSekolah = '';

      // Coba ambil data guru berdasarkan user_id
      final userId = prefs.getInt('user_id');
      if (userId != null) {
        try {
          final guruResponse = await http.get(
            Uri.parse(
                '${dotenv.env['API_BASE_URL']}/api/guru?user_id=$userId&limit=1'),
            headers: {
              'accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );

          if (guruResponse.statusCode == 200) {
            final guruData = jsonDecode(guruResponse.body);
            if (guruData['success'] == true &&
                guruData['data']['data'] != null &&
                guruData['data']['data'].isNotEmpty) {
              final guru = guruData['data']['data'][0];
              namaPembimbingSekolah = guru['nama'] ?? '';
              nipPembimbingSekolah = guru['nip'] ?? '';

              // Tentukan jabatan berdasarkan role
              if (guru['is_koordinator'] == true) {
                jabatanPembimbingSekolah = 'Koordinator PKL';
              } else if (guru['is_pembimbing'] == true) {
                jabatanPembimbingSekolah = 'Guru Pembimbing PKL';
              } else if (guru['is_wali_kelas'] == true) {
                jabatanPembimbingSekolah = 'Wali Kelas';
              } else {
                jabatanPembimbingSekolah = 'Guru';
              }

              print('✅ Data guru ditemukan:');
              print('   - Nama: $namaPembimbingSekolah');
              print('   - NIP: $nipPembimbingSekolah');
              print('   - Jabatan: $jabatanPembimbingSekolah');
            }
          }
        } catch (e) {
          print('❌ Error fetching guru data: $e');
        }
      }

      // Jika data guru tidak ditemukan, pakai dari SharedPreferences
      if (namaPembimbingSekolah.isEmpty) {
        print('⚠️ Menggunakan data dari SharedPreferences');
        namaPembimbingSekolah =
            prefs.getString('user_name') ?? 'Guru Pembimbing PKL';
        nipPembimbingSekolah = prefs.getString('user_nip') ?? '-';
        jabatanPembimbingSekolah =
            prefs.getString('user_jabatan') ?? 'Guru Pembimbing PKL';

        print('   - Nama: $namaPembimbingSekolah');
        print('   - NIP: $nipPembimbingSekolah');
        print('   - Jabatan: $jabatanPembimbingSekolah');
      }

      // ===== GABUNGKAN SEMUA DATA UNTUK API =====
      final Map<String, dynamic> requestBody = {
        'nomor_sertifikat': nomorSertifikat,
        'siswa': {
          'nama': siswa.nama,
          'nisn': siswa.nisn,
        },
        'nama_industri': siswa.industri,
        'tanggal_mulai': tanggalMulai,
        'tanggal_selesai': tanggalSelesai,
        'hasil_pkl': hasilPKL,
        'tanggal_terbit': formattedDate,
        'nilai': {
          'aspek_1': skor1,
          'desc_1': desc1,
          'aspek_2': skor2,
          'desc_2': desc2,
          'aspek_3': skor3,
          'desc_3': desc3,
          'aspek_4': skor4,
          'desc_4': desc4,
        },
        // Data Pimpinan Industri
        'nama_pimpinan': namaPimpinan,
        'nip_pimpinan': nipPimpinan,
        'jabatan_pimpinan': jabatanPimpinan,

        // Data Pembimbing Industri
        'nama_pembimbing': namaPembimbingIndustri,
        'nip_pembimbing': nipPembimbingIndustri,
        'jabatan_pembimbing': jabatanPembimbingIndustri,

        // Data Pembimbing Sekolah (Koordinator)
        'nama_pembimbing_sekolah': namaPembimbingSekolah,
        'nip_pembimbing_sekolah': nipPembimbingSekolah,
        'jabatan_pembimbing_sekolah': jabatanPembimbingSekolah,
      };

      print('\n📤 ===== REQUEST BODY FINAL =====');
      print(jsonEncode(requestBody));
      print('===============================\n');

      // Kirim request ke API sertifikat
      final response = await http.post(
        Uri.parse('${dotenv.env['SERTIF']}/api/v1/letters/sertifikat/$jurusan'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Sertifikat berhasil dibuat: ${data['file_url']}');
        return data['file_url'];
      } else {
        print('❌ Error response: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        throw Exception('Gagal membuat sertifikat: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error generating certificate: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchSiswaDetailData(int applicationId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      _redirectToLogin();
      return null;
    }

    try {
      final url =
          '${dotenv.env['API_BASE_URL']}/api/penilaian/review/$applicationId';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Pastikan data industri_id tersedia
        print('✅ Detail data untuk application $applicationId:');
        print('   - industri_id: ${data['industri_id']}');
        print('   - form_items: ${data['form_items']?.length ?? 0}');
        print('   - items: ${data['items']?.length ?? 0}');

        return data;
      }
    } catch (e) {
      print('Error fetching detail for application $applicationId: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> _fetchIndustriData(int industriId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      print('❌ Token tidak tersedia untuk fetch industri');
      _redirectToLogin();
      return null;
    }

    try {
      final url = '${dotenv.env['API_BASE_URL']}/api/industri/$industriId';
      print('📡 Fetching industri data from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Industri Response status: ${response.statusCode}');
      print('📡 Industri Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // API mengembalikan struktur: { "success": true, "data": { ... } }
        if (responseData['success'] == true && responseData['data'] != null) {
          final industriData = responseData['data'] as Map<String, dynamic>;

          print('✅ Data industri ditemukan:');
          print('   - Nama: ${industriData['nama']}');
          print('   - PIC: ${industriData['pic']}');
          print('   - Jabatan: ${industriData['jabatan']}'); // CEK INI
          print('   - No Telp: ${industriData['no_telp']}');
          print('   - Email: ${industriData['email']}');

          return industriData;
        } else {
          print('❌ Response success false atau data null');
        }
      } else {
        print('❌ Gagal fetch industri: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching industri data for id $industriId: $e');
    }
    return null;
  }

  void _updateFilterOptionsFromData() {
    if (_reviewList.isEmpty) return;

    final Set<String> kelasSet = {};
    final Map<String, Map<int, String>> industriPerKelas = {};

    for (var review in _reviewList) {
      final kelas = review['kelas_nama']?.toString();
      final industriNama = review['industri_nama']?.toString();
      final industriId = review['industri_id'];

      if (kelas != null && kelas.isNotEmpty) {
        kelasSet.add(kelas);

        if (!industriPerKelas.containsKey(kelas)) {
          industriPerKelas[kelas] = {};
        }
        if (industriNama != null &&
            industriNama.isNotEmpty &&
            industriId != null) {
          industriPerKelas[kelas]![industriId] = industriNama;
        }
      }
    }

    final kelasList = kelasSet.toList()..sort();

    final List<Map<String, dynamic>> newKelasList = [];
    for (var kelas in kelasList) {
      final industriMap = industriPerKelas[kelas] ?? {};
      final industriList = industriMap.entries.map((entry) {
        return {
          'id': entry.key,
          'nama': entry.value,
        };
      }).toList();

      // PERBAIKAN: gunakan where dan sorting manual
      industriList.sort((a, b) {
        // Pastikan nilai tidak null dengan memberikan default string kosong
        final namaA = a['nama'] == null ? '' : a['nama'] as String;
        final namaB = b['nama'] == null ? '' : b['nama'] as String;
        return namaA.compareTo(namaB);
      });

      newKelasList.add({
        'nama': kelas,
        'industri': industriList,
      });
    }

    setState(() {
      _kelasList = newKelasList;

      if (_selectedKelasNama != null) {
        final selectedKelas = _kelasList.firstWhere(
          (k) => k['nama'] == _selectedKelasNama,
          orElse: () => {'industri': []},
        );
        _industriList =
            List<Map<String, dynamic>>.from(selectedKelas['industri'] ?? []);
      } else {
        _industriList = _getUniqueIndustriesFromData();
      }
    });
  }

  List<Map<String, dynamic>> _getUniqueIndustriesFromData() {
    final Map<int, String> industriMap = {};

    for (var review in _reviewList) {
      final industriId = review['industri_id'];
      final industriNama = review['industri_nama']?.toString();

      if (industriId != null &&
          industriNama != null &&
          industriNama.isNotEmpty) {
        industriMap[industriId] = industriNama;
      }
    }

    final result = industriMap.entries
        .map((entry) => {
              'id': entry.key,
              'nama': entry.value,
            })
        .toList();

    // PERBAIKAN: sorting manual dengan null check
    result.sort((a, b) {
      final namaA = a['nama'] == null ? '' : a['nama'] as String;
      final namaB = b['nama'] == null ? '' : b['nama'] as String;
      return namaA.compareTo(namaB);
    });

    return result;
  }

  void _onKelasSelected(String? kelasNama) {
    setState(() {
      _selectedKelasNama = kelasNama;
      _selectedIndustriId = null;

      // Filter industri berdasarkan kelas yang dipilih
      if (kelasNama != null) {
        final selectedKelas = _kelasList.firstWhere(
          (k) => k['nama'] == kelasNama,
          orElse: () => {'industri': []},
        );
        _industriList =
            List<Map<String, dynamic>>.from(selectedKelas['industri'] ?? []);
      } else {
        // Jika semua kelas, tampilkan semua industri dari data
        _industriList = _getUniqueIndustriesFromData();
      }
    });

    // HAPUS PANGGILAN _applyFilters() DARI SINI
    // _applyFilters(); // <-- JANGAN PANGGIL DI SINI (SUDAH DIHAPUS)
  }

  // ==================== FUNGSI FORM PENILAIAN ====================
  Future<void> _fetchFormsList({bool reset = false}) async {
    if (reset) {
      setState(() {
        _isLoadingForms = true;
        _currentPageForm = 1;
        _formsList.clear();
        _filteredFormsList.clear();
        _hasMoreDataForm = true;
      });
    } else {
      if (!_hasMoreDataForm || _isLoadingMoreForm) return;
      setState(() => _isLoadingMoreForm = true);
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      _redirectToLogin();
      return;
    }

    try {
      final queryParams = {
        'page': _currentPageForm.toString(),
        'limit': _itemsPerPage.toString(),
        if (_searchFormQuery.isNotEmpty) 'search': _searchFormQuery,
      };

      final uri = Uri.parse('${dotenv.env['API_BASE_URL']}/api/penilaian/forms')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          if (reset) {
            _formsList = List<Map<String, dynamic>>.from(data['data'] ?? []);
          } else {
            _formsList
                .addAll(List<Map<String, dynamic>>.from(data['data'] ?? []));
          }

          _totalItemsForm = data['total'] ?? 0;
          _hasMoreDataForm = _formsList.length < _totalItemsForm;
          _currentPageForm++;
          _applyFormSearchFilter();
          _isLoadingForms = false;
          _isLoadingMoreForm = false;
        });
      } else if (response.statusCode == 401) {
        _redirectToLogin();
      } else {
        throw Exception('Gagal memuat data form penilaian');
      }
    } catch (e) {
      print('Error fetching forms list: $e');
      if (mounted) {
        setState(() {
          _isLoadingForms = false;
          _isLoadingMoreForm = false;
        });
        _showSnackBar('Gagal memuat data form penilaian', isError: true);
      }
    }
  }

  void _applyFormSearchFilter() {
    if (_searchFormQuery.isEmpty) {
      _filteredFormsList = List.from(_formsList);
    } else {
      final query = _searchFormQuery.toLowerCase();
      _filteredFormsList = _formsList.where((form) {
        final nama = (form['nama'] ?? '').toLowerCase();
        return nama.contains(query);
      }).toList();
    }
  }

  void _filterForms(String query) {
    setState(() {
      _searchFormQuery = query;
      _applyFormSearchFilter();
    });
    _fetchFormsList(reset: true);
  }

  Future<void> _activateForm(int formId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aktifkan Form'),
        content: const Text(
            'Form yang aktif akan digunakan untuk penilaian PKL. Lanjutkan?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: _neutralColor,
            ),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _successColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Aktifkan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      _redirectToLogin();
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(
            '${dotenv.env['API_BASE_URL']}/api/penilaian/forms/$formId/activate'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _showSnackBar('Form berhasil diaktifkan');
        _fetchFormsList(reset: true);
      } else {
        throw Exception('Gagal mengaktifkan form');
      }
    } catch (e) {
      print('Error activating form: $e');
      _showSnackBar('Gagal mengaktifkan form', isError: true);
    }
  }

  void _navigateToFormDetail(Map<String, dynamic>? formData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormDetailScreen(
          formData: formData,
          onFormSaved: () => _fetchFormsList(reset: true),
        ),
      ),
    );
  }

  // ==================== FUNGSI UMUM ====================
  void _redirectToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showSnackBar(String message,
      {bool isError = false, Duration? duration}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : _primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: duration ?? const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToDetail(Map<String, dynamic> review) {
    if (_isSelectionMode) {
      setState(() {
        _isSelectionMode = false;
        _selectedSiswa.clear();
      });
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewDetailScreen(
          applicationId: review['application_id'],
          reviewData: review,
        ),
      ),
    );
  }

  Color _getScoreTextColor(double score) {
    if (score >= 90) return _successColor;
    if (score >= 75) return _warningColor;
    return Colors.red;
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'S';
    final parts = name.split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  // ==================== BUILD WIDGET ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundLight,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
            decoration: BoxDecoration(
              color: _primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.rate_review_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Penilaian PKL',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tinjau & Formulir Penilaian',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  height: 45,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.white,
                    ),
                    labelColor: _primaryColor,
                    unselectedLabelColor: Colors.white,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    tabs: const [
                      Tab(text: 'Tinjau Nilai'),
                      Tab(text: 'Formulir Penilaian'),
                    ],
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    splashBorderRadius: BorderRadius.circular(30),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildReviewTab(),
                _buildFormTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

// ==================== TAB REVIEW PENILAIAN ====================
  Widget _buildReviewTab() {
    return RefreshIndicator(
      onRefresh: () => _fetchReviewList(reset: true),
      color: _primaryColor,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search bar dan tombol select
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: _filterReview,
                                  decoration: InputDecoration(
                                    hintText: 'Cari siswa, kelas, industri',
                                    hintStyle:
                                        TextStyle(color: Colors.grey[400]),
                                    prefixIcon: Icon(Icons.search_rounded,
                                        color: _primaryColor),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                height: 46,
                                width: 1,
                                color: _borderSoft,
                              ),
                              IconButton(
                                icon: Icon(
                                  _showFilters
                                      ? Icons.filter_alt_off_rounded
                                      : Icons.filter_alt_rounded,
                                  color: _primaryColor,
                                ),
                                onPressed: _toggleFilters,
                                tooltip: 'Filter',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color:
                              _isSelectionMode ? _primaryColor : Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.select_all_rounded,
                            color:
                                _isSelectionMode ? Colors.white : _primaryColor,
                          ),
                          onPressed: _toggleSelectionMode,
                          tooltip: _isSelectionMode
                              ? 'Keluar mode pilih'
                              : 'Pilih siswa untuk sertifikat',
                        ),
                      ),
                    ],
                  ),

                  // FILTER SECTION
                  if (_showFilters) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(
                          color: _primaryColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header dengan jumlah filter aktif
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: _primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.filter_alt_rounded,
                                  color: _primaryColor,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Filter',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _primaryColor,
                                ),
                              ),
                              const Spacer(),
                              if (_selectedKelasNama != null ||
                                  _selectedIndustriId != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _primaryColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${(_selectedKelasNama != null ? 1 : 0) + (_selectedIndustriId != null ? 1 : 0)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Dropdown Kelas
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _selectedKelasNama != null
                                    ? _primaryColor
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: DropdownButtonFormField<String?>(
                              value: _selectedKelasNama,
                              decoration: InputDecoration(
                                labelText: 'Kelas',
                                labelStyle: TextStyle(
                                  color: _selectedKelasNama != null
                                      ? _primaryColor
                                      : Colors.grey.shade600,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                prefixIcon: Icon(
                                  Icons.class_rounded,
                                  size: 18,
                                  color: _selectedKelasNama != null
                                      ? _primaryColor
                                      : Colors.grey.shade400,
                                ),
                              ),
                              icon: Icon(
                                Icons.arrow_drop_down_rounded,
                                color: _primaryColor,
                              ),
                              dropdownColor: Colors.white,
                              isExpanded: true,
                              items: [
                                DropdownMenuItem<String?>(
                                  value: null,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.clear_all_rounded,
                                        size: 16,
                                        color: Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Semua Kelas',
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ..._kelasList.map((k) {
                                  final namaKelas = k['nama'] ?? '';
                                  return DropdownMenuItem<String?>(
                                    value: namaKelas,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 4,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: _primaryColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            namaKelas,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedKelasNama = value;
                                  if (value != null) {
                                    // Filter industri berdasarkan kelas yang dipilih
                                    final selectedKelas = _kelasList.firstWhere(
                                      (k) => k['nama'] == value,
                                      orElse: () => {'industri': []},
                                    );
                                    _industriList =
                                        List<Map<String, dynamic>>.from(
                                            selectedKelas['industri'] ?? []);
                                  } else {
                                    // Jika semua kelas, tampilkan semua industri
                                    _industriList =
                                        _getUniqueIndustriesFromData();
                                  }
                                });
                                _applyFilters();
                              },
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Dropdown Industri - BISA DIPILIH TANPA MEMILIH KELAS
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _selectedIndustriId != null
                                    ? _primaryColor
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: DropdownButtonFormField<int?>(
                              value: _selectedIndustriId,
                              decoration: InputDecoration(
                                labelText: 'Industri/DUDI',
                                labelStyle: TextStyle(
                                  color: _selectedIndustriId != null
                                      ? _primaryColor
                                      : Colors.grey.shade600,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                prefixIcon: Icon(
                                  Icons.business_center_rounded,
                                  size: 18,
                                  color: _selectedIndustriId != null
                                      ? _primaryColor
                                      : Colors.grey.shade400,
                                ),
                              ),
                              icon: Icon(
                                Icons.arrow_drop_down_rounded,
                                color: _primaryColor,
                              ),
                              dropdownColor: Colors.white,
                              isExpanded: true,
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Row(
                                    children: [
                                      Icon(Icons.clear_all_rounded,
                                          size: 16, color: Colors.grey),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Semua Industri',
                                          style: TextStyle(color: Colors.grey),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ..._industriList.map((i) {
                                  final namaIndustri = i['nama'] ?? '';
                                  return DropdownMenuItem<int?>(
                                    value: i['id'],
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 4,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: _primaryColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            namaIndustri,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                        // Badge jumlah
                                        if (_reviewList
                                            .where((r) =>
                                                r['industri_id'] == i['id'])
                                            .isNotEmpty)
                                          Container(
                                            margin:
                                                const EdgeInsets.only(left: 4),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _primaryColor.withValues(
                                                  alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '${_reviewList.where((r) => r['industri_id'] == i['id']).length}',
                                              style: TextStyle(
                                                fontSize: 8,
                                                color: _primaryColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedIndustriId = value;
                                });
                                _applyFilters(); // LANGSUNG FILTER SAAT INDUSTRI DIPILIH
                              },
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Informasi jumlah data dan tombol reset
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _primaryColor.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 14,
                                  color: _primaryColor,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${_filteredReviewList.length} data ditampilkan',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _primaryColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (_selectedKelasNama != null ||
                                    _selectedIndustriId != null)
                                  TextButton(
                                    onPressed: _resetFilters,
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(40, 30),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'Reset',
                                      style: TextStyle(
                                        color: _primaryColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // SELECTION MODE INFO
                  if (_isSelectionMode) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _primaryColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _selectAll,
                            onChanged: _toggleSelectAll,
                            activeColor: _primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Pilih Semua',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _primaryColor,
                            ),
                          ),
                          const Spacer(),
                          if (_getSelectedCount() > 0)
                            ElevatedButton.icon(
                              onPressed: _generateMultipleCertificates,
                              icon: const Icon(Icons.picture_as_pdf, size: 16),
                              label: Text(
                                'Buat ${_getSelectedCount()} Sertifikat',
                                style: const TextStyle(fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // LIST VIEW
          _isLoadingReview && _reviewList.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  ),
                )
              : _filteredReviewList.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withValues(alpha: 0.2),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.rate_review_outlined,
                                size: 50,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Tidak ada hasil yang cocok'
                                  : 'Belum ada review penilaian',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              TextButton(
                                onPressed: () {
                                  _searchController.clear();
                                  _filterReview('');
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: _primaryColor,
                                ),
                                child: const Text('Reset Pencarian'),
                              ),
                          ],
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index >= _filteredReviewList.length - 2 &&
                              _hasMoreDataReview &&
                              !_isLoadingMoreReview) {
                            _fetchReviewList();
                          }
                          final review = _filteredReviewList[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: _isSelectionMode
                                ? _buildSelectableReviewCard(review, index)
                                : _buildReviewCard(review),
                          );
                        },
                        childCount: _filteredReviewList.length,
                      ),
                    ),

          // LOADING MORE INDICATOR
          if (_isLoadingMoreReview)
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(color: _primaryColor),
                ),
              ),
            ),

          // BOTTOM SPACING
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDialog(int current, int total, [String? currentName]) {
    return AlertDialog(
      title: const Text('Memproses Sertifikat'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            'Progress: $current dari $total',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (currentName != null)
            Text(
              'Sedang memproses:\n$currentName',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
        ],
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  void _updateProgressDialog(
      BuildContext context, int current, int total, String currentName) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildProgressDialog(current, total, currentName),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final double rataRata =
        double.tryParse(review['rata_rata']?.toString() ?? '0') ?? 0;
    final Color scoreColor = _getScoreTextColor(rataRata);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToDetail(review),
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _borderSoft),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _primaryColor.withValues(alpha: 0.2),
                            _primaryColor.withValues(alpha: 0.1)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(review['siswa_username'] ?? 'S'),
                          style: TextStyle(
                            color: _primaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review['siswa_username'] ?? 'Tanpa Nama',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              review['kelas_nama'] ?? '-',
                              style: TextStyle(
                                color: _primaryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(height: 1, color: _borderSoft),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Industri',
                            style: TextStyle(
                              fontSize: 11,
                              color: _neutralColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            review['industri_nama'] ?? '-',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: _primaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: scoreColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Rata-rata',
                            style: TextStyle(
                              fontSize: 9,
                              color: scoreColor,
                            ),
                          ),
                          Text(
                            rataRata.toStringAsFixed(1),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: scoreColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: _neutralColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Selesai: ${_formatDateIndonesian(review['finalized_at'])}',
                      style: TextStyle(
                        fontSize: 11,
                        color: _neutralColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Total: ${review['total_skor'] ?? 0}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: _primaryColor,
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

  Widget _buildSelectableReviewCard(
      Map<String, dynamic> review, int listIndex) {
    final double rataRata =
        double.tryParse(review['rata_rata']?.toString() ?? '0') ?? 0;
    final Color scoreColor = _getScoreTextColor(rataRata);

    final siswaIndex = _selectedSiswa
        .indexWhere((s) => s.applicationId == review['application_id']);

    final bool isSelected =
        siswaIndex >= 0 && _selectedSiswa[siswaIndex].isSelected;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? _primaryColor : _borderSoft,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          if (siswaIndex >= 0) {
            _toggleSiswaSelection(siswaIndex, !isSelected);
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (value) {
                  if (siswaIndex >= 0) {
                    _toggleSiswaSelection(siswaIndex, value);
                  }
                },
                activeColor: _primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _primaryColor.withValues(alpha: 0.2),
                                _primaryColor.withValues(alpha: 0.1)
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              _getInitials(review['siswa_username'] ?? 'S'),
                              style: TextStyle(
                                color: _primaryColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                review['siswa_username'] ?? 'Tanpa Nama',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                review['kelas_nama'] ?? '-',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _neutralColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                review['industri_nama'] ?? '-',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Rata-rata: ',
                            style: TextStyle(
                              fontSize: 10,
                              color: scoreColor,
                            ),
                          ),
                          Text(
                            rataRata.toStringAsFixed(1),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: scoreColor,
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
      ),
    );
  }

  // ==================== TAB FORM PENILAIAN ====================
  Widget _buildFormTab() {
    return RefreshIndicator(
      onRefresh: () => _fetchFormsList(reset: true),
      color: _primaryColor,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchFormController,
                            onChanged: _filterForms,
                            decoration: InputDecoration(
                              hintText: 'Cari nama form',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              prefixIcon: Icon(Icons.search_rounded,
                                  color: _primaryColor),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: _primaryColor,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryColor.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add_rounded,
                              color: Colors.white),
                          onPressed: () => _navigateToFormDetail(null),
                          tooltip: 'Buat Form Baru',
                          iconSize: 28,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _isLoadingForms && _formsList.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  ),
                )
              : _filteredFormsList.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withValues(alpha: 0.2),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.assignment_outlined,
                                size: 50,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _searchFormQuery.isNotEmpty
                                  ? 'Tidak ada form yang cocok'
                                  : 'Belum ada form penilaian',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_searchFormQuery.isNotEmpty)
                              TextButton(
                                onPressed: () {
                                  _searchFormController.clear();
                                  _filterForms('');
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: _primaryColor,
                                ),
                                child: const Text('Reset Pencarian'),
                              ),
                            if (_searchFormQuery.isEmpty)
                              ElevatedButton(
                                onPressed: () => _navigateToFormDetail(null),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text('Buat Form Baru'),
                              ),
                          ],
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index >= _filteredFormsList.length - 2 &&
                              _hasMoreDataForm &&
                              !_isLoadingMoreForm) {
                            _fetchFormsList();
                          }
                          final form = _filteredFormsList[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: _buildFormCard(form),
                          );
                        },
                        childCount: _filteredFormsList.length,
                      ),
                    ),
          if (_isLoadingMoreForm)
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(color: _primaryColor),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFormCard(Map<String, dynamic> form) {
    final bool isActive = form['is_active'] == true;
    final int itemCount = form['items']?.length ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToFormDetail(form),
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive ? _successColor : _borderSoft,
                width: isActive ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isActive
                              ? [
                                  _successColor.withValues(alpha: 0.2),
                                  _successColor.withValues(alpha: 0.1)
                                ]
                              : [
                                  _primaryColor.withValues(alpha: 0.2),
                                  _primaryColor.withValues(alpha: 0.1)
                                ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(form['nama'] ?? 'F'),
                          style: TextStyle(
                            color: isActive ? _successColor : _primaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            form['nama'] ?? 'Tanpa Nama',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _neutralColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.list_alt_rounded,
                                      size: 12,
                                      color: _neutralColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$itemCount kompetensi',
                                      style: TextStyle(
                                        color: _neutralColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _neutralColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.update_rounded,
                                      size: 12,
                                      color: _neutralColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDateIndonesian(form['updated_at']),
                                      style: TextStyle(
                                        color: _neutralColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? _successColor.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive
                              ? _successColor.withValues(alpha: 0.3)
                              : Colors.grey.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isActive
                                ? Icons.check_circle_rounded
                                : Icons.pause_circle_outline_rounded,
                            size: 10,
                            color: isActive ? _successColor : Colors.grey,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            isActive ? 'Aktif' : 'Tidak',
                            style: TextStyle(
                              color: isActive ? _successColor : Colors.grey,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: _borderSoft),
                const SizedBox(height: 12),
                if (itemCount > 0) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(
                      itemCount > 3 ? 3 : itemCount,
                      (i) {
                        final item = form['items'][i];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _primaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Kompetensi ${item['urutan'] ?? i + 1}',
                            style: TextStyle(
                              color: _primaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (itemCount > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '+${itemCount - 3} kompetensi lainnya',
                        style: TextStyle(
                          color: _neutralColor,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!isActive)
                      TextButton.icon(
                        onPressed: () => _activateForm(form['id']),
                        icon: const Icon(Icons.power_settings_new_rounded,
                            size: 14),
                        label: const Text('Aktifkan',
                            style: TextStyle(fontSize: 11)),
                        style: TextButton.styleFrom(
                          foregroundColor: _successColor,
                          backgroundColor: _successColor.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    if (!isActive) const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Detail',
                            style: TextStyle(
                              color: _primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 12,
                            color: _primaryColor,
                          ),
                        ],
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

extension on Directory? {}

// ==================== HALAMAN DETAIL REVIEW ====================
class ReviewDetailScreen extends StatefulWidget {
  final int applicationId;
  final Map<String, dynamic> reviewData;

  const ReviewDetailScreen({
    super.key,
    required this.applicationId,
    required this.reviewData,
  });

  @override
  State<ReviewDetailScreen> createState() => _ReviewDetailScreenState();
}

class _ReviewDetailScreenState extends State<ReviewDetailScreen> {
  bool _isLoading = true;
  bool _isGeneratingCertificate = false;
  Map<String, dynamic>? _detailData;
  List<Map<String, dynamic>> _formItems = [];
  List<Map<String, dynamic>> _nilaiItems = [];

  late Map<String, dynamic> _siswaData;

  final Color _primaryColor = const Color(0xFF641E20);
  final Color _primaryLight = const Color(0xFFFCE8E8);
  final Color _successColor = const Color(0xFF2E7D32);
  final Color _warningColor = const Color(0xFFED6C02);
  final Color _neutralColor = const Color(0xFF757575);
  final Color _backgroundLight = const Color(0xFFF5F5F5);
  final Color _borderSoft = const Color(0xFFEEEEEE);

  @override
  void initState() {
    super.initState();
    _siswaData = widget.reviewData;
    _fetchDetailData();
  }

  // ==================== FUNGSI FORMAT TANGGAL ====================
  String _formatDateIndonesian(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';

    try {
      final date = DateTime.parse(dateString);
      const List<String> bulan = [
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
      return '-';
    }
  }

  String _getPredikatFromSkor(int skor) {
    if (skor >= 86) return 'Sangat Baik';
    if (skor >= 75) return 'Baik';
    return 'Kurang'; // < 75
  }

  String _getSoftSkillDescription(int skor) {
    final predikat = _getPredikatFromSkor(skor);
    if (predikat == 'Sangat Baik') {
      return 'Peserta didik mampu menerapkan soft skill yang dimiliki dengan menunjukkan integritas (jujur, disiplin, komitmen, dan tanggung jawab), memiliki etos kerja, menunjukkan kemandirian, menunjukkan kerja sama, dan menunjukkan kepedulian sosial dan lingkungan dengan predikat sangat baik.';
    } else if (predikat == 'Baik') {
      return 'Peserta didik mampu menerapkan soft skill yang dimiliki dengan menunjukkan integritas (jujur, disiplin, komitmen, dan tanggung jawab), memiliki etos kerja, menunjukkan kemandirian, menunjukkan kerja sama, dan menunjukkan kepedulian sosial dan lingkungan dengan predikat baik.';
    } else {
      return 'Peserta didik mampu menerapkan soft skill yang dimiliki dengan menunjukkan integritas (jujur, disiplin, komitmen, dan tanggung jawab), memiliki etos kerja, menunjukkan kemandirian, menunjukkan kerja sama, dan menunjukkan kepedulian sosial dan lingkungan dengan predikat kurang.';
    }
  }

  String _getNormaK3LHDescription(int skor) {
    final predikat = _getPredikatFromSkor(skor);
    if (predikat == 'Sangat Baik') {
      return 'Peserta didik mampu menerapkan norma, Prosedur Operasional Standar (POS), dan Kesehatan, Keselamatan Kerja, dan Lingkungan Hidup (K3LH) yang ditunjukkan dengan menggunakan APD dengan tertib dan benar, serta melaksanakan pekerjaan sesuai POS dengan predikat sangat baik.';
    } else if (predikat == 'Baik') {
      return 'Peserta didik mampu menerapkan norma, Prosedur Operasional Standar (POS), dan Kesehatan, Keselamatan Kerja, dan Lingkungan Hidup (K3LH) yang ditunjukkan dengan menggunakan APD dengan tertib dan benar, serta melaksanakan pekerjaan sesuai POS dengan predikat baik.';
    } else {
      return 'Peserta didik mampu menerapkan norma, Prosedur Operasional Standar (POS), dan Kesehatan, Keselamatan Kerja, dan Lingkungan Hidup (K3LH) yang ditunjukkan dengan menggunakan APD dengan tertib dan benar, serta melaksanakan pekerjaan sesuai POS dengan predikat kurang.';
    }
  }

  String _getKompetensiTeknisDescription(int skor) {
    final predikat = _getPredikatFromSkor(skor);
    if (predikat == 'Sangat Baik') {
      return 'Peserta didik mampu menerapkan kompetensi teknis yang sudah dipelajari di sekolah dan/atau baru dipelajari di dunia kerja (tempat PKL) dengan predikat sangat baik.';
    } else if (predikat == 'Baik') {
      return 'Peserta didik mampu menerapkan kompetensi teknis yang sudah dipelajari di sekolah dan/atau baru dipelajari di dunia kerja (tempat PKL) dengan predikat baik.';
    } else {
      return 'Peserta didik mampu menerapkan kompetensi teknis yang sudah dipelajari di sekolah dan/atau baru dipelajari di dunia kerja (tempat PKL) dengan predikat kurang.';
    }
  }

  String _getAlurBisnisDescription(int skor) {
    final predikat = _getPredikatFromSkor(skor);
    if (predikat == 'Sangat Baik') {
      return 'Peserta didik mampu memahami alur bisnis dunia kerja tempat PKL dan wawasan wirausaha dengan predikat sangat baik.';
    } else if (predikat == 'Baik') {
      return 'Peserta didik mampu memahami alur bisnis dunia kerja tempat PKL dan wawasan wirausaha dengan predikat baik.';
    } else {
      return 'Peserta didik mampu memahami alur bisnis dunia kerja tempat PKL dan wawasan wirausaha dengan predikat kurang.';
    }
  }

  // ==================== FUNGSI FETCH DATA ====================
  Future<void> _fetchDetailData() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      _redirectToLogin();
      return;
    }

    try {
      final url =
          '${dotenv.env['API_BASE_URL']}/api/penilaian/review/${widget.applicationId}';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _detailData = data;
          _formItems =
              List<Map<String, dynamic>>.from(data['form_items'] ?? []);
          _nilaiItems = List<Map<String, dynamic>>.from(data['items'] ?? []);
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        _redirectToLogin();
      } else {
        throw Exception('Gagal memuat detail review');
      }
    } catch (e) {
      print('Error fetching detail: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Gagal memuat detail review', isError: true);
      }
    }
  }

  // ==================== FUNGSI UTILITY ====================
  void _redirectToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : _primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'S';
    final parts = name.split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return _successColor;
    if (score >= 75) return _warningColor;
    return Colors.red;
  }

  String _getJurusanFromKelas(String? kelasNama) {
    if (kelasNama == null) return 'rpl';

    final kelasLower = kelasNama.toLowerCase();
    if (kelasLower.contains('dkv')) return 'dkv';
    if (kelasLower.contains('rpl')) return 'rpl';
    if (kelasLower.contains('tkj')) return 'tkj';
    if (kelasLower.contains('av')) return 'av';
    if (kelasLower.contains('bc')) return 'bc';
    if (kelasLower.contains('mt')) return 'mt';
    if (kelasLower.contains('an')) return 'an';
    if (kelasLower.contains('ei')) return 'ei';

    return 'rpl';
  }

  String _getHasilPKL(double average) {
    if (average >= 90) return 'Amat Baik';
    if (average >= 80) return 'Baik';
    if (average >= 70) return 'Cukup';
    return 'Perlu Peningkatan';
  }

  String _formatDate(DateTime date) {
    const months = [
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // ==================== FUNGSI DOWNLOAD & GENERATE SERTIFIKAT ====================
  Future<void> _downloadFile(String fileUrl, String filename) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      _redirectToLogin();
      return;
    }

    try {
      _showSnackBar('Mengunduh file...');

      final response = await http.get(
        Uri.parse('${dotenv.env['SERTIF']}$fileUrl'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$filename');
        await file.writeAsBytes(response.bodyBytes);

        _showSnackBar('File berhasil diunduh: $filename');

        await OpenFile.open(file.path);
      } else {
        throw Exception('Gagal mengunduh file');
      }
    } catch (e) {
      print('Error downloading file: $e');
      _showSnackBar('Gagal mengunduh file', isError: true);
    }
  }

  Future<void> _generateSertifikat() async {
    setState(() => _isGeneratingCertificate = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      _redirectToLogin();
      return;
    }

    try {
      if (_formItems.isEmpty) {
        _showSnackBar('Data kompetensi tidak tersedia', isError: true);
        setState(() => _isGeneratingCertificate = false);
        return;
      }

      final rataRata = _detailData?['rata_rata'] ?? 0;
      double rataRataDouble;
      if (rataRata is String) {
        rataRataDouble = double.tryParse(rataRata) ?? 0;
      } else {
        rataRataDouble = rataRata.toDouble();
      }

      final hasilPKL = _getHasilPKL(rataRataDouble);
      final jurusan = _getJurusanFromKelas(_siswaData['kelas_nama']);

      final now = DateTime.now();
      final formattedDate = _formatDate(now);
      final nomorSertifikat =
          '420/${now.day}${now.month}${now.year}/101.6.9.19/${now.year}';

      final String desc1 = _formItems.isNotEmpty
          ? _formItems[0]['tujuan_pembelajaran'] ?? 'Kompetensi 1'
          : 'Kompetensi 1';
      final String desc2 = _formItems.length > 1
          ? _formItems[1]['tujuan_pembelajaran'] ?? 'Kompetensi 2'
          : 'Kompetensi 2';
      final String desc3 = _formItems.length > 2
          ? _formItems[2]['tujuan_pembelajaran'] ?? 'Kompetensi 3'
          : 'Kompetensi 3';
      final String desc4 = _formItems.length > 3
          ? _formItems[3]['tujuan_pembelajaran'] ?? 'Kompetensi 4'
          : 'Kompetensi 4';

      int skor1 = 0, skor2 = 0, skor3 = 0, skor4 = 0;

      for (var i = 0; i < _formItems.length; i++) {
        final formItem = _formItems[i];
        final nilaiItem = _nilaiItems.firstWhere(
          (item) => item['form_item_id'] == formItem['id'],
          orElse: () => {},
        );

        final skor = nilaiItem['skor'] ?? 0;

        if (i == 0) {
          skor1 = skor;
        } else if (i == 1)
          skor2 = skor;
        else if (i == 2)
          skor3 = skor;
        else if (i == 3) skor4 = skor;
      }

      // FORMAT TANGGAL
      String tanggalMulai = '';
      String tanggalSelesai = '';

      if (_detailData != null) {
        tanggalMulai = _detailData!['tanggal_mulai'] ??
            _detailData!['start_date'] ??
            _detailData!['mulai'] ??
            '';

        tanggalSelesai = _detailData!['tanggal_selesai'] ??
            _detailData!['end_date'] ??
            _detailData!['selesai'] ??
            _detailData!['finalized_at'] ??
            '';
      }

      if (tanggalMulai.isEmpty) {
        try {
          if (tanggalSelesai.isNotEmpty) {
            final dateSelesai = DateTime.parse(tanggalSelesai.split(' ')[0]);
            final dateMulai = dateSelesai.subtract(const Duration(days: 180));
            tanggalMulai = _formatDate(dateMulai);
          } else {
            tanggalMulai =
                _formatDate(DateTime.now().subtract(const Duration(days: 180)));
          }
        } catch (e) {
          tanggalMulai =
              _formatDate(DateTime.now().subtract(const Duration(days: 180)));
        }
      } else {
        try {
          final dateMulai = DateTime.parse(tanggalMulai);
          tanggalMulai = _formatDate(dateMulai);
        } catch (e) {}
      }

      if (tanggalSelesai.isNotEmpty) {
        try {
          final dateSelesai = DateTime.parse(tanggalSelesai.split(' ')[0]);
          tanggalSelesai = _formatDate(dateSelesai);
        } catch (e) {}
      } else {
        tanggalSelesai = formattedDate;
      }

      // ===== DATA INDUSTRI (PIMPINAN + PEMBIMBING INDUSTRI) =====
      print(
          '\n📋 ===== DATA INDUSTRI UNTUK ${_siswaData['siswa_username']} =====');

      String namaPimpinan = '';
      String nipPimpinan = '';
      String jabatanPimpinan = '';

      String namaPembimbingIndustri = '';
      String nipPembimbingIndustri = '';
      String jabatanPembimbingIndustri = '';

      // AMBIL DARI SHAREDPREFERENCES
      print('📡 Mencari data industri di SharedPreferences...');
      final industriData =
          await PimpinanStorage.ambilDataIndustri(widget.applicationId);

      if (industriData != null) {
        // Data Pimpinan Industri
        namaPimpinan = industriData['pimpinan']?['nama'] ?? '';
        nipPimpinan = industriData['pimpinan']?['nip'] ?? '-';
        jabatanPimpinan = industriData['pimpinan']?['jabatan'] ?? '';

        // Data Pembimbing Industri
        namaPembimbingIndustri =
            industriData['pembimbing_industri']?['nama'] ?? '';
        nipPembimbingIndustri =
            industriData['pembimbing_industri']?['nip'] ?? '-';
        jabatanPembimbingIndustri =
            industriData['pembimbing_industri']?['jabatan'] ?? '';

        print('✅ Data industri ditemukan di SharedPreferences:');
        print('   - Pimpinan: $namaPimpinan ($jabatanPimpinan)');
        print(
            '   - Pembimbing Industri: $namaPembimbingIndustri ($jabatanPembimbingIndustri)');
      } else {
        print('❌ TIDAK ADA DATA INDUSTRI DI SHAREDPREFERENCES!');
        print(
            '❌ Pembimbing belum menginput data untuk aplikasi ID: ${widget.applicationId}');

        _showSnackBar('Data pimpinan dan pembimbing industri belum diinput',
            isError: true);
        setState(() => _isGeneratingCertificate = false);
        return;
      }

      // ===== DATA PEMBIMBING SEKOLAH (KOORDINATOR) =====
      print('\n📋 ===== DATA PEMBIMBING SEKOLAH =====');

      String namaPembimbingSekolah = '';
      String nipPembimbingSekolah = '';
      String jabatanPembimbingSekolah = '';

      // Coba ambil data guru berdasarkan user_id
      final userId = prefs.getInt('user_id');
      if (userId != null) {
        try {
          final guruResponse = await http.get(
            Uri.parse(
                '${dotenv.env['API_BASE_URL']}/api/guru?user_id=$userId&limit=1'),
            headers: {
              'accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );

          if (guruResponse.statusCode == 200) {
            final guruData = jsonDecode(guruResponse.body);
            if (guruData['success'] == true &&
                guruData['data']['data'] != null &&
                guruData['data']['data'].isNotEmpty) {
              final guru = guruData['data']['data'][0];
              namaPembimbingSekolah = guru['nama'] ?? '';
              nipPembimbingSekolah = guru['nip'] ?? '';

              // Tentukan jabatan berdasarkan role
              if (guru['is_koordinator'] == true) {
                jabatanPembimbingSekolah = 'Koordinator PKL';
              } else if (guru['is_pembimbing'] == true) {
                jabatanPembimbingSekolah = 'Guru Pembimbing PKL';
              } else if (guru['is_wali_kelas'] == true) {
                jabatanPembimbingSekolah = 'Wali Kelas';
              } else {
                jabatanPembimbingSekolah = 'Guru';
              }

              print('✅ Data guru ditemukan:');
              print('   - Nama: $namaPembimbingSekolah');
              print('   - NIP: $nipPembimbingSekolah');
              print('   - Jabatan: $jabatanPembimbingSekolah');
            }
          }
        } catch (e) {
          print('❌ Error fetching guru data: $e');
        }
      }

      // Jika data guru tidak ditemukan, pakai dari SharedPreferences
      if (namaPembimbingSekolah.isEmpty) {
        print('⚠️ Menggunakan data dari SharedPreferences');
        namaPembimbingSekolah =
            prefs.getString('user_name') ?? 'Guru Pembimbing PKL';
        nipPembimbingSekolah = prefs.getString('user_nip') ?? '-';
        jabatanPembimbingSekolah =
            prefs.getString('user_jabatan') ?? 'Guru Pembimbing PKL';

        print('   - Nama: $namaPembimbingSekolah');
        print('   - NIP: $nipPembimbingSekolah');
        print('   - Jabatan: $jabatanPembimbingSekolah');
      }

      // ===== GABUNGKAN SEMUA DATA UNTUK API =====
      final Map<String, dynamic> requestBody = {
        'nomor_sertifikat': nomorSertifikat,
        'siswa': {
          'nama': _siswaData['siswa_username'] ?? '',
          'nisn': _siswaData['nisn'] ?? '0123456789',
        },
        'nama_industri': _siswaData['industri_nama'] ?? '',
        'tanggal_mulai': tanggalMulai,
        'tanggal_selesai': tanggalSelesai,
        'hasil_pkl': hasilPKL,
        'tanggal_terbit': formattedDate,
        'nilai': {
          'aspek_1': skor1,
          'desc_1': desc1,
          'aspek_2': skor2,
          'desc_2': desc2,
          'aspek_3': skor3,
          'desc_3': desc3,
          'aspek_4': skor4,
          'desc_4': desc4,
        },
        // Data Pimpinan Industri
        'nama_pimpinan': namaPimpinan,
        'nip_pimpinan': nipPimpinan,
        'jabatan_pimpinan': jabatanPimpinan,

        // Data Pembimbing Industri
        'nama_pembimbing': namaPembimbingIndustri,
        'nip_pembimbing': nipPembimbingIndustri,
        'jabatan_pembimbing': jabatanPembimbingIndustri,

        // Data Pembimbing Sekolah (Koordinator)
        'nama_pembimbing_sekolah': namaPembimbingSekolah,
        'nip_pembimbing_sekolah': nipPembimbingSekolah,
        'jabatan_pembimbing_sekolah': jabatanPembimbingSekolah,
      };

      print('\n📤 ===== REQUEST BODY FINAL =====');
      print(jsonEncode(requestBody));
      print('===============================\n');

      // Kirim request ke API sertifikat
      final response = await http.post(
        Uri.parse('${dotenv.env['SERTIF']}/api/v1/letters/sertifikat/$jurusan'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _showSnackBar('Sertifikat berhasil dibuat');
        await _downloadFile(data['file_url'], data['filename']);
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        _showSnackBar('Error: ${error['detail'] ?? 'Jurusan tidak valid'}',
            isError: true);
      } else {
        throw Exception('Gagal membuat sertifikat: ${response.statusCode}');
      }
    } catch (e) {
      print('Error generating certificate: $e');
      _showSnackBar('Gagal membuat sertifikat', isError: true);
    } finally {
      if (mounted) setState(() => _isGeneratingCertificate = false);
    }
  }

  // ==================== BUILD WIDGET ====================
  @override
  Widget build(BuildContext context) {
    final String siswaUsername = _siswaData['siswa_username'] ?? '-';
    final String kelasNama = _siswaData['kelas_nama'] ?? '-';
    final String jurusanNama = _siswaData['jurusan_nama'] ?? '-';
    final String industriNama = _siswaData['industri_nama'] ?? '-';

    final String formNama = _detailData?['form_nama'] ?? '-';
    final int totalSkor = _detailData?['total_skor'] ?? 0;
    final double rataRata =
        double.tryParse(_detailData?['rata_rata']?.toString() ?? '0') ?? 0;
    final String catatanAkhir = _detailData?['catatan_akhir'] ?? '-';
    final String finalizedAt =
        _detailData?['finalized_at'] ?? _siswaData['finalized_at'] ?? '';

    return Scaffold(
      backgroundColor: _backgroundLight,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Detail Penilaian',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: _primaryColor),
            )
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ===== CARD INFORMASI SISWA =====
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        _primaryColor.withValues(alpha: 0.2),
                                        _primaryColor.withValues(alpha: 0.1)
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _getInitials(siswaUsername),
                                      style: TextStyle(
                                        color: _primaryColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 28,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        siswaUsername,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(height: 1),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Kelas',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _neutralColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        kelasNama,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Jurusan',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _neutralColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        jurusanNama,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.business_center_rounded,
                                  size: 16,
                                  color: _neutralColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    industriNama,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ===== CARD FORM PENILAIAN =====
                      if (formNama != '-')
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _borderSoft),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _primaryLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.assignment_rounded,
                                  color: _primaryColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Form Penilaian',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: _neutralColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      formNama,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
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
                      if (formNama != '-') const SizedBox(height: 20),

                      // ===== DETAIL NILAI KOMPETENSI DENGAN DESKRIPSI DI BAWAHNYA =====
                      if (_formItems.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            'Detail Nilai',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // LOOPING UNTUK SETIAP KOMPETENSI
                        ...List.generate(_formItems.length, (index) {
                          final formItem = _formItems[index];
                          final nomor = index + 1;

                          final nilaiItem = _nilaiItems.firstWhere(
                            (item) => item['form_item_id'] == formItem['id'],
                            orElse: () => {},
                          );

                          final int skor = nilaiItem['skor'] ?? 0;
                          final String predikat = _getPredikatFromSkor(skor);

                          // Fungsi untuk mendapatkan deskripsi berdasarkan nomor kompetensi
                          String getDeskripsiKompetensi(
                              int nomorKompetensi, int skor) {
                            if (nomorKompetensi == 1) {
                              return _getSoftSkillDescription(skor);
                            } else if (nomorKompetensi == 2) {
                              return _getNormaK3LHDescription(skor);
                            } else if (nomorKompetensi == 3) {
                              return _getKompetensiTeknisDescription(skor);
                            } else if (nomorKompetensi == 4) {
                              return _getAlurBisnisDescription(skor);
                            }
                            return '';
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _borderSoft),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withValues(alpha: 0.05),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header Kompetensi
                                Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: _primaryColor,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$nomor',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Kompetensi $nomor',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Tujuan Pembelajaran
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _backgroundLight,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _borderSoft),
                                  ),
                                  child: Text(
                                    formItem['tujuan_pembelajaran'] ?? '-',
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Nilai dan Predikat
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Nilai',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _backgroundLight,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                  color: _borderSoft),
                                            ),
                                            child: Text(
                                              skor.toString(),
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 18,
                                                color: _getScoreColor(
                                                    skor.toDouble()),
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Predikat',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _backgroundLight,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                  color: _borderSoft),
                                            ),
                                            child: Text(
                                              predikat,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color: _primaryColor,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // ===== DESKRIPSI CAPAIAN (DITEMPATKAN DI BAWAH SETIAP KOMPETENSI) =====
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color:
                                        _primaryColor.withValues(alpha: 0.03),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: _primaryColor.withValues(
                                            alpha: 0.2)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.description_rounded,
                                        size: 16,
                                        color: _primaryColor.withValues(
                                            alpha: 0.7),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Deskripsi Capaian:',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: _primaryColor,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              getDeskripsiKompetensi(
                                                  nomor, skor),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[800],
                                                height: 1.4,
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
                          );
                        }),
                        const SizedBox(height: 16),
                      ],

                      // ===== CATATAN AKHIR =====
                      if (catatanAkhir != '-')
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _borderSoft),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.note_alt_rounded,
                                    size: 20,
                                    color: _primaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Catatan Akhir',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _backgroundLight,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: _borderSoft),
                                ),
                                child: Text(
                                  catatanAkhir,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (catatanAkhir != '-') const SizedBox(height: 16),

                      // ===== RINGKASAN TOTAL SKOR =====
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _primaryColor,
                              _primaryColor.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryColor.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Total Skor',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      totalSkor.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 24,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: Colors.white30,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'Rata-rata',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      rataRata.toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 24,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(
                              height: 1,
                              color: Colors.white30,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 14,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Selesai: ${_formatDateIndonesian(finalizedAt)}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

// ===== TAMBAHKAN INI =====
// ===== DATA PIMPINAN & PEMBIMBING INDUSTRI =====
                      FutureBuilder<Map<String, dynamic>?>(
                        future: PimpinanStorage.ambilDataIndustri(
                            widget.applicationId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final industriData = snapshot.data;
                          if (industriData == null) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border:
                                    Border.all(color: Colors.orange.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded,
                                      color: Colors.orange.shade700),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Data pimpinan dan pembimbing industri belum diinput',
                                      style: TextStyle(
                                        color: Colors.orange.shade800,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final pimpinan = industriData['pimpinan'] ?? {};
                          final pembimbing =
                              industriData['pembimbing_industri'] ?? {};

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _borderSoft),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: _primaryColor.withValues(
                                            alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(Icons.business_center,
                                          color: _primaryColor, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Data Industri',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Pimpinan Industri
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _backgroundLight,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: _borderSoft),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.person,
                                              size: 16, color: _primaryColor),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Pimpinan Industri',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: _primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: Text('Nama',
                                                style: TextStyle(
                                                    color: _neutralColor,
                                                    fontSize: 12)),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              pimpinan['nama'] ?? '-',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: Text('NIP',
                                                style: TextStyle(
                                                    color: _neutralColor,
                                                    fontSize: 12)),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              pimpinan['nip']?.isNotEmpty ==
                                                      true
                                                  ? pimpinan['nip']
                                                  : '-',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: Text('Jabatan',
                                                style: TextStyle(
                                                    color: _neutralColor,
                                                    fontSize: 12)),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              pimpinan['jabatan'] ?? '-',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Pembimbing Industri
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _backgroundLight,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: _borderSoft),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.people,
                                              size: 16,
                                              color: Colors.green.shade700),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Pembimbing Industri',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: Text('Nama',
                                                style: TextStyle(
                                                    color: _neutralColor,
                                                    fontSize: 12)),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              pembimbing['nama'] ?? '-',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: Text('NIP',
                                                style: TextStyle(
                                                    color: _neutralColor,
                                                    fontSize: 12)),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              pembimbing['nip']?.isNotEmpty ==
                                                      true
                                                  ? pembimbing['nip']
                                                  : '-',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: Text('Jabatan',
                                                style: TextStyle(
                                                    color: _neutralColor,
                                                    fontSize: 12)),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              pembimbing['jabatan'] ?? '-',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.access_time,
                                          size: 14,
                                          color: Colors.blue.shade700),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'Disimpan: ${_formatDateIndonesian(industriData['waktu_simpan'])}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.blue.shade700,
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
                      ),
                      const SizedBox(height: 20),

                      // ===== TOMBOL BUAT SERTIFIKAT =====
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 20),
                        child: ElevatedButton.icon(
                          onPressed: _isGeneratingCertificate
                              ? null
                              : _generateSertifikat,
                          icon: _isGeneratingCertificate
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.picture_as_pdf, size: 20),
                          label: Text(
                            _isGeneratingCertificate
                                ? 'Memproses...'
                                : 'Buat Sertifikat',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ==================== HALAMAN DETAIL FORM ====================
class FormDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? formData;
  final VoidCallback onFormSaved;

  const FormDetailScreen({
    super.key,
    this.formData,
    required this.onFormSaved,
  });

  @override
  State<FormDetailScreen> createState() => _FormDetailScreenState();
}

class _FormDetailScreenState extends State<FormDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaController = TextEditingController();

  List<Map<String, dynamic>> _items = [];
  final bool _isLoading = false;
  bool _isSaving = false;
  bool _isEditMode = false;

  final Color _primaryColor = const Color(0xFF641E20);
  final Color _successColor = const Color(0xFF2E7D32);
  final Color _warningColor = const Color(0xFFED6C02);
  final Color _backgroundLight = const Color(0xFFF5F5F5);
  final Color _borderSoft = const Color(0xFFEEEEEE);

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.formData != null;
    if (_isEditMode) {
      _namaController.text = widget.formData!['nama'] ?? '';
      _items = List<Map<String, dynamic>>.from(widget.formData!['items'] ?? []);
    } else {
      _addNewItem();
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    super.dispose();
  }

  void _addNewItem() {
    setState(() {
      _items.add({
        'urutan': _items.length + 1,
        'tujuan_pembelajaran': '',
        'isNew': true,
      });
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      for (int i = 0; i < _items.length; i++) {
        _items[i]['urutan'] = i + 1;
      }
    });
  }

  void _moveItemUp(int index) {
    if (index > 0) {
      setState(() {
        final temp = _items[index];
        _items[index] = _items[index - 1];
        _items[index - 1] = temp;
        for (int i = 0; i < _items.length; i++) {
          _items[i]['urutan'] = i + 1;
        }
      });
    }
  }

  void _moveItemDown(int index) {
    if (index < _items.length - 1) {
      setState(() {
        final temp = _items[index];
        _items[index] = _items[index + 1];
        _items[index + 1] = temp;
        for (int i = 0; i < _items.length; i++) {
          _items[i]['urutan'] = i + 1;
        }
      });
    }
  }

  bool _validateItems() {
    for (var i = 0; i < _items.length; i++) {
      final tp = _items[i]['tujuan_pembelajaran']?.toString().trim() ?? '';
      if (tp.isEmpty) {
        _showSnackBar('Tujuan pembelajaran kompetensi ${i + 1} harus diisi',
            isError: true);
        return false;
      }
    }
    return true;
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_validateItems()) return;

    setState(() => _isSaving = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      _redirectToLogin();
      return;
    }

    try {
      final List<Map<String, dynamic>> items = [];
      for (var item in _items) {
        items.add({
          'urutan': item['urutan'],
          'tujuan_pembelajaran':
              item['tujuan_pembelajaran']?.toString().trim() ?? '',
        });
      }

      final body = {
        'nama': _namaController.text.trim(),
        'items': items,
      };

      late http.Response response;

      if (_isEditMode) {
        response = await http.put(
          Uri.parse(
              '${dotenv.env['API_BASE_URL']}/api/penilaian/forms/${widget.formData!['id']}'),
          headers: {
            'accept': 'application/json',
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        );
      } else {
        response = await http.post(
          Uri.parse('${dotenv.env['API_BASE_URL']}/api/penilaian/forms'),
          headers: {
            'accept': 'application/json',
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar(
            _isEditMode ? 'Form berhasil diperbarui' : 'Form berhasil dibuat');
        widget.onFormSaved();
        Navigator.pop(context);
      } else {
        throw Exception('Gagal menyimpan form');
      }
    } catch (e) {
      print('Error saving form: $e');
      _showSnackBar('Gagal menyimpan form', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _redirectToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : _primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatDateIndonesian(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';

    try {
      final date = DateTime.parse(dateString);
      const List<String> bulan = [
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
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = widget.formData?['is_active'] == true;

    return Scaffold(
      backgroundColor: _backgroundLight,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isEditMode ? 'Ubah Form Penilaian' : 'Buat Form Penilaian',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: _primaryColor,
              ),
            )
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isEditMode) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color:
                                      isActive ? _successColor : _warningColor,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? _successColor.withValues(alpha: 0.1)
                                          : _warningColor.withValues(
                                              alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      isActive
                                          ? Icons.check_circle_rounded
                                          : Icons.pause_circle_outline_rounded,
                                      color: isActive
                                          ? _successColor
                                          : _warningColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isActive
                                              ? 'Form Aktif'
                                              : 'Form Tidak Aktif',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                            color: isActive
                                                ? _successColor
                                                : _warningColor,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Diperbarui: ${_formatDateIndonesian(widget.formData?['updated_at'])}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _borderSoft),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withValues(alpha: 0.05),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: _primaryColor,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Informasi Form',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _namaController,
                                  decoration: InputDecoration(
                                    labelText: 'Nama Form',
                                    hintText: 'Contoh: Penilaian Semester 6',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide:
                                          BorderSide(color: _borderSoft),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide:
                                          BorderSide(color: _borderSoft),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide:
                                          BorderSide(color: _primaryColor),
                                    ),
                                    prefixIcon: Icon(Icons.assignment_rounded,
                                        color: _primaryColor),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Nama form harus diisi';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _borderSoft),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withValues(alpha: 0.05),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: _primaryColor,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Kompetensi yang Dinilai',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tambahkan kompetensi yang akan dinilai selama PKL',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ...List.generate(_items.length, (index) {
                                  final item = _items[index];
                                  final nomor = index + 1;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _backgroundLight,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: _borderSoft),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                color: _primaryColor,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '$nomor',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                'Kompetensi $nomor',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                            if (index > 0)
                                              IconButton(
                                                icon: Icon(
                                                    Icons.arrow_upward_rounded,
                                                    size: 18,
                                                    color: _primaryColor),
                                                onPressed: () =>
                                                    _moveItemUp(index),
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                              ),
                                            if (index < _items.length - 1)
                                              IconButton(
                                                icon: Icon(
                                                    Icons
                                                        .arrow_downward_rounded,
                                                    size: 18,
                                                    color: _primaryColor),
                                                onPressed: () =>
                                                    _moveItemDown(index),
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                              ),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.delete_outline_rounded,
                                                  size: 18,
                                                  color: Colors.red),
                                              onPressed: _items.length > 1
                                                  ? () => _removeItem(index)
                                                  : null,
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        TextFormField(
                                          initialValue:
                                              item['tujuan_pembelajaran'],
                                          maxLines: 3,
                                          decoration: InputDecoration(
                                            hintText: 'Tujuan pembelajaran...',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: BorderSide(
                                                  color: _borderSoft),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: BorderSide(
                                                  color: _borderSoft),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: BorderSide(
                                                  color: _primaryColor),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.all(12),
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              _items[index]
                                                      ['tujuan_pembelajaran'] =
                                                  value;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: _addNewItem,
                                  icon: Icon(Icons.add_rounded,
                                      color: _primaryColor),
                                  label: const Text('Tambah Kompetensi'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _primaryColor,
                                    side: BorderSide(color: _primaryColor),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(
                                _isEditMode ? 'Perbarui Form' : 'Buat Form',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

extension ColorExtension on Color {
  Color withValues({double? alpha}) {
    if (alpha != null) {
      return withAlpha((alpha * 255).round());
    }
    return this;
  }
}
