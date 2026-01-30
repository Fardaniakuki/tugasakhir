import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ajukan_pkl_dialog.dart';
import '../../login/login_screen.dart';
import 'detail_popup.dart';
import 'industri_list_page.dart';
import 'websocket_manager.dart';
import 'notification_popup.dart';

class SiswaDashboard extends StatefulWidget {
  const SiswaDashboard(
      {super.key, required void Function() onAjukanPklPressed});

  @override
  State<SiswaDashboard> createState() => _SiswaDashboardState();
}

class _SiswaDashboardState extends State<SiswaDashboard> {
  String _namaSiswa = 'Memuat...';
  String _kelasSiswa = 'Memuat...';
  int? _kelasId;
  bool _isLoading = true;
  bool _hasToken = false;

  Map<String, dynamic>? _pklData;
  List<dynamic> _pklApplications = [];
  Map<String, dynamic>? _industriData;
  Map<String, dynamic>? _pembimbingData;
  Map<String, dynamic>? _processedByData;

  // Cache variables
  static Map<String, dynamic>? _cachedPklData;
  static List<dynamic>? _cachedPklApplications;
  static Map<String, dynamic>? _cachedIndustriData;
  static Map<String, dynamic>? _cachedPembimbingData;
  static Map<String, dynamic>? _cachedProcessedByData;
  static bool _isCached = false;
  static String? _cachedNamaSiswa;
  static String? _cachedKelasSiswa;
  static int? _cachedKelasId;

  // ========== WEBSOCKET MANAGER ==========
  late WebSocketManager _webSocketManager;
  final List<Map<String, dynamic>> _notifications = [];
  int _unreadNotificationCount = 0;
  // =======================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // ========== CEK ACCESS TOKEN PERTAMA ==========
      final tokenValid = await _checkTokenOnStartup();

      if (!tokenValid) {
        _redirectToLogin();
        return;
      }

      // ========== INISIALISASI WEBSOCKET ==========
      _webSocketManager = WebSocketManager();
      _setupWebSocketListeners();

      // ========== LOAD DATA ==========
      await _checkAuthAndLoadData();
      await _loadNotificationsFromPrefs();

