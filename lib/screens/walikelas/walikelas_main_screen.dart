// walikelas_main_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Import halaman-halaman
import 'wali_kelas_dashboard.dart';
import 'kelola_perizinan_screen.dart';
import 'kelola_rekap_nilai_screen.dart'; // BARU: Import halaman rekap nilai
import '../login/login_screen.dart';

class WalikelasMainScreen extends StatefulWidget {
  const WalikelasMainScreen({super.key});

  @override
  State<WalikelasMainScreen> createState() => _WalikelasMainScreenState();
}

class _WalikelasMainScreenState extends State<WalikelasMainScreen> {
  int _currentIndex = 0;
  bool _isCheckingToken = true;
  String? _accessToken;
  
  // Cache untuk menyimpan widget halaman
  final Map<int, Widget> _pageCache = {};
  final Map<int, bool> _pageLoaded = {};
  
  // Controller untuk mempertahankan scroll position
  final List<ScrollController> _scrollControllers = [
    ScrollController(), // Dashboard
    ScrollController(), // Perizinan (SIA)
    ScrollController(), // Rekap Nilai (BARU)
  ];

  late final List<Widget> _pageBuilders;

  // WARNA UNTUK WALI KELAS
  final Color _primaryColor = const Color(0xFF6B1B1B);

  @override
  void initState() {
    super.initState();
    _checkTokenAndInit();
  }

  Future<void> _checkTokenAndInit() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      _redirectToLogin();
      return;
    }

    setState(() {
      _accessToken = token;
      _isCheckingToken = false;
    });

    // Inisialisasi page builders setelah token valid
    _pageBuilders = [
      _buildDashboardPage(),
      _buildSiaPage(),
      _buildRekapNilaiPage(), // BARU: Halaman rekap nilai
    ];
  }

  Future<String?> _getToken() async {
    if (_accessToken != null) return _accessToken;
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    
    setState(() {
      _accessToken = token;
    });
    
    return token;
  }

  String _getBaseUrl() {
    return dotenv.env['API_BASE_URL'] ?? 'https://api.gedanggoreng.com';
  }

  void _redirectToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    // Dispose semua scroll controller
    for (var controller in _scrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Builder untuk halaman Dashboard
  Widget _buildDashboardPage() {
    return _buildCachedPage(
      index: 0,
      builder: () => FutureBuilder<String?>(
        future: _getToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingScreen();
          }
          
          if (!snapshot.hasData || snapshot.data == null) {
            _redirectToLogin();
            return const SizedBox.shrink();
          }

          return WaliKelasDashboard(
            key: const ValueKey('dashboard_page'),
            scrollController: _scrollControllers[0],
            token: snapshot.data!,
            baseUrl: _getBaseUrl(),
          );
        },
      ),
    );
  }

  // Builder untuk halaman SIA (Perizinan)
  Widget _buildSiaPage() {
    return _buildCachedPage(
      index: 1,
      builder: () => FutureBuilder<String?>(
        future: _getToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingScreen();
          }
          
          if (!snapshot.hasData || snapshot.data == null) {
            _redirectToLogin();
            return const SizedBox.shrink();
          }

          return KelolaPerizinanTabScreen(
            key: const ValueKey('sia_page'),
            scrollController: _scrollControllers[1],
            token: snapshot.data!,
            baseUrl: _getBaseUrl(),
          );
        },
      ),
    );
  }

  // BARU: Builder untuk halaman Rekap Nilai
  Widget _buildRekapNilaiPage() {
    return _buildCachedPage(
      index: 2,
      builder: () => FutureBuilder<String?>(
        future: _getToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingScreen();
          }
          
          if (!snapshot.hasData || snapshot.data == null) {
            _redirectToLogin();
            return const SizedBox.shrink();
          }

          return KelolaRekapNilaiScreen(
            key: const ValueKey('rekap_nilai_page'),
            scrollController: _scrollControllers[2],
            token: snapshot.data!,
            baseUrl: _getBaseUrl(),
          );
        },
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

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: _primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Memeriksa sesi...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingToken) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Halaman konten
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: _pageBuilders,
            ),
          ),
          
          // Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _WalikelasBottomBar(
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
class _WalikelasBottomBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTabSelected;
  final Color primaryColor;

  const _WalikelasBottomBar({
    required this.currentIndex,
    required this.onTabSelected,
    required this.primaryColor,
  });

  @override
  State<_WalikelasBottomBar> createState() => __WalikelasBottomBarState();
}

class __WalikelasBottomBarState extends State<_WalikelasBottomBar> {
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
          // Menu 1: Dashboard
          _buildTabItem(
            index: 0,
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            label: 'Beranda',
          ),

          // Menu 2: SIA (Perizinan)
          _buildTabItem(
            index: 1,
            icon: Icons.assignment_outlined,
            activeIcon: Icons.assignment,
            label: 'Perizinan',
          ),

          // BARU: Menu 3: Rekap Nilai
          _buildTabItem(
            index: 2,
            icon: Icons.assessment_outlined,
            activeIcon: Icons.assessment,
            label: 'Rekap Nilai',
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