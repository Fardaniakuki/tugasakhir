import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Model untuk Industri
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

// Model untuk Teman PKL
class TemanPKL {
  final int id;
  final String nama;
  final String nisn;

  final String? username; // Tambahkan username jika ada di response
  bool isSelected;

  TemanPKL({
    required this.id,
    required this.nama,
    required this.nisn,
    this.username,
    this.isSelected = false,
  });

  factory TemanPKL.fromJson(Map<String, dynamic> json) {
    return TemanPKL(
      id: json['id'],
      nama: json['nama'],
      nisn: json['nisn'],
      username: json['username'], // Sesuaikan dengan response API
      isSelected: false,
    );
  }
}

// Cache untuk menyimpan data industri
class IndustriCache {
  static final Map<int, List<Industri>> _cacheByJurusan = {};
  static List<Industri>? _allIndustriCache;
  static DateTime? _lastFetchTime;

  static bool isCacheValid() {
    if (_lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!).inMinutes < 5;
  }

  static List<Industri>? getCachedIndustriByJurusan(int? jurusanId) {
    if (jurusanId == null) return _allIndustriCache;
    return _cacheByJurusan[jurusanId];
  }

  static void cacheIndustriByJurusan(
      int? jurusanId, List<Industri> industriList) {
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

// Enum untuk tipe pengajuan
enum TipePengajuan {
  individu,
  group,
}

// Enum untuk posisi popup
enum PopupPosition {
  below,
  above,
  center,
  custom,
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
    required this.token,
    required this.kelasId,
    this.popupPosition = PopupPosition.below,
    this.customPosition,
    this.popupWidth,
    this.popupMaxHeight,
    this.horizontalOffset = 40.0,
    this.verticalOffset = 0.0,
    required Color primaryColor,
  });

  @override
  State<AjukanPKLDialog> createState() => _AjukanPKLDialogState();
}

class _AjukanPKLDialogState extends State<AjukanPKLDialog> {
  // Warna
  final Color _primaryColor = const Color.fromARGB(255, 177, 22, 11);
  final Color _secondaryColor = Colors.white;
  final Color _accentColor = const Color.fromARGB(255, 240, 240, 240);
  final Color _borderColor = const Color.fromARGB(255, 150, 150, 150);
  final Color _textColor = const Color.fromARGB(255, 30, 30, 30);
  final Color _hintColor = const Color.fromARGB(255, 120, 120, 120);
  final Color _successColor = const Color.fromARGB(255, 34, 139, 34);

  // Shadow
  final BoxShadow _softShadow = BoxShadow(
    color: Colors.black.withAlpha(38),
    offset: const Offset(0, 2),
    blurRadius: 6,
    spreadRadius: 0,
  );

  final BoxShadow _mediumShadow = BoxShadow(
    color: Colors.black.withAlpha(51),
    offset: const Offset(0, 4),
    blurRadius: 8,
    spreadRadius: 0,
  );

  final _catatanController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _searchTemanController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _catatanFocusNode = FocusNode();
  final ScrollController _temanScrollController = ScrollController();

  List<Industri> _industriList = [];
  List<Industri> _filteredIndustriList = [];
  List<TemanPKL> _temanList = [];
  List<TemanPKL> _filteredTemanList = [];
  List<TemanPKL> _selectedTemanList = [];
  Industri? _selectedIndustri;
  bool _isLoading = true;
  bool _showIndustriPopup = false;
  bool _isSearching = false;
  bool _isSearchingTeman = false;
  int? _jurusanId;

  bool _hasLoadedData = false;
  bool _isLoadingIndustri = false;
  bool _isLoadingTeman = false;
  bool _showTemanSection = false;

  TipePengajuan _tipePengajuan = TipePengajuan.individu;

