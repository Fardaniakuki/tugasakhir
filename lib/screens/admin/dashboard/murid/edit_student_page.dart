import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EditStudentPage extends StatefulWidget {
  final Map<String, dynamic> studentData;

  const EditStudentPage({super.key, required this.studentData});

  @override
  State<EditStudentPage> createState() => _EditStudentPageState();
}

class _EditStudentPageState extends State<EditStudentPage> {
  final _formKey = GlobalKey<FormState>();
  final _kelasFieldKey = GlobalKey();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  late TextEditingController _namaController;
  late TextEditingController _nisnController;
  late TextEditingController _alamatController;
  late TextEditingController _noTelpController;
  late TextEditingController _tanggalLahirController;

  final Color _primaryColor = const Color(0xFF3B060A);
  final Color _accentColor = const Color(0xFF5B1A1A);
  bool _isSubmitting = false;

  List<Map<String, dynamic>> _kelasList = [];
  List<Map<String, dynamic>> _filteredKelasList = [];
  Map<String, dynamic>? _selectedKelas;
  bool _isLoadingKelas = true;
  bool _showKelasPopup = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _namaController =
        TextEditingController(text: widget.studentData['nama_lengkap']);
    _nisnController = TextEditingController(text: widget.studentData['nisn']);
    _alamatController =
        TextEditingController(text: widget.studentData['alamat']);
    _noTelpController =
        TextEditingController(text: widget.studentData['no_telp']);
    _tanggalLahirController = TextEditingController(
      text: _formatDateForDisplay(widget.studentData['tanggal_lahir']),
    );

