import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ==================== PKL SERVICE ====================
class PKLService {
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

  // ==================== PERMOHONAN PKL ====================
  Future<List<Map<String, dynamic>>> fetchPKLApplications({
    String? status,
    String? siswaUsername,
    String? industriName,
    int page = 1,
    int limit = 10,
  }) async {
    final token = await _getToken();
    if (token == null) return [];

    final url = Uri.parse('$_baseUrl/api/pkl/applications').replace(
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (siswaUsername != null && siswaUsername.isNotEmpty) 'siswa_username': siswaUsername,
        if (industriName != null && industriName.isNotEmpty) 'industri_name': industriName,
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
        throw Exception('Gagal mengambil permohonan: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      if (data['data'] is List) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching PKL applications: $e');
      rethrow;
    }
  }

  Future<bool> approveApplication(int applicationId, {String? kaprogNote}) async {
    final token = await _getToken();
    if (token == null) return false;

    final url = Uri.parse('$_baseUrl/api/pkl/applications/$applicationId/approve');

    try {
      final Map<String, dynamic> body = {};
      if (kaprogNote != null && kaprogNote.isNotEmpty) {
        body['kaprog_note'] = kaprogNote;
      }

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
        throw Exception('Gagal menyetujui permohonan: ${response.statusCode}');
      }

      return true;
    } catch (e) {
      debugPrint('Error approving application: $e');
      rethrow;
    }
  }

  Future<bool> rejectApplication(int applicationId, {String? kaprogNote}) async {
    final token = await _getToken();
    if (token == null) return false;

    final url = Uri.parse('$_baseUrl/api/pkl/applications/$applicationId/reject');

    try {
      final Map<String, dynamic> body = {};
      if (kaprogNote != null && kaprogNote.isNotEmpty) {
        body['kaprog_note'] = kaprogNote;
      }

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
        throw Exception('Gagal menolak permohonan: ${response.statusCode}');
      }

      return true;
    } catch (e) {
      debugPrint('Error rejecting application: $e');
      rethrow;
    }
  }

  // ==================== KUOTA INDUSTRI ====================
  Future<List<Map<String, dynamic>>> fetchIndustriQuota({
    String? search,
    int page = 1,
    int limit = 10,
  }) async {
    final token = await _getToken();
    if (token == null) return [];

    final url = Uri.parse('$_baseUrl/api/pkl/industri/preview').replace(
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
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
        throw Exception('Gagal mengambil kuota industri: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      if (data['data'] is List) {
        return List<Map<String, dynamic>>.from(data['data']).map((item) {
          final kuotaSiswa = item['kuota_siswa'] ?? 0;
          final activeStudents = item['active_students'] ?? 0;
          final remainingSlots = item['remaining_slots'];
          
          // PERBAIKAN: Handle nilai negatif untuk kuota tersedia
          int kuotaTersedia;
          if (remainingSlots != null) {
            kuotaTersedia = max(0, remainingSlots as int);
          } else {
            final calculated = (kuotaSiswa as int? ?? 0) - (activeStudents as int? ?? 0);
            kuotaTersedia = max(0, calculated);
          }

          return {
            'id': item['industri_id'],
            'nama': item['nama'],
            'kuota': kuotaSiswa,
            'kuota_digunakan': activeStudents,
            'kuota_tersedia': kuotaTersedia,
            'pending_applications': item['pending_applications'] ?? 0,
            'approved_applications': item['approved_applications'] ?? 0,
          };
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching industri quota: $e');
      rethrow;
    }
  }

  Future<bool> updateQuota(int industriId, int quota) async {
    final token = await _getToken();
    if (token == null) return false;

    final url = Uri.parse('$_baseUrl/api/pkl/industri/$industriId/quota');

    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'kuota_siswa': quota}),
      );

      if (!_validateResponse(response)) {
        throw Exception('Gagal memperbarui kuota: ${response.statusCode}');
      }

      return true;
    } catch (e) {
      debugPrint('Error updating quota: $e');
      rethrow;
    }
  }

  // ==================== PEMBIMBING ====================
  Future<List<Map<String, dynamic>>> fetchPembimbing({
    String? search,
  }) async {
    final token = await _getToken();
    if (token == null) return [];

    final url = Uri.parse('$_baseUrl/api/pkl/pembimbing').replace(
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
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
        throw Exception('Gagal mengambil data pembimbing: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data).map((item) {
          return {
            'id': item['id'],
            'nama': item['nama'],
            'nip': item['nip'],
            'no_telp': item['no_telp'],
          };
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching pembimbing: $e');
      rethrow;
    }
  }

  Future<bool> assignPembimbing(int applicationId, int pembimbingId) async {
    final token = await _getToken();
    if (token == null) return false;

    final url = Uri.parse('$_baseUrl/api/pkl/applications/$applicationId/pembimbing');

    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'pembimbing_guru_id': pembimbingId}),
      );

      if (!_validateResponse(response)) {
        throw Exception('Gagal menetapkan pembimbing: ${response.statusCode}');
      }

      return true;
    } catch (e) {
      debugPrint('Error assigning pembimbing: $e');
      rethrow;
    }
  }

  // ==================== UTILITY FUNCTIONS ====================
  Future<void> clearCache() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  Future<bool> checkAuth() async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final url = Uri.parse('$_baseUrl/api/pkl/applications?limit=1');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      
      return response.statusCode != 401;
    } catch (e) {
      return false;
    }
  }
}