  final GlobalKey _industriFieldKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterIndustriList);
    _searchTemanController.addListener(_filterTemanList);

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
            industri.alamat.toLowerCase().contains(query);
      }).toList();
    });

    if (_overlayEntry != null && _overlayEntry!.mounted) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _filterTemanList() {
    final query = _searchTemanController.text.toLowerCase();
    if (!mounted) return;

    setState(() {
      _isSearchingTeman = query.isNotEmpty;
      _filteredTemanList = _temanList.where((teman) {
        return teman.nama.toLowerCase().contains(query) ||
            teman.nisn.toLowerCase().contains(query);
      }).toList();
    });
  }
  // Di file tempat memanggil AjukanPKLDialog, tambahkan pengecekan:

  Future<bool> _checkExistingPengajuan() async {
    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/pkl/applications/status'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Cek apakah ada pengajuan aktif
        if (data['has_active_application'] == true) {
          _showExistingPengajuanWarning(data['applications']);
          return false;
        }
        return true;
      }
      return true;
    } catch (e) {
      print('Error checking existing pengajuan: $e');
      return true;
    }
  }

  void _showExistingPengajuanWarning(List applications) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pengajuan Belum Selesai'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Anda masih memiliki pengajuan PKL yang belum selesai:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ...applications.map((app) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status: ${app['status']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (app['industri'] != null)
                        Text('Industri: ${app['industri']['nama']}'),
                      Text('Tanggal: ${app['created_at']}'),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            const Text(
              'Selesaikan pengajuan yang ada sebelum mengajukan yang baru.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Optional: Navigasi ke halaman detail pengajuan
              // _navigateToApplicationDetail();
            },
            child: const Text('Lihat Detail'),
          ),
        ],
      ),
    );
  }