      // ========== CONNECT WEBSOCKET ==========
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _webSocketManager.connect();
        }
      });
    });
  }

  @override
  void dispose() {
    _webSocketManager.dispose();
    super.dispose();
  }

  // ========== TOKEN CHECK FUNCTIONS ==========
  Future<bool> _checkTokenOnStartup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        return false;
      }

      try {
        final response = await http.get(
          Uri.parse('${dotenv.env['API_BASE_URL']}/api/auth/me'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 401 || response.statusCode == 403) {
          return false;
        }

        if (response.statusCode == 200) {
          setState(() {
            _hasToken = true;
          });
          return true;
        }

        return true;
      } catch (e) {
        setState(() {
          _hasToken = true;
        });
        return true;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> _isTokenValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
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

  // ========== WEBSOCKET FUNCTIONS ==========
  void _setupWebSocketListeners() {
    _webSocketManager.addListener((event) {
      if (event.type == WebSocketEventType.message) {
        _handleWebSocketMessage(event.data);
      }
    });
  }

  void _handleWebSocketMessage(dynamic message) {
    try {
      final Map<String, dynamic> data;

      if (message is String) {
        data = jsonDecode(message);
      } else if (message is Map) {
        data = Map<String, dynamic>.from(message);
      } else {
        return;
      }

      _processNotification(data);
    // ignore: empty_catches
    } catch (e) {}
  }

  Future<void> _processNotification(Map<String, dynamic> data) async {
    final notificationData = data['data'];
    if (notificationData == null) return;

    final siswaUsername = notificationData['siswa_username']?.toString();
    final siswaId = notificationData['siswa_id']?.toString();

    final prefs = await SharedPreferences.getInstance();
    final currentUsername = prefs.getString('user_name');
    final currentUserId = prefs.getString('user_id');

    bool isForCurrentUser = false;

    if (siswaUsername != null && currentUsername != null) {
      isForCurrentUser = siswaUsername == currentUsername;
    } else if (siswaId != null && currentUserId != null) {
      isForCurrentUser = siswaId == currentUserId;
    }

    if (!isForCurrentUser) {
      return;
    }

    final String type = data['type'] ?? 'tidak_dikenal';

    switch (type) {
      case 'pkl_approved':
        await _handlePKLDisetujui(data);
        break;
      case 'pkl_rejected':
        await _handlePKLDitolak(data);
        break;
      default:
    }
  }

  Future<void> _saveNotificationsToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('user_name');
      if (userName != null && mounted) {
        final notificationsJson = jsonEncode(_notifications);
        await prefs.setString('notifications_$userName', notificationsJson);
      }
    // ignore: empty_catches
    } catch (e) {}
  }

  Future<void> _loadNotificationsOnLogin() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('user_name');

    if (userName != null && userName.isNotEmpty) {
      await _loadNotificationsFromPrefs();
    }
  }

  Future<void> _loadNotificationsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('user_name');

    if (userName == null) {
      return;
    }

    try {
      final key = 'notifications_$userName';
      final notificationsJson = prefs.getString(key);

      if (notificationsJson != null && notificationsJson.isNotEmpty) {
        try {
          final List<dynamic> loadedNotifications =
              jsonDecode(notificationsJson);
          setState(() {
            _notifications.clear();
            _notifications.addAll(
                loadedNotifications.map((n) => Map<String, dynamic>.from(n)));
            _unreadNotificationCount =
                _notifications.where((n) => !(n['read'] ?? false)).length;
          });
        // ignore: empty_catches
        } catch (e) {}
      }
    // ignore: empty_catches
    } catch (e) {}
  }

  Future<void> _handlePKLDisetujui(Map<String, dynamic> data) async {
    final notificationData = data['data'];
    if (notificationData == null) return;

    final industriNama = notificationData['industri_nama'] ?? 'Perusahaan';
    final catatan = notificationData['catatan'];
    final applicationId = notificationData['application_id'];
    final notificationId = 'pkl_approved_$applicationId';

    final prefs = await SharedPreferences.getInstance();
    final alreadyNotifiedKey = 'pkl_notified_$applicationId';
    final alreadyNotified = prefs.getBool(alreadyNotifiedKey) ?? false;

    if (!alreadyNotified) {
      final notification = {
        'id': notificationId,
        'title': 'PKL DISETUJUI! 🎉',
        'message': 'Pengajuan PKL ke $industriNama telah disetujui',
        'catatan': catatan,
        'timestamp': DateTime.now().toIso8601String(),
        'read': false,
        'type': 'disetujui',
        'data': data,
      };

      setState(() {
        _notifications.insert(0, notification);
        _unreadNotificationCount++;
      });

      await prefs.setBool(alreadyNotifiedKey, true);
      await _saveNotificationsToPrefs();

      if (mounted) {
        NotificationPopup.showApprovalPopup(
          context,
          industriNama: industriNama,
          catatan: catatan,
          onViewPressed: () {
            _loadAllData();
          },
        );
      }
    }

    await Future.delayed(const Duration(seconds: 2));
    await _loadAllData();
  }

  Future<void> _handlePKLDitolak(Map<String, dynamic> data) async {
    final notificationData = data['data'];
    if (notificationData == null) return;

    final industriNama = notificationData['industri_nama'] ?? 'Perusahaan';
    final catatan = notificationData['catatan'] ?? 'Tidak ada alasan diberikan';
    final applicationId = notificationData['application_id'];
    final notificationId = 'pkl_rejected_$applicationId';

    final prefs = await SharedPreferences.getInstance();
    final alreadyNotifiedKey = 'pkl_notified_$applicationId';
    final alreadyNotified = prefs.getBool(alreadyNotifiedKey) ?? false;

    if (!alreadyNotified) {
      final notification = {
        'id': notificationId,
        'title': 'PKL DITOLAK ❌',
        'message': 'Pengajuan PKL ke $industriNama ditolak',
        'catatan': catatan,
        'timestamp': DateTime.now().toIso8601String(),
        'read': false,
        'type': 'ditolak',
        'data': data,
      };

      setState(() {
        _notifications.insert(0, notification);
        _unreadNotificationCount++;
      });

      await prefs.setBool(alreadyNotifiedKey, true);
      await _saveNotificationsToPrefs();

      if (mounted) {
        NotificationPopup.showRejectionPopup(
          context,
          industriNama: industriNama,
          catatan: catatan,
          onReapplyPressed: () {
            _ajukanPKL();
          },
        );
      }
    }

    await Future.delayed(const Duration(seconds: 2));
    await _loadAllData();
  }

  Future<void> _resetNotificationFlags() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (var key in keys) {
      if (key.startsWith('pkl_notified_')) {
        await prefs.remove(key);
      }
    }
  }

  // ========== NOTIFICATION PANEL ==========
  void _showNotificationsPanel() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha:0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 180, 16, 4),
                        border: Border(
                          bottom:
                              BorderSide(color: Colors.grey[300]!, width: 1),
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.notifications,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'NOTIFIKASI',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (_unreadNotificationCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$_unreadNotificationCount',
                                style: const TextStyle(
                                  color: Color.fromARGB(255, 180, 16, 4),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Content
                    Expanded(
                      child: _notifications.isEmpty
                          ? _buildEmptyNotifications()
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              physics: const BouncingScrollPhysics(),
                              itemCount: _notifications.length,
                              itemBuilder: (context, index) {
                                final notification = _notifications[index];
                                final isRead = notification['read'] ?? false;
                                final isDisetujui =
                                    notification['type'] == 'disetujui';
                                final isDitolak =
                                    notification['type'] == 'ditolak';

                                return _buildNotificationCard(
                                  notification,
                                  isRead,
                                  isDisetujui,
                                  isDitolak,
                                  index,
                                  setState,
                                );
                              },
                            ),
                    ),

                    // Footer
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: Colors.grey[300]!, width: 1),
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[100],
                                foregroundColor: Colors.black,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Tutup'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (_unreadNotificationCount > 0)
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  for (var notification in _notifications) {
                                    notification['read'] = true;
                                  }
                                  setState(() {
                                    _unreadNotificationCount = 0;
                                  });
                                  await _saveNotificationsToPrefs();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromARGB(255, 180, 16, 4),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('Tandai Semua Dibaca'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Widget _buildNotificationCard(
    Map<String, dynamic> notification,
    bool isRead,
    bool isDisetujui,
    bool isDitolak,
    int index,
    StateSetter setState,
  ) {
    final timestamp = DateTime.parse(notification['timestamp']);
    final timeAgo = _formatTimeAgo(timestamp);
    final catatan = notification['catatan'] ?? '';

    return GestureDetector(
      onTap: () {
        if (!isRead) {
          setState(() {
            notification['read'] = true;
            _unreadNotificationCount--;
          });
          _saveNotificationsToPrefs();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.grey[50] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead
                ? Colors.grey[200]!
                : const Color.fromARGB(255, 180, 16, 4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isDitolak
                        ? Colors.red
                        : (isDisetujui ? Colors.green : Colors.orange),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    notification['title'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                if (!isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              notification['message'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            if (catatan.isNotEmpty && catatan != 'Tidak ada alasan diberikan')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  catatan,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                if (isDitolak)
                  TextButton(
                    onPressed: _ajukanPKL,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    child: const Text(
                      'Ajukan Ulang',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color.fromARGB(255, 180, 16, 4),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyNotifications() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada notifikasi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Semua update status pengajuan PKL akan muncul di sini',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years tahun lalu';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months bulan lalu';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }

  // ========== DATA LOADING FUNCTIONS ==========
  Future<void> _checkAuthAndLoadData() async {
    if (!await _isTokenValid()) {
      _redirectToLogin();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      _redirectToLogin();
      return;
    }

    // Gunakan data cache jika tersedia
    if (_isCached) {
      _loadFromCache();
      setState(() {
        _isLoading = false;
      });
    } else {
      await _loadAllData();
    }
  }

  void _loadFromCache() {
    if (_cachedPklData != null) _pklData = _cachedPklData;
    if (_cachedPklApplications != null) {
      _pklApplications = _cachedPklApplications!;
    }
    if (_cachedIndustriData != null) _industriData = _cachedIndustriData;
    if (_cachedPembimbingData != null) _pembimbingData = _cachedPembimbingData;
    if (_cachedProcessedByData != null) {
      _processedByData = _cachedProcessedByData;
    }
    if (_cachedNamaSiswa != null) _namaSiswa = _cachedNamaSiswa!;
    if (_cachedKelasSiswa != null) _kelasSiswa = _cachedKelasSiswa!;
    if (_cachedKelasId != null) _kelasId = _cachedKelasId;
  }

  void _saveToCache() {
    _cachedPklData = _pklData;
    _cachedPklApplications = _pklApplications;
    _cachedIndustriData = _industriData;
    _cachedPembimbingData = _pembimbingData;
    _cachedProcessedByData = _processedByData;
    _cachedNamaSiswa = _namaSiswa;
    _cachedKelasSiswa = _kelasSiswa;
    _cachedKelasId = _kelasId;
    _isCached = true;
  }

  Future<void> _loadAllData() async {
    if (!await _isTokenValid()) {
      _redirectToLogin();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      _redirectToLogin();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _loadProfileData();
      await _loadPklApplications();
      await _loadNotificationsOnLogin();
      _saveToCache();
    } catch (e) {
      if (e.toString().contains('401') ||
          e.toString().contains('Unauthorized')) {
        _redirectToLogin();
        return;
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadProfileData() async {
    if (!await _isTokenValid()) {
      _redirectToLogin();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final userName = prefs.getString('user_name');

    if (token == null || token.isEmpty) {
      _redirectToLogin();
      return;
    }

    try {
      final apiUrl = '${dotenv.env['API_BASE_URL']}/api/siswa?search=$userName';

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true &&
            data['data'] != null &&
            data['data']['data'] != null &&
            data['data']['data'].isNotEmpty) {
          final List<dynamic> siswaList = data['data']['data'];

          final matchedSiswa = siswaList.firstWhere(
              (siswa) => siswa['nama_lengkap'] == userName, orElse: () {
            return siswaList.first;
          });

          final kelasId = matchedSiswa['kelas_id'];
          String kelasNama = 'Kelas Tidak Tersedia';

          if (kelasId != null) {
            try {
              final kelasResponse = await http.get(
                Uri.parse('${dotenv.env['API_BASE_URL']}/api/kelas/$kelasId'),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
              );

              if (kelasResponse.statusCode == 200) {
                final kelasData = jsonDecode(kelasResponse.body);
                if (kelasData['success'] == true && kelasData['data'] != null) {
                  kelasNama =
                      kelasData['data']['nama'] ?? 'Kelas Tidak Tersedia';
                }
              }
            // ignore: empty_catches
            } catch (e) {}
          }

          final userId = matchedSiswa['id']?.toString();
          if (userId != null) {
            await prefs.setString('user_id', userId);
          }

          await prefs.setInt('kelas_id', kelasId);
          await prefs.setInt('user_kelas_id', kelasId);
          await prefs.setString('kelas_nama', kelasNama);
          await prefs.setString('user_kelas', kelasNama);

          if (mounted) {
            setState(() {
              _namaSiswa = userName ?? 'Nama Tidak Tersedia';
              _kelasSiswa = kelasNama;
              _kelasId = kelasId;
            });
          }
          return;
        }
      } else if (response.statusCode == 401) {
        _redirectToLogin();
        return;
      }
    // ignore: empty_catches
    } catch (e) {}

    if (mounted) {
      final kelasIdFromPrefs =
          prefs.getInt('kelas_id') ?? prefs.getInt('user_kelas_id');
      final kelasNamaFromPrefs = prefs.getString('kelas_nama') ??
          prefs.getString('user_kelas') ??
          'Kelas Tidak Tersedia';

      setState(() {
        _namaSiswa = userName ?? 'Nama Tidak Tersedia';
        _kelasSiswa = kelasNamaFromPrefs;
        _kelasId = kelasIdFromPrefs;
      });
    }
  }

  Future<void> _loadPklApplications() async {
    if (!await _isTokenValid()) {
      _redirectToLogin();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      _redirectToLogin();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/pkl/applications/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null && data['data'].isNotEmpty) {
          if (mounted) {
            setState(() {
              _pklApplications = data['data'];
              _pklApplications.sort((a, b) => b['id'].compareTo(a['id']));
            });
          }

          final approvedApplications = _pklApplications.where((app) {
            final status = app['status'].toString().toLowerCase();
            return status == 'disetujui' || status == 'approved';
          }).toList();

          if (approvedApplications.isNotEmpty) {
            if (mounted) {
              setState(() {
                _pklData = approvedApplications.first;
              });
            }

            if (_pklData?['industri_id'] != null) {
              await _loadIndustriData(_pklData!['industri_id']);
            }
            if (_pklData?['pembimbing_guru_id'] != null) {
              await _loadPembimbingData(_pklData!['pembimbing_guru_id']);
            }
            if (_pklData?['processed_by'] != null) {
              await _loadProcessedByData(_pklData!['processed_by']);
            }
          } else {
            final latestApplication = _pklApplications.first;
            if (mounted) {
              setState(() {
                _pklData = latestApplication;
              });
            }

            if (latestApplication['industri_id'] != null) {
              await _loadIndustriData(latestApplication['industri_id']);
            }
            if (latestApplication['processed_by'] != null) {
              await _loadProcessedByData(latestApplication['processed_by']);
            }
            if (latestApplication['pembimbing_guru_id'] != null) {
              await _loadPembimbingData(
                  latestApplication['pembimbing_guru_id']);
            }
          }
        } else {
          if (mounted) {
            setState(() {
              _pklData = null;
            });
          }
        }
      } else if (response.statusCode == 401) {
        _redirectToLogin();
      }
    } catch (_) {}
  }

  Future<void> _loadIndustriData(int industriId) async {
    if (!await _isTokenValid()) {
      _redirectToLogin();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      _redirectToLogin();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/industri/$industriId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() => _industriData = data['data']);
        }
      } else if (response.statusCode == 401) {
        _redirectToLogin();
      }
    } catch (_) {}
  }

  Future<void> _loadPembimbingData(int? guruId) async {
    if (guruId == null) return;

    if (!await _isTokenValid()) {
      _redirectToLogin();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      _redirectToLogin();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/guru/$guruId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() => _pembimbingData = data['data']);
        }
      } else if (response.statusCode == 401) {
        _redirectToLogin();
      }
    } catch (_) {}
  }

  Future<void> _loadProcessedByData(int? guruId) async {
    if (guruId == null) return;

    if (!await _isTokenValid()) {
      _redirectToLogin();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      _redirectToLogin();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/guru/$guruId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() => _processedByData = data['data']);
        }
      } else if (response.statusCode == 401) {
        _redirectToLogin();
      }
    } catch (_) {}
  }

  Future<void> _ajukanPKL() async {
    if (!await _isTokenValid()) {
      _redirectToLogin();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      _redirectToLogin();
      return;
    }

    try {
      if (_kelasId == null) {
        await _loadProfileData();
      }

      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AjukanPKLDialog(
          token: token,
          kelasId: _kelasId,
          primaryColor: const Color(0xFF9f0712),
        ),
      );

      if (result != null) {
        final response = await http.post(
          Uri.parse('${dotenv.env['API_BASE_URL']}/api/pkl/applications'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'catatan': result['catatan'],
            'industri_id': result['industri_id'],
          }),
        );

        if (response.statusCode == 201) {
          await _resetNotificationFlags();
          _clearCache();
          await _loadAllData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pengajuan PKL berhasil dikirim'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else if (response.statusCode == 401) {
          _redirectToLogin();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal mengajukan PKL: ${response.body}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan saat mengajukan PKL'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearCache() {
    _isCached = false;
    _cachedPklData = null;
    _cachedPklApplications = null;
    _cachedIndustriData = null;
    _cachedPembimbingData = null;
    _cachedProcessedByData = null;
    _cachedNamaSiswa = null;
    _cachedKelasSiswa = null;
    _cachedKelasId = null;
  }

  Future<void> _bukaIndustri() async {
    if (!await _isTokenValid()) {
      _redirectToLogin();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      _redirectToLogin();
      return;
    }

    if (mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const IndustriListPage(),
        ),
      );
    }
  }

  Future<void> _bukaRiwayat() async {
    if (!await _isTokenValid()) {
      _redirectToLogin();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      _redirectToLogin();
      return;
    }

    try {
      if (_pklApplications.isEmpty) {
        await _loadPklApplications();
      }

      if (mounted) {
        await DetailPopup.showRiwayatPopup(
          context,
          _pklApplications,
          industriData: _industriData,
          formatTanggal: _formatTanggal,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memuat riwayat'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'disetujui':
      case 'approved':
        return const Color.fromARGB(255, 46, 125, 50);
      case 'ditolak':
      case 'rejected':
        return Colors.red;
      case 'menunggu':
      case 'pending':
        return Colors.orange;
      default:
        return Colors.orange;
    }
  }

  String _formatTanggal(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';

    try {
      final date = DateTime.parse(dateString);
      final bulan = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des'
      ];

      return '${date.day} ${bulan[date.month - 1]} ${date.year}';
    } catch (e) {
      return '-';
    }
  }

  int _getCurrentProgressStatus(String? status) {
    if (status == null) return 0;

    switch (status.toLowerCase()) {
      case 'menunggu':
      case 'pending':
        return 1;
      case 'disetujui':
      case 'approved':
        return 2;
      case 'selesai':
      case 'completed':
        return 3;
      default:
        return 0;
    }
  }

  String _getStatusText(String? status) {
    if (status == null) return 'Belum Mengajukan';

    switch (status.toLowerCase()) {
      case 'menunggu':
      case 'pending':
        return 'Menunggu';
      case 'disetujui':
      case 'approved':
        return 'Menjalankan PKL';
      case 'selesai':
      case 'completed':
        return 'Selesai PKL';
      default:
        return 'Mengajukan';
    }
  }

  bool _hasDisetujuiApplication() {
    if (_pklData == null) return false;
    final status = _pklData!['status'].toString().toLowerCase();
    return status == 'disetujui' || status == 'approved';
  }

  bool _hasDitolakApplication() {
    if (_pklData == null) return false;
    final status = _pklData!['status'].toString().toLowerCase();
    return status == 'ditolak' || status == 'rejected';
  }

  @override
  Widget build(BuildContext context) {
    // Jika tidak ada token, tampilkan loading screen yang akan redirect
    if (!_hasToken && _isLoading) {
      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 180, 16, 4),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'MEMERIKSA LOGIN...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color.fromARGB(255, 180, 16, 4),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 180, 16, 4),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header dengan notifikasi badge
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, $_namaSiswa!',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Selamat datang di dashboard PKL',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha:0.8),
                          ),
                        ),
                      ],
                    ),
                    Stack(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha:0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: _showNotificationsPanel,
                            icon: const Icon(
                              Icons.notifications,
                              size: 24,
                              color: Color.fromARGB(255, 180, 16, 4),
                            ),
                          ),
                        ),
                        if (_unreadNotificationCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  _unreadNotificationCount > 9
                                      ? '9+'
                                      : '$_unreadNotificationCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Container waktu PKL dengan progress bar
              Container(
                margin: const EdgeInsets.only(top: 10, left: 20, right: 20),
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha:0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _isLoading
                    ? _buildTimeSectionSkeleton()
                    : Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildTimeItem(
                                  'Mulai',
                                  _pklData != null
                                      ? _formatTanggal(
                                          _pklData!['tanggal_mulai'])
                                      : '-'),
                              Container(
                                width: 2,
                                height: 40,
                                color: Colors.grey[300],
                              ),
                              _buildTimeItem(
                                  'Selesai',
                                  _pklData != null
                                      ? _formatTanggal(
                                          _pklData!['tanggal_selesai'])
                                      : '-'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                height: 27,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(13.5),
                                ),
                                child: Stack(
                                  children: [
                                    Container(
                                      width:
                                          (MediaQuery.of(context).size.width -
                                                  88) *
                                              ((_getCurrentProgressStatus(
                                                          _pklData?['status']) +
                                                      1.2) /
                                                  4),
                                      height: 27,
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                            255, 88, 89, 90),
                                        borderRadius:
                                            BorderRadius.circular(13.5),
                                      ),
                                      child: Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12),
                                          child: Text(
                                            _getStatusText(_pklData?['status']),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),

              // Container utama
              Container(
                margin: const EdgeInsets.only(top: 30),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Aksi cepat
                      _isLoading
                          ? _buildQuickActionsSkeleton()
                          : Container(
                              width: double.infinity,
                              height: 140,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color.fromARGB(255, 128, 13, 7),
                                    Color.fromARGB(255, 175, 20, 9),
                                    Color(0xFFD11F0B),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(31),
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    left: 140,
                                    top: 22,
                                    bottom: 22,
                                    child: Container(
                                      width: 1,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Positioned(
                                    left: 158,
                                    right: 22,
                                    top: 70,
                                    child: Container(
                                      height: 1,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Positioned(
                                    left: 45,
                                    top: 40,
                                    child: _buildMenuOptionKiri('Pengajuan',
                                        Icons.assignment_add, _ajukanPKL),
                                  ),
                                  Positioned(
                                    right: 85,
                                    top: 20,
                                    child: _buildMenuOptionKanan('Industri',
                                        Icons.factory, _bukaIndustri),
                                  ),
                                  Positioned(
                                    right: 85,
                                    bottom: 20,
                                    child: _buildMenuOptionKanan(
                                        'Riwayat', Icons.history, _bukaRiwayat),
                                  ),
                                ],
                              ),
                            ),

                      const SizedBox(height: 30),

                      // Judul Daftar Pengajuan PKL
                      _isLoading
                          ? _buildTitleSkeleton()
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Pengajuan PKL Disetujui',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  _hasDisetujuiApplication()
                                      ? '1 Disetujui'
                                      : (_hasDitolakApplication()
                                          ? '1 Ditolak'
                                          : _pklData != null
                                              ? '1 Menunggu'
                                              : '0 Pengajuan'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),

                      const SizedBox(height: 16),

                      // Tampilkan pengajuan
                      if (_isLoading)
                        _buildPKLCardSkeleton()
                      else if (_pklData != null)
                        _buildPengajuanCard({
                          'status': _pklData!['status'],
                          'industri_nama': _industriData?['nama'] ?? 'Industri',
                          'tanggal_permohonan':
                              _formatTanggal(_pklData!['tanggal_permohonan']),
                          'tanggal_mulai':
                              _formatTanggal(_pklData!['tanggal_mulai']),
                          'tanggal_selesai':
                              _formatTanggal(_pklData!['tanggal_selesai']),
                          'catatan': _pklData!['catatan'] ?? '-',
                          'kaprog_note':
                              _pklData!['kaprog_note'] ?? 'Tidak ada catatan',
                          'decided_at': _formatTanggal(_pklData!['decided_at']),
                          'diproses_oleh': _processedByData?['nama'] ?? '-',
                          'pembimbing_pkl': _pembimbingData?['nama'] ?? '-',
                        })
                      else
                        _buildNoPengajuanCard(),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== SKELETON LOADING WIDGETS ==========
  Widget _buildTimeSectionSkeleton() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTimeItemSkeleton(),
            Container(
              width: 2,
              height: 40,
              color: Colors.grey[300],
            ),
            _buildTimeItemSkeleton(),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          height: 27,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(13.5),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeItemSkeleton() {
    return Column(
      children: [
        Container(
          width: 40,
          height: 12,
          color: Colors.grey[300],
        ),
        const SizedBox(height: 4),
        Container(
          width: 60,
          height: 18,
          color: Colors.grey[300],
        ),
      ],
    );
  }

  Widget _buildQuickActionsSkeleton() {
    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(31),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 140,
            top: 22,
            bottom: 22,
            child: Container(
              width: 2,
              color: Colors.grey[300],
            ),
          ),
          Positioned(
            left: 158,
            right: 22,
            top: 70,
            child: Container(
              height: 2,
              color: Colors.grey[300],
            ),
          ),
          Positioned(
            left: 45,
            top: 40,
            child: _buildMenuOptionSkeleton(),
          ),
          Positioned(
            right: 85,
            top: 20,
            child: _buildMenuOptionSkeletonKanan(),
          ),
          Positioned(
            right: 85,
            bottom: 20,
            child: _buildMenuOptionSkeletonKanan(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOptionSkeleton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: 12,
          color: Colors.grey[300],
        ),
      ],
    );
  }

  Widget _buildMenuOptionSkeletonKanan() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 50,
          height: 12,
          color: Colors.grey[300],
        ),
      ],
    );
  }

  Widget _buildTitleSkeleton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 150,
          height: 20,
          color: Colors.grey[300],
        ),
        Container(
          width: 80,
          height: 12,
          color: Colors.grey[300],
        ),
      ],
    );
  }

  Widget _buildPKLCardSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 150,
            height: 20,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 200, height: 14, color: Colors.grey[200]),
              const SizedBox(height: 4),
              Container(width: 180, height: 14, color: Colors.grey[200]),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 100, height: 12, color: Colors.grey[200]),
              const SizedBox(height: 2),
              Container(width: 80, height: 14, color: Colors.grey[300]),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 80, height: 12, color: Colors.grey[200]),
                const SizedBox(height: 4),
                Container(
                    width: double.infinity,
                    height: 14,
                    color: Colors.grey[300]),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 80, height: 12, color: Colors.grey[200]),
                const SizedBox(height: 4),
                Container(
                    width: double.infinity,
                    height: 14,
                    color: Colors.grey[300]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPengajuanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color.fromARGB(255, 180, 16, 4),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.assignment_outlined,
            size: 60,
            color: Color.fromARGB(255, 180, 16, 4),
          ),
          const SizedBox(height: 20),
          const Text(
            'Belum ada pengajuan yang disetujui',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Ajukan PKL untuk memulai praktik kerja lapangan',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _ajukanPKL,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 180, 16, 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Ajukan PKL Sekarang',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ========== END SKELETON LOADING WIDGETS ==========

  Widget _buildTimeItem(String label, String date) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          date,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
Widget _buildPengajuanCard(Map<String, dynamic> pengajuan) {
  final status = pengajuan['status'];
  // Gunakan fungsi _translateStatus untuk mendapatkan status dalam Bahasa Indonesia
  final statusText = _translateStatus(status);
  final isDisetujui = status.toLowerCase() == 'disetujui';

  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha:0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      border: Border.all(
        color: Colors.grey[200]!,
        width: 1,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _statusColor(status).withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _statusColor(status),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDisetujui ? Icons.check_circle : Icons.access_time,
                size: 14,
                color: _statusColor(status),
              ),
              const SizedBox(width: 4),
              Text(
                statusText,
                style: TextStyle(
                  color: _statusColor(status),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          pengajuan['industri_nama'],
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Diproses oleh: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                      TextSpan(
                        text: pengajuan['diproses_oleh'],
                        style: TextStyle(
                          fontSize: 12,
                          color: _statusColor(status),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Pembimbing PKL: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                    TextSpan(
                      text: pengajuan['pembimbing_pkl'],
                      style: TextStyle(
                        fontSize: 12,
                        color: _statusColor(status),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tanggal Pengajuan',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pengajuan['tanggal_permohonan'],
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 248, 249, 250),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Catatan Pengajuan:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                pengajuan['catatan'],
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _statusColor(status).withValues(alpha:0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Catatan Kaprog:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _statusColor(status),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                pengajuan['kaprog_note'],
                style: TextStyle(
                  fontSize: 12,
                  color: _statusColor(status),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Diputuskan pada: ${pengajuan['decided_at']}',
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    ),
  );
}

// Fungsi untuk menerjemahkan status ke Bahasa Indonesia
String _translateStatus(String status) {
  switch (status.toLowerCase()) {
    case 'approved':
      return 'DISETUJUI';
    case 'rejected':
      return 'DITOLAK';
    case 'pending':
      return 'MENUNGGU';
    case 'completed':
      return 'SELESAI';
    case 'disetujui':
      return 'DISETUJUI';
    case 'ditolak':
      return 'DITOLAK';
    case 'menunggu':
      return 'MENUNGGU';
    case 'selesai':
      return 'SELESAI';
    default:
      return status.toUpperCase();
  }
}

// Fungsi untuk mendapatkan warna berdasarkan status
  Widget _buildMenuOptionKiri(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: const Color.fromARGB(255, 180, 16, 4),
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOptionKanan(
      String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: const Color.fromARGB(255, 180, 16, 4),
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}