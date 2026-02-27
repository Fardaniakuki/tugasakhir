import 'package:flutter/material.dart';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupKeyboardListener();
    });
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
      isScrollControlled: true,
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
              _buildAddTile(Icons.category, 'Tambah Program Keahlian', 'Program Keahlian'),
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
        if (jenis == 'Siswa') {
          _showAddSiswaOptions();
        } else if (jenis == 'Guru') {
          _showAddGuruOptions();
        } else {
          _navigateToAddPage(jenis);
        }
      },
    );
  }

  void _showAddSiswaOptions() {
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
                  'Tambah Siswa',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF641E20),
                  ),
                ),
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF641E20).withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person_add, color: Color(0xFF641E20)),
                ),
                title: const Text(
                  'Tambah Manual',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: const Text('Tambah data siswa satu per satu'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToAddPage('Siswa');
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF641E20).withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      const Icon(Icons.upload_file, color: Color(0xFF641E20)),
                ),
                title: const Text(
                  'Unggah Excel',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: const Text('Unggah file Excel untuk mengunggah data'),
                onTap: () {
                  Navigator.pop(context);
                  _showExcelImportDialog('siswa');
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showAddGuruOptions() {
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
                  'Tambah Guru',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF641E20),
                  ),
                ),
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF641E20).withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person_add, color: Color(0xFF641E20)),
                ),
                title: const Text(
                  'Tambah Manual',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: const Text('Tambah data guru satu per satu'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToAddPage('Guru');
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF641E20).withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      const Icon(Icons.upload_file, color: Color(0xFF641E20)),
                ),
                title: const Text(
                  'Unggah Excel',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: const Text('Unggah file Excel untuk mengunggah data guru'),
                onTap: () {
                  Navigator.pop(context);
                  _showExcelImportDialog('guru');
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showExcelImportDialog(String tipe) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExcelImportPage(
          tipe: tipe,
          onImportSuccess: () {
            _adminDataKey.currentState?.refreshData();
          },
        ),
      ),
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

      final isAtBottom = metrics.pixels >= metrics.maxScrollExtent - 10;

      _scrollTimer?.cancel();

      if (!_isKeyboardVisible) {
        _hideBottomBar();
      }

      _scrollTimer = Timer(const Duration(milliseconds: 3000), () {
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

  void _handleVerticalDrag(DragUpdateDetails details) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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

class LifecycleEventHandler extends WidgetsBindingObserver {
  final VoidCallback? onMetricsChanged;

  LifecycleEventHandler({this.onMetricsChanged});

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    onMetricsChanged?.call();
  }
}

// ============================================
// Halaman Import Excel dengan UI Modern (Siswa & Guru)
// ============================================

class ExcelImportPage extends StatefulWidget {
  final String tipe; // 'siswa' atau 'guru'
  final VoidCallback? onImportSuccess;

  const ExcelImportPage({
    super.key,
    required this.tipe,
    this.onImportSuccess,
  });

  @override
  State<ExcelImportPage> createState() => _ExcelImportPageState();
}

class _ExcelImportPageState extends State<ExcelImportPage> {
  final Dio _dio = Dio();
  bool _isLoading = false;
  String _statusMessage = '';
  bool _isSuccess = false;
  Map<String, dynamic>? _previewData;
  String? _sessionId;
  String? _authToken;
  PlatformFile? _selectedFile;

  @override
  void initState() {
    super.initState();
    _loadAuthToken();
  }

  Future<void> _loadAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      print('🔑 Token loaded: ${token != null ? "Yes" : "No"}');

      setState(() {
        _authToken = token;
      });
    } catch (e) {
      print('Error loading token: $e');
    }
  }

  String _getTitle() {
    return widget.tipe == 'siswa' ? 'Unggah Excel Siswa' : 'Unggah Excel Guru';
  }

  String _getEntityName() {
    return widget.tipe == 'siswa' ? 'Siswa' : 'Guru';
  }

  List<Map<String, String>> _getGuideItems() {
    if (widget.tipe == 'siswa') {
      return [
        {'label': 'Kolom 1', 'value': 'Nama Lengkap'},
        {'label': 'Kolom 2', 'value': 'NISN (unik, 10 digit)'},
        {'label': 'Kolom 3', 'value': 'Kelas (harus terdaftar)'},
        {'label': 'Kolom 4', 'value': 'Alamat'},
      ];
    } else {
      return [
        {'label': 'Kolom 1', 'value': 'Nama Lengkap'},
        {'label': 'Kolom 2', 'value': 'NIP (unik)'},
        {'label': 'Kolom 3', 'value': 'Kode Guru'},
        {'label': 'Kolom 4', 'value': 'No. Telepon'},
        {'label': 'Kolom 5', 'value': 'Password (default)'},
      ];
    }
  }

  String _getPreviewApiUrl() {
    return widget.tipe == 'siswa'
        ? 'https://api.gedanggoreng.com/api/siswa/bulk/preview'
        : 'https://api.gedanggoreng.com/api/guru/bulk/preview';
  }

  String _getImportApiUrl() {
    return widget.tipe == 'siswa'
        ? 'https://api.gedanggoreng.com/api/siswa/bulk/import'
        : 'https://api.gedanggoreng.com/api/guru/bulk/import';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _getTitle(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF641E20),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_authToken == null) {
      return _buildLoadingScreen();
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeaderSection(),
            const SizedBox(height: 25),

            // File Upload Section
            _buildUploadSection(),
            const SizedBox(height: 25),

            // Preview Section (jika ada data)
            if (_previewData != null) _buildPreviewDataSection(),

            // Status Message
            if (_statusMessage.isNotEmpty) _buildStatusMessage(),

            // Spacer
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF641E20),
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            'Memuat autentikasi...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    final guideItems = _getGuideItems();

    return Container(
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
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF641E20).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFF641E20),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Panduan Unggah ${_getEntityName()}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pastikan file Excel Anda memiliki format berikut:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),
                ...guideItems.map((item) => _buildGuideItem(item['label']!, item['value']!)),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    _downloadTemplate();
                  },
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: Text('Unduh Template Excel ${_getEntityName()}'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF641E20),
                    side: const BorderSide(color: Color(0xFF641E20)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _downloadTemplate() {
    // Implementasi download template
    _showSnackbar('Template ${_getEntityName()} akan didownload');
  }

  Widget _buildGuideItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• $label:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon Section
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF641E20).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _selectedFile == null
                  ? Icons.cloud_upload_rounded
                  : Icons.insert_drive_file_rounded,
              size: 40,
              color: const Color(0xFF641E20),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            _selectedFile == null ? 'Unggah File Excel' : 'File Terpilih',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            _selectedFile == null
                ? 'Pilih file Excel (.xlsx/.xls) untuk memulai mengunggah'
                : '${_selectedFile!.name} (${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB)',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 25),

          if (_selectedFile == null)
            // Upload Button
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.upload_file_rounded, size: 20),
              label: const Text('Pilih File Excel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF641E20),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            )
          else
            // File Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedFile = null;
                      _previewData = null;
                    });
                  },
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Ganti File'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    side: BorderSide(color: Colors.grey[400]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _uploadFile,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.visibility_rounded, size: 18),
                  label: Text(_isLoading ? 'Memproses...' : 'Tinjau'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF641E20),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPreviewDataSection() {
    final summary = _previewData!['summary'];
    final validRows = _previewData!['valid_rows'] ?? [];
    final errorRows = _previewData!['error_rows'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Text(
            'Preview Data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),

        // Summary Cards
        Row(
          children: [
            Expanded(
                child: _buildSummaryCard(
                    'Total', summary['total_rows'].toString(), Colors.blue)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildSummaryCard(
                    'Valid', summary['valid_count'].toString(), Colors.green)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildSummaryCard(
                    'Error', summary['error_count'].toString(), Colors.orange)),
          ],
        ),
        const SizedBox(height: 25),

        // Valid Data Section
        if (validRows.isNotEmpty) _buildValidDataSection(validRows),

        // Error Data Section
        if (errorRows.isNotEmpty) _buildErrorDataSection(errorRows),

        // Import Button
        if (validRows.isNotEmpty && _sessionId != null)
          Container(
            margin: const EdgeInsets.only(top: 20),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _importData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF641E20),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Icon(Icons.cloud_upload_rounded, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    _isLoading ? 'Mengimport...' : 'Import Data Valid',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidDataSection(List<dynamic> validRows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.green, size: 18),
            const SizedBox(width: 8),
            const Text(
              'Data Valid',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${validRows.length} data',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...validRows.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;
          return _buildDataItem(
            index + 1,
            row['nama'] ?? row['nama_lengkap'] ?? '',
            _getValidRowSubtitle(row),
            true,
          );
        }),
        const SizedBox(height: 20),
      ],
    );
  }

  String _getValidRowSubtitle(Map<String, dynamic> row) {
    if (widget.tipe == 'siswa') {
      return 'NISN: ${row['nisn']} • ${row['kelas'] ?? '-'}';
    } else {
      return 'NIP: ${row['nip'] ?? '-'} • Kode: ${row['kode_guru'] ?? '-'}';
    }
  }

  Widget _buildErrorDataSection(List<dynamic> errorRows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.orange, size: 18),
            const SizedBox(width: 8),
            const Text(
              'Data Bermasalah',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.orange,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${errorRows.length} data',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...errorRows.map((error) {
          final data = error['data'];
          final errors = (error['errors'] as List<dynamic>).join(', ');
          return _buildDataItem(
            error['row_number'],
            data['nama'] ?? data['nama_lengkap'] ?? 'Data tidak valid',
            'Error: $errors',
            false,
          );
        }),
      ],
    );
  }

  Widget _buildDataItem(
      int number, String title, String subtitle, bool isSuccess) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSuccess
            ? Colors.green.withValues(alpha: 0.05)
            : Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSuccess
              ? Colors.green.withValues(alpha: 0.2)
              : Colors.orange.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isSuccess
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: TextStyle(
                  color: isSuccess ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
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
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSuccess ? Colors.black87 : Colors.grey[800],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSuccess ? Colors.grey[600] : Colors.orange,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
            color: isSuccess ? Colors.green : Colors.orange,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: _isSuccess
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isSuccess
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
            color: _isSuccess ? Colors.green : Colors.red,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSuccess ? 'Berhasil!' : 'Terjadi Kesalahan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _isSuccess ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _statusMessage,
                  style: TextStyle(
                    fontSize: 13,
                    color: _isSuccess ? Colors.green[800] : Colors.red[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
          _previewData = null;
          _statusMessage = '';
        });
      }
    } catch (e) {
      _showSnackbar('Gagal memilih file: $e');
    }
  }
