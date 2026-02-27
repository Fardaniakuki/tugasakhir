// File: lib/screens/siswa/siswa_dashboard.dart

// ignore_for_file: empty_catches, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ajukan_pkl_dialog.dart';
import '../../login/login_screen.dart';
import 'detail_popup.dart';
import 'industri_list_page.dart';
import 'websocket_manager.dart';
import 'notification_popup.dart';
import 'dashboard_helpers.dart';
import 'edit_members_dialog.dart';

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
  int? _currentUserId;
  bool _isLoading = true;
  bool _initialLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  // Data PKL Individual
  Map<String, dynamic>? _pklData;
  List<dynamic> _pklApplications = [];
  Map<String, dynamic>? _industriData;
  Map<String, dynamic>? _pembimbingData;
  Map<String, dynamic>? _processedByData;

  // Data Group PKL
  List<PKLGroupModel> _myGroups = [];
  PKLGroupModel? _activeGroup;
  bool _isInGroup = false;

  // NEW: Invitations data
  List<GroupInvitation> _invitations = [];
  bool _hasInvitations = false;
  bool _isProcessingInvitation = false;

  // Cache
  static Map<String, dynamic>? _cachedPklData;
  static List<dynamic>? _cachedPklApplications;
  static Map<String, dynamic>? _cachedIndustriData;
  static Map<String, dynamic>? _cachedPembimbingData;
  static Map<String, dynamic>? _cachedProcessedByData;
  static List<PKLGroupModel>? _cachedGroups;
  static List<GroupInvitation>? _cachedInvitations; // NEW
  static bool _isCached = false;
  static String? _cachedNamaSiswa;
  static String? _cachedKelasSiswa;
  static int? _cachedKelasId;
  static int? _cachedUserId;

  // WebSocket
  late WebSocketManager _webSocketManager;
  final List<Map<String, dynamic>> _notifications = [];
  int _unreadNotificationCount = 0;

  Timer? _loadingTimeoutTimer;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _handleRefresh() async {
    // Cek token terlebih dahulu
    if (!await _isTokenValid()) {
      _redirectToLogin();
      return;
    }

    // Clear cache agar mengambil data baru dari server
    _clearCache();

    // Reload semua data
    await _loadAllData(forceRefresh: true);
  }

// Tambahkan method ini di dalam class _SiswaDashboardState
  Future<List<IndustriModel>> _loadAvailableIndustries() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return [];

    return await IndustriApiHelper.getAvailableIndustries(token: token);
  }

  Future<void> _initializeApp() async {
    try {
      _loadingTimeoutTimer = Timer(const Duration(seconds: 8), () {
        if (mounted && _initialLoading) {
          setState(() {
            _hasError = true;
            _errorMessage = 'Timeout: Gagal memuat data. Cek koneksi internet.';
            _initialLoading = false;
            _isLoading = false;
          });
        }
      });

      final tokenValid = await _checkTokenOnStartup();
      if (!tokenValid) {
        _redirectToLogin();
        _loadingTimeoutTimer?.cancel();
        return;
      }

      _webSocketManager = WebSocketManager();
      _setupWebSocketListeners();

      await _checkAuthAndLoadData();

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) _webSocketManager.connect();
      });

      _loadingTimeoutTimer?.cancel();
    } catch (e) {
      if (mounted) _forceExitLoading();
      _loadingTimeoutTimer?.cancel();
    }
  }

  void _forceExitLoading() {
    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Gagal memuat data. Silakan coba lagi.';
        _initialLoading = false;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _loadingTimeoutTimer?.cancel();
    _webSocketManager.dispose();
    super.dispose();
  }

// ========== TOKEN CHECK ==========
  Future<bool> _checkTokenOnStartup() async {
    print('=== MEMULAI CEK TOKEN ===');

    try {
      final prefs = await SharedPreferences.getInstance();
      print('SharedPreferences berhasil diakses');

      final token = prefs.getString('access_token');
      print(
          'Token dari SharedPreferences: ${token != null ? "ADA (${token.substring(0, 10)}...)" : "TIDAK ADA"}');

      // Cek apakah token ada
      if (token == null || token.isEmpty) {
        print('❌ Token tidak ditemukan atau kosong');
        print('Token null: ${token == null}');
        print('Token empty: ${token?.isEmpty}');
        return false;
      }

      print('Token valid secara format, lanjut validasi ke server...');
      print('API Base URL: ${dotenv.env['API_BASE_URL']}');

      // Validasi token ke server
      try {
        final url = Uri.parse('${dotenv.env['API_BASE_URL']}/api/auth/me');
        print('Request URL: $url');

        final response = await http.get(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 5));

        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        print('Response headers: ${response.headers}');

        // Handle response
        if (response.statusCode == 200) {
          // Token valid
          print('✅ Token valid! Response 200 OK');
          return true;
        } else if (response.statusCode == 401) {
          print('❌ Token tidak valid (401 Unauthorized)');
          print('Kemungkinan token expired atau salah');
          await _clearTokenAndRedirect();
          return false;
        } else if (response.statusCode == 403) {
          print('❌ Token tidak memiliki akses (403 Forbidden)');
          print('Kemungkinan role tidak sesuai');
          await _clearTokenAndRedirect();
          return false;
        } else if (response.statusCode == 500) {
          print('⚠️ Server error (500 Internal Server Error)');
          print('Ini bukan masalah token, tapi server bermasalah');
          // Tetap anggap token valid karena ini error server
          return true;
        } else {
          // Status code lain
          print('⚠️ Response tidak terduga: ${response.statusCode}');
          print('Body: ${response.body}');
          // Anggap token valid untuk sementara
          return true;
        }
      } on TimeoutException catch (e) {
        // Timeout, anggap token valid untuk sementara
        print('⚠️ Timeout saat cek token: $e');
        print('Koneksi mungkin lambat atau server tidak merespons');
        return true;
      } on SocketException catch (e) {
        print('⚠️ SocketException: $e');
        print('Tidak bisa connect ke server. Cek koneksi internet');
        return true;
      } catch (e) {
        // Error lain
        print('❌ Error tidak terduga saat request: $e');
        print('Type error: ${e.runtimeType}');
        return true;
      }
    } catch (e) {
      print('❌ Error di _checkTokenOnStartup: $e');
      print('Stack trace:');
      print(StackTrace.current);
      return false;
    } finally {
      print('=== SELESAI CEK TOKEN ===');
    }
  }

// Helper method untuk membersihkan token dan redirect
  Future<void> _clearTokenAndRedirect() async {
    print('=== MEMBERSIHKAN TOKEN ===');
    try {
      final prefs = await SharedPreferences.getInstance();
      print('Menghapus semua data session...');

      await prefs.remove('access_token');
      print('access_token dihapus');

      await prefs.remove('refresh_token');
      print('refresh_token dihapus');

      await prefs.remove('user_name');
      print('user_name dihapus');

      await prefs.remove('user_id');
      print('user_id dihapus');

      await prefs.remove('user_role');
      print('user_role dihapus');

      // Clear cache juga
      _clearCache();
      print('Cache dibersihkan');

      if (mounted) {
        print('Redirect ke login screen...');
        _redirectToLogin();
      }

      print('✅ Token dan session berhasil dibersihkan');
    } catch (e) {
      print('❌ Error clearing token: $e');
    }
    print('=== SELESAI MEMBERSIHKAN TOKEN ===');
  }

