import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../login/login_screen.dart';

class KoordinatorGenerateSurat extends StatefulWidget {
  const KoordinatorGenerateSurat({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  State<KoordinatorGenerateSurat> createState() =>
      _KoordinatorGenerateSuratState();
}

class _KoordinatorGenerateSuratState extends State<KoordinatorGenerateSurat> {
  // Professional Color Palette (sama dengan KoordinatorData)
  static const Color _primaryColor = Color(0xFF641E20);
  static const Color _accentColor = Color(0xFFE74C3C);
  static const Color _successColor = Color(0xFF27AE60);
  static const Color _infoColor = Color(0xFF3498DB);
  static const Color _backgroundLight = Color(0xFFF8F9FA);
  static const Color _borderColor = Color(0xFFE1E8ED);
  static const Color _textPrimary = Color(0xFF2C3E50);
  static const Color _textSecondary = Color(0xFF7F8C8D);

  bool _isLoading = false;
  bool _isLoadingSiswa = false;
  String _statusMessage = '';
  bool _hasError = false;

  // Data dari API
  Map<String, List<Map<String, dynamic>>> _siswaByIndustri = {};
  List<String> _industriList = [];
  String? _selectedIndustri;
  List<String> _selectedSiswaIds = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _checkTokenAndLoadData();
  }

  @override
  void dispose() {
    super.dispose();
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

  String _getTempatTanggal() {
    return 'Singosari, ${_formatDate(_selectedDate)}';
  }

  // Format tanggal untuk PDF
  String formatTanggalIndonesia(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '..............';
    try {
      final date = DateTime.parse(isoString);
      const monthNames = [
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
      return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
    } catch (e) {
      return isoString;
    }
  }

  // Load authentication token dan data siswa
  Future<void> _checkTokenAndLoadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        _redirectToLogin();
        return;
      }

      await _loadDataSiswa();
    } catch (e) {
      print('Error loading token: $e');
      setState(() {
        _statusMessage = 'Error: $e';
        _hasError = true;
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

  // ==================== LOAD DATA SISWA DARI API ====================
  Future<void> _loadDataSiswa() async {
    if (_isLoadingSiswa) return;

    setState(() {
      _isLoadingSiswa = true;
      _statusMessage = '';
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
                'jurusan': appMap['jurusan_nama']?.toString() ?? '-',
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
          _hasError = false;
          _selectedDate = DateTime.now();
        });
      } else {
        throw Exception('HTTP ${response.statusCode}: Gagal memuat data siswa');
      }
    } catch (e) {
      print('Error loading siswa: $e');
      setState(() {
        _statusMessage = '❌ Error: ${e.toString()}';
        _hasError = true;
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

  // ==================== GENERATE SURAT PERMOHONAN ====================
  Future<void> _generateSuratPermohonan() async {
    if (_isLoading) return;

    if (_selectedIndustri == null || _selectedIndustri!.isEmpty) {
      _showErrorSnackbar('Pilih industri terlebih dahulu');
      return;
    }

    if (_selectedSiswaIds.isEmpty) {
      _showErrorSnackbar('Pilih minimal 1 siswa dari industri ini');
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _statusMessage = 'Membuat Surat Permohonan...';
    });

    try {
      // Load logo
      final ByteData imageData =
          await rootBundle.load('assets/images/jatimm.png');
      final Uint8List imageBytes = imageData.buffer.asUint8List();
      final pw.MemoryImage logo = pw.MemoryImage(imageBytes);

      // Ambil data siswa yang dipilih
      final selectedStudents = _siswaByIndustri[_selectedIndustri]!
          .where((siswa) => _selectedSiswaIds.contains(siswa['id']))
          .toList();

      // Buat PDF
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // KOP SURAT
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 65,
                      height: 65,
                      child: pw.Image(logo),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Column(
                        children: [
                          pw.Text(
                            'PEMERINTAH PROVINSI JAWA TIMUR',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            'DINAS PENDIDIKAN',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'SMK NEGERI 2 SINGOSARI',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Jalan Perusahaan No. 20, Tunjungtirto, Singosari, Kab. Malang, Jawa Timur, 65153',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                          pw.Text(
                            'Telepon (0341) 4345127',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 8),
                pw.Container(height: 0.8, color: PdfColors.black),
                pw.Container(
                    height: 0.2,
                    color: PdfColors.black,
                    margin: const pw.EdgeInsets.only(top: 1)),
                pw.SizedBox(height: 15),

                // TANGGAL SURAT
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text(
                      _getTempatTanggal(),
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),

                pw.SizedBox(height: 15),

                // META DATA SURAT
                pw.Row(
                  children: [
                    pw.Text('Nomor      : 400.3 / 001 / 101.6.9.19 / 2025',
                        style: const pw.TextStyle(fontSize: 11)),
                  ],
                ),
                pw.Row(
                  children: [
                    pw.Text('Lampiran   : -',
                        style: const pw.TextStyle(fontSize: 11)),
                  ],
                ),
                pw.Row(
                  children: [
                    pw.Text('Perihal     : ',
                        style: const pw.TextStyle(fontSize: 11)),
                    pw.Text('Permohonan Praktik Kerja Lapangan (PKL)',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          decoration: pw.TextDecoration.underline,
                        )),
                  ],
                ),

                pw.SizedBox(height: 20),

                // TUJUAN SURAT
                pw.Text('Kepada Yth,', style: const pw.TextStyle(fontSize: 11)),
                pw.Text('Pimpinan $_selectedIndustri',
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.Text('di -', style: const pw.TextStyle(fontSize: 11)),
                pw.Text('Tempat', style: const pw.TextStyle(fontSize: 11)),

                pw.SizedBox(height: 20),

                // ISI SURAT
                pw.Text(
                  'Dengan ini kami sampaikan bahwa kegiatan Praktik Kerja Lapangan (PKL) '
                  'siswa-siswi SMK Negeri 2 Singosari akan dilaksanakan sekitar tanggal '
                  '${formatTanggalIndonesia(DateTime.now().toIso8601String())} s.d '
                  '${formatTanggalIndonesia(DateTime.now().add(const Duration(days: 90)).toIso8601String())}. '
                  'Sehubungan dengan hal tersebut, kami mohon agar siswa-siswi kami dapat '
                  'diterima di Instansi/Industri yang Bapak/Ibu pimpin. Adapun siswa-siswi '
                  'yang akan kami ajukan untuk melaksanakan Praktik Kerja Lapangan (PKL) '
                  'di Instansi/Industri yang Bapak/Ibu pimpin adalah sebanyak '
                  '${selectedStudents.length} orang, sebagai berikut:',
                  style: const pw.TextStyle(fontSize: 11),
                  textAlign: pw.TextAlign.justify,
                ),

                pw.SizedBox(height: 15),

                // TABEL SISWA
                pw.Container(
                  margin: const pw.EdgeInsets.symmetric(horizontal: 10),
                  child: pw.Table(
                    border: pw.TableBorder.all(),
                    children: [
                      // HEADER
                      pw.TableRow(
                        decoration:
                            const pw.BoxDecoration(color: PdfColors.grey300),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('NO',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold),
                                textAlign: pw.TextAlign.center),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('NAMA SISWA',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold),
                                textAlign: pw.TextAlign.center),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('KELAS',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold),
                                textAlign: pw.TextAlign.center),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('JURUSAN',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold),
                                textAlign: pw.TextAlign.center),
                          ),
                        ],
                      ),
                      // BODY
                      ...selectedStudents.asMap().entries.map((entry) {
                        final int index = entry.key;
                        final Map<String, dynamic> student = entry.value;
                        return pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text('${index + 1}',
                                  textAlign: pw.TextAlign.center),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(student['nama']!,
                                  textAlign: pw.TextAlign.left),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(student['kelas']!,
                                  textAlign: pw.TextAlign.center),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(student['jurusan']!,
                                  textAlign: pw.TextAlign.center),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                // PENUTUP
                pw.Text(
                  'Demikian surat permohonan ini kami ajukan. Atas perhatian dan kerjasama '
                  'yang baik, kami sampaikan terima kasih.',
                  style: const pw.TextStyle(fontSize: 11),
                  textAlign: pw.TextAlign.justify,
                ),

                pw.SizedBox(height: 25),

                // TANDA TANGAN
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Kepala SMK Negeri 2 Singosari,',
                            style: const pw.TextStyle(fontSize: 11)),
                        pw.SizedBox(height: 25),
                        pw.Text('SUMIJAH, S.Pd., M.Si.',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              decoration: pw.TextDecoration.underline,
                            )),
                        pw.Text('Pembina Utama Muda (IV/c)',
                            style: const pw.TextStyle(fontSize: 11)),
                        pw.Text('NIP. 19700210 199802 2 009',
                            style: const pw.TextStyle(fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      // Simpan PDF ke bytes
      final Uint8List bytes = await pdf.save();

      // Simpan ke file dan share/download
      await Printing.sharePdf(
        bytes: bytes,
        filename:
            'Surat_Permohonan_PKL_${_selectedIndustri}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      setState(() {
        _statusMessage = '✅ Surat Permohonan berhasil dibuat!';
        _hasError = false;
      });

      _showSuccessDialog(
        _selectedIndustri!,
        selectedStudents.length,
      );
    } catch (e) {
      print('Error generate surat: $e');
      setState(() {
        _statusMessage = '❌ Gagal: ${e.toString()}';
        _hasError = true;
      });
      _showErrorSnackbar('Gagal membuat surat: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Status Banner
  Widget _buildStatusBanner() {
    if (_statusMessage.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _hasError
            ? _accentColor.withValues(alpha: 0.1)
            : _successColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _hasError
              ? _accentColor.withValues(alpha: 0.3)
              : _successColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _hasError ? Icons.error_outline : Icons.check_circle_outline,
            color: _hasError ? _accentColor : _successColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _statusMessage,
              style: TextStyle(
                color: _hasError ? _accentColor : _successColor,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
// Dropdown untuk Pilih Industri (tanpa icon)
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
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Surat permohonan akan dibuat untuk industri yang dipilih',
                    style: TextStyle(
                      fontSize: 14,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

        // DROPDOWN INDUSTRI (TANPA ICON)
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              prefixIcon: const Padding(
                padding: EdgeInsets.all(14),
                child: Icon(Icons.apartment, color: _primaryColor, size: 28),
              ),
              suffixIcon: _selectedIndustri != null
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 24, color: _textSecondary),
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
              child: Icon(Icons.arrow_drop_down, color: _primaryColor, size: 36),
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
  // Student Card untuk setiap siswa dengan checkbox
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
                    '${siswa['kelas']} - ${siswa['jurusan']}',
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
              child: Text(
                siswa['status'] ?? 'Approved',
                style: const TextStyle(
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

  // Main Content setelah memilih industri
  Widget _buildMainContent() {
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
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.business,
                    color: _primaryColor,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Pilih Industri Terlebih Dahulu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Pilih industri/DU/DI untuk melihat daftar siswa',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
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
            // Industri Info Card
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

            // Tanggal Pembuatan
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
                          'Tanggal Pembuatan Surat',
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

            // Selection Controls
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
                          : 'Pilih Semua Siswa',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectedSiswaIds.isNotEmpty && !_isLoading
                        ? _generateSuratPermohonan
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
                    icon: _isLoading
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
                      _isLoading ? 'Memproses...' : 'Buat Surat',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Student Count
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

            const SizedBox(height: 16),

            // Student List
            ...selectedStudents.map((siswa) => _buildSiswaCard(siswa)),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(String industri, int jumlahSiswa) {
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
                            'Surat Permohonan PKL telah dibuat',
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
                                  industri,
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
                                      'Surat_Permohonan_PKL_$industri.pdf',
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
                          'Tutup',
                          style: TextStyle(
                            color: _textSecondary,
                            fontWeight: FontWeight.w600,
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: const Text(
          'Surat Permohonan PKL',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _primaryColor,
          ),
        ),
        iconTheme: const IconThemeData(color: _primaryColor),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDataSiswa,
        color: _primaryColor,
        child: SingleChildScrollView(
          controller: widget.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
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
                                'Cetak Surat Permohonan PKL',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: _textPrimary,
                                  height: 1.2,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Pilih industri/DU/DI dan siswa untuk membuat surat permohonan PKL',
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
                    _buildStatusBanner(),
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
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
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: _loadDataSiswa,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Muat Ulang Data'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            _buildIndustriDropdown(),
                            const SizedBox(height: 20),
                            _buildMainContent(),
                          ],
                        ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
