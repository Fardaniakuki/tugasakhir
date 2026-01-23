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

// Cache untuk menyimpan data industri
class IndustriCache {
  static final Map<int, List<Industri>> _cacheByJurusan = {};
  static List<Industri>? _allIndustriCache;
  static DateTime? _lastFetchTime;
  
  static bool isCacheValid() {
    if (_lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!).inMinutes < 5; // Cache 5 menit
  }
  
  static List<Industri>? getCachedIndustriByJurusan(int? jurusanId) {
    if (jurusanId == null) return _allIndustriCache;
    return _cacheByJurusan[jurusanId];
  }
  
  static void cacheIndustriByJurusan(int? jurusanId, List<Industri> industriList) {
    if (jurusanId == null) {
      _allIndustriCache = industriList;
    } else {
      _cacheByJurusan[jurusanId] = industriList;
    }
    _lastFetchTime = DateTime.now();
  }
  
  static void clearCache() {
    _cacheByJurusan.clear();
    _allIndustriCache = null;
    _lastFetchTime = null;
  }
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
  final double horizontalOffset;
  final double verticalOffset;

  const AjukanPKLDialog({
    super.key, 
    required this.token, // Wajib ada token
    required this.kelasId, // Wajib ada kelasId
    this.popupPosition = PopupPosition.below,
    this.customPosition,
    this.popupWidth,
    this.popupMaxHeight,
    this.horizontalOffset = 40.0,
    this.verticalOffset = 0.0, required Color primaryColor,
  });

  @override
  State<AjukanPKLDialog> createState() => _AjukanPKLDialogState();
}

class _AjukanPKLDialogState extends State<AjukanPKLDialog> {
  // Warna serius - merah tua
  final Color _primaryColor = const Color.fromARGB(255, 177, 22, 11); // Merah tua serius
  final Color _secondaryColor = Colors.white; // Putih bersih
  final Color _accentColor = const Color.fromARGB(255, 240, 240, 240); // Abu-abu sangat muda
// Hitam gelap
  final Color _borderColor = const Color.fromARGB(255, 150, 150, 150); // Abu-abu untuk border
  final Color _textColor = const Color.fromARGB(255, 30, 30, 30); // Hitam untuk teks
  final Color _hintColor = const Color.fromARGB(255, 120, 120, 120); // Abu-abu untuk hint

  // Shadow yang lebih halus
  final BoxShadow _softShadow = BoxShadow(
    color: Colors.black.withValues(alpha:0.15),
    offset: const Offset(0, 2),
    blurRadius: 6,
    spreadRadius: 0,
  );

  final BoxShadow _mediumShadow = BoxShadow(
    color: Colors.black.withValues(alpha:0.2),
    offset: const Offset(0, 4),
    blurRadius: 8,
    spreadRadius: 0,
  );

  final _catatanController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _catatanFocusNode = FocusNode();
  
  List<Industri> _industriList = [];
  List<Industri> _filteredIndustriList = [];
  Industri? _selectedIndustri;
  bool _isLoading = true;
  bool _showIndustriPopup = false;
  bool _isSearching = false;
  int? _jurusanId;
  
  // Tambahkan flag untuk tracking loading state
  bool _hasLoadedData = false;
  bool _isLoadingIndustri = false;
  
