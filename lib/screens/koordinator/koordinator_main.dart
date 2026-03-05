import 'package:flutter/material.dart';
import 'dashboard/koordinator_dashboard.dart';
import 'dashboard/koordinator_jadwal.dart';
import 'dashboard/koordinator_data.dart';
import 'dashboard/koordinator_perizinan_screen.dart';
import 'dashboard/koordinator_generate_surat.dart'; // IMPORT HALAMAN BARU
import 'dashboard/koordinator_review_penilaian.dart'; // IMPORT HALAMAN REVIEW PENILAIAN

class KoordinatorMain extends StatefulWidget {
  const KoordinatorMain({super.key});

  @override
  State<KoordinatorMain> createState() => _KoordinatorMainState();
}

class _KoordinatorMainState extends State<KoordinatorMain> {
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
    ScrollController(),
    ScrollController(), // TAMBAH CONTROLLER UNTUK GENERATE SURAT (index 5)
  ];

  late final List<Widget> _pageBuilders;

  // WARNA SAMA PERSIS DENGAN PEMBIMBING
  final Color _primaryColor = const Color(0xFF641E20); // MAROON/MERAH TUA
  final Color _blackColor = Colors.black;

  @override
  void initState() {
    super.initState();

    // Inisialisasi page builders (SEKARANG 6 HALAMAN)
    _pageBuilders = [
      _buildDashboardPage(), // index 0
      _buildJadwalPage(), // index 1
      _buildDataPage(), // index 2
      _buildPerizinanPage(), // index 3
      _buildGenerateSuratPage(), // index 4 - GANTI PENGATURAN DENGAN GENERATE SURAT
      _buildReviewPenilaianPage(), // index 5 - PENGATURAN PINDAH KE SINI
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
      builder: () {
        return const KoordinatorDashboard(
          key: ValueKey('dashboard_page'),
        );
      },
    );
  }

  // Builder untuk halaman Jadwal dengan caching sederhana
  Widget _buildJadwalPage() {
    return _buildCachedPage(
      index: 1,
      builder: () {
        return const KoordinatorJadwal(
          key: ValueKey('jadwal_page'),
        );
      },
    );
  }

  // Builder untuk halaman Data dengan caching sederhana
  Widget _buildDataPage() {
    return _buildCachedPage(
      index: 2,
      builder: () {
        return const KoordinatorData(
          key: ValueKey('data_page'),
        );
      },
    );
  }

  // Builder untuk halaman Perizinan dengan caching sederhana
  Widget _buildPerizinanPage() {
    return _buildCachedPage(
      index: 3,
      builder: () {
        return KoordinatorPerizinanScreen(
          key: const ValueKey('perizinan_page'),
          scrollController: _scrollControllers[3],
        );
      },
    );
  }

  // Builder untuk halaman Generate Surat (BARU)
  Widget _buildGenerateSuratPage() {
    return _buildCachedPage(
      index: 4,
      builder: () {
        return KoordinatorGenerateSurat(
          key: const ValueKey('generate_surat_page'),
          scrollController: _scrollControllers[4],
        );
      },
    );
  }

// Tambahkan method:
  Widget _buildReviewPenilaianPage() {
    return _buildCachedPage(
      index: 5,
      builder: () {
        return KoordinatorReviewPenilaian(
          key: const ValueKey('review_penilaian_page'),
          scrollController: _scrollControllers[5],
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
            child: _KoordinatorBottomBar(
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

class _KoordinatorBottomBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTabSelected;
  final Color primaryColor;
  final Color blackColor;

  const _KoordinatorBottomBar({
    required this.currentIndex,
    required this.onTabSelected,
    required this.primaryColor,
    required this.blackColor,
  });

  @override
  State<_KoordinatorBottomBar> createState() => __KoordinatorBottomBarState();
}

class __KoordinatorBottomBarState extends State<_KoordinatorBottomBar> {
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
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            label: 'Beranda',
          ),

          // Menu 2: Jadwal
          _buildTabItem(
            index: 1,
            icon: Icons.calendar_today_outlined,
            activeIcon: Icons.calendar_today,
            label: 'Jadwal',
          ),

          // Menu 3: Data
          _buildTabItem(
            index: 2,
            icon: Icons.business_center_outlined,
            activeIcon: Icons.business_center,
            label: 'Data',
          ),

          // Menu 4: Perizinan
          _buildTabItem(
            index: 3,
            icon: Icons.assignment_outlined,
            activeIcon: Icons.assignment,
            label: 'Perizinan',
          ),

          // Menu 5: Generate Surat (BARU)
          _buildTabItem(
            index: 4,
            icon: Icons.description_outlined,
            activeIcon: Icons.description,
            label: 'Buat Surat',
          ),
// Menu 5: Review Penilaian
          _buildTabItem(
            index: 5,
            icon: Icons.rate_review_outlined,
            activeIcon: Icons.rate_review_rounded,
            label: 'Nilai',
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
