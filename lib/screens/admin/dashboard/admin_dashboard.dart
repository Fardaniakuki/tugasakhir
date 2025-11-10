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
                child: const Text(
                  'Tambah Data Baru',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5B1A1A),
                  ),
                ),
              ),
              _buildAddTile(Icons.school, 'Tambah Murid', 'Siswa'),
              _buildAddTile(Icons.person, 'Tambah Guru', 'Guru'),
              _buildAddTile(Icons.category, 'Tambah Jurusan', 'Jurusan'),
              _buildAddTile(Icons.business, 'Tambah Industri', 'Industri'),
              _buildAddTile(Icons.class_, 'Tambah Kelas', 'Kelas'),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  ListTile _buildAddTile(IconData icon, String title, String type) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF5B1A1A).withAlpha(13),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF5B1A1A)),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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

  // CHART SEDERHANA - Distribusi Data
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

    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics, color: Color(0xFF5B1A1A)),
              SizedBox(width: 8),
              Text(
                'Distribusi Data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5B1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: const Color(0xFF5B1A1A),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final titles = ['Murid', 'Guru', 'Kelas', 'Jurusan', 'Industri'];
                      return BarTooltipItem(
                        '${titles[groupIndex]}\n${rod.toY.toInt()}',
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
                        final titles = ['Murid', 'Guru', 'Kelas', 'Jurusan', 'Industri'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            titles[value.toInt()],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
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
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
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
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: siswaCount.toDouble(),
                        color: const Color(0xFF8B0000),
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: guruCount.toDouble(),
                        color: const Color(0xFFB22222),
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: kelasCount.toDouble(),
                        color: const Color(0xFFDC143C),
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 3,
                    barRods: [
                      BarChartRodData(
                        toY: jurusanCount.toDouble(),
                        color: const Color(0xFFCD5C5C),
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 4,
                    barRods: [
                      BarChartRodData(
                        toY: industriCount.toDouble(),
                        color: const Color(0xFFF08080),
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // STATISTIK RINGKAS
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
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: Color(0xFF5B1A1A)),
              SizedBox(width: 8),
              Text(
                'Statistik Ringkas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5B1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem('Rata Murid/Kelas', _calculateAverageStudentsPerClass(), Icons.people),
              const SizedBox(width: 16),
              _buildStatItem('Rasio Guru:Murid', _calculateTeacherStudentRatio(), Icons.balance),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF5B1A1A).withAlpha(10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat('Murid', siswaCount, Icons.school),
                _buildMiniStat('Guru', guruCount, Icons.person),
                _buildMiniStat('Kelas', kelasCount, Icons.class_),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF5B1A1A).withAlpha(10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF5B1A1A), size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5B1A1A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String title, int value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF5B1A1A), size: 20),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5B1A1A),
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
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

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.all(40.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5B1A1A)),
            ),
            SizedBox(height: 16),
            Text(
              'Memuat data...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Gagal memuat dashboard',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _refreshData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B1A1A),
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF5B1A1A),
        title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: const Color(0xFF5B1A1A),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                
                if (_isLoading && _dashboardData == null)
                  _buildLoading()
                else if (_dashboardData != null) ...[
                  StatGrid(
                    data: _dashboardData!,
                    onAddPressed: _showAddOptions,
                    onBoxTap: _handleStatBoxTap,
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
    );
  }
}