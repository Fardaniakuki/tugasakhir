import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EditMajorPage extends StatefulWidget {
  final Map<String, dynamic> majorData;

  const EditMajorPage({super.key, required this.majorData});

  @override
  State<EditMajorPage> createState() => _EditMajorPageState();
}

class _EditMajorPageState extends State<EditMajorPage> {
  final _formKey = GlobalKey<FormState>();
  late FocusNode _kodeFocusNode;
  late FocusNode _namaFocusNode;
  late FocusNode _kaprogFocusNode;

  late TextEditingController _kodeController;
  late TextEditingController _namaController;
  late TextEditingController _kaprogController;
  String? _selectedKaprogId;
  List<Map<String, dynamic>> _kaprogList = [];
  List<Map<String, dynamic>> _filteredKaprogList = [];

  final Color _primaryColor = const Color(0xFF3B060A);
  final Color _accentColor = const Color(0xFF5B1A1A);
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _showKaprogPopup = false;

  // Keys untuk mendapatkan posisi
  final GlobalKey _kaprogFieldKey = GlobalKey();
  OverlayEntry? _kaprogOverlayEntry;
  final TextEditingController _kaprogSearchController = TextEditingController();
  final FocusNode _kaprogSearchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _kodeController = TextEditingController(text: widget.majorData['kode']);
    _namaController = TextEditingController(text: widget.majorData['nama']);
    _kaprogController = TextEditingController();
    _selectedKaprogId = widget.majorData['kaprog_guru_id']?.toString();
    
    _kodeFocusNode = FocusNode();
    _namaFocusNode = FocusNode();
    _kaprogFocusNode = FocusNode();

    _kaprogSearchController.addListener(_filterKaprogList);
    
