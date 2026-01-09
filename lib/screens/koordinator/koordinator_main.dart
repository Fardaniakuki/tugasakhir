import 'package:flutter/material.dart';
import 'dart:async';
import 'dashboard/koordinator_dashboard.dart';
import 'dashboard/koordinator_jadwal.dart';
import 'dashboard/koordinator_data.dart';
import 'dashboard/koordinator_pengaturan.dart';

class KoordinatorMain extends StatefulWidget {
  const KoordinatorMain({super.key});

  @override
  State<KoordinatorMain> createState() => _KoordinatorMainState();
}

class _KoordinatorMainState extends State<KoordinatorMain> {
  int _selectedIndex = 0;
  bool _isBottomBarVisible = true;
  Timer? _scrollTimer;
  bool _isKeyboardVisible = false;

  // Warna tema Neo Brutalism KOORDINATOR
  final Color _primaryColor = const Color(0xFF1D3557); // Merah khas koordinator
  final Color _backgroundColor = Colors.white;
  final Color _borderColor = const Color(0xFF000000);
  final double _borderThickness = 2.0;
  final double _circleBorderThickness = 0.7;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    
    _pages = [
      const KoordinatorDashboard(),    // INDEX 0 - BERANDA
      const KoordinatorJadwal(),       // INDEX 1 - JADWAL
      const KoordinatorData(),         // INDEX 2 - DATA
      const KoordinatorPengaturan(),   // INDEX 3 - PENGATURAN
    ];

    _showBottomBar();