  // Keys untuk mendapatkan posisi
  final GlobalKey _industriFieldKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterIndustriList);
    
    // Listen untuk focus catatan
    _catatanFocusNode.addListener(() {
      if (_showIndustriPopup) {
        _removeOverlay();
      }
    });
  }

  void _filterIndustriList() {
    final query = _searchController.text.toLowerCase();
    if (!mounted) return;
    
    setState(() {
      _isSearching = query.isNotEmpty;
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
    // Cek jika sudah pernah load data sebelumnya
    if (_hasLoadedData) {
      return;
    }

    setState(() {
      _isLoading = true;
      _isLoadingIndustri = true;
    });

    try {
      // Cek cache terlebih dahulu
      final cachedData = IndustriCache.getCachedIndustriByJurusan(_jurusanId);
      if (cachedData != null && IndustriCache.isCacheValid()) {
        if (mounted) {
          setState(() {
            _industriList = cachedData;
            _filteredIndustriList = List.from(cachedData);
            _isLoading = false;
            _isLoadingIndustri = false;
            _hasLoadedData = true;
          });
        }
        return;
      }

      // Load jurusanId dari kelasId
      await _loadJurusanId();
      
      // Load data industri dari API
      await _loadIndustriFromAPI();
      
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingIndustri = false;
        });
      }
    }
  }

  Future<void> _loadJurusanId() async {
    try {
      final kelasResponse = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/kelas/${widget.kelasId}'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (kelasResponse.statusCode == 200) {
        final kelasData = jsonDecode(kelasResponse.body);
        setState(() {
          _jurusanId = kelasData['data']['jurusan_id'];
        });
      } else {
        setState(() {
          _jurusanId = null; // Jika gagal, load semua industri
        });
      }
    } catch (e) {
      setState(() {
        _jurusanId = null; // Jika error, load semua industri
      });
    }
  }

  Future<void> _loadIndustriFromAPI() async {
    try {
      final url = _jurusanId != null
          ? '${dotenv.env['API_BASE_URL']}/api/industri?jurusan_id=$_jurusanId&limit=100'
          : '${dotenv.env['API_BASE_URL']}/api/industri?limit=100';

      final response = await http.get(
        Uri.parse(url),
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
      // Jika gagal, coba load semua industri
      await _loadAllIndustriAsFallback();
    }
  }

  Future<void> _loadAllIndustriAsFallback() async {
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
      
      final industriList = industriListData
          .map((item) => Industri.fromJson(item))
          .where((industri) => industri.isActive)
          .toList();
      
      // Cache data
      IndustriCache.cacheIndustriByJurusan(_jurusanId, industriList);
      
      if (mounted) {
        setState(() {
          _industriList = industriList;
          _filteredIndustriList = List.from(industriList);
          _isLoading = false;
          _isLoadingIndustri = false;
          _hasLoadedData = true;
        });
      }
    } else {
      throw Exception('Format data tidak sesuai');
    }
  }

  // Fungsi untuk menghitung posisi popup
  Offset _calculatePopupPosition(BuildContext context, Size fieldSize, Offset fieldOffset) {
    final screenSize = MediaQuery.of(context).size;
    final popupWidth = widget.popupWidth ?? fieldSize.width;
    double left = fieldOffset.dx;
    double top = fieldOffset.dy;

    switch (widget.popupPosition) {
      case PopupPosition.below:
        top = fieldOffset.dy + fieldSize.height + widget.verticalOffset;
        left += widget.horizontalOffset;
        break;
        
      case PopupPosition.above:
        final maxHeight = widget.popupMaxHeight ?? screenSize.height * 0.35;
        top = fieldOffset.dy - maxHeight - widget.verticalOffset;
        left += widget.horizontalOffset;
        break;
        
      case PopupPosition.center:
        left = (screenSize.width - popupWidth) / 2 + widget.horizontalOffset;
        top = (screenSize.height - (widget.popupMaxHeight ?? screenSize.height * 0.35)) / 2 + widget.verticalOffset;
        break;
        
      case PopupPosition.custom:
        if (widget.customPosition != null) {
          left = widget.customPosition!.dx + widget.horizontalOffset;
          top = widget.customPosition!.dy + widget.verticalOffset;
        } else {
          top = fieldOffset.dy + fieldSize.height + widget.verticalOffset;
          left += widget.horizontalOffset;
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
    final maxHeight = widget.popupMaxHeight ?? MediaQuery.of(context).size.height * 0.35;
    
    final popupPosition = _calculatePopupPosition(context, fieldSize, fieldOffset);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return GestureDetector(
          onTap: () {
            // Tutup popup saat klik di luar
            _removeOverlay();
          },
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(color: Colors.black.withValues(alpha:0.3)),
                ),
                Positioned(
                  left: popupPosition.dx,
                  top: popupPosition.dy,
                  width: popupWidth,
                  child: GestureDetector(
                    onTap: () {}, // Mencegah event bubble
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: maxHeight,
                      ),
                      decoration: BoxDecoration(
                        color: _secondaryColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _borderColor, width: 1),
                        boxShadow: [_mediumShadow],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Search Bar
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _primaryColor,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: _secondaryColor,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: _borderColor, width: 1),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.search, color: _hintColor, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextField(
                                            controller: _searchController,
                                            focusNode: _searchFocusNode,
                                            decoration: InputDecoration(
                                              hintText: 'Cari industri...',
                                              hintStyle: TextStyle(
                                                color: _hintColor,
                                                fontWeight: FontWeight.normal,
                                                fontSize: 14,
                                              ),
                                              border: InputBorder.none,
                                              contentPadding: EdgeInsets.zero,
                                              isDense: true,
                                            ),
                                            style: TextStyle(
                                              fontSize: 14, 
                                              color: _textColor,
                                              fontWeight: FontWeight.normal,
                                            ),
                                            cursorColor: _primaryColor,
                                          ),
                                        ),
                                        if (_searchController.text.isNotEmpty)
                                          GestureDetector(
                                            onTap: () => _searchController.clear(),
                                            child: Icon(Icons.clear, size: 18, color: _hintColor),
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
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _secondaryColor,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: _borderColor, width: 1),
                                    ),
                                    child: Icon(Icons.close, size: 20, color: _primaryColor),
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
                ),
              ],
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
    // Gunakan _isLoadingIndustri untuk overlay, bukan _isLoading
    if (_isLoadingIndustri) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                strokeWidth: 3,
                color: _primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Memuat data industri...',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final displayList = _isSearching ? _filteredIndustriList : _industriList;
    
    if (displayList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.business_outlined, 
                size: 48,
                color: _hintColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Tidak ada industri',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Coba kata kunci lain',
                style: TextStyle(
                  color: _hintColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: displayList.length,
      itemBuilder: (context, index) {
        final industri = displayList[index];
        final isSelected = _selectedIndustri?.id == industri.id;
        
        return Material(
          color: isSelected ? _primaryColor.withValues(alpha:0.1) : Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedIndustri = industri;
              });
              _removeOverlay();
            },
            splashColor: _primaryColor.withValues(alpha:0.2),
            highlightColor: _primaryColor.withValues(alpha:0.1),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                border: index == 0
                    ? null
                    : Border(
                        top: BorderSide(color: _borderColor.withValues(alpha:0.3), width: 1),
                      ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _accentColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _borderColor, width: 1),
                    ),
                    child: Icon(
                      Icons.business,
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
                          industri.nama,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: _textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _accentColor,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: _borderColor, width: 1),
                          ),
                          child: Text(
                            industri.bidang,
                            style: TextStyle(
                              fontSize: 11,
                              color: _textColor,
                              fontWeight: FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          industri.alamat,
                          style: TextStyle(
                            fontSize: 12,
                            color: _hintColor,
                            fontWeight: FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      size: 20,
                      color: _primaryColor,
                    ),
                ],
              ),
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
    if (mounted) {
      setState(() {
        _showIndustriPopup = false;
        _isSearching = false;
      });
    }
    _searchController.clear();
    _searchFocusNode.unfocus();
  }

  Widget _buildIndustriField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      key: _industriFieldKey,
      children: [
        Text(
          'Industri',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textColor,
          ),
        ),
        
        const SizedBox(height: 8),
        
        GestureDetector(
          onTap: () {
            if (!_hasLoadedData && !_isLoadingIndustri) {
              // Reload data hanya jika belum pernah load sebelumnya
              _loadData();
            }
            _showIndustriPopupOverlay(context);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _secondaryColor,
              border: Border.all(color: _borderColor, width: 1.5),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [_softShadow],
            ),
            child: Row(
              children: [
                if (_isLoading && !_hasLoadedData)
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(right: 12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _primaryColor,
                    ),
                  )
                else
                  Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: _accentColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _borderColor, width: 1),
                    ),
                    child: Icon(
                      Icons.business_outlined,
                      color: _primaryColor,
                      size: 18,
                    ),
                  ),
                Expanded(
                  child: _selectedIndustri == null
                      ? Text(
                          _isLoading && !_hasLoadedData 
                            ? 'Memuat data industri...' 
                            : 'Pilih industri',
                          style: TextStyle(
                            color: _hintColor,
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedIndustri!.nama,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedIndustri!.bidang,
                              style: TextStyle(
                                fontSize: 13,
                                color: _hintColor,
                                fontWeight: FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                ),
                Icon(
                  _showIndustriPopup ? Icons.expand_less : Icons.expand_more,
                  color: _primaryColor,
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: 500,
        ),
        decoration: BoxDecoration(
          color: _secondaryColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [_mediumShadow],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pengajuan PKL',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _secondaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pilih industri dan tulis catatan',
                        style: TextStyle(
                          fontSize: 14,
                          color: _secondaryColor.withValues(alpha:0.9),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      _removeOverlay();
                      Navigator.of(context).pop();
                    },
                    icon: Icon(
                      Icons.close,
                      color: _secondaryColor,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIndustriField(context),
                    
                    const SizedBox(height: 24),
                    
                    // Catatan Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Catatan',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _textColor,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _borderColor, width: 1.5),
                            color: _secondaryColor,
                            boxShadow: [_softShadow],
                          ),
                          child: TextFormField(
                            controller: _catatanController,
                            focusNode: _catatanFocusNode,
                            decoration: InputDecoration(
                              hintText: 'Tulis catatan pengajuan PKL...',
                              hintStyle: TextStyle(
                                color: _hintColor,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              isDense: true,
                            ),
                            style: TextStyle(
                              fontSize: 14, 
                              color: _textColor,
                              fontWeight: FontWeight.normal,
                            ),
                            maxLines: 4,
                            minLines: 3,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Tombol aksi
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _removeOverlay();
                              Navigator.of(context).pop();
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: _borderColor, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              backgroundColor: _secondaryColor,
                            ),
                            child: Text(
                              'Batal',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _textColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // Validasi harus memilih industri dan catatan harus diisi
                              if (_selectedIndustri == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Silakan pilih industri terlebih dahulu',
                                      style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                    backgroundColor: _primaryColor,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                );
                                return;
                              }
                              
                              if (_catatanController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Catatan harus diisi',
                                      style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                    backgroundColor: _primaryColor,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
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
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: _primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                              shadowColor: Colors.transparent,
                            ),
                            child: Text(
                              'Ajukan PKL',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _secondaryColor,
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
          ],
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
    _catatanFocusNode.dispose();
    super.dispose();
  }
}