Future<void> _uploadFile() async {
  if (_selectedFile == null) return;

  print('📤 MEMULAI PROSES UPLOAD FILE - Tipe: ${widget.tipe}');
  print('📁 File: ${_selectedFile!.name} (${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB)');
  print('🔑 Token tersedia: ${_authToken != null ? "Ya" : "Tidak"}');

  setState(() {
    _isLoading = true;
    _statusMessage = 'Sedang mengupload file...';
    _isSuccess = false;
  });

  try {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        _selectedFile!.path!,
        filename: _selectedFile!.name,
      ),
    });

    final apiUrl = _getPreviewApiUrl();
    print('🌐 URL API Preview: $apiUrl');
    print('📤 Mengirim request ke server...');

    final response = await _dio.post(
      apiUrl,
      data: formData,
      options: Options(headers: {
        'Authorization': 'Bearer $_authToken',
      }),
    );

    print('📥 Response status: ${response.statusCode}');
    print('📦 Response data: ${response.data}');

    if (response.statusCode == 200) {
      final data = response.data;
      if (data['success'] == true) {
        final summary = data['summary'];
        print('✅ UPLOAD BERHASIL!');
        print('📊 Ringkasan:');
        print('   - Total baris: ${summary['total_rows']}');
        print('   - Data valid: ${summary['valid_count']}');
        print('   - Data error: ${summary['error_count']}');
        print('   - Session ID: ${data['session_id']}');
        
        if (widget.tipe == 'guru') {
          print('👨‍🏫 PREVIEW DATA GURU:');
          final validRows = data['valid_rows'] ?? [];
          for (var i = 0; i < validRows.length; i++) {
            final guru = validRows[i];
            print('   Guru #${i + 1}: ${guru['nama_lengkap']} (NIP: ${guru['nip']}, Kode: ${guru['kode_guru']})');
          }
        }

        setState(() {
          _previewData = data;
          _sessionId = data['session_id'];
          _statusMessage = 'File berhasil diupload! Pratinjau data siap.';
          _isSuccess = true;
        });
      } else {
        print('❌ UPLOAD GAGAL: ${data['message']}');
        setState(() {
          _statusMessage = data['message'] ?? 'Gagal memproses file';
          _isSuccess = false;
        });
      }
    } else {
      print('❌ ERROR HTTP ${response.statusCode}');
      setState(() {
        _statusMessage = 'Error ${response.statusCode}';
        _isSuccess = false;
      });
    }
  } on DioException catch (e) {
    print('🚨 DIO EXCEPTION:');
    print('   - Message: ${e.message}');
    print('   - Type: ${e.type}');
    print('   - Response: ${e.response?.data}');
    print('   - Status Code: ${e.response?.statusCode}');
    
    setState(() {
      _statusMessage =
          e.response?.data?['message'] ?? e.message ?? 'Gagal upload';
      _isSuccess = false;
    });
  } finally {
    setState(() {
      _isLoading = false;
    });
    print('🏁 Proses upload selesai');
  }
}

