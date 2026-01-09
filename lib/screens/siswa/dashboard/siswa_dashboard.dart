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
import 'websocket_manager.dart'; // Tambahkan ini
import 'notification_popup.dart'; // File baru untuk popup notifikasi

class SiswaDashboard extends StatefulWidget {
  const SiswaDashboard({super.key});

  @override
  State<SiswaDashboard> createState() => _SiswaDashboardState();
}

class _SiswaDashboardState extends State<SiswaDashboard> {
  String _namaSiswa = 'Loading...';
  String _kelasSiswa = 'Loading...';
  int? _kelasId;
  bool _isLoading = true;

  Map<String, dynamic>? _pklData;
  List<dynamic> _pklApplications = [];
  Map<String, dynamic>? _industriData;
  Map<String, dynamic>? _pembimbingData;
  Map<String, dynamic>? _processedByData;

  // Cache variables
  Map<String, dynamic>? _cachedPklData;
  List<dynamic>? _cachedPklApplications;
  Map<String, dynamic>? _cachedIndustriData;
  Map<String, dynamic>? _cachedPembimbingData;
  Map<String, dynamic>? _cachedProcessedByData;
  bool _isCached = false;
  String? _cachedNamaSiswa;
  String? _cachedKelasSiswa;
  int? _cachedKelasId;

  // User tracking
  String? _currentUsername;
  StreamSubscription? _prefsSubscription;

  // ========== WEBSOCKET MANAGER ==========
  late WebSocketManager _webSocketManager;
  final List<Map<String, dynamic>> _notifications = [];
  int _unreadNotificationCount = 0;
  final Color _notificationColor = const Color(0xFFE63946);
  // =======================================

  // Neo Brutalism Colors
  final Color _primaryColor = const Color(0xFFE71543);
  final Color _secondaryColor = const Color(0xFFE6E3E3);
  final Color _accentColor = const Color(0xFFA8DADC);
  final Color _darkColor = const Color(0xFF1D3557);
  final Color _yellowColor = const Color(0xFFFFB703);
  final Color _blackColor = Colors.black;

  // Neo Brutalism Shadows
  static const BoxShadow _heavyShadow = BoxShadow(
    color: Colors.black,
    offset: Offset(6, 6),
    blurRadius: 0,
  );

  final BoxShadow _lightShadow = BoxShadow(
    color: Colors.black.withValues(alpha:0.2),
    offset: const Offset(4, 4),
    blurRadius: 0,
  );
  @override
  void initState() {
    super.initState();

    print('🚀 SiswaDashboard State dibuat');

    _webSocketManager = WebSocketManager();
    _setupWebSocketListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // ========== PERBAIKAN: LOAD NOTIFIKASI SETELAH SEMUA DATA ==========
      // Tunggu dulu sampai auth check selesai
      await _checkAuthAndLoadData();

      // BARU load notifikasi
      await _loadNotificationsFromPrefs();
      print('📋 Loaded notifications AFTER auth check');
      // ==========================================

      // Connect WebSocket
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _webSocketManager.connect();
        }
      });
    });

    _startPrefsListener();
  }

  @override
  void dispose() {
    _webSocketManager.dispose();
    _prefsSubscription?.cancel();
    super.dispose();
  }
