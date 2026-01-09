import 'package:flutter/material.dart';
import 'dart:async';

// Import halaman untuk wali kelas
import 'wali_kelas_dashboard.dart';
import 'wali_kelas_pengaturan.dart';

class WaliKelasMain extends StatefulWidget {
  const WaliKelasMain({super.key});

  @override
  State<WaliKelasMain> createState() => _WaliKelasMainState();
}

class _WaliKelasMainState extends State<WaliKelasMain> {
  int _selectedIndex = 0;
  bool _isBottomBarVisible = true;
  Timer? _scrollTimer;
  bool _isKeyboardVisible = false;

  // Warna tema Neo Brutalism
  final Color _primaryColor = const Color(0xFFE71543);
  final Color _backgroundColor = const Color(0xFF1D3557);
  final Color _borderColor = Colors.black;
  final double _borderThickness = 3.0;
  final double _circleBorderThickness = 3.0;

  // Shadow sesuai dashboard
  static const BoxShadow _heavyShadow = BoxShadow(
    color: Colors.black,
    offset: Offset(6, 6),
    blurRadius: 0,
  );

  // Warna untuk icon tidak aktif
  final Color _inactiveIconColor = const Color.fromARGB(255, 134, 134, 134);

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const WaliKelasDashboard(),
      _buildPlaceholderPage(),
      const WaliKelasPengaturan(),
    ];

    _showBottomBar();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupKeyboardListener();
    });
  }

  // Halaman placeholder untuk index 1 (tombol +)
  Widget _buildPlaceholderPage() {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          border: Border.all(color: _borderColor, width: _borderThickness),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  border: Border.all(color: _borderColor, width: 3),
                  shape: BoxShape.circle,
                  boxShadow: const [_heavyShadow],
                ),
                child: Icon(
                  Icons.add,
                  color: _primaryColor,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Aksi Cepat',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Tekan tombol + di bawah untuk aksi cepat',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha:0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    // Handle tombol tengah (index 1) untuk aksi cepat
    if (index == 1) {
      _showQuickActionsDialog(context);
      return;
    }

    setState(() {
      _selectedIndex = index;
    });

    _showBottomBar();
  }

  void _showQuickActionsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFE6E3E3),
          border: Border(
            top: BorderSide(color: Colors.black, width: 4),
            left: BorderSide(color: Colors.black, width: 4),
            right: BorderSide(color: Colors.black, width: 4),
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [_heavyShadow],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 6,
                decoration: BoxDecoration(
                  color: _borderColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'AKSI CEPAT',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _borderColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickActionItem(
                    icon: Icons.notifications_active,
                    label: 'Buat\nPengumuman',
                    color: _primaryColor,
                    onTap: () {
                      Navigator.pop(context);
                      _showUnderDevelopment('Buat Pengumuman');
                    },
                  ),
                  _buildQuickActionItem(
                    icon: Icons.report_problem,
                    label: 'Laporkan\nMasalah',
                    color: const Color(0xFFE63946),
                    onTap: () {
                      Navigator.pop(context);
                      _showUnderDevelopment('Laporkan Masalah');
                    },
                  ),
                  _buildQuickActionItem(
                    icon: Icons.assignment_turned_in,
                    label: 'Verifikasi\nProgress',
                    color: const Color(0xFF06D6A0),
                    onTap: () {
                      Navigator.pop(context);
                      _showUnderDevelopment('Verifikasi Progress');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB703),
                  border: Border.all(color: _borderColor, width: 3),
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
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: _borderColor, width: 3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: _borderColor,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  void _showUnderDevelopment(String featureName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFE6E3E3),
            border: Border.all(color: _borderColor, width: 4),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [_heavyShadow],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB703),
                  border: Border.all(color: _borderColor, width: 3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.construction,
                  color: Colors.black,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'FITUR DALAM PENGEMBANGAN',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _borderColor,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '$featureName sedang dalam tahap pengembangan dan akan segera hadir.',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1D3557),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _primaryColor,
                  border: Border.all(color: _borderColor, width: 3),
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

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required int index,
    bool isAddButton = false,
  }) {
    final isSelected = _selectedIndex == index;

    if (isAddButton) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onItemTapped(index),
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFFB703),
            border: Border.all(color: _borderColor, width: _circleBorderThickness),
            boxShadow: const [_heavyShadow],
          ),
          child: const Icon(
            Icons.add,
            color: Colors.black,
            size: 32,
          ),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: isSelected
            ? BoxDecoration(
                color: _primaryColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _borderColor, width: _borderThickness),
                boxShadow: const [_heavyShadow],
              )
            : BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.transparent, width: _borderThickness),
              ),
        child: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? Colors.white : _inactiveIconColor,
          size: 28,
        ),
      ),
    );
  }

  void _handleScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification && !_isKeyboardVisible) {
      _scrollTimer?.cancel();
      _hideBottomBar();
      _scrollTimer = Timer(const Duration(milliseconds: 750), () {
        if (!_isKeyboardVisible) {
          _showBottomBar();
        }
      });
    }
  }

  Widget _buildPageWithGestureDetector(int index, Widget child) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (_isKeyboardVisible) return;
        final deltaY = details.primaryDelta ?? 0;
        if (deltaY.abs() > 5) {
          _hideBottomBar();
          _scrollTimer?.cancel();
          _scrollTimer = Timer(const Duration(seconds: 2), _showBottomBar);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          _handleScroll(notification);
          return false;
        },
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          border: Border.all(color: _borderColor, width: _borderThickness),
        ),
        child: Stack(
          children: [
            // Halaman utama
            Positioned.fill(
              child: _buildPageWithGestureDetector(
                _selectedIndex,
                IndexedStack(
                  index: _selectedIndex,
                  children: _pages,
                ),
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
                  offset: Offset(
                      0, _isBottomBarVisible && !_isKeyboardVisible ? 0.0 : 1.0),
                  curve: Curves.easeInOut,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: const Color(0xFFE6E3E3),
                      border: Border.all(
                        color: _borderColor,
                        width: _borderThickness,
                      ),
                      boxShadow: const [_heavyShadow],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Dashboard Button
                        _buildNavItem(
                          icon: Icons.home_outlined,
                          activeIcon: Icons.home_filled,
                          index: 0,
                        ),
                        
                        // Add Button (Tengah)
                        _buildNavItem(
                          icon: Icons.add,
                          activeIcon: Icons.add,
                          index: 1,
                          isAddButton: true,
                        ),
                        
                        // Settings Button
                        _buildNavItem(
                          icon: Icons.settings_outlined,
                          activeIcon: Icons.settings,
                          index: 2,
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