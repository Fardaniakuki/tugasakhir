import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class KoordinatorData extends StatefulWidget {
  const KoordinatorData({super.key});

  @override
  State<KoordinatorData> createState() => _KoordinatorDataState();
}

class _KoordinatorDataState extends State<KoordinatorData> {
  // WARNA SAMA DENGAN PEMBIMBING
  static const Color _primaryColor = Color(0xFF641E20);
  
  static const Color _textSecondary = Color(0xFF666666);
  static const Color _greenColor = Color(0xFF4CAF50);
  static const Color _redColor = Color(0xFFF44336);
  static const Color _blueColor = Color(0xFF2196F3);
  static const Color _borderColor = Color(0xFFE0E0E0);

  // State variables
  bool _isLoadingSuratTugas = false;
  bool _isLoadingPersetujuan = false;
  String _statusMessage = '';
  bool _hasError = false;
  String? _downloadUrl;
  String? _filename;

  // API Base URL
  final String _apiBaseUrl = 'https://sertif.gedanggoreng.com';

  // Form controllers untuk Surat Tugas
  final TextEditingController _nomorSuratController = TextEditingController(text: '800/123/SMK.2/2024');
  final TextEditingController _tanggalSuratController = TextEditingController(text: '1 Juli 2024');
  final TextEditingController _tempatSuratController = TextEditingController(text: 'Singosari');
  final TextEditingController _perihalController = TextEditingController(text: 'SURAT TUGAS');
  
  // School Info
  final TextEditingController _namaSekolahController = TextEditingController(text: 'SMK NEGERI 2 SINGOSARI');
  final TextEditingController _alamatSekolahController = TextEditingController(text: 'Jalan Perusahaan No. 20');
  final TextEditingController _kelurahanController = TextEditingController(text: 'Tunjungtirto');
  final TextEditingController _kecamatanController = TextEditingController(text: 'Singosari');
  final TextEditingController _kabKotaController = TextEditingController(text: 'Kab. Malang');
  final TextEditingController _provinsiController = TextEditingController(text: 'Jawa Timur');
  final TextEditingController _kodePosController = TextEditingController(text: '65153');
  final TextEditingController _teleponController = TextEditingController(text: '(0341) 4345127');
  final TextEditingController _emailController = TextEditingController(text: 'smkn2singosari@yahoo.co.id');
  final TextEditingController _websiteController = TextEditingController(text: 'www.smkn2singosari.sch.id');
  final TextEditingController _logoUrlController = TextEditingController(text: 'https://upload.wikimedia.org/wikipedia/commons/d/d6/Logo_SMKN_2_Singosari.png');
  
  // Penandatangan
  final TextEditingController _namaPenandatanganController = TextEditingController(text: 'SUMIJAH, S.Pd., M.Si.');
  final TextEditingController _jabatanPenandatanganController = TextEditingController(text: 'Kepala SMK Negeri 2 Singosari');
  final TextEditingController _nipPenandatanganController = TextEditingController(text: '19700210 199802 2 009');
  final TextEditingController _pangkatPenandatanganController = TextEditingController(text: 'Pembina Tk. I');
  
  // Assignees (Penerima Tugas)
  final List<Map<String, TextEditingController>> _assigneesControllers = [
    {
      'nama': TextEditingController(text: 'Inasni Dyah Rahmatika, S.Pd.'),
      'jabatan': TextEditingController(text: 'Guru'),
      'nip': TextEditingController(text: '19850101 201001 2 005'),
      'pangkat': TextEditingController(text: ''),
      'instansi': TextEditingController(text: 'SMK Negeri 2 Singosari'),
    },
    {
      'nama': TextEditingController(text: 'Budi Santoso, S.Kom.'),
      'jabatan': TextEditingController(text: 'Guru Kejuruan'),
      'nip': TextEditingController(text: ''),
      'pangkat': TextEditingController(text: ''),
      'instansi': TextEditingController(text: 'SMK Negeri 2 Singosari'),
    },
  ];
  
