import 'dart:async';
import 'package:flutter/material.dart';
import 'murid/student_detail_page.dart';
import 'guru/teacher_detail_page.dart';
import 'jurusan/major_detail_page.dart';
import 'industri/industry_detail_page.dart';
import 'kelas/class_detail_page.dart';
import 'dashboard_service.dart';

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
  final Color _primaryColor = const Color(0xFF641E20);
  
  // Data untuk tab selector
  final List<Map<String, dynamic>> _tabData = [
    {
      'type': 'Murid',
      'icon': Icons.person,
      'stats': {'total': 0, 'active': 0, 'baru': 0}
    },
    {
      'type': 'Guru', 
      'icon': Icons.school,
      'stats': {'total': 0, 'active': 0, 'baru': 0}
    },
    {
      'type': 'Jurusan',
      'icon': Icons.category,
      'stats': {'total': 0, 'active': 0, 'baru': 0}
    },
    {
      'type': 'Industri',
      'icon': Icons.business,
      'stats': {'total': 0, 'active': 0, 'baru': 0}
    },
    {
      'type': 'Kelas',
      'icon': Icons.class_,
      'stats': {'total': 0, 'active': 0, 'baru': 0}
    },
  ];

  int _currentTab = 0;
  String _selectedKelasDisplay = 'Semua Kelas';
  String _selectedKelasId = '';
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

  // Untuk filter kelas
  List<Map<String, String>> _availableKelas = [];

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
    final keysToRemove = _dataCache.keys.where(
      (key) => key.startsWith('${currentType.toLowerCase()}-')
    ).toList();
    
    for (final key in keysToRemove) {
      _dataCache.remove(key);
    }
    
    _service.clearCacheByPattern(currentType.toLowerCase());
  }

  void _cleanCacheIfNeeded() {
    final currentType = _tabData[_currentTab]['type'];
    final currentTypeKeys = _dataCache.keys.where(
      (key) => key.startsWith('${currentType.toLowerCase()}-')
    ).toList();
    
    if (currentTypeKeys.length > _maxCacheSize) {
      _dataCache.remove(currentTypeKeys.first);
    }
  }

  Future<void> _fetchDataWithCache(String query, {bool forceRefresh = false}) async {
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
            kelasId: _selectedKelasId,
            jurusanId: '',
          );
          break;
        case 'Guru':
          data = await _service.fetchGuruData(searchQuery: query);
          break;
        case 'Jurusan':
          data = await _service.fetchJurusanData(searchQuery: query);
          break;
        case 'Industri':
          data = await _service.fetchIndustriData(searchQuery: query);
          break;
        case 'Kelas':
          data = await _service.fetchKelasData(searchQuery: query);
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
    if (currentType == 'Murid') {
      return '${currentType.toLowerCase()}-$query-$_selectedKelasId';
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

  // ✅ PERBAIKAN: Method _handleTabChange yang sudah diperbaiki
  void _handleTabChange(int newIndex) {
    if (newIndex == _currentTab) return;
    
    setState(() {
      _currentTab = newIndex;
      _selectedKelasDisplay = 'Semua Kelas';
      _selectedKelasId = '';
      _searchQuery = '';
      _searchController.text = '';
      
      // ✅ PERBAIKAN: Reset statistik untuk tab baru
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
      
      // ✅ PERBAIKAN: Update statistik dengan data cache
      _updateStats(cachedData);
    } else {
      // Data belum di cache, fetch dengan loading
      setState(() => _isLoading = true);
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
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              currentStats['total'].toString(), 
              'Total $currentType', 
              Icons.data_array,
              isPrimary: true
            ),
            const SizedBox(width: 20),
            _buildStatItem(
              currentStats['active'].toString(), 
              'Aktif', 
              Icons.check_circle,
              isPrimary: false
            ),
            const SizedBox(width: 20),
            _buildStatItem(
              currentStats['baru'].toString(), 
              'Baru', 
              Icons.new_releases,
              isPrimary: false
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, {bool isPrimary = false}) {
    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isPrimary ? _withOpacity(Colors.white, 0.3) : _withOpacity(Colors.white, 0.2),
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
            style: TextStyle(
              fontSize: 12,
              color: _withOpacity(Colors.white, 0.9),
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
              return _buildDataTab(tab['type'] as String, tab['icon'] as IconData, index);
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
              Icon(
                icon,
                size: 18,
                color: isSelected ? _primaryColor : Colors.grey,
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

  // SEARCH SECTION - Fixed untuk menghindari overflow
  Widget _buildSearchSection() {
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
                      hintText: 'Cari ${_tabData[_currentTab]['type'].toString().toLowerCase()}...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Filter button hanya untuk Murid
              if (_tabData[_currentTab]['type'] == 'Murid')
                GestureDetector(
                  onTap: _showKelasFilterDialog,
                  child: Container(
                    width: 48,
                    height: 48,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: _selectedKelasDisplay != 'Semua Kelas'
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _primaryColor,
                                const Color(0xFF8B2A2D),
                              ],
                            )
                          : null,
                      color: _selectedKelasDisplay == 'Semua Kelas' ? Colors.white : null,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
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
                          color: _selectedKelasDisplay != 'Semua Kelas' 
                              ? Colors.white 
                              : _primaryColor,
                          size: 20,
                        ),
                        if (_selectedKelasDisplay != 'Semua Kelas')
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          
          // Tampilkan filter aktif jika ada
          if (_tabData[_currentTab]['type'] == 'Murid' && _selectedKelasDisplay != 'Semua Kelas')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _primaryColor.withValues(alpha: 0.1),
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
                          Icons.class_rounded,
                          size: 14,
                          color: _primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _selectedKelasDisplay,
                          style: TextStyle(
                            color: _primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            _selectKelas('Semua Kelas', '');
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

  // FILTER KELAS DIALOG YANG LEBIH BAGUS
  void _showKelasFilterDialog() {
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
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _primaryColor,
                      const Color(0xFF8B2A2D),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
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
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.filter_list_rounded, 
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Filter Kelas',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pilih kelas untuk memfilter data murid',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
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
              
              // Search Bar untuk kelas
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
                      hintText: 'Cari kelas...',
                      prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      // Implement search functionality if needed
                    },
                  ),
                ),
              ),
              
              // Kelas List dengan design lebih modern
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: _buildKelasList(),
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
                          _selectKelas('Semua Kelas', '');
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
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                          shadowColor: _primaryColor.withValues(alpha: 0.3),
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

  // METHOD BARU untuk build kelas list yang lebih bagus
  Widget _buildKelasList() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        // Opsi Semua Kelas dengan design khusus
        _buildEnhancedKelasOption(
          title: 'Semua Kelas',
          subtitle: 'Tampilkan semua murid',
          isSelected: _selectedKelasDisplay == 'Semua Kelas',
          icon: Icons.all_inclusive_rounded,
          iconColor: Colors.blue,
          onTap: () {
            _selectKelas('Semua Kelas', '');
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
                  'Daftar Kelas',
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
        
        // Daftar kelas dengan design enhanced
        ..._availableKelas.map((kelas) => 
          _buildEnhancedKelasOption(
            title: kelas['name']!,
            subtitle: 'Klik untuk memfilter',
            isSelected: _selectedKelasDisplay == kelas['name'],
            icon: Icons.class_rounded,
            iconColor: _primaryColor,
            onTap: () {
              _selectKelas(kelas['name']!, kelas['id']!);
              Navigator.pop(context);
            },
          )
        ),
        
        // Empty state jika tidak ada kelas
        if (_availableKelas.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Icon(
                  Icons.class_outlined,
                  size: 60,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Tidak ada kelas tersedia',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Data kelas akan muncul di sini',
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

  // METHOD BARU untuk option kelas yang lebih bagus
  Widget _buildEnhancedKelasOption({
    required String title,
    required String subtitle,
    required bool isSelected,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? _primaryColor.withValues(alpha: 0.08) : Colors.transparent,
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
            color: isSelected ? _primaryColor.withValues(alpha: 0.05) : Colors.transparent,
          ),
          child: Row(
            children: [
              // Icon dengan background
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? _primaryColor : iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
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
                        color: isSelected ? _primaryColor.withValues(alpha: 0.8) : Colors.grey[600],
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
                    color: _primaryColor,
                    shape: BoxShape.circle,
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

  void _selectKelas(String displayName, String kelasId) {
    setState(() {
      _selectedKelasDisplay = displayName;
      _selectedKelasId = kelasId;
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
      return _buildSkeletonLoading();
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

  // SKELETON LOADING - Ditambahkan
  Widget _buildSkeletonLoading() {
    return ListView.builder(
      itemCount: 6, // Jumlah skeleton items
      itemBuilder: (context, index) {
        return _buildSkeletonCard();
      },
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: _withOpacity(Colors.grey, 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Skeleton Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 16),
            
            // Skeleton Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Skeleton Title
                  Container(
                    width: double.infinity,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Skeleton Info Rows
                  Container(
                    width: 150,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
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
      ),
    );
  }

  Widget _buildEmptyState() {
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
              'Coba ubah pencarian atau filter yang berbeda',
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
            color: _withOpacity(Colors.grey, 0.1),
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
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _withOpacity(_primaryColor, 0.8),
                        _primaryColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _withOpacity(_primaryColor, 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
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

  Widget _buildCardContent(Map<String, dynamic> item, String currentType, String name) {
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
            _buildEnhancedInfoRow(
              Icons.class_outlined,
              item['kelas'] ?? 'Kelas tidak tersedia',
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
            if (item['kode'] != null)
              _buildEnhancedInfoRow(
                Icons.code,
                'Kode: ${item['kode']}',
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
              color: _withOpacity(_primaryColor, 0.1),
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
          color: isEnabled ? _primaryColor : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
          boxShadow: isEnabled ? [
            BoxShadow(
              color: _withOpacity(_primaryColor, 0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ] : null,
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
          color: isActive ? _primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? _primaryColor : Colors.grey[300]!,
            width: isActive ? 0 : 1,
          ),
          boxShadow: isActive ? [
            BoxShadow(
              color: _withOpacity(_primaryColor, 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ] : null,
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
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: refreshData,
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