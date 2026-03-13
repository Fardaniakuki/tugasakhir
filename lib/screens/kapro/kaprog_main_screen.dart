// lib/screens/kaprog/kaprog_main_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import halaman-halaman
import 'kaprog_dashboard.dart';
import 'bukti_pkl_screen.dart';
import 'kelola_perizinan_screen.dart';
import 'review_penilaian_screen.dart';

class KaprogMainScreen extends StatefulWidget {
  const KaprogMainScreen({super.key});

  @override
  State<KaprogMainScreen> createState() => _KaprogMainScreenState();
}

class _KaprogMainScreenState extends State<KaprogMainScreen> {
  int _currentIndex = 0;
  
  // Token dan baseUrl
  String? _token;
  final String _baseUrl = 'https://api.gedanggoreng.com';
  
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

  late List<Widget> _pageBuilders;

  // WARNA UNTUK KAPROG
  final Color _primaryColor = const Color(0xFF6B1B1B);

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Coba ambil token dengan berbagai kemungkinan key
      final String? token = prefs.getString('access_token') ?? 
                     prefs.getString('token') ?? 
                     prefs.getString('auth_token');
      
      print('📦 Token dari SharedPreferences: ${token != null ? "ADA" : "TIDAK ADA"}');
      
      setState(() {
        _token = token;
      });
      
      // Inisialisasi page builders setelah token didapat
      _pageBuilders = [
        _buildDashboardPage(),
        _buildReviewPenilaianPage(),
        _buildBuktiPklPage(),
        _buildPerizinanPage(),
      ];
    } catch (e) {
      print('❌ Error loading token: $e');
      setState(() {
        _token = null;
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _scrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildDashboardPage() {
    return _buildCachedPage(
      index: 0,
      builder: () => KaprogDashboard(
        key: const ValueKey('dashboard_page'),
        scrollController: _scrollControllers[0],
      ),
    );
  }

  Widget _buildReviewPenilaianPage() {
    // Jika token belum ada, tampilkan loading
    if (_token == null || _token!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memuat token...'),
          ],
        ),
      );
    }
    
    return _buildCachedPage(
      index: 1,
      builder: () => ReviewPenilaianScreen(
        key: const ValueKey('review_penilaian_page'),
        scrollController: _scrollControllers[1],
        token: _token!,
        baseUrl: _baseUrl,
      ),
    );
  }

  Widget _buildBuktiPklPage() {
    return _buildCachedPage(
      index: 2,
      builder: () => BuktiPklScreen(
        key: const ValueKey('bukti_pkl_page'),
        scrollController: _scrollControllers[2],
      ),
    );
  }

  Widget _buildPerizinanPage() {
    return _buildCachedPage(
      index: 3,
      builder: () => KelolaPerizinanTabScreen(
        key: const ValueKey('perizinan_page'),
        scrollController: _scrollControllers[3],
      ),
    );
  }

  Widget _buildCachedPage({
    required int index,
    required Widget Function() builder,
  }) {
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
    // Jika token belum ada, tampilkan loading
    if (_token == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memuat data pengguna...'),
            ],
          ),
        ),
      );
    }

    // Pastikan _pageBuilders sudah diinisialisasi
    if (_pageBuilders.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: _pageBuilders,
            ),
          ),
          
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
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTabItem(
            index: 0,
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            label: 'Beranda',
          ),
          _buildTabItem(
            index: 1,
            icon: Icons.assignment_turned_in_outlined,
            activeIcon: Icons.assignment_turned_in,
            label: 'Tinjau Nilai',
          ),
          _buildTabItem(
            index: 2,
            icon: Icons.fact_check_outlined,
            activeIcon: Icons.fact_check,
            label: 'Bukti PKL',
          ),
          _buildTabItem(
            index: 3,
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
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
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