  // Details (Detail Tugas)
  final List<Map<String, TextEditingController>> _detailsControllers = [
    {
      'label': TextEditingController(text: 'Keperluan'),
      'value': TextEditingController(text: 'Pengantaran Siswa Praktik Kerja Lapangan (PKL)'),
      'separator': TextEditingController(text: ':'),
    },
    {
      'label': TextEditingController(text: 'Hari / Tanggal'),
      'value': TextEditingController(text: 'Senin, 1 Juli 2024'),
      'separator': TextEditingController(text: ':'),
    },
    {
      'label': TextEditingController(text: 'Waktu'),
      'value': TextEditingController(text: '08.00 - Selesai'),
      'separator': TextEditingController(text: ':'),
    },
    {
      'label': TextEditingController(text: 'Tempat'),
      'value': TextEditingController(text: 'BACAMALANG.COM'),
      'separator': TextEditingController(text: ':'),
    },
    {
      'label': TextEditingController(text: 'Alamat'),
      'value': TextEditingController(text: 'JL. MOROJANTEK NO. 87 B, PANGENTAN, KEC. SINGOSARI, KAB. MALANG'),
      'separator': TextEditingController(text: ':'),
    },
  ];
  
  final TextEditingController _pembukaController = TextEditingController(text: 'Kepala SMK Negeri 2 Singosari Dinas Pendidikan Kabupaten Malang menugaskan kepada :');
  final TextEditingController _penutupController = TextEditingController(text: 'Demikian surat tugas ini dibuat untuk dilaksanakan dengan sebaik-baiknya dan melaporkan hasilnya kepada kepala sekolah.');

  // Form controllers untuk Lembar Persetujuan
  final TextEditingController _namaPerusahaanController = TextEditingController(text: 'JTV MALANG');
  final TextEditingController _tempatTanggalController = TextEditingController(text: 'Malang, 12 Januari 2026');
  final List<TextEditingController> _namaSiswaPersetujuanControllers = [
    TextEditingController(text: 'CHANDA ZULIA LESTARI'),
    TextEditingController(text: 'DIWA SASRI HALIA'),
  ];

