import 'package:flutter/material.dart';
import 'dart:async';
import 'dashboard/siswa_dashboard.dart';
import 'dashboard/siswa_kalender.dart';
import 'dashboard/siswa_permohonan.dart';
import 'dashboard/siswa_pindah_pkl.dart'; // Dipindah ke index 3
import 'dashboard/siswa_pengaturan.dart'; // Dipindah ke index 4
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
  final TextEditingController _alasanPindahController = TextEditingController();
  final TextEditingController _searchIndustriController =
      TextEditingController();
  String? _jenisIzin = 'izin';
  final List<File> _selectedFiles = [];
  final List<File> _selectedPindahFiles = [];
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  bool _isSubmittingPindah = false;
  List<Map<String, dynamic>> _existingIzin = [];

  // Variabel untuk dropdown industri
  List<Map<String, dynamic>> _industriList = [];
  int? _selectedIndustriId;
  bool _isLoadingIndustri = false;

  @override
  void initState() {
    super.initState();
    dotenv.load();
    _pageBuilders = [
      _buildDashboardPage(), // index 0: Beranda
      _buildKalenderPage(), // index 1: Kalender
      _buildRekapPage(), // index 2: Permohonan
      _buildPindahPklPage(), // index 3: Pindah PKL
      _buildPengaturanPage(), // index 4: Pengaturan
    ];
    _loadExistingIzin();
    _loadIndustriList(); // Load daftar industri saat init
  }

  @override
  void dispose() {
    _tanggalController.dispose();
    _alasanController.dispose();
    _alasanPindahController.dispose();
    _searchIndustriController.dispose();
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

  // TAB KE-3: Pindah PKL
  Widget _buildPindahPklPage() {
    return _buildCachedPage(
      index: 3,
      builder: () => PindahPKLPage(
        key: const ValueKey('pindah_pkl_page'),
        primaryColor: _primaryColor,
        onAjukanPindahPressed: _showAjukanPindahPKLForm,
      ),
    );
  }

  // TAB KE-4: Pengaturan
  Widget _buildPengaturanPage() {
    return _buildCachedPage(
      index: 4,
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
          primaryColor: _primaryColor, token: '', kelasId: null),
    );
  }

  Future<void> _loadIndustriList({String search = ''}) async {
    if (_isLoadingIndustri) return;

    setState(() => _isLoadingIndustri = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) throw Exception('Token tidak ditemukan');

      await dotenv.load();
      final baseUrl =
          dotenv.env['API_BASE_URL'] ?? 'https://api.gedanggoreng.com';
      final url = Uri.parse('$baseUrl/api/pkl/industri/available')
          .replace(queryParameters: {
        'search': search.isNotEmpty ? search : null,
        'limit': '100',
      });

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> items = data['data'] ?? [];

        setState(() {
          _industriList = items.map((item) {
            return {
              'id': item['id'] ?? 0,
              'name': item['name'] ?? 'Tidak ada nama',
              'address': item['address'] ?? 'Alamat tidak tersedia',
              'sector': item['sector'] ?? 'Sektor tidak tersedia',
              'quota': item['quota'] ?? 0,
              'remaining_slots': item['remaining_slots'] ?? 0,
            };
          }).toList();

          // Reset selected if not in list
          if (_selectedIndustriId != null &&
              !_industriList.any((ind) => ind['id'] == _selectedIndustriId)) {
            _selectedIndustriId = null;
          }
        });
      } else {
        throw Exception('Gagal memuat daftar industri: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading industri: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Gagal memuat daftar industri'),
            backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoadingIndustri = false);
    }
  }

  Widget _buildIndustriDropdown(StateSetter setState) {
    if (_isLoadingIndustri) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: CircularProgressIndicator(color: _primaryColor),
        ),
      );
    }

    if (_industriList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Tidak ada industri tersedia',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _industriList.length,
      itemBuilder: (context, index) {
        final industri = _industriList[index];
        final isSelected = _selectedIndustriId == industri['id'];
        final remainingSlots = industri['remaining_slots'] ?? 0;
        final isFull = remainingSlots <= 0;

        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFull
                  ? Colors.grey[300]
                  : _primaryColor.withValues(alpha: 0.1),
            ),
            child: Icon(
              isSelected ? Icons.check_circle : Icons.business,
              color: isSelected
                  ? _primaryColor
                  : (isFull ? Colors.grey : _primaryColor),
            ),
          ),
          title: Text(
            industri['name'],
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isFull ? Colors.grey : Colors.black,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${industri['sector']} • ${industri['address']}',
                style: TextStyle(
                  fontSize: 12,
                  color: isFull ? Colors.grey : Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Kuota: ${industri['remaining_slots']}/${industri['quota']}',
                style: TextStyle(
                  fontSize: 11,
                  color: isFull ? Colors.red : Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          trailing: isFull
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'PENUH',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : null,
          onTap: isFull
              ? null
              : () {
                  setState(() {
                    _selectedIndustriId = industri['id'];
                  });
                },
          tileColor: isSelected ? _primaryColor.withValues(alpha: 0.05) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected ? _primaryColor : Colors.transparent,
              width: isSelected ? 1 : 0,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedIndustriInfo(StateSetter setState) {
    final selectedIndustri = _industriList.firstWhere(
      (ind) => ind['id'] == _selectedIndustriId,
      orElse: () => {},
    );

    if (selectedIndustri.isEmpty) return const SizedBox();

    final remainingSlots = selectedIndustri['remaining_slots'] ?? 0;
    final isFull = remainingSlots <= 0;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isFull ? Colors.red[50] : _primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              isFull ? Colors.red[100]! : _primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.business,
            color: isFull ? Colors.red : _primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedIndustri['name'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isFull ? Colors.red[700] : _primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  selectedIndustri['address'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        selectedIndustri['sector'],
                        style: TextStyle(
                          fontSize: 11,
                          color: _primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isFull ? Colors.red[100]! : Colors.green[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Kuota: ${selectedIndustri['remaining_slots']}/${selectedIndustri['quota']}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isFull ? Colors.red[700] : Colors.green[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _selectedIndustriId = null;
              });
            },
            icon: Icon(Icons.close, color: Colors.grey[600], size: 20),
          ),
        ],
      ),
    );
  }

  Future<void> _showAjukanPindahPKLForm() async {
    _alasanPindahController.clear();
    _selectedPindahFiles.clear();
    _selectedIndustriId = null; // Reset selection
    _searchIndustriController.clear(); // Reset search

    // Load industri list
    await _loadIndustriList();

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
                      'Ajukan Pindah PKL',
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
                  'Isi formulir di bawah untuk mengajukan pindah PKL',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),

                // INDUSTRI TUJUAN
                Text('Industri Tujuan', style: _labelStyle),
                const SizedBox(height: 8),

                // Search Field
                TextFormField(
                  controller: _searchIndustriController,
                  decoration: InputDecoration(
                    hintText: 'Cari industri...',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchIndustriController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchIndustriController.clear();
                              _loadIndustriList();
                            },
                            icon: const Icon(Icons.clear, color: Colors.grey),
                          )
                        : null,
                  ),
                  onChanged: (value) async {
                    // Debounce search
                    await Future.delayed(const Duration(milliseconds: 500));
                    if (value != _searchIndustriController.text) return;
                    await _loadIndustriList(search: value);
                  },
                ),
                const SizedBox(height: 12),

                // Dropdown List Industri
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: _buildIndustriDropdown(setState),
                ),

                // Info industri yang dipilih
                if (_selectedIndustriId != null)
                  _buildSelectedIndustriInfo(setState),

                const SizedBox(height: 20),

                // Alasan
                Text('Alasan Pindah', style: _labelStyle),
                const SizedBox(height: 8),
                Text(
                  'Jelaskan alasan pindah PKL (minimal 10 karakter)',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _alasanPindahController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText:
                        'Alasan Pindah PKL',
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
                _buildPindahFileUploadSection(setState),
                const SizedBox(height: 32),

                // Tombol Submit
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmittingPindah
                        ? null
                        : () => _submitPindahPKLForm(context, setState),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmittingPindah
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'AJUKAN PINDAH PKL',
                            style: TextStyle(
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

  Widget _buildPindahFileUploadSection(StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bukti Pendukung', style: _labelStyle),
        const SizedBox(height: 8),
        Text(
          'Upload 1-5 file bukti (JPEG/PNG/PDF, maks 5MB per file)',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        const SizedBox(height: 12),
        if (_selectedPindahFiles.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _selectedPindahFiles.length,
            itemBuilder: (context, index) =>
                _buildPindahFilePreview(index, setState),
          ),
        if (_selectedPindahFiles.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            '${_selectedPindahFiles.length} file terpilih',
            style: TextStyle(
              color: _primaryColor,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
        ],
        ElevatedButton.icon(
          onPressed: _selectedPindahFiles.length >= 5
              ? null
              : () => _pickPindahFiles(setState),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: _primaryColor,
            side: BorderSide(color: _primaryColor),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            minimumSize: const Size(double.infinity, 48),
          ),
          icon: Icon(
              _selectedPindahFiles.isEmpty ? Icons.attach_file : Icons.add,
              size: 20),
          label: Text(_selectedPindahFiles.isEmpty
              ? 'Pilih File'
              : 'Tambah File (${_selectedPindahFiles.length}/5)'),
        ),
      ],
    );
  }

  Widget _buildPindahFilePreview(int index, StateSetter setState) {
    final file = _selectedPindahFiles[index];
    final isImage = file.path.toLowerCase().endsWith('.jpg') ||
        file.path.toLowerCase().endsWith('.jpeg') ||
        file.path.toLowerCase().endsWith('.png');

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: isImage
                ? Image.file(
                    file,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  )
                : Container(
                    color: Colors.blue[50],
                    child: const Center(
                      child: Icon(Icons.picture_as_pdf,
                          color: Colors.blue, size: 40),
                    ),
                  ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => setState(() => _selectedPindahFiles.removeAt(index)),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
        Positioned(
          bottom: 4,
          left: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              file.path.split('/').last,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickPindahFiles(StateSetter setState) async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty) {
        final newFiles = pickedFiles.map((xFile) => File(xFile.path)).toList();
        final totalFiles = _selectedPindahFiles.length + newFiles.length;

        if (totalFiles > 5) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Maksimal 5 file'), backgroundColor: Colors.red),
          );
          return;
        }

        setState(() => _selectedPindahFiles.addAll(newFiles));
      }
    } catch (e) {
      print('Error picking files: $e');
    }
  }

  Future<void> _submitPindahPKLForm(
      BuildContext context, StateSetter setState) async {
    if (_isSubmittingPindah) return;

    // Validasi
    if (_selectedIndustriId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Harap pilih industri tujuan'),
            backgroundColor: Colors.red),
      );
      return;
    }

    // Cek apakah industri sudah penuh
    final selectedIndustri = _industriList.firstWhere(
      (ind) => ind['id'] == _selectedIndustriId,
      orElse: () => {},
    );

    final remainingSlots = selectedIndustri['remaining_slots'] ?? 0;
    if (remainingSlots <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Industri tujuan sudah penuh'),
            backgroundColor: Colors.red),
      );
      return;
    }

    if (_alasanPindahController.text.isEmpty ||
        _alasanPindahController.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Harap isi alasan minimal 10 karakter'),
            backgroundColor: Colors.red),
      );
      return;
    }

    if (_selectedPindahFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Harap upload minimal 1 bukti pendukung'),
            backgroundColor: Colors.red),
      );
      return;
    }

    if (_selectedPindahFiles.length > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Maksimal 5 file'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmittingPindah = true);

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
            Text('Mengajukan pindah PKL...'),
          ],
        ),
      ),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) throw Exception('Token tidak ditemukan');

      await dotenv.load();
      final baseUrl =
          dotenv.env['API_BASE_URL'] ?? 'https://api.gedanggoreng.com';
      final url = Uri.parse('$baseUrl/api/pindah-pkl');

      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['industri_baru_id'] = _selectedIndustriId!.toString();
      request.fields['alasan'] = _alasanPindahController.text;

      for (var file in _selectedPindahFiles) {
        try {
          final fileSize = await file.length();
          if (fileSize > 5 * 1024 * 1024) {
            // 5MB
            throw Exception('File ${file.path} melebihi 5MB');
          }

          final fileName = file.path.split('/').last;
          request.files.add(await http.MultipartFile.fromPath(
              'files', file.path,
              filename: fileName));
        } catch (e) {
          print('Error adding file: $e');
        }
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      Navigator.pop(context); // Tutup loading

      if (response.statusCode == 201) {
        if (context.mounted) {
          Navigator.pop(context); // Tutup form
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.green,
              content: Row(children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text('Pengajuan pindah PKL berhasil!'),
              ]),
            ),
          );
          refreshPage(3); // Refresh halaman pindah PKL
        }
      } else {
        final Map<String, dynamic> errorData = jsonDecode(responseBody);
        final errorMessage = errorData['error']?['message'] ??
            errorData['detail'] ??
            'Gagal mengajukan pindah PKL (${response.statusCode})';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSubmittingPindah = false);
    }
  }

  Future<void> _loadExistingIzin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) return;

      await dotenv.load();
      final baseUrl =
          dotenv.env['API_BASE_URL'] ?? 'https://api.gedanggoreng.com';
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
          _existingIzin =
              data.map((item) => item as Map<String, dynamic>).toList();
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
  _jenisIzin = 'Izin'; // Default ke Izin (dengan huruf kapital)
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
              // Header
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
                'Isi formulir di bawah untuk mengajukan izin/sakit/dispen',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // PILIHAN JENIS PENGAJUAN (3 OPSI)
              Text('Jenis Pengajuan', style: _labelStyle),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildIzinTypeOption(context, setState, 'Izin', 'Izin', Icons.event_available)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildIzinTypeOption(context, setState, 'Sakit', 'Sakit', Icons.medical_services)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildIzinTypeOption(context, setState, 'Dispen', 'Dispen', Icons.school)),
                ],
              ),
              const SizedBox(height: 24),

              // Tanggal Izin
              Text('Tanggal Izin', style: _labelStyle),
              const SizedBox(height: 8),
              
              // Peringatan jika tanggal sudah ada izin
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
              
              // Field Pilih Tanggal
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
              const SizedBox(height: 24),

              // Alasan
              Text('Alasan', style: _labelStyle),
              const SizedBox(height: 8),
              TextFormField(
                controller: _alasanController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Jelaskan alasan izin/sakit/dispen...',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),

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

// Perbaiki method _buildIzinTypeOption
Widget _buildIzinTypeOption(BuildContext context, StateSetter setState, 
    String value, String label, IconData icon) {
  final bool isSelected = _jenisIzin == value;
  return GestureDetector(
    onTap: () => setState(() => _jenisIzin = value),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
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
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),
  );
}