// ==================== MANAJEMEN PKL PAGE ====================
class ManajemenPklPage extends StatefulWidget {
  final String? initialFilter;

  const ManajemenPklPage({super.key, this.initialFilter});

  @override
  State<ManajemenPklPage> createState() => ManajemenPklPageState();
}

class ManajemenPklPageState extends State<ManajemenPklPage> {
  final PKLService _service = PKLService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Timer? _debounceTimer;
  bool _isLoading = true;

  final Color _primaryColor = const Color(0xFF3B060A);
  final Color _accentColor = const Color(0xFF5B1A1A);
  final Color _dangerColor = const Color(0xFF8B0000);
  final Color _successColor = const Color(0xFF2E7D32);
  final Color _warningColor = const Color(0xFFF57C00);
  
  static const LinearGradient _primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3B060A),    // Maroon gelap
      Color(0xFF5B1A1A),    // Maroon sedang
    ],
  );
  
  static const LinearGradient _reverseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF5B1A1A),    // Maroon sedang
      Color(0xFF3B060A),    // Maroon gelap
    ],
  );

  final List<Map<String, dynamic>> _tabData = [
    {
      'type': 'Permohonan',
      'icon': Icons.request_page,
      'stats': {'total': 0, 'pending': 0, 'approved': 0, 'rejected': 0, 'completed': 0},
      'hasFilter': true,
      'filterType': 'status',
      'filterLabel': 'Filter Status',
    },
    {
      'type': 'Kuota Industri',
      'icon': Icons.business_center,
      'stats': {'total': 0, 'available': 0, 'used': 0, 'pending': 0},
      'hasFilter': false,
    },
    {
      'type': 'Pembimbing',
      'icon': Icons.supervised_user_circle,
      'stats': {'total': 0, 'available': 0},
      'hasFilter': false,
    },
  ];

  int _currentTab = 0;
  String _selectedFilterDisplay = 'Semua';
  String _selectedFilterId = '';
  String _searchQuery = '';

  final Map<String, List<Map<String, dynamic>>> _dataCache = {};
  final int _maxCacheSize = 3;

  int _currentPage = 1;
  final int _itemsPerPage = 10;
  int _totalPages = 1;
  List<Map<String, dynamic>> _allData = [];
  List<Map<String, dynamic>> _currentPageData = [];

  final List<Map<String, String>> _availableStatus = [
    {'id': '', 'name': 'Semua'},
    {'id': 'Pending', 'name': 'Pending'},
    {'id': 'Approved', 'name': 'Disetujui'},
    {'id': 'Rejected', 'name': 'Ditolak'},
    {'id': 'Completed', 'name': 'Selesai'},
  ];

  @override
  void initState() {
    super.initState();
    _initAll();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final newQuery = _searchController.text.trim();
      if (newQuery != _searchQuery) {
        _resetPagination();
        _fetchDataWithCache(newQuery);
      }
    });
  }

  void _resetPagination() {
    setState(() {
      _currentPage = 1;
      _totalPages = 1;
      _allData = [];
      _currentPageData = [];
    });
  }

  void _resetStatsForTab(int tabIndex) {
    final stats = _tabData[tabIndex]['stats'] as Map<String, dynamic>;
    stats.forEach((key, value) {
      stats[key] = 0;
    });
  }

  Future<void> _initAll() async {
    await _fetchDataWithCache(_searchQuery);
  }

  Future<void> refreshData() async {
    _clearCacheForCurrentType();
    _resetPagination();
    setState(() => _isLoading = true);
    await _fetchDataWithCache(_searchQuery, forceRefresh: true);
    setState(() => _isLoading = false);
  }

  void _clearCacheForCurrentType() {
    final currentType = _tabData[_currentTab]['type'];
    final keysToRemove = _dataCache.keys
        .where((key) => key.startsWith('${currentType.toLowerCase()}-'))
        .toList();
    for (final key in keysToRemove) {
      _dataCache.remove(key);
    }
  }

  void _cleanCacheIfNeeded() {
    final currentType = _tabData[_currentTab]['type'];
    final currentTypeKeys = _dataCache.keys
        .where((key) => key.startsWith('${currentType.toLowerCase()}-'))
        .toList();
    if (currentTypeKeys.length > _maxCacheSize) {
      _dataCache.remove(currentTypeKeys.first);
    }
  }

  Future<void> _fetchDataWithCache(String query,
      {bool forceRefresh = false}) async {
    final cacheKey = _getCacheKey(query);
    _cleanCacheIfNeeded();

    if (!forceRefresh && _dataCache.containsKey(cacheKey)) {
      final cachedData = _dataCache[cacheKey]!;
      _setupPaginationData(cachedData);
      _updateStats(cachedData);
      setState(() {
        _searchQuery = query;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _searchQuery = query;
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> data;
      final currentType = _tabData[_currentTab]['type'];

      switch (currentType) {
        case 'Permohonan':
          data = await _service.fetchPKLApplications(
            status: _selectedFilterId.isNotEmpty ? _selectedFilterId : null,
            siswaUsername: query.isNotEmpty ? query : null,
            page: _currentPage,
            limit: _itemsPerPage,
          );
          break;
        case 'Kuota Industri':
          data = await _service.fetchIndustriQuota(
            search: query.isNotEmpty ? query : null,
            page: _currentPage,
            limit: _itemsPerPage,
          );
          break;
        case 'Pembimbing':
          data = await _service.fetchPembimbing(
            search: query.isNotEmpty ? query : null,
          );
          break;
        default:
          data = [];
      }

      _dataCache[cacheKey] = data;
      _updateStats(data);
      _setupPaginationData(data);
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Exception fetching ${_tabData[_currentTab]['type']}: $e');
      _showDialog(
        title: 'Terjadi Kesalahan',
        message: 'Gagal mengambil data: ${e.toString()}',
        type: 'error',
      );
      setState(() => _isLoading = false);
    }
  }

  void _updateStats(List<Map<String, dynamic>> data) {
    final currentStats = _tabData[_currentTab]['stats'] as Map<String, dynamic>;
    final currentType = _tabData[_currentTab]['type'];
    
    switch (currentType) {
      case 'Permohonan':
        currentStats['total'] = data.length;
        currentStats['pending'] = data.where((item) {
          final app = item['application'] as Map<String, dynamic>;
          return app['status'] == 'Pending';
        }).length;
        currentStats['approved'] = data.where((item) {
          final app = item['application'] as Map<String, dynamic>;
          return app['status'] == 'Approved';
        }).length;
        currentStats['rejected'] = data.where((item) {
          final app = item['application'] as Map<String, dynamic>;
          return app['status'] == 'Rejected';
        }).length;
        currentStats['completed'] = data.where((item) {
          final app = item['application'] as Map<String, dynamic>;
          return app['status'] == 'Completed';
        }).length;
        break;
      case 'Kuota Industri':
        currentStats['total'] = data.length;
        currentStats['available'] = data.fold<int>(0, (sum, item) => sum + ((item['kuota_tersedia'] as int?) ?? 0));
        currentStats['used'] = data.fold<int>(0, (sum, item) => sum + ((item['kuota_digunakan'] as int?) ?? 0));
        currentStats['pending'] = data.fold<int>(0, (sum, item) => sum + ((item['pending_applications'] as int?) ?? 0));
        break;
      case 'Pembimbing':
        currentStats['total'] = data.length;
        currentStats['available'] = data.length;
        break;
    }
  }

  void _setupPaginationData(List<Map<String, dynamic>> allData) {
    _allData = allData;
    _totalPages = (allData.length / _itemsPerPage).ceil();
    if (_totalPages == 0) _totalPages = 1;
    _goToPage(_currentPage);
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    setState(() {
      _currentPage = page;
      final startIndex = (page - 1) * _itemsPerPage;
      final endIndex = startIndex + _itemsPerPage;
      _currentPageData = _allData.sublist(
        startIndex,
        endIndex > _allData.length ? _allData.length : endIndex,
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  void _nextPage() => _currentPage < _totalPages ? _goToPage(_currentPage + 1) : null;
  void _previousPage() => _currentPage > 1 ? _goToPage(_currentPage - 1) : null;

  String _getCacheKey(String query) {
    final currentType = _tabData[_currentTab]['type'];
    return '${currentType.toLowerCase()}-$query-$_selectedFilterId';
  }

  void _handleItemTap(Map<String, dynamic> item) async {
    final currentType = _tabData[_currentTab]['type'];
    
    if (currentType == 'Permohonan') {
      await _showApplicationDetailDialog(item);
    } else if (currentType == 'Kuota Industri') {
      await _showQuotaEditDialog(item);
    } else if (currentType == 'Pembimbing') {
      await _showPembimbingDetailDialog(item);
    }
  }

  // ==================== DIALOG THEMES ====================
  void _showDialog({
    required String title,
    required String message,
    required String type, // 'success', 'error', 'warning', 'info'
    VoidCallback? onOk,
    VoidCallback? onCancel,
    String? okText,
    String? cancelText,
  }) {
    final gradientColors = _getDialogGradient(type);
    final iconData = _getDialogIcon(type);
    final iconColor = _getDialogIconColor(type);
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
                      color: iconColor,
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
                    if (onCancel != null) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _primaryColor,
                            side: BorderSide(color: _primaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(cancelText ?? 'Batal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onOk ?? () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          shadowColor: buttonColor.withValues(alpha: 0.3),
                        ),
                        child: Text(okText ?? 'OK'),
                      ),
                    ),
                  ],
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

  // PERBAIKAN: Dialog detail permohonan dengan tema baru
  Future<void> _showApplicationDetailDialog(Map<String, dynamic> item) async {
    final application = item['application'] as Map<String, dynamic>;
    final status = application['status'] as String;
    final noteController = TextEditingController(text: application['kaprog_note'] ?? '');
    
    final Color statusColor = _getStatusColor(status);
    final String statusText = _getStatusText(status);
    final String siswaNama = item['siswa_username'] ?? 'Siswa';

    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) {
        return Dialog(
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
                        child: const Icon(Icons.request_page, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Detail Permohonan PKL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              siswaNama,
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
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Info Siswa
                        _buildDialogSection(
                          title: 'Data Siswa',
                          children: [
                            _buildDialogInfoRow('Nama Siswa', siswaNama),
                            _buildDialogInfoRow('NISN', item['siswa_nisn'] ?? '-'),
                            _buildDialogInfoRow('Kelas', item['kelas_nama'] ?? '-'),
                            _buildDialogInfoRow('Jurusan', item['jurusan_nama'] ?? '-'),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Info Industri
                        _buildDialogSection(
                          title: 'Data Industri',
                          children: [
                            _buildDialogInfoRow('Nama Industri', item['industri_nama'] ?? '-'),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Info Permohonan
                        _buildDialogSection(
                          title: 'Detail Permohonan',
                          children: [
                            _buildDialogInfoRow('Tanggal Permohonan', _formatDateTime(application['tanggal_permohonan'])),
                            if (application['tanggal_mulai'] != null)
                              _buildDialogInfoRow('Tanggal Mulai', _formatDate(application['tanggal_mulai'])),
                            if (application['tanggal_selesai'] != null)
                              _buildDialogInfoRow('Tanggal Selesai', _formatDate(application['tanggal_selesai'])),
                            _buildDialogInfoRowWithColor('Status', statusText, statusColor),
                            if (application['catatan'] != null && application['catatan'].isNotEmpty)
                              _buildDialogInfoRow('Catatan Siswa', application['catatan']),
                            if (application['decided_at'] != null)
                              _buildDialogInfoRow('Waktu Keputusan', _formatDateTime(application['decided_at'])),
                            if (application['pembimbing_guru_id'] != null)
                              _buildDialogInfoRow('ID Pembimbing', '${application['pembimbing_guru_id']}'),
                          ],
                        ),
                        
                        // Catatan Kaprog (hanya untuk status Pending)
                        if (status == 'Pending') ...[
                          const SizedBox(height: 16),
                          Text(
                            'Catatan Kaprog',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: noteController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Masukkan catatan (opsional)',
                              hintStyle: const TextStyle(color: Colors.grey),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _primaryColor, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
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
                  child: status == 'Pending'
                      ? Row(
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
                                onPressed: () => _handleApplicationAction(
                                  application['id'], 
                                  'reject',
                                  note: noteController.text,
                                  context: context,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _dangerColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Tolak'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _handleApplicationAction(
                                  application['id'], 
                                  'approve',
                                  note: noteController.text,
                                  context: context,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _successColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Setujui'),
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Tutup'),
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // PERBAIKAN: Dialog edit kuota dengan tema baru
  Future<void> _showQuotaEditDialog(Map<String, dynamic> item) async {
    final quotaController = TextEditingController(
      text: (item['kuota'] ?? 0).toString(),
    );
    
    final String industriNama = item['nama'] ?? 'Industri';
    
    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
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
                            child: const Icon(Icons.edit, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Edit Kuota Industri',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  industriNama,
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Input kuota
                          Text(
                            'Jumlah Kuota',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: quotaController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Masukkan jumlah kuota',
                              hintStyle: const TextStyle(color: Colors.grey),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _primaryColor, width: 2),
                              ),
                              suffixText: 'siswa',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Info kuota
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    _buildDialogQuotaInfo(
                                      'Tersedia',
                                      '${max<int>(0, item['kuota_tersedia'] ?? 0)}',
                                      const Color(0xFF4CAF50),
                                    ),
                                    const SizedBox(width: 12),
                                    _buildDialogQuotaInfo(
                                      'Digunakan',
                                      '${item['kuota_digunakan'] ?? 0}',
                                      _primaryColor,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _buildDialogQuotaInfo(
                                      'Pending',
                                      '${item['pending_applications'] ?? 0}',
                                      _warningColor,
                                    ),
                                    const SizedBox(width: 12),
                                    _buildDialogQuotaInfo(
                                      'Disetujui',
                                      '${item['approved_applications'] ?? 0}',
                                      const Color(0xFF2196F3),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
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
                                final newQuota = int.tryParse(quotaController.text);
                                if (newQuota == null || newQuota < 0) {
                                  _showDialog(
                                    title: 'Input Tidak Valid',
                                    message: 'Kuota harus berupa angka positif',
                                    type: 'warning',
                                  );
                                  return;
                                }

                                try {
                                  final success = await _service.updateQuota(item['id'], newQuota);
                                  if (success) {
                                    if (mounted) Navigator.pop(context);
                                    refreshData();
                                    _showDialog(
                                      title: 'Berhasil',
                                      message: '✓ Kuota berhasil diperbarui',
                                      type: 'success',
                                    );
                                  }
                                } catch (e) {
                                  _showDialog(
                                    title: 'Gagal',
                                    message: '✗ ${e.toString()}',
                                    type: 'error',
                                  );
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
        );
      },
    );
  }

  // PERBAIKAN: Dialog detail pembimbing dengan tema baru
  Future<void> _showPembimbingDetailDialog(Map<String, dynamic> item) async {
    final String pembimbingNama = item['nama'] ?? 'Pembimbing';
    
    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => Dialog(
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
                      child: const Icon(Icons.supervised_user_circle, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Detail Pembimbing',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pembimbingNama,
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: _primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: _primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildDialogInfoRow('Nama', item['nama'] ?? '-'),
                    _buildDialogInfoRow('NIP', item['nip'] ?? '-'),
                    _buildDialogInfoRow('No. Telepon', item['no_telp'] ?? '-'),
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
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

  // ==================== WIDGET HELPER FUNCTIONS ====================
  Widget _buildDialogSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDialogInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogInfoRowWithColor(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogQuotaInfo(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleApplicationAction(int applicationId, String action, 
      {String? note, required BuildContext context}) async {
    try {
      bool success;
      if (action == 'approve') {
        success = await _service.approveApplication(applicationId, kaprogNote: note);
      } else {
        success = await _service.rejectApplication(applicationId, kaprogNote: note);
      }
      
      if (success && mounted) {
        Navigator.pop(context); // Close detail dialog
        refreshData();
        _showDialog(
          title: 'Berhasil',
          message: '✓ Permohonan berhasil di${action == 'approve' ? 'setujui' : 'tolak'}',
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

  String _formatDate(dynamic date) {
    if (date == null) return '-';
    try {
      if (date is String) {
        return DateFormat('dd MMM yyyy').format(DateTime.parse(date));
      }
      return date.toString();
    } catch (e) {
      return date.toString();
    }
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return '-';
    try {
      if (dateTime is String) {
        return DateFormat('dd MMM yyyy HH:mm').format(DateTime.parse(dateTime));
      }
      return dateTime.toString();
    } catch (e) {
      return dateTime.toString();
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'Pending':
        return 'Menunggu';
      case 'Approved':
        return 'Disetujui';
      case 'Rejected':
        return 'Ditolak';
      case 'Completed':
        return 'Selesai';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return _warningColor;
      case 'Approved':
        return _successColor;
      case 'Rejected':
        return _dangerColor;
      case 'Completed':
        return const Color(0xFF2196F3);
      default:
        return Colors.grey;
    }
  }

  void _handleTabChange(int newIndex) {
    if (newIndex == _currentTab) return;
    setState(() {
      _currentTab = newIndex;
      _searchQuery = '';
      _searchController.text = '';
      _selectedFilterDisplay = 'Semua';
      _selectedFilterId = '';
      _resetStatsForTab(newIndex);
    });
    _resetPagination();
    _fetchDataWithCache('');
  }

  // PERBAIKAN: HEADER STATS untuk Pembimbing hanya 2 item
  Widget _buildHeaderStats() {
    final currentStats = _tabData[_currentTab]['stats'] as Map<String, dynamic>;
    final currentType = _tabData[_currentTab]['type'];

    List<Widget> statItems = [];
    
    switch (currentType) {
      case 'Permohonan':
        statItems = [
          _buildStatItem(currentStats['total'].toString(), 'Total', Icons.list_alt),
          _buildStatItem(currentStats['pending'].toString(), 'Pending', Icons.pending),
          _buildStatItem(currentStats['approved'].toString(), 'Disetujui', Icons.check_circle),
          _buildStatItem(currentStats['rejected'].toString(), 'Ditolak', Icons.cancel),
        ];
        if (currentStats['completed'] != null && currentStats['completed'] > 0) {
          statItems.add(_buildStatItem(currentStats['completed'].toString(), 'Selesai', Icons.assignment_turned_in));
        }
        break;
      case 'Kuota Industri':
        statItems = [
          _buildStatItem(currentStats['total'].toString(), 'Total Industri', Icons.business),
          _buildStatItem(currentStats['available'].toString(), 'Kuota Tersedia', Icons.event_available),
          _buildStatItem(currentStats['used'].toString(), 'Kuota Digunakan', Icons.event_busy),
          _buildStatItem(currentStats['pending'].toString(), 'Pending', Icons.pending_actions),
        ];
        break;
      case 'Pembimbing':
        // PERBAIKAN: Hanya 2 item untuk Pembimbing, dibuat center
        statItems = [
          _buildStatItem(currentStats['total'].toString(), 'Total Pembimbing', Icons.supervised_user_circle),
          _buildStatItem(currentStats['available'].toString(), 'Tersedia', Icons.person),
        ];
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: _currentTab == 2 
              ? MainAxisAlignment.center  // Center untuk Pembimbing
              : MainAxisAlignment.start,  // Start untuk yang lain
          children: [
            ...statItems.map((item) => Padding(
              padding: const EdgeInsets.only(right: 20),
              child: item,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.4),
                  Colors.white.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // TAB BAR
  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ..._tabData.asMap().entries.map((entry) {
              final index = entry.key;
              final tab = entry.value;
              return _buildDataTab(
                  tab['type'] as String, tab['icon'] as IconData, index);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTab(String title, IconData icon, int index) {
    final isSelected = _currentTab == index;
    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      child: InkWell(
        onTap: () => _handleTabChange(index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? _primaryColor : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: isSelected
                    ? const BoxDecoration(
                        gradient: _primaryGradient,
                        shape: BoxShape.circle,
                      )
                    : null,
                child: Icon(
                  icon,
                  size: 18,
                  color: isSelected ? Colors.white : Colors.grey,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? _primaryColor : Colors.grey,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    final currentTabData = _tabData[_currentTab];
    final bool hasFilter = currentTabData['hasFilter'] as bool;
    
    if (!hasFilter && _selectedFilterDisplay != 'Semua') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _selectFilter('Semua', '');
      });
    }
    
    final String filterType = hasFilter ? currentTabData['filterType'] as String : '';
    final String filterLabel = hasFilter ? currentTabData['filterLabel'] as String : '';

    final List<Widget> searchChildren = [
      Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: currentType == 'Permohonan' 
                      ? 'Cari nama siswa...' 
                      : currentType == 'Kuota Industri'
                          ? 'Cari nama industri...'
                          : 'Cari nama pembimbing...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16),
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (hasFilter)
            GestureDetector(
              onTap: () => _showFilterDialog(filterType, filterLabel),
              child: Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: _selectedFilterDisplay != 'Semua'
                      ? _primaryGradient
                      : null,
                  color: _selectedFilterDisplay == 'Semua'
                      ? Colors.white
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.filter_list,
                  color: _selectedFilterDisplay != 'Semua'
                      ? Colors.white
                      : _primaryColor,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    ];

    if (hasFilter && _selectedFilterDisplay != 'Semua') {
      searchChildren.add(Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    _primaryColor.withValues(alpha: 0.25),
                    _primaryColor.withValues(alpha: 0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _primaryColor.withValues(alpha: 0.76),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.filter_list,
                    size: 14,
                    color: _primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _selectedFilterDisplay,
                    style: TextStyle(
                      color: _primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      _selectFilter('Semua', '');
                    },
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: _primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: searchChildren,
      ),
    );
  }

  String get currentType => _tabData[_currentTab]['type'] as String;

  void _showFilterDialog(String filterType, String filterLabel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: _primaryGradient,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.76),
                            Colors.white.withValues(alpha: 0.25),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.filter_list_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Filter Status',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView(
                  children: [
                    ..._availableStatus.map((item) => ListTile(
                          leading: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _selectedFilterId == item['id']
                                  ? _primaryColor.withValues(alpha: 0.25)
                                  : Colors.transparent,
                            ),
                            child: Icon(
                              Icons.circle,
                              size: 16,
                              color: _selectedFilterId == item['id']
                                  ? _primaryColor
                                  : Colors.grey[300],
                            ),
                          ),
                          title: Text(item['name']!),
                          onTap: () {
                            _selectFilter(item['name']!, item['id']!);
                            Navigator.pop(context);
                          },
                        )),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _selectFilter(String displayName, String filterId) {
    final currentTabData = _tabData[_currentTab];
    if (currentTabData['hasFilter'] != true) {
      debugPrint('⚠️ Tab ${currentTabData['type']} tidak mendukung filter');
      return;
    }

    setState(() {
      _selectedFilterDisplay = displayName;
      _selectedFilterId = filterId;
      _isLoading = true;
    });

    _resetPagination();
    _fetchDataWithCache(_searchQuery, forceRefresh: true);
  }

  // CONTENT SECTION
  Widget _buildContent() {
    return Expanded(
      child: RefreshIndicator(
        onRefresh: refreshData,
        color: _primaryColor,
        child: _buildDataListWithPagination(),
      ),
    );
  }

  Widget _buildDataListWithPagination() {
    if (_isLoading) {
      return _buildSkeletonLoading();
    }

    if (_allData.isEmpty) {
      return _buildEmptyState();
    }

    return ListView(
      controller: _scrollController,
      children: [
        Column(
          children: [
            ..._currentPageData.map((item) => _buildDataCard(item)),
            const SizedBox(height: 16),
          ],
        ),
        _buildPaginationControls(),
      ],
    );
  }

  Widget _buildSkeletonLoading() {
    return ListView(
      children: List.generate(5, (index) => _buildSkeletonCard()),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 150,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 200,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final currentTabData = _tabData[_currentTab];
    final bool hasFilter = currentTabData['hasFilter'] as bool;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada data ditemukan',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              hasFilter && _selectedFilterDisplay != 'Semua'
                  ? 'Coba ubah pencarian atau pilih filter yang berbeda'
                  : 'Coba ubah pencarian atau tambahkan data baru',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleItemTap(item),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: _reverseGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _tabData[_currentTab]['icon'] as IconData,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCardContent(item, _tabData[_currentTab]['type'] as String),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(Map<String, dynamic> item, String currentType) {
    switch (currentType) {
      case 'Permohonan':
        return _buildApplicationCardContent(item);
      case 'Kuota Industri':
        return _buildIndustriCardContent(item);
      case 'Pembimbing':
        return _buildPembimbingCardContent(item);
      default:
        return const SizedBox();
    }
  }

  Widget _buildApplicationCardContent(Map<String, dynamic> item) {
    final application = item['application'] as Map<String, dynamic>;
    final status = application['status'] as String;
    
    final List<Widget> children = [
      Row(
        children: [
          Expanded(
            child: Text(
              item['siswa_username'] ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getStatusColor(status),
                width: 1,
              ),
            ),
            child: Text(
              _getStatusText(status),
              style: TextStyle(
                color: _getStatusColor(status),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      _buildEnhancedInfoRow(
        Icons.class_outlined,
        '${item['kelas_nama'] ?? ''} (${item['jurusan_nama'] ?? ''})',
      ),
      _buildEnhancedInfoRow(
        Icons.business,
        item['industri_nama'] ?? '',
      ),
    ];

    if (application['tanggal_mulai'] != null) {
      children.add(_buildEnhancedInfoRow(
        Icons.calendar_today,
        '${_formatDate(application['tanggal_mulai'])} - ${_formatDate(application['tanggal_selesai'])}',
      ));
    }
    if (application['pembimbing_guru_id'] != null) {
      children.add(_buildEnhancedInfoRow(
        Icons.supervised_user_circle,
        'Pembimbing: #${application['pembimbing_guru_id']}',
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildIndustriCardContent(Map<String, dynamic> item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item['nama'] ?? '',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildEnhancedInfoRow(
                Icons.people,
                '${max<int>(0, item['kuota_tersedia'] ?? 0)} tersedia dari ${item['kuota'] ?? 0}',
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _primaryColor.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${item['kuota_digunakan'] ?? 0} digunakan',
                style: TextStyle(
                  color: _primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            _buildMiniInfoRow(
              '${item['pending_applications'] ?? 0} Pending',
              _warningColor,
            ),
            const SizedBox(width: 8),
            _buildMiniInfoRow(
              '${item['approved_applications'] ?? 0} Disetujui',
              _successColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniInfoRow(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPembimbingCardContent(Map<String, dynamic> item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item['nama'] ?? '',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        _buildEnhancedInfoRow(
          Icons.badge,
          'NIP: ${item['nip'] ?? ''}',
        ),
        _buildEnhancedInfoRow(
          Icons.phone,
          item['no_telp'] ?? '',
        ),
      ],
    );
  }

  Widget _buildEnhancedInfoRow(IconData icon, String text, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _primaryColor.withValues(alpha: 0.38),
                  _primaryColor.withValues(alpha: 0.12),
                ],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 14,
              color: _primaryColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    if (_totalPages <= 1) return const SizedBox();
    
    final List<Widget> pageChildren = [
      _buildPaginationButton(
        icon: Icons.arrow_back_ios_rounded,
        isEnabled: _currentPage > 1,
        onTap: _previousPage,
      ),
      const SizedBox(width: 12),
    ];

    if (_totalPages <= 5) {
      pageChildren.addAll(List.generate(_totalPages, (index) {
        final pageNumber = index + 1;
        return _buildPageNumber(pageNumber);
      }));
    } else {
      pageChildren.add(_buildPageNumber(1));
      if (_currentPage > 3) pageChildren.add(const Text('...'));
      if (_currentPage > 2 && _currentPage < _totalPages - 1) pageChildren.add(_buildPageNumber(_currentPage - 1));
      if (_currentPage > 1 && _currentPage < _totalPages) pageChildren.add(_buildPageNumber(_currentPage));
      if (_currentPage < _totalPages - 1) pageChildren.add(_buildPageNumber(_currentPage + 1));
      if (_currentPage < _totalPages - 2) pageChildren.add(const Text('...'));
      pageChildren.add(_buildPageNumber(_totalPages));
    }

    pageChildren.add(const SizedBox(width: 12));
    pageChildren.add(_buildPaginationButton(
      icon: Icons.arrow_forward_ios_rounded,
      isEnabled: _currentPage < _totalPages,
      onTap: _nextPage,
    ));

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Halaman $_currentPage dari $_totalPages • ${_allData.length} Total Data',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: pageChildren,
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationButton({
    required IconData icon,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: isEnabled ? _primaryGradient : null,
          color: !isEnabled ? Colors.grey[300] : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isEnabled ? Colors.white : Colors.grey[500],
        ),
      ),
    );
  }

  Widget _buildPageNumber(int pageNumber) {
    final isActive = _currentPage == pageNumber;
    return GestureDetector(
      onTap: () => _goToPage(pageNumber),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: isActive ? _primaryGradient : null,
          color: !isActive ? Colors.transparent : null,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? Colors.transparent : Colors.grey[300]!,
          ),
        ),
        child: Center(
          child: Text(
            '$pageNumber',
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey[700],
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  void updateFilter(String newFilter) {
    if (!mounted) return;

    final newType = newFilter;
    final index = _tabData.indexWhere((tab) => tab['type'] == newType);
    if (index != -1 && index != _currentTab) {
      _handleTabChange(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Manajemen PKL',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              FocusScope.of(context).requestFocus(FocusNode());
              Future.delayed(const Duration(milliseconds: 100), () {
                _searchController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _searchController.text.length),
                );
              });
            },
          ),
          if (_tabData[_currentTab]['hasFilter'] as bool)
            IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.white),
              onPressed: () {
                final currentTabData = _tabData[_currentTab];
                _showFilterDialog(
                  currentTabData['filterType'] as String,
                  currentTabData['filterLabel'] as String,
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          _buildHeaderStats(),
          _buildTabBar(),
          _buildSearchSection(),
          _buildContent(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}