  // Function to launch URL
  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $urlString');
    }
  }

  // Function to download file
  Future<void> _downloadFile(String url, String filename) async {
    try {
      final Uri fullUrl = Uri.parse('$_apiBaseUrl$url');
      if (!await launchUrl(fullUrl, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $fullUrl');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Membuka file: $filename'),
          backgroundColor: _greenColor,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: _redColor,
        ),
      );
    }
  }

  // Function to view file
  Future<void> _viewFile(String url) async {
    try {
      final Uri fullUrl = Uri.parse('$_apiBaseUrl$url');
      await _launchUrl(fullUrl.toString());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tidak dapat membuka file: $e'),
          backgroundColor: _redColor,
        ),
      );
    }
  }

  // Function to generate Surat Tugas
  Future<void> _generateSuratTugas() async {
    setState(() {
      _isLoadingSuratTugas = true;
      _hasError = false;
      _statusMessage = 'Sedang membuat Surat Tugas...';
      _downloadUrl = null;
      _filename = null;
    });

    try {
      // Prepare assignees data
      final List<Map<String, String>> assignees = _assigneesControllers
          .where((assignee) => assignee['nama']!.text.trim().isNotEmpty)
          .map((assignee) => {
                'nama': assignee['nama']!.text.trim(),
                'jabatan': assignee['jabatan']!.text.trim(),
                'nip': assignee['nip']!.text.trim(),
                'pangkat': assignee['pangkat']!.text.trim(),
                'instansi': assignee['instansi']!.text.trim(),
              })
          .toList();

      if (assignees.isEmpty) {
        throw Exception('Minimal 1 penerima tugas harus diisi');
      }

      // Prepare details data
      final List<Map<String, String>> details = _detailsControllers
          .where((detail) => detail['label']!.text.trim().isNotEmpty && detail['value']!.text.trim().isNotEmpty)
          .map((detail) => {
                'label': detail['label']!.text.trim(),
                'value': detail['value']!.text.trim(),
                'separator': detail['separator']!.text.trim(),
              })
          .toList();

      if (details.isEmpty) {
        throw Exception('Minimal 1 detail tugas harus diisi');
      }

      final Map<String, dynamic> requestData = {
        'nomor_surat': _nomorSuratController.text.trim(),
        'tanggal_surat': _tanggalSuratController.text.trim(),
        'tempat_surat': _tempatSuratController.text.trim(),
        'perihal': _perihalController.text.trim(),
        'school_info': {
          'nama_sekolah': _namaSekolahController.text.trim(),
          'alamat_jalan': _alamatSekolahController.text.trim(),
          'kelurahan': _kelurahanController.text.trim(),
          'kecamatan': _kecamatanController.text.trim(),
          'kab_kota': _kabKotaController.text.trim(),
          'provinsi': _provinsiController.text.trim(),
          'kode_pos': _kodePosController.text.trim(),
          'telepon': _teleponController.text.trim(),
          'email': _emailController.text.trim(),
          'website': _websiteController.text.trim(),
          'logo_url': _logoUrlController.text.trim(),
        },
        'penandatangan': {
          'nama': _namaPenandatanganController.text.trim(),
          'jabatan': _jabatanPenandatanganController.text.trim(),
          'nip': _nipPenandatanganController.text.trim(),
          'pangkat': _pangkatPenandatanganController.text.trim(),
          'instansi': _namaSekolahController.text.trim(),
        },
        'assignees': assignees,
        'details': details,
        'pembuka': _pembukaController.text.trim(),
        'penutup': _penutupController.text.trim(),
      };

      print('Request Data: ${jsonEncode(requestData)}'); // Debug log

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/api/v1/letters/surat-tugas'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestData),
      );

      print('Response Status: ${response.statusCode}'); // Debug log
      print('Response Body: ${response.body}'); // Debug log

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        
        final String? filename = result['filename'];
        final String? fileUrl = result['file_url'];
        
        if (filename != null && fileUrl != null) {
          _downloadUrl = fileUrl;
          _filename = filename;
          setState(() {
            _statusMessage = '✅ Surat Tugas berhasil dibuat!';
            _hasError = false;
          });
          
          // Show success dialog
          _showResultDialog('SURAT TUGAS', _downloadUrl!, _filename!);
        } else {
          throw Exception('Filename atau file_url tidak ditemukan dalam response');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error: $e'); // Debug log
      setState(() {
        _statusMessage = '❌ Error: ${e.toString()}';
        _hasError = true;
      });
    } finally {
      setState(() {
        _isLoadingSuratTugas = false;
      });
    }
  }

  // Function to generate Lembar Persetujuan
  Future<void> _generateLembarPersetujuan() async {
    setState(() {
      _isLoadingPersetujuan = true;
      _hasError = false;
      _statusMessage = 'Sedang membuat Lembar Persetujuan...';
      _downloadUrl = null;
      _filename = null;
    });

    try {
      // Filter out empty student names
      final List<Map<String, String>> students = _namaSiswaPersetujuanControllers
          .where((controller) => controller.text.trim().isNotEmpty)
          .map((controller) => {
                'nama': controller.text.trim(),
              })
          .toList();

      if (students.isEmpty) {
        throw Exception('Minimal 1 siswa harus diisi');
      }

      final Map<String, dynamic> requestData = {
        'school_info': {
          'nama_sekolah': _namaSekolahController.text.trim(),
          'alamat_jalan': _alamatSekolahController.text.trim(),
          'kab_kota': _kabKotaController.text.trim(),
          'provinsi': _provinsiController.text.trim(),
          'kode_pos': _kodePosController.text.trim(),
          'telepon': _teleponController.text.trim(),
          'logo_url': _logoUrlController.text.trim(),
        },
        'students': students,
        'nama_perusahaan': _namaPerusahaanController.text.trim(),
        'tempat_tanggal': _tempatTanggalController.text.trim(),
      };

      print('Request Data: ${jsonEncode(requestData)}'); // Debug log

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/api/v1/letters/lembar-persetujuan'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestData),
      );

      print('Response Status: ${response.statusCode}'); // Debug log
      print('Response Body: ${response.body}'); // Debug log

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        
        final String? filename = result['filename'];
        final String? fileUrl = result['file_url'];
        
        if (filename != null && fileUrl != null) {
          _downloadUrl = fileUrl;
          _filename = filename;
          setState(() {
            _statusMessage = '✅ Lembar Persetujuan berhasil dibuat!';
            _hasError = false;
          });
          
          // Show success dialog
          _showResultDialog('LEMBAR PERSETUJUAN', _downloadUrl!, _filename!);
        } else {
          throw Exception('Filename atau file_url tidak ditemukan dalam response');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error: $e'); // Debug log
      setState(() {
        _statusMessage = '❌ Error: ${e.toString()}';
        _hasError = true;
      });
    } finally {
      setState(() {
        _isLoadingPersetujuan = false;
      });
    }
  }

  // Show result dialog with view and download options
  void _showResultDialog(String jenisSurat, String downloadUrl, String filename) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _greenColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: _greenColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$jenisSurat Selesai',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'File: $filename',
                            style: const TextStyle(
                              fontSize: 13,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Actions
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _viewFile(downloadUrl);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _blueColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.visibility, size: 20),
                        label: const Text(
                          'LIHAT HASIL',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _downloadFile(downloadUrl, filename);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _greenColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.download, size: 20),
                        label: const Text(
                          'UNDUH PDF',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryColor,
                          side: const BorderSide(color: _primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'TUTUP',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Build form field
  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    bool required = true,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              if (required)
                const Text(
                  '*',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderColor),
            ),
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(16),
                border: InputBorder.none,
                hintText: 'Masukkan $label',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build assignee field
  Widget _buildAssigneeField(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Penerima Tugas ${index + 1}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _primaryColor,
                ),
              ),
              if (_assigneesControllers.length > 1)
                IconButton(
                  onPressed: () {
                    setState(() {
                      _assigneesControllers.removeAt(index);
                    });
                  },
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFormField(
            label: 'Nama',
            controller: _assigneesControllers[index]['nama']!,
            required: true,
          ),
          _buildFormField(
            label: 'Jabatan',
            controller: _assigneesControllers[index]['jabatan']!,
            required: true,
          ),
          _buildFormField(
            label: 'NIP',
            controller: _assigneesControllers[index]['nip']!,
            required: false,
          ),
          _buildFormField(
            label: 'Pangkat',
            controller: _assigneesControllers[index]['pangkat']!,
            required: false,
          ),
          _buildFormField(
            label: 'Instansi',
            controller: _assigneesControllers[index]['instansi']!,
            required: true,
          ),
        ],
      ),
    );
  }

  // Build detail field
  Widget _buildDetailField(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Detail Tugas ${index + 1}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _primaryColor,
                ),
              ),
              if (_detailsControllers.length > 1)
                IconButton(
                  onPressed: () {
                    setState(() {
                      _detailsControllers.removeAt(index);
                    });
                  },
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFormField(
                  label: 'Label',
                  controller: _detailsControllers[index]['label']!,
                  required: true,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 60,
                child: _buildFormField(
                  label: 'Separator',
                  controller: _detailsControllers[index]['separator']!,
                  required: true,
                ),
              ),
            ],
          ),
          _buildFormField(
            label: 'Value',
            controller: _detailsControllers[index]['value']!,
            required: true,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Generator Surat PKL',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF641E20),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Generate dan download surat tugas & lembar persetujuan PKL',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    // Status message
                    if (_statusMessage.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _hasError ? _redColor.withValues(alpha: 0.1) : _greenColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _hasError ? _redColor.withValues(alpha: 0.3) : _greenColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _hasError ? Icons.error : Icons.info,
                              color: _hasError ? _redColor : _greenColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _statusMessage,
                                style: TextStyle(
                                  color: _hasError ? _redColor : _greenColor,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const TabBar(
                  labelColor: Color(0xFF641E20),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Color(0xFF641E20),
                  indicatorWeight: 3,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  tabs: [
                    Tab(text: 'SURAT TUGAS'),
                    Tab(text: 'LEMBAR PERSETUJUAN'),
                  ],
                ),
              ),

              // Tab content
              Expanded(
                child: TabBarView(
                  children: [
                    // SURAT TUGAS TAB
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Data Surat',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF641E20),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          _buildFormField(label: 'Nomor Surat', controller: _nomorSuratController),
                          _buildFormField(label: 'Tanggal Surat', controller: _tanggalSuratController),
                          _buildFormField(label: 'Tempat Surat', controller: _tempatSuratController),
                          _buildFormField(label: 'Perihal', controller: _perihalController),
                          
                          const SizedBox(height: 24),
                          const Text(
                            'Data Sekolah',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF641E20),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          _buildFormField(label: 'Nama Sekolah', controller: _namaSekolahController),
                          _buildFormField(label: 'Alamat Jalan', controller: _alamatSekolahController, maxLines: 2),
                          _buildFormField(label: 'Kelurahan', controller: _kelurahanController),
                          _buildFormField(label: 'Kecamatan', controller: _kecamatanController),
                          _buildFormField(label: 'Kabupaten/Kota', controller: _kabKotaController),
                          _buildFormField(label: 'Provinsi', controller: _provinsiController),
                          _buildFormField(label: 'Kode Pos', controller: _kodePosController),
                          _buildFormField(label: 'Telepon', controller: _teleponController),
                          _buildFormField(label: 'Email', controller: _emailController),
                          _buildFormField(label: 'Website', controller: _websiteController),
                          _buildFormField(label: 'Logo URL', controller: _logoUrlController),
                          
                          const SizedBox(height: 24),
                          const Text(
                            'Penandatangan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF641E20),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          _buildFormField(label: 'Nama Penandatangan', controller: _namaPenandatanganController),
                          _buildFormField(label: 'Jabatan', controller: _jabatanPenandatanganController),
                          _buildFormField(label: 'NIP', controller: _nipPenandatanganController),
                          _buildFormField(label: 'Pangkat', controller: _pangkatPenandatanganController),
                          
                          const SizedBox(height: 24),
                          const Text(
                            'Penerima Tugas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF641E20),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Dynamic list of assignees
                          Column(
                            children: List.generate(
                              _assigneesControllers.length,
                              (index) => _buildAssigneeField(index),
                            ),
                          ),
                          
                          // Add assignee button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _assigneesControllers.add({
                                    'nama': TextEditingController(),
                                    'jabatan': TextEditingController(),
                                    'nip': TextEditingController(),
                                    'pangkat': TextEditingController(),
                                    'instansi': TextEditingController(text: _namaSekolahController.text),
                                  });
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _primaryColor,
                                side: const BorderSide(color: _primaryColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              icon: const Icon(Icons.add, size: 20),
                              label: const Text(
                                'TAMBAH PENERIMA TUGAS',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          const Text(
                            'Detail Tugas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF641E20),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Dynamic list of details
                          Column(
                            children: List.generate(
                              _detailsControllers.length,
                              (index) => _buildDetailField(index),
                            ),
                          ),
                          
                          // Add detail button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _detailsControllers.add({
                                    'label': TextEditingController(),
                                    'value': TextEditingController(),
                                    'separator': TextEditingController(text: ':'),
                                  });
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _primaryColor,
                                side: const BorderSide(color: _primaryColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              icon: const Icon(Icons.add, size: 20),
                              label: const Text(
                                'TAMBAH DETAIL TUGAS',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          const Text(
                            'Paragraf',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF641E20),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          _buildFormField(label: 'Pembuka', controller: _pembukaController, maxLines: 3),
                          _buildFormField(label: 'Penutup', controller: _penutupController, maxLines: 3),
                          
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoadingSuratTugas ? null : _generateSuratTugas,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isLoadingSuratTugas
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : const Text(
                                      'GENERATE SURAT TUGAS',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),

                    // LEMBAR PERSETUJUAN TAB
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Data Perusahaan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF641E20),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          _buildFormField(label: 'Nama Perusahaan', controller: _namaPerusahaanController),
                          _buildFormField(label: 'Tempat & Tanggal', controller: _tempatTanggalController),
                          
                          const SizedBox(height: 24),
                          const Text(
                            'Data Sekolah',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF641E20),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          _buildFormField(label: 'Nama Sekolah', controller: _namaSekolahController),
                          _buildFormField(label: 'Alamat Jalan', controller: _alamatSekolahController, maxLines: 2),
                          _buildFormField(label: 'Kabupaten/Kota', controller: _kabKotaController),
                          _buildFormField(label: 'Provinsi', controller: _provinsiController),
                          _buildFormField(label: 'Kode Pos', controller: _kodePosController),
                          _buildFormField(label: 'Telepon', controller: _teleponController),
                          _buildFormField(label: 'Logo URL', controller: _logoUrlController),
                          
                          const SizedBox(height: 24),
                          const Text(
                            'Daftar Siswa',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF641E20),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Dynamic list of students
                          Column(
                            children: List.generate(
                              _namaSiswaPersetujuanControllers.length,
                              (index) => Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _namaSiswaPersetujuanControllers[index],
                                        decoration: InputDecoration(
                                          labelText: 'Nama Siswa ${index + 1}',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (_namaSiswaPersetujuanControllers.length > 1)
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _namaSiswaPersetujuanControllers.removeAt(index);
                                          });
                                        },
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          // Add student button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _namaSiswaPersetujuanControllers.add(TextEditingController());
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _primaryColor,
                                side: const BorderSide(color: _primaryColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              icon: const Icon(Icons.add, size: 20),
                              label: const Text(
                                'TAMBAH SISWA',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoadingPersetujuan ? null : _generateLembarPersetujuan,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _greenColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isLoadingPersetujuan
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : const Text(
                                      'GENERATE LEMBAR PERSETUJUAN',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 40),
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

  @override
  void dispose() {
    // Dispose all controllers
    _nomorSuratController.dispose();
    _tanggalSuratController.dispose();
    _tempatSuratController.dispose();
    _perihalController.dispose();
    
    _namaSekolahController.dispose();
    _alamatSekolahController.dispose();
    _kelurahanController.dispose();
    _kecamatanController.dispose();
    _kabKotaController.dispose();
    _provinsiController.dispose();
    _kodePosController.dispose();
    _teleponController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _logoUrlController.dispose();
    
    _namaPenandatanganController.dispose();
    _jabatanPenandatanganController.dispose();
    _nipPenandatanganController.dispose();
    _pangkatPenandatanganController.dispose();
    
    for (var assignee in _assigneesControllers) {
      assignee['nama']?.dispose();
      assignee['jabatan']?.dispose();
      assignee['nip']?.dispose();
      assignee['pangkat']?.dispose();
      assignee['instansi']?.dispose();
    }
    
    for (var detail in _detailsControllers) {
      detail['label']?.dispose();
      detail['value']?.dispose();
      detail['separator']?.dispose();
    }
    
    _pembukaController.dispose();
    _penutupController.dispose();
    
    _namaPerusahaanController.dispose();
    _tempatTanggalController.dispose();
    
    for (var controller in _namaSiswaPersetujuanControllers) {
      controller.dispose();
    }
    
    super.dispose();
  }
}