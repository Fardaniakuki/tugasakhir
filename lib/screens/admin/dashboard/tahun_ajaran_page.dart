// tahun_ajaran_page.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ==================== TAHUN AJARAN SERVICE ====================
class TahunAjaranService {
  String? _token;
  
  String get _baseUrl => dotenv.get('API_BASE_URL');

  Future<String?> _getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    return _token;
  }

  bool _validateResponse(http.Response response) {
    if (response.statusCode == 401) {
      _token = null;
      return false;
    }
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  // Ambil semua tahun ajaran
  Future<List<Map<String, dynamic>>> fetchTahunAjaran({
    String? search,
    bool? isActive,
    int page = 1,
    int limit = 10,
  }) async {
    final token = await _getToken();
    if (token == null) return [];

    final url = Uri.parse('$_baseUrl/api/tahun-ajaran').replace(
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (isActive != null) 'is_active': isActive.toString(),
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (!_validateResponse(response)) {
        throw Exception('Gagal mengambil tahun ajaran: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      if (data['data'] is List) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching tahun ajaran: $e');
      rethrow;
    }
  }

  // Buat tahun ajaran baru
  Future<Map<String, dynamic>?> createTahunAjaran({
    required String kode,
    required String nama,
    bool isActive = false,
  }) async {
    final token = await _getToken();
    if (token == null) return null;

    final url = Uri.parse('$_baseUrl/api/tahun-ajaran');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'kode': kode,
          'nama': nama,
          'is_active': isActive,
        }),
      );

      if (!_validateResponse(response)) {
        throw Exception('Gagal membuat tahun ajaran: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      return data['data'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error creating tahun ajaran: $e');
      rethrow;
    }
  }

  // Update tahun ajaran
  Future<Map<String, dynamic>?> updateTahunAjaran({
    required int id,
    String? kode,
    String? nama,
    bool? isActive,
  }) async {
    final token = await _getToken();
    if (token == null) return null;

    final url = Uri.parse('$_baseUrl/api/tahun-ajaran/$id');

    final Map<String, dynamic> body = {};
    if (kode != null) body['kode'] = kode;
    if (nama != null) body['nama'] = nama;
    if (isActive != null) body['is_active'] = isActive;

    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (!_validateResponse(response)) {
        throw Exception('Gagal update tahun ajaran: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      return data['data'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error updating tahun ajaran: $e');
      rethrow;
    }
  }

  // Hapus tahun ajaran
  Future<bool> deleteTahunAjaran(int id) async {
    final token = await _getToken();
    if (token == null) return false;

    final url = Uri.parse('$_baseUrl/api/tahun-ajaran/$id');

    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      return _validateResponse(response);
    } catch (e) {
      debugPrint('Error deleting tahun ajaran: $e');
      rethrow;
    }
  }
}

// ==================== TAHUN AJARAN PAGE ====================
class TahunAjaranPage extends StatefulWidget {
  const TahunAjaranPage({super.key});

  @override
  State<TahunAjaranPage> createState() => _TahunAjaranPageState();
}

class _TahunAjaranPageState extends State<TahunAjaranPage> {
  final TahunAjaranService _service = TahunAjaranService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Timer? _debounceTimer;
  bool _isLoading = true;

  final Color _primaryColor = const Color(0xFF3B060A);
  final Color _accentColor = const Color(0xFF5B1A1A);
  final Color _successColor = const Color(0xFF2E7D32);
  