    _searchController.addListener(_filterKelasList);
    _fetchKelas();
  }

  void _filterKelasList() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredKelasList = _kelasList.where((kelas) {
        return (kelas['nama'] ?? '').toLowerCase().contains(query);
      }).toList();
    });
    
    if (_overlayEntry != null && _overlayEntry!.mounted) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  Future<void> _fetchKelas() async {
    setState(() {
      _isLoadingKelas = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final baseUrl = dotenv.env['API_BASE_URL'] ?? '';

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/kelas?limit=1000'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        
        List<Map<String, dynamic>> allKelas = [];
        if (data['data'] is List) {
          allKelas = List<Map<String, dynamic>>.from(data['data']);
        } else if (data['data']['data'] is List) {
          allKelas = List<Map<String, dynamic>>.from(data['data']['data']);
        }

        setState(() {
          _kelasList = allKelas;
          _filteredKelasList = List.from(_kelasList);
          
          // Set selected kelas berdasarkan studentData
          if (widget.studentData['kelas_id'] != null) {
            _selectedKelas = _kelasList.firstWhere(
              (k) => k['id'] == widget.studentData['kelas_id'],
              orElse: () => _kelasList.isNotEmpty ? _kelasList[0] : {},
            );
          }
          
          _isLoadingKelas = false;
        });
      } else {
        setState(() {
          _isLoadingKelas = false;
        });
        print('Gagal fetch kelas: ${res.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoadingKelas = false;
      });
      print('Error fetch kelas: $e');
    }
  }

  String _formatDateForDisplay(String? rawDate) {
    if (rawDate == null) return '';
    try {
      final date = DateTime.parse(rawDate);
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    } catch (_) {
      return rawDate;
    }
  }

  String _convertDisplayDateToISO(String inputDate) {
    try {
      final parts = inputDate.split('-');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      }
      return inputDate;
    } catch (_) {
      return inputDate;
    }
  }

  Future<void> _pickTanggalLahir() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate:
          DateTime.tryParse(widget.studentData['tanggal_lahir'] ?? '') ??
              DateTime(2005),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: _primaryColor,
              ),
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _tanggalLahirController.text =
            '${pickedDate.day.toString().padLeft(2, '0')}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.year}';
      });
    }
  }

  void _showKelasPopupOverlay(BuildContext context) {
    if (_overlayEntry != null) {
      _removeOverlay();
      return;
    }

    final RenderBox renderBox = _kelasFieldKey.currentContext!.findRenderObject() as RenderBox;
    final fieldOffset = renderBox.localToGlobal(Offset.zero);
    final fieldSize = renderBox.size;
    final screenSize = MediaQuery.of(context).size;

    double top = fieldOffset.dy + fieldSize.height;
    double left = fieldOffset.dx;
    final double width = fieldSize.width;
    final double maxHeight = screenSize.height * 0.4;

    // Pastikan popup tidak keluar dari layar
    if (top + maxHeight > screenSize.height) {
      top = fieldOffset.dy - maxHeight;
    }
    if (left + width > screenSize.width) {
      left = screenSize.width - width;
    }
    if (left < 0) left = 0;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: left,
        top: top,
        width: width,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search, color: Colors.grey, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  focusNode: _searchFocusNode,
                                  decoration: const InputDecoration(
                                    hintText: 'Cari kelas...',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                  ),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              if (_searchController.text.isNotEmpty)
                                GestureDetector(
                                  onTap: () => _searchController.clear(),
                                  child: const Icon(Icons.clear, size: 16, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          _removeOverlay();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.close, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // List Kelas
                Expanded(
                  child: _buildKelasList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _showKelasPopup = true;
    });
  }

  Widget _buildKelasList() {
    if (_isLoadingKelas) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_filteredKelasList.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.class_outlined, size: 40, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'Tidak ada kelas tersedia',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Tambahkan opsi "Pilih kelas" di atas
    final List<Map<String, dynamic>> options = [
      {'id': null, 'nama': 'Pilih kelas'},
      ..._filteredKelasList,
    ];

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: options.length,
      itemBuilder: (context, index) {
        final kelas = options[index];
        final isSelected = _selectedKelas?['id'] == kelas['id'] || 
                          (_selectedKelas == null && kelas['id'] == null);
        
        return InkWell(
          onTap: () {
            setState(() {
              _selectedKelas = kelas['id'] != null ? kelas : null;
            });
            _removeOverlay();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              border: index == 0
                  ? null
                  : Border(
                      top: BorderSide(color: Colors.grey[100]!),
                    ),
              color: isSelected ? _primaryColor.withValues(alpha: 0.1) : Colors.transparent,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? _primaryColor : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.class_,
                    color: isSelected ? Colors.white : Colors.grey[600],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    kelas['nama'] ?? '-',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: isSelected ? _primaryColor : Colors.black87,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check,
                    color: _primaryColor,
                    size: 20,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    setState(() {
      _showKelasPopup = false;
    });
    _searchController.clear();
    _searchFocusNode.unfocus();
  }

  Future<void> _updateStudent() async {
    // Dismiss keyboard before validating
    FocusScope.of(context).unfocus();
    
    if (!_formKey.currentState!.validate()) return;

    if (_selectedKelas == null) {
      _showErrorDialog('Silakan pilih kelas terlebih dahulu');
      return;
    }

    setState(() => _isSubmitting = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      setState(() => _isSubmitting = false);
      _showErrorDialog('Token tidak ditemukan. Silakan login ulang.');
      return;
    }

    final Map<String, dynamic> updateData = {
      'nama_lengkap': _namaController.text.trim(),
      'nisn': _nisnController.text.trim(),
      'alamat': _alamatController.text.trim(),
      'no_telp': _noTelpController.text.trim(),
      'kelas_id': _selectedKelas!['id'] ?? 0,
      'tanggal_lahir':
          _convertDisplayDateToISO(_tanggalLahirController.text.trim()),
    };

    try {
      final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
      final response = await http.put(
        Uri.parse('$baseUrl/api/siswa/${widget.studentData['id']}'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(updateData),
      );

      if (!mounted) {
        setState(() => _isSubmitting = false);
        return;
      }

      setState(() => _isSubmitting = false);

      if (response.statusCode == 200) {
        _showSuccessDialog();
      } else {
        final error = json.decode(response.body);
        String errorMessage = 'Gagal memperbarui data siswa.';
        if (error['message'] != null) {
          errorMessage = error['message'];
        } else if (error['errors'] != null) {
          errorMessage = error['errors'].values.first[0];
        }
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showErrorDialog('Terjadi kesalahan jaringan');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha:0.5),
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
            maxWidth: 400,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header dengan gradient
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF2E7D32),
                      Color(0xFF4CAF50),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha:0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.check_circle_rounded,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Berhasil!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context, true);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              
              // Konten utama
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 60,
                      color: Color(0xFF4CAF50),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Data berhasil diperbarui',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Data siswa "${_namaController.text}" berhasil diperbarui',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              // Tombol OK
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('OK'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha:0.5),
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
            maxWidth: 400,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header dengan gradient merah
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFC62828),
                      Color(0xFFEF5350),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha:0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.error_outline_rounded,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Terjadi Kesalahan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              
              // Konten utama
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 60,
                      color: Color(0xFFEF5350),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Silakan coba lagi',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              // Tombol Tutup
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF5350),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Tutup'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== FORM FIELDS ==========

  Widget _buildFormField(
      IconData icon, String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text,
      bool readOnly = false,
      VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _primaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey[300],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: controller,
                    keyboardType: keyboardType,
                    readOnly: readOnly,
                    onTap: onTap,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Wajib diisi' : null,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                      errorStyle: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKelasField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      key: _kelasFieldKey,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showKelasPopupOverlay(context),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.class_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey[300],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kelas',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedKelas == null ? 'Pilih Kelas' : _selectedKelas!['nama'] ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _selectedKelas != null ? Colors.black87 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              _showKelasPopup ? Icons.expand_less : Icons.expand_more,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside
        FocusScope.of(context).unfocus();
        // Tutup overlay kelas jika terbuka
        if (_overlayEntry != null) {
          _removeOverlay();
        }
      },
      child: Scaffold(
        backgroundColor: _primaryColor,
        body: SafeArea(
          child: Column(
            children: [
              // APPBAR CUSTOM
              Container(
                height: 60,
                color: _primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Edit Siswa',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              
              // SATU CONTAINER PUTIH UTUH DENGAN BORDER RADIUS
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                    border: Border.all(
                      color: const Color(0xFFBEBEBE),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: _isLoadingKelas
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF3B060A),
                          ),
                        )
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // ICON PROFILE DI TENGAH
                                Container(
                                  margin: const EdgeInsets.only(bottom: 30),
                                  child: Container(
                                    width: 110,
                                    height: 110,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha:0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            _primaryColor,
                                            _accentColor,
                                          ],
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.person_rounded,
                                        size: 60,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // JUDUL FORM DI TENGAH
                                const Text(
                                  'Edit Data Siswa',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 30),
                                
                                // FORM FIELDS
                                _buildFormField(
                                  Icons.person_rounded,
                                  'Nama Lengkap',
                                  _namaController,
                                ),
                                _buildFormField(
                                  Icons.numbers_rounded,
                                  'NISN',
                                  _nisnController,
                                  keyboardType: TextInputType.number,
                                ),
                                _buildKelasField(),
                                _buildFormField(
                                  Icons.home_rounded,
                                  'Alamat',
                                  _alamatController,
                                ),
                                _buildFormField(
                                  Icons.phone_rounded,
                                  'Nomor Telepon',
                                  _noTelpController,
                                  keyboardType: TextInputType.phone,
                                ),
                                _buildFormField(
                                  Icons.calendar_today_rounded,
                                  'Tanggal Lahir',
                                  _tanggalLahirController,
                                  readOnly: true,
                                  onTap: _pickTanggalLahir,
                                ),
                                
                                const SizedBox(height: 40),
                                
                                // TOMBOL SIMPAN
                                Container(
                                  margin: const EdgeInsets.only(bottom: 30),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: _primaryColor.withValues(alpha:0.2),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            onPressed: _isSubmitting ? null : _updateStudent,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: _primaryColor,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              elevation: 0,
                                            ),
                                            child: _isSubmitting
                                                ? const Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2.5,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      SizedBox(width: 12),
                                                      Text(
                                                        'Menyimpan...',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                : const Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(Icons.save_rounded, size: 20),
                                                      SizedBox(width: 10),
                                                      Text(
                                                        'Simpan Perubahan',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
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
    _removeOverlay();
    _namaController.dispose();
    _nisnController.dispose();
    _alamatController.dispose();
    _noTelpController.dispose();
    _tanggalLahirController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
}