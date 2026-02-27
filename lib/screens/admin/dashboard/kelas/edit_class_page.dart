import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EditClassPage extends StatefulWidget {
  final Map<String, dynamic> classData;

  const EditClassPage({super.key, required this.classData});

  @override
  State<EditClassPage> createState() => _EditClassPageState();
}

class _EditClassPageState extends State<EditClassPage> {
  final _formKey = GlobalKey<FormState>();
  late FocusNode _namaFocusNode;
  late FocusNode _jurusanFocusNode;

  late TextEditingController _namaController;
  late TextEditingController _jurusanController;

  Map<String, dynamic>? _selectedJurusan;
  List<Map<String, dynamic>> _jurusanList = [];
  List<Map<String, dynamic>> _filteredJurusanList = [];

  // State untuk Wali Kelas
  List<Map<String, dynamic>> _guruList = [];
  List<Map<String, dynamic>> _filteredGuruList = [];
  Map<String, dynamic>? _selectedWaliKelas;
  bool _isLoadingGuru = false;

  final Color _primaryColor = const Color(0xFF3B060A);
  final Color _accentColor = const Color(0xFF5B1A1A);
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _showJurusanPopup = false;
  bool _showWaliKelasPopup = false;

  // Keys untuk mendapatkan posisi
  final GlobalKey _jurusanFieldKey = GlobalKey();
  final GlobalKey _waliKelasFieldKey = GlobalKey();

  OverlayEntry? _jurusanOverlayEntry;
  OverlayEntry? _waliKelasOverlayEntry;

  final TextEditingController _jurusanSearchController =
      TextEditingController();
  final TextEditingController _waliKelasSearchController =
      TextEditingController();