  static const LinearGradient _primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3B060A),    // Maroon gelap
      Color(0xFF5B1A1A),    // Maroon sedang
    ],
  );

  List<Map<String, dynamic>> _tahunAjaranList = [];
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  int _totalPages = 1;
  int _totalItems = 0;
  String _searchQuery = '';
  bool _showActiveOnly = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final newQuery = _searchController.text.trim();
      if (newQuery != _searchQuery) {
        _searchQuery = newQuery;
        _currentPage = 1;
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final data = await _service.fetchTahunAjaran(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        isActive: _showActiveOnly ? true : null,
        page: _currentPage,
        limit: _itemsPerPage,
      );

      // Untuk API yang mengembalikan pagination
      if (data.isNotEmpty && data[0].containsKey('total')) {
        _totalItems = data[0]['total'] ?? data.length;
      } else {
        _totalItems = data.length;
      }

      _totalPages = (_totalItems / _itemsPerPage).ceil();
      if (_totalPages == 0) _totalPages = 1;

      setState(() {
        _tahunAjaranList = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading tahun ajaran: $e');
      _showDialog(
        title: 'Terjadi Kesalahan',
        message: 'Gagal mengambil data tahun ajaran',
        type: 'error',
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await _loadData();
  }

  void _toggleActiveFilter() {
    setState(() {
      _showActiveOnly = !_showActiveOnly;
      _currentPage = 1;
    });
    _loadData();
  }

  void _showAddDialog() {
    final formKey = GlobalKey<FormState>();
    final kodeController = TextEditingController();
    final namaController = TextEditingController();
    bool isActive = false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // HEADER
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      gradient: _primaryGradient,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Tambah Tahun Ajaran',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // CONTENT
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Kode
                          TextFormField(
                            controller: kodeController,
                            decoration: InputDecoration(
                              labelText: 'Kode Tahun Ajaran',
                              hintText: 'Contoh: 2024, 2024-2025',
                              prefixIcon: const Icon(Icons.numbers),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _primaryColor, width: 2),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Kode tahun ajaran wajib diisi';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Nama
                          TextFormField(
                            controller: namaController,
                            decoration: InputDecoration(
                              labelText: 'Nama Tahun Ajaran',
                              hintText: 'Contoh: Tahun Ajaran 2024/2025',
                              prefixIcon: const Icon(Icons.description),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _primaryColor, width: 2),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Nama tahun ajaran wajib diisi';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Status Aktif
                          SwitchListTile(
                            title: const Text('Aktifkan Tahun Ajaran'),
                            subtitle: const Text('Hanya satu tahun ajaran yang bisa aktif'),
                            value: isActive,
                            onChanged: (value) => setState(() => isActive = value),
                            activeThumbColor: _successColor,
                            tileColor: Colors.grey[50],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // BUTTONS
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
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _primaryColor,
                              side: BorderSide(color: _primaryColor),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                try {
                                  await _service.createTahunAjaran(
                                    kode: kodeController.text,
                                    nama: namaController.text,
                                    isActive: isActive,
                                  );
                                  
                                  if (mounted) {
                                    Navigator.pop(context);
                                    _refreshData();
                                    _showDialog(
                                      title: 'Berhasil',
                                      message: '✓ Tahun ajaran berhasil ditambahkan',
                                      type: 'success',
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    _showDialog(
                                      title: 'Gagal',
                                      message: '✗ ${e.toString()}',
                                      type: 'error',
                                    );
                                  }
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Simpan'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> tahunAjaran) {
    final formKey = GlobalKey<FormState>();
    final kodeController = TextEditingController(text: tahunAjaran['kode']?.toString() ?? '');
    final namaController = TextEditingController(text: tahunAjaran['nama']?.toString() ?? '');
    bool isActive = tahunAjaran['is_active'] == true;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // HEADER
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      gradient: _primaryGradient,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.edit_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Edit Tahun Ajaran',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tahunAjaran['nama'] ?? '',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // CONTENT
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Kode
                          TextFormField(
                            controller: kodeController,
                            decoration: InputDecoration(
                              labelText: 'Kode Tahun Ajaran',
                              prefixIcon: const Icon(Icons.numbers),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _primaryColor, width: 2),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Kode tahun ajaran wajib diisi';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Nama
                          TextFormField(
                            controller: namaController,
                            decoration: InputDecoration(
                              labelText: 'Nama Tahun Ajaran',
                              prefixIcon: const Icon(Icons.description),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _primaryColor, width: 2),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Nama tahun ajaran wajib diisi';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Status Aktif
                          SwitchListTile(
                            title: const Text('Status Aktif'),
                            subtitle: Text(
                              isActive 
                                ? 'Tahun ajaran ini sedang aktif'
                                : 'Tahun ajaran ini tidak aktif',
                            ),
                            value: isActive,
                            onChanged: (value) => setState(() => isActive = value),
                            activeThumbColor: _successColor,
                            tileColor: Colors.grey[50],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Info
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue[100]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info, color: Colors.blue[700], size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Jika mengaktifkan tahun ajaran ini, tahun ajaran lain akan otomatis dinonaktifkan',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue[700],
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

                  // BUTTONS
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
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _primaryColor,
                              side: BorderSide(color: _primaryColor),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                try {
                                  await _service.updateTahunAjaran(
                                    id: tahunAjaran['id'],
                                    kode: kodeController.text,
                                    nama: namaController.text,
                                    isActive: isActive,
                                  );
                                  
                                  if (mounted) {
                                    Navigator.pop(context);
                                    _refreshData();
                                    _showDialog(
                                      title: 'Berhasil',
                                      message: '✓ Tahun ajaran berhasil diperbarui',
                                      type: 'success',
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    _showDialog(
                                      title: 'Gagal',
                                      message: '✗ ${e.toString()}',
                                      type: 'error',
                                    );
                                  }
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Simpan'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> tahunAjaran) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Hapus Tahun Ajaran'),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus tahun ajaran "${tahunAjaran['nama']}"? '
          'Aksi ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _service.deleteTahunAjaran(tahunAjaran['id']);
                _refreshData();
                _showDialog(
                  title: 'Berhasil',
                  message: '✓ Tahun ajaran berhasil dihapus',
                  type: 'success',
                );
              } catch (e) {
                _showDialog(
                  title: 'Gagal',
                  message: '✗ ${e.toString()}',
                  type: 'error',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showDialog({
    required String title,
    required String message,
    required String type, // 'success', 'error', 'warning', 'info'
  }) {
    final gradientColors = _getDialogGradient(type);
    final iconData = _getDialogIcon(type);
    final buttonColor = _getDialogButtonColor(type);

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // HEADER
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(iconData, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // CONTENT
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      iconData,
                      size: 60,
                      color: _getDialogIconColor(type),
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
                  ],
                ),
              ),

              // BUTTON
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
                child: Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

  List<Color> _getDialogGradient(String type) {
    switch (type) {
      case 'success':
        return [const Color(0xFF2E7D32), const Color(0xFF4CAF50)];
      case 'error':
        return [const Color(0xFFC62828), const Color(0xFFEF5350)];
      case 'warning':
        return [const Color(0xFFF57C00), const Color(0xFFFF9800)];
      default: // info
        return [_primaryColor, _accentColor];
    }
  }

  IconData _getDialogIcon(String type) {
    switch (type) {
      case 'success':
        return Icons.check_circle_rounded;
      case 'error':
        return Icons.error_outline_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color _getDialogIconColor(String type) {
    switch (type) {
      case 'success':
        return const Color(0xFF4CAF50);
      case 'error':
        return const Color(0xFFEF5350);
      case 'warning':
        return const Color(0xFFFF9800);
      default:
        return _primaryColor;
    }
  }

  Color _getDialogButtonColor(String type) {
    switch (type) {
      case 'success':
        return const Color(0xFF4CAF50);
      case 'error':
        return const Color(0xFFEF5350);
      case 'warning':
        return const Color(0xFFFF9800);
      default:
        return _primaryColor;
    }
  }

  Widget _buildTahunAjaranCard(Map<String, dynamic> item) {
    final isActive = item['is_active'] == true;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isActive ? _successColor.withValues(alpha: 0.3) : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isActive
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _successColor.withValues(alpha:0.05),
                    _successColor.withValues(alpha:0.02),
                  ],
                )
              : null,
        ),
        child: ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: _primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: _successColor.withValues(alpha:0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              isActive ? Icons.check_circle : Icons.calendar_today,
              color: Colors.white,
              size: 24,
            ),
          ),
          title: Text(
            item['nama'] ?? 'Tahun Ajaran',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: isActive ? _successColor : Colors.black87,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                'Kode: ${item['kode'] ?? '-'}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive 
                      ? _successColor.withValues(alpha:0.1)
                      : Colors.grey.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive 
                        ? _successColor.withValues(alpha:0.3)
                        : Colors.grey.withValues(alpha:0.3),
                  ),
                ),
                child: Text(
                  isActive ? 'Aktif' : 'Tidak Aktif',
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive ? _successColor : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'edit') {
                _showEditDialog(item);
              } else if (value == 'delete') {
                _showDeleteDialog(item);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Hapus'),
                  ],
                ),
              ),
            ],
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    if (_totalPages <= 1) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Tombol Previous
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1
                ? () {
                    setState(() => _currentPage--);
                    _loadData();
                  }
                : null,
            style: IconButton.styleFrom(
              backgroundColor: _currentPage > 1 
                  ? _primaryColor 
                  : Colors.grey[300],
              foregroundColor: _currentPage > 1 
                  ? Colors.white 
                  : Colors.grey[500],
            ),
          ),
          
          // Page numbers
          const SizedBox(width: 16),
          Text(
            'Halaman $_currentPage dari $_totalPages',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          
          // Tombol Next
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _totalPages
                ? () {
                    setState(() => _currentPage++);
                    _loadData();
                  }
                : null,
            style: IconButton.styleFrom(
              backgroundColor: _currentPage < _totalPages
                  ? _primaryColor
                  : Colors.grey[300],
              foregroundColor: _currentPage < _totalPages
                  ? Colors.white
                  : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final activeCount = _tahunAjaranList.where((item) => item['is_active'] == true).length;
    final inactiveCount = _tahunAjaranList.length - activeCount;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha:0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Stat Aktif
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _successColor,
                        _successColor.withValues(alpha:0.7),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 8),
                Text(
                  '$activeCount',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _successColor,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Aktif',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          
          // Stat Tidak Aktif
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.grey[600]!,
                        Colors.grey[400]!,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cancel, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 8),
                Text(
                  '$inactiveCount',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tidak Aktif',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          
          // Stat Total
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    gradient: _primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.list, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_tahunAjaranList.length}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Manajemen Tahun Ajaran',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          // Filter aktif saja
          IconButton(
            icon: Icon(
              _showActiveOnly ? Icons.toggle_on : Icons.toggle_off,
              color: Colors.white,
            ),
            onPressed: _toggleActiveFilter,
            tooltip: _showActiveOnly ? 'Tampilkan semua' : 'Hanya aktif',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha:0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Cari tahun ajaran...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: _primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha:0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.filter_list, color: Colors.white),
                    onPressed: _toggleActiveFilter,
                    tooltip: 'Filter',
                  ),
                ),
              ],
            ),
          ),

          // Stats
          _buildStats(),

          // List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              color: _primaryColor,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF3B060A),
                      ),
                    )
                  : _tahunAjaranList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Tidak ada tahun ajaran',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _showActiveOnly
                                    ? 'Tidak ada tahun ajaran aktif'
                                    : 'Tambahkan tahun ajaran baru',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: _tahunAjaranList.length,
                          itemBuilder: (context, index) {
                            return _buildTahunAjaranCard(_tahunAjaranList[index]);
                          },
                        ),
            ),
          ),

          // Pagination
          _buildPaginationControls(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}