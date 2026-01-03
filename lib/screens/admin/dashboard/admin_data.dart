import 'dart:async';
import 'package:flutter/material.dart';
import 'murid/student_detail_page.dart';
import 'guru/teacher_detail_page.dart';
import 'jurusan/major_detail_page.dart';
import 'industri/industry_detail_page.dart';
import 'kelas/class_detail_page.dart';
import 'dashboard_service.dart';
import 'skeleton_loading.dart'; // Import file skeleton

class AdminData extends StatefulWidget {
  final String? initialFilter;

  const AdminData({super.key, this.initialFilter});

  @override
  State<AdminData> createState() => AdminDataState();
}

class AdminDataState extends State<AdminData> {
  final DashboardService _service = DashboardService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Timer? _debounceTimer;
  bool _isLoading = true;

  // Warna konsisten untuk semua tab
  final Color _primaryColor = const Color(0xFF3B060A);
  
  // Gradasi untuk tombol dan aksen
  static const LinearGradient _primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3B060A),    // Maroon gelap
      Color(0xFF5B1A1A),    // Maroon sedang
    ],
  );
  
  // Gradasi terbalik untuk variasi
  static const LinearGradient _reverseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF5B1A1A),    // Maroon sedang
      Color(0xFF3B060A),    // Maroon gelap
    ],
  );

  // Data untuk tab selector - HAPUS hasFilter dari Jurusan
  final List<Map<String, dynamic>> _tabData = [
    {
      'type': 'Murid',
      'icon': Icons.person,
      'stats': {'total': 0, 'active': 0, 'baru': 0},
      'hasFilter': true,
      'filterType': 'kelas',
      'filterLabel': 'Filter Kelas',
    },
    {
      'type': 'Guru',
      'icon': Icons.school,
      'stats': {'total': 0, 'active': 0, 'baru': 0},
      'hasFilter': false,
    },
    {
      'type': 'Jurusan',
      'icon': Icons.category,
      'stats': {'total': 0, 'active': 0, 'baru': 0},
      'hasFilter': false, // DIUBAH: dari true menjadi false
    },
    {
      'type': 'Industri',
      'icon': Icons.business,
      'stats': {'total': 0, 'active': 0, 'baru': 0},
      'hasFilter': true,
      'filterType': 'jurusan',
      'filterLabel': 'Filter Jurusan',
    },
    {
      'type': 'Kelas',
      'icon': Icons.class_,
      'stats': {'total': 0, 'active': 0, 'baru': 0},
      'hasFilter': true,
      'filterType': 'jurusan',
      'filterLabel': 'Filter Jurusan',
    },
  ];

  int _currentTab = 0;
  String _selectedFilterDisplay = 'Semua';
  String _selectedFilterId = '';
  String _searchQuery = '';

  // Cache untuk data yang sudah di-fetch
  final Map<String, List<Map<String, dynamic>>> _dataCache = {};
  final int _maxCacheSize = 3;

  // Pagination variables
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  int _totalPages = 1;
  List<Map<String, dynamic>> _allData = [];
  List<Map<String, dynamic>> _currentPageData = [];

  // Untuk filter options
  List<Map<String, String>> _availableKelas = [];
  List<Map<String, String>> _availableJurusan = [];

  @override
  void initState() {
    super.initState();

    // Set initial filter jika ada
    if (widget.initialFilter != null) {
      final initialType = _mapFilterToType(widget.initialFilter!);
      final index = _tabData.indexWhere((tab) => tab['type'] == initialType);
      if (index != -1) {
        _currentTab = index;
      }
    }

    _initAll();
    _searchController.addListener(_onSearchChanged);
  }

  String _mapFilterToType(String filter) {
    switch (filter.toLowerCase()) {
      case 'siswa':
      case 'murid':
        return 'Murid';
      case 'guru':
        return 'Guru';
      case 'jurusan':
        return 'Jurusan';
      case 'industri':
        return 'Industri';
      case 'kelas':
        return 'Kelas';
      default:
        return 'Murid';
    }
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

  // ✅ PERBAIKAN: Method untuk reset statistik tab tertentu
  void _resetStatsForTab(int tabIndex) {
    final stats = _tabData[tabIndex]['stats'] as Map<String, dynamic>;
    stats['total'] = 0;
    stats['active'] = 0;
    stats['baru'] = 0;
  }

  Future<void> _initAll() async {
    await Future.wait([
      _fetchKelasOptions(),
      _fetchJurusanOptions(),
    ]);
    await _fetchDataWithCache(_searchQuery);
  }

  Future<void> _fetchKelasOptions() async {
    try {
      final kelasData = await _service.fetchKelas();
      setState(() {
        _availableKelas = kelasData;
      });
    } catch (e) {
      debugPrint('❌ Error fetching kelas options: $e');
      setState(() {
        _availableKelas = [];
      });
    }
  }

  Future<void> _fetchJurusanOptions() async {
    try {
      final jurusanData = await _service.fetchJurusan();
      setState(() {
        _availableJurusan = jurusanData;
      });
    } catch (e) {
      debugPrint('❌ Error fetching jurusan options: $e');
      setState(() {
        _availableJurusan = [];
      });
    }
  }

  Future<void> refreshData() async {
    // Clear cache untuk tab yang sedang aktif
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

    _service.clearCacheByPattern(currentType.toLowerCase());
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

      // ✅ PERBAIKAN: Update statistik juga ketika menggunakan cache
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
        case 'Murid':
          data = await _service.fetchSiswaData(
            searchQuery: query,
            kelasId: _selectedFilterId,
            jurusanId: '',
          );
          break;
        case 'Guru':
          data = await _service.fetchGuruData(searchQuery: query);
          break;
        case 'Jurusan':
          // DIUBAH: Hapus parameter kelasId karena jurusan tidak perlu filter kelas
          data = await _service.fetchJurusanData(searchQuery: query);
          break;
        case 'Industri':
          data = await _service.fetchIndustriData(
            searchQuery: query,
            jurusanId: _selectedFilterId,
          );
          break;
        case 'Kelas':
          data = await _service.fetchKelasData(
            searchQuery: query,
            jurusanId: _selectedFilterId,
          );
          break;
        default:
          data = [];
      }

      // Cache the data
      _dataCache[cacheKey] = data;

      // Update stats
      _updateStats(data);

      _setupPaginationData(data);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Exception fetching ${_tabData[_currentTab]['type']}: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateStats(List<Map<String, dynamic>> data) {
    final currentStats = _tabData[_currentTab]['stats'] as Map<String, dynamic>;
    currentStats['total'] = data.length;
    currentStats['active'] = data.length;
    currentStats['baru'] = data.isNotEmpty ? (data.length * 0.2).round() : 0;
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

    // Scroll ke atas setelah berpindah halaman
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      _goToPage(_currentPage + 1);
    }
  }

  void _previousPage() {
    if (_currentPage > 1) {
      _goToPage(_currentPage - 1);
    }
  }

  String _getCacheKey(String query) {
    final currentType = _tabData[_currentTab]['type'];
    if (_selectedFilterId.isNotEmpty) {
      return '${currentType.toLowerCase()}-$query-$_selectedFilterId';
    }
    return '${currentType.toLowerCase()}-$query';
  }

  void _handleItemTap(Map<String, dynamic> item) async {
    final String itemId = item['id'] ?? '';
    if (itemId.isEmpty) return;

    final currentType = _tabData[_currentTab]['type'];
    Widget? targetPage;

    switch (currentType) {
      case 'Murid':
        targetPage = StudentDetailPage(studentId: itemId);
        break;
      case 'Guru':
        targetPage = TeacherDetailPage(teacherId: itemId);
        break;
      case 'Jurusan':
        targetPage = MajorDetailPage(majorId: itemId);
        break;
      case 'Industri':
        targetPage = IndustryDetailPage(industryId: itemId);
        break;
      case 'Kelas':
        targetPage = ClassDetailPage(classId: itemId);
        break;
    }

    if (targetPage != null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => targetPage!),
      );

      if (!mounted) return;

      if (result != null) {
        if (result['deleted'] == true || result['updated'] == true) {
          // Clear cache untuk type yang berubah
          _clearCacheForCurrentType();
          _resetPagination();

          // Refresh data
          await _fetchDataWithCache(_searchQuery, forceRefresh: true);
        }
      }
    }
  }

  void _handleTabChange(int newIndex) {
    if (newIndex == _currentTab) return;

    setState(() {
      _currentTab = newIndex;
      _searchQuery = '';
      _searchController.text = '';
      
      // PERBAIKAN: Reset filter hanya untuk tab yang memiliki filter
      final newTabData = _tabData[newIndex];
      if (newTabData['hasFilter'] == true) {
        // Tab baru memiliki filter, biarkan filter tetap
        // Tapi cek apakah filter yang ada cocok dengan tipe filter tab baru
        
        // Jika filter aktif tapi tidak cocok dengan tab baru, reset
        if (_selectedFilterId.isNotEmpty) {
          // Misal: filter aktif adalah kelas, tapi tab baru menggunakan filter jurusan
          // Untuk sederhana, kita reset dulu
          // (Bisa juga di-advanced dengan konversi, tapi untuk sekarang reset saja)
          _selectedFilterDisplay = 'Semua';
          _selectedFilterId = '';
        }
      } else {
        // Tab baru tidak memiliki filter, HARUS reset filter
        _selectedFilterDisplay = 'Semua';
        _selectedFilterId = '';
      }
      
      // Reset statistik untuk tab baru
      _resetStatsForTab(newIndex);
    });

    // Reset pagination
    _resetPagination();

    // Cek dulu apakah data sudah ada di cache
    final cacheKey = _getCacheKey('');
    if (_dataCache.containsKey(cacheKey)) {
      // Data ada di cache, langsung pakai tanpa loading
      final cachedData = _dataCache[cacheKey]!;
      _setupPaginationData(cachedData);
      _updateStats(cachedData);
      
      // PERBAIKAN: Jangan set isLoading ke false di sini karena akan bertentangan
      if (_isLoading) {
        setState(() => _isLoading = false);
      }
    } else {
      // Data belum di cache, fetch dengan loading
      if (!_isLoading) {
        setState(() => _isLoading = true);
      }
      _fetchDataWithCache('');
    }
  }

  // HEADER STATS - Menampilkan jumlah data untuk setiap role
  Widget _buildHeaderStats() {
    final currentStats = _tabData[_currentTab]['stats'] as Map<String, dynamic>;
    final currentType = _tabData[_currentTab]['type'];

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
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(currentStats['total'].toString(),
                'Total $currentType', Icons.data_array,
                isPrimary: true),
            const SizedBox(width: 20),
            _buildStatItem(
                currentStats['active'].toString(), 'Aktif', Icons.check_circle,
                isPrimary: false),
            const SizedBox(width: 20),
            _buildStatItem(
                currentStats['baru'].toString(), 'Baru', Icons.new_releases,
                isPrimary: false),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon,
      {bool isPrimary = false}) {
    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: isPrimary
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.4),
                        Colors.white.withValues(alpha: 0.2),
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.3),
                        Colors.white.withValues(alpha: 0.1),
                      ],
                    ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: isPrimary
                  ? [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
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
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper method untuk menghindari deprecated withOpacity
  Color _withOpacity(Color color, double opacity) {
    final int alpha = (opacity * 255).clamp(0, 255).round();
    return color.withAlpha(alpha);
  }

  // TAB BAR - Fixed untuk menghindari overflow
  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: _withOpacity(Colors.grey, 0.1),
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
    
    // PERBAIKAN: Pastikan filter tidak ditampilkan jika tab tidak memiliki filter
    if (!hasFilter && _selectedFilterDisplay != 'Semua') {
      // Reset filter jika tab tidak memiliki filter tapi filter aktif
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _selectFilter('Semua', '');
      });
    }
    
    final String filterType = hasFilter ? currentTabData['filterType'] as String : '';
    final String filterLabel = hasFilter ? currentTabData['filterLabel'] as String : '';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: _withOpacity(Colors.grey, 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText:
                          'Cari ${currentTabData['type'].toString().toLowerCase()}...',
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
              // PERBAIKAN: Filter button hanya ditampilkan jika tab memiliki filter
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
                      boxShadow: _selectedFilterDisplay != 'Semua'
                          ? [
                              BoxShadow(
                                color: const Color(0xFF3B060A).withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: _withOpacity(Colors.grey, 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Stack(
                      children: [
                        Icon(
                          Icons.tune,
                          color: _selectedFilterDisplay != 'Semua'
                              ? Colors.white
                              : _primaryColor,
                          size: 20,
                        ),
                        if (_selectedFilterDisplay != 'Semua')
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withValues(alpha: 0.5),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // PERBAIKAN: Tampilkan filter aktif hanya jika tab memiliki filter
          if (hasFilter && _selectedFilterDisplay != 'Semua')
            Padding(
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
                          _primaryColor.withValues(alpha: 0.1),
                          _primaryColor.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _primaryColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getFilterIcon(filterType),
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
            ),
        ],
      ),
    );
  }

  IconData _getFilterIcon(String filterType) {
    switch (filterType) {
      case 'kelas':
        return Icons.class_rounded;
      case 'jurusan':
        return Icons.category;
      default:
        return Icons.filter_list;
    }
  }

  // FILTER DIALOG YANG LEBIH BAGUS
  void _showFilterDialog(String filterType, String filterLabel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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
              // Header yang lebih stylish
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF3B060A),
                      Color(0xFF5B1A1A),
                      Color(0xFF8B2A2D),
                    ],
                  ),
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
                            Colors.white.withValues(alpha: 0.3),
                            Colors.white.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: const Icon(Icons.filter_list_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            filterLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pilih $filterType untuk memfilter data',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar untuk filter
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari $filterType...',
                      prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      // Implement search functionality if needed
                    },
                  ),
                ),
              ),

              // Filter List dengan design lebih modern
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: _buildFilterList(filterType),
              ),

              // Footer dengan action buttons
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
                        onPressed: () {
                          _selectFilter('Semua', '');
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryColor,
                          side: BorderSide(color: _primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Reset Filter'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                          shadowColor: const Color(0xFF3B060A).withValues(alpha: 0.3),
                        ).copyWith(
                          backgroundColor: WidgetStateProperty.resolveWith<Color>(
                            (Set<WidgetState> states) {
                              if (states.contains(WidgetState.pressed)) {
                                return const Color(0xFF5B1A1A);
                              }
                              return const Color(0xFF3B060A);
                            },
                          ),
                        ),
                        child: const Text('Selesai'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // METHOD BARU untuk build filter list yang lebih bagus
  Widget _buildFilterList(String filterType) {
    final List<Map<String, String>> filterOptions = filterType == 'kelas' 
        ? _availableKelas 
        : _availableJurusan;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        // Opsi Semua dengan design khusus
        _buildEnhancedFilterOption(
          title: 'Semua',
          subtitle: 'Tampilkan semua data',
          isSelected: _selectedFilterDisplay == 'Semua',
          icon: Icons.all_inclusive_rounded,
          iconColor: Colors.blue,
          onTap: () {
            _selectFilter('Semua', '');
            Navigator.pop(context);
          },
        ),

        // Divider dengan text
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Divider(
                  color: Colors.grey[300],
                  thickness: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Daftar $filterType',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: Colors.grey[300],
                  thickness: 1,
                ),
              ),
            ],
          ),
        ),

        // Daftar filter dengan design enhanced
        ...filterOptions.map((item) => _buildEnhancedFilterOption(
              title: item['name']!,
              subtitle: 'Klik untuk memfilter',
              isSelected: _selectedFilterDisplay == item['name'],
              icon: filterType == 'kelas' ? Icons.class_rounded : Icons.category,
              iconColor: _primaryColor,
              onTap: () {
                _selectFilter(item['name']!, item['id']!);
                Navigator.pop(context);
              },
            )),

        // Empty state jika tidak ada filter
        if (filterOptions.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Icon(
                  filterType == 'kelas' ? Icons.class_outlined : Icons.category_outlined,
                  size: 60,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Tidak ada $filterType tersedia',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Data $filterType akan muncul di sini',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
      ],
    );
  }

  // METHOD untuk option filter yang lebih bagus
  Widget _buildEnhancedFilterOption({
    required String title,
    required String subtitle,
    required bool isSelected,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected
          ? _primaryColor.withValues(alpha: 0.08)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? _primaryColor : Colors.transparent,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _primaryColor.withValues(alpha: 0.05),
                      _primaryColor.withValues(alpha: 0.02),
                    ],
                  )
                : null,
          ),
          child: Row(
            children: [
              // Icon dengan background
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? _primaryGradient
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            iconColor.withValues(alpha: 0.15),
                            iconColor.withValues(alpha: 0.05),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _primaryColor.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected ? Colors.white : iconColor,
                ),
              ),

              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isSelected ? _primaryColor : Colors.grey[800],
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isSelected
                            ? _primaryColor.withValues(alpha: 0.8)
                            : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Selection indicator
              if (isSelected)
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: _primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _primaryColor.withValues(alpha: 0.3),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                )
              else
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectFilter(String displayName, String filterId) {
    // PERBAIKAN: Cek apakah tab saat ini memiliki filter
    final currentTabData = _tabData[_currentTab];
    if (currentTabData['hasFilter'] != true) {
      // Tab saat ini tidak memiliki filter, tidak boleh set filter
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

  // CONTENT SECTION - Pagination ikut scroll
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
      // Gunakan skeleton loading dari file terpisah
      return SkeletonLoading(primaryColor: _primaryColor);
    }

    if (_allData.isEmpty) {
      return _buildEmptyState();
    }

    return ListView(
      controller: _scrollController,
      children: [
        // List Data
        Column(
          children: [
            ..._currentPageData.map((item) => _buildDataCard(item)),
            const SizedBox(height: 16),
          ],
        ),

        // Pagination Controls - ikut scroll
        _buildPaginationControls(),
      ],
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
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // DATA CARD - Design premium untuk setiap role (TANPA STATUS AKTIF)
  Widget _buildDataCard(Map<String, dynamic> item) {
    final currentType = _tabData[_currentTab]['type'];
    final String name = item['name'] ?? item['nama'] ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
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
                // Avatar dengan gradient sesuai role
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: _reverseGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B060A).withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    _tabData[_currentTab]['icon'] as IconData,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: _buildCardContent(item, currentType, name),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(
      Map<String, dynamic> item, String currentType, String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hanya nama saja, tanpa status aktif
        Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),

        // Informasi spesifik berdasarkan role
        _buildRoleSpecificInfo(item, currentType),
      ],
    );
  }

  Widget _buildRoleSpecificInfo(Map<String, dynamic> item, String currentType) {
    switch (currentType) {
      case 'Murid':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item['kelas'] != null)
              _buildEnhancedInfoRow(
                Icons.class_outlined,
                item['kelas'],
              ),
            if (item['nisn'] != null)
              _buildEnhancedInfoRow(
                Icons.confirmation_number,
                'NISN: ${item['nisn']}',
              ),
          ],
        );

      case 'Guru':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item['kode_guru'] != null)
              _buildEnhancedInfoRow(
                Icons.badge,
                'Kode: ${item['kode_guru']}',
              ),
            if (item['nisn'] != null) // NIP diambil dari field 'nisn'
              _buildEnhancedInfoRow(
                Icons.credit_card,
                'NIP: ${item['nisn']}',
              ),
          ],
        );

      case 'Jurusan':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PERUBAHAN: Tampilkan nama kaprog jika ada
            if (item['kaprog_nama'] != null && item['kaprog_nama'].isNotEmpty)
              _buildEnhancedInfoRow(
                Icons.person,
                'Kaprog: ${item['kaprog_nama']}',
              )
            else
              _buildEnhancedInfoRow(
                Icons.person,
                'Kaprog: Belum ditentukan',
              ),

            if (item['jumlah_kelas'] != null)
              _buildEnhancedInfoRow(
                Icons.class_,
                '${item['jumlah_kelas']} Kelas',
              ),
          ],
        );

      case 'Industri':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item['bidang'] != null)
              _buildEnhancedInfoRow(
                Icons.business_center,
                item['bidang'],
              ),
            if (item['alamat'] != null)
              _buildEnhancedInfoRow(
                Icons.location_on,
                item['alamat'],
                maxLines: 2,
              ),
          ],
        );

      case 'Kelas':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item['jurusan_nama'] != null)
              _buildEnhancedInfoRow(
                Icons.category,
                item['jurusan_nama'],
              ),
            if (item['jumlah_murid'] != null)
              _buildEnhancedInfoRow(
                Icons.people,
                '${item['jumlah_murid']} Murid',
              ),
          ],
        );

      default:
        return const SizedBox();
    }
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
                  _primaryColor.withValues(alpha: 0.15),
                  _primaryColor.withValues(alpha: 0.05),
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
            children: [
              // Previous Button
              _buildPaginationButton(
                icon: Icons.arrow_back_ios_rounded,
                isEnabled: _currentPage > 1,
                onTap: _previousPage,
              ),

              const SizedBox(width: 12),

              // Page Numbers - Responsif
              if (_totalPages <= 5)
                Row(
                  children: List.generate(_totalPages, (index) {
                    final pageNumber = index + 1;
                    return _buildPageNumber(pageNumber);
                  }),
                )
              else
                Row(
                  children: [
                    _buildPageNumber(1),
                    if (_currentPage > 3)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '...',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (_currentPage > 2 && _currentPage < _totalPages - 1)
                      _buildPageNumber(_currentPage - 1),
                    if (_currentPage > 1 && _currentPage < _totalPages)
                      _buildPageNumber(_currentPage),
                    if (_currentPage < _totalPages - 1)
                      _buildPageNumber(_currentPage + 1),
                    if (_currentPage < _totalPages - 2)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '...',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    _buildPageNumber(_totalPages),
                  ],
                ),

              const SizedBox(width: 12),

              // Next Button
              _buildPaginationButton(
                icon: Icons.arrow_forward_ios_rounded,
                isEnabled: _currentPage < _totalPages,
                onTap: _nextPage,
              ),
            ],
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: isEnabled
              ? _primaryGradient
              : null,
          color: !isEnabled ? Colors.grey[300] : null,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: const Color(0xFF3B060A).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: isActive
              ? _primaryGradient
              : null,
          color: !isActive ? Colors.transparent : null,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? Colors.transparent : Colors.grey[300]!,
            width: isActive ? 0 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF3B060A).withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
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

    final newType = _mapFilterToType(newFilter);
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
          'Data',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: _primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B060A).withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Stats - Menampilkan jumlah data untuk role yang aktif
          _buildHeaderStats(),

          // Tab Bar - Horizontal scroll untuk menghindari overflow
          _buildTabBar(),

          // Search Section - Design lebih compact
          _buildSearchSection(),

          // Content dengan pagination yang ikut scroll
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