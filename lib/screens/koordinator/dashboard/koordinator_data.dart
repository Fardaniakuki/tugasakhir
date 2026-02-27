import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../login/login_screen.dart';

class KoordinatorData extends StatefulWidget {
  const KoordinatorData({super.key});

  @override
  State<KoordinatorData> createState() => _KoordinatorDataState();
}

class _KoordinatorDataState extends State<KoordinatorData>
    with SingleTickerProviderStateMixin {
  // Professional Color Palette
  static const Color _primaryColor = Color(0xFF641E20);
  static const Color _accentColor = Color(0xFFE74C3C);
  static const Color _successColor = Color(0xFF27AE60);
  static const Color _infoColor = Color(0xFF3498DB);
  static const Color _backgroundLight = Color(0xFFF8F9FA);
  static const Color _borderColor = Color(0xFFE1E8ED);
  static const Color _textPrimary = Color(0xFF2C3E50);
  static const Color _textSecondary = Color(0xFF7F8C8D);

  // Tab Controller
  late TabController _tabController;

  // State variables for Surat Tugas
  bool _isLoadingGuru = false;
  String _statusMessageGuru = '';
  bool _hasErrorGuru = false;
  List<Map<String, dynamic>> _guruPembimbing = [];
  Map<String, dynamic>? _selectedGuru;

  // State variables for Lembar Persetujuan
  bool _isLoadingSiswa = false;
  String _statusMessageSiswa = '';
  bool _hasErrorSiswa = false;
  Map<String, List<Map<String, dynamic>>> _siswaByIndustri = {};
  List<String> _industriList = [];
  String? _selectedIndustri;
  List<String> _selectedSiswaIds = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkTokenAndLoadData();
  }

  String _formatDate(DateTime date) {
    final months = [
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

  String _getTempatTanggal() {
    return 'Malang, ${_formatDate(_selectedDate)}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Load authentication token dan data
  Future<void> _checkTokenAndLoadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        _redirectToLogin();
        return;
      }

      await Future.wait([
        _loadDataGuru(),
        _loadDataSiswa(),
      ]);
    } catch (e) {
      print('Error loading token: $e');
      setState(() {
        _statusMessageGuru = 'Error: $e';
        _hasErrorGuru = true;
      });
    }
  }

  void _redirectToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    });
  }

  // Function to launch URL
  Future<void> _launchUrl(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $urlString');
      }
    } catch (e) {
      _showErrorSnackbar('Gagal membuka URL: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _accentColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ==================== SURAT TUGAS SECTION ====================
  Future<void> _loadDataGuru() async {
    if (_isLoadingGuru) return;

    setState(() {
      _isLoadingGuru = true;
      _statusMessageGuru = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        _redirectToLogin();
        return;
      }

      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/guru'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 401) {
        _showErrorSnackbar('Sesi telah berakhir, silakan login kembali');
        _redirectToLogin();
        return;
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          List<dynamic> teachersList = [];

          if (responseData['data']['data'] is List) {
            teachersList = responseData['data']['data'];
          } else if (responseData['data'] is List) {
            teachersList = responseData['data'];
          }

          final List<Map<String, dynamic>> pembimbingList = teachersList
              .where((teacher) => teacher['is_pembimbing'] == true)
              .map((teacher) => Map<String, dynamic>.from(teacher))
              .toList();

          final List<Map<String, dynamic>> formattedGuruPembimbing =
              pembimbingList.map((guru) {
            return {
              ...guru,
              'id': guru['id'] ?? 0,
              'nama': guru['nama'] ?? 'N/A',
            };
          }).toList();

          setState(() {
            _guruPembimbing = formattedGuruPembimbing;
            _hasErrorGuru = false;
            _selectedGuru = null;
          });
        } else {
          final errorMsg = responseData['message'] ?? 'Gagal memuat data guru';
          throw Exception(errorMsg);
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: Gagal memuat data guru');
      }
    } catch (e) {
      print('Error loading guru: $e');
      setState(() {
        _statusMessageGuru = '❌ Error: ${e.toString()}';
        _hasErrorGuru = true;
      });
      _showErrorSnackbar('Gagal memuat data guru: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingGuru = false;
        });
      }
    }
  }

  Future<void> _generateSuratTugas() async {
    if (_isLoadingGuru) return;

    if (_selectedGuru == null) {
      _showErrorSnackbar('Pilih guru pembimbing terlebih dahulu');
      return;
    }

    setState(() {
      _isLoadingGuru = true;
      _hasErrorGuru = false;
      _statusMessageGuru =
          'Membuat Surat Tugas untuk ${_selectedGuru!['nama']}...';
    });

    try {
      const String apiBaseUrl = 'https://sertif.gedanggoreng.com';
      const String endpoint = '$apiBaseUrl/api/v1/letters/surat-tugas';

      final Map<String, dynamic> requestData = {
        'nomor_surat': '800/123/SMK.2/${DateTime.now().year}',
        'tanggal_surat': _formatDate(DateTime.now()),
        'tempat_surat': 'Singosari',
        'perihal': 'SURAT TUGAS',
        'school_info': {
          'nama_sekolah': 'SMK NEGERI 2 SINGOSARI',
          'alamat_jalan': 'Jalan Perusahaan No. 20',
          'kelurahan': 'Tunjungtirto',
          'kecamatan': 'Singosari',
          'kab_kota': 'Kab. Malang',
          'provinsi': 'Jawa Timur',
          'kode_pos': '65153',
          'telepon': '(0341) 4345127',
          'email': 'smkn2singosari@yahoo.co.id',
          'website': 'www.smkn2singosari.sch.id',
          'logo_url':
              'https://upload.wikimedia.org/wikipedia/commons/7/74/Coat_of_arms_of_East_Java.svg',
        },
        'penandatangan': {
          'instansi': 'SMK Negeri 2 Singosari',
          'jabatan': 'Kepala SMK Negeri 2 Singosari',
          'nama': 'SUMIJAH, S.Pd., M.Si.',
          'nip': '19700210 199802 2 009',
          'pangkat': 'Pembina Tk. I'
        },
        'assignees': [
          {
            'instansi': 'SMK Negeri 2 Singosari',
            'jabatan': 'Guru Pembimbing PKL',
            'nama': _selectedGuru!['nama'],
            'nip': '',
          }
        ],
        'details': [
          {
            'label': 'Keperluan',
            'separator': ':',
            'value': 'Pengantaran Siswa Praktik Kerja Lapangan (PKL)'
          },
          {
            'label': 'Hari / Tanggal',
            'separator': ':',
            'value': _formatDate(DateTime.now())
          },
          {'label': 'Waktu', 'separator': ':', 'value': '08.00 - Selesai'},
          {'label': 'Tempat', 'separator': ':', 'value': 'BACAMALANG.COM'},
          {
            'label': 'Alamat',
            'separator': ':',
            'value':
                'JL. MOROJANTEK NO. 87 B, PANGENTAN, KEC. SINGOSARI, KAB. MALANG'
          }
        ],
        'pembuka':
            'Kepala SMK Negeri 2 Singosari Dinas Pendidikan Kabupaten Malang menugaskan kepada :',
        'penutup':
            'Demikian surat tugas ini dibuat untuk dilaksanakan dengan sebaik-baiknya dan melaporkan hasilnya kepada kepala sekolah.',
      };

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(requestData),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> result = jsonDecode(response.body);

        final String? filename = result['filename'];
        final String? fileUrl = result['file_url'];
        final String? downloadUrl = result['download_url'];

        if (filename != null && (fileUrl != null || downloadUrl != null)) {
          final String finalDownloadUrl = downloadUrl ?? fileUrl!;
          final String fullDownloadUrl = finalDownloadUrl.startsWith('http')
              ? finalDownloadUrl
              : '$apiBaseUrl$finalDownloadUrl';

          setState(() {
            _statusMessageGuru =
                '✅ Surat Tugas untuk ${_selectedGuru!['nama']} berhasil dibuat!';
            _hasErrorGuru = false;
          });

          _showSuccessDialogSuratTugas(
              _selectedGuru!['nama'], filename, fullDownloadUrl);
        } else {
          throw Exception('Format response tidak lengkap');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error generate surat: $e');
      setState(() {
        _statusMessageGuru = '❌ Gagal: ${e.toString()}';
        _hasErrorGuru = true;
      });
      _showErrorSnackbar('Gagal membuat surat: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingGuru = false;
        });
      }
    }
  }

  // Status Banner untuk Surat Tugas
  Widget _buildStatusBannerGuru() {
    if (_statusMessageGuru.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _hasErrorGuru
            ? _accentColor.withValues(alpha: 0.1)
            : _successColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _hasErrorGuru
              ? _accentColor.withValues(alpha: 0.3)
              : _successColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _hasErrorGuru ? Icons.error_outline : Icons.check_circle_outline,
            color: _hasErrorGuru ? _accentColor : _successColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _statusMessageGuru,
              style: TextStyle(
                color: _hasErrorGuru ? _accentColor : _successColor,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

// Dropdown untuk Pilih Guru Pembimbing - UKURAN BESAR
  Widget _buildGuruDropdown() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_search,
                  color: _primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih Guru Pembimbing',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Surat tugas akan dibuat untuk guru yang dipilih',
                      style: TextStyle(
                        fontSize: 14,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _infoColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_guruPembimbing.length} Guru',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _infoColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // DROPDOWN GURU - UKURAN SANGAT BESAR
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: _borderColor, width: 1.8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: DropdownButtonFormField<Map<String, dynamic>>(
              initialValue: _selectedGuru,
              hint: const Text(
                '-- Pilih Guru Pembimbing --',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 14,
                ),
              ),
              isExpanded: true,
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Icon(Icons.person, color: _primaryColor, size: 28),
                ),
                suffixIcon: _selectedGuru != null
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            size: 24, color: _textSecondary),
                        onPressed: () {
                          setState(() {
                            _selectedGuru = null;
                          });
                        },
                      )
                    : null,
              ),
              icon: const Padding(
                padding: EdgeInsets.all(14),
                child:
                    Icon(Icons.arrow_drop_down, color: _primaryColor, size: 36),
              ),
              dropdownColor: Colors.white,
              style: const TextStyle(
                fontSize: 17,
                color: _textPrimary,
                fontWeight: FontWeight.w500,
              ),
              menuMaxHeight: 450,
              // selectedItemBuilder untuk mengubah tampilan item yang terpilih
              selectedItemBuilder: (BuildContext context) {
                return _guruPembimbing.map((guru) {
                  return Container(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      guru['nama'] ?? 'N/A',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 17,
                        color: _textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList();
              },
              items: _guruPembimbing.map((guru) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: guru,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.school,
                            color: _primaryColor,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                guru['nama'] ?? 'N/A',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 17,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (Map<String, dynamic>? newValue) {
                setState(() {
                  _selectedGuru = newValue;
                });
              },
            ),
          ),

          const SizedBox(height: 20),

          // Selected Guru Info Card
          if (_selectedGuru != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: _primaryColor.withValues(alpha: 0.2), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _primaryColor.withValues(alpha: 0.9),
                          _primaryColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedGuru!['nama'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: _successColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Guru Pembimbing PKL',
                            style: TextStyle(
                              fontSize: 13,
                              color: _successColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // Generate Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoadingGuru || _selectedGuru == null
                  ? null
                  : _generateSuratTugas,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 18),
                elevation: 0,
              ),
              icon: _isLoadingGuru
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.file_download_outlined, size: 24),
              label: Text(
                _isLoadingGuru
                    ? 'Memproses...'
                    : _selectedGuru == null
                        ? 'Pilih Guru Terlebih Dahulu'
                        : 'Buat Surat Tugas',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== LEMBAR PERSETUJUAN SECTION ====================
  Future<void> _loadDataSiswa() async {
    if (_isLoadingSiswa) return;

    setState(() {
      _isLoadingSiswa = true;
      _statusMessageSiswa = '';
      _selectedSiswaIds.clear();
      _selectedIndustri = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        _redirectToLogin();
        return;
      }

      final response = await http.get(
        Uri.parse(
            '${dotenv.env['API_BASE_URL']}/api/pkl/applications?status=Approved'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 401) {
        _showErrorSnackbar('Sesi telah berakhir, silakan login kembali');
        _redirectToLogin();
        return;
      }

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);

        List<dynamic> applications = [];

        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data')) {
            applications = responseData['data'] ?? [];
          } else if (responseData.containsKey('success') &&
              responseData['success'] == true) {
            applications = responseData['data'] ?? [];
          }
        } else if (responseData is List) {
          applications = responseData;
        }

        _siswaByIndustri = {};
        _industriList = [];

        for (var app in applications) {
          try {
            if (app is! Map<String, dynamic>) continue;

            final appMap = app;
            final applicationData =
                appMap['application'] as Map<String, dynamic>?;
            final siswaId = applicationData?['siswa_id']?.toString();
            final industriNama = appMap['industri_nama']?.toString() ??
                'Industri Tidak Diketahui';

            if (siswaId != null && industriNama.isNotEmpty) {
              final siswaData = {
                'id': siswaId,
                'nama': appMap['siswa_username']?.toString() ?? 'Siswa',
                'kelas': appMap['kelas_nama']?.toString() ?? '-',
                'industri': industriNama,
                'status': applicationData?['status']?.toString() ?? 'Approved',
                'nisn': appMap['siswa_nisn']?.toString() ?? '',
              };

              if (!_siswaByIndustri.containsKey(industriNama)) {
                _siswaByIndustri[industriNama] = [];
              }
              _siswaByIndustri[industriNama]!.add(siswaData);

              if (!_industriList.contains(industriNama)) {
                _industriList.add(industriNama);
              }
            }
          } catch (e) {
            print('Error processing application: $e');
          }
        }

        _industriList.sort();

        setState(() {
          _hasErrorSiswa = false;
          _selectedDate = DateTime.now();
        });
      } else {
        throw Exception('HTTP ${response.statusCode}: Gagal memuat data siswa');
      }
    } catch (e) {
      print('Error loading siswa: $e');
      setState(() {
        _statusMessageSiswa = '❌ Error: ${e.toString()}';
        _hasErrorSiswa = true;
      });
      _showErrorSnackbar('Gagal memuat data siswa: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSiswa = false;
        });
      }
    }
  }

