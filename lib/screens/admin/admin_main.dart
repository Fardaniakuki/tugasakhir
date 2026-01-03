import 'package:flutter/material.dart';
import 'dart:async';
import 'dashboard/admin_dashboard.dart';
import 'admin_setting.dart';
import 'dashboard/admin_data.dart';
import '../admin/crud/add_person_page.dart';
import 'manajemen_pkl_page.dart';

class AdminMain extends StatefulWidget {
  const AdminMain({super.key});

  @override
  State<AdminMain> createState() => _AdminMainState();
}

class _AdminMainState extends State<AdminMain> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  bool _isBottomBarVisible = true;
  Timer? _scrollTimer;
  bool _isKeyboardVisible = false;

  final GlobalKey<AdminDataState> _adminDataKey = GlobalKey<AdminDataState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      AdminDashboard(onNavigateToData: _navigateToDataWithFilter),
      AdminData(key: _adminDataKey),
      const ManajemenPklPage(),
      const AdminSetting(),
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
    if (index == 2) {
      _showAddDataDialog();
      return;
    }

    int pageIndex = index;
    if (index > 2) {
      pageIndex = index - 1;
    }

    setState(() {
      _selectedIndex = pageIndex;
    });
    _pageController.jumpToPage(pageIndex);

    _showBottomBar();
  }

  int _getCurrentNavIndex() {
    if (_selectedIndex == 2) return 3;
    if (_selectedIndex == 3) return 4;
    return _selectedIndex;
  }

  void _navigateToDataWithFilter(String filter) {
    setState(() {
      _selectedIndex = 1;
    });
    _pageController.jumpToPage(1);

    _showBottomBar();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _adminDataKey.currentState?.updateFilter(filter);
    });
  }

  void _showAddDataDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled:
          true, // Penting agar dialog bisa naik saat keyboard muncul
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
                    color: Color(0xFF641E20),
                  ),
                ),
              ),
              _buildAddTile(Icons.person, 'Tambah Murid', 'Siswa'),
              _buildAddTile(Icons.school, 'Tambah Guru', 'Guru'),
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

  ListTile _buildAddTile(IconData icon, String title, String jenis) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF641E20).withAlpha(25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF641E20)),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: () {
        Navigator.pop(context);
        _navigateToAddPage(jenis);
      },
    );
  }

  void _navigateToAddPage(String jenisData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPersonPage(jenisData: jenisData),
      ),
    ).then((result) {
      if (result == true) {
        _adminDataKey.currentState?.refreshData();
      }
    });
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
        onTap: _showAddDataDialog,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF641E20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 3),
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
                color: const Color(0xFF641E20).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        child: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? const Color(0xFF641E20) : Colors.grey.shade600,
          size: 24,
        ),
      ),
    );
  }

  void _handleScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final metrics = notification.metrics;

      // Check jika sudah mencapai paling bawah
      final isAtBottom =
          metrics.pixels >= metrics.maxScrollExtent - 10; // Buffer 10 pixel

      // Cancel timer sebelumnya
      _scrollTimer?.cancel();

      // Jangan hide navbar jika keyboard sedang terbuka
      if (!_isKeyboardVisible) {
        _hideBottomBar();
      }

      // Set timer untuk show setelah 2.5 detik - berlaku untuk semua kasus
      _scrollTimer = Timer(const Duration(milliseconds: 3000), () {
        // Jangan show jika keyboard masih terbuka
        if (!_isKeyboardVisible) {
          _showBottomBar();
        }
      });

      // Jika tidak di bottom, set timer yang lebih pendek (500ms) untuk show
      if (!isAtBottom && !_isKeyboardVisible) {
        _scrollTimer?.cancel(); // Cancel timer 2.5 detik
        _scrollTimer = Timer(const Duration(milliseconds: 500), () {
          if (!_isKeyboardVisible) {
            _showBottomBar();
          }
        });
      }
      // Jika di bottom, timer 2.5 detik tetap berjalan
    }
  }

  // Handler untuk gesture/swipe di halaman yang tidak bisa discroll
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

  // Widget untuk wrap setiap page dengan gesture detector
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main Content
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              if (!_isKeyboardVisible) {
                _showBottomBar();
              }
            },
            children: _pages.asMap().entries.map((entry) {
              final index = entry.key;
              final page = entry.value;
              return _buildPageWithGestureDetector(index, page);
            }).toList(),
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
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
                        icon: Icons.folder_outlined,
                        activeIcon: Icons.folder,
                        index: 1,
                      ),
                      _buildNavItem(
                        icon: Icons.add,
                        activeIcon: Icons.add,
                        index: 2,
                        isAddButton: true,
                      ),
                      _buildNavItem(
                        icon: Icons.work_outline,
                        activeIcon: Icons.work,
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
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
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