// Perbaiki method _submitIzinForm
Future<void> _submitIzinForm(BuildContext context, StateSetter setState) async {
  if (_isSubmitting) return;
  
  // Validasi
  if (_tanggalController.text.isEmpty) {
    _showErrorDialog(context, 'Harap pilih tanggal izin');
    return;
  }

  if (_isDateAlreadyHasIzin(_tanggalController.text)) {
    _showErrorDialog(context, 'Anda sudah memiliki izin di tanggal ini');
    return;
  }

  // Validasi jenis izin (harus sesuai API)
  if (_jenisIzin == null || _jenisIzin!.isEmpty) {
    _showErrorDialog(context, 'Harap pilih jenis izin');
    return;
  }

  final validJenis = ['Izin', 'Sakit', 'Dispen'];
  if (!validJenis.contains(_jenisIzin)) {
    _showErrorDialog(context, 'Jenis izin tidak valid. Pilih dari: Izin, Sakit, atau Dispen');
    return;
  }

  if (_alasanController.text.isEmpty || _alasanController.text.length < 10) {
    _showErrorDialog(context, 'Harap isi alasan minimal 10 karakter');
    return;
  }

  if (_selectedFiles.isEmpty) {
    _showErrorDialog(context, 'Harap upload minimal 1 bukti foto');
    return;
  }

  setState(() => _isSubmitting = true);

  // Loading dialog
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
    request.fields['jenis'] = _jenisIzin!; // Nilai sudah "Izin", "Sakit", atau "Dispen"
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
    
    // Tutup loading dialog
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    if (response.statusCode == 201) {
      await _loadExistingIzin();
      
      if (context.mounted) {
        // Tutup bottom sheet form
        Navigator.pop(context);
        
        // Tampilkan snackbar sukses
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Izin ${_jenisIzin!.toLowerCase()} berhasil diajukan!',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
        
        refreshPage(2);
      }
    } else {
      // Parse error response
      String errorMessage = 'Gagal mengajukan izin';
      try {
        final Map<String, dynamic> errorData = jsonDecode(responseBody);
        
        if (errorData.containsKey('error')) {
          if (errorData['error'] is Map) {
            errorMessage = errorData['error']['message'] ?? errorMessage;
          } else if (errorData['error'] is String) {
            errorMessage = errorData['error'];
          }
        } else if (errorData.containsKey('message')) {
          errorMessage = errorData['message'];
        } else if (errorData.containsKey('detail')) {
          errorMessage = errorData['detail'];
        } else if (errorData.containsKey('errors')) {
          final errors = errorData['errors'];
          if (errors is Map) {
            final firstError = errors.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              errorMessage = firstError.first;
            }
          }
        }
      } catch (e) {
        errorMessage = responseBody.isNotEmpty 
            ? responseBody 
            : 'Gagal mengajukan izin (${response.statusCode})';
      }
      
      if (context.mounted) {
        _showErrorDialog(context, errorMessage);
      }
    }
  } catch (e) {
    // Tutup loading dialog
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    
    if (context.mounted) {
      _showErrorDialog(context, 'Error: ${e.toString()}');
    }
  } finally {
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }
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
      final selectedDate =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';

      if (_isDateAlreadyHasIzin(selectedDate)) {
        final bool? confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sudah Ada Izin'),
            content: Text(
                'Anda sudah memiliki izin pada tanggal $selectedDate.\n\nApakah Anda ingin tetap mengajukan izin baru?'),
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
          Text(
            '${_selectedFiles.length} file terpilih',
            style: TextStyle(
              color: _primaryColor,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
        ],
        ElevatedButton.icon(
          onPressed:
              _selectedFiles.length >= 3 ? null : () => _pickFiles(setState),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: _primaryColor,
            side: BorderSide(color: _primaryColor),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            minimumSize: const Size(double.infinity, 48),
          ),
          icon: Icon(_selectedFiles.isEmpty ? Icons.attach_file : Icons.add,
              size: 20),
          label: Text(_selectedFiles.isEmpty
              ? 'Pilih File'
              : 'Tambah File (${_selectedFiles.length}/3)'),
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
                color: Colors.red.withValues(alpha: 0.9),
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
            const SnackBar(
                content: Text('Maksimal 3 file'), backgroundColor: Colors.red),
          );
          return;
        }

        setState(() => _selectedFiles.addAll(newFiles));
      }
    } catch (e) {
      print('Error picking files: $e');
    }
  }


  /// Method untuk menampilkan dialog error yang lebih informatif
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700, size: 28),
            const SizedBox(width: 10),
            const Text(
              'Gagal',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Terjadi kesalahan saat mengajukan izin:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  message,
                  style: TextStyle(
                    color: Colors.red.shade900,
                    fontSize: 14,
                  ),
                ),
              ),
              if (message.contains('duplicate') ||
                  message.contains('already exists') ||
                  message.contains('sudah')) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Anda mungkin sudah memiliki izin di tanggal yang sama',
                          style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: _primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'TUTUP',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
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
                child: Text(
                  'AKSI CEPAT',
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
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      trailing: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(shape: BoxShape.circle, color: _primaryColor),
        child: const Icon(Icons.arrow_forward_ios_rounded,
            size: 14, color: Colors.white),
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
          // FAB untuk Beranda (Ajukan PKL), Permohonan (Ajukan Izin), dan Pindah PKL (Ajukan Pindah PKL)
          if (_currentIndex == 0 || _currentIndex == 2 || _currentIndex == 3)
            Positioned(
              right: 20,
              bottom: 80,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tombol utama berdasarkan tab
                  FloatingActionButton(
                    onPressed: () async {
                      if (_currentIndex == 0) {
                        _showAjukanPKLDialog();
                      } else if (_currentIndex == 2) {
                        await _showAjukanIzinForm();
                      } else if (_currentIndex == 3) {
                        await _showAjukanPindahPKLForm();
                      }
                    },
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    heroTag: 'main_fab_$_currentIndex',
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
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // index 0: Beranda
          _buildTabItem(0, Icons.home_outlined, Icons.home, 'Beranda'),
          // index 1: Kalender
          _buildTabItem(1, Icons.calendar_today_outlined, Icons.calendar_today,
              'Kalender'),
          // index 2: Permohonan
          _buildTabItem(
              2, Icons.assignment_outlined, Icons.assignment, 'Perizinan'),
          // index 3: Pindah PKL
          _buildTabItem(
              3, Icons.swap_horiz_outlined, Icons.swap_horiz, 'Pindah PKL'),
          // index 4: Pengaturan
          _buildTabItem(
              4, Icons.settings_outlined, Icons.settings, 'Pengaturan'),
        ],
      ),
    );
  }

  Widget _buildTabItem(
      int index, IconData icon, IconData activeIcon, String label) {
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
                  color: isActive
                      ? widget.primaryColor.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? widget.primaryColor : widget.inactiveColor,
                  size: 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
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
