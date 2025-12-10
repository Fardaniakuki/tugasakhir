import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Industri {
  final int id;
  final String nama;
  final String alamat;
  final String bidang;
  final String? email;
  final String? noTelp;
  final String? pic;
  final String? picTelp;
  final int? jurusanId;
  final bool isActive;

  Industri({
    required this.id,
    required this.nama,
    required this.alamat,
    required this.bidang,
    this.email,
    this.noTelp,
    this.pic,
    this.picTelp,
    this.jurusanId,
    required this.isActive,
  });

  factory Industri.fromJson(Map<String, dynamic> json) {
    return Industri(
      id: json['id'],
      nama: json['nama'],
      alamat: json['alamat'],
      bidang: json['bidang'],
      email: json['email'],
      noTelp: json['no_telp'],
      pic: json['pic'],
      picTelp: json['pic_telp'],
      jurusanId: json['jurusan_id'],
      isActive: json['is_active'] ?? true,
    );
  }

  @override
  String toString() => nama;
}

// Enum untuk posisi popup
enum PopupPosition {
  below,      // Di bawah field (default)
  above,      // Di atas field
  center,     // Di tengah layar
  custom,     // Posisi kustom
}

class AjukanPKLDialog extends StatefulWidget {
  final String? token;
  final int? kelasId;
  final PopupPosition popupPosition;
  final Offset? customPosition;
  final double? popupWidth;
  final double? popupMaxHeight;
  final double horizontalOffset; // TAMBAHAN: offset horizontal
  final double verticalOffset;   // TAMBAHAN: offset vertikal

  const AjukanPKLDialog({
    super.key, 
    this.token, 
    this.kelasId,
    this.popupPosition = PopupPosition.below,
    this.customPosition,
    this.popupWidth,
    this.popupMaxHeight,
    this.horizontalOffset = 40.0, // TAMBAHAN: default 40
    this.verticalOffset = 0.0,   // TAMBAHAN: default 0
  });

  @override
  State<AjukanPKLDialog> createState() => _AjukanPKLDialogState();
}

class _AjukanPKLDialogState extends State<AjukanPKLDialog> {
  final _catatanController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  List<Industri> _industriList = [];
  List<Industri> _filteredIndustriList = [];
  Industri? _selectedIndustri;
  bool _isLoading = true;
  bool _showIndustriPopup = false;
  int? _jurusanId;
  
