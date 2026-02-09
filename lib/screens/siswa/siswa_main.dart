import 'package:flutter/material.dart';
import 'dart:async';
import 'dashboard/siswa_dashboard.dart';
import 'dashboard/siswa_kalender.dart';
import 'dashboard/siswa_permohonan.dart';
import 'dashboard/siswa_pengaturan.dart';
import 'dashboard/ajukan_pkl_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class SiswaMain extends StatefulWidget {
  const SiswaMain({super.key});
  @override
  State<SiswaMain> createState() => _SiswaMainState();
}

class _SiswaMainState extends State<SiswaMain> {
  int _currentIndex = 0;
  final Map<int, Widget> _pageCache = {};
  final Map<int, bool> _pageLoaded = {};
  late final List<Widget> _pageBuilders;
  final Color _primaryColor = const Color(0xFF9f0712);
  final Color _inactiveColor = const Color(0xFF9E9E9E);
  final TextEditingController _tanggalController = TextEditingController();
  final TextEditingController _alasanController = TextEditingController();
  String? _jenisIzin = 'izin';
  final List<File> _selectedFiles = [];
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _existingIzin = [];

  @override
  void initState() {
    super.initState();
    dotenv.load();
    _pageBuilders = [
      _buildDashboardPage(),
      _buildKalenderPage(),
      _buildRekapPage(),
      _buildPengaturanPage(),
    ];
    _loadExistingIzin();
  }

  @override
  void dispose() {
    _tanggalController.dispose();
    _alasanController.dispose();
    super.dispose();
  }

  Widget _buildDashboardPage() {
    return _buildCachedPage(
      index: 0,
      builder: () => SiswaDashboard(
        key: const ValueKey('dashboard_page'),
        onAjukanPklPressed: _showAjukanPKLDialog,
      ),
    );
  }

  Widget _buildKalenderPage() {
    return _buildCachedPage(
      index: 1,
      builder: () => const SiswaKalender(key: ValueKey('kalender_page')),
    );
  }

  Widget _buildRekapPage() {
    return _buildCachedPage(
      index: 2,
      builder: () => SiswaRekap(
        key: const ValueKey('rekap_page'),
        onQuickActionPressed: _showQuickActionsDialog,
        onAjukanIjin: () async => await _showAjukanIzinForm(),
      ),
    );
  }

  Widget _buildPengaturanPage() {
    return _buildCachedPage(
      index: 3,
      builder: () => const SiswaPengaturan(key: ValueKey('pengaturan_page')),
    );
  }

