import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../login/login_screen.dart';

class PembimbingDashboard extends StatefulWidget {
  const PembimbingDashboard({super.key});

  @override
  State<PembimbingDashboard> createState() => _PembimbingDashboardState();
}

class _PembimbingDashboardState extends State<PembimbingDashboard> {
  // Neo Brutalism Colors
  final Color _primaryColor = const Color(0xFFE71543);
  final Color _secondaryColor = const Color(0xFFE6E3E3);
  final Color _accentColor = const Color(0xFFA8DADC);
  final Color _darkColor = const Color(0xFF1D3557);
  final Color _yellowColor = const Color(0xFFFFB703);
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

  // Mock data
  List<Map<String, dynamic>> _siswaList = [];
  List<Map<String, dynamic>> _permasalahanList = [];
  List<Map<String, dynamic>> _ijinList = [];
  List<Map<String, dynamic>> _recentActivities = [];

  // Bottom bar state
  int _selectedIndex = 0;
  bool _isBottomBarVisible = true;
  Timer? _scrollTimer;
  bool _isKeyboardVisible = false;

  // Pages for bottom navigation
  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _loadMockData();

    // Initialize pages
    _pages.addAll([
      _buildDashboardPage(), // Index 0: Dashboard
      _buildUploadPage(), // Index 1: Upload
      _buildMasalahIjinPage(), // Index 2: Masalah & Ijin (gabungan)
      _buildPengaturanPage(), // Index 3: Pengaturan
    ]);