  // Keys untuk mendapatkan posisi
  final GlobalKey _industriFieldKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterIndustriList);
  }

  void _filterIndustriList() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredIndustriList = _industriList.where((industri) {
        return industri.nama.toLowerCase().contains(query) ||
               industri.bidang.toLowerCase().contains(query) ||
               (industri.alamat).toLowerCase().contains(query);
      }).toList();
    });
    
    // Update overlay jika sedang terbuka
    if (_overlayEntry != null && _overlayEntry!.mounted) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  Future<void> _loadData() async {
    if (widget.token == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      if (widget.kelasId == null) {
        await _loadAllIndustri();
        return;
      }

      final kelasResponse = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/kelas/${widget.kelasId}'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (kelasResponse.statusCode == 200) {
        final kelasData = jsonDecode(kelasResponse.body);
        _jurusanId = kelasData['data']['jurusan_id'];
        await _loadIndustriByJurusan(_jurusanId!);
      } else {
        throw Exception('Gagal memuat data kelas');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadIndustriByJurusan(int jurusanId) async {
    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/industri?jurusan_id=$jurusanId&limit=100'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _processIndustriData(data);
      } else {
        throw Exception('Gagal memuat data industri');
      }
    } catch (e) {
      await _loadAllIndustri();
    }
  }

  Future<void> _loadAllIndustri() async {
    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/industri?limit=100'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _processIndustriData(data);
      } else {
        throw Exception('Gagal memuat semua industri');
      }
    } catch (e) {
      throw Exception('Gagal memuat data industri: $e');
    }
  }

  void _processIndustriData(Map<String, dynamic> data) {
    if (data['success'] == true && data['data'] != null) {
      final List<dynamic> industriListData = data['data']['data'] ?? [];
      
      setState(() {
        _industriList = industriListData
            .map((item) => Industri.fromJson(item))
            .where((industri) => industri.isActive)
            .toList();
        _filteredIndustriList = List.from(_industriList);
        _isLoading = false;
      });
    } else {
      throw Exception('Format data tidak sesuai');
    }
  }

  // Fungsi untuk menghitung posisi popup - DIMODIFIKASI
  Offset _calculatePopupPosition(BuildContext context, Size fieldSize, Offset fieldOffset) {
    final screenSize = MediaQuery.of(context).size;
    final popupWidth = widget.popupWidth ?? fieldSize.width;
    double left = fieldOffset.dx;
    double top = fieldOffset.dy;

    switch (widget.popupPosition) {
      case PopupPosition.below:
        top = fieldOffset.dy + fieldSize.height + widget.verticalOffset;
        left += widget.horizontalOffset; // TAMBAHAN
        break;
        
      case PopupPosition.above:
        final maxHeight = widget.popupMaxHeight ?? screenSize.height * 0.4;
        top = fieldOffset.dy - maxHeight - widget.verticalOffset;
        left += widget.horizontalOffset; // TAMBAHAN
        break;
        
      case PopupPosition.center:
        left = (screenSize.width - popupWidth) / 2 + widget.horizontalOffset; // TAMBAHAN
        top = (screenSize.height - (widget.popupMaxHeight ?? screenSize.height * 0.4)) / 2 + widget.verticalOffset; // TAMBAHAN
        break;
        
      case PopupPosition.custom:
        if (widget.customPosition != null) {
          left = widget.customPosition!.dx + widget.horizontalOffset; // TAMBAHAN
          top = widget.customPosition!.dy + widget.verticalOffset; // TAMBAHAN
        } else {
          top = fieldOffset.dy + fieldSize.height + widget.verticalOffset;
          left += widget.horizontalOffset; // TAMBAHAN
        }
        break;
    }

    // Pastikan popup tidak keluar dari layar
    if (left + popupWidth > screenSize.width) {
      left = screenSize.width - popupWidth;
    }
    if (left < 0) left = 0;
    
    if (top < 0) top = 0;

    return Offset(left, top);
  }

  void _showIndustriPopupOverlay(BuildContext context) {
    if (_overlayEntry != null) {
      _removeOverlay();
      return;
    }

    final RenderBox renderBox = _industriFieldKey.currentContext!.findRenderObject() as RenderBox;
    final fieldOffset = renderBox.localToGlobal(Offset.zero);
    final fieldSize = renderBox.size;
    final popupWidth = widget.popupWidth ?? fieldSize.width;
    final maxHeight = widget.popupMaxHeight ?? MediaQuery.of(context).size.height * 0.4;
    
    final popupPosition = _calculatePopupPosition(context, fieldSize, fieldOffset);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: popupPosition.dx,
          top: popupPosition.dy,
          width: popupWidth,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: maxHeight,
              ),
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
                                      hintText: 'Cari industri...',
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
                  
                  // List Industri
                  Expanded(
                    child: _buildIndustriList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _showIndustriPopup = true;
    });
  }

  Widget _buildIndustriList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_filteredIndustriList.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.business_outlined, size: 40, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'Tidak ada industri tersedia',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _filteredIndustriList.length,
      itemBuilder: (context, index) {
        final industri = _filteredIndustriList[index];
        final isSelected = _selectedIndustri?.id == industri.id;
        
        return InkWell(
          onTap: () {
            setState(() {
              _selectedIndustri = industri;
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
              color: isSelected ? Colors.blue[50] : Colors.transparent,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.business,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        industri.nama,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        industri.bidang,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        industri.alamat,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check,
                    color: Colors.blue,
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
      _showIndustriPopup = false;
    });
    _searchController.clear();
    _searchFocusNode.unfocus();
  }

  Widget _buildIndustriField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      key: _industriFieldKey,
      children: [
        // Label "Industri"
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Industri',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        
        // Field untuk pilih industri
        GestureDetector(
          onTap: () => _showIndustriPopupOverlay(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white, // Warna putih
            ),
            child: Row(
              children: [
                Expanded(
                  child: _selectedIndustri == null
                      ? Text(
                          'Pilih industri',
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.6), // Warna hitam dengan opacity
                            fontSize: 16,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedIndustri!.nama,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black, // Warna hitam
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedIndustri!.bidang,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600], // Warna abu-abu lebih gelap
                              ),
                            ),
                          ],
                        ),
                ),
                Icon(
                  _showIndustriPopup ? Icons.expand_less : Icons.expand_more,
                  color: Colors.black.withOpacity(0.6), // Warna icon
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: GestureDetector(
        onTap: () {
          // Tutup overlay jika klik di luar popup
          if (_overlayEntry != null) {
            _removeOverlay();
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white, // Warna putih untuk form
            borderRadius: BorderRadius.circular(12),
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header "Ajukan PKL" dengan garis bawah transparan
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Ajukan PKL',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () {
                              _removeOverlay();
                              Navigator.of(context).pop();
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 1,
                        color: Colors.grey.withOpacity(0.3), // Garis abu-abu transparan
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Industri Field
                  _buildIndustriField(context),
                  
                  const SizedBox(height: 16),
                  
                  // Catatan Field dengan label di atas border
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Label Catatan (di atas border)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8, left: 4),
                        child: Text(
                          'Catatan',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      
                      // TextField dengan ukuran yang lebih kecil - DIUBAH
                      Container(
                        height: 100, // DIUBAH: Tinggi tetap 100px
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: TextFormField(
                          controller: _catatanController,
                          decoration: const InputDecoration(
                            hintText: 'Catatan untuk pengajuan PKL',
                            border: InputBorder.none, // Hapus border default
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, 
                              vertical: 8, // DIUBAH: padding vertikal lebih kecil
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            hintStyle: TextStyle(fontSize: 14), // DIUBAH: ukuran hint lebih kecil
                          ),
                          style: const TextStyle(fontSize: 14), // DIUBAH: ukuran teks lebih kecil
                          maxLines: null, // Biarkan otomatis wrap
                          expands: false, // Tidak mengisi seluruh container
                          textInputAction: TextInputAction.newline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Catatan harus diisi';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _removeOverlay();
                            Navigator.of(context).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Colors.black),
                            backgroundColor: Colors.white, // Warna putih
                          ),
                          child: const Text('Batal', style: TextStyle(color: Colors.black)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_selectedIndustri == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Silakan pilih industri terlebih dahulu'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            
                            if (_catatanController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Silakan isi catatan'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            
                            _removeOverlay();
                            Navigator.of(context).pop({
                              'catatan': _catatanController.text,
                              'industri_id': _selectedIndustri!.id,
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Ajukan',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _catatanController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
}