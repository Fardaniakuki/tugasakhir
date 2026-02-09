// kaprog_main_screen.dart
import 'package:flutter/material.dart';

// Import halaman-halaman (sesuaikan dengan path Anda)
import 'kaprog_dashboard.dart'; // Import dashboard yang sudah ada
import 'bukti_pkl_screen.dart'; // Screen baru untuk Bukti PKL
import 'kelola_perizinan_screen.dart'; // Screen baru untuk Perizinan

class KaprogMainScreen extends StatefulWidget {
  const KaprogMainScreen({super.key});

  @override
  State<KaprogMainScreen> createState() => _KaprogMainScreenState();
}

class _KaprogMainScreenState extends State<KaprogMainScreen> {
  int _currentIndex = 0;
  
  // Cache untuk menyimpan widget halaman
  final Map<int, Widget> _pageCache = {};
  final Map<int, bool> _pageLoaded = {};
  
  // Controller untuk mempertahankan scroll position
  final List<ScrollController> _scrollControllers = [
    ScrollController(),
    ScrollController(),
    ScrollController(),
  ];

  late final List<Widget> _pageBuilders;

  // WARNA UNTUK KAPROG
  final Color _primaryColor = const Color(0xFF6B1B1B); // WARNA KAPROG

  @override
  void initState() {
    super.initState();
    
    // Inisialisasi page builders
    _pageBuilders = [
      _buildDashboardPage(),
      _buildBuktiPklPage(),
      _buildPerizinanPage(),
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

  // Builder untuk halaman Dashboard dengan caching sederhana
  Widget _buildDashboardPage() {
    return _buildCachedPage(
      index: 0,
      builder: () => KaprogDashboard(
        key: const ValueKey('dashboard_page'),
        scrollController: _scrollControllers[0],
      ),
    );
  }

  // Builder untuk halaman Bukti PKL dengan caching sederhana
  Widget _buildBuktiPklPage() {
    return _buildCachedPage(
      index: 1,
      builder: () => BuktiPklScreen(
        key: const ValueKey('bukti_pkl_page'),
        scrollController: _scrollControllers[1],
      ),
    );
  }

  // Builder untuk halaman Perizinan dengan caching sederhana
  Widget _buildPerizinanPage() {
    return _buildCachedPage(
      index: 2,
      builder: () => KelolaPerizinanTabScreen(
        key: const ValueKey('perizinan_page'),
        scrollController: _scrollControllers[2],
      ),
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
            child: _KaprogBottomBar(
              currentIndex: _currentIndex,
              onTabSelected: _onTabSelected,
              primaryColor: _primaryColor,
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
// Dipindahkan ke dalam file yang sama

class _KaprogBottomBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTabSelected;
  final Color primaryColor;

  const _KaprogBottomBar({
    required this.currentIndex,
    required this.onTabSelected,
    required this.primaryColor,
  });

  @override
  State<_KaprogBottomBar> createState() => __KaprogBottomBarState();
}

class __KaprogBottomBarState extends State<_KaprogBottomBar> {
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
          const BoxShadow(
            color: Colors.black,
            offset: Offset(0, 0),
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
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            label: 'Beranda',
          ),

          // Menu 2: Data Bukti Diterima PKL
          _buildTabItem(
            index: 1,
            icon: Icons.fact_check_outlined,
            activeIcon: Icons.fact_check,
            label: 'Bukti PKL',
          ),

          // Menu 3: Kelola Perizinan
          _buildTabItem(
            index: 2,
            icon: Icons.assignment_outlined,
            activeIcon: Icons.assignment,
            label: 'Perizinan',
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
                    ? activeColor.withValues(alpha: 0.1)
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