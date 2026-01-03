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
    this.verticalOffset = 0.0,
  });

  @override
  State<AjukanPKLDialog> createState() => _AjukanPKLDialogState();
}

class _AjukanPKLDialogState extends State<AjukanPKLDialog> {
  // Neo Brutalism Colors
  final Color _primaryColor = const Color(0xFFE63946); // Merah cerah
  final Color _secondaryColor = const Color(0xFFF1FAEE); // Putih krem
  final Color _accentColor = const Color(0xFFA8DADC); // Biru muda
  final Color _darkColor = const Color(0xFF1D3557); // Biru tua
  final Color _yellowColor = const Color(0xFFFFB703); // Kuning cerah
  final Color _blackColor = Colors.black;

  // Neo Brutalism Shadows
  static const BoxShadow _heavyShadow = BoxShadow(
    color: Colors.black,
    offset: Offset(6, 6),
    blurRadius: 0,
  );

  final BoxShadow _lightShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.2),
    offset: const Offset(4, 4),
    blurRadius: 0,
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
                  child: Container(color: Colors.transparent),
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
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _blackColor, width: 3),
                        boxShadow: const [_heavyShadow],
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
                              border: Border(
                                bottom: BorderSide(color: _blackColor, width: 3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: _secondaryColor,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: _blackColor, width: 2),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.search, color: _darkColor, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextField(
                                            controller: _searchController,
                                            focusNode: _searchFocusNode,
                                            decoration: InputDecoration(
                                              hintText: 'CARI INDUSTRI...',
                                              hintStyle: TextStyle(
                                                color: _darkColor.withValues(alpha: 0.7),
                                                fontWeight: FontWeight.w800,
                                                fontSize: 12,
                                                letterSpacing: -0.3,
                                              ),
                                              border: InputBorder.none,
                                              contentPadding: EdgeInsets.zero,
                                              isDense: true,
                                            ),
                                            style: TextStyle(
                                              fontSize: 14, 
                                              color: _blackColor,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: -0.3,
                                            ),
                                            cursorColor: _primaryColor,
                                          ),
                                        ),
                                        if (_searchController.text.isNotEmpty)
                                          GestureDetector(
                                            onTap: () => _searchController.clear(),
                                            child: Icon(Icons.clear, size: 18, color: _darkColor),
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
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: _blackColor, width: 2),
                                    ),
                                    child: Icon(Icons.close, size: 20, color: _darkColor),
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _yellowColor,
                  border: Border.all(color: _blackColor, width: 3),
                  shape: BoxShape.circle,
                ),
                child: const CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _primaryColor,
                  border: Border.all(color: _blackColor, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'MEMUAT INDUSTRI...',
                  style: TextStyle(
                    color: _secondaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
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
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _accentColor,
                  border: Border.all(color: _blackColor, width: 3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.business_outlined, 
                  size: 32,
                  color: _darkColor,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _primaryColor,
                  border: Border.all(color: _blackColor, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'TIDAK ADA INDUSTRI',
                  style: TextStyle(
                    color: _secondaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Coba kata kunci lain',
                style: TextStyle(
                  color: _darkColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
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
          color: isSelected ? _primaryColor.withValues(alpha: 0.2) : Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedIndustri = industri;
              });
              _removeOverlay();
            },
            splashColor: _primaryColor.withValues(alpha: 0.3),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                border: index == 0
                    ? null
                    : Border(
                        top: BorderSide(color: _blackColor, width: 2),
                      ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _accentColor,
                      border: Border.all(color: _blackColor, width: 3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.business,
                      color: _darkColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          industri.nama.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: _blackColor,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _yellowColor,
                            border: Border.all(color: _blackColor, width: 1.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            industri.bidang,
                            style: TextStyle(
                              fontSize: 10,
                              color: _blackColor,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          industri.alamat,
                          style: TextStyle(
                            fontSize: 11,
                            color: _darkColor,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        border: Border.all(color: _blackColor, width: 2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        size: 16,
                        color: _secondaryColor,
                      ),
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _yellowColor,
            border: Border.all(color: _blackColor, width: 2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'INDUSTRI',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: _blackColor,
              letterSpacing: -0.2,
            ),
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
              border: Border.all(color: _blackColor, width: 3),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [_lightShadow],
            ),
            child: Row(
              children: [
                if (_isLoading && !_hasLoadedData)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      border: Border.all(color: _blackColor, width: 2),
                      shape: BoxShape.circle,
                    ),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _accentColor,
                      border: Border.all(color: _blackColor, width: 3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.business_outlined,
                      color: _darkColor,
                      size: 18,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: _selectedIndustri == null
                      ? Text(
                          _isLoading && !_hasLoadedData 
                            ? 'MEMUAT DATA INDUSTRI...' 
                            : 'PILIH INDUSTRI',
                          style: TextStyle(
                            color: _darkColor.withValues(alpha: 0.7),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedIndustri!.nama.toUpperCase(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: _blackColor,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _yellowColor,
                                border: Border.all(color: _blackColor, width: 1.5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _selectedIndustri!.bidang,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _blackColor,
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _secondaryColor,
                    border: Border.all(color: _blackColor, width: 3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _showIndustriPopup ? Icons.expand_less : Icons.expand_more,
                    color: _darkColor,
                  ),
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
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.65,
          maxWidth: 500,
        ),
        decoration: BoxDecoration(
          color: _secondaryColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _blackColor, width: 4),
          boxShadow: const [_heavyShadow],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header dengan warna tema
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: Border(
                  bottom: BorderSide(color: _blackColor, width: 4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AJUKAN PKL',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: _secondaryColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _yellowColor,
                          border: Border.all(color: _blackColor, width: 2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'PILIH INDUSTRI & CATATAN',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: _blackColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      _removeOverlay();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _secondaryColor,
                        border: Border.all(color: _blackColor, width: 3),
                        shape: BoxShape.circle,
                        boxShadow: [_lightShadow],
                      ),
                      child: Icon(
                        Icons.close,
                        size: 22,
                        color: _primaryColor,
                      ),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _primaryColor,
                            border: Border.all(color: _blackColor, width: 2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: _secondaryColor,
                                  border: Border.all(color: _blackColor, width: 2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.edit,
                                  size: 10,
                                  color: _primaryColor,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'CATATAN',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: _secondaryColor,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _blackColor, width: 3),
                            color: Colors.white,
                            boxShadow: [_lightShadow],
                          ),
                          child: TextFormField(
                            controller: _catatanController,
                            focusNode: _catatanFocusNode,
                            decoration: InputDecoration(
                              hintText: 'TULIS CATATAN PENGAJUAN PKL...',
                              hintStyle: TextStyle(
                                color: _darkColor.withValues(alpha: 0.6),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              isDense: true,
                            ),
                            style: TextStyle(
                              fontSize: 14, 
                              color: _blackColor,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 3,
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
                          child: GestureDetector(
                            onTap: () {
                              _removeOverlay();
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: _accentColor,
                                border: Border.all(color: _blackColor, width: 3),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [_lightShadow],
                              ),
                              child: Center(
                                child: Text(
                                  'BATAL',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: _blackColor,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              // Validasi harus memilih industri dan catatan harus diisi
                              if (_selectedIndustri == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'SILAKAN PILIH INDUSTRI TERLEBIH DAHULU',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    backgroundColor: _primaryColor,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(color: _blackColor, width: 2),
                                    ),
                                  ),
                                );
                                return;
                              }
                              
                              if (_catatanController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'CATATAN HARUS DIISI',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    backgroundColor: _primaryColor,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(color: _blackColor, width: 2),
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
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: _primaryColor,
                                border: Border.all(color: _blackColor, width: 3),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [_heavyShadow],
                              ),
                              child: Center(
                                child: Text(
                                  'AJUKAN PKL',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: _secondaryColor,
                                    letterSpacing: -0.3,
                                  ),
                                ),
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