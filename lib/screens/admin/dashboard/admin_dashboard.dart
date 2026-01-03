import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dashboard_service.dart';
import 'stat_grid.dart';
import '../crud/add_person_page.dart';

class AdminDashboard extends StatefulWidget {
  final Function(String)? onNavigateToData;
  
  const AdminDashboard({super.key, this.onNavigateToData});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> 
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  
  final DashboardService _service = DashboardService();
  
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  bool _isAppPaused = false;

  // WARNA BARU SESUAI AdminData
  final Color _primaryColor = const Color(0xFF3B060A);
  
  // Gradasi untuk tombol dan aksen (SAMA PERSIS DENGAN AdminData)
  static const LinearGradient _primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3B060A),    // Maroon gelap
      Color(0xFF5B1A1A),    // Maroon sedang
    ],
  );
  
  // Gradasi terbalik untuk variasi (SAMA PERSIS DENGAN AdminData)

  // Warna untuk setiap jenis data (konsisten dengan AdminData)
  final Map<String, Color> _typeColors = {
    'Murid': const Color(0xFF3B060A),
    'Guru': const Color(0xFF5B1A1A),
    'Jurusan': const Color(0xFF8B2A2D),
    'Industri': const Color(0xFFCD5C5C),
    'Kelas': const Color(0xFFF08080),
  };

  // Icon untuk setiap jenis data (SAMA DENGAN AdminData)
  final Map<String, IconData> _typeIcons = {
    'Murid': Icons.person,
    'Guru': Icons.school,
    'Jurusan': Icons.category,
    'Industri': Icons.business,
    'Kelas': Icons.class_,
  };

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDashboard();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _isAppPaused = true;
    } else if (state == AppLifecycleState.resumed && _isAppPaused) {
      _isAppPaused = false;
      _refreshSilently();
    }
  }

  Future<void> _loadDashboard() async {
    if (_dashboardData != null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final cachedData = _service.getCachedData('dashboard');
      if (cachedData != null && mounted) {
        setState(() {
          _dashboardData = cachedData;
          _isLoading = false;
        });
        _fetchDashboardData(silent: true);
        return;
      }

      await _fetchDashboardData();
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchDashboardData({bool silent = false}) async {
    try {
      final data = await _service.fetchDashboardData();
      if (mounted) {
        setState(() {
          _dashboardData = data;
          if (!silent) {
            _isLoading = false;
          }
        });
      }
      
      _service.setCacheData('dashboard', data);
    } catch (e) {
      debugPrint('Error fetching dashboard: $e');
      if (mounted && !silent) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshSilently() async {
    try {
      final data = await _service.fetchDashboardData(forceRefresh: true);
      if (mounted && data != null) {
        setState(() {
          _dashboardData = data;
        });
      }
    } catch (e) {
      debugPrint('Error silent refresh: $e');
    }
  }

  Future<void> _refreshData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    await _fetchDashboardData();
  }

  void _handleStatBoxTap(String type) {
    widget.onNavigateToData?.call(type);
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
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
                            Colors.white.withAlpha(30),
                            Colors.white.withAlpha(10),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withAlpha(20),
                          width: 1,
                        ),
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Tambah Data Baru',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
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
              _buildAddTile(Icons.school, 'Tambah Murid', 'Siswa', _typeColors['Murid']!),
              _buildAddTile(Icons.person, 'Tambah Guru', 'Guru', _typeColors['Guru']!),
              _buildAddTile(Icons.category, 'Tambah Jurusan', 'Jurusan', _typeColors['Jurusan']!),
              _buildAddTile(Icons.business, 'Tambah Industri', 'Industri', _typeColors['Industri']!),
              _buildAddTile(Icons.class_, 'Tambah Kelas', 'Kelas', _typeColors['Kelas']!),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  ListTile _buildAddTile(IconData icon, String title, String type, Color color) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withAlpha(204)], // 0.8 opacity
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white), // ICON PUTIH
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      trailing: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withAlpha(204)],
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.white),
      ),
      onTap: () {
        Navigator.pop(context);
        _navigateToAddPersonPage(type);
      },
    );
  }

  void _navigateToAddPersonPage(String jenisData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPersonPage(jenisData: jenisData),
      ),
    );
  }

  // SIMPLE SKELETON LOADING
  Widget _buildLoading() {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(height: 24),
        
        // Stat Grid Skeleton
        _buildSkeletonContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSkeletonLine(width: 150, height: 20),
                      const SizedBox(height: 8),
                      _buildSkeletonLine(width: 200, height: 14),
                    ],
                  ),
                  _buildSkeletonLine(width: 120, height: 40, borderRadius: 20),
                ],
              ),
              const SizedBox(height: 20),
              
              // Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: List.generate(6, (index) => _buildGridItemSkeleton()),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Chart Skeleton
        _buildSkeletonContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: _primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildSkeletonLine(width: 120, height: 20),
                ],
              ),
              const SizedBox(height: 20),
              _buildSkeletonLine(width: double.infinity, height: 200, borderRadius: 8),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Quick Stats Skeleton
        _buildSkeletonContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: _primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildSkeletonLine(width: 120, height: 20),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _buildStatItemSkeleton()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatItemSkeleton()),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _primaryColor.withAlpha(5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _primaryColor.withAlpha(15),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(3, (index) => _buildMiniStatSkeleton()),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSkeletonContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha:.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withValues(alpha:.1),
          width: 1,
        ),
      ),
      child: child,
    );
  }

  Widget _buildGridItemSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: _primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 12),
          _buildSkeletonLine(width: 80, height: 16),
          const SizedBox(height: 8),
          _buildSkeletonLine(width: 60, height: 20),
          const SizedBox(height: 4),
          _buildSkeletonLine(width: 100, height: 12),
        ],
      ),
    );
  }

  Widget _buildStatItemSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryColor.withAlpha(5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _primaryColor.withAlpha(10),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: _primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 12),
          _buildSkeletonLine(width: 60, height: 20),
          const SizedBox(height: 4),
          _buildSkeletonLine(width: 80, height: 14),
        ],
      ),
    );
  }

  Widget _buildMiniStatSkeleton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            gradient: _primaryGradient,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 8),
        _buildSkeletonLine(width: 30, height: 16),
        const SizedBox(height: 2),
        _buildSkeletonLine(width: 40, height: 12),
      ],
    );
  }

  Widget _buildSkeletonLine({
    required double width,
    required double height,
    double borderRadius = 4,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[300]!,
            Colors.grey[200]!,
          ],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  // CHART SEDERHANA - Distribusi Data DENGAN WARNA BARU DAN ICON KONSISTEN
  Widget _buildSimpleDistributionChart() {
    if (_dashboardData == null) return const SizedBox();

    final siswaCount = _dashboardData!['total_siswa'] ?? 0;
    final guruCount = _dashboardData!['total_guru'] ?? 0;
    final kelasCount = _dashboardData!['total_kelas'] ?? 0;
    final jurusanCount = _dashboardData!['total_jurusan'] ?? 0;
    final industriCount = _dashboardData!['total_industri'] ?? 0;

    final maxValue = [siswaCount, guruCount, kelasCount, jurusanCount, industriCount]
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    // Data untuk bar chart dengan warna dan icon yang sesuai
    final List<ChartData> chartData = [
      ChartData(
        'Murid', 
        siswaCount.toDouble(), 
        _typeIcons['Murid']!,
        _typeColors['Murid']!,
      ),
      ChartData(
        'Guru', 
        guruCount.toDouble(), 
        _typeIcons['Guru']!,
        _typeColors['Guru']!,
      ),
      ChartData(
        'Kelas', 
        kelasCount.toDouble(), 
        _typeIcons['Kelas']!,
        _typeColors['Kelas']!,
      ),
      ChartData(
        'Jurusan', 
        jurusanCount.toDouble(), 
        _typeIcons['Jurusan']!,
        _typeColors['Jurusan']!,
      ),
      ChartData(
        'Industri', 
        industriCount.toDouble(), 
        _typeIcons['Industri']!,
        _typeColors['Industri']!,
      ),
    ];

    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha:.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withValues(alpha:.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: _primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.analytics_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Distribusi Data',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Legend dengan Icon
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: chartData.map((data) => _buildChartLegend(data)).toList(),
            ),
          ),
          
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: _primaryColor,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final data = chartData[groupIndex];
                      return BarTooltipItem(
                        '${data.label}\n${rod.toY.toInt()}',
                        const TextStyle(color: Colors.white),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            chartData[value.toInt()].label,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: chartData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: data.value,
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            data.color,
                            data.color.withAlpha(178), // 0.7 opacity
                          ],
                        ),
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend(ChartData data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: data.color.withAlpha(10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: data.color.withAlpha(20),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [data.color, data.color.withAlpha(204)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, size: 12, color: Colors.white),
          ),
          const SizedBox(width: 6),
          Text(
            data.label,
            style: TextStyle(
              fontSize: 12,
              color: data.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // STATISTIK RINGKAS DENGAN DESIGN BARU DAN ICON KONSISTEN
  Widget _buildQuickStats() {
    if (_dashboardData == null) return const SizedBox();

    final siswaCount = _dashboardData!['total_siswa'] ?? 0;
    final guruCount = _dashboardData!['total_guru'] ?? 0;
    final kelasCount = _dashboardData!['total_kelas'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha:.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withValues(alpha:.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: _primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.trending_up_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Statistik Ringkas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildStatItem(
                'Rata Murid/Kelas', 
                _calculateAverageStudentsPerClass(), 
                Icons.people_rounded,
                _typeColors['Murid']!,
              )),
              const SizedBox(width: 16),
              Expanded(child: _buildStatItem(
                'Rasio Guru:Murid', 
                _calculateTeacherStudentRatio(), 
                Icons.balance_rounded,
                _typeColors['Guru']!,
              )),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _primaryColor.withAlpha(10),
                  _primaryColor.withAlpha(5),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _primaryColor.withAlpha(15),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat('Murid', siswaCount, Icons.school_rounded, _typeColors['Murid']!),
                _buildMiniStat('Guru', guruCount, Icons.person_rounded, _typeColors['Guru']!),
                _buildMiniStat('Kelas', kelasCount, Icons.class_rounded, _typeColors['Kelas']!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withAlpha(10),
            color.withAlpha(5),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withAlpha(15),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withAlpha(204)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 12),
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
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String title, int value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withAlpha(204)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(76), // 0.3 opacity
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: color.withAlpha(204), // 0.8 opacity
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _calculateAverageStudentsPerClass() {
    if (_dashboardData == null) return '-';
    final siswaCount = _dashboardData!['total_siswa'] ?? 0;
    final kelasCount = _dashboardData!['total_kelas'] ?? 0;
    
    if (kelasCount == 0) return '0';
    final average = (siswaCount / kelasCount).round();
    return average.toString();
  }

  String _calculateTeacherStudentRatio() {
    if (_dashboardData == null) return '-';
    final siswaCount = _dashboardData!['total_siswa'] ?? 0;
    final guruCount = _dashboardData!['total_guru'] ?? 0;
    
    if (guruCount == 0) return '-';
    final ratio = (siswaCount / guruCount).round();
    return '1:$ratio';
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha:.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _primaryColor.withAlpha(10),
                  _primaryColor.withAlpha(5),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Gagal memuat dashboard',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Silakan coba lagi beberapa saat',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _refreshData,
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ).copyWith(
              backgroundColor: WidgetStateProperty.resolveWith<Color>(
                (Set<WidgetState> states) {
                  if (states.contains(WidgetState.pressed)) {
                    return const Color(0xFF5B1A1A);
                  }
                  return _primaryColor;
                },
              ),
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: _primaryColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: _primaryColor,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header dengan warna maroon yang ikut discroll
              SliverAppBar(
                backgroundColor: _primaryColor,
                expandedHeight: 63,
                floating: false,
                pinned: true,
                flexibleSpace: const FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: EdgeInsets.only(left: 16, bottom: 16),
                  expandedTitleScale: 1.0,
                  title: Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withAlpha(51), // 0.2 opacity
                          Colors.white.withAlpha(25), // 0.1 opacity
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                      onPressed: _refreshData,
                    ),
                  ),
                ],
              ),
              
              // Konten utama dalam container putih
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(13), // 0.05 opacity
                        blurRadius: 20,
                        offset: const Offset(0, -10),
                      ),
                    ],
                  ),
                  child: _isLoading && _dashboardData == null
                      ? _buildLoading()
                      : Padding(
                          padding: const EdgeInsets.only(
                            top: 24,
                            bottom: 20,
                            left: 16,
                            right: 16,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_dashboardData != null) ...[
                                // StatGrid dengan warna yang konsisten
                                StatGrid(
                                  data: _dashboardData!,
                                  onAddPressed: _showAddOptions,
                                  onBoxTap: _handleStatBoxTap, typeColors: const {},
                                ),
                                
                                // CHART SEDERHANA & STATISTIK
                                _buildSimpleDistributionChart(),
                                _buildQuickStats(),
                                
                                const SizedBox(height: 20),
                              ]
                              else
                                _buildError(),
                            ],
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

// Class helper untuk data chart
class ChartData {
  final String label;
  final double value;
  final IconData icon;
  final Color color;

  ChartData(this.label, this.value, this.icon, this.color);
}