    _loadKaprogData();
  }

  @override
  void dispose() {
    _kodeFocusNode.dispose();
    _namaFocusNode.dispose();
    _kaprogFocusNode.dispose();
    _kaprogSearchController.dispose();
    _kaprogSearchFocusNode.dispose();
    _removeKaprogOverlay();
    super.dispose();
  }

  void _filterKaprogList() {
    final query = _kaprogSearchController.text.toLowerCase();
    setState(() {
      _filteredKaprogList = _kaprogList.where((kaprog) {
        return (kaprog['nama']?.toString().toLowerCase() ?? '').contains(query);
      }).toList();
    });
    
    // Update overlay jika sedang terbuka
    if (_kaprogOverlayEntry != null && _kaprogOverlayEntry!.mounted) {
      _kaprogOverlayEntry!.markNeedsBuild();
    }
  }

  Future<void> _loadKaprogData() async {
    try {
      setState(() => _isLoading = true);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/guru'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        List data = [];
        if (decoded['data'] != null && decoded['data']['data'] is List) {
          data = decoded['data']['data'];
        } else if (decoded['data'] is List) {
          data = decoded['data'];
        }

        final List<Map<String, dynamic>> kaprogData = [];
        for (var guru in data) {
          if (guru['is_kaprog'] == true) {
            kaprogData.add({
              'id': guru['id']?.toString(),
              'nama': guru['nama_lengkap'] ?? guru['nama'] ?? 'Unknown',
            });
          }
        }

        setState(() {
          _kaprogList = kaprogData;
          _filteredKaprogList = List.from(kaprogData);
          
          // Set nama kaprog yang terpilih ke controller
          if (_selectedKaprogId != null && _selectedKaprogId!.isNotEmpty && _selectedKaprogId != 'null') {
            try {
              final selectedKaprog = kaprogData.firstWhere(
                (k) => k['id'] == _selectedKaprogId,
              );
              _kaprogController.text = selectedKaprog['nama'];
            } catch (e) {
              _kaprogController.clear();
            }
          }
          
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load kaprog data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading kaprog data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateMajor() async {
    // Dismiss keyboard before validating
    FocusScope.of(context).unfocus();
    
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final Map<String, dynamic> updateData = {
      'kode': _kodeController.text,
      'nama': _namaController.text,
    };

    if (_selectedKaprogId != null &&
        _selectedKaprogId!.isNotEmpty &&
        _selectedKaprogId != 'null') {
      final kaprogId = int.tryParse(_selectedKaprogId!);
      if (kaprogId != null) {
        updateData['kaprog_guru_id'] = kaprogId;
      } else {
        updateData['kaprog_guru_id'] = null;
      }
    } else {
      updateData['kaprog_guru_id'] = null;
    }

    try {
      final response = await http.put(
        Uri.parse(
            '${dotenv.env['API_BASE_URL']}/api/jurusan/${widget.majorData['id']}'),
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
        final String errorMessage = error['message'] ?? 'Gagal memperbarui jurusan';
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
                      'Data jurusan "${_namaController.text}" berhasil diperbarui',
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

  // ========== KAPROG OVERLAY POPUP ==========

  void _showKaprogPopupOverlay(BuildContext context) {
    if (_kaprogOverlayEntry != null) {
      _removeKaprogOverlay();
      return;
    }

    final RenderBox renderBox = _kaprogFieldKey.currentContext!.findRenderObject() as RenderBox;
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

    _kaprogOverlayEntry = OverlayEntry(
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
                                  controller: _kaprogSearchController,
                                  focusNode: _kaprogSearchFocusNode,
                                  decoration: const InputDecoration(
                                    hintText: 'Cari kaprog...',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                  ),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              if (_kaprogSearchController.text.isNotEmpty)
                                GestureDetector(
                                  onTap: () => _kaprogSearchController.clear(),
                                  child: const Icon(Icons.clear, size: 16, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          _removeKaprogOverlay();
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
                
                // List Kaprog
                Expanded(
                  child: _buildKaprogList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_kaprogOverlayEntry!);
    setState(() {
      _showKaprogPopup = true;
    });
  }

  Widget _buildKaprogList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_filteredKaprogList.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_outline, size: 40, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'Tidak ada kaprog tersedia',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Tambahkan opsi "Tidak ada kaprog"
    final List<Map<String, dynamic>> options = [
      {'id': null, 'nama': 'Tidak ada kaprog'},
      ..._filteredKaprogList,
    ];

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: options.length,
      itemBuilder: (context, index) {
        final kaprog = options[index];
        final isSelected = _selectedKaprogId == kaprog['id']?.toString() || 
                          (_selectedKaprogId == null && kaprog['id'] == null);
        
        return InkWell(
          onTap: () {
            setState(() {
              _selectedKaprogId = kaprog['id']?.toString();
              _kaprogController.text = kaprog['nama'] ?? '';
            });
            _removeKaprogOverlay();
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
              color: isSelected ? _primaryColor.withValues(alpha:0.1) : Colors.transparent,
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
                    Icons.person,
                    color: isSelected ? Colors.white : Colors.grey[600],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    kaprog['nama'] ?? '-',
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

  void _removeKaprogOverlay() {
    if (_kaprogOverlayEntry != null) {
      _kaprogOverlayEntry!.remove();
      _kaprogOverlayEntry = null;
    }
    setState(() {
      _showKaprogPopup = false;
    });
    _kaprogSearchController.clear();
    _kaprogSearchFocusNode.unfocus();
  }

  // ========== FORM FIELDS ==========

  Widget _buildFormField(
      IconData icon, String label, TextEditingController controller, FocusNode focusNode) {
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
    );
  }

  Widget _buildKaprogField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      key: _kaprogFieldKey,
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
        onTap: () => _showKaprogPopupOverlay(context),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
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
                    'Kaprog',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _kaprogController.text.isEmpty ? 'Pilih Kaprog' : _kaprogController.text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _kaprogController.text.isNotEmpty ? Colors.black87 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              _showKaprogPopup ? Icons.expand_less : Icons.expand_more,
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
        // Tutup overlay kaprog jika terbuka
        if (_kaprogOverlayEntry != null) {
          _removeKaprogOverlay();
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
                      'Edit Jurusan',
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
                                        Icons.school_rounded,
                                        size: 60,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // JUDUL FORM DI TENGAH
                                const Text(
                                  'Edit Data Jurusan',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 30),
                                
                                // FORM FIELDS
                                _buildFormField(
                                  Icons.code_rounded,
                                  'Kode Jurusan',
                                  _kodeController,
                                  _kodeFocusNode,
                                ),
                                _buildFormField(
                                  Icons.school_rounded,
                                  'Nama Jurusan',
                                  _namaController,
                                  _namaFocusNode,
                                ),
                                _buildKaprogField(),
                                
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
                                            onPressed: _isSubmitting ? null : _updateMajor,
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