    // Setup keyboard listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupKeyboardListener();
    });
  }

  void _setupKeyboardListener() {
    // Menggunakan MediaQuery untuk mendeteksi keyboard
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
              // Keyboard muncul - sembunyikan bottom bar
              _hideBottomBar();
            } else {
              // Keyboard hilang - tampilkan bottom bar
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
    // Handle tombol tengah (index 2) yang untuk aksi cepat
    if (index == 2) {
      _showQuickActionsDialog();
      return;
    }

    // Mapping index BottomNavigationBar ke _pages
    int pageIndex = index;
    if (index > 2) {
      pageIndex = index - 1; // Adjust untuk tombol tengah
    }

    setState(() {
      _selectedIndex = pageIndex;
    });

    _showBottomBar();
  }

  // Method untuk mapping _selectedIndex ke BottomNavigationBar index
  int _getCurrentNavIndex() {
    if (_selectedIndex == 2) return 3; // Data di nav index 3
    if (_selectedIndex == 3) return 4; // Pengaturan di nav index 4
    return _selectedIndex; // Beranda (0), Jadwal (1)
  }

  void _showQuickActionsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20)
        ),
        side: BorderSide(color: _borderColor, width: _borderThickness),
      ),
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: _borderColor, width: _borderThickness),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _primaryColor,
                  border: Border(
                    bottom: BorderSide(color: _borderColor, width: _borderThickness),
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'AKSI CEPAT KOORDINATOR',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              _buildActionTile(Icons.schedule, 'BUAT JADWAL PEMBEKALAN', 'jadwal'),
              Divider(height: 1, color: _borderColor, thickness: 1),
              _buildActionTile(Icons.business, 'TAMBAH INDUSTRI BARU', 'industri'),
              Divider(height: 1, color: _borderColor, thickness: 1),
              _buildActionTile(Icons.description, 'CETAK SURAT PERMOHONAN', 'surat'),
              Divider(height: 1, color: _borderColor, thickness: 1),
              _buildActionTile(Icons.assignment, 'BUAT LAPORAN MONITORING', 'laporan'),
              Divider(height: 1, color: _borderColor, thickness: 1),
              _buildActionTile(Icons.group_add, 'ASSIGN PEMBIMBING', 'assign'),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  ListTile _buildActionTile(IconData icon, String title, String jenis) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _primaryColor,
          border: Border.all(color: _borderColor, width: _circleBorderThickness),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          color: Colors.black,
          letterSpacing: 1,
        ),
      ),
      trailing: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _primaryColor,
          border: Border.all(color: _borderColor, width: _circleBorderThickness),
        ),
        child: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: Colors.white,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        _navigateToAction(jenis);
      },
    );
  }

  void _navigateToAction(String jenisAksi) {
    switch (jenisAksi) {
      case 'jadwal':
        setState(() {
          _selectedIndex = 1; // Navigasi ke halaman Jadwal
        });
        break;
      case 'industri':
        setState(() {
          _selectedIndex = 2; // Navigasi ke halaman Data
        });
        break;
      case 'surat':
        _showSnackbar('Membuka generator surat...');
        break;
      case 'laporan':
        _showSnackbar('Membuat laporan monitoring...');
        break;
      case 'assign':
        _showSnackbar('Membuka assign pembimbing...');
        break;
    }
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required int index,
    bool isAddButton = false,
  }) {
    final isSelected = _getCurrentNavIndex() == index;

    if (isAddButton) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _showQuickActionsDialog,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _primaryColor,
            border: Border.all(color: _borderColor, width: _circleBorderThickness),
            boxShadow: [
              BoxShadow(
                color: _borderColor,
                offset: const Offset(1, 1),
              ),
            ],
          ),
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 26,
          ),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: isSelected
            ? BoxDecoration(
                color: _primaryColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _borderColor, width: _borderThickness),
              )
            : BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.transparent, width: _borderThickness),
              ),
        child: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? Colors.white : Colors.grey.shade800,
          size: 24,
        ),
      ),
    );
  }

  void _handleScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final metrics = notification.metrics;

      // Check jika sudah mencapai paling bawah
      final isAtBottom = metrics.pixels >= metrics.maxScrollExtent - 10;

      // Cancel timer sebelumnya
      _scrollTimer?.cancel();

      // Jangan hide navbar jika keyboard sedang terbuka
      if (!_isKeyboardVisible) {
        _hideBottomBar();
      }

      // Set timer untuk show setelah 3 detik
      _scrollTimer = Timer(const Duration(milliseconds: 750), () {
        // Jangan show jika keyboard masih terbuka
        if (!_isKeyboardVisible) {
          _showBottomBar();
        }
      });

      // Jika tidak di bottom, set timer yang lebih pendek (500ms) untuk show
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

  void _handleVerticalDrag(DragUpdateDetails details) {
    // Jangan handle swipe jika keyboard terbuka
    if (_isKeyboardVisible) return;

    final deltaY = details.primaryDelta ?? 0;
    const swipeThreshold = 5.0;

    if (deltaY.abs() > swipeThreshold) {
      _hideBottomBar();
      _scrollTimer?.cancel();

      _scrollTimer = Timer(const Duration(seconds: 2), () {
        _showBottomBar();
      });
    }
  }

  Widget _buildPageWithGestureDetector(int index, Widget child) {
    return GestureDetector(
      onVerticalDragUpdate: _handleVerticalDrag,
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

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: _borderColor, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 2),
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
            // Ganti PageView dengan IndexedStack
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
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.white,
                      border: Border.all(
                        color: _borderColor,
                        width: _borderThickness,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _borderColor,
                          offset: const Offset(5, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(
                          icon: Icons.dashboard_outlined,
                          activeIcon: Icons.dashboard,
                          index: 0,
                        ),
                        _buildNavItem(
                          icon: Icons.calendar_today_outlined,
                          activeIcon: Icons.calendar_today,
                          index: 1,
                        ),
                        _buildNavItem(
                          icon: Icons.add,
                          activeIcon: Icons.add,
                          index: 2,
                          isAddButton: true,
                        ),
                        _buildNavItem(
                          icon: Icons.business_center_outlined,
                          activeIcon: Icons.business_center,
                          index: 3,
                        ),
                        _buildNavItem(
                          icon: Icons.settings_outlined,
                          activeIcon: Icons.settings,
                          index: 4,
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