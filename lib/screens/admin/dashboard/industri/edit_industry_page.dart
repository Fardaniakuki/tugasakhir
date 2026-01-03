import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EditIndustryPage extends StatefulWidget {
  final Map<String, dynamic> industryData;

  const EditIndustryPage({super.key, required this.industryData});

  @override
  State<EditIndustryPage> createState() => _EditIndustryPageState();
}

class _EditIndustryPageState extends State<EditIndustryPage> {
  final _formKey = GlobalKey<FormState>();
  
  late FocusNode _namaFocusNode;
  late FocusNode _alamatFocusNode;
  late FocusNode _telpFocusNode;
  late FocusNode _emailFocusNode;
  late FocusNode _bidangFocusNode;
  late FocusNode _jurusanFocusNode;
  late FocusNode _picFocusNode;
  late FocusNode _picTelpFocusNode;
  
  late TextEditingController _namaController;
  late TextEditingController _alamatController;
  late TextEditingController _telpController;
  late TextEditingController _emailController;
  late TextEditingController _bidangController;
  late TextEditingController _jurusanController;
  late TextEditingController _picController;
  late TextEditingController _picTelpController;
  
  bool _isActive = false;
  
  // Variabel untuk dropdown jurusan dengan overlay popup
  Map<String, dynamic>? _selectedJurusan;
  List<Map<String, dynamic>> _jurusanList = [];
  List<Map<String, dynamic>> _filteredJurusanList = [];
  
  final Color _primaryColor = const Color(0xFF3B060A);
  final Color _accentColor = const Color(0xFF5B1A1A);
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _showJurusanPopup = false;
  
  // Keys untuk mendapatkan posisi
  final GlobalKey _jurusanFieldKey = GlobalKey();
  OverlayEntry? _jurusanOverlayEntry;
  final TextEditingController _jurusanSearchController = TextEditingController();
  final FocusNode _jurusanSearchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final data = widget.industryData;
    
    print('=== INIT EDIT INDUSTRY PAGE ===');
    print('Industry Data: $data');
    print('Jurusan ID dari data: ${data['jurusan_id']}');
    
    _namaController = TextEditingController(text: data['nama']);
    _alamatController = TextEditingController(text: data['alamat'] ?? '');
    _telpController = TextEditingController(text: data['no_telp'] ?? '');
    _emailController = TextEditingController(text: data['email'] ?? '');
    _bidangController = TextEditingController(text: data['bidang'] ?? '');
    _jurusanController = TextEditingController();
    _picController = TextEditingController(text: data['pic'] ?? '');
    _picTelpController = TextEditingController(text: data['pic_telp'] ?? '');
    _isActive = data['is_active'] ?? false;
    
    _namaFocusNode = FocusNode();
    _alamatFocusNode = FocusNode();
    _telpFocusNode = FocusNode();
    _emailFocusNode = FocusNode();
    _bidangFocusNode = FocusNode();
    _jurusanFocusNode = FocusNode();
    _picFocusNode = FocusNode();
    _picTelpFocusNode = FocusNode();
    
    _jurusanSearchController.addListener(_filterJurusanList);
    
    // Coba cek dulu jurusan dari data sebelum fetch
    final jurusanFromData = data['jurusan'];
    if (jurusanFromData != null) {
      print('Jurusan dari data object: $jurusanFromData');
      print('Jurusan ID: ${jurusanFromData['id']}');
      print('Jurusan Nama: ${jurusanFromData['nama']}');
      
      // Set sementara sebelum fetch
      _jurusanController.text = jurusanFromData['nama'] ?? '';
    }
    
