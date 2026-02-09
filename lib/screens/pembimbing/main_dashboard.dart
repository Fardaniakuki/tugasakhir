import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'masalah_ijin_page.dart';
import 'pengaturan_page.dart';
import 'upload_page.dart';

class PembimbingMainScreen extends StatefulWidget {
  const PembimbingMainScreen ({super.key});

  @override
  State<PembimbingMainScreen > createState() => _PembimbingMainScreen ();
}

class _PembimbingMainScreen  extends State<PembimbingMainScreen > {
  int _currentIndex = 0;
  
  // Cache untuk menyimpan widget halaman
  final Map<int, Widget> _pageCache = {};
  final Map<int, bool> _pageLoaded = {};
  
  // Controller untuk mempertahankan scroll position
  final List<ScrollController> _scrollControllers = [
    ScrollController(),
    ScrollController(),
    ScrollController(),
    ScrollController(),
  ];

  late final List<Widget> _pageBuilders;

  @override
  void initState() {
    super.initState();
    
    // Inisialisasi page builders
    _pageBuilders = [
      _buildDashboardPage(),
      _buildUploadPage(),
      _buildMasalahIjinPage(),
      _buildPengaturanPage(),
    ];
  }

  @override
  void dispose() {
    // Dispose semua scroll controller
    for (var controller in _scrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Neo Brutalism Colors
  final Color _primaryColor = const Color(0xFF641E20);
  final Color _secondaryColor = const Color(0xFFE6E3E3);
  final Color _accentColor = const Color(0xFFA8DADC);
  final Color _darkColor = const Color(0xFF641E20);
  final Color _yellowColor = const Color(0xFFFFB703);
  final Color _blackColor = Colors.black;

  // Builder untuk halaman Dashboard dengan caching sederhana
  Widget _buildDashboardPage() {
    return _buildCachedPage(
      index: 0,
      builder: () {


        return const PembimbingDashboard(
          key: ValueKey('dashboard_page'),
        );
      },
    );
  }

  // Builder untuk halaman Upload dengan caching sederhana
  Widget _buildUploadPage() {
    return _buildCachedPage(
      index: 1,
      builder: () {
        const heavyShadow = BoxShadow(
          color: Colors.black,
          offset: Offset(6, 6),
          blurRadius: 0,
        );

        final lightShadow = BoxShadow(
          color: Colors.black.withValues(alpha:0.2),
          offset: const Offset(4, 4),
          blurRadius: 0,
        );

        return UploadPage(
          primaryColor: _primaryColor,
          secondaryColor: _secondaryColor,
          accentColor: _accentColor,
          darkColor: _darkColor,
          yellowColor: _yellowColor,
          blackColor: _blackColor,
          heavyShadow: heavyShadow,
          lightShadow: lightShadow,
          key: const ValueKey('upload_page'),
          scrollController: _scrollControllers[1],
        );
      },
    );
  }

  // Builder untuk halaman Masalah Ijin dengan caching sederhana
  Widget _buildMasalahIjinPage() {
    return _buildCachedPage(
      index: 2,
      builder: () => const KelolaPerizinanTabScreen(
        key: ValueKey('masalah_ijin_page'),
      ),
    );
  }

  // Builder untuk halaman Pengaturan dengan caching sederhana
  Widget _buildPengaturanPage() {
    return _buildCachedPage(
      index: 3,
      builder: () {


        return const PengaturanPage(
      
          key: ValueKey('pengaturan_page'),
        );
      },
    );
  }

  // Fungsi untuk caching halaman sederhana
  Widget _buildCachedPage({
    required int index,
    required Widget Function() builder,
  }) {
    // Jika halaman belum pernah dibuat
    if (!_pageLoaded.containsKey(index) || !_pageLoaded[index]!) {
      return FutureBuilder<void>(
        future: Future.delayed(Duration.zero, () {
          _pageCache[index] = builder();
          _pageLoaded[index] = true;
        }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return _pageCache[index]!;
          }
          return Center(
            child: CircularProgressIndicator(
              color: _primaryColor,
            ),
          );
        },
      );
    }

    return _pageCache[index]!;
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Background utama putih
      body: Stack(
        children: [
          // Halaman konten - mengisi seluruh layar
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: _pageBuilders,
            ),
          ),
          
          // Bottom Navigation Bar - posisi absolute di bawah
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _PembimbingBottomBar(
              currentIndex: _currentIndex,
              onTabSelected: _onTabSelected,
              primaryColor: _primaryColor,
              blackColor: _blackColor,
            ),
          ),
        ],
      ),
    );
  }

  // Method untuk refresh halaman tertentu
  void refreshPage(int pageIndex) {
    if (_pageLoaded.containsKey(pageIndex)) {
      _pageCache.remove(pageIndex);
      _pageLoaded[pageIndex] = false;
      
      if (_currentIndex == pageIndex) {
        setState(() {});
      }
    }
  }
}

// ============== BOTTOM NAVIGATION BAR ==============

class _PembimbingBottomBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTabSelected;
  final Color primaryColor;
  final Color blackColor;

  const _PembimbingBottomBar({
    required this.currentIndex,
    required this.onTabSelected,
    required this.primaryColor,
    required this.blackColor,
  });

  @override
  State<_PembimbingBottomBar> createState() => __PembimbingBottomBarState();
}

class __PembimbingBottomBarState extends State<_PembimbingBottomBar> {
  final Color _inactiveColor = const Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        // HAPUS BORDER DI SINI ↓↓↓
        // border: Border(  // ← HAPUS BARIS INI
        //   top: BorderSide(color: widget.blackColor, width: 1),  // ← HAPUS
        //   left: BorderSide(color: widget.blackColor, width: 1), // ← HAPUS
        //   right: BorderSide(color: widget.blackColor, width: 1),// ← HAPUS
        // ), // ← HAPUS BARIS INI JUGA
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
          // Neo brutalism shadow - hanya di bawah
          BoxShadow(
            color: widget.blackColor,
            offset: const Offset(0, 0),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Menu 1: Dashboard
          _buildTabItem(
            index: 0,
            icon: Icons.home_outlined,
            activeIcon: Icons.home_filled,
            label: 'Beranda',
          ),

          // Menu 2: Upload
          _buildTabItem(
            index: 1,
            icon: Icons.cloud_upload_outlined,
            activeIcon: Icons.cloud_upload,
            label: 'Upload',
          ),

          // Menu 3: Masalah Ijin
          _buildTabItem(
            index: 2,
            icon: Icons.report_problem_outlined,
            activeIcon: Icons.report_problem,
            label: 'Masalah',
          ),

          // Menu 4: Pengaturan
          _buildTabItem(
            index: 3,
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final bool isActive = widget.currentIndex == index;
    final activeColor = widget.primaryColor;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onTabSelected(index),
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon dengan efek animasi
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isActive 
                    ? activeColor.withValues(alpha:0.1)
                    : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? activeColor : _inactiveColor,
                  size: 22,
                ),
              ),
              const SizedBox(height: 4),
              
              // Label
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? activeColor : _inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}