// Method redirect ke login (sudah ada)
  void _redirectToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    });
  }
// Helper method untuk membersihkan token dan redirect

  Future<bool> _isTokenValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('access_token') != null;
    } catch (e) {
      return false;
    }
  }

  // ========== WEBSOCKET ==========
  void _setupWebSocketListeners() {
    _webSocketManager.addListener((event) {
      if (event.type == WebSocketEventType.message) {
        _handleWebSocketMessage(event.data);
      }
    });
  }

  void _handleWebSocketMessage(dynamic message) {
    try {
      final Map<String, dynamic> data = message is String
          ? jsonDecode(message)
          : Map<String, dynamic>.from(message);
      _processNotification(data);
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _processNotification(Map<String, dynamic> data) async {
    final notificationData = data['data'];
    if (notificationData == null) return;

    final prefs = await SharedPreferences.getInstance();
    final currentUsername = prefs.getString('user_name');
    final siswaUsername = notificationData['siswa_username']?.toString();

    if (siswaUsername == null ||
        currentUsername == null ||
        siswaUsername != currentUsername) {
      return;
    }

    final String type = data['type'] ?? '';
    switch (type) {
      case 'pkl_approved':
        await _handlePKLDisetujui(data);
        break;
      case 'pkl_rejected':
        await _handlePKLDitolak(data);
        break;
      case 'group_invitation': // NEW: Handle group invitation via WebSocket
        await _handleNewInvitation(data);
        break;
    }
  }

  // NEW: Handle new invitation notification
  Future<void> _handleNewInvitation(Map<String, dynamic> data) async {
    await _loadInvitations();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda mendapatkan undangan grup baru!'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  Future<void> _handlePKLDisetujui(Map<String, dynamic> data) async {
    final notificationData = data['data'];
    if (notificationData == null) return;

    final industriNama = notificationData['industri_nama'] ?? 'Perusahaan';
    final catatan = notificationData['catatan'];
    final applicationId = notificationData['application_id'];
    final notificationId = 'pkl_approved_$applicationId';

    final prefs = await SharedPreferences.getInstance();
    final alreadyNotified =
        prefs.getBool('pkl_notified_$applicationId') ?? false;

    if (!alreadyNotified) {
      setState(() {
        _notifications.insert(0, {
          'id': notificationId,
          'title': 'PKL DISETUJUI! 🎉',
          'message': 'Pengajuan PKL ke $industriNama telah disetujui',
          'catatan': catatan,
          'timestamp': DateTime.now().toIso8601String(),
          'read': false,
          'type': 'disetujui',
          'data': data,
        });
        _unreadNotificationCount++;
      });

      await prefs.setBool('pkl_notified_$applicationId', true);
      await _saveNotificationsToPrefs();

      if (mounted) {
        NotificationPopup.showApprovalPopup(
          context,
          industriNama: industriNama,
          catatan: catatan,
          onViewPressed: _loadAllData,
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
    final alreadyNotified =
        prefs.getBool('pkl_notified_$applicationId') ?? false;

    if (!alreadyNotified) {
      setState(() {
        _notifications.insert(0, {
          'id': notificationId,
          'title': 'PKL DITOLAK ❌',
          'message': 'Pengajuan PKL ke $industriNama ditolak',
          'catatan': catatan,
          'timestamp': DateTime.now().toIso8601String(),
          'read': false,
          'type': 'ditolak',
          'data': data,
        });
        _unreadNotificationCount++;
      });

      await prefs.setBool('pkl_notified_$applicationId', true);
      await _saveNotificationsToPrefs();

      if (mounted) {
        NotificationPopup.showRejectionPopup(
          context,
          industriNama: industriNama,
          catatan: catatan,
          onReapplyPressed: _ajukanPKL,
        );
      }
    }

    await Future.delayed(const Duration(seconds: 2));
    await _loadAllData();
  }

  Future<void> _saveNotificationsToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('user_name');
      if (userName != null) {
        await prefs.setString(
            'notifications_$userName', jsonEncode(_notifications));
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _loadNotificationsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('user_name');
    if (userName == null) return;

    try {
      final jsonStr = prefs.getString('notifications_$userName');
      if (jsonStr != null) {
        final List<dynamic> loaded = jsonDecode(jsonStr);
        setState(() {
          _notifications.clear();
          _notifications
              .addAll(loaded.map((n) => Map<String, dynamic>.from(n)));
          _unreadNotificationCount =
              _notifications.where((n) => !(n['read'] ?? false)).length;
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // ========== NOTIFICATION PANEL ==========
  void _showNotificationsPanel() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 180, 16, 4),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications,
                          color: Colors.white, size: 24),
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
                              horizontal: 8, vertical: 4),
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
                Expanded(
                  child: _notifications.isEmpty
                      ? _buildEmptyNotifications()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _notifications.length,
                          itemBuilder: (context, index) {
                            final notif = _notifications[index];
                            return NotificationCard(
                              notification: notif,
                              isRead: notif['read'] ?? false,
                              isDisetujui: notif['type'] == 'disetujui',
                              isDitolak: notif['type'] == 'ditolak',
                              onTap: () async {
                                if (!(notif['read'] ?? false)) {
                                  setState(() {
                                    notif['read'] = true;
                                    _unreadNotificationCount--;
                                  });
                                  await _saveNotificationsToPrefs();
                                }
                              },
                              onReapply: _ajukanPKL,
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
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
                          ),
                          child: const Text('Tutup'),
                        ),
                      ),
                      if (_unreadNotificationCount > 0) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              for (var n in _notifications) {
                                n['read'] = true;
                              }
                              setState(() => _unreadNotificationCount = 0);
                              await _saveNotificationsToPrefs();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 180, 16, 4),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Tandai Semua Dibaca'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) => mounted ? setState(() {}) : null);
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

  // ========== DATA LOADING ==========
  Future<void> _checkAuthAndLoadData() async {
    try {
      if (!await _isTokenValid()) {
        _redirectToLogin();
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) {
        _redirectToLogin();
        return;
      }

      if (_isCached) {
        final lastLoad = prefs.getInt('last_load_time') ?? 0;
        if (DateTime.now().millisecondsSinceEpoch - lastLoad < 5 * 60 * 1000) {
          _loadFromCache();
          if (mounted) {
            setState(() {
              _isLoading = false;
              _initialLoading = false;
            });
          }
          return;
        } else {
          _clearCache();
        }
      }

      await _loadAllData();
    } catch (e) {
      _forceExitLoading();
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
    if (_cachedGroups != null) {
      _myGroups = _cachedGroups!;
      _activeGroup = _myGroups.isNotEmpty ? _myGroups.first : null;
      _isInGroup = _myGroups.isNotEmpty;
    }
    // NEW: Load cached invitations
    if (_cachedInvitations != null) {
      _invitations = _cachedInvitations!;
      _hasInvitations = _invitations.isNotEmpty;
    }
    if (_cachedNamaSiswa != null) _namaSiswa = _cachedNamaSiswa!;
    if (_cachedKelasSiswa != null) _kelasSiswa = _cachedKelasSiswa!;
    if (_cachedKelasId != null) _kelasId = _cachedKelasId;
    if (_cachedUserId != null) _currentUserId = _cachedUserId;
  }

  void _saveToCache() {
    _cachedPklData = _pklData;
    _cachedPklApplications = _pklApplications;
    _cachedIndustriData = _industriData;
    _cachedPembimbingData = _pembimbingData;
    _cachedProcessedByData = _processedByData;
    _cachedGroups = _myGroups;
    _cachedInvitations = _invitations; // NEW
    _cachedNamaSiswa = _namaSiswa;
    _cachedKelasSiswa = _kelasSiswa;
    _cachedKelasId = _kelasId;
    _cachedUserId = _currentUserId;
    _isCached = true;

    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('last_load_time', DateTime.now().millisecondsSinceEpoch);
    });
  }

  Future<void> _loadAllData({bool forceRefresh = false}) async {
    print('=== LOAD ALL DATA ===');
    print('Force refresh: $forceRefresh');

    try {
      if (!await _isTokenValid()) {
        print('Token tidak valid, redirect');
        _redirectToLogin();
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) {
        print('Token null, redirect');
        _redirectToLogin();
        return;
      }

      if (mounted) setState(() => _isLoading = true);

      print('Loading profile data...');
      await _loadProfileData(token, prefs);

      print('Loading invitations...');
      await _loadInvitations();

      // Only load groups if no pending invitations
      if (!_hasInvitations) {
        print('No invitations, loading groups...');
        await _loadMyGroups(token);
      } else {
        print('Has invitations, skipping groups load');
      }

      await Future.delayed(const Duration(milliseconds: 300));

      if (!_isInGroup) {
        print('Not in group, loading active PKL...');
        await _loadActivePkl(token);
      }

      print('Loading PKL applications...');
      await _loadPklApplications(token);

      print('Loading notifications...');
      await _loadNotificationsFromPrefs();

      if (forceRefresh) {
        print('Force refresh: clearing cache');
        _clearCache();
      }

      print('Saving to cache...');
      _saveToCache();

      print('✅ Load all data completed');
    } catch (e) {
      print('❌ Error in _loadAllData: $e');
      print('Stack trace:');
      print(StackTrace.current);
      if (e.toString().contains('401')) _redirectToLogin();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _initialLoading = false;
        });
      }
    }
    print('=== END LOAD ALL DATA ===');
  }

  // NEW: Load invitations
  Future<void> _loadInvitations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/pkl/group/invitations'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _invitations = data.map((i) => GroupInvitation.fromJson(i)).toList();
          _hasInvitations = _invitations.isNotEmpty;
        });
      }
    } catch (e) {
      setState(() {
        _invitations = [];
        _hasInvitations = false;
      });
    }
  }