// Dropdown untuk Pilih Industri - UKURAN BESAR
  Widget _buildIndustriDropdown() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.factory,
                  color: _primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih Industri / DU/DI',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Lembar persetujuan akan dibuat untuk industri yang dipilih',
                      style: TextStyle(
                        fontSize: 14,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _infoColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_industriList.length} Industri',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _infoColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // DROPDOWN INDUSTRI - UKURAN SANGAT BESAR
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: _borderColor, width: 1.8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedIndustri,
              hint: const Text(
                '-- Pilih Industri --',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 17,
                ),
              ),
              isExpanded: true,
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Icon(Icons.apartment, color: _primaryColor, size: 28),
                ),
                suffixIcon: _selectedIndustri != null
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            size: 24, color: _textSecondary),
                        onPressed: () {
                          setState(() {
                            _selectedIndustri = null;
                            _selectedSiswaIds.clear();
                          });
                        },
                      )
                    : null,
              ),
              icon: const Padding(
                padding: EdgeInsets.all(14),
                child:
                    Icon(Icons.arrow_drop_down, color: _primaryColor, size: 36),
              ),
              dropdownColor: Colors.white,
              style: const TextStyle(
                fontSize: 17,
                color: _textPrimary,
                fontWeight: FontWeight.w500,
              ),
              menuMaxHeight: 450,
              // selectedItemBuilder untuk mengubah tampilan item yang terpilih
              selectedItemBuilder: (BuildContext context) {
                return _industriList.map((industri) {
                  return Container(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      industri,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 17,
                        color: _textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList();
              },
              items: _industriList.map((industri) {
                final siswaCount = _siswaByIndustri[industri]?.length ?? 0;

                return DropdownMenuItem<String>(
                  value: industri,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.business,
                            color: _primaryColor,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                industri,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 17,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$siswaCount siswa',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: _textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedIndustri = newValue;
                  _selectedSiswaIds.clear();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateLembarPersetujuan() async {
    if (_isLoadingSiswa) return;

    if (_selectedIndustri == null || _selectedIndustri!.isEmpty) {
      _showErrorSnackbar('Pilih industri terlebih dahulu');
      return;
    }

    if (_selectedSiswaIds.isEmpty) {
      _showErrorSnackbar('Pilih minimal 1 siswa dari industri ini');
      return;
    }

    setState(() {
      _isLoadingSiswa = true;
      _hasErrorSiswa = false;
      _statusMessageSiswa = 'Membuat Lembar Persetujuan...';
    });

    try {
      const String apiBaseUrl = 'https://sertif.gedanggoreng.com';
      const String endpoint = '$apiBaseUrl/api/v1/letters/lembar-persetujuan';

      final selectedStudents = _siswaByIndustri[_selectedIndustri]!
          .where((siswa) => _selectedSiswaIds.contains(siswa['id']))
          .toList();

      final List<Map<String, dynamic>> selectedStudentsData =
          selectedStudents.map((siswa) => {'nama': siswa['nama']}).toList();

      final Map<String, dynamic> requestData = {
        'nama_perusahaan': _selectedIndustri!,
        'school_info': {
          'nama_sekolah': 'SMK NEGERI 2 SINGOSARI',
          'alamat_jalan': 'Jalan Perusahaan No. 20',
          'kab_kota': 'Kab. Malang',
          'kode_pos': '65153',
          'logo_url':
              'https://upload.wikimedia.org/wikipedia/commons/7/74/Coat_of_arms_of_East_Java.svg',
          'provinsi': 'Jawa Timur',
          'telefon': '(0341) 458823'
        },
        'students': selectedStudentsData,
        'tempat_tanggal': _getTempatTanggal(),
      };

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(requestData),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> result = jsonDecode(response.body);

        final String? filename = result['filename'];
        final String? fileUrl = result['file_url'];
        final String? downloadUrl = result['download_url'];

        if (filename != null && (fileUrl != null || downloadUrl != null)) {
          final String finalDownloadUrl = downloadUrl ?? fileUrl!;
          final String fullDownloadUrl = finalDownloadUrl.startsWith('http')
              ? finalDownloadUrl
              : '$apiBaseUrl$finalDownloadUrl';

          setState(() {
            _statusMessageSiswa = '✅ Lembar Persetujuan berhasil dibuat!';
            _hasErrorSiswa = false;
          });

          _showSuccessDialogLembarPersetujuan(_selectedIndustri!, filename,
              fullDownloadUrl, selectedStudents.length);
        } else {
          throw Exception('Format response tidak lengkap');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error generate lembar persetujuan: $e');
      setState(() {
        _statusMessageSiswa = '❌ Gagal: ${e.toString()}';
        _hasErrorSiswa = true;
      });
      _showErrorSnackbar('Gagal membuat lembar persetujuan: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSiswa = false;
        });
      }
    }
  }

  // Status Banner untuk Lembar Persetujuan
  Widget _buildStatusBannerSiswa() {
    if (_statusMessageSiswa.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _hasErrorSiswa
            ? _accentColor.withValues(alpha: 0.1)
            : _successColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _hasErrorSiswa
              ? _accentColor.withValues(alpha: 0.3)
              : _successColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _hasErrorSiswa ? Icons.error_outline : Icons.check_circle_outline,
            color: _hasErrorSiswa ? _accentColor : _successColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _statusMessageSiswa,
              style: TextStyle(
                color: _hasErrorSiswa ? _accentColor : _successColor,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Student Card for each siswa dengan checkbox
  Widget _buildSiswaCard(Map<String, dynamic> siswa) {
    final isSelected = _selectedSiswaIds.contains(siswa['id']);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? _primaryColor : _borderColor,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedSiswaIds.add(siswa['id']);
                  } else {
                    _selectedSiswaIds.remove(siswa['id']);
                  }
                });
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              activeColor: _primaryColor,
            ),
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.person,
                color: _primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    siswa['nama'] ?? 'Siswa',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${siswa['kelas']}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _successColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _successColor.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'Approved',
                style: TextStyle(
                  fontSize: 11,
                  color: _successColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Form input untuk Lembar Persetujuan
  Widget _buildInputForm() {
    final selectedStudents = _selectedIndustri != null
        ? _siswaByIndustri[_selectedIndustri!] ?? []
        : [];

    final selectedCount = _selectedSiswaIds.length;

    if (_selectedIndustri == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.business,
                    color: _primaryColor,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pilih Industri Terlebih Dahulu',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pilih industri/DU/DI untuk melihat daftar siswa',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: _primaryColor.withValues(alpha: 0.2), width: 1.5),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _primaryColor.withValues(alpha: 0.9),
                              _primaryColor,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.apartment,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Industri / DU/DI',
                              style: TextStyle(
                                fontSize: 14,
                                color: _textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedIndustri!,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: _textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Dipilih',
                              style: TextStyle(
                                fontSize: 12,
                                color: _textSecondary,
                              ),
                            ),
                            Text(
                              '$selectedCount/${selectedStudents.length}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: _primaryColor,
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
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _infoColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _infoColor.withValues(alpha: 0.2), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _infoColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.calendar_today,
                      color: _infoColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tanggal Pembuatan',
                          style: TextStyle(
                            fontSize: 13,
                            color: _textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getTempatTanggal(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: selectedStudents.isNotEmpty
                        ? () {
                            setState(() {
                              final allIds = selectedStudents
                                  .map((s) => s['id'] as String)
                                  .toList();
                              if (_selectedSiswaIds.length == allIds.length) {
                                _selectedSiswaIds.clear();
                              } else {
                                _selectedSiswaIds = List.from(allIds);
                              }
                            });
                          }
                        : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          _selectedSiswaIds.length == selectedStudents.length
                              ? _accentColor
                              : _primaryColor,
                      side: BorderSide(
                        color:
                            _selectedSiswaIds.length == selectedStudents.length
                                ? _accentColor
                                : _primaryColor.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: Icon(
                      _selectedSiswaIds.length == selectedStudents.length
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 20,
                    ),
                    label: Text(
                      _selectedSiswaIds.length == selectedStudents.length
                          ? 'Batal Pilih Semua'
                          : 'Pilih Semua',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectedSiswaIds.isNotEmpty && !_isLoadingSiswa
                        ? _generateLembarPersetujuan
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    icon: _isLoadingSiswa
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.file_download_outlined, size: 22),
                    label: Text(
                      _isLoadingSiswa ? 'Memproses...' : 'Buat Lembar',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daftar Siswa di Industri Ini',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _successColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$selectedCount/${selectedStudents.length} terpilih',
                    style: const TextStyle(
                      fontSize: 14,
                      color: _successColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== DIALOGS ====================
  void _showSuccessDialogSuratTugas(
      String namaGuru, String filename, String downloadUrl) {
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
                    colors: [
                      _primaryColor,
                      _primaryColor.withValues(alpha: 0.8)
                    ],
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Berhasil!',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Surat Tugas telah dibuat',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.9),
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
                        color: _backgroundLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _borderColor, width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              color: _primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Untuk Guru',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  namaGuru,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: _textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _backgroundLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _borderColor, width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _infoColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.insert_drive_file,
                              color: _infoColor,
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
                                    color: _textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  filename,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Siap untuk diunduh',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _successColor,
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
                  border:
                      Border(top: BorderSide(color: _borderColor, width: 1)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: _textSecondary.withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Nanti Saja',
                          style: TextStyle(
                            color: _textSecondary,
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
                          _launchUrl(downloadUrl);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
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
                            Icon(Icons.download, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Unduh File',
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

  void _showSuccessDialogLembarPersetujuan(String namaPerusahaan,
      String filename, String downloadUrl, int jumlahSiswa) {
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
                    colors: [
                      _primaryColor,
                      _primaryColor.withValues(alpha: 0.8)
                    ],
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Berhasil!',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Lembar Persetujuan telah dibuat',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.9),
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
                        color: _backgroundLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _borderColor, width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.apartment,
                              color: _primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Untuk Perusahaan',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  namaPerusahaan,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: _textPrimary,
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
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _backgroundLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _borderColor, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _infoColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.insert_drive_file,
                                  color: _infoColor,
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
                                        color: _textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      filename,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _successColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: _successColor.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.people,
                                  color: _successColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$jumlahSiswa siswa terdaftar',
                                  style: const TextStyle(
                                    color: _successColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
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
                  border:
                      Border(top: BorderSide(color: _borderColor, width: 1)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: _textSecondary.withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Nanti Saja',
                          style: TextStyle(
                            color: _textSecondary,
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
                          _launchUrl(downloadUrl);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
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
                            Icon(Icons.download, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Unduh File',
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

  // ==================== BUILD METHOD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: const Text(
          'Cetak Dokumen',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _primaryColor,
          ),
        ),
        iconTheme: const IconThemeData(color: _primaryColor),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _primaryColor,
          unselectedLabelColor: _textSecondary,
          indicatorColor: _primaryColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Surat Tugas'),
            Tab(text: 'Lembar Persetujuan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: SURAT TUGAS
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Surat Tugas Guru Pembimbing',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: _textPrimary,
                                    height: 1.2,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Buat surat tugas resmi untuk guru pembimbing PKL',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildStatusBannerGuru(),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                _isLoadingGuru
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: _primaryColor,
                              strokeWidth: 3,
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Memuat data guru...',
                              style: TextStyle(
                                color: _textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _guruPembimbing.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.group_off,
                                  color: _textSecondary.withValues(alpha: 0.3),
                                  size: 80,
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Tidak Ada Data Guru',
                                  style: TextStyle(
                                    color: _textSecondary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 40),
                                  child: Text(
                                    'Belum ada guru yang terdaftar sebagai pembimbing PKL',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color:
                                          _textSecondary.withValues(alpha: 0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _buildGuruDropdown(),
              ],
            ),
          ),

          // TAB 2: LEMBAR PERSETUJUAN
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Lembar Persetujuan PKL',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: _textPrimary,
                                    height: 1.2,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Pilih industri/DU/DI dan siswa untuk membuat lembar persetujuan',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildStatusBannerSiswa(),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                _isLoadingSiswa
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Column(
                            children: [
                              CircularProgressIndicator(
                                color: _primaryColor,
                                strokeWidth: 3,
                              ),
                              SizedBox(height: 20),
                              Text(
                                'Memuat data siswa...',
                                style: TextStyle(
                                  color: _textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _industriList.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.business_center,
                                  color: _textSecondary.withValues(alpha: 0.3),
                                  size: 80,
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Belum Ada Data Industri',
                                  style: TextStyle(
                                    color: _textSecondary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Text(
                                    'Belum ada pengajuan PKL dengan status Approved',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color:
                                          _textSecondary.withValues(alpha: 0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              _buildIndustriDropdown(),
                              const SizedBox(height: 20),
                              _buildInputForm(),
                              const SizedBox(height: 20),
                              if (_selectedIndustri != null &&
                                  _siswaByIndustri[_selectedIndustri] != null &&
                                  _siswaByIndustri[_selectedIndustri]!
                                      .isNotEmpty)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.05),
                                        blurRadius: 15,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ..._siswaByIndustri[_selectedIndustri]!
                                            .map((siswa) {
                                          return _buildSiswaCard(siswa);
                                        }),
                                      ],
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 40),
                            ],
                          ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