// ========== WEBSOCKET FUNCTIONS ==========
void _setupWebSocketListeners() {
  _webSocketManager.addListener((event) {
    if (event.type == WebSocketEventType.message) {
      _handleWebSocketMessage(event.data);
    }
    // Hapus bagian connected dan disconnected
    // else if (event.type == WebSocketEventType.connected) {
    //   _showConnectedSnackbar();
    // } else if (event.type == WebSocketEventType.disconnected) {
    //   _showDisconnectedSnackbar();
    // }
  });
}

  void _handleWebSocketMessage(dynamic message) {
    print('📨 WebSocket message received');

    try {
      final Map<String, dynamic> data;

      if (message is String) {
        data = jsonDecode(message);
      } else if (message is Map) {
        data = Map<String, dynamic>.from(message);
      } else {
        print('❌ Unknown message type');
        return;
      }

      final type = data['type']?.toString() ?? 'unknown';

      print('📊 Message type: $type');

      // Process notification
      _processNotification(data);
    } catch (e) {
      print('❌ Error processing WebSocket message: $e');
    }
  }

  Future<void> _processNotification(Map<String, dynamic> data) async {
    final notificationData = data['data'];
    if (notificationData == null) return;

    final siswaUsername = notificationData['siswa_username']?.toString();
    final siswaId = notificationData['siswa_id']?.toString();

    // Get current user info
    final prefs = await SharedPreferences.getInstance();
    final currentUsername = prefs.getString('user_name');
    final currentUserId = prefs.getString('user_id');

    print('👤 Notification check:');
    print('   - For siswa: $siswaUsername (ID: $siswaId)');
    print('   - Current user: $currentUsername (ID: $currentUserId)');

    // Check if notification is for current user
    bool isForCurrentUser = false;

    if (siswaUsername != null && currentUsername != null) {
      isForCurrentUser = siswaUsername == currentUsername;
    } else if (siswaId != null && currentUserId != null) {
      isForCurrentUser = siswaId == currentUserId;
    }

    if (!isForCurrentUser) {
      print('⚠️  Notification not for current user');
      return;
    }

    print('✅ Notification IS for current user!');

    // Process based on type
    final String type = data['type'] ?? 'unknown';

    switch (type) {
      case 'pkl_approved':
        await _handlePKLApproved(data);
        break;
      case 'pkl_rejected':
        await _handlePKLRejected(data);
        break;
      default:
        print('⚠️ Unknown message type: $type');
    }
  }

  Future<void> _saveNotificationsToPrefs() async {
    print('💾 Attempting to save notifications...');
    print('   - Current username: $_currentUsername');
    print('   - Notification count: ${_notifications.length}');

    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentUsername != null && mounted) {
        final notificationsJson = jsonEncode(_notifications);
        await prefs.setString(
            'notifications_$_currentUsername', notificationsJson);

        // Verify it was saved
        final saved = prefs.getString('notifications_$_currentUsername');
        print('✅ Notifications saved successfully!');
        print('   - Unread count: $_unreadNotificationCount');
        print('   - Saved JSON length: ${saved?.length ?? 0} characters');
      } else {
        print('❌ Cannot save: username is null or widget not mounted');
        print('   - _currentUsername: $_currentUsername');
        print('   - mounted: $mounted');
      }
    } catch (e) {
      print('❌ Error saving notifications: $e');
      print('   - Error type: ${e.runtimeType}');
    }
  }

  Future<void> _loadNotificationsOnLogin() async {
    print('🔔 Loading notifications on login...');

    // Tunggu sebentar untuk memastikan username tersedia
    await Future.delayed(const Duration(milliseconds: 500));

    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('user_name');

    if (userName != null && userName.isNotEmpty) {
      _currentUsername = userName;
      print('👤 Loading notifications for user: $userName');
      await _loadNotificationsFromPrefs();
    } else {
      print('⚠️  Username not available for loading notifications');
    }
  }

  Future<void> _loadNotificationsFromPrefs() async {
    print('📂 ========== LOADING NOTIFICATIONS ==========');
    print('   - Current username: $_currentUsername');
    print('   - Widget mounted: $mounted');

    // Jika username belum tersedia, coba ambil dari prefs
    if (_currentUsername == null) {
      final prefs = await SharedPreferences.getInstance();
      _currentUsername = prefs.getString('user_name');
      print('   - Got username from prefs: $_currentUsername');
    }

    if (_currentUsername == null) {
      print('❌ Cannot load: username is null');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'notifications_$_currentUsername';
      final notificationsJson = prefs.getString(key);

      print('   - Checking key: $key');
      print('   - Data exists: ${notificationsJson != null}');

      if (notificationsJson != null && notificationsJson.isNotEmpty) {
        print('   - JSON length: ${notificationsJson.length}');

        try {
          final List<dynamic> loadedNotifications =
              jsonDecode(notificationsJson);
          print(
              '   - Successfully parsed ${loadedNotifications.length} notifications');

          // ... rest of the loading code ...
        } catch (e) {
          print('❌ Parse error: $e');
        }
      } else {
        print('📭 No notifications found for user $_currentUsername');
      }
    } catch (e) {
      print('❌ Load error: $e');
    }

    print('📂 ========== END LOADING ==========');
  }

  Future<void> _handlePKLApproved(Map<String, dynamic> data) async {
    print('✅ PKL Approved received via WebSocket');

    final notificationData = data['data'];
    if (notificationData == null) return;

    final industriNama = notificationData['industri_nama'] ?? 'Perusahaan';
    final catatan = notificationData['catatan'];
    final applicationId = notificationData['application_id'];
    final notificationId = 'pkl_approved_$applicationId';

    // ========== CEK DI SHARED PREFERENCES ==========
    final prefs = await SharedPreferences.getInstance();
    final alreadyNotifiedKey = 'pkl_notified_$applicationId';
    final alreadyNotified = prefs.getBool(alreadyNotifiedKey) ?? false;
    // ================================================

    if (!alreadyNotified) {
      final notification = {
        'id': notificationId,
        'title': 'PKL DISETUJUI! 🎉',
        'message': 'Pengajuan PKL ke $industriNama telah disetujui',
        'catatan': catatan,
        'timestamp': DateTime.now().toIso8601String(),
        'read': false,
        'type': 'approved',
        'data': data,
      };

      setState(() {
        _notifications.insert(0, notification);
        _unreadNotificationCount++;
      });

      // ========== SIMPAN FLAG ==========
      await prefs.setBool(alreadyNotifiedKey, true);
      // ================================

      // Save to SharedPreferences
      await _saveNotificationsToPrefs();

      print('📝 Saved approval notification to SharedPreferences');
      print('   - Application ID: $applicationId');
      print('   - Unread count: $_unreadNotificationCount');

      // Show popup notification
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
    } else {
      print('📌 PKL $applicationId sudah pernah di-notifikasi (WebSocket)');
    }

    // Refresh data
    await Future.delayed(const Duration(seconds: 2));
    await _loadAllData();
  }

  Future<void> _handlePKLRejected(Map<String, dynamic> data) async {
    print('❌ PKL Rejected received via WebSocket');

    final notificationData = data['data'];
    if (notificationData == null) return;

    final industriNama = notificationData['industri_nama'] ?? 'Perusahaan';
    final catatan = notificationData['catatan'] ?? 'Tidak ada alasan diberikan';
    final applicationId = notificationData['application_id'];
    final notificationId = 'pkl_rejected_$applicationId';

    // ========== CEK DI SHARED PREFERENCES ==========
    final prefs = await SharedPreferences.getInstance();
    final alreadyNotifiedKey = 'pkl_notified_$applicationId';
    final alreadyNotified = prefs.getBool(alreadyNotifiedKey) ?? false;
    // ================================================

    if (!alreadyNotified) {
      final notification = {
        'id': notificationId,
        'title': 'PKL DITOLAK ❌',
        'message': 'Pengajuan PKL ke $industriNama ditolak',
        'catatan': catatan,
        'timestamp': DateTime.now().toIso8601String(),
        'read': false,
        'type': 'rejected',
        'data': data,
      };

      setState(() {
        _notifications.insert(0, notification);
        _unreadNotificationCount++;
      });

      // ========== SIMPAN FLAG ==========
      await prefs.setBool(alreadyNotifiedKey, true);
      // ================================

      // Save to SharedPreferences
      await _saveNotificationsToPrefs();

      print('📝 Saved rejection notification to SharedPreferences');
      print('   - Application ID: $applicationId');
      print('   - Unread count: $_unreadNotificationCount');

      // Show popup notification
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
    } else {
      print('📌 PKL $applicationId sudah pernah di-notifikasi (WebSocket)');
    }

    // Refresh data
    await Future.delayed(const Duration(seconds: 2));
    await _loadAllData();
  }

  // Panggil fungsi ini saat berhasil mengajukan PKL
  Future<void> _resetNotificationFlags() async {
    final prefs = await SharedPreferences.getInstance();

    // Hapus semua flag pkl_notified_*
    final keys = prefs.getKeys();
    for (var key in keys) {
      if (key.startsWith('pkl_notified_')) {
        await prefs.remove(key);
        print('🗑️  Removed notification flag: $key');
      }
    }
  }

