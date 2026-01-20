import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PengajuanMenungguScreen extends StatefulWidget {
  final List<dynamic> pendingApplications;
  
  const PengajuanMenungguScreen({
    super.key,
    required this.pendingApplications,
  });

  @override
  State<PengajuanMenungguScreen> createState() =>
      _PengajuanMenungguScreenState();
}

class _PengajuanMenungguScreenState extends State<PengajuanMenungguScreen> {
  static const Color _primaryRed = Color(0xFF6B1B1B);
  static const Color _bgSoft = Color(0xFFF6EEEE);
  static const Color _borderSoft = Color(0xFFE0E0E0);
  static const Color _darkRed = Color(0xFF4A0E0E);

  final TextEditingController _alasanController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();

  String? _selectedGuruId;
  DateTime? _selectedMulai;
  DateTime? _selectedSelesai;
  
  List<dynamic> _pendingApplications = [];
  List<dynamic> _guruList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() {
      _pendingApplications = widget.pendingApplications;
    });
    
    await _loadTeachers();
    setState(() => _isLoading = false);
  }

  Future<void> _loadTeachers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/pkl/pembimbing'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Process teacher data
        List<dynamic> teachers = [];
        if (data is List) {
          teachers = data;
        } else if (data is Map && data.containsKey('data')) {
          if (data['data'] is List) {
            teachers = data['data'];
          } else if (data['data'] is Map && data['data']['data'] is List) {
            teachers = data['data']['data'];
          }
        }

        // Create dropdown items
        setState(() {
          _guruList = teachers.map((teacher) {
            final nama = teacher['nama']?.toString() ?? 'Guru';
            final mapel = teacher['mata_pelajaran']?.toString() ?? '';
            final nip = teacher['nip']?.toString() ?? '';
            final id = teacher['id']?.toString() ?? teacher['user_id']?.toString() ?? teacher['guru_id']?.toString() ?? '';
            
            return {
              'id': id,
              'display': mapel.isNotEmpty ? '$nama ($mapel)' : nama,
              'nama': nama,
              'nip': nip,
              'mapel': mapel,
            };
          }).toList();
        });
      }
    } catch (e) {
      print('Error loading teachers: $e');
    }
  }

  Future<void> _rejectApplication(int applicationId, String reason) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) return;

    try {
      final response = await http.put(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/pkl/applications/$applicationId/reject'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'alasan_penolakan': reason}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengajuan berhasil ditolak'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Remove from list
        setState(() {
          _pendingApplications.removeWhere((app) {
            final appData = app is Map ? app : {};
            final nestedApp = appData['application'] ?? {};
            return nestedApp['id'] == applicationId || 
                   appData['id'] == applicationId;
          });
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menolak pengajuan'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error rejecting application: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terjadi kesalahan saat menolak pengajuan'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _approveApplication(
    int applicationId, 
    String guruId,
    String catatan, 
    DateTime mulai, 
    DateTime selesai
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) return;

    try {
      final response = await http.put(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/pkl/applications/$applicationId/approve'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'pembimbing_guru_id': int.parse(guruId),
          'catatan': catatan.isEmpty ? '-' : catatan,
          'tanggal_mulai': mulai.toIso8601String().split('T')[0],
          'tanggal_selesai': selesai.toIso8601String().split('T')[0],
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengajuan berhasil disetujui'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Remove from list
        setState(() {
          _pendingApplications.removeWhere((app) {
            final appData = app is Map ? app : {};
            final nestedApp = appData['application'] ?? {};
            return nestedApp['id'] == applicationId || 
                   appData['id'] == applicationId;
          });
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyetujui pengajuan'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error approving application: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terjadi kesalahan saat menyetujui pengajuan'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showTolakDialog(dynamic applicationData) {
    final appData = applicationData is Map ? applicationData : {};
    final siswaName = appData['siswa_username'] ?? 'Siswa';
    final industriName = appData['industri_nama'] ?? 'Industri';
    
    // Akses nested application object
    final nestedApp = appData['application'] ?? {};
    final applicationId = nestedApp['id'] ?? appData['id'];

    if (applicationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID aplikasi tidak valid'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                // Header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _primaryRed.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: _primaryRed,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TOLAK PENGAJUAN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF6B1B1B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Siswa: $siswaName • Industri: $industriName',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Title
                const Text(
                  'Alasan Penolakan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B1B1B),
                  ),
                ),

                const SizedBox(height: 10),

                // Text Field
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _bgSoft,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _borderSoft),
                  ),
                  child: TextField(
                    controller: _alasanController,
                    maxLines: 4,
                    decoration: const InputDecoration.collapsed(
                      hintText: 'Masukkan alasan penolakan...',
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _alasanController.clear();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryRed,
                          side: const BorderSide(color: _primaryRed),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'BATAL',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_alasanController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Masukkan alasan penolakan'),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }
                          
                          _rejectApplication(applicationId, _alasanController.text.trim());
                          
                          Navigator.of(context).pop();
                          _alasanController.clear();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _darkRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'TOLAK',
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

  void _showSetujuiDialog(dynamic applicationData) {
    final appData = applicationData is Map ? applicationData : {};
    final siswaName = appData['siswa_username'] ?? 'Siswa';
    final industriName = appData['industri_nama'] ?? 'Industri';
    
    // Akses nested application object
    final nestedApp = appData['application'] ?? {};
    final applicationId = nestedApp['id'] ?? appData['id'];

    if (applicationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID aplikasi tidak valid'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: SingleChildScrollView(
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
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha:0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.green,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'SETUJUI PENGAJUAN',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF6B1B1B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Siswa: $siswaName • Industri: $industriName',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Guru Pembimbing
                      const Text(
                        'Guru Pembimbing',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B1B1B),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Dropdown Guru
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: _bgSoft,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _borderSoft),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedGuruId,
                            hint: const Text(
                              'Pilih guru pembimbing',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down),
                            items: _guruList.map((teacher) {
                              return DropdownMenuItem<String>(
                                value: teacher['id'],
                                child: Text(teacher['display']),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                _guruList.firstWhere(
                                  (t) => t['id'] == newValue,
                                  orElse: () => {},
                                );
                                setState(() {
                                  _selectedGuruId = newValue;
                                });
                              }
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Catatan
                      const Text(
                        'Catatan',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B1B1B),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Field Catatan
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _bgSoft,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _borderSoft),
                        ),
                        child: TextField(
                          controller: _catatanController,
                          maxLines: 3,
                          decoration: const InputDecoration.collapsed(
                            hintText: 'Masukkan catatan (opsional)',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Tanggal Mulai
                      const Text(
                        'Tanggal Mulai',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B1B1B),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Tombol Pilih Tanggal Mulai
                      GestureDetector(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2027, 12, 31),
                          );
                          if (picked != null) {
                            setState(() {
                              _selectedMulai = picked;
                            });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _bgSoft,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: _borderSoft),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedMulai != null
                                    ? '${_selectedMulai!.day}/${_selectedMulai!.month}/${_selectedMulai!.year}'
                                    : 'Pilih tanggal mulai',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _selectedMulai != null
                                      ? Colors.black
                                      : Colors.grey,
                                ),
                              ),
                              const Icon(Icons.calendar_month, color: Color(0xFF6B1B1B)),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Tanggal Selesai
                      const Text(
                        'Tanggal Selesai',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B1B1B),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Tombol Pilih Tanggal Selesai
                      GestureDetector(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedMulai ?? DateTime.now(),
                            firstDate: _selectedMulai ?? DateTime.now(),
                            lastDate: DateTime(2027, 12, 31),
                          );
                          if (picked != null) {
                            setState(() {
                              _selectedSelesai = picked;
                            });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _bgSoft,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: _borderSoft),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedSelesai != null
                                    ? '${_selectedSelesai!.day}/${_selectedSelesai!.month}/${_selectedSelesai!.year}'
                                    : 'Pilih tanggal selesai',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _selectedSelesai != null
                                      ? Colors.black
                                      : Colors.grey,
                                ),
                              ),
                              const Icon(Icons.calendar_month, color: Color(0xFF6B1B1B)),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _catatanController.clear();
                                setState(() {
                                  _selectedGuruId = null;
                                  _selectedMulai = null;
                                  _selectedSelesai = null;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _primaryRed,
                                side: const BorderSide(color: _primaryRed),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text(
                                'BATAL',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                // Validasi form
                                if (_selectedGuruId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Pilih guru pembimbing terlebih dahulu'),
                                      backgroundColor: Colors.red,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }
                                if (_selectedMulai == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Pilih tanggal mulai terlebih dahulu'),
                                      backgroundColor: Colors.red,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }
                                if (_selectedSelesai == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Pilih tanggal selesai terlebih dahulu'),
                                      backgroundColor: Colors.red,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }

                                if (_selectedSelesai!.isBefore(_selectedMulai!)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Tanggal selesai harus setelah tanggal mulai'),
                                      backgroundColor: Colors.red,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }

                                // Handle setujui pengajuan
                                _approveApplication(
                                  applicationId,
                                  _selectedGuruId!,
                                  _catatanController.text.trim(),
                                  _selectedMulai!,
                                  _selectedSelesai!,
                                );

                                Navigator.of(context).pop();
                                _catatanController.clear();
                                setState(() {
                                  _selectedGuruId = null;
                                  _selectedMulai = null;
                                  _selectedSelesai = null;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text(
                                'SETUJUI',
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
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgSoft,
      appBar: AppBar(
        backgroundColor: _primaryRed,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Pengajuan Menunggu',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6B1B1B),
              ),
            )
          : _pendingApplications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Tidak ada pengajuan menunggu',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: _pendingApplications.map((application) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _pengajuanCard(application),
                      );
                    }).toList(),
                  ),
                ),
    );
  }

  // ================= CARD PENGAJUAN =================
  Widget _pengajuanCard(dynamic applicationData) {
    final appData = applicationData is Map ? applicationData : {};
    final siswaName = appData['siswa_username'] ?? 'Siswa';
    final industriName = appData['industri_nama'] ?? 'Industri';
    final kelasName = appData['kelas_nama'] ?? '-';
    
    // Akses nested application object untuk tanggal
    final nestedApp = appData['application'] ?? {};
    
    // Format tanggal diajukan
    String tanggalDiajukan = '';
    final dateString = nestedApp['tanggal_permohonan'] ?? 
                      nestedApp['created_at'] ?? 
                      appData['tanggal_diajukan'] ?? 
                      appData['created_at'];
    
    if (dateString != null && dateString.isNotEmpty) {
      try {
        final date = DateTime.parse(dateString);
        tanggalDiajukan = '${date.day} ${_getMonthName(date.month)} ${date.year}';
      } catch (e) {
        tanggalDiajukan = 'Tanggal tidak valid';
      }
    }
    if (tanggalDiajukan.isEmpty) {
      tanggalDiajukan = '-';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            offset: Offset(0, 6),
            color: Colors.black12,
          ),
        ],
      ),
      child: Column(
        children: [
          _statusHeader(siswaName),
          const SizedBox(height: 14),
          _infoItem(Icons.apartment, 'Lokasi PKL', industriName),
          _infoItem(Icons.school, 'Kelas', kelasName),
          _infoItem(Icons.calendar_month, 'Diajukan', tanggalDiajukan),
          const SizedBox(height: 18),
          _actionButton(applicationData),
        ],
      ),
    );
  }

  Widget _statusHeader(String siswaName) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: _primaryRed.withValues(alpha:0.15),
          child: const Icon(Icons.access_time, color: _primaryRed),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MENUNGGU',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            Text(
              siswaName,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        const Spacer(),
        _badge('1'),
      ],
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderSoft),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _primaryRed,
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(dynamic applicationData) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showTolakDialog(applicationData),
            icon: const Icon(Icons.close),
            label: const Text('Tolak'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primaryRed,
              side: const BorderSide(color: _primaryRed),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showSetujuiDialog(applicationData),
            icon: const Icon(Icons.check),
            label: const Text('Setujui'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _primaryRed,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return months[month - 1];
  }

  @override
  void dispose() {
    _alasanController.dispose();
    _catatanController.dispose();
    super.dispose();
  }
}