// Panggil fungsi ini sebelum membuka dialog

  Future<void> _loadData() async {
    if (_hasLoadedData) return;

    setState(() {
      _isLoading = true;
      _isLoadingIndustri = true;
    });

    try {
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

      await _loadJurusanId();
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
          _jurusanId = null;
        });
      }
    } catch (e) {
      setState(() {
        _jurusanId = null;
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

  Future<void> _loadTemanSekelas() async {
    if (_temanList.isNotEmpty) return;

    setState(() {
      _isLoadingTeman = true;
    });

    try {
      final url =
          '${dotenv.env['API_BASE_URL']}/api/pkl/group/available-members';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        final temanList = data.map((item) => TemanPKL.fromJson(item)).toList();

        if (mounted) {
          setState(() {
            _temanList = temanList;
            _filteredTemanList = List.from(temanList);
            _isLoadingTeman = false;
          });

          if (temanList.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    const Text('Tidak ada teman yang tersedia untuk diundang'),
                backgroundColor: _primaryColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }
        }
      } else {
        throw Exception('Gagal memuat data teman (${response.statusCode})');
      }
    } catch (e) {
      print('Error loading teman: $e');
      if (mounted) {
        setState(() {
          _isLoadingTeman = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat daftar teman: ${e.toString()}'),
            backgroundColor: _primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

// Perbaiki fungsi _toggleTemanSelection
  void _toggleTemanSelection(TemanPKL teman) {
    if (!mounted) return;

    setState(() {
      // Update di _temanList
      final indexTeman = _temanList.indexWhere((t) => t.id == teman.id);
      if (indexTeman != -1) {
        _temanList[indexTeman].isSelected = !_temanList[indexTeman].isSelected;
      }

      // Update di _filteredTemanList
      final indexFiltered =
          _filteredTemanList.indexWhere((t) => t.id == teman.id);
      if (indexFiltered != -1) {
        _filteredTemanList[indexFiltered].isSelected =
            _temanList.firstWhere((t) => t.id == teman.id).isSelected;
      }

      // Update selected list
      _selectedTemanList = _temanList.where((t) => t.isSelected).toList();

      // Jika memilih teman, otomatis ganti tipe ke group
      if (_selectedTemanList.isNotEmpty) {
        _tipePengajuan = TipePengajuan.group;
      }
    });
  }

// Perbaiki widget _buildTemanList
  Widget _buildTemanList() {
    if (_isLoadingTeman) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(strokeWidth: 3, color: _primaryColor),
              const SizedBox(height: 16),
              Text('Memuat data teman...', style: TextStyle(color: _textColor)),
            ],
          ),
        ),
      );
    }

    final displayList = _isSearchingTeman ? _filteredTemanList : _temanList;

    if (displayList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.group_outlined, size: 48, color: _hintColor),
              const SizedBox(height: 16),
              Text('Tidak ada teman tersedia',
                  style: TextStyle(
                      color: _textColor, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                _isSearchingTeman
                    ? 'Coba kata kunci lain'
                    : 'Semua teman sudah dalam group',
                style: TextStyle(color: _hintColor, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _accentColor,
            border: Border(bottom: BorderSide(color: _borderColor, width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Daftar Teman Tersedia',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _textColor)),
              Text('${displayList.length} orang',
                  style: TextStyle(fontSize: 12, color: _hintColor)),
            ],
          ),
        ),
        Expanded(
          child: Scrollbar(
            controller: _temanScrollController,
            child: ListView.builder(
              controller: _temanScrollController,
              padding: const EdgeInsets.all(8),
              itemCount: displayList.length,
              itemBuilder: (context, index) {
                final teman = displayList[index];

                return GestureDetector(
                  onTap: () => _toggleTemanSelection(teman),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: teman.isSelected
                          ? _primaryColor.withAlpha(25)
                          : _secondaryColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: teman.isSelected
                            ? _primaryColor
                            : _borderColor.withAlpha(127),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: teman.isSelected
                                  ? _primaryColor.withAlpha(51)
                                  : _accentColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: teman.isSelected
                                      ? _primaryColor
                                      : _borderColor,
                                  width: 1),
                            ),
                            child: Icon(
                              teman.isSelected
                                  ? Icons.person
                                  : Icons.person_outline,
                              size: 20,
                              color:
                                  teman.isSelected ? _primaryColor : _textColor,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Info teman
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  teman.nama,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: _textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _accentColor,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: _borderColor.withAlpha(127),
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Text(
                                        'NISN: ${teman.nisn}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: _hintColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Checkbox
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: teman.isSelected
                                  ? _primaryColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: teman.isSelected
                                    ? _primaryColor
                                    : _borderColor,
                                width: 2,
                              ),
                            ),
                            child: teman.isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 18,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

// Perbaiki juga bagian pemilihan industri (opsional, untuk konsistensi)
  Widget _buildIndustriList() {
    if (_isLoadingIndustri) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(strokeWidth: 3, color: _primaryColor),
              const SizedBox(height: 16),
              Text('Memuat data industri...',
                  style: TextStyle(color: _textColor)),
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
              Icon(Icons.business_outlined, size: 48, color: _hintColor),
              const SizedBox(height: 16),
              Text('Tidak ada industri',
                  style: TextStyle(
                      color: _textColor, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Coba kata kunci lain', style: TextStyle(color: _hintColor)),
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

        return GestureDetector(
          onTap: () {
            setState(() => _selectedIndustri = industri);
            _removeOverlay();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color:
                  isSelected ? _primaryColor.withAlpha(25) : Colors.transparent,
              border: index == 0
                  ? null
                  : Border(
                      top: BorderSide(
                          color: _borderColor.withAlpha(76), width: 1)),
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
                  child: Icon(Icons.business, color: _primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(industri.nama,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: _textColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _accentColor,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _borderColor, width: 1),
                        ),
                        child: Text(industri.bidang,
                            style: TextStyle(fontSize: 11, color: _textColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(height: 4),
                      Text(industri.alamat,
                          style: TextStyle(fontSize: 12, color: _hintColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, size: 20, color: _primaryColor),
              ],
            ),
          ),
        );
      },
    );
  }

  void _toggleTemanSection() async {
    if (!_showTemanSection) {
      await _loadTemanSekelas();
    }

    setState(() {
      _showTemanSection = !_showTemanSection;
    });
  }
// Di dalam class _AjukanPKLDialogState
bool _isSubmitting = false;

Future<void> _submitPengajuan() async {
  // Cegah double submission
  if (_isSubmitting) {
    print('⚠️ Already submitting, ignoring double click...');
    return;
  }
  
  // Validasi untuk individu
  if (_tipePengajuan == TipePengajuan.individu) {
    if (_selectedIndustri == null) {
      _showSnackBar('Silakan pilih industri terlebih dahulu');
      return;
    }

    if (_catatanController.text.isEmpty) {
      _showSnackBar('Catatan harus diisi');
      return;
    }
  }

  // Validasi untuk group
  if (_tipePengajuan == TipePengajuan.group && _selectedTemanList.isEmpty) {
    _showSnackBar('Pilih minimal 1 teman untuk pengajuan group');
    return;
  }

  _isSubmitting = true;
  print('=== SUBMIT PENGAJUAN ===');
  print('Tipe: $_tipePengajuan');
  print('Selected teman: ${_selectedTemanList.length}');

  // Tampilkan loading dialog
  if (!mounted) return;

  BuildContext? dialogContext;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      dialogContext = context;
      return Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _secondaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: _primaryColor),
              const SizedBox(height: 16),
              Text(
                _tipePengajuan == TipePengajuan.group
                    ? 'Membuat group PKL...'
                    : 'Mengajukan PKL...',
                style: TextStyle(color: _textColor),
              ),
            ],
          ),
        ),
      );
    },
  );

  try {
    late http.Response response;

    if (_tipePengajuan == TipePengajuan.group) {
      final invitedMembers = _selectedTemanList
          .map((t) => t.username ?? t.nama)
          .toList();

      final Map<String, dynamic> requestBody = {
        'invited_members': invitedMembers,
      };

      print('Request body group: $requestBody');
      print('URL: ${dotenv.env['API_BASE_URL']}/api/pkl/group');

      response = await http.post(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/pkl/group'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10));
    } else {
      final Map<String, dynamic> requestBody = {
        'catatan': _catatanController.text,
        'industri_id': _selectedIndustri!.id,
      };

      print('Request body individu: $requestBody');
      print('URL: ${dotenv.env['API_BASE_URL']}/api/pkl/applications');

      response = await http.post(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/pkl/applications'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10));
    }

    print('Response status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    // Tutup loading dialog
    if (mounted && dialogContext != null && Navigator.canPop(dialogContext!)) {
      Navigator.of(dialogContext!).pop();
    }

    // Handle response
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Sukses 2xx
      print('✅ Request berhasil');
      
      _removeOverlay();

      if (mounted) {
        Navigator.of(context).pop({
          'success': true,
          'data': jsonDecode(response.body),
          'tipe': _tipePengajuan == TipePengajuan.group ? 'group' : 'individu',
          'invited_members': _tipePengajuan == TipePengajuan.group 
              ? _selectedTemanList.map((t) => t.username ?? t.nama).toList() 
              : [],
          'industri_id': _tipePengajuan == TipePengajuan.individu 
              ? _selectedIndustri?.id 
              : null,
          'catatan': _tipePengajuan == TipePengajuan.individu 
              ? _catatanController.text 
              : '',
        });
      }
    } 
    else if (response.statusCode == 409) {
      // Conflict - handle sesuai tipe
      print('⚠️ 409 Conflict');
      
      _removeOverlay();
      
      // Parse error message
      String errorMessage = 'Terjadi konflik';
      try {
        final errorData = jsonDecode(response.body);
        errorMessage = errorData['message'] ?? errorMessage;
        print('Error message: $errorMessage');
      } catch (e) {}
      
      if (mounted) {
        // Untuk 409, kita tetap return dengan status sukses tapi beri pesan berbeda
        Navigator.of(context).pop({
          'success': true, // Anggap sukses karena group sudah ada
          'conflict': true,
          'message': errorMessage,
          'tipe': _tipePengajuan == TipePengajuan.group ? 'group' : 'individu',
        });
      }
    }
    else {
      // Error lainnya
      print('❌ Request gagal');
      
      _removeOverlay();
      
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Gagal mengajukan PKL');
    }
  } catch (e) {
    // Tutup loading dialog jika error
    if (mounted && dialogContext != null && Navigator.canPop(dialogContext!)) {
      Navigator.of(dialogContext!).pop();
    }

    print('❌ Error submitting PKL: $e');
    print('Stack trace:');
    print(StackTrace.current);

    if (mounted) {
      _showSnackBar('Gagal mengajukan PKL: ${e.toString()}');
    }
  } finally {
    _isSubmitting = false;
    print('=== SELESAI SUBMIT PENGAJUAN ===');
  }
}
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Fungsi untuk menghitung posisi popup
  Offset _calculatePopupPosition(
      BuildContext context, Size fieldSize, Offset fieldOffset) {
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
        top = (screenSize.height -
                    (widget.popupMaxHeight ?? screenSize.height * 0.35)) /
                2 +
            widget.verticalOffset;
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

    final RenderBox renderBox =
        _industriFieldKey.currentContext!.findRenderObject() as RenderBox;
    final fieldOffset = renderBox.localToGlobal(Offset.zero);
    final fieldSize = renderBox.size;
    final popupWidth = widget.popupWidth ?? fieldSize.width;
    final maxHeight =
        widget.popupMaxHeight ?? MediaQuery.of(context).size.height * 0.35;

    final popupPosition =
        _calculatePopupPosition(context, fieldSize, fieldOffset);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return GestureDetector(
          onTap: _removeOverlay,
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(color: Colors.black.withAlpha(76)),
                ),
                Positioned(
                  left: popupPosition.dx,
                  top: popupPosition.dy,
                  width: popupWidth,
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      constraints: BoxConstraints(maxHeight: maxHeight),
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
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: _secondaryColor,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: _borderColor, width: 1),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.search,
                                            color: _hintColor, size: 20),
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
                                            onTap: () =>
                                                _searchController.clear(),
                                            child: Icon(Icons.clear,
                                                size: 18, color: _hintColor),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: _removeOverlay,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _secondaryColor,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: _borderColor, width: 1),
                                    ),
                                    child: Icon(Icons.close,
                                        size: 20, color: _primaryColor),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // List Industri
                          Expanded(child: _buildIndustriList()),
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

  // Widget pilihan tipe pengajuan
  Widget _buildTipePengajuanSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _accentColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tipe Pengajuan',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTipeOption(
                  tipe: TipePengajuan.individu,
                  icon: Icons.person,
                  label: 'Individu',
                  description: 'Ajukan sendiri',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTipeOption(
                  tipe: TipePengajuan.group,
                  icon: Icons.group,
                  label: 'Kelompok',
                  description: 'Buat group PKL',
                ),
              ),
            ],
          ),
          if (_tipePengajuan == TipePengajuan.group &&
              _selectedTemanList.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: _primaryColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Pilih teman di bawah untuk membuat group',
                      style: TextStyle(fontSize: 11, color: _primaryColor),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTipeOption({
    required TipePengajuan tipe,
    required IconData icon,
    required String label,
    required String description,
  }) {
    final isSelected = _tipePengajuan == tipe;

    return GestureDetector(
      onTap: () {
        setState(() {
          _tipePengajuan = tipe;
          // Jika pilih individu, reset pilihan teman
          if (tipe == TipePengajuan.individu) {
            for (var teman in _temanList) {
              teman.isSelected = false;
            }
            _selectedTemanList.clear();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor.withAlpha(25) : _secondaryColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? _primaryColor : _borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? _primaryColor : _textColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? _primaryColor : _textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: TextStyle(
                fontSize: 10,
                color: _hintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemanSection() {
    // Sembunyikan section teman jika pilih individu
    if (_tipePengajuan == TipePengajuan.individu) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ajukan Bersama Teman',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textColor)),
            const SizedBox(height: 4),
            Text('Pilih teman yang tersedia untuk diundang',
                style: TextStyle(fontSize: 12, color: _hintColor)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _toggleTemanSection,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _showTemanSection ? _accentColor : _primaryColor,
                  foregroundColor:
                      _showTemanSection ? _textColor : _secondaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: _borderColor, width: 1),
                  ),
                  elevation: 0,
                ),
                icon: Icon(
                    _showTemanSection ? Icons.expand_less : Icons.expand_more,
                    size: 20),
                label: Text(
                    _showTemanSection ? 'Tutup Daftar Teman' : 'Pilih Teman',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
        if (_showTemanSection) ...[
          const SizedBox(height: 16),
          if (_selectedTemanList.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: _accentColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _successColor, width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _successColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _successColor, width: 1),
                    ),
                    child: Icon(Icons.group, color: _successColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${_selectedTemanList.length} Teman Terpilih',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _textColor)),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  for (var teman in _temanList) {
                                    teman.isSelected = false;
                                  }
                                  _filteredTemanList = List.from(_temanList);
                                  _selectedTemanList.clear();
                                });
                              },
                              style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap),
                              child: Text('Hapus semua',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: _primaryColor,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _selectedTemanList.map((teman) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _primaryColor.withAlpha(25),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: _primaryColor.withAlpha(76),
                                    width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(teman.nama,
                                      style: TextStyle(
                                          fontSize: 12, color: _textColor)),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () => _toggleTemanSelection(teman),
                                    child: Icon(Icons.close,
                                        size: 14, color: _primaryColor),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _accentColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _borderColor, width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: _hintColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchTemanController,
                    decoration: InputDecoration(
                      hintText: 'Cari teman berdasarkan nama atau NISN...',
                      hintStyle: TextStyle(color: _hintColor, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    style: TextStyle(fontSize: 14, color: _textColor),
                    cursorColor: _primaryColor,
                  ),
                ),
                if (_searchTemanController.text.isNotEmpty)
                  GestureDetector(
                    onTap: () => _searchTemanController.clear(),
                    child: Icon(Icons.clear, size: 18, color: _hintColor),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(maxHeight: 250),
            decoration: BoxDecoration(
              color: _secondaryColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _borderColor, width: 1),
              boxShadow: [_softShadow],
            ),
            child: _buildTemanList(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _accentColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _borderColor, width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: _primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Total: ${_temanList.length} teman tersedia',
                    style: TextStyle(fontSize: 12, color: _hintColor),
                  ),
                ),
                if (_selectedTemanList.isNotEmpty)
                  Text(
                    'Terpilih: ${_selectedTemanList.length}',
                    style: TextStyle(
                        fontSize: 12,
                        color: _successColor,
                        fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
        ],
      ],
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
        Text('Industri',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: _textColor)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            if (!_hasLoadedData && !_isLoadingIndustri) _loadData();
            _showIndustriPopupOverlay(context);
          },
          child: Container(
            width: double.infinity,
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
                          strokeWidth: 2, color: _primaryColor))
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
                    child: Icon(Icons.business_outlined,
                        color: _primaryColor, size: 18),
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
                              fontWeight: FontWeight.normal),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_selectedIndustri!.nama,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _textColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(_selectedIndustri!.bidang,
                                style:
                                    TextStyle(fontSize: 13, color: _hintColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                ),
                Icon(_showIndustriPopup ? Icons.expand_less : Icons.expand_more,
                    color: _primaryColor, size: 24),
              ],
            ),
          ),
        ),
        if (_selectedIndustri != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _accentColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _successColor, width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _successColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _successColor, width: 1),
                  ),
                  child:
                      Icon(Icons.check_circle, color: _successColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Industri Dipilih',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _textColor)),
                      const SizedBox(height: 4),
                      Text(_selectedIndustri!.nama,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _textColor)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _primaryColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: _primaryColor.withAlpha(76)),
                            ),
                            child: Text(_selectedIndustri!.bidang,
                                style:
                                    TextStyle(fontSize: 11, color: _textColor)),
                          ),
                          if (_selectedIndustri!.alamat.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _accentColor,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: _borderColor),
                              ),
                              child: Text(_selectedIndustri!.alamat,
                                  style: TextStyle(
                                      fontSize: 11, color: _hintColor)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _selectedIndustri = null),
                  icon: Icon(Icons.close, color: _primaryColor, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pengajuan PKL',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: _secondaryColor)),
                        const SizedBox(height: 4),
                        Text(
                          _selectedTemanList.isNotEmpty
                              ? 'Mengundang ${_selectedTemanList.length} teman'
                              : 'Pilih industri dan tipe pengajuan',
                          style: TextStyle(
                              fontSize: 14,
                              color: _secondaryColor.withAlpha(230)),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      _removeOverlay();
                      Navigator.of(context).pop();
                    },
                    icon: Icon(Icons.close, color: _secondaryColor, size: 24),
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
                    // Pilihan tipe pengajuan
                    _buildTipePengajuanSelector(),

                    // 🔥 PERBAIKAN: Hanya tampilkan field industri dan catatan jika pilih individu
                    if (_tipePengajuan == TipePengajuan.individu) ...[
                      _buildIndustriField(context),

                      const SizedBox(height: 24),
                      Divider(color: _borderColor.withAlpha(127), height: 1),
                      const SizedBox(height: 24),

                      // Catatan Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Catatan Pengajuan',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _textColor)),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: _borderColor, width: 1.5),
                              color: _secondaryColor,
                              boxShadow: [_softShadow],
                            ),
                            child: TextFormField(
                              controller: _catatanController,
                              focusNode: _catatanFocusNode,
                              decoration: InputDecoration(
                                hintText:
                                    'Tulis alasan/catatan pengajuan PKL...',
                                hintStyle:
                                    TextStyle(color: _hintColor, fontSize: 14),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                isDense: true,
                              ),
                              style: TextStyle(fontSize: 14, color: _textColor),
                              maxLines: 4,
                              minLines: 3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Catatan akan dilihat oleh pembimbing dan admin',
                              style:
                                  TextStyle(fontSize: 11, color: _hintColor)),
                        ],
                      ),
                    ],

                    // Teman section (hanya muncul jika pilih group)
                    _buildTemanSection(),

                    const SizedBox(height: 32),

                    // Summary (hanya untuk individu)
                    if (_tipePengajuan == TipePengajuan.individu &&
                        _selectedIndustri != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: _accentColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _borderColor, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ringkasan Pengajuan',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _textColor)),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 20,
                                  color: _primaryColor,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pengajuan Individu',
                                        style: TextStyle(
                                            fontSize: 12, color: _hintColor),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '1 orang',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: _textColor),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_selectedIndustri != null)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('Industri',
                                          style: TextStyle(
                                              fontSize: 12, color: _hintColor)),
                                      const SizedBox(height: 4),
                                      SizedBox(
                                        width: 150,
                                        child: Text(
                                          _selectedIndustri!.nama,
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: _textColor),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

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
                                  borderRadius: BorderRadius.circular(8)),
                              backgroundColor: _secondaryColor,
                            ),
                            child: Text('Batal',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _textColor)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _submitPengajuan,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: _primaryColor,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                              shadowColor: Colors.transparent,
                            ),
                            child: Text(
                              _tipePengajuan == TipePengajuan.group
                                  ? 'Buat Group'
                                  : 'Ajukan PKL',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _secondaryColor),
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
    _searchTemanController.dispose();
    _searchFocusNode.dispose();
    _catatanFocusNode.dispose();
    _temanScrollController.dispose();
    super.dispose();
  }
}