  Widget _buildCachedPage(
      {required int index, required Widget Function() builder}) {
    if (!_pageLoaded.containsKey(index) || !_pageLoaded[index]!) {
      return FutureBuilder<void>(
        future: Future.delayed(Duration.zero, () {
          _pageCache[index] = builder();
          _pageLoaded[index] = true;
        }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return _pageCache[index]!;
          }
          return Center(child: CircularProgressIndicator(color: _primaryColor));
        },
      );
    }
    return _pageCache[index]!;
  }

  void _onTabSelected(int index) => setState(() => _currentIndex = index);

  void _showAjukanPKLDialog() {
    showDialog(
      context: context,
      builder: (context) => AjukanPKLDialog(
        primaryColor: _primaryColor, 
        token: '', 
        kelasId: null
      ),
    );
  }

  void _showAjukanPindahPKLDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ajukan Pindah PKL', style: TextStyle(color: _primaryColor)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Alasan Pindah',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Tempat PKL Baru',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Alasan Detail',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('BATAL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pengajuan pindah PKL berhasil dikirim!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
            child: const Text('AJUKAN', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _loadExistingIzin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) return;

      await dotenv.load();
      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://api.gedanggoreng.com';
      final url = Uri.parse('$baseUrl/api/izin-siswa');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _existingIzin = data.map((item) => item as Map<String, dynamic>).toList();
        });
      }
    } catch (e) {
      print('Error loading izin: $e');
    }
  }

  bool _isDateAlreadyHasIzin(String tanggal) {
    if (_existingIzin.isEmpty) return false;
    return _existingIzin.any((izin) => izin['tanggal'] == tanggal);
  }

  Future<void> _showAjukanIzinForm() async {
    _tanggalController.clear();
    _alasanController.clear();
    _selectedFiles.clear();
    _jenisIzin = 'izin';
    await _loadExistingIzin();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ajukan Izin',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.grey),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Isi formulir di bawah untuk mengajukan izin/sakit',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),

                // Pilihan Jenis Pengajuan
                Text('Jenis Pengajuan', style: _labelStyle),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildIzinTypeOption(context, setState, 'izin', 'Izin', Icons.event_available)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildIzinTypeOption(context, setState, 'sakit', 'Sakit', Icons.medical_services)),
                  ],
                ),
                const SizedBox(height: 20),

                // Tanggal
                Text('Tanggal Izin', style: _labelStyle),
                const SizedBox(height: 8),
                
                if (_tanggalController.text.isNotEmpty && 
                    _isDateAlreadyHasIzin(_tanggalController.text))
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Anda sudah memiliki izin di tanggal ini',
                                style: TextStyle(
                                  color: Colors.orange[800],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                
                GestureDetector(
                  onTap: () => _pickDate(context, setState),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _tanggalController.text.isNotEmpty && 
                               _isDateAlreadyHasIzin(_tanggalController.text)
                            ? Colors.orange
                            : Colors.grey.shade300,
                        width: _tanggalController.text.isNotEmpty && 
                               _isDateAlreadyHasIzin(_tanggalController.text)
                            ? 2
                            : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today, 
                          color: _tanggalController.text.isNotEmpty && 
                                 _isDateAlreadyHasIzin(_tanggalController.text)
                              ? Colors.orange
                              : _primaryColor, 
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _tanggalController.text.isNotEmpty
                                ? _tanggalController.text
                                : 'Pilih tanggal',
                            style: TextStyle(
                              color: _tanggalController.text.isNotEmpty
                                  ? _tanggalController.text.isNotEmpty && 
                                     _isDateAlreadyHasIzin(_tanggalController.text)
                                      ? Colors.orange[800]
                                      : Colors.black
                                  : Colors.grey[500],
                              fontWeight: _tanggalController.text.isNotEmpty && 
                                         _isDateAlreadyHasIzin(_tanggalController.text)
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (_tanggalController.text.isNotEmpty && 
                            _isDateAlreadyHasIzin(_tanggalController.text))
                          const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Jenis Izin
                Text('Jenis Izin', style: _labelStyle),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _jenisIzin == 'izin' ? Icons.event_available : Icons.medical_services,
                        color: _primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _jenisIzin == 'izin' ? 'Izin' : 'Sakit',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Alasan
                Text('Alasan', style: _labelStyle),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _alasanController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Jelaskan alasan izin/sakit...',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 20),

                // Upload File
                _buildFileUploadSection(setState),
                const SizedBox(height: 32),

                // Tombol Submit
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (_isSubmitting || 
                               (_tanggalController.text.isNotEmpty && 
                                _isDateAlreadyHasIzin(_tanggalController.text)))
                        ? null
                        : () => _submitIzinForm(context, setState),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (_tanggalController.text.isNotEmpty && 
                                       _isDateAlreadyHasIzin(_tanggalController.text))
                          ? Colors.grey
                          : _primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            (_tanggalController.text.isNotEmpty && 
                             _isDateAlreadyHasIzin(_tanggalController.text))
                                ? 'SUDAH ADA IZIN'
                                : 'AJUKAN IZIN',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildIzinTypeOption(BuildContext context, StateSetter setState, 
      String value, String label, IconData icon) {
    final bool isSelected = _jenisIzin == value;
    return GestureDetector(
      onTap: () => setState(() => _jenisIzin = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor.withValues(alpha:0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? _primaryColor : Colors.grey, size: 24),
            const SizedBox(height: 8),
            Text(label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? _primaryColor : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, StateSetter setState) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(primary: _primaryColor),
        ),
        child: child!,
      ),
    );
    
    if (picked != null) {
      final selectedDate = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      
      if (_isDateAlreadyHasIzin(selectedDate)) {
        final bool? confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sudah Ada Izin'),
            content: Text('Anda sudah memiliki izin pada tanggal $selectedDate.\n\nApakah Anda ingin tetap mengajukan izin baru?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('BATAL'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('LANJUTKAN'),
              ),
            ],
          ),
        );
        if (confirm != true) return;
      }
      
      setState(() => _tanggalController.text = selectedDate);
    }
  }

  Widget _buildFileUploadSection(StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bukti Pendukung', style: _labelStyle),
        const SizedBox(height: 8),
        Text(
          'Upload 1-3 foto (JPEG/PNG, maks 5MB per file)',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        const SizedBox(height: 12),

        if (_selectedFiles.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _selectedFiles.length,
            itemBuilder: (context, index) => _buildFilePreview(index, setState),
          ),

        if (_selectedFiles.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('${_selectedFiles.length} file terpilih',
            style: TextStyle(
              color: _primaryColor,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
        ],

        ElevatedButton.icon(
          onPressed: _selectedFiles.length >= 3 ? null : () => _pickFiles(setState),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: _primaryColor,
            side: BorderSide(color: _primaryColor),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            minimumSize: const Size(double.infinity, 48),
          ),
          icon: Icon(_selectedFiles.isEmpty ? Icons.attach_file : Icons.add, size: 20),
          label: Text(_selectedFiles.isEmpty ? 'Pilih File' : 'Tambah File (${_selectedFiles.length}/3)'),
        ),
      ],
    );
  }

  Widget _buildFilePreview(int index, StateSetter setState) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              _selectedFiles[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => setState(() => _selectedFiles.removeAt(index)),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha:0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickFiles(StateSetter setState) async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty) {
        final newFiles = pickedFiles.map((xFile) => File(xFile.path)).toList();
        final totalFiles = _selectedFiles.length + newFiles.length;

        if (totalFiles > 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maksimal 3 file'), backgroundColor: Colors.red),
          );
          return;
        }

        setState(() => _selectedFiles.addAll(newFiles));
      }
    } catch (e) {
      print('Error picking files: $e');
    }
  }

  Future<void> _submitIzinForm(BuildContext context, StateSetter setState) async {
    if (_isSubmitting) return;
    
    // Validasi
    if (_tanggalController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap pilih tanggal izin'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_isDateAlreadyHasIzin(_tanggalController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda sudah memiliki izin di tanggal ini'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_alasanController.text.isEmpty || _alasanController.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi alasan minimal 10 karakter'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap upload minimal 1 bukti foto'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Mengajukan izin...'),
          ],
        ),
      ),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) throw Exception('Token tidak ditemukan');

      await dotenv.load();
      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://api.gedanggoreng.com';
      final url = Uri.parse('$baseUrl/api/izin');

      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['tanggal'] = _tanggalController.text;
      request.fields['jenis'] = _jenisIzin!;
      request.fields['keterangan'] = _alasanController.text;

      for (var file in _selectedFiles) {
        try {
          request.files.add(await http.MultipartFile.fromPath('files', file.path));
        } catch (e) {
          print('Error adding file: $e');
        }
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      Navigator.pop(context); // Tutup loading

      if (response.statusCode == 201) {
        await _loadExistingIzin();
        if (context.mounted) {
          Navigator.pop(context); // Tutup form
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.green,
              content: Row(children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text('Izin berhasil diajukan!'),
              ]),
            ),
          );
          refreshPage(2);
        }
      } else {
        final errorMessage = jsonDecode(responseBody)['error']?['message'] ?? 
            'Gagal mengajukan izin';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showQuickActionsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: const Center(
                child: Text('AKSI CEPAT',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            _buildActionTile(Icons.assignment, 'AJUKAN PKL', 'pengajuan'),
            Divider(height: 1, color: Colors.grey.shade300),
            _buildActionTile(Icons.calendar_today, 'LIHAT JADWAL', 'jadwal'),
            Divider(height: 1, color: Colors.grey.shade300),
            _buildActionTile(Icons.assessment, 'LIHAT NILAI', 'nilai'),
            Divider(height: 1, color: Colors.grey.shade300),
            _buildActionTile(Icons.chat, 'KONSULTASI', 'konsultasi'),
            Divider(height: 1, color: Colors.grey.shade300),
            _buildActionTile(Icons.report, 'LAPORAN HARIAN', 'laporan'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  ListTile _buildActionTile(IconData icon, String title, String jenis) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(shape: BoxShape.circle, color: _primaryColor),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      trailing: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(shape: BoxShape.circle, color: _primaryColor),
        child: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white),
      ),
      onTap: () {
        Navigator.pop(context);
        _navigateToAction(jenis);
      },
    );
  }

  void _navigateToAction(String jenisAksi) {
    switch (jenisAksi) {
      case 'pengajuan':
        if (_currentIndex == 0) _showAjukanPKLDialog();
        break;
      case 'jadwal':
        setState(() => _currentIndex = 1);
        break;
      case 'nilai':
      case 'laporan':
        setState(() => _currentIndex = 2);
        break;
      case 'konsultasi':
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(index: _currentIndex, children: _pageBuilders),
          ),
          // MODIFIKASI DI SINI - TAMBAH TOMBOL PINDAH PKL
          if (_currentIndex == 0 || _currentIndex == 2)
            Positioned(
              right: 20,
              bottom: 80,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tombol Pindah PKL (hanya di index 2/permohonan)
                  if (_currentIndex == 2)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: FloatingActionButton(
                        onPressed: _showAjukanPindahPKLDialog,
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        heroTag: 'pindah_pkl',
                        mini: true,
                        child: const Icon(Icons.swap_horiz, size: 22),
                      ),
                    ),
                  // Tombol Utama
                  FloatingActionButton(
                    onPressed: () async {
                      if (_currentIndex == 0) {
                        _showAjukanPKLDialog();
                      } else {
                        await _showAjukanIzinForm();
                      }
                    },
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    heroTag: 'main_fab',
                    child: const Icon(Icons.add, size: 28),
                  ),
                ],
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _SiswaBottomBar(
              currentIndex: _currentIndex,
              onTabSelected: _onTabSelected,
              primaryColor: _primaryColor,
              inactiveColor: _inactiveColor,
            ),
          ),
        ],
      ),
    );
  }

  void refreshPage(int pageIndex) {
    if (_pageLoaded.containsKey(pageIndex)) {
      _pageCache.remove(pageIndex);
      _pageLoaded[pageIndex] = false;
      if (_currentIndex == pageIndex) setState(() {});
    }
  }

  TextStyle get _labelStyle => const TextStyle(
        fontWeight: FontWeight.w600,
        color: Colors.black87,
        fontSize: 15,
      );
}

class _SiswaBottomBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTabSelected;
  final Color primaryColor;
  final Color inactiveColor;
  
  const _SiswaBottomBar({
    required this.currentIndex,
    required this.onTabSelected,
    required this.primaryColor,
    required this.inactiveColor,
  });
  
  @override
  State<_SiswaBottomBar> createState() => __SiswaBottomBarState();
}

class __SiswaBottomBarState extends State<_SiswaBottomBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTabItem(0, Icons.home_outlined, Icons.home, 'Beranda'),
          _buildTabItem(1, Icons.calendar_today_outlined, Icons.calendar_today, 'Kalender'),
          _buildTabItem(2, Icons.assignment_outlined, Icons.assignment, 'Permohonan'),
          _buildTabItem(3, Icons.settings_outlined, Icons.settings, 'Pengaturan'),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, IconData icon, IconData activeIcon, String label) {
    final bool isActive = widget.currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onTabSelected(index),
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isActive ? widget.primaryColor.withValues(alpha:0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? widget.primaryColor : widget.inactiveColor,
                  size: 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? widget.primaryColor : widget.inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}