// NEW: Respond to invitation
  Future<void> _respondToInvitation(int invitationId, bool accept) async {
    print('=== RESPOND TO INVITATION ===');
    print('Invitation ID: $invitationId');
    print('Accept: $accept');

    if (!await _isTokenValid()) {
      print('❌ Token tidak valid, redirect ke login');
      _redirectToLogin();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) {
      print('❌ Token null, redirect ke login');
      _redirectToLogin();
      return;
    }

    setState(() => _isProcessingInvitation = true);

    try {
      final url = Uri.parse(
          '${dotenv.env['API_BASE_URL']}/api/pkl/group/invitations/$invitationId');
      print('Request URL: $url');
      print('Request body: ${jsonEncode({'accept': accept})}');

      final response = await http
          .post(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'accept': accept}),
          )
          .timeout(const Duration(seconds: 10));

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      print('Response headers: ${response.headers}');

      // PERBAIKAN: Terima semua status code 2xx (200-299)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✅ Request berhasil dengan status code: ${response.statusCode}');

        // Remove the invitation from list
        setState(() {
          _invitations.removeWhere((inv) => inv.id == invitationId);
          _hasInvitations = _invitations.isNotEmpty;
        });

        if (accept) {
          print('✅ Undangan diterima, load groups...');
          // If accepted, load the groups
          await _loadMyGroups(token);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Undangan diterima! Anda sekarang tergabung dalam kelompok'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          print('✅ Undangan ditolak');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Undangan ditolak'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }

        print('🔄 Clear cache dan reload data...');
        _clearCache();
        await _loadAllData();
        print('✅ Selesai memproses undangan');
      } else {
        // Ini yang menyebabkan "gagal" padahal mungkin berhasil dengan status code 204
        print('❌ Request gagal dengan status code: ${response.statusCode}');
        print('Error response body: ${response.body}');
        _handleErrorResponse(response);
      }
    } catch (e) {
      print('❌ Exception occurred: $e');
      print('Stack trace:');
      print(StackTrace.current);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      print('=== SELESAI RESPOND TO INVITATION ===');
      setState(() => _isProcessingInvitation = false);
    }
  }

  Future<void> _loadProfileData(String token, SharedPreferences prefs) async {
    try {
      final userName = prefs.getString('user_name');
      if (userName == null) {
        setState(() {
          _namaSiswa = 'Nama Tidak Ditemukan';
          _kelasSiswa = 'Kelas Tidak Ditemukan';
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/siswa?search=$userName'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true &&
            data['data']['data']?.isNotEmpty == true) {
          final siswaList = data['data']['data'];
          final dynamic matchedSiswa = siswaList.firstWhere(
            (s) => s['nama_lengkap'] == userName,
            orElse: () => siswaList.first,
          );

          final int? kelasId = matchedSiswa['kelas_id'] is int
              ? matchedSiswa['kelas_id']
              : int.tryParse(matchedSiswa['kelas_id']?.toString() ?? '');
          String kelasNama = 'Kelas Tidak Tersedia';

          if (kelasId != null) {
            try {
              final kelasRes = await http.get(
                Uri.parse('${dotenv.env['API_BASE_URL']}/api/kelas/$kelasId'),
                headers: {'Authorization': 'Bearer $token'},
              );
              if (kelasRes.statusCode == 200) {
                final kelasData = jsonDecode(kelasRes.body);
                kelasNama = kelasData['data']['nama'] ?? 'Kelas Tidak Tersedia';
              }
            } catch (e) {}
          }

          final userId = matchedSiswa['id']?.toString();
          if (userId != null) await prefs.setString('user_id', userId);

          await prefs.setInt('kelas_id', kelasId ?? 0);
          await prefs.setString('kelas_nama', kelasNama);

          setState(() {
            _namaSiswa = matchedSiswa['nama_lengkap'] ?? userName;
            _kelasSiswa = kelasNama;
            _kelasId = kelasId;
            _currentUserId = int.tryParse(userId ?? '');
          });
          return;
        }
      }
    } catch (e) {}

    setState(() {
      _namaSiswa = prefs.getString('user_name') ?? 'Nama Tidak Ditemukan';
      _kelasSiswa = prefs.getString('user_kelas') ?? 'Kelas Tidak Ditemukan';
      _kelasId = prefs.getInt('user_kelas_id');
    });
  }

  Future<void> _loadMyGroups(String token) async {
    print('=== LOAD MY GROUPS ===');
    try {
      final url = Uri.parse('${dotenv.env['API_BASE_URL']}/api/pkl/group/my');
      print('GET: $url');

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Groups found: ${data.length}');

        setState(() {
          _myGroups = data.map((g) => PKLGroupModel.fromJson(g)).toList();
          _activeGroup = _myGroups.isNotEmpty ? _myGroups.first : null;
          _isInGroup = _myGroups.isNotEmpty;
        });

        if (_activeGroup != null) {
          print('Active group ID: ${_activeGroup!.id}');
          print('Active group status: ${_activeGroup!.status}');
          await _loadIndustriData(_activeGroup!.industri.id, token);
        }
      } else if (response.statusCode == 404) {
        print('No groups found (404)');
        setState(() {
          _myGroups = [];
          _activeGroup = null;
          _isInGroup = false;
        });
      } else {
        print('Unexpected status code: ${response.statusCode}');
        _handleErrorResponse(response);
      }
    } catch (e) {
      print('Error loading groups: $e');
      setState(() {
        _myGroups = [];
        _activeGroup = null;
        _isInGroup = false;
      });
    }
    print('=== END LOAD MY GROUPS ===');
  }

  Future<void> _loadPklApplications(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/pkl/applications/me'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          setState(() {
            _pklApplications = data['data'];
            _pklApplications.sort((a, b) => b['id'].compareTo(a['id']));
          });
        }
      }
    } catch (e) {}
  }

  Future<void> _loadIndustriData(int industriId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/industri/$industriId'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _industriData = data['data']);
      }
    } catch (e) {}
  }

  Future<void> _loadPembimbingData(int? guruId, String token) async {
    if (guruId == null) return;
    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/guru/$guruId'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _pembimbingData = data['data']);
      }
    } catch (e) {}
  }

  Future<void> _loadProcessedByData(int? guruId, String token) async {
    if (guruId == null) return;
    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/guru/$guruId'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _processedByData = data['data']);
      }
    } catch (e) {}
  }

  Future<void> _loadActivePkl(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/pkl/active/me'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['id'] != null) {
          setState(() => _pklData = data);
          if (_pklData?['industri_id'] != null) {
            await _loadIndustriData(_pklData!['industri_id'], token);
          }
          if (_pklData?['pembimbing_guru_id'] != null) {
            await _loadPembimbingData(_pklData!['pembimbing_guru_id'], token);
          }
          if (_pklData?['processed_by'] != null) {
            await _loadProcessedByData(_pklData!['processed_by'], token);
          }
        } else {
          setState(() => _pklData = null);
        }
      } else if (response.statusCode == 404) {
        setState(() => _pklData = null);
      }
    } catch (e) {}
  }

  Future<void> _submitGroup() async {
    print('=== SUBMIT GROUP ===');

    if (_activeGroup == null) {
      print('❌ Tidak ada grup aktif');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada grup aktif'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (!await _isTokenValid()) {
      print('❌ Token tidak valid');
      _redirectToLogin();
      return;
    }

    // Validasi hanya ketua kelompok yang bisa submit
    if (_currentUserId == null ||
        !_activeGroup!.isUserLeader(_currentUserId!)) {
      print('❌ Bukan ketua kelompok');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hanya ketua kelompok yang bisa mengirim pengajuan'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Validasi status harus PENDING/DRAFT
    if (_activeGroup!.status.toLowerCase() != 'pending' &&
        _activeGroup!.status.toLowerCase() != 'draft') {
      print('❌ Status grup bukan PENDING/DRAFT: ${_activeGroup!.status}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group sudah dikirim atau sedang diproses'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Validasi semua anggota sudah menerima undangan
    final pendingMembers = _activeGroup!.getPendingMembers();
    if (pendingMembers.isNotEmpty) {
      print(
          '❌ Masih ada anggota yang belum menerima: ${pendingMembers.length}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Semua anggota harus menerima undangan terlebih dahulu (${pendingMembers.length} menunggu)'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Validasi minimal anggota (termasuk ketua)
    final acceptedMembers = _activeGroup!.getAcceptedMembers();
    if (acceptedMembers.length < 2) {
      print('❌ Anggota kurang dari 2: ${acceptedMembers.length}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Minimal 2 anggota (termasuk ketua) untuk mengirim'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Tampilkan dialog untuk input tanggal, catatan, dan pilihan industri
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _buildSubmitGroupDialog(),
    );

    if (result == null) {
      print('Dialog dibatalkan');
      return;
    }

    // Validasi industri_id
    if (result['industri_id'] == null) {
      print('❌ Industri tidak dipilih');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pilih industri tujuan'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Validasi tanggal
    final tanggalMulaiStr = result['tanggal_mulai'] as String;
    final tanggalSelesaiStr = result['tanggal_selesai'] as String;

    DateTime? tanggalMulai;
    DateTime? tanggalSelesai;

    try {
      tanggalMulai = DateTime.parse(tanggalMulaiStr);
      tanggalSelesai = DateTime.parse(tanggalSelesaiStr);
    } catch (e) {
      print('❌ Format tanggal tidak valid: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Format tanggal tidak valid'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (tanggalSelesai.isBefore(tanggalMulai)) {
      print('❌ Tanggal selesai sebelum tanggal mulai');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tanggal selesai harus setelah tanggal mulai'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Konfirmasi sebelum submit
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi Pengajuan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Yakin ingin mengirim pengajuan grup PKL ini?'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Informasi Industri
                      Row(
                        children: [
                          const Icon(Icons.business,
                              size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Industri',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                                Text(
                                  _activeGroup!.industri.nama,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),

                      // Tanggal Mulai
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 16, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tanggal Mulai',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                                Text(
                                  '${tanggalMulai!.day} ${_getMonthName(tanggalMulai.month)} ${tanggalMulai.year}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Tanggal Selesai
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 16, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tanggal Selesai',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                                Text(
                                  '${tanggalSelesai!.day} ${_getMonthName(tanggalSelesai.month)} ${tanggalSelesai.year}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      if (result['catatan'] != null &&
                          result['catatan'].toString().isNotEmpty) ...[
                        const Divider(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.note,
                                size: 16, color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Catatan',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                  Text(
                                    result['catatan'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],

                      const Divider(height: 16),

                      // Jumlah Anggota
                      Row(
                        children: [
                          const Icon(Icons.people,
                              size: 16, color: Colors.purple),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Jumlah Anggota',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                                Text(
                                  '${acceptedMembers.length} orang',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 180, 16, 4),
              ),
              child: const Text('Ya, Kirim',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      print('Submit dibatalkan');
      return;
    }

    // Kirim ke API
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) {
      _redirectToLogin();
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('Mengirim request ke API...');
      print('Group ID: ${_activeGroup!.id}');
      print('Industri ID: ${result['industri_id']}');
      print('Tanggal Mulai: ${result['tanggal_mulai']}');
      print('Tanggal Selesai: ${result['tanggal_selesai']}');
      print('Catatan: ${result['catatan']}');

      final response = await http
          .post(
            Uri.parse(
                '${dotenv.env['API_BASE_URL']}/api/pkl/group/${_activeGroup!.id}/submit'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'industri_id': result['industri_id'],
              'tanggal_mulai': result['tanggal_mulai'],
              'tanggal_selesai': result['tanggal_selesai'],
              'catatan': result['catatan'] ?? '',
            }),
          )
          .timeout(const Duration(seconds: 15));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✅ Group berhasil disubmit');

        // Clear cache dan reload data
        _clearCache();
        await _loadAllData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pengajuan grup PKL berhasil dikirim'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else if (response.statusCode == 400) {
        // Bad request - kemungkinan validasi error
        try {
          final errorData = jsonDecode(response.body);
          String errorMsg = errorData['message'] ?? 'Data tidak valid';

          // Handle specific error messages
          if (errorMsg.contains('already has an active or pending PKL')) {
            errorMsg =
                'Salah satu anggota sudah memiliki PKL aktif atau pending';
          } else if (errorMsg.contains('not all members have accepted')) {
            errorMsg = 'Belum semua anggota menerima undangan';
          } else if (errorMsg.contains('invalid date format')) {
            errorMsg = 'Format tanggal tidak valid';
          } else if (errorMsg.contains('end date must be after start date')) {
            errorMsg = 'Tanggal selesai harus setelah tanggal mulai';
          } else if (errorMsg.contains('industri not found')) {
            errorMsg = 'Industri tidak ditemukan';
          } else if (errorMsg.contains('industri is full')) {
            errorMsg = 'Kuota industri sudah penuh';
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMsg),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Data yang dikirim tidak valid'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else if (response.statusCode == 403) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Anda tidak memiliki izin untuk submit grup ini'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else if (response.statusCode == 404) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Grup tidak ditemukan'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        // Reload untuk refresh data
        _clearCache();
        await _loadAllData();
      } else if (response.statusCode == 409) {
        // Conflict - group already submitted or members have conflicts
        try {
          final errorData = jsonDecode(response.body);
          final String errorMsg =
              errorData['message'] ?? 'Grup sudah dalam proses pengajuan';

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMsg),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Grup sudah dalam proses pengajuan'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        print('❌ Gagal submit group: ${response.statusCode}');
        _handleErrorResponse(response);
      }
    } catch (e) {
      print('❌ Exception saat submit group: $e');
      print('Stack trace:');
      print(StackTrace.current);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print('=== SELESAI SUBMIT GROUP ===');
    }
  }

// Helper method untuk mendapatkan nama bulan
  String _getMonthName(int month) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return months[month - 1];
  }

// Helper method untuk format tanggal ke YYYY-MM-DD
  String _formatDateForApi(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

// Helper method untuk parse tanggal dari string
  DateTime? _parseDate(String dateStr) {
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  Widget _buildSubmitGroupDialog() {
    final TextEditingController tanggalMulaiController =
        TextEditingController();
    final TextEditingController tanggalSelesaiController =
        TextEditingController();
    final TextEditingController catatanController = TextEditingController();
    final TextEditingController searchController = TextEditingController();

    final DateTime now = DateTime.now();
    // Format as YYYY-MM-DD as expected by the API
    tanggalMulaiController.text = _formatDateForApi(now);
    tanggalSelesaiController.text = _formatDateForApi(
      now.add(const Duration(days: 90)),
    );

    // State untuk dialog
    List<IndustriModel> industries = [];
    List<IndustriModel> filteredIndustries = [];
    bool isLoadingIndustries = true;
    IndustriModel? selectedIndustri;
    String searchQuery = '';

    return StatefulBuilder(
      builder: (context, setState) {
        // Load industries if empty
        if (industries.isEmpty && isLoadingIndustries) {
          _loadAvailableIndustries().then((loadedIndustries) {
            setState(() {
              industries = loadedIndustries;
              filteredIndustries = loadedIndustries;
              isLoadingIndustries = false;

              // Auto-select if only one industry available
              if (loadedIndustries.length == 1) {
                selectedIndustri = loadedIndustries.first;
              }
            });
          });
        }

        return AlertDialog(
          title: const Text(
            'Kirim Kelompok PKL',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
              minWidth: 400,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label Pilihan Industri
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.factory, size: 18, color: Colors.grey[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'Pilih Industri Tujuan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Search Field
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari nama industri...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color.fromARGB(255, 180, 16, 4)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                        if (searchQuery.isEmpty) {
                          filteredIndustries = industries;
                        } else {
                          filteredIndustries = industries.where((industri) {
                            return industri.name
                                .toLowerCase()
                                .contains(searchQuery);
                          }).toList();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Daftar Industri (Hanya Nama)
                  isLoadingIndustries
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : filteredIndustries.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.factory_outlined,
                                        size: 40, color: Colors.grey[400]),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tidak ada industri tersedia',
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Container(
                              constraints: const BoxConstraints(maxHeight: 180),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: filteredIndustries.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final industri = filteredIndustries[index];
                                  final isSelected =
                                      selectedIndustri?.id == industri.id;
                                  final isAvailable = industri.isAvailable;

                                  return ListTile(
                                    onTap: isAvailable
                                        ? () {
                                            setState(() {
                                              selectedIndustri = industri;
                                            });
                                          }
                                        : null,
                                    leading: Radio<IndustriModel>(
                                      value: industri,
                                      groupValue: selectedIndustri,
                                      activeColor:
                                          const Color.fromARGB(255, 180, 16, 4),
                                      onChanged: isAvailable
                                          ? (value) {
                                              setState(() {
                                                selectedIndustri = value;
                                              });
                                            }
                                          : null,
                                    ),
                                    title: Text(
                                      industri.name,
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isAvailable
                                            ? Colors.black
                                            : Colors.grey,
                                      ),
                                    ),
                                    trailing: isAvailable
                                        ? null
                                        : Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              'Penuh',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.red,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                  );
                                },
                              ),
                            ),

                  const SizedBox(height: 16),

                  // Informasi Industri Terpilih (Ringkas)
                  if (selectedIndustri != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 180, 16, 4)
                            .withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color.fromARGB(255, 180, 16, 4)
                                .withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 180, 16, 4)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 14,
                              color: Color.fromARGB(255, 180, 16, 4),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Industri Terpilih',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  selectedIndustri!.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Garis Pemisah
                  const Divider(),

                  // Tanggal Mulai
                  const SizedBox(height: 8),
                  const Text(
                    'Periode PKL',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),

                  // Tanggal Mulai
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: tanggalMulaiController,
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Mulai',
                        hintText: 'YYYY-MM-DD',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.calendar_today,
                            size: 18, color: Colors.grey),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final DateTime? date = await showDatePicker(
                          context: context,
                          initialDate: now,
                          firstDate: now,
                          lastDate: now.add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            tanggalMulaiController.text =
                                _formatDateForApi(date);

                            // Jika tanggal selesai sebelum tanggal mulai, update
                            final DateTime? selesai =
                                _parseDate(tanggalSelesaiController.text);
                            if (selesai != null && selesai.isBefore(date)) {
                              tanggalSelesaiController.text = _formatDateForApi(
                                date.add(const Duration(days: 90)),
                              );
                            }
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tanggal Selesai
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: tanggalSelesaiController,
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Selesai',
                        hintText: 'YYYY-MM-DD',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.calendar_today,
                            size: 18, color: Colors.grey),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final DateTime startDate =
                            _parseDate(tanggalMulaiController.text) ?? now;
                        final DateTime? date = await showDatePicker(
                          context: context,
                          initialDate: startDate.add(const Duration(days: 90)),
                          firstDate: startDate,
                          lastDate: startDate.add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            tanggalSelesaiController.text =
                                _formatDateForApi(date);
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Catatan
                  const Text(
                    'Catatan (opsional)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: catatanController,
                      decoration: const InputDecoration(
                        hintText:
                            'Contoh: Ingin belajar di industri ini bersama teman',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                      ),
                      maxLines: 2,
                    ),
                  ),

                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pastikan semua anggota sudah menerima undangan sebelum mengirim',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
              ),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                // Validasi input
                if (selectedIndustri == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pilih industri tujuan'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                if (tanggalMulaiController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pilih tanggal mulai'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                if (tanggalSelesaiController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pilih tanggal selesai'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                // Validasi tanggal selesai tidak sebelum tanggal mulai
                final DateTime? mulai = _parseDate(tanggalMulaiController.text);
                final DateTime? selesai =
                    _parseDate(tanggalSelesaiController.text);

                if (mulai != null &&
                    selesai != null &&
                    selesai.isBefore(mulai)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Tanggal selesai harus setelah tanggal mulai'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(context, {
                  'industri_id': selectedIndustri!.id,
                  'tanggal_mulai': tanggalMulaiController.text,
                  'tanggal_selesai': tanggalSelesaiController.text,
                  'catatan': catatanController.text,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 180, 16, 4),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Kirim Pengajuan',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateGroupMembers() async {
    if (_activeGroup == null) return;

    if (!await _isTokenValid()) {
      _redirectToLogin();
      return;
    }

    if (_currentUserId == null ||
        !_activeGroup!.isUserLeader(_currentUserId!)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hanya ketua kelompok yang bisa ubah anggota'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Validasi status harus PENDING (DRAFT di database)
    if (_activeGroup!.status.toLowerCase() != 'pending') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hanya grup dengan status PENDING yang bisa diubah'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
// Di dalam method _updateGroupMembers, ganti bagian showDialog dengan:

    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => EditMembersDialog(
        group: _activeGroup!,
        currentUserId: _currentUserId!,
        onGetAvailableMembers: _getAvailableMembers,
        onSave: (selectedUsernames) {
          // Ini akan dipanggil setelah user menekan Simpan
          Navigator.of(context).pop(selectedUsernames);
        },
      ),
    );

    if (result == null || result.isEmpty) return;

    // Konfirmasi perubahan
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Perubahan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Anggota baru yang akan diundang:'),
            const SizedBox(height: 12),
            ...result.map((username) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(username),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            const Text(
              'Anggota lama akan diganti dengan daftar ini. Lanjutkan?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Ya, Update'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Kirim request ke API
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) {
      _redirectToLogin();
      return;
    }

    try {
      setState(() => _isLoading = true);

      print('=== UPDATE GROUP MEMBERS ===');
      print('Group ID: ${_activeGroup!.id}');
      print('Invited members: $result');

      final response = await http
          .put(
            Uri.parse(
                '${dotenv.env['API_BASE_URL']}/api/pkl/group/${_activeGroup!.id}/members'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'invited_members': result,
            }),
          )
          .timeout(const Duration(seconds: 10));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        _clearCache();
        await _loadAllData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Anggota kelompok berhasil diubah'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        _handleErrorResponse(response);
      }
    } catch (e) {
      print('Error updating members: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Tambahkan method ini ke dalam class _SiswaDashboardState
  Future<void> _deleteGroup() async {
    if (_activeGroup == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada grup aktif'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (!await _isTokenValid()) {
      _redirectToLogin();
      return;
    }

    // Validasi hanya ketua kelompok yang bisa menghapus
    if (_currentUserId == null ||
        !_activeGroup!.isUserLeader(_currentUserId!)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hanya ketua kelompok yang bisa menghapus grup'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Validasi status harus DRAFT
    if (_activeGroup!.status.toLowerCase() != 'pending') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hanya grup dengan status DRAFT yang bisa dihapus'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Konfirmasi sebelum menghapus
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Grup PKL'),
        content: const Text(
            'Yakin ingin menghapus grup ini? Semua data grup akan hilang dan anggota akan dikeluarkan. Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) {
      _redirectToLogin();
      return;
    }

    try {
      setState(() => _isLoading = true);

      print('=== DELETE GROUP ===');
      print('Group ID: ${_activeGroup!.id}');
      print('Token: $token');

      final response = await http.delete(
        Uri.parse(
            '${dotenv.env['API_BASE_URL']}/api/pkl/group/${_activeGroup!.id}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': '*/*',
        },
      ).timeout(const Duration(seconds: 10));

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Handle berbagai status code
      if (response.statusCode == 204) {
        // Sukses - No Content
        print('✅ Group berhasil dihapus (204 No Content)');

        // Clear cache dan reload data
        _clearCache();
        await _loadAllData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Grup PKL berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (response.statusCode == 401) {
        print('❌ Unauthorized - Token invalid');
        _redirectToLogin();
      } else if (response.statusCode == 403) {
        print('❌ Forbidden - Bukan ketua kelompok');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Anda tidak memiliki izin untuk menghapus grup ini'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else if (response.statusCode == 404) {
        print('❌ Not Found - Group tidak ditemukan');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Grup tidak ditemukan'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        // Reload untuk refresh data
        _clearCache();
        await _loadAllData();
      } else if (response.statusCode == 409) {
        print('❌ Conflict - Group tidak dalam status DRAFT');

        // Parse error message
        String errorMessage = 'Grup tidak dalam status DRAFT';
        try {
          if (response.body.isNotEmpty) {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          }
        } catch (e) {}

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else if (response.statusCode >= 500) {
        print('❌ Server Error: ${response.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Terjadi kesalahan pada server. Silakan coba lagi.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Status code lainnya
        print('❌ Unexpected status code: ${response.statusCode}');
        _handleErrorResponse(response);
      }
    } catch (e) {
      print('❌ Exception saat menghapus grup: $e');
      print('Stack trace:');
      print(StackTrace.current);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print('=== SELESAI DELETE GROUP ===');
    }
  }

  Future<void> _removeMember(int siswaId, String namaSiswa) async {
    if (_activeGroup == null) return;
    if (!await _isTokenValid()) {
      _redirectToLogin();
      return;
    }

    if (_currentUserId == null ||
        !_activeGroup!.isUserLeader(_currentUserId!)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hanya ketua kelompok yang bisa hapus anggota'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (_activeGroup!.status.toLowerCase() != 'pending') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Hanya group dengan status DRAFT yang bisa menghapus anggota'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (siswaId == _currentUserId) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ketua tidak bisa menghapus diri sendiri'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Anggota'),
        content: Text('Yakin ingin menghapus $namaSiswa dari kelompok?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) {
      _redirectToLogin();
      return;
    }

    try {
      setState(() => _isLoading = true);

      final response = await http.delete(
        Uri.parse(
            '${dotenv.env['API_BASE_URL']}/api/pkl/group/${_activeGroup!.id}/members/$siswaId'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _clearCache();
        await _loadAllData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$namaSiswa berhasil dihapus dari kelompok'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        _handleErrorResponse(response);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  // Di dalam class _SiswaDashboardState, tambahkan method ini:

  Future<List<AvailableMember>> _getAvailableMembers(
      {String query = ''}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) return [];

      final url = query.isEmpty
          ? '${dotenv.env['API_BASE_URL']}/api/pkl/group/available-members'
          : '${dotenv.env['API_BASE_URL']}/api/pkl/group/available-members?q=$query';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => AvailableMember.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error getting available members: $e');
    }
    return [];
  }

  Future<void> _ajukanPKL() async {
    print('=== AJUKAN PKL DIPANGGIL ===');

    if (!await _isTokenValid()) {
      print('Token tidak valid, redirect ke login');
      _redirectToLogin();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) {
      print('Token null, redirect ke login');
      _redirectToLogin();
      return;
    }

    try {
      if (_kelasId == null) await _loadProfileData(token, prefs);

      print('Menampilkan dialog AjukanPKLDialog...');
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AjukanPKLDialog(
          token: token,
          kelasId: _kelasId,
          primaryColor: const Color(0xFF9f0712),
        ),
      );

      print('Result dari dialog: $result');

      if (result != null) {
        http.Response response;
        if (result['tipe'] == 'group') {
          print('Membuat group PKL...');
          print('Invited members: ${result['invited_members']}');

          response = await http
              .post(
                Uri.parse('${dotenv.env['API_BASE_URL']}/api/pkl/group'),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
                body: jsonEncode({
                  'invited_members': result['invited_members'] ?? [],
                }),
              )
              .timeout(const Duration(seconds: 10));

          print('Response status code (group): ${response.statusCode}');
          print('Response body (group): ${response.body}');
        } else {
          print('Membuat pengajuan individu PKL...');
          print('Industri ID: ${result['industri_id']}');

          response = await http
              .post(
                Uri.parse('${dotenv.env['API_BASE_URL']}/api/pkl/applications'),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
                body: jsonEncode({
                  'catatan': result['catatan'] ?? '',
                  'industri_id': result['industri_id'],
                }),
              )
              .timeout(const Duration(seconds: 10));

          print('Response status code (individu): ${response.statusCode}');
          print('Response body (individu): ${response.body}');
        }

        // Handle berbagai status code
        if (response.statusCode >= 200 && response.statusCode < 300) {
          // Sukses 2xx
          print(
              '✅ Request berhasil dengan status code: ${response.statusCode}');

          await _resetNotificationFlags();
          _clearCache();

          print('Memuat ulang semua data...');
          await _loadAllData();

          if (mounted) {
            final String successMessage = result['tipe'] == 'group'
                ? 'Group PKL berhasil dibuat'
                : 'Pengajuan PKL berhasil dikirim';

            print('Menampilkan snackbar sukses: $successMessage');

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(successMessage),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else if (response.statusCode == 409 && result['tipe'] == 'group') {
          // Conflict - group sudah ada
          print('⚠️ Group already exists (409 Conflict)');

          // Parse pesan error
          try {
            final errorData = jsonDecode(response.body);
            print('Error message: ${errorData['message']}');
          } catch (e) {}

          // Tetap reload data untuk mendapatkan group terbaru
          _clearCache();
          await _loadAllData();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Pengajuan group PKL sudah ada yang sedang diproses'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }
        } else {
          // Error lainnya
          print('❌ Request gagal dengan status code: ${response.statusCode}');
          _handleErrorResponse(response);
        }
      } else {
        print('Dialog dibatalkan (result null)');
      }
    } catch (e) {
      print('❌ Error di _ajukanPKL: $e');
      print('Stack trace:');
      print(StackTrace.current);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    print('=== SELESAI AJUKAN PKL ===');
  }

  void _handleErrorResponse(http.Response response) {
    print('=== HANDLE ERROR RESPONSE ===');
    print('Status code: ${response.statusCode}');
    print('Body: ${response.body}');

    try {
      final errorData = jsonDecode(response.body);
      final String errorCode = errorData['error'] ?? '';
      final String msg = errorData['message'] ?? 'Gagal';
      print('Error code: $errorCode');
      print('Error message: $msg');

      // Handle 409 Conflict khusus untuk group
      if (response.statusCode == 409) {
        if (errorCode == 'GROUP_ALREADY_PENDING') {
          print('⚠️ 409 Conflict: Group sudah ada dalam status pending');

          // Reload data untuk mendapatkan group terbaru
          _clearCache();
          _loadAllData();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Anda sudah memiliki group PKL yang sedang diproses'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        } else if (errorCode == 'ALREADY_IN_GROUP') {
          print('⚠️ 409 Conflict: User sudah dalam group');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Anda sudah tergabung dalam group PKL'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
      }

      // Handle 400 Bad Request
      if (response.statusCode == 400) {
        print('⚠️ 400 Bad Request: Validasi error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Handle 401 Unauthorized
      if (response.statusCode == 401) {
        print('⚠️ 401 Unauthorized: Token expired');
        _redirectToLogin();
        return;
      }

      // Handle 403 Forbidden
      if (response.statusCode == 403) {
        print('⚠️ 403 Forbidden: Tidak memiliki akses');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Anda tidak memiliki akses untuk melakukan ini'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Handle 404 Not Found
      if (response.statusCode == 404) {
        print('⚠️ 404 Not Found: Resource tidak ditemukan');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data tidak ditemukan'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Handle 500 Internal Server Error
      if (response.statusCode >= 500) {
        print('⚠️ ${response.statusCode} Server Error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Terjadi kesalahan pada server. Silakan coba lagi.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Default error handling untuk status code lainnya
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Error parsing response: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    print('=== END HANDLE ERROR ===');
  }

  Future<void> _resetNotificationFlags() async {
    final prefs = await SharedPreferences.getInstance();
    for (var key in prefs.getKeys()) {
      if (key.startsWith('pkl_notified_')) {
        await prefs.remove(key);
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
    _cachedGroups = null;
    _cachedInvitations = null; // NEW
    _cachedNamaSiswa = null;
    _cachedKelasSiswa = null;
    _cachedKelasId = null;
    _cachedUserId = null;
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('last_load_time');
    });
  }

  Future<void> _bukaIndustri() async {
    if (!await _isTokenValid()) {
      _redirectToLogin();
      return;
    }
    if (mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const IndustriListPage()),
      );
    }
  }

  Future<void> _bukaRiwayat() async {
    try {
      if (!await _isTokenValid()) {
        _redirectToLogin();
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) {
        _redirectToLogin();
        return;
      }

      if (_pklApplications.isEmpty) await _loadPklApplications(token);
      if (mounted) {
        await DetailPopup.showRiwayatPopup(
          context,
          _pklApplications,
          industriData: _industriData,
          formatTanggal: DateFormatter.format,
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

  bool _hasDisetujuiApplication() {
    if (_isInGroup) {
      return _activeGroup?.status.toLowerCase() == 'approved' ||
          _activeGroup?.status.toLowerCase() == 'disetujui';
    }
    if (_pklData == null) return false;
    final s = _pklData!['status'].toString().toLowerCase();
    return s == 'disetujui' || s == 'approved';
  }

  bool _hasDitolakApplication() {
    if (_isInGroup) {
      return _activeGroup?.status.toLowerCase() == 'rejected' ||
          _activeGroup?.status.toLowerCase() == 'ditolak';
    }
    if (_pklData == null) return false;
    final s = _pklData!['status'].toString().toLowerCase();
    return s == 'ditolak' || s == 'rejected';
  }

  // ========== BUILD INVITATIONS SECTION ==========
  Widget _buildInvitationsSection() {
    if (_invitations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.mail, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Undangan Group (${_invitations.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
        ..._invitations.map((invitation) => InvitationCard(
              invitation: invitation,
              isProcessing: _isProcessingInvitation,
              onAccept: () => _respondToInvitation(invitation.id, true),
              onReject: () => _respondToInvitation(invitation.id, false),
            )),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return ErrorScreen(
        errorMessage: _errorMessage,
        onRetry: _initializeApp,
        onLogout: _redirectToLogin,
      );
    }

    if (_initialLoading) return _buildSkeletonScreen();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 180, 16, 4),
      body: SafeArea(
        child: RefreshIndicator(
          // TAMBAHKAN INI
          onRefresh: _handleRefresh, // Method untuk refresh
          color: const Color.fromARGB(255, 180, 16, 4),
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(), // Penting agar bisa di-refresh meski konten sedikit
            child: Column(
              children: [
                DashboardHeader(
                  namaSiswa: _namaSiswa,
                  isLoading: _isLoading,
                  unreadCount: _unreadNotificationCount,
                  onNotificationTap: _showNotificationsPanel,
                ),
                Container(
                  margin: const EdgeInsets.only(top: 10, left: 20, right: 20),
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TimelineSection(
                    isLoading: _isLoading,
                    isInGroup: _isInGroup,
                    activeGroup: _activeGroup,
                    pklData: _pklData,
                    tanggalMulai: _isInGroup
                        ? _activeGroup?.tanggalMulai
                        : _pklData?['tanggal_mulai'],
                    tanggalSelesai: _isInGroup
                        ? _activeGroup?.tanggalSelesai
                        : _pklData?['tanggal_selesai'],
                    status:
                        _isInGroup ? _activeGroup?.status : _pklData?['status'],
                  ),
                ),
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
                        _isLoading
                            ? const SkeletonQuickActions()
                            : QuickActionsMenu(
                                onAjukanPKL: _ajukanPKL,
                                onBukaIndustri: _bukaIndustri,
                                onBukaRiwayat: _bukaRiwayat,
                              ),
                        const SizedBox(height: 30),

                        // Invitations section (shown if there are invitations)
                        if (!_isLoading && _hasInvitations)
                          _buildInvitationsSection(),

                        // Title section
                        _isLoading
                            ? const SkeletonTitle()
                            : Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _isInGroup
                                        ? 'Kelompok PKL Saya'
                                        : 'Pengajuan PKL Disetujui',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (!_hasInvitations)
                                    Text(
                                      _isInGroup
                                          ? '${_activeGroup?.memberCount ?? 0} Anggota'
                                          : (_hasDisetujuiApplication()
                                              ? '1 Disetujui'
                                              : (_hasDitolakApplication()
                                                  ? '1 Ditolak'
                                                  : _pklData != null
                                                      ? '1 Menunggu'
                                                      : '0 Pengajuan')),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                        const SizedBox(height: 16),

                        // Content section
                        if (_isLoading)
                          const SkeletonPKLCard()
                        else if (_hasInvitations)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.blue.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.info_outline,
                                    size: 32, color: Colors.blue[300]),
                                const SizedBox(height: 12),
                                const Text(
                                  'Anda memiliki undangan grup yang menunggu',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Terima undangan untuk bergabung dengan kelompok atau tolak untuk mengabaikan',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
// Di dalam method build(), cari bagian ini:
                        else if (_isInGroup && _activeGroup != null)
                          GroupCard(
                            group: _activeGroup!,
                            currentUserId: _currentUserId,
                            onEditMembers: _updateGroupMembers,
                            onSubmitGroup: _submitGroup,

                            onRemoveMember: _removeMember,
                            // TAMBAHKAN PARAMETER INI:
                            onDeleteGroup: _deleteGroup, // <-- Tambahkan ini
                          )
                        else if (_pklData != null)
                          PengajuanCard(
                            pengajuan: {
                              'status': _pklData!['status'],
                              'industri_nama':
                                  _industriData?['nama'] ?? 'Industri',
                              'tanggal_permohonan': DateFormatter.format(
                                  _pklData!['tanggal_permohonan']),
                              'tanggal_mulai': DateFormatter.format(
                                  _pklData!['tanggal_mulai']),
                              'tanggal_selesai': DateFormatter.format(
                                  _pklData!['tanggal_selesai']),
                              'catatan': _pklData!['catatan'] ?? '-',
                              'kaprog_note': _pklData!['kaprog_note'] ??
                                  'Tidak ada catatan',
                              'decided_at':
                                  DateFormatter.format(_pklData!['decided_at']),
                              'diproses_oleh': _processedByData?['nama'] ?? '-',
                              'pembimbing_pkl': _pembimbingData?['nama'] ?? '-',
                            },
                            industriData: _industriData,
                          )
                        else
                          EmptyPengajuanCard(onAjukan: _ajukanPKL),
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ), // TUTUP RefreshIndicator
      ),
    );
  }

  Widget _buildSkeletonScreen() {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 180, 16, 4),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              DashboardHeader(
                namaSiswa: '',
                isLoading: true,
                unreadCount: 0,
                onNotificationTap: () {},
              ),
              Container(
                margin: const EdgeInsets.only(top: 10, left: 20, right: 20),
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const SkeletonTimeSection(),
              ),
              Container(
                margin: const EdgeInsets.only(top: 30),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      SkeletonQuickActions(),
                      SizedBox(height: 30),
                      SkeletonTitle(),
                      SizedBox(height: 16),
                      SkeletonPKLCard(),
                      SizedBox(height: 60),
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
}