// Update fungsi _ajukanPKL():
  Future<void> _ajukanPKL() async {
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
          // ========== RESET NOTIFICATION FLAGS ==========
          await _resetNotificationFlags();
          // =============================================

          _clearCache();
          await _loadAllData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pengajuan PKL berhasil dikirim')),
            );
          }
        } else if (response.statusCode == 401) {
          _redirectToLogin();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal mengajukan PKL: ${response.body}')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Terjadi kesalahan saat mengajukan PKL')),
        );
      }
    }
  }

void _showNotificationsPanel() {
  print('🔔 Opening notifications panel...');
  print('   - Current unread: $_unreadNotificationCount');

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
                color: _secondaryColor,
                border: Border.all(color: _blackColor, width: 4),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(6, 6),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // === HEADER - CLEAN & BOLD ===
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      border: Border(
                        bottom: BorderSide(color: _blackColor, width: 4),
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Clean icon
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: _blackColor, width: 3),
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black,
                                offset: Offset(3, 3),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.notifications,
                            color: _primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Title only
                        const Expanded(
                          child: Text(
                            'NOTIFIKASI PKL',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // === NOTIFICATIONS CONTENT ===
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
                              final isApproved =
                                  notification['type'] == 'approved';
                              final isRejected =
                                  notification['type'] == 'rejected';
                              
                              return _buildNotificationCard(
                                notification,
                                isRead,
                                isApproved,
                                isRejected,
                                index,
                                setState,
                              );
                            },
                          ),
                  ),
                  
                  // === ACTION BUTTONS - SIMPLE ===
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _secondaryColor,
                      border: Border(
                        top: BorderSide(color: _blackColor, width: 4),
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Close button
                        Expanded(
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: _yellowColor,
                              border: Border.all(color: _blackColor, width: 3),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black,
                                  offset: Offset(3, 3),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                foregroundColor: _blackColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                              ),
                              child: const Text(
                                'TUTUP',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        // Mark all button (only if has unread)
                        if (_unreadNotificationCount > 0)
                          Expanded(
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: _primaryColor,
                                border: Border.all(color: _blackColor, width: 3),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black,
                                    offset: Offset(3, 3),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              child: TextButton(
                                onPressed: () async {
                                  for (var notification in _notifications) {
                                    notification['read'] = true;
                                  }
                                  setState(() {
                                    _unreadNotificationCount = 0;
                                  });
                                  await _saveNotificationsToPrefs();
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                ),
                                child: const Text(
                                  'TANDAI SEMUA',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
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

// ========== NOTIFICATION CARD - ENHANCED CONTENT ==========

Widget _buildNotificationCard(
  Map<String, dynamic> notification,
  bool isRead,
  bool isApproved,
  bool isRejected,
  int index,
  StateSetter setState,
) {
  final timestamp = DateTime.parse(notification['timestamp']);
  final timeAgo = _formatTimeAgo(timestamp);
  final industriNama =
      notification['data']?['industri_nama'] ?? 'Perusahaan';
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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isRead ? _secondaryColor : Colors.white,
        border: Border.all(
          color: _blackColor,
          width: isRead ? 2 : 3,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:isRead ? 0.1 : 0.2),
            offset: const Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // === STATUS BANNER ===
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: isRejected
                  ? const Color(0xFFE63946)
                  : (isApproved
                      ? const Color(0xFF06D6A0)
                      : const Color(0xFFFFB703)),
              border: Border(
                bottom: BorderSide(color: _blackColor, width: 2),
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                // Status indicator
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _blackColor, width: 2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isRejected ? Icons.close : Icons.check,
                    size: 18,
                    color: isRejected
                        ? const Color(0xFFE63946)
                        : const Color(0xFF06D6A0),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Status text
                Expanded(
                  child: Text(
                    isRejected ? 'STATUS: DITOLAK' : 'STATUS: DISETUJUI',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                
                // Unread indicator
                if (!isRead)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
          
          // === CONTENT - ENHANCED ===
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === PERUSAHAAN INFO ===
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _accentColor,
                    border: Border.all(color: _blackColor, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _primaryColor,
                          border: Border.all(color: _blackColor, width: 2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.business,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LOKASI PKL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _darkColor,
                                letterSpacing: 1.0,
                              ),
                            ),
                            Text(
                              industriNama,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: _blackColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // === DETAIL STATUS ===
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isRejected
                        ? const Color(0xFFE63946).withValues(alpha:0.1)
                        : const Color(0xFF06D6A0).withValues(alpha:0.1),
                    border: Border.all(
                      color: isRejected
                          ? const Color(0xFFE63946)
                          : const Color(0xFF06D6A0),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isRejected ? Icons.warning : Icons.verified,
                            size: 16,
                            color: isRejected
                                ? const Color(0xFFE63946)
                                : const Color(0xFF06D6A0),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isRejected ? 'PENOLAKAN' : 'PERSETUJUAN',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: _blackColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      if (isRejected)
                        Text(
                          'Pengajuan PKL Anda ditolak. Perbaiki pengajuan berdasarkan catatan di bawah, lalu ajukan kembali.',
                          style: TextStyle(
                            fontSize: 13,
                            color: _darkColor,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else
                        Text(
                          'Pengajuan PKL Anda telah disetujui. Siapkan diri untuk memulai kegiatan praktik kerja lapangan.',
                          style: TextStyle(
                            fontSize: 13,
                            color: _darkColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // === CATATAN DETAIL ===
                if (catatan.isNotEmpty && catatan != 'Tidak ada alasan diberikan')
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: _blackColor, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: _primaryColor,
                                border: Border.all(color: _blackColor, width: 1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.description,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'CATATAN',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: _darkColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          catatan,
                          style: TextStyle(
                            fontSize: 13,
                            color: _darkColor,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // === ACTION BUTTON ===
                if (isRejected)
                  Container(
                    decoration: BoxDecoration(
                      color: _yellowColor,
                      border: Border.all(color: _blackColor, width: 3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextButton(
                      onPressed: _ajukanPKL,
                      style: TextButton.styleFrom(
                        foregroundColor: _blackColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'AJUKAN ULANG PKL',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (isApproved)
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF06D6A0),
                      border: Border.all(color: _blackColor, width: 3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close panel
                        _loadAllData(); // Refresh dashboard
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.visibility, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'LIHAT DETAIL PKL',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                const SizedBox(height: 12),
                
                // === FOOTER ===
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: _blackColor.withValues(alpha:0.3), width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _secondaryColor,
                          border: Border.all(color: _blackColor, width: 1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 10,
                              color: _darkColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              timeAgo.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _darkColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// ========== EMPTY STATE - CLEAN ==========

Widget _buildEmptyNotifications() {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _secondaryColor,
              border: Border.all(color: _blackColor, width: 4),
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(4, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Icon(
              Icons.inbox,
              size: 40,
              color: _darkColor,
            ),
          ),
          
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: _yellowColor,
              border: Border.all(color: _blackColor, width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'BELUM ADA NOTIFIKASI',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: _blackColor,
                letterSpacing: 1.0,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Semua update status pengajuan PKL akan muncul di sini',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _darkColor,
                fontWeight: FontWeight.w600,
              ),
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


  void _startPrefsListener() async {
    print('🔧 Starting prefs listener (read-only mode)');

    final prefs = await SharedPreferences.getInstance();

    _prefsSubscription = Stream.periodic(const Duration(seconds: 5))
        .asyncMap((_) async {
          return {
            'token': prefs.getString('access_token'),
            'shouldClear': prefs.getBool('should_clear_cache') ?? false,
          };
        })
        .distinct()
        .listen((Map<String, dynamic> data) {
          final token = data['token'] as String?;

          // HANYA handle jika token hilang (logout)
          if (token == null || token.isEmpty) {
            print('🔑 Token missing, redirecting to login');
            _redirectToLogin();
          }

          // JANGAN handle shouldClear atau username change
          // Biarkan dashboard tetap utuh
        });
  }

  Future<void> _checkAuthAndLoadData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.getString('access_token');
    final userName = prefs.getString('user_name');

    print('🔄 _checkAuthAndLoadData dipanggil');
    print('   - Username baru: $userName');
    print('   - Username sebelumnya: $_currentUsername');

    // ========== PERBAIKAN: SET USERNAME DULU ==========
    if (userName != null) {
      _currentUsername = userName;
      print('👤 Username set to: $_currentUsername');
    }
    // =================================================

    // Clear cache jika perlu
    final shouldClear = prefs.getBool('should_clear_cache') ?? false;
    if (shouldClear) {
      await prefs.remove('should_clear_cache');
      _clearCache();
      await _loadAllData();
      return;
    }

    // Jika ada cache, load dari cache
    if (_isCached &&
        _currentUsername != null &&
        userName != null &&
        _currentUsername == userName &&
        _cachedNamaSiswa != null &&
        _cachedNamaSiswa == userName) {
      _loadFromCache();
      setState(() {
        _isLoading = false;
      });
    } else {
      // Load semua data dari API
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
    if (_currentUsername == null) return;

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

  void _clearCache() {
    print('🧹 _clearCache() dipanggil - RESET TOTAL');

    // Reset semua cache variables TAPI JANGAN NOTIFIKASI
    _isCached = false;

    _cachedPklData = null;
    _cachedPklApplications = null;
    _cachedIndustriData = null;
    _cachedPembimbingData = null;
    _cachedProcessedByData = null;
    _cachedNamaSiswa = null;
    _cachedKelasSiswa = null;
    _cachedKelasId = null;

    // ========== JANGAN CLEAR NOTIFIKASI! ==========
    // Biarkan notifikasi tetap ada sebagai history
    // _notifications.clear(); // ← JANGAN PAKAI INI
    // _unreadNotificationCount = 0; // ← JANGAN PAKAI INI
    // ==============================================

    // Reset state data lainnya
    if (mounted) {
      setState(() {
        _pklData = null;
        _pklApplications = [];
        _industriData = null;
        _pembimbingData = null;
        _processedByData = null;
        _namaSiswa = 'Loading...';
        _kelasSiswa = 'Loading...';
        _kelasId = null;
        _isLoading = true;
      });
    }

    print('✅ Semua cache telah di-reset (notifikasi TETAP ADA)');
    print('   - Notifications count: ${_notifications.length}');
    print('   - Unread notifications: $_unreadNotificationCount');
  }

  Future<void> _checkLatestPKLStatus() async {
    print('🔍 Checking latest PKL status...');

    try {
      await _loadPklApplications();

      if (_pklApplications.isNotEmpty) {
        final latestPKL = _pklApplications.first;
        final status = latestPKL['status'].toString().toLowerCase();
        final applicationId = latestPKL['id'];

        // ========== CEK DI SHARED PREFERENCES ==========
        final prefs = await SharedPreferences.getInstance();
        final alreadyNotifiedKey = 'pkl_notified_$applicationId';
        final alreadyNotified = prefs.getBool(alreadyNotifiedKey) ?? false;
        // ================================================

        if (!alreadyNotified && (status == 'rejected' || status == 'ditolak')) {
          final industriId = latestPKL['industri_id'];
          String industriNama = 'Perusahaan';

          if (industriId != null) {
            await _loadIndustriData(industriId);
            industriNama = _industriData?['nama'] ?? 'Perusahaan';
          }

          final catatan =
              latestPKL['kaprog_note'] ?? 'Tidak ada alasan diberikan';
          final notificationId = 'pkl_rejected_$applicationId';

          // Cek apakah sudah ada notifikasi di list
          final hasNotificationInList =
              _notifications.any((n) => n['id'] == notificationId);

          if (!hasNotificationInList) {
            print('🎯 Found NEW rejected PKL - creating notification');

            final notification = {
              'id': notificationId,
              'title': 'PKL DITOLAK ❌',
              'message': 'Pengajuan PKL ke $industriNama ditolak',
              'catatan': catatan,
              'timestamp': DateTime.now().toIso8601String(),
              'read': false,
              'type': 'rejected',
              'data': {
                'type': 'pkl_rejected',
                'data': {
                  'application_id': applicationId,
                  'industri_nama': industriNama,
                  'catatan': catatan,
                }
              },
            };

            setState(() {
              _notifications.insert(0, notification);
              _unreadNotificationCount++;
            });

            // ========== SIMPAN FLAG ==========
            await prefs.setBool(alreadyNotifiedKey, true);
            // ================================

            // Save notifications
            await _saveNotificationsToPrefs();

            // Show popup hanya jika belum dibaca
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
        } else if (!alreadyNotified &&
            (status == 'approved' || status == 'disetujui')) {
          final industriId = latestPKL['industri_id'];
          String industriNama = 'Perusahaan';

          if (industriId != null) {
            await _loadIndustriData(industriId);
            industriNama = _industriData?['nama'] ?? 'Perusahaan';
          }

          final catatan = latestPKL['kaprog_note'];
          final notificationId = 'pkl_approved_$applicationId';

          final hasNotificationInList =
              _notifications.any((n) => n['id'] == notificationId);

          if (!hasNotificationInList) {
            print('🎯 Found NEW approved PKL - creating notification');

            final notification = {
              'id': notificationId,
              'title': 'PKL DISETUJUI! 🎉',
              'message': 'Pengajuan PKL ke $industriNama telah disetujui',
              'catatan': catatan,
              'timestamp': DateTime.now().toIso8601String(),
              'read': false,
              'type': 'approved',
              'data': {
                'type': 'pkl_approved',
                'data': {
                  'application_id': applicationId,
                  'industri_nama': industriNama,
                  'catatan': catatan,
                }
              },
            };

            setState(() {
              _notifications.insert(0, notification);
              _unreadNotificationCount++;
            });

            // ========== SIMPAN FLAG ==========
            await prefs.setBool(alreadyNotifiedKey, true);
            // ================================

            // Save notifications
            await _saveNotificationsToPrefs();

            // Show popup hanya jika belum dibaca
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
        } else if (alreadyNotified) {
          print('📌 PKL $applicationId sudah pernah di-notifikasi');
        }
      }
    } catch (e) {
      print('❌ Error checking PKL status: $e');
    }
  }

// Di _loadAllData():
  Future<void> _loadAllData() async {
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

      // ========== TAMBAHKAN INI ==========
      // Load notifications setelah semua data selesai
      await _loadNotificationsOnLogin();
      // ===================================

      _checkLatestPKLStatus();
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

  Future<void> _loadProfileData() async {
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
            } catch (e) {
              print('❌ Error mengambil data kelas: $e');
            }
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
    } catch (e) {
      print('❌ Error loading profile from API: $e');
    }

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
            return status == 'approved' || status == 'disetujui';
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

  Future<void> _bukaIndustri() async {
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
          const SnackBar(content: Text('Gagal memuat riwayat')),
        );
      }
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
      case 'pending':
      case 'menunggu':
        return 1;
      case 'approved':
      case 'disetujui':
        return 2;
      case 'completed':
      case 'selesai':
        return 3;
      default:
        return 0;
    }
  }

  String _getStatusText(String? status) {
    if (status == null) return 'Belum Mengajukan';

    switch (status.toLowerCase()) {
      case 'pending':
      case 'menunggu':
        return 'Menunggu';
      case 'approved':
      case 'disetujui':
        return 'Menjalankan PKL';
      case 'completed':
      case 'selesai':
        return 'Selesai PKL';
      case 'rejected':
      case 'ditolak':
        return 'Pengajuan Ditolak';
      default:
        return 'Mengajukan';
    }
  }

  bool _hasApprovedApplication() {
    if (_pklData == null) return false;
    final status = _pklData!['status'].toString().toLowerCase();
    return status == 'approved' || status == 'disetujui';
  }

  bool _hasRejectedApplication() {
    if (_pklData == null) return false;
    final status = _pklData!['status'].toString().toLowerCase();
    return status == 'rejected' || status == 'ditolak';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header dengan WebSocket status
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _primaryColor,
                  border: Border.all(color: _blackColor, width: 3),
                  boxShadow: const [_heavyShadow],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Halo, $_namaSiswa!',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Kelas $_kelasSiswa',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _secondaryColor,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _yellowColor,
                              border: Border.all(color: _blackColor, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Dashboard PKL',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: _blackColor,
                                  ),
                                ),
                                // WebSocket status indicator
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _webSocketManager.isConnected
                                        ? Colors.green
                                        : Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: _blackColor, width: 1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Notification icon with badge
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: _showNotificationsPanel,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: _yellowColor,
                              border: Border.all(color: _blackColor, width: 3),
                              boxShadow: [_lightShadow],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.notifications,
                              size: 28,
                              color: _blackColor,
                            ),
                          ),
                        ),
                        if (_unreadNotificationCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: _notificationColor,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: _blackColor, width: 2),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Text(
                                '${_unreadNotificationCount > 9 ? '9+' : _unreadNotificationCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Container waktu PKL
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _secondaryColor,
                  border: Border.all(color: _blackColor, width: 3),
                  boxShadow: const [_heavyShadow],
                  borderRadius: BorderRadius.circular(20),
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
                                width: 4,
                                height: 50,
                                color: _blackColor,
                              ),
                              _buildTimeItem(
                                  'Selesai',
                                  _pklData != null
                                      ? _formatTanggal(
                                          _pklData!['tanggal_selesai'])
                                      : '-'),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _secondaryColor,
                                  border:
                                      Border.all(color: _blackColor, width: 3),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Stack(
                                  children: [
                                    Container(
                                      width:
                                          (MediaQuery.of(context).size.width -
                                                  72) *
                                              ((_getCurrentProgressStatus(
                                                          _pklData?['status']) +
                                                      1.2) /
                                                  4),
                                      height: 34,
                                      margin: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: _primaryColor,
                                        borderRadius: BorderRadius.circular(17),
                                      ),
                                      child: Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12),
                                          child: Text(
                                            _getStatusText(_pklData?['status']),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.3,
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
                margin: const EdgeInsets.only(top: 24),
                decoration: BoxDecoration(
                  color: _secondaryColor,
                  border: Border.all(color: _blackColor, width: 4),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                  boxShadow: const [_heavyShadow],
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
                              height: 160,
                              decoration: BoxDecoration(
                                color: _primaryColor,
                                border:
                                    Border.all(color: _blackColor, width: 3),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: const [_heavyShadow],
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    left: 150,
                                    top: 20,
                                    bottom: 20,
                                    child: Container(
                                      width: 4,
                                      color: _blackColor,
                                    ),
                                  ),
                                  Positioned(
                                    left: 166,
                                    right: 20,
                                    top: 80,
                                    child: Container(
                                      height: 4,
                                      color: _blackColor,
                                    ),
                                  ),
                                  Positioned(
                                    left: 30,
                                    top: 25,
                                    child: _buildMenuOptionKiri('Pengajuan',
                                        Icons.assignment_add, _ajukanPKL),
                                  ),
                                  Positioned(
                                    right: 40,
                                    top: 20,
                                    child: _buildMenuOptionKanan('Industri',
                                        Icons.factory, _bukaIndustri),
                                  ),
                                  Positioned(
                                    right: 40,
                                    bottom: 15,
                                    child: _buildMenuOptionKanan(
                                        'Riwayat', Icons.history, _bukaRiwayat),
                                  ),
                                ],
                              ),
                            ),
                      const SizedBox(height: 32),
                      // Judul Daftar Pengajuan PKL
                      _isLoading
                          ? _buildTitleSkeleton()
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: _yellowColor,
                                border:
                                    Border.all(color: _blackColor, width: 3),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [_lightShadow],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'PENGAJUAN PKL',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: _blackColor,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _secondaryColor,
                                      border: Border.all(
                                          color: _blackColor, width: 2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _hasApprovedApplication()
                                          ? '1 DISETUJUI'
                                          : (_hasRejectedApplication()
                                              ? '1 DITOLAK'
                                              : '0 DISETUJUI'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: _blackColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      const SizedBox(height: 20),
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

  // ========== SKELETON LOADING WIDGETS (SAMA) ==========
  Widget _buildTimeSectionSkeleton() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTimeItemSkeleton(),
            Container(
              width: 4,
              height: 50,
              color: _blackColor,
            ),
            _buildTimeItemSkeleton(),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          height: 40,
          decoration: BoxDecoration(
            color: _secondaryColor,
            border: Border.all(color: _blackColor, width: 3),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeItemSkeleton() {
    return Column(
      children: [
        Container(
          width: 50,
          height: 12,
          color: _blackColor.withValues(alpha:0.3),
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: 24,
          decoration: BoxDecoration(
            color: _secondaryColor,
            border: Border.all(color: _blackColor, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSkeleton() {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: _primaryColor,
        border: Border.all(color: _blackColor, width: 3),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [_heavyShadow],
      ),
    );
  }

  Widget _buildTitleSkeleton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _yellowColor,
        border: Border.all(color: _blackColor, width: 3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
              width: 150, height: 20, color: _blackColor.withValues(alpha:0.3)),
          Container(width: 80, height: 20, color: _blackColor.withValues(alpha:0.3)),
        ],
      ),
    );
  }

  Widget _buildPKLCardSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _secondaryColor,
        border: Border.all(color: _blackColor, width: 3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 100,
            height: 30,
            decoration: BoxDecoration(
              color: _primaryColor,
              border: Border.all(color: _blackColor, width: 2),
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          const SizedBox(height: 16),
          Container(
              width: 200, height: 24, color: _blackColor.withValues(alpha:0.2)),
          const SizedBox(height: 12),
          Container(
              width: double.infinity,
              height: 16,
              color: _blackColor.withValues(alpha:0.2)),
          const SizedBox(height: 8),
          Container(
              width: 150, height: 16, color: _blackColor.withValues(alpha:0.2)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _accentColor,
              border: Border.all(color: _blackColor, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    width: 100,
                    height: 14,
                    color: _blackColor.withValues(alpha:0.2)),
                const SizedBox(height: 8),
                Container(
                    width: double.infinity,
                    height: 14,
                    color: _blackColor.withValues(alpha:0.2)),
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
        color: _secondaryColor,
        border: Border.all(color: _blackColor, width: 4),
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [_heavyShadow],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _primaryColor,
              border: Border.all(color: _blackColor, width: 3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assignment_outlined,
              size: 40,
              color: _secondaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'BELUM ADA PENGAJUAN DISETUJUI',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: _blackColor,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Ajukan PKL untuk memulai praktik kerja lapangan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _darkColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _ajukanPKL,
            style: ElevatedButton.styleFrom(
              backgroundColor: _yellowColor,
              foregroundColor: _blackColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: _blackColor, width: 3),
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
            ),
            child: const Text(
              'AJUKAN PKL SEKARANG',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== CARD BUILDERS ==========
  Widget _buildPengajuanCard(Map<String, dynamic> pengajuan) {
    final status = pengajuan['status'];
    final isApproved = status.toLowerCase() == 'approved' ||
        status.toLowerCase() == 'disetujui';
    final isRejected =
        status.toLowerCase() == 'rejected' || status.toLowerCase() == 'ditolak';

    final statusColor = isRejected
        ? const Color(0xFFE63946)
        : (isApproved ? const Color(0xFF06D6A0) : const Color(0xFFFFB703));

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: _secondaryColor,
        border: Border.all(
          color: _blackColor,
          width: 4,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [_heavyShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER STATUS
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border(
                bottom: BorderSide(color: _blackColor, width: 4),
              ),
            ),
            child: Row(
              children: [
                // Icon status
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _blackColor, width: 3),
                    shape: BoxShape.circle,
                    boxShadow: [_lightShadow],
                  ),
                  child: Icon(
                    isRejected
                        ? Icons.cancel
                        : (isApproved ? Icons.check_circle : Icons.access_time),
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Text status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRejected
                            ? 'DITOLAK'
                            : (isApproved ? 'DISETUJUI' : 'MENUNGGU'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        isRejected
                            ? 'Pengajuan PKL Anda ditolak'
                            : (isApproved
                                ? 'Pengajuan PKL Anda telah disetujui'
                                : 'Pengajuan PKL Anda sedang diproses'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha:0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // KONTEN UTAMA
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // INDUSTRI
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isRejected
                        ? const Color(0xFFE63946).withValues(alpha:0.1)
                        : _primaryColor.withValues(alpha:0.1),
                    border: Border.all(
                      color:
                          isRejected ? const Color(0xFFE63946) : _primaryColor,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isRejected
                              ? const Color(0xFFE63946)
                              : _primaryColor,
                          border: Border.all(color: _blackColor, width: 3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isRejected ? Icons.block : Icons.factory,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isRejected ? 'LOKASI YG DIAJUKAN' : 'LOKASI PKL',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: _darkColor,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pengajuan['industri_nama'],
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: _blackColor,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // CATATAN PENGAJUAN
                if (pengajuan['catatan'] != null &&
                    pengajuan['catatan'].isNotEmpty &&
                    pengajuan['catatan'] != '-')
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _secondaryColor,
                      border: Border.all(color: _blackColor, width: 3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: _primaryColor,
                                border:
                                    Border.all(color: _blackColor, width: 2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.note_add,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'CATATAN PENGAJUAN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: _blackColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: _blackColor, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            pengajuan['catatan'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // TAMPILAN KHUSUS UNTUK STATUS DITOLAK
                if (isRejected) ...[
                  // ALASAN PENOLAKAN
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE63946).withValues(alpha:0.15),
                      border: Border.all(
                        color: const Color(0xFFE63946),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE63946),
                                border:
                                    Border.all(color: _blackColor, width: 2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.warning_amber,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'ALASAN PENOLAKAN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: _blackColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: _blackColor, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            pengajuan['kaprog_note'] ??
                                'Tidak ada alasan yang diberikan',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // INFORMASI PENGAJUAN
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _accentColor,
                      border: Border.all(color: _blackColor, width: 3),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [_lightShadow],
                    ),
                    child: Column(
                      children: [
                        // DIAJUKAN PADA
                        _buildInfoRowCompact(
                          icon: Icons.calendar_today_outlined,
                          iconColor: const Color(0xFFFFB703),
                          title: 'DIAJUKAN PADA',
                          value: pengajuan['tanggal_permohonan'],
                        ),

                        const SizedBox(height: 16),

                        // DIPUTUSKAN PADA
                        _buildInfoRowCompact(
                          icon: Icons.gavel_outlined,
                          iconColor: const Color(0xFFE63946),
                          title: 'DIPUTUSKAN PADA',
                          value: pengajuan['decided_at'],
                        ),

                        const SizedBox(height: 16),

                        // DIPROSES OLEH (KAPROG)
                        _buildInfoRowCompact(
                          icon: Icons.person_outline,
                          iconColor: const Color(0xFFA8DADC),
                          title: 'DIPROSES OLEH',
                          value: pengajuan['diproses_oleh'],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // TOMBOL AJUKAN ULANG
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _secondaryColor,
                      border: Border.all(color: _blackColor, width: 3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BUTUH REVISI?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: _blackColor,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Perbaiki pengajuan Anda berdasarkan alasan penolakan di atas, lalu ajukan kembali.',
                          style: TextStyle(
                            fontSize: 14,
                            color: _darkColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _ajukanPKL,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _yellowColor,
                                  foregroundColor: _blackColor,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 24),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                        color: _blackColor, width: 3),
                                  ),
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.refresh, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'AJUKAN ULANG',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else if (isApproved) ...[
                  // TAMPILAN UNTUK DISETUJUI
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _accentColor,
                      border: Border.all(color: _blackColor, width: 3),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [_lightShadow],
                    ),
                    child: Column(
                      children: [
                        _buildInfoRowCompact(
                          icon: Icons.person_outline,
                          iconColor: const Color(0xFFE63946),
                          title: 'DIPROSES OLEH',
                          value: pengajuan['diproses_oleh'],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRowCompact(
                          icon: Icons.school_outlined,
                          iconColor: const Color(0xFF06D6A0),
                          title: 'PEMBIMBING',
                          value: pengajuan['pembimbing_pkl'],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRowCompact(
                          icon: Icons.calendar_today_outlined,
                          iconColor: const Color(0xFFFFB703),
                          title: 'DIAJUKAN',
                          value: pengajuan['tanggal_permohonan'],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRowCompact(
                          icon: Icons.gavel_outlined,
                          iconColor: const Color(0xFFA8DADC),
                          title: 'DIPUTUSKAN',
                          value: pengajuan['decided_at'],
                        ),
                      ],
                    ),
                  ),

                  // CATATAN APPROVAL JIKA ADA
                  if (pengajuan['kaprog_note'] != null &&
                      pengajuan['kaprog_note'].isNotEmpty &&
                      pengajuan['kaprog_note'] != 'Tidak ada catatan')
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06D6A0).withValues(alpha:0.1),
                        border: Border.all(
                            color: const Color(0xFF06D6A0), width: 3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF06D6A0),
                                  border:
                                      Border.all(color: _blackColor, width: 2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'CATATAN APPROVAL',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: _blackColor,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: _blackColor, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              pengajuan['kaprog_note'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ] else ...[
                  // TAMPILAN UNTUK MENUNGGU
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _accentColor,
                      border: Border.all(color: _blackColor, width: 3),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [_lightShadow],
                    ),
                    child: Column(
                      children: [
                        _buildInfoRowCompact(
                          icon: Icons.person_outline,
                          iconColor: const Color(0xFFE63946),
                          title: 'DIAJUKAN PADA',
                          value: pengajuan['tanggal_permohonan'],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRowCompact(
                          icon: Icons.access_time,
                          iconColor: const Color(0xFFFFB703),
                          title: 'STATUS',
                          value: 'Menunggu Persetujuan',
                        ),
                        const SizedBox(height: 16),
                        if (pengajuan['diproses_oleh'] != null &&
                            pengajuan['diproses_oleh'] != '-')
                          _buildInfoRowCompact(
                            icon: Icons.person_outline,
                            iconColor: const Color(0xFFA8DADC),
                            title: 'SEDANG DIPROSES',
                            value: pengajuan['diproses_oleh'],
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowCompact({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _blackColor, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor,
              border: Border.all(color: _blackColor, width: 2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: Colors.white,
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
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _darkColor,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _blackColor,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOptionKiri(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _secondaryColor,
              border: Border.all(color: _blackColor, width: 3),
              shape: BoxShape.circle,
              boxShadow: [_lightShadow],
            ),
            child: Icon(
              icon,
              color: _primaryColor,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _yellowColor,
              border: Border.all(color: _blackColor, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              title,
              style: TextStyle(
                color: _blackColor,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _secondaryColor,
              border: Border.all(color: _blackColor, width: 3),
              shape: BoxShape.circle,
              boxShadow: [_lightShadow],
            ),
            child: Icon(
              icon,
              color: _primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _yellowColor,
              border: Border.all(color: _blackColor, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              title,
              style: TextStyle(
                color: _blackColor,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeItem(String label, String date) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: _blackColor,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _yellowColor,
            border: Border.all(color: _blackColor, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            date,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: _blackColor,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }
}