  final FocusNode _jurusanSearchFocusNode = FocusNode();
  final FocusNode _waliKelasSearchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.classData['nama']);
    _jurusanController = TextEditingController();

    _namaFocusNode = FocusNode();
    _jurusanFocusNode = FocusNode();

    _jurusanSearchController.addListener(_filterJurusanList);
    _waliKelasSearchController.addListener(_filterWaliKelasList);

    _fetchJurusan();
    _fetchGuruWaliKelas();
  }

  @override
  void dispose() {
    _namaFocusNode.dispose();
    _jurusanFocusNode.dispose();
    _jurusanSearchController.dispose();
    _jurusanSearchFocusNode.dispose();
    _waliKelasSearchController.dispose();
    _waliKelasSearchFocusNode.dispose();
    _removeJurusanOverlay();
    _removeWaliKelasOverlay();
    super.dispose();
  }

  // ========== FILTER METHODS ==========
  void _filterJurusanList() {
    final query = _jurusanSearchController.text.toLowerCase();
    setState(() {
      _filteredJurusanList = _jurusanList.where((jurusan) {
        return (jurusan['nama']?.toString().toLowerCase() ?? '')
                .contains(query) ||
            (jurusan['kode']?.toString().toLowerCase() ?? '').contains(query);
      }).toList();
    });

    if (_jurusanOverlayEntry != null && _jurusanOverlayEntry!.mounted) {
      _jurusanOverlayEntry!.markNeedsBuild();
    }
  }

  void _filterWaliKelasList() {
    final query = _waliKelasSearchController.text.toLowerCase().trim();

    print('🟡 Filtering with query: "$query"');
    print('🟡 Total guru before filter: ${_guruList.length}');

    setState(() {
      if (query.isEmpty) {
        // Jika query kosong, tampilkan semua
        _filteredGuruList = List.from(_guruList);
        print('🟡 Query empty, showing all: ${_filteredGuruList.length}');
      } else {
        // Filter berdasarkan nama, nip, atau kode_guru
        _filteredGuruList = _guruList.where((guru) {
          final nama = (guru['nama']?.toString().toLowerCase() ?? '');
          final nip = (guru['nip']?.toString().toLowerCase() ?? '');
          final kode = (guru['kode_guru']?.toString().toLowerCase() ?? '');

          final matches = nama.contains(query) ||
              nip.contains(query) ||
              kode.contains(query);

          if (matches) {
            print('🟡 Match found: ${guru['nama']}');
          }

          return matches;
        }).toList();

        print('🟡 Filtered count: ${_filteredGuruList.length}');
      }
    });

    // Update overlay jika terbuka
    if (_waliKelasOverlayEntry != null && _waliKelasOverlayEntry!.mounted) {
      _waliKelasOverlayEntry!.markNeedsBuild();
    }
  }

  // ========== FETCH DATA ==========
  Future<void> _fetchJurusan() async {
    try {
      setState(() => _isLoading = true);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/jurusan?limit=1000'),
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

        final List<Map<String, dynamic>> jurusanData = [];
        for (var jurusan in data) {
          jurusanData.add({
            'id': jurusan['id']?.toString(),
            'nama': jurusan['nama'] ?? 'Unknown',
            'kode': jurusan['kode'] ?? '',
          });
        }

        setState(() {
          _jurusanList = jurusanData;
          _filteredJurusanList = List.from(jurusanData);

          final currentJurusanId = widget.classData['jurusan']?['id'] ??
              widget.classData['jurusan_id'];
          if (currentJurusanId != null) {
            try {
              final selectedJurusan = jurusanData.firstWhere(
                (j) => j['id'] == currentJurusanId.toString(),
              );
              _selectedJurusan = selectedJurusan;
              _jurusanController.text = selectedJurusan['nama'];
            } catch (e) {
              _jurusanController.clear();
            }
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

  Future<void> _fetchGuruWaliKelas() async {
    try {
      setState(() => _isLoadingGuru = true);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      print('🟡 Fetching guru data...');

      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/guru?limit=1000'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🟡 Response status: ${response.statusCode}');
      print('🟡 Response body: ${response.body}'); // Log full response

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        // Log struktur data
        print('🟡 Decoded data structure: $decoded');

        List data = [];

        // Handle berbagai kemungkinan struktur response
        if (decoded['data'] != null) {
          if (decoded['data']['data'] is List) {
            data = decoded['data']['data'];
            print('🟡 Using data.data structure, count: ${data.length}');
          } else if (decoded['data'] is List) {
            data = decoded['data'];
            print('🟡 Using data array structure, count: ${data.length}');
          }
        } else if (decoded is List) {
          data = decoded;
          print('🟡 Using direct array structure, count: ${data.length}');
        }

        print('🟡 Total guru from API: ${data.length}');

        // Filter hanya guru dengan is_wali_kelas = true
        final List<Map<String, dynamic>> guruData = [];
        for (var guru in data) {
          print(
              '🟡 Guru: ${guru['nama']}, is_wali_kelas: ${guru['is_wali_kelas']}');

          if (guru['is_wali_kelas'] == true) {
            guruData.add({
              'id': guru['id']?.toString(),
              'nama': guru['nama'] ?? 'Unknown',
              'nip': guru['nip'] ?? '',
              'kode_guru': guru['kode_guru'] ?? '',
              'is_wali_kelas': guru['is_wali_kelas'] ?? false,
            });
          }
        }

        print('🟡 Filtered wali kelas count: ${guruData.length}');

        setState(() {
          _guruList = guruData;
          _filteredGuruList = List.from(guruData);

          final currentWaliKelasId = widget.classData['wali_kelas_guru_id'];
          print('🟡 Current wali_kelas_guru_id: $currentWaliKelasId');

          if (currentWaliKelasId != null) {
            try {
              final selectedGuru = guruData.firstWhere(
                (g) => g['id'] == currentWaliKelasId.toString(),
              );
              _selectedWaliKelas = selectedGuru;
              print('🟡 Selected wali kelas: ${selectedGuru['nama']}');
            } catch (e) {
              print('🟡 Selected wali kelas not found in list');
              _selectedWaliKelas = null;
            }
          }

          _isLoadingGuru = false;
        });
      } else {
        print('🟡 Error response: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load guru data: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading guru data: $e');
      setState(() {
        _isLoadingGuru = false;
      });
    }
  }

  // ========== UPDATE CLASS ==========
  Future<void> _updateClass() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final Map<String, dynamic> updateData = {
      'nama': _namaController.text.trim(),
    };

    if (_selectedJurusan != null) {
      final jurusanId = int.tryParse(_selectedJurusan!['id']!);
      if (jurusanId != null) {
        updateData['jurusan_id'] = jurusanId;
      }
    }

    if (_selectedWaliKelas != null && _selectedWaliKelas!['id'] != null) {
      final waliKelasId = int.tryParse(_selectedWaliKelas!['id']!);
      if (waliKelasId != null) {
        updateData['wali_kelas_guru_id'] = waliKelasId;
      }
    } else {
      updateData['remove_wali_kelas'] = true;
    }

    try {
      final response = await http.put(
        Uri.parse(
            '${dotenv.env['API_BASE_URL']}/api/kelas/${widget.classData['id']}'),
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
        final String errorMessage =
            error['message'] ?? 'Gagal memperbarui kelas';
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showErrorDialog('Terjadi kesalahan jaringan');
    }
  }

  // ========== DIALOGS ==========
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
                      icon: const Icon(Icons.close,
                          size: 20, color: Colors.white),
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
                      'Data kelas "${_namaController.text}" berhasil diperbarui',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
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
                      icon: const Icon(Icons.close,
                          size: 20, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
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

  // ========== JURUSAN OVERLAY ==========
  void _showJurusanPopupOverlay(BuildContext context) {
    if (_jurusanOverlayEntry != null) {
      _removeJurusanOverlay();
      return;
    }

    final RenderBox renderBox =
        _jurusanFieldKey.currentContext!.findRenderObject() as RenderBox;
    final fieldOffset = renderBox.localToGlobal(Offset.zero);
    final fieldSize = renderBox.size;
    final screenSize = MediaQuery.of(context).size;

    double top = fieldOffset.dy + fieldSize.height;
    double left = fieldOffset.dx;
    final double width = fieldSize.width;
    final double maxHeight = screenSize.height * 0.3;

    if (top + maxHeight > screenSize.height) {
      top = fieldOffset.dy - maxHeight;
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
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search,
                                  color: Colors.grey, size: 20),
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
                                  child: const Icon(Icons.clear,
                                      size: 16, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _removeJurusanOverlay,
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
            _selectedJurusan!['id'] == jurusan['id'];

        return InkWell(
          onTap: () {
            setState(() {
              if (jurusan['id'] == null) {
                _selectedJurusan = null;
                _jurusanController.clear();
              } else {
                _selectedJurusan = jurusan;
                _jurusanController.text = jurusan['nama'] ?? '';
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
              color: isSelected
                  ? _primaryColor.withValues(alpha: 0.1)
                  : Colors.transparent,
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
                      if (jurusan['kode'] != null &&
                          jurusan['kode'].toString().isNotEmpty)
                        Text(
                          jurusan['kode'].toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? _primaryColor.withValues(alpha: 0.8)
                                : Colors.grey,
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

  // ========== WALI KELAS OVERLAY ==========
  void _showWaliKelasPopupOverlay(BuildContext context) {
    if (_waliKelasOverlayEntry != null) {
      _removeWaliKelasOverlay();
      return;
    }

    final RenderBox renderBox =
        _waliKelasFieldKey.currentContext!.findRenderObject() as RenderBox;
    final fieldOffset = renderBox.localToGlobal(Offset.zero);
    final fieldSize = renderBox.size;
    final screenSize = MediaQuery.of(context).size;

    double top = fieldOffset.dy + fieldSize.height;
    double left = fieldOffset.dx;
    final double width = fieldSize.width;
    final double maxHeight = screenSize.height * 0.3;

    if (top + maxHeight > screenSize.height) {
      top = fieldOffset.dy - maxHeight;
    }
    if (left + width > screenSize.width) {
      left = screenSize.width - width;
    }
    if (left < 0) left = 0;

    _waliKelasOverlayEntry = OverlayEntry(
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
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search,
                                  color: Colors.grey, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _waliKelasSearchController,
                                  focusNode: _waliKelasSearchFocusNode,
                                  decoration: const InputDecoration(
                                    hintText: 'Cari wali kelas...',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                  ),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              if (_waliKelasSearchController.text.isNotEmpty)
                                GestureDetector(
                                  onTap: () =>
                                      _waliKelasSearchController.clear(),
                                  child: const Icon(Icons.clear,
                                      size: 16, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _removeWaliKelasOverlay,
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
                Expanded(
                  child: _buildWaliKelasList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_waliKelasOverlayEntry!);
    setState(() {
      _showWaliKelasPopup = true;
    });
  }

  Widget _buildWaliKelasList() {
    if (_isLoadingGuru) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    print('🟡 Building wali kelas list');
    print('🟡 _guruList length: ${_guruList.length}');
    print('🟡 _filteredGuruList length: ${_filteredGuruList.length}');
    print('🟡 Search query: "${_waliKelasSearchController.text}"');

    // Tentukan list yang akan ditampilkan
    List<Map<String, dynamic>> displayList;

    if (_waliKelasSearchController.text.isEmpty) {
      // Jika tidak ada pencarian, tampilkan semua guru
      displayList = _guruList;
      print('🟡 No search, showing all ${_guruList.length} guru');
    } else {
      // Jika ada pencarian, tampilkan hasil filter
      displayList = _filteredGuruList;
      print(
          '🟡 Search active, showing ${_filteredGuruList.length} filtered results');
    }

    if (displayList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _waliKelasSearchController.text.isEmpty
                    ? Icons.person_off_outlined
                    : Icons.search_off,
                size: 40,
                color: Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                _waliKelasSearchController.text.isEmpty
                    ? 'Tidak ada wali kelas tersedia'
                    : 'Tidak ada hasil untuk "${_waliKelasSearchController.text}"',
                style: const TextStyle(color: Colors.grey),
              ),
              if (_waliKelasSearchController.text.isNotEmpty)
                TextButton(
                  onPressed: () {
                    _waliKelasSearchController.clear();
                  },
                  child: const Text('Hapus pencarian'),
                ),
            ],
          ),
        ),
      );
    }

    // Buat list options dengan "Tidak ada wali kelas" di atas
    final List<Map<String, dynamic>> options = [
      {'id': null, 'nama': 'Tidak ada wali kelas', 'nip': '', 'kode_guru': ''},
      ...displayList,
    ];

    print('🟡 Total options to display: ${options.length}');

    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: options.length,
      itemBuilder: (context, index) {
        final guru = options[index];
        final isSelected = _selectedWaliKelas != null &&
            _selectedWaliKelas!['id'] == guru['id'];

        // Log untuk setiap item yang ditampilkan
        if (index > 0) {
          print(
              '🟡 Displaying option $index: ${guru['nama']} (ID: ${guru['id']})');
        }

        return InkWell(
          onTap: () {
            print('🟡 Selected: ${guru['nama']}');
            setState(() {
              if (guru['id'] == null) {
                _selectedWaliKelas = null;
              } else {
                _selectedWaliKelas = guru;
              }
            });
            _removeWaliKelasOverlay();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? _primaryColor.withValues(alpha: 0.1)
                  : Colors.transparent,
              border: index > 0
                  ? Border(
                      top: BorderSide(color: Colors.grey[100]!),
                    )
                  : null,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        guru['nama'] ?? '-',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: isSelected ? _primaryColor : Colors.black87,
                        ),
                      ),
                      if (guru['nip'] != null &&
                          guru['nip'].toString().isNotEmpty)
                        Text(
                          'NIP: ${guru['nip']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? _primaryColor.withValues(alpha: 0.8)
                                : Colors.grey,
                          ),
                        ),
                      if (guru['kode_guru'] != null &&
                          guru['kode_guru'].toString().isNotEmpty)
                        Text(
                          'Kode: ${guru['kode_guru']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? _primaryColor.withValues(alpha: 0.8)
                                : Colors.grey,
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

  void _removeWaliKelasOverlay() {
    if (_waliKelasOverlayEntry != null) {
      _waliKelasOverlayEntry!.remove();
      _waliKelasOverlayEntry = null;
    }
    setState(() {
      _showWaliKelasPopup = false;
    });
    _waliKelasSearchController.clear();
    _waliKelasSearchFocusNode.unfocus();
  }

  // ========== FORM FIELDS ==========
  Widget _buildFormField(IconData icon, String label,
      TextEditingController controller, FocusNode focusNode) {
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
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: focusNode.hasFocus
                          ? _primaryColor
                          : Colors.grey.shade300,
                      width: focusNode.hasFocus ? 2 : 1,
                    ),
                  ),
                  child: TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Wajib diisi' : null,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      border: InputBorder.none,
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      errorStyle: const TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                      ),
                      suffixIcon: focusNode.hasFocus
                          ? Icon(
                              Icons.edit_rounded,
                              size: 18,
                              color: _primaryColor,
                            )
                          : null,
                    ),
                    onTap: () {
                      setState(() {});
                    },
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
              child: const Icon(Icons.school_rounded,
                  color: Colors.white, size: 20),
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
                    'Program Keahlian',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _jurusanController.text.isEmpty
                        ? 'Pilih Jurusan'
                        : _jurusanController.text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _jurusanController.text.isNotEmpty
                          ? Colors.black87
                          : Colors.grey[600],
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

  Widget _buildWaliKelasField() {
    String displayText = 'Pilih Wali Kelas';
    if (_selectedWaliKelas != null) {
      displayText = _selectedWaliKelas!['nama'];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      key: _waliKelasFieldKey,
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
        onTap: () => _showWaliKelasPopupOverlay(context),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded,
                  color: Colors.white, size: 20),
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
                    'Wali Kelas',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _selectedWaliKelas != null
                          ? Colors.black87
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              _showWaliKelasPopup ? Icons.expand_less : Icons.expand_more,
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
        FocusScope.of(context).unfocus();
        if (_jurusanOverlayEntry != null) {
          _removeJurusanOverlay();
        }
        if (_waliKelasOverlayEntry != null) {
          _removeWaliKelasOverlay();
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
                      'Ubah Data Kelas',
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 30),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // ICON KELAS DI TENGAH
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
                                          color: Colors.black
                                              .withValues(alpha: 0.1),
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
                                        Icons.class_rounded,
                                        size: 60,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),

                                // JUDUL FORM DI TENGAH
                                const Text(
                                  'Ubah Data Kelas',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 30),

                                // FORM FIELDS
                                _buildFormField(
                                  Icons.class_rounded,
                                  'Nama Kelas',
                                  _namaController,
                                  _namaFocusNode,
                                ),
                                _buildJurusanField(),
                                _buildWaliKelasField(),

                                const SizedBox(height: 40),

                                // TOMBOL SIMPAN
                                Container(
                                  margin: const EdgeInsets.only(bottom: 30),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: _primaryColor.withValues(
                                                    alpha: 0.2),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            onPressed: _isSubmitting
                                                ? null
                                                : _updateClass,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: _primaryColor,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 16),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              elevation: 0,
                                            ),
                                            child: _isSubmitting
                                                ? const Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child:
                                                            CircularProgressIndicator(
                                                          strokeWidth: 2.5,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      SizedBox(width: 12),
                                                      Text(
                                                        'Menyimpan...',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                : const Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(Icons.save_rounded,
                                                          size: 20),
                                                      SizedBox(width: 10),
                                                      Text(
                                                        'Simpan Perubahan',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
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