    _fetchJurusanList();
    print('=== END INIT ===');
  }

  @override
  void dispose() {
    _namaFocusNode.dispose();
    _alamatFocusNode.dispose();
    _telpFocusNode.dispose();
    _emailFocusNode.dispose();
    _bidangFocusNode.dispose();
    _jurusanFocusNode.dispose();
    _picFocusNode.dispose();
    _picTelpFocusNode.dispose();
    _jurusanSearchController.dispose();
    _jurusanSearchFocusNode.dispose();
    _removeJurusanOverlay();
    super.dispose();
  }

  void _filterJurusanList() {
    final query = _jurusanSearchController.text.toLowerCase();
    setState(() {
      _filteredJurusanList = _jurusanList.where((jurusan) {
        return (jurusan['nama']?.toString().toLowerCase() ?? '').contains(query) ||
               (jurusan['kode']?.toString().toLowerCase() ?? '').contains(query);
      }).toList();
    });
    
    // Update overlay jika sedang terbuka
    if (_jurusanOverlayEntry != null && _jurusanOverlayEntry!.mounted) {
      _jurusanOverlayEntry!.markNeedsBuild();
    }
  }

  Future<void> _fetchJurusanList() async {
    try {
      setState(() => _isLoading = true);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/jurusan'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('=== FETCH JURUSAN LIST ===');
      print('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        print('Decoded Response: $decoded');

        List<Map<String, dynamic>> jurusanData = [];
        
        if (decoded is List) {
          jurusanData = List<Map<String, dynamic>>.from(decoded);
        } else if (decoded['data'] != null) {
          if (decoded['data'] is List) {
            jurusanData = List<Map<String, dynamic>>.from(decoded['data']);
          } else if (decoded['data']['data'] is List) {
            jurusanData = List<Map<String, dynamic>>.from(decoded['data']['data']);
          }
        }

        print('Loaded ${jurusanData.length} jurusan');
        for (var jurusan in jurusanData) {
          print('Jurusan: ${jurusan['id']} - ${jurusan['nama']}');
        }

        setState(() {
          _jurusanList = jurusanData;
          _filteredJurusanList = List.from(jurusanData);
          
          // CARI JURUSAN YANG SESUAI
          final currentJurusanId = widget.industryData['jurusan_id']?.toString() ?? 
                                  widget.industryData['jurusan']?['id']?.toString();
          
          print('Current Jurusan ID to find: $currentJurusanId');
          
          if (currentJurusanId != null && currentJurusanId.isNotEmpty) {
            try {
              final selectedJurusan = jurusanData.firstWhere(
                (j) => j['id'].toString() == currentJurusanId.toString(),
              );
              
              print('Found jurusan: ${selectedJurusan['nama']}');
              
              _selectedJurusan = selectedJurusan;
              _jurusanController.text = selectedJurusan['nama'] ?? '';
            } catch (e) {
              print('Jurusan not found in list: $e');
              
              // Coba cek jurusan dari data object langsung
              final jurusanFromData = widget.industryData['jurusan'];
              if (jurusanFromData != null) {
                print('Using jurusan from data object directly');
                _selectedJurusan = {
                  'id': jurusanFromData['id']?.toString(),
                  'nama': jurusanFromData['nama'] ?? '',
                  'kode': jurusanFromData['kode'] ?? '',
                };
                _jurusanController.text = jurusanFromData['nama'] ?? '';
              } else {
                _jurusanController.clear();
              }
            }
          } else {
            print('No jurusan ID found in industry data');
          }
          
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load jurusan data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading jurusan data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateIndustry() async {
    // Dismiss keyboard before validating
    FocusScope.of(context).unfocus();
    
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final Map<String, dynamic> updateData = {
      'nama': _namaController.text,
      'alamat': _alamatController.text,
      'no_telp': _telpController.text,
      'email': _emailController.text,
      'bidang': _bidangController.text,
      'pic': _picController.text,
      'pic_telp': _picTelpController.text,
      'is_active': _isActive,
    };

    print('Selected Jurusan: $_selectedJurusan');
    
    if (_selectedJurusan != null && _selectedJurusan!['id'] != null) {
      final jurusanId = int.tryParse(_selectedJurusan!['id']!.toString());
      if (jurusanId != null) {
        updateData['jurusan_id'] = jurusanId;
      } else {
        updateData['jurusan_id'] = null;
      }
    } else {
      updateData['jurusan_id'] = null;
    }

    print('Update Data with jurusan_id: ${updateData['jurusan_id']}');

    try {
      final response = await http.put(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/industri/${widget.industryData['id']}'),
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
        final String errorMessage = error['message'] ?? 'Gagal memperbarui industri';
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
      barrierColor: Colors.black.withValues(alpha: 0.5),
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
                            color: Colors.white.withValues(alpha: 0.2),
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
                      'Data industri "${_namaController.text}" berhasil diperbarui',
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
      barrierColor: Colors.black.withValues(alpha: 0.5),
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
                            color: Colors.white.withValues(alpha: 0.2),
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

  // ========== JURUSAN OVERLAY POPUP ==========

  void _showJurusanPopupOverlay(BuildContext context) {
    if (_jurusanOverlayEntry != null) {
      _removeJurusanOverlay();
      return;
    }

    final RenderBox renderBox = _jurusanFieldKey.currentContext!.findRenderObject() as RenderBox;
    final fieldOffset = renderBox.localToGlobal(Offset.zero);
    final fieldSize = renderBox.size;
    final screenSize = MediaQuery.of(context).size;

    double top = fieldOffset.dy + fieldSize.height + 4;
    double left = fieldOffset.dx;
    final double width = fieldSize.width;
    final double maxHeight = screenSize.height * 0.4;

    // Pastikan popup tidak keluar dari layar
    if (top + maxHeight > screenSize.height) {
      top = fieldOffset.dy - maxHeight - 4;
    }
    if (left + width > screenSize.width) {
      left = screenSize.width - width;
    }
    if (left < 0) left = 0;

    _jurusanOverlayEntry = OverlayEntry(
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
                                  controller: _jurusanSearchController,
                                  focusNode: _jurusanSearchFocusNode,
                                  decoration: const InputDecoration(
                                    hintText: 'Cari jurusan...',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                  ),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              if (_jurusanSearchController.text.isNotEmpty)
                                GestureDetector(
                                  onTap: () => _jurusanSearchController.clear(),
                                  child: const Icon(Icons.clear, size: 16, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          _removeJurusanOverlay();
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
                
                // List Jurusan
                Expanded(
                  child: _buildJurusanList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_jurusanOverlayEntry!);
    setState(() {
      _showJurusanPopup = true;
    });
  }

  Widget _buildJurusanList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_filteredJurusanList.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.school_outlined, size: 40, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'Tidak ada jurusan tersedia',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Tambahkan opsi "Tidak ada jurusan"
    final List<Map<String, dynamic>> options = [
      {'id': null, 'nama': 'Tidak ada jurusan', 'kode': ''},
      ..._filteredJurusanList,
    ];

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: options.length,
      itemBuilder: (context, index) {
        final jurusan = options[index];
        final isSelected = _selectedJurusan != null && 
                        _selectedJurusan!['id']?.toString() == jurusan['id']?.toString();
        
        print('Building jurusan item: ${jurusan['nama']} - isSelected: $isSelected');
        
        return InkWell(
          onTap: () {
            print('Jurusan selected: ${jurusan['nama']}');
            setState(() {
              if (jurusan['id'] == null) {
                _selectedJurusan = null;
                _jurusanController.clear();
                print('Jurusan cleared');
              } else {
                _selectedJurusan = jurusan;
                _jurusanController.text = jurusan['nama'] ?? '';
                print('Jurusan set to: ${jurusan['nama']}');
              }
            });
            _removeJurusanOverlay();
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
                    Icons.school,
                    color: isSelected ? Colors.white : Colors.grey[600],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        jurusan['nama'] ?? '-',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: isSelected ? _primaryColor : Colors.black87,
                        ),
                      ),
                      if (jurusan['kode'] != null && jurusan['kode'].toString().isNotEmpty)
                        Text(
                          jurusan['kode'].toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? _primaryColor.withValues(alpha: 0.8) : Colors.grey,
                          ),
                        ),
                    ],
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

  void _removeJurusanOverlay() {
    if (_jurusanOverlayEntry != null) {
      _jurusanOverlayEntry!.remove();
      _jurusanOverlayEntry = null;
    }
    setState(() {
      _showJurusanPopup = false;
    });
    _jurusanSearchController.clear();
    _jurusanSearchFocusNode.unfocus();
  }

  // ========== FORM FIELDS ==========

  Widget _buildFormField(
      IconData icon, String label, TextEditingController controller, FocusNode focusNode,
      {TextInputType keyboardType = TextInputType.text, bool isRequired = true}) {
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
                  focusNode: focusNode,
                  keyboardType: keyboardType,
                  validator: isRequired
                      ? (value) => value == null || value.isEmpty ? 'Wajib diisi' : null
                      : null,
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
    );
  }

  Widget _buildJurusanField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      key: _jurusanFieldKey,
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
        onTap: () => _showJurusanPopupOverlay(context),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
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
                    'Jurusan',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _jurusanController.text.isEmpty ? 'Pilih Jurusan (Opsional)' : _jurusanController.text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _jurusanController.text.isNotEmpty ? Colors.black87 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              _showJurusanPopup ? Icons.expand_less : Icons.expand_more,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchField() {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _primaryColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.power_settings_new_rounded, color: Colors.white, size: 20),
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
                  'Status',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isActive ? 'Aktif' : 'Tidak Aktif',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Switch(
                      value: _isActive,
                      activeColor: _primaryColor,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside
        FocusScope.of(context).unfocus();
        // Tutup overlay jurusan jika terbuka
        if (_jurusanOverlayEntry != null) {
          _removeJurusanOverlay();
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
                      'Edit Industri',
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
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: _isLoading
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
                                // ICON INDUSTRI DI TENGAH
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
                                          color: Colors.black.withValues(alpha: 0.1),
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
                                        Icons.factory_rounded,
                                        size: 60,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // JUDUL FORM DI TENGAH
                                const Text(
                                  'Edit Data Industri',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 30),
                                
                                // FORM FIELDS
                                _buildFormField(
                                  Icons.business_rounded,
                                  'Nama Industri',
                                  _namaController,
                                  _namaFocusNode,
                                ),
                                _buildFormField(
                                  Icons.location_on_rounded,
                                  'Alamat',
                                  _alamatController,
                                  _alamatFocusNode,
                                ),
                                _buildFormField(
                                  Icons.phone_rounded,
                                  'No. Telepon',
                                  _telpController,
                                  _telpFocusNode,
                                  keyboardType: TextInputType.phone,
                                ),
                                _buildFormField(
                                  Icons.email_rounded,
                                  'Email',
                                  _emailController,
                                  _emailFocusNode,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                _buildFormField(
                                  Icons.work_rounded,
                                  'Bidang',
                                  _bidangController,
                                  _bidangFocusNode,
                                ),
                                _buildJurusanField(),
                                _buildFormField(
                                  Icons.person_rounded,
                                  'Nama PIC',
                                  _picController,
                                  _picFocusNode,
                                ),
                                _buildFormField(
                                  Icons.phone_android_rounded,
                                  'Telepon PIC',
                                  _picTelpController,
                                  _picTelpFocusNode,
                                  keyboardType: TextInputType.phone,
                                ),
                                _buildSwitchField(),
                                
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
                                                color: _primaryColor.withValues(alpha: 0.2),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            onPressed: _isSubmitting ? null : _updateIndustry,
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
}