    _showBottomBar();
    _setupKeyboardListener();
  }

  void _setupKeyboardListener() {
    WidgetsBinding.instance.addObserver(
      LifecycleEventHandler(
        onMetricsChanged: () {
          final newKeyboardVisible =
              MediaQuery.of(context).viewInsets.bottom > 0;
          if (newKeyboardVisible != _isKeyboardVisible) {
            setState(() {
              _isKeyboardVisible = newKeyboardVisible;
            });

            if (_isKeyboardVisible) {
              _hideBottomBar();
            } else {
              _showBottomBar();
            }
          }
        },
      ),
    );
  }

  void _showBottomBar() {
    if (!_isBottomBarVisible && !_isKeyboardVisible) {
      setState(() {
        _isBottomBarVisible = true;
      });
    }
  }

  void _hideBottomBar() {
    if (_isKeyboardVisible || _isBottomBarVisible) {
      setState(() {
        _isBottomBarVisible = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _showBottomBar();
  }

  Widget _buildDashboardPage() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildHeader(),
          _buildMainMenu(),
        ],
      ),
    );
  }

  Widget _buildUploadPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _primaryColor,
              border: Border.all(color: _blackColor, width: 3),
              boxShadow: const [_heavyShadow],
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'UPLOAD LAPORAN',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildUploadCard('Laporan Harian', Icons.assignment,
              'Unggah laporan harian siswa'),
          _buildUploadCard('Laporan Mingguan', Icons.assignment_turned_in,
              'Unggah laporan mingguan'),
          _buildUploadCard(
              'Bukti Monitoring', Icons.photo_camera, 'Unggah foto kunjungan'),
          _buildUploadCard(
              'Dokumen Pendukung', Icons.folder, 'Unggah dokumen lainnya'),
        ],
      ),
    );
  }

  Widget _buildMasalahIjinPage() {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _secondaryColor,
        body: Container(
          decoration: BoxDecoration(
            border: Border.all(color: _blackColor, width: 4),
          ),
          child: Column(
            children: [
              // HEADER - NEO BRUTALISM
              Container(
                padding: const EdgeInsets.only(
                    top: 40, left: 20, right: 20, bottom: 16),
                decoration: BoxDecoration(
                  color: _primaryColor,
                  border: Border(
                    bottom: BorderSide(color: _blackColor, width: 4),
                  ),
                  boxShadow: const [_heavyShadow],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'MASALAH & IJIN',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1.5,
                          ),
                        ),
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: _yellowColor,
                            border: Border.all(color: _blackColor, width: 3),
                            shape: BoxShape.circle,
                            boxShadow: const [_heavyShadow],
                          ),
                          child: const Icon(Icons.filter_list,
                              color: Colors.black),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // TABS - NEO BRUTALISM
                    Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: _darkColor,
                        border: Border.all(color: _blackColor, width: 3),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [_heavyShadow],
                      ),
                      child: TabBar(
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white70,
                        indicatorColor: Colors.transparent,
                        labelStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                        tabs: [
                          Tab(
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: _primaryColor,
                                border:
                                    Border.all(color: _blackColor, width: 2),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [_heavyShadow],
                              ),
                              child: const Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.report_problem, size: 20),
                                    SizedBox(width: 8),
                                    Text('MASALAH'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Tab(
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1D3557),
                                border:
                                    Border.all(color: _blackColor, width: 2),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [_heavyShadow],
                              ),
                              child: const Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.event_available, size: 20),
                                    SizedBox(width: 8),
                                    Text('IJIN'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: TabBarView(
                  children: [
                    // MASALAH PAGE - EXTREME NEO BRUTALISM
                    Container(
                      decoration: BoxDecoration(
                        color: _secondaryColor,
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // SEARCH BAR - BRUTAL
                            Container(
                              height: 70,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border:
                                    Border.all(color: _blackColor, width: 4),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [_heavyShadow],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: _primaryColor,
                                      border: Border.all(
                                          color: _blackColor, width: 3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.search,
                                        color: Colors.white),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      'CARI MASALAH...',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: _blackColor,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // STATS CARDS - BLOCKY
                            Container(
                              height: 135,
                              margin: const EdgeInsets.only(bottom: 20),
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  _buildBrutalStatsCard(
                                    '${_permasalahanList.length}',
                                    'TOTAL',
                                    Icons.list,
                                    _primaryColor,
                                  ),
                                  const SizedBox(width: 16),
                                  _buildBrutalStatsCard(
                                    '${_permasalahanList.where((m) => m['status'] == 'Belum Ditangani').length}',
                                    'BELUM',
                                    Icons.warning,
                                    const Color(0xFFFFB703),
                                  ),
                                  const SizedBox(width: 16),
                                  _buildBrutalStatsCard(
                                    '${_permasalahanList.where((m) => m['status'] == 'Sedang').length}',
                                    'PROSES',
                                    Icons.access_time,
                                    const Color(0xFF06D6A0),
                                  ),
                                ],
                              ),
                            ),

                            // MASALAH LIST
                            ..._permasalahanList.map(
                                (masalah) => _buildBrutalMasalahCard(masalah)),

                            if (_permasalahanList.isEmpty)
                              Container(
                                height: 300,
                                margin: const EdgeInsets.only(top: 40),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border:
                                      Border.all(color: _blackColor, width: 4),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: const [_heavyShadow],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: _yellowColor,
                                        border: Border.all(
                                            color: _blackColor, width: 4),
                                        shape: BoxShape.circle,
                                        boxShadow: const [_heavyShadow],
                                      ),
                                      child: const Icon(Icons.check,
                                          size: 50, color: Colors.black),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'TIDAK ADA MASALAH!',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        color: _blackColor,
                                        letterSpacing: -1,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Semua berjalan lancar 👍',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: _darkColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // IJIN PAGE - EXTREME NEO BRUTALISM
                    Container(
                      decoration: BoxDecoration(
                        color: _secondaryColor,
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // IJIN STATS - BIG BLOCKS
                            Container(
                              height: 145,
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border:
                                    Border.all(color: _blackColor, width: 4),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [_heavyShadow],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildBrutalIjinStat(
                                      '${_ijinList.where((i) => i['status'] == 'Pending').length}',
                                      'PENDING',
                                      const Color(0xFFFFB703),
                                    ),
                                  ),
                                  Container(
                                    width: 4,
                                    color: _blackColor,
                                  ),
                                  Expanded(
                                    child: _buildBrutalIjinStat(
                                      '${_ijinList.where((i) => i['status'] == 'Disetuju').length}',
                                      'DISETUJU',
                                      const Color(0xFF06D6A0),
                                    ),
                                  ),
                                  Container(
                                    width: 4,
                                    color: _blackColor,
                                  ),
                                  Expanded(
                                    child: _buildBrutalIjinStat(
                                      '${_ijinList.where((i) => i['status'] == 'Ditolak').length}',
                                      'DITOLAK',
                                      _primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // SORT BAR - BRUTAL
                            Container(
                              height: 70,
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: _darkColor,
                                border:
                                    Border.all(color: _blackColor, width: 4),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [_heavyShadow],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      child: const Text(
                                        'SORT: TERBARU ⬇️',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 60,
                                    decoration: BoxDecoration(
                                      color: _primaryColor,
                                      border: Border.all(
                                          color: _blackColor, width: 3),
                                    ),
                                    child: const Icon(Icons.sort,
                                        color: Colors.white, size: 30),
                                  ),
                                ],
                              ),
                            ),

                            // IJIN LIST
                            ..._ijinList
                                .map((ijin) => _buildBrutalIjinCard(ijin)),

                            if (_ijinList.isEmpty)
                              Container(
                                height: 300,
                                margin: const EdgeInsets.only(top: 40),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border:
                                      Border.all(color: _blackColor, width: 4),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: const [_heavyShadow],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF06D6A0),
                                        border: Border.all(
                                            color: _blackColor, width: 4),
                                        shape: BoxShape.circle,
                                        boxShadow: const [_heavyShadow],
                                      ),
                                      child: const Icon(Icons.event_available,
                                          size: 50, color: Colors.black),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'TIDAK ADA IJIN!',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        color: _blackColor,
                                        letterSpacing: -1,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Semua siswa hadir 💪',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: _darkColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
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
    );
  }

  Widget _buildBrutalStatsCard(
      String value, String label, IconData icon, Color color) {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: _blackColor, width: 4),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [_heavyShadow],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -10,
            right: -10,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: _blackColor, width: 3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrutalIjinStat(String count, String status, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: _blackColor, width: 3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBrutalMasalahCard(Map<String, dynamic> masalah) {
    final priorityColor = masalah['priority'] == 'Tinggi'
        ? const Color(0xFFFFB703)
        : masalah['priority'] == 'Sedang'
            ? const Color(0xFFA8DADC)
            : const Color(0xFF06D6A0);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _blackColor, width: 4),
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [_heavyShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER - BIG AND BOLD
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _darkColor,
              border: Border(
                bottom: BorderSide(color: _blackColor, width: 4),
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(21),
                topRight: Radius.circular(21),
              ),
            ),
            child: Row(
              children: [
                // PRIORITY BADGE
                Container(
                  width: 80,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: priorityColor,
                    border: Border.all(color: _blackColor, width: 3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.priority_high,
                        size: 16,
                        color: Colors.black,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        masalah['priority'],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        masalah['title'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.8,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person,
                              size: 16, color: Colors.white70),
                          const SizedBox(width: 6),
                          Text(
                            masalah['siswa_nama'],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // STATUS CIRCLE
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: masalah['status'] == 'Belum Ditangani'
                        ? _primaryColor
                        : const Color(0xFF06D6A0),
                    border: Border.all(color: _blackColor, width: 3),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      masalah['status'] == 'Belum Ditangani' ? '!' : '✓',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // CONTENT
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // DESCRIPTION
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _secondaryColor,
                    border: Border.all(color: _blackColor, width: 3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    masalah['description'],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _darkColor,
                      height: 1.4,
                    ),
                  ),
                ),

                // FOOTER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _accentColor,
                        border: Border.all(color: _blackColor, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 16, color: _darkColor),
                          const SizedBox(width: 8),
                          Text(
                            masalah['date'],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _darkColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        border: Border.all(color: _blackColor, width: 3),
                        shape: BoxShape.circle,
                        boxShadow: const [_heavyShadow],
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrutalIjinCard(Map<String, dynamic> ijin) {
    final statusColor = ijin['status'] == 'Pending'
        ? const Color(0xFFFFB703)
        : ijin['status'] == 'Disetujui'
            ? const Color(0xFF06D6A0)
            : _primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _blackColor, width: 4),
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [_heavyShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // STUDENT HEADER - BOLD
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _darkColor,
              border: Border(
                bottom: BorderSide(color: _blackColor, width: 4),
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(21),
                topRight: Radius.circular(21),
              ),
            ),
            child: Row(
              children: [
                // STUDENT AVATAR - BIG CIRCLE
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    border: Border.all(color: _blackColor, width: 3),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      ijin['siswa_nama'].split(' ').map((n) => n[0]).join(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ijin['siswa_nama'],
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const Text(
                        'Permohonan Ijin',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                // STATUS PILL
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: statusColor,
                    border: Border.all(color: _blackColor, width: 3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    ijin['status'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // DETAILS - BLOCK LAYOUT
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // REASON - BIG CARD
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: _secondaryColor,
                    border: Border.all(color: _blackColor, width: 3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _primaryColor,
                              border: Border.all(color: _blackColor, width: 2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.info,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'ALASAN',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: _blackColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        ijin['alasan'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _darkColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // DETAILS GRID - BLOCKY
                Container(
                  height: 100,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: _accentColor,
                    border: Border.all(color: _blackColor, width: 3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(color: _blackColor, width: 3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'TANGGAL',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: _darkColor,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                ijin['tanggal'],
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: _blackColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'DURASI',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: _darkColor,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                ijin['durasi'],
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: _blackColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ACTION BUTTONS - BIG AND BOLD
                if (ijin['status'] == 'Pending')
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 70,
                          decoration: BoxDecoration(
                            color: const Color(0xFF06D6A0),
                            border: Border.all(color: _blackColor, width: 4),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [_heavyShadow],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border:
                                      Border.all(color: _blackColor, width: 2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check,
                                    color: Colors.black, size: 24),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'SETUJU',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          height: 70,
                          decoration: BoxDecoration(
                            color: _primaryColor,
                            border: Border.all(color: _blackColor, width: 4),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [_heavyShadow],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border:
                                      Border.all(color: _blackColor, width: 2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    color: Colors.black, size: 24),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'TOLAK',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Container(
                    height: 70,
                    decoration: BoxDecoration(
                      color: _darkColor,
                      border: Border.all(color: _blackColor, width: 4),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [_heavyShadow],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: _blackColor, width: 2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.delete,
                              color: Colors.black, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'HAPUS IZIN',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1,
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

  Widget _buildPengaturanPage() {
    const Color borderColor = Colors.black;
    const double borderThickness = 3.0;
    const double circleShadowOffset = 4.0;

    return Scaffold(
      backgroundColor: _darkColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header dengan tombol kembali
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: const Row(
                children: [
                 
                  SizedBox(width: 12),
                  Text(
                    'PENGATURAN PEMBIMBING',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),

            // Konten Utama
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(40)),
                  border:
                      Border.all(color: borderColor, width: borderThickness),
                  boxShadow: const [
                    BoxShadow(
                      color: borderColor,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    children: [
                      // Profile Section
                      Container(
                        margin: const EdgeInsets.only(top: 20, bottom: 30),
                        child: Column(
                          children: [
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _primaryColor,
                                border: Border.all(
                                    color: borderColor,
                                    width: borderThickness),
                                boxShadow: const [
                                  BoxShadow(
                                    color: borderColor,
                                    blurRadius: 0,
                                    offset: Offset(circleShadowOffset,
                                        circleShadowOffset),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.work_rounded,
                                size: 60,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Column(
                              children: [
                                const Text(
                                  'PEMBIMBING INDUSTRI',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                    letterSpacing: 1,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _yellowColor,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: borderColor,
                                        width: borderThickness),
                                  ),
                                  child: const Text(
                                    'MONITORING & BIMBINGAN',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Menu Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ..._buildMenuSection(
                            items: [
                              _buildMenuCard(
                                icon: Icons.help_outline_rounded,
                                title: 'BANTUAN & PANDUAN',
                                subtitle: 'Cara menggunakan aplikasi',
                                iconColor: const Color(0xFF795548),
                                onTap: () {
                                  _showUnderDevelopment('Bantuan & Panduan');
                                },
                              ),
                              _buildMenuCard(
                                icon: Icons.info_outline_rounded,
                                title: 'TENTANG APLIKASI',
                                subtitle: 'Versi & informasi aplikasi',
                                iconColor: const Color(0xFF607D8B),
                                onTap: () {
                                  _showAboutDialog();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Logout Button
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: borderColor,
                              offset: Offset(
                                  circleShadowOffset, circleShadowOffset),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => _logout(context),
                          icon: const Icon(Icons.logout_rounded, size: 22),
                          label: const Text(
                            'KELUAR DARI APLIKASI',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE63946),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(
                                  color: borderColor, width: borderThickness),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMenuSection({
    required List<Widget> items,
  }) {
    return items;
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    const Color borderColor = Colors.black;
    const double borderThickness = 3.0;
    const double circleShadowOffset = 4.0;
    const Color primaryColor = Color(0xFFE71543);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: borderColor,
                width: borderThickness,
              ),
              boxShadow: const [
                BoxShadow(
                  color: borderColor,
                  blurRadius: 0,
                  offset: Offset(circleShadowOffset, circleShadowOffset),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: borderColor, width: borderThickness),
                    boxShadow: const [
                      BoxShadow(
                        color: borderColor,
                        offset:
                            Offset(circleShadowOffset, circleShadowOffset),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: borderColor, width: borderThickness),
                    boxShadow: const [
                      BoxShadow(
                        color: borderColor,
                        offset:
                            Offset(circleShadowOffset, circleShadowOffset),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUnderDevelopment(String featureName) {
    const Color borderColor = Colors.black;
    const double borderThickness = 3.0;
    const Color primaryColor = Color(0xFFE71543);
    const Color yellowColor = Color(0xFFFFB703);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: borderColor, width: borderThickness),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: borderColor,
                offset: Offset(4, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: yellowColor,
                  border:
                      Border.all(color: borderColor, width: borderThickness),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.construction,
                  color: Colors.black,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'FITUR DALAM PENGEMBANGAN',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '$featureName sedang dalam tahap pengembangan dan akan segera hadir.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: primaryColor,
                  border:
                      Border.all(color: borderColor, width: borderThickness),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: const Text(
                    'MENGERTI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
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

  void _showAboutDialog() {
    const Color borderColor = Colors.black;
    const double borderThickness = 3.0;
    const Color primaryColor = Color(0xFFE71543);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: borderColor, width: borderThickness),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: borderColor,
                offset: Offset(4, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: primaryColor,
                  border:
                      Border.all(color: borderColor, width: borderThickness),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'TENTANG APLIKASI',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'SISFO PKL - PEMBIMBING',
                style: TextStyle(
                  fontSize: 16,
                  color: primaryColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Versi: 1.0.0\nBuild: 2024.01',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Aplikasi untuk monitoring dan bimbingan siswa PKL bagi Pembimbing',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: primaryColor,
                  border:
                      Border.all(color: borderColor, width: borderThickness),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: const Text(
                    'TUTUP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
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

  Widget _buildUploadCard(String title, IconData icon, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _secondaryColor,
        border: Border.all(color: _blackColor, width: 3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [_lightShadow],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _primaryColor,
              border: Border.all(color: _blackColor, width: 3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _blackColor,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: _darkColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _accentColor,
              border: Border.all(color: _blackColor, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.arrow_forward,
              size: 20,
              color: _blackColor,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: isSelected
            ? BoxDecoration(
                color: _primaryColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _blackColor, width: 2.0),
                boxShadow: [_lightShadow],
              )
            : null,
        child: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? Colors.white : Colors.grey.shade800,
          size: 28,
        ),
      ),
    );
  }

  void _handleScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final metrics = notification.metrics;
      final isAtBottom = metrics.pixels >= metrics.maxScrollExtent - 10;

      _scrollTimer?.cancel();

      if (!_isKeyboardVisible) {
        _hideBottomBar();
      }

      _scrollTimer = Timer(const Duration(milliseconds: 750), () {
        if (!_isKeyboardVisible) {
          _showBottomBar();
        }
      });

      if (!isAtBottom && !_isKeyboardVisible) {
        _scrollTimer?.cancel();
        _scrollTimer = Timer(const Duration(milliseconds: 500), () {
          if (!_isKeyboardVisible) {
            _showBottomBar();
          }
        });
      }
    }
  }

  void _loadMockData() {
    // Mock data for siswa
    _siswaList = [
      {
        'id': 1,
        'nama': 'Ahmad Rizki',
        'kelas': 'XII TKJ 1',
        'industri': 'PT. Teknologi Nusantara',
        'status': 'Aktif',
        'progress': 75,
        'last_visit': '3 hari lalu',
        'avatar_color': 0xFFE71543,
      },
      {
        'id': 2,
        'nama': 'Siti Nurhaliza',
        'kelas': 'XII TKJ 2',
        'industri': 'CV. Digital Solusi',
        'status': 'Aktif',
        'progress': 90,
        'last_visit': '1 hari lalu',
        'avatar_color': 0xFF1D3557,
      },
      {
        'id': 3,
        'nama': 'Budi Santoso',
        'kelas': 'XII TKJ 1',
        'industri': 'PT. Mandiri Teknik',
        'status': 'Perlu Monitoring',
        'progress': 40,
        'last_visit': '5 hari lalu',
        'avatar_color': 0xFFFFB703,
      },
    ];

    // Mock data for permasalahan
    _permasalahanList = [
      {
        'id': 1,
        'siswa_nama': 'Ahmad Rizki',
        'title': 'Kesulitan dengan Database',
        'description': 'Siswa mengalami kesulitan dalam membuat relasi tabel',
        'date': '2 hari lalu',
        'status': 'Belum Ditangani',
        'priority': 'Tinggi',
      },
      {
        'id': 2,
        'siswa_nama': 'Siti Nurhaliza',
        'title': 'Laporan Harian',
        'description': 'Siswa belum mengumpulkan laporan selama 3 hari',
        'date': '1 hari lalu',
        'status': 'Sedang',
        'priority': 'Tinggi',
      },
    ];

    // Mock data for ijin
    _ijinList = [
      {
        'id': 1,
        'siswa_nama': 'Budi Santoso',
        'alasan': 'Sakit',
        'tanggal': '12 Mar',
        'status': 'Pending',
        'durasi': '2 hari',
      },
      {
        'id': 2,
        'siswa_nama': 'Dewi Anggraini',
        'alasan': 'Keperluan Keluarga',
        'tanggal': '11 Mar',
        'status': 'Disetujui',
        'durasi': '1 hari',
      },
    ];

    // Mock recent activities
    _recentActivities = [
      {
        'id': 1,
        'title': 'Monitoring PT. Teknologi Nusantara',
        'description': 'Kunjungan monitoring ke Ahmad Rizki',
        'time': 'Hari ini, 10:30',
        'type': 'monitoring',
      },
      {
        'id': 2,
        'title': 'Izin Disetujui',
        'description': 'Menyetujui izin Dewi Anggraini',
        'time': 'Kemarin, 14:20',
        'type': 'approval',
      },
      {
        'id': 3,
        'title': 'Laporan Monitoring diupload',
        'description': 'Upload bukti kunjungan ke CV. Digital Solusi',
        'time': '2 hari lalu',
        'type': 'upload',
      },
    ];
  }

  Future<void> _logout(BuildContext context) async {
    print('🚪 Logout initiated from Pembimbing');

    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (context) => _buildLogoutConfirmationDialog(),
    );

    if (shouldLogout == true) {
      print('✅ User confirmed logout');

      _showLogoutLoadingDialog(context);

      await Future.delayed(const Duration(milliseconds: 500));

      await _processLogout();

      if (context.mounted) {
        Navigator.pop(context);

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } else {
      print('❌ User cancelled logout');
    }
  }

  Widget _buildLogoutConfirmationDialog() {
    const Color primaryColor = Color(0xFFE71543);
    const Color borderColor = Colors.black;
    const double borderThickness = 3.0;
    const double circleShadowOffset = 4.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: borderColor, width: borderThickness),
          boxShadow: const [
            BoxShadow(
              color: borderColor,
              offset: Offset(circleShadowOffset, circleShadowOffset),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Container(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // HEADER
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: primaryColor,
                    border: Border(
                        bottom: BorderSide(
                            color: borderColor, width: borderThickness)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: borderColor, width: borderThickness),
                          boxShadow: const [
                            BoxShadow(
                              color: borderColor,
                              offset: Offset(circleShadowOffset / 2,
                                  circleShadowOffset / 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.logout_rounded,
                            color: primaryColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'KONFIRMASI LOGOUT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Pembimbing',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // CONTENT
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: borderColor, width: borderThickness),
                          boxShadow: const [
                            BoxShadow(
                              color: borderColor,
                              offset: Offset(circleShadowOffset / 2,
                                  circleShadowOffset / 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.exit_to_app_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'YAKIN INGIN KELUAR?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Anda perlu login kembali untuk masuk',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // BUTTONS
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: const BorderSide(
                                color: primaryColor, width: borderThickness),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.white,
                          ),
                          child: const Text(
                            'BATAL',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(
                                  color: borderColor, width: borderThickness),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'KELUAR',
                            style: TextStyle(fontWeight: FontWeight.w900),
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
      ),
    );
  }

  void _showLogoutLoadingDialog(BuildContext context) {
    const Color primaryColor = Color(0xFFE71543);
    const Color borderColor = Colors.black;
    const double borderThickness = 3.0;
    const double circleShadowOffset = 4.0;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha:0.3),
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: borderThickness),
            boxShadow: const [
              BoxShadow(
                color: borderColor,
                offset:
                    Offset(circleShadowOffset / 2, circleShadowOffset / 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor,
                  border:
                      Border.all(color: borderColor, width: borderThickness),
                  boxShadow: const [
                    BoxShadow(
                      color: borderColor,
                      offset: Offset(
                          circleShadowOffset / 2, circleShadowOffset / 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.hourglass_bottom_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'MEMPROSES...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Menyelesaikan sesi anda',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processLogout() async {
    print('🔄 Processing logout...');

    final prefs = await SharedPreferences.getInstance();
    final currentUsername = prefs.getString('user_name');

    print('👤 Current username: $currentUsername');

    // Hapus data login saja
    print('🗑️ Removing login data...');
    await prefs.remove('access_token');
    await prefs.remove('user_role');
    await prefs.remove('user_name');

    final usernameForLog = currentUsername ?? 'unknown_user';

    print('💾 Preserving notifications for user: $usernameForLog');

    print('✅ Logout completed successfully');
    print('   - User: $usernameForLog');
    print('   - Login data: REMOVED');
    print('   - Notifications: PRESERVED');
  }

  void _refreshData() {
    setState(() {
      _loadMockData();
    });
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _primaryColor,
        border: Border.all(color: _blackColor, width: 3),
        boxShadow: const [_heavyShadow],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Halo, Pembimbing!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Monitor dan bimbingan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _secondaryColor,
                    ),
                  ),
                ],
              ),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _yellowColor,
                  border: Border.all(color: _blackColor, width: 3),
                  shape: BoxShape.circle,
                  boxShadow: [_lightShadow],
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshData,
                  color: _blackColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainMenu() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        color: _secondaryColor,
        border: Border.all(color: _blackColor, width: 4),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
        boxShadow: const [_heavyShadow],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Container untuk 4 aksi cepat dalam 1 baris
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFF1D3557),
                border: Border.all(color: _blackColor, width: 3),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [_heavyShadow],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildHorizontalActionItem(
                        icon: Icons.people,
                        title: 'Siswa',
                        iconColor: _primaryColor,
                        onTap: () => _onItemTapped(0),
                      ),
                      _buildHorizontalActionItem(
                        icon: Icons.cloud_upload,
                        title: 'Upload',
                        iconColor: _accentColor,
                        onTap: () => _onItemTapped(1),
                      ),
                      _buildHorizontalActionItem(
                        icon: Icons.report_problem,
                        title: 'Masalah',
                        iconColor: const Color(0xFFFFB703),
                        onTap: () => _onItemTapped(2),
                      ),
                      _buildHorizontalActionItem(
                        icon: Icons.event_available,
                        title: 'Ijin',
                        iconColor: const Color(0xFF06D6A0),
                        onTap: () => _onItemTapped(2),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // SISWA PERLU PERHATIAN
            if (_siswaList.isNotEmpty) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _primaryColor,
                  border: Border.all(color: _blackColor, width: 3),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [_lightShadow],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SISWA PERLU PERHATIAN',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 4),
                      decoration: BoxDecoration(
                        color: _secondaryColor,
                        border: Border.all(color: _blackColor, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_siswaList.length} SISWA',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _blackColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Students needing attention
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _siswaList.length,
                  itemBuilder: (context, index) {
                    final siswa = _siswaList[index];
                    return _buildStudentCard(siswa);
                  },
                ),
              ),

              const SizedBox(height: 32),
            ],

            // AKTIVITAS TERBARU
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _yellowColor,
                border: Border.all(color: _blackColor, width: 3),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [_lightShadow],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'AKTIVITAS TERBARU',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: _blackColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _secondaryColor,
                      border: Border.all(color: _blackColor, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_recentActivities.length} ITEM',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _blackColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Recent Activities List
            ..._recentActivities
                .map((activity) => _buildActivityCard(activity)),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalActionItem({
    required IconData icon,
    required String title,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 75,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: iconColor,
                border: Border.all(color: _blackColor, width: 3),
                shape: BoxShape.circle,
                boxShadow: [_lightShadow],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: _secondaryColor,
                border: Border.all(color: _blackColor, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: _blackColor,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    final icon = activity['type'] == 'monitoring'
        ? Icons.visibility
        : activity['type'] == 'approval'
            ? Icons.check_circle
            : Icons.cloud_upload;
    final color = activity['type'] == 'monitoring'
        ? _accentColor
        : activity['type'] == 'approval'
            ? const Color(0xFF06D6A0)
            : _yellowColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _secondaryColor,
        border: Border.all(color: _blackColor, width: 3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [_lightShadow],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: _blackColor, width: 3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _blackColor,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: _darkColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity['time'],
                  style: TextStyle(
                    fontSize: 12,
                    color: _darkColor.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              border: Border.all(color: _blackColor, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.arrow_forward,
              size: 20,
              color: _blackColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> siswa) {
    final isUrgent = siswa['status'] == 'Perlu Monitoring';

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: isUrgent ? const Color(0xFFFFF3CD) : _secondaryColor,
        border: Border.all(
          color: isUrgent ? const Color(0xFFFFB703) : _blackColor,
          width: 3,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [_lightShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUrgent ? const Color(0xFFFFB703) : _primaryColor,
              border: Border(
                bottom: BorderSide(
                  color: isUrgent ? const Color(0xFFFFB703) : _blackColor,
                  width: 3,
                ),
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(17),
                topRight: Radius.circular(17),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Color(siswa['avatar_color']),
                    border: Border.all(color: _blackColor, width: 2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      siswa['nama'].split(' ').map((n) => n[0]).join(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        siswa['nama'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isUrgent ? _blackColor : Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        siswa['kelas'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isUrgent
                              ? _darkColor
                              : Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isUrgent)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _secondaryColor,
                      border: Border.all(color: _blackColor, width: 2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'URGENT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: _blackColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'INDUSTRI',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _darkColor,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        siswa['industri'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _blackColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'PROGRESS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: _darkColor,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            '${siswa['progress']}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: _primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: _darkColor.withValues(alpha: 0.1),
                          border: Border.all(color: _blackColor, width: 1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Stack(
                          children: [
                            Container(
                              width:
                                  (252 * (siswa['progress'] / 100)).toDouble(),
                              decoration: BoxDecoration(
                                color: _primaryColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _accentColor,
                          border: Border.all(color: _blackColor, width: 2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: _darkColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              siswa['last_visit'],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _darkColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _primaryColor,
                          border: Border.all(color: _blackColor, width: 2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: Colors.white,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkColor,
      body: Container(
        decoration: BoxDecoration(
          border: Border.all(color: _blackColor, width: 2.0),
        ),
        child: Stack(
          children: [
            // Main content
            Positioned.fill(
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification notification) {
                  _handleScroll(notification);
                  return false;
                },
                child: _pages[_selectedIndex],
              ),
            ),

            // Floating Bottom Navigation Bar
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isBottomBarVisible && !_isKeyboardVisible ? 1.0 : 0.0,
                curve: Curves.easeInOut,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 300),
                  offset: Offset(0,
                      _isBottomBarVisible && !_isKeyboardVisible ? 0.0 : 1.0),
                  curve: Curves.easeInOut,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white,
                      border: Border.all(
                        color: _blackColor,
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _blackColor,
                          offset: const Offset(5, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(
                          icon: Icons.home_outlined,
                          activeIcon: Icons.home_filled,
                          index: 0,
                        ),
                        _buildNavItem(
                          icon: Icons.cloud_upload_outlined,
                          activeIcon: Icons.cloud_upload,
                          index: 1,
                        ),
                        _buildNavItem(
                          icon: Icons.report_problem_outlined,
                          activeIcon: Icons.report_problem,
                          index: 2,
                        ),
                        _buildNavItem(
                          icon: Icons.settings_outlined,
                          activeIcon: Icons.settings,
                          index: 3,
                        ),
                      ],
                    ),
                  ),
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
    _scrollTimer?.cancel();
    super.dispose();
  }
}

// Helper class untuk mendeteksi perubahan keyboard
class LifecycleEventHandler extends WidgetsBindingObserver {
  final VoidCallback? onMetricsChanged;

  LifecycleEventHandler({this.onMetricsChanged});

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    onMetricsChanged?.call();
  }
}