Future<void> _importData() async {
  if (_sessionId == null) return;

  print('🚀 MEMULAI PROSES IMPORT DATA - Tipe: ${widget.tipe}');
  print('🆔 Session ID: $_sessionId');

  setState(() {
    _isLoading = true;
    _statusMessage = 'Sedang mengimport data...';
  });

  try {
    final apiUrl = _getImportApiUrl();
    print('🌐 URL API Import: $apiUrl');

    final response = await _dio.post(
      apiUrl,
      data: {'session_id': _sessionId},
      options: Options(headers: {
        'Authorization': 'Bearer $_authToken',
      }),
    );

    print('📥 Response import status: ${response.statusCode}');
    print('📦 Response import data: ${response.data}');

    if (response.statusCode == 200) {
      final data = response.data;
      if (data['success'] == true) {
        print('✅ IMPORT BERHASIL!');
        print('📊 Detail Import:');
        
        if (widget.tipe == 'guru') {
          print('👨‍🏫 DATA GURU BERHASIL DIIMPOR:');
          final insertedCount = data['inserted_count'] ?? 
              _previewData?['summary']?['valid_count'] ?? 0;
          print('   - Jumlah guru diimpor: $insertedCount');
          
          // Coba ambil detail dari response jika ada
          if (data['data'] != null) {
            final importedData = data['data'];
            print('   - Data yang diimpor: $importedData');
          }
        }

        // Tampilkan popup sukses
        await _showSuccessPopup(
          'Data ${_getEntityName()} berhasil diimport!',
          '${_previewData!['summary']['valid_count']} data ${_getEntityName().toLowerCase()} telah ditambahkan.',
        );

        print('📱 Menampilkan popup sukses');
        widget.onImportSuccess?.call();

        if (mounted) {
          print('👋 Menutup halaman import');
          Navigator.pop(context);
        }
      } else {
        print('❌ IMPORT GAGAL: ${data['message']}');
        setState(() {
          _statusMessage = data['message'] ?? 'Gagal import data';
          _isSuccess = false;
          _isLoading = false;
        });
      }
    }
  } on DioException catch (e) {
    print('🚨 DIO EXCEPTION SAAT IMPORT:');
    print('   - Message: ${e.message}');
    print('   - Type: ${e.type}');
    print('   - Response: ${e.response?.data}');
    print('   - Status Code: ${e.response?.statusCode}');
    
    setState(() {
      _statusMessage = e.response?.data?['message'] ?? 'Gagal import data';
      _isSuccess = false;
      _isLoading = false;
    });
  }
}

  Future<void> _showSuccessPopup(String title, String message) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SuccessPopup(
        title: title,
        message: message,
        onClose: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF641E20),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ============================================
// Popup Sukses yang Elegan
// ============================================

class SuccessPopup extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback onClose;

  const SuccessPopup({
    super.key,
    required this.title,
    required this.message,
    required this.onClose,
  });

  @override
  State<SuccessPopup> createState() => _SuccessPopupState();
}

class _SuccessPopupState extends State<SuccessPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Auto close setelah 3 detik
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _closePopup();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _closePopup() {
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onClose();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        _closePopup();
        return false;
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Success Icon dengan animasi
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Message
                  Text(
                    widget.message,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // Close Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _closePopup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF641E20),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Tutup',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}