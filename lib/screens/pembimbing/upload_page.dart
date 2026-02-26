import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:photo_view/photo_view.dart';
import 'package:intl/intl.dart';

class UploadPage extends StatefulWidget {
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color darkColor;
  final Color yellowColor;
  final Color blackColor;
  final BoxShadow heavyShadow;
  final BoxShadow lightShadow;
  final ScrollController scrollController;

  const UploadPage({
    super.key,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.darkColor,
    required this.yellowColor,
    required this.blackColor,
    required this.heavyShadow,
    required this.lightShadow,
    required this.scrollController,
  });

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // Data dari API
  List<dynamic> _industriList = [];
  List<dynamic> _riwayatRealisasi = [];
  final Map<DateTime, List<dynamic>> _events = {};

  // ========== DATA JADWAL ==========
  List<KegiatanPkl> _allKegiatan = [];
  List<KegiatanPkl> _activeKegiatan = [];
  final Map<DateTime, List<KegiatanPkl>> _jadwalEvents = {};
  // =================================

  // State management
  bool _isLoading = true;
  bool _isLoadingRiwayat = false;
  String _errorMessage = '';
  String? _accessToken;

  // Upload state - SIMPLE VERSION
  final Map<String, bool> _isUploading = {};
  final Map<String, List<String>> _uploadedFiles = {};
  
  // Untuk modal upload sementara
  List<XFile> _selectedImages = [];
  final TextEditingController _catatanController = TextEditingController();

  // Kalender
  DateTime _currentDate = DateTime.now();
  DateTime? _selectedDate;
  late List<List<DateTime?>> _calendarDays;
  late String _currentMonth;

  // Fungsi untuk mengubah nama hari ke Bahasa Indonesia
  String _getIndonesianDayName(String englishDay) {
    switch (englishDay.toLowerCase()) {
      case 'monday': return 'Senin';
      case 'tuesday': return 'Selasa';
      case 'wednesday': return 'Rabu';
      case 'thursday': return 'Kamis';
      case 'friday': return 'Jumat';
      case 'saturday': return 'Sabtu';
      case 'sunday': return 'Minggu';
      default: return englishDay;
    }
  }

  // Fungsi untuk mengubah nama bulan ke Bahasa Indonesia
  String _getIndonesianMonthName(String englishMonth) {
    switch (englishMonth.toLowerCase()) {
      case 'january': return 'Januari';
      case 'february': return 'Februari';
      case 'march': return 'Maret';
      case 'april': return 'April';
      case 'may': return 'Mei';
      case 'june': return 'Juni';
      case 'july': return 'Juli';
      case 'august': return 'Agustus';
      case 'september': return 'September';
      case 'october': return 'Oktober';
      case 'november': return 'November';
      case 'december': return 'Desember';
      default: return englishMonth;
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _generateCalendar();
    _loadTokenAndData();
    _fetchKegiatanPkl();
  }

  // ========== GENERATE KALENDER ==========
  void _generateCalendar() {
    final englishMonth = DateFormat('MMMM').format(_currentDate);
    _currentMonth = '${_getIndonesianMonthName(englishMonth)} ${_currentDate.year}';
    _calendarDays = [];

    final firstDayOfMonth = DateTime(_currentDate.year, _currentDate.month, 1);
    final lastDayOfMonth = DateTime(_currentDate.year, _currentDate.month + 1, 0);
    final int startingWeekday = firstDayOfMonth.weekday % 7;

    final List<DateTime?> currentWeek = [];

    if (startingWeekday > 0) {
      final previousMonthLastDay = DateTime(_currentDate.year, _currentDate.month, 0);
      for (int i = startingWeekday - 1; i >= 0; i--) {
        final previousDate = DateTime(
          previousMonthLastDay.year,
          previousMonthLastDay.month,
          previousMonthLastDay.day - i,
        );
        currentWeek.add(previousDate);
      }
    }

    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(_currentDate.year, _currentDate.month, day);
      currentWeek.add(date);

      if (currentWeek.length == 7) {
        _calendarDays.add(List.from(currentWeek));
        currentWeek.clear();
      }
    }

    if (currentWeek.isNotEmpty) {
      int nextMonthDay = 1;
      while (currentWeek.length < 7) {
        final nextDate = DateTime(_currentDate.year, _currentDate.month + 1, nextMonthDay);
        currentWeek.add(nextDate);
        nextMonthDay++;
      }
      _calendarDays.add(currentWeek);
    }
  }

  void _goToPreviousMonth() {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month - 1, 1);
      _generateCalendar();
    });
  }

  void _goToNextMonth() {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month + 1, 1);
      _generateCalendar();
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _currentDate = now;
      _selectedDate = now;
      _generateCalendar();
    });
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadTokenAndData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('access_token');

      if (_accessToken == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Token tidak ditemukan. Silakan login kembali.';
        });
        return;
      }

      await _loadData();
    } catch (e) {
      print('Error loading token: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Terjadi kesalahan: $e';
      });
    }
  }

  Future<void> _loadData() async {
    try {
      if (_accessToken == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Token tidak ditemukan. Silakan login kembali.';
        });
        return;
      }

      await Future.wait([
        _loadIndustriData(),
        _loadRiwayatRealisasi(),
      ]);

      _generateCalendarEvents();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Terjadi kesalahan: $e';
      });
    }
  }

  Future<void> _fetchKegiatanPkl() async {
    setState(() {
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        return;
      }

      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/kegiatan-pkl/active'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        final List<KegiatanPkl> kegiatanList =
            responseData.map((item) => KegiatanPkl.fromJson(item)).toList();

        setState(() {
          _allKegiatan = kegiatanList;
          _activeKegiatan = kegiatanList.where((k) => k.status == 'active').toList();
          _initializeJadwalEvents();
        });
      } else {
        throw Exception('Failed to load kegiatan PKL: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
      });
    }
  }

  void _initializeJadwalEvents() {
    _jadwalEvents.clear();

    for (var kegiatan in _allKegiatan) {
      final dateKey = DateTime(
        kegiatan.tanggalMulai.year,
        kegiatan.tanggalMulai.month,
        kegiatan.tanggalMulai.day,
      );

      if (_jadwalEvents.containsKey(dateKey)) {
        _jadwalEvents[dateKey]!.add(kegiatan);
      } else {
        _jadwalEvents[dateKey] = [kegiatan];
      }
    }
  }

  Future<void> _loadIndustriData() async {
    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/pkl/guru/tasks'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['data'] != null) {
          setState(() {
            _industriList = data['data'] ?? [];
          });
        } else {
          setState(() {
            _industriList = [];
          });
        }
      } else if (response.statusCode == 404) {
        await _loadIndustriDataAlternative();
      } else {
        print('Error load industri: ${response.statusCode}');
        setState(() {
          _industriList = [];
        });
      }
    } catch (e) {
      print('Error load industri: $e');
      setState(() {
        _industriList = [];
      });
    }
  }

  Future<void> _loadIndustriDataAlternative() async {
    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/pkl/guru/industri'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
          setState(() {
            _industriList = responseData['data'] ?? [];
          });
        }
      } else {
        setState(() {
          _industriList = [];
        });
      }
    } catch (e) {
      print('Error load industri alternative: $e');
      setState(() {
        _industriList = [];
      });
    }
  }

  Future<void> _loadRiwayatRealisasi() async {
    setState(() {
      _isLoadingRiwayat = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/realisasi-kegiatan/me'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          setState(() {
            _riwayatRealisasi = data;
          });
        } else if (data is Map<String, dynamic> && data.containsKey('data')) {
          setState(() {
            _riwayatRealisasi = List<dynamic>.from(data['data']);
          });
        } else {
          setState(() {
            _riwayatRealisasi = [];
          });
        }
      } else {
        setState(() {
          _riwayatRealisasi = [];
        });
      }
    } catch (e) {
      print('Error load riwayat: $e');
      setState(() {
        _riwayatRealisasi = [];
      });
    } finally {
      setState(() {
        _isLoadingRiwayat = false;
      });
    }
  }

  void _generateCalendarEvents() {
    _events.clear();
    for (var riwayat in _riwayatRealisasi) {
      try {
        final date = DateTime.parse(riwayat['tanggal_realisasi']);
        final day = DateTime(date.year, date.month, date.day);

        if (_events[day] == null) {
          _events[day] = [];
        }
        _events[day]!.add(riwayat);
      } catch (e) {
        print('Error parsing date: $e');
      }
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final List<dynamic> events = [];
    
    final jadwalDateKey = DateTime(day.year, day.month, day.day);
    if (_jadwalEvents.containsKey(jadwalDateKey)) {
      events.addAll(_jadwalEvents[jadwalDateKey]!.map((kegiatan) => {
        'type': 'jadwal',
        'data': kegiatan,
      }));
    }
    
    if (_events.containsKey(jadwalDateKey)) {
      events.addAll(_events[jadwalDateKey]!.map((riwayat) => {
        'type': 'riwayat',
        'data': riwayat,
      }));
    }
    
    return events;
  }

  bool _hasEvent(DateTime date) {
    final hasJadwal = _jadwalEvents.containsKey(DateTime(date.year, date.month, date.day));
    final hasRiwayat = _events.containsKey(DateTime(date.year, date.month, date.day));
    return hasJadwal || hasRiwayat;
  }

  Future<void> _startUploadProcess({
    required int industriId,
    required int kegiatanId,
    required dynamic kegiatan,
  }) async {
    
    if (_isTaskAlreadyUploaded(industriId, kegiatanId)) {
      _showSnackBar('⚠️ Task ini sudah pernah diupload!', isError: true);
      
      await _showAlreadyUploadedDialog(industriId, kegiatanId);
      return;
    }
    
    _selectedImages.clear();
    _catatanController.clear();
    
    await _showImageSourceDialog(industriId, kegiatanId, kegiatan);
  }

  bool _isTaskAlreadyUploaded(int industriId, int kegiatanId) {
    final taskKey = '${industriId}_$kegiatanId';
    
    if (_uploadedFiles.containsKey(taskKey) && _uploadedFiles[taskKey]!.isNotEmpty) {
      return true;
    }
    
    return _riwayatRealisasi.any((riwayat) {
      return riwayat['industri_id'] == industriId && 
             riwayat['kegiatan_id'] == kegiatanId;
    });
  }

  Future<void> _showAlreadyUploadedDialog(int industriId, int kegiatanId) async {
    final taskKey = '${industriId}_$kegiatanId';
    final imageUrls = _uploadedFiles[taskKey] ?? [];
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Sudah Diupload', style: TextStyle(color: widget.primaryColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Task ini sudah pernah diupload sebelumnya.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (imageUrls.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Bukti foto yang sudah diupload:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: imageUrls.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _showImagePreview(imageUrls[index]),
                        child: Container(
                          width: 80,
                          height: 80,
                          margin: EdgeInsets.only(
                            right: index < imageUrls.length - 1 ? 8 : 0,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[100],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrls[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(Icons.broken_image, color: Colors.grey),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ]
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showImageSourceDialog(
    int industriId, 
    int kegiatanId, 
    dynamic kegiatan
  ) async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Pilih Sumber Gambar', style: TextStyle(color: widget.primaryColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: widget.primaryColor),
                title: const Text('Dari Galeri'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: widget.primaryColor),
                title: const Text('Ambil Foto'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );

    if (source != null) {
      try {
        final pickedFile = await _picker.pickImage(
          source: source,
          imageQuality: 85,
          maxWidth: 1920,
        );

        if (pickedFile != null) {
          _selectedImages = [pickedFile];
          await _showPreviewAndCatatanDialog(industriId, kegiatanId, kegiatan);
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Gagal memilih gambar: ${e.toString()}', isError: true);
        }
      }
    }
  }

  Future<void> _showPreviewAndCatatanDialog(
    int industriId, 
    int kegiatanId, 
    dynamic kegiatan
  ) async {
    final taskKey = '${industriId}_$kegiatanId';
    bool isUploading = false;
    String status = '';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Unggah Bukti ${kegiatan['jenis']}',
                style: TextStyle(color: widget.primaryColor),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedImages.isNotEmpty)
                      Container(
                        width: 200,
                        height: 200,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[100],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_selectedImages.first.path),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
                              );
                            },
                          ),
                        ),
                      ),
                    
                    TextField(
                      controller: _catatanController,
                      decoration: const InputDecoration(
                        hintText: 'Tambahkan catatan (opsional)...',
                        border: OutlineInputBorder(),
                        labelText: 'Catatan',
                      ),
                      maxLines: 3,
                    ),
                    
                    if (status.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: status.contains('✅') ? Colors.green[50] : 
                                 status.contains('❌') ? Colors.red[50] : Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            if (isUploading)
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(widget.primaryColor),
                                ),
                              )
                            else if (status.contains('✅'))
                              const Icon(Icons.check_circle, color: Colors.green, size: 20)
                            else if (status.contains('❌'))
                              const Icon(Icons.error, color: Colors.red, size: 20)
                            else
                              const Icon(Icons.info, color: Colors.blue, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: status.contains('✅') ? Colors.green : 
                                         status.contains('❌') ? Colors.red : Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                if (!isUploading)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                ElevatedButton(
                  onPressed: isUploading ? null : () async {
                    setDialogState(() {
                      isUploading = true;
                      status = 'Mengunggah gambar...';
                    });

                    try {
                      final url = await _uploadSingleImage(_selectedImages.first);
                      
                      if (url != null && url.isNotEmpty) {
                        setDialogState(() {
                          status = 'Menyimpan data realisasi...';
                        });

                        final success = await _submitRealisasiData(
                          industriId: industriId,
                          kegiatanId: kegiatanId,
                          tanggalRealisasi: _formatDate(DateTime.now()),
                          imageUrls: [url],
                          catatan: _catatanController.text,
                        );

                        if (success) {
                          setDialogState(() {
                            status = '✅ Mengunggah berhasil!';
                          });

                          if (mounted) {
                            setState(() {
                              if (_uploadedFiles[taskKey] == null) {
                                _uploadedFiles[taskKey] = [];
                              }
                              _uploadedFiles[taskKey]!.add(url);
                              _isUploading[taskKey] = false;
                            });
                          }

                          await Future.delayed(const Duration(seconds: 2));
                          
                          if (mounted) {
                            Navigator.pop(context);
                            _showSnackBar('✅ Bukti berhasil diunggah!');
                            await _loadRiwayatRealisasi();
                            _generateCalendarEvents();
                            setState(() {});
                          }
                        } else {
                          setDialogState(() {
                            status = '❌ Gagal menyimpan data';
                            isUploading = false;
                          });
                          
                          if (mounted) {
                            _showSnackBar('❌ Gagal menyimpan data', isError: true);
                          }
                        }
                      } else {
                        setDialogState(() {
                          status = '❌ Gagal unggah gambar';
                          isUploading = false;
                        });
                        
                        if (mounted) {
                          _showSnackBar('❌ Gagal unggah gambar', isError: true);
                        }
                      }
                    } catch (e) {
                      setDialogState(() {
                        status = '❌ Error: ${e.toString()}';
                        isUploading = false;
                      });
                      
                      if (mounted) {
                        _showSnackBar('Error: ${e.toString()}', isError: true);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryColor,
                  ),
                  child: isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Unggah'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String?> _uploadSingleImage(XFile imageFile) async {
    try {
      if (_accessToken == null) {
        print('❌ Token tidak ditemukan');
        return null;
      }

      final baseUrl = dotenv.env['API_BASE_URL'];
      if (baseUrl == null) {
        print('❌ Konfigurasi server tidak ditemukan');
        return null;
      }

      final bytes = await imageFile.readAsBytes();
      
      print('🟡 Uploading file: ${imageFile.name}');
      print('🟡 File size: ${bytes.length} bytes');
      
      if (bytes.length > 5 * 1024 * 1024) {
        print('❌ File terlalu besar (${bytes.length} bytes > 5MB)');
        if (mounted) {
          _showSnackBar('File terlalu besar (max 5MB)', isError: true);
        }
        return null;
      }

      String mimeType = 'image/jpeg';
      if (imageFile.name.toLowerCase().endsWith('.png')) {
        mimeType = 'image/png';
      } else if (imageFile.name.toLowerCase().endsWith('.gif')) {
        mimeType = 'image/gif';
      }

      final uploadUrl = Uri.parse('$baseUrl/api/upload/image');
      
      final response = await http.post(
        uploadUrl,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': mimeType,
          'Accept': 'application/json',
        },
        body: bytes,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = jsonDecode(response.body);
          
          if (data is Map<String, dynamic>) {
            if (data.containsKey('url') && data['url'] is String) {
              return data['url'] as String;
            } else if (data.containsKey('data') && data['data'] is String) {
              return data['data'] as String;
            } else if (data.containsKey('path') && data['path'] is String) {
              final path = data['path'] as String;
              if (!path.startsWith('http')) {
                final String cleanBaseUrl = baseUrl.endsWith('/') 
                    ? baseUrl.substring(0, baseUrl.length - 1) 
                    : baseUrl;
                final String cleanPath = path.startsWith('/') ? path.substring(1) : path;
                return '$cleanBaseUrl/$cleanPath';
              }
              return path;
            } else if (data.containsKey('image_url') && data['image_url'] is String) {
              return data['image_url'] as String;
            }
            
            for (var key in data.keys) {
              if (key.toString().toLowerCase().contains('url') &&
                  data[key] is String &&
                  (data[key] as String).isNotEmpty) {
                return data[key] as String;
              }
            }
          }
          
          if (response.body.startsWith('http://') || response.body.startsWith('https://')) {
            return response.body;
          }
          
          print('⚠️ Tidak dapat menemukan URL dalam response');
          return null;
          
        } catch (e) {
          print('❌ Error parsing upload response: $e');
          return null;
        }
      } else {
        print('❌ Upload failed: ${response.statusCode} - ${response.body}');
        if (mounted) {
          try {
            final errorData = jsonDecode(response.body);
            final errorMsg = errorData['message'] ?? errorData['error'] ?? 'Upload gagal: ${response.statusCode}';
            _showSnackBar(errorMsg, isError: true);
          } catch (e) {
            _showSnackBar('Upload gagal: ${response.statusCode}', isError: true);
          }
        }
        return null;
      }
      
    } catch (e) {
      print('❌ Upload error: $e');
      if (mounted) {
        _showSnackBar('Upload error: ${e.toString()}', isError: true);
      }
      return null;
    }
  }

  Future<bool> _submitRealisasiData({
    required int industriId,
    required int kegiatanId,
    required String tanggalRealisasi,
    required List<String> imageUrls,
    required String catatan,
  }) async {
    try {
      if (_accessToken == null) {
        print('❌ Token tidak ditemukan');
        return false;
      }

      final baseUrl = dotenv.env['API_BASE_URL'];
      if (baseUrl == null) {
        print('❌ Konfigurasi server tidak ditemukan');
        return false;
      }

      final submitUrl = Uri.parse('$baseUrl/api/realisasi-kegiatan/submit');

      final body = {
        'bukti_foto_urls': imageUrls,
        'catatan': catatan,
        'industri_id': industriId,
        'kegiatan_id': kegiatanId,
        'tanggal_realisasi': tanggalRealisasi,
      };

      final response = await http.post(
        submitUrl,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Submit berhasil!');
        return true;
      } else {
        print('❌ Submit failed: ${response.statusCode}');
        if (mounted) {
          try {
            final errorData = jsonDecode(response.body);
            final errorMsg = errorData['message'] ?? errorData['error'] ?? 'Submit gagal: ${response.statusCode}';
            _showSnackBar(errorMsg, isError: true);
          } catch (e) {
            _showSnackBar('Submit gagal: ${response.statusCode}', isError: true);
          }
        }
        return false;
      }
    } catch (e) {
      print('❌ Submit error: $e');
      if (mounted) {
        _showSnackBar('Submit error: ${e.toString()}', isError: true);
      }
      return false;
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showImagePreview(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.8,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: PhotoView(
                  imageProvider: NetworkImage(imageUrl),
                  backgroundDecoration: const BoxDecoration(color: Colors.black),
                  minScale: PhotoViewComputedScale.contained * 0.8,
                  maxScale: PhotoViewComputedScale.covered * 2,
                  loadingBuilder: (context, event) {
                    if (event == null || event.expectedTotalBytes == null) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(widget.primaryColor),
                        ),
                      );
                    }
                    return Center(
                      child: CircularProgressIndicator(
                        value: event.cumulativeBytesLoaded / event.expectedTotalBytes!,
                        valueColor: AlwaysStoppedAnimation<Color>(widget.primaryColor),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage.isNotEmpty
              ? _buildErrorState()
              : _buildContentState(),
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.primaryColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircularProgressIndicator(
            color: widget.primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTokenAndData,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryColor,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentState() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _loadTokenAndData(),
            _fetchKegiatanPkl(),
          ]);
        },
        backgroundColor: Colors.white,
        color: widget.primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: widget.scrollController,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kalender Kegiatan',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF641E20),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Unggah Bukti Monitoring',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _goToToday,
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: widget.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: widget.primaryColor.withValues(alpha: 0.3)),
                                ),
                                child: Icon(Icons.today,
                                    color: widget.primaryColor, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: widget.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: widget.primaryColor.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            '${_activeKegiatan.length} Jadwal Aktif',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: widget.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.green.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            '${_industriList.length} Industri',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.blue.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            '${_allKegiatan.length} Total',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildNavButton(
                      icon: Icons.chevron_left,
                      onPressed: _goToPreviousMonth,
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              widget.primaryColor.withValues(alpha: 0.05),
                              widget.primaryColor.withValues(alpha: 0.05)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: widget.primaryColor.withValues(alpha: 0.2)),
                        ),
                        child: Center(
                          child: Text(
                            _currentMonth.toUpperCase(),
                            style: TextStyle(
                              color: widget.primaryColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    _buildNavButton(
                      icon: Icons.chevron_right,
                      onPressed: _goToNextMonth,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'].map((day) {
                        return Expanded(
                          child: Center(
                            child: Text(
                              day,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF666666),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    Column(
                      children: _calendarDays.map((week) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: week.map((date) {
                              if (date == null) {
                                return Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.all(4),
                                    height: 50,
                                  ),
                                );
                              }

                              final isCurrentMonth = _isCurrentMonth(date);
                              final hasEvent = _hasEvent(date);
                              final isToday = _isToday(date);
                              final isSelected = _isSelected(date);
                              final isPastDay = _isPastDay(date);

                              return Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedDate = date;
                                      if (!isCurrentMonth) {
                                        _currentDate = DateTime(
                                            date.year, date.month, 1);
                                        _generateCalendar();
                                      }
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.all(4),
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: isPastDay
                                          ? const Color(0xFFF5F5F5)
                                          : isSelected
                                              ? widget.primaryColor
                                              : isToday
                                                  ? widget.yellowColor.withValues(
                                                      alpha: 0.15)
                                                  : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isPastDay
                                            ? Colors.grey[200]!
                                            : isSelected
                                                ? widget.primaryColor
                                                : isToday
                                                    ? widget.yellowColor
                                                    : Colors.grey[200]!,
                                        width: isPastDay
                                            ? 1
                                            : isSelected
                                                ? 2
                                                : (isToday ? 1.5 : 1),
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: widget.primaryColor
                                                    .withValues(alpha: 0.3),
                                                blurRadius: 6,
                                                offset: const Offset(0, 3),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              date.day.toString(),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: isSelected
                                                    ? FontWeight.w800
                                                    : FontWeight.w600,
                                                color: isPastDay
                                                    ? const Color(0xFF999999)
                                                    : isSelected
                                                        ? Colors.white
                                                        : isCurrentMonth
                                                            ? Colors.black
                                                            : Colors.grey[400],
                                              ),
                                            ),
                                            if (hasEvent && isPastDay)
                                              Container(
                                                margin: const EdgeInsets.only(
                                                    top: 2),
                                                width: 6,
                                                height: 6,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF999999),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            if (hasEvent && !isPastDay)
                                              Container(
                                                margin: const EdgeInsets.only(
                                                    top: 2),
                                                width: 6,
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? Colors.white
                                                      : widget.primaryColor,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (_selectedDate != null) ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_getIndonesianDayName(DateFormat('EEEE').format(_selectedDate!))}, ${_selectedDate!.day} ${_getIndonesianMonthName(DateFormat('MMMM').format(_selectedDate!))} ${_selectedDate!.year}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_getEventsForDay(_selectedDate!).where((e) => e['type'] == 'jadwal').length} Jadwal, ${_getEventsForDay(_selectedDate!).where((e) => e['type'] == 'riwayat').length} Upload',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF666666),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getEventsForDay(_selectedDate!).isEmpty
                                  ? Colors.grey.withValues(alpha: 0.1)
                                  : Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _getEventsForDay(_selectedDate!).isEmpty
                                    ? Colors.grey.withValues(alpha: 0.3)
                                    : Colors.green.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              '${_getEventsForDay(_selectedDate!).length} Kegiatan',
                              style: TextStyle(
                                color: _getEventsForDay(_selectedDate!).isEmpty
                                    ? Colors.grey
                                    : Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (_getEventsForDay(_selectedDate!).isEmpty)
                        Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.event_available,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Tidak ada jadwal hari ini',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._getEventsForDay(_selectedDate!).map((event) {
                          if (event['type'] == 'jadwal') {
                            final kegiatan = event['data'] as KegiatanPkl;
                            final isPastEvent = kegiatan.tanggalMulai.isBefore(DateTime.now());
                            final jenisColor = _getJenisColor(kegiatan.jenisKegiatan);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isPastEvent
                                      ? Colors.grey[300]!
                                      : jenisColor.withValues(alpha: 0.3),
                                  width: isPastEvent ? 1 : 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: jenisColor.withValues(
                                                alpha: isPastEvent ? 0.05 : 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: jenisColor.withValues(
                                                  alpha: isPastEvent ? 0.1 : 0.3),
                                            ),
                                          ),
                                          child: Text(
                                            kegiatan.jenisKegiatan,
                                            style: TextStyle(
                                              color: isPastEvent
                                                  ? Colors.grey[600]
                                                  : jenisColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(kegiatan.status)
                                                .withValues(alpha: isPastEvent ? 0.05 : 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: _getStatusColor(kegiatan.status)
                                                  .withValues(alpha: isPastEvent ? 0.1 : 0.3),
                                            ),
                                          ),
                                          child: Text(
                                            kegiatan.status == 'active' ? 'Aktif' : 'Selesai',
                                            style: TextStyle(
                                              color: isPastEvent
                                                  ? Colors.grey[600]
                                                  : _getStatusColor(kegiatan.status),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      kegiatan.deskripsi,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: isPastEvent
                                            ? Colors.grey[700]
                                            : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today,
                                            size: 16,
                                            color: isPastEvent
                                                ? Colors.grey[500]
                                                : const Color(0xFF666666)),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${kegiatan.tanggalMulai.day} ${_getIndonesianMonthName(DateFormat('MMMM').format(kegiatan.tanggalMulai))} ${kegiatan.tanggalMulai.year}',
                                          style: TextStyle(
                                            color: isPastEvent
                                                ? Colors.grey[600]
                                                : const Color(0xFF666666),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (kegiatan.tanggalSelesai != kegiatan.tanggalMulai)
                                          Row(
                                            children: [
                                              const SizedBox(width: 8),
                                              Text('-',
                                                  style: TextStyle(
                                                      color: isPastEvent
                                                          ? Colors.grey[500]
                                                          : const Color(0xFF666666))),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${kegiatan.tanggalSelesai.day} ${_getIndonesianMonthName(DateFormat('MMMM').format(kegiatan.tanggalSelesai))} ${kegiatan.tanggalSelesai.year}',
                                                style: TextStyle(
                                                  color: isPastEvent
                                                      ? Colors.grey[600]
                                                      : const Color(0xFF666666),
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        if (isPastEvent)
                                          Container(
                                            margin: const EdgeInsets.only(left: 8),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Lewat',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          } else {
                            return _riwayatCard(event['data']);
                          }
                        }),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    if (_industriList.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[300]!, width: 1.5),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.assignment, size: 60, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            const Text(
                              'Belum ada tugas monitoring',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._industriList.map((industriData) => _buildIndustriCard(industriData)),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Riwayat Realisasi',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: widget.primaryColor,
                          ),
                        ),
                        const Spacer(),
                        if (_isLoadingRiwayat)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(widget.primaryColor),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_riwayatRealisasi.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E5E5)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.history, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            const Text(
                              'Belum ada riwayat realisasi',
                              style: TextStyle(
                                color: Color(0xFF666666),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._riwayatRealisasi.map((riwayat) {
                        return _riwayatCard(riwayat);
                      }),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isSelected(DateTime date) {
    return _selectedDate != null &&
        _selectedDate!.year == date.year &&
        _selectedDate!.month == date.month &&
        _selectedDate!.day == date.day;
  }

  bool _isCurrentMonth(DateTime date) {
    return date.year == _currentDate.year && date.month == _currentDate.month;
  }

  bool _isPastDay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDate = DateTime(date.year, date.month, date.day);
    return checkDate.isBefore(today);
  }

  Color _getJenisColor(String jenis) {
    switch (jenis) {
      case 'Pembekalan':
        return const Color(0xFF641E20);
      case 'Monitoring1':
        return Colors.green;
      case 'Monitoring2':
        return Colors.blue;
      case 'Penjemputan':
        return Colors.purple;
      default:
        return const Color(0xFF641E20);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      default:
        return const Color(0xFF641E20);
    }
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(icon, color: widget.primaryColor, size: 22),
        ),
      ),
    );
  }

  Widget _buildIndustriCard(Map<String, dynamic> industriData) {
    final industri = industriData['industri'] ?? {};
    final siswaCount = industriData['siswa_count'] ?? 0;
    final tasks = (industriData['tasks'] as List?) ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: widget.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: widget.primaryColor, width: 1.5),
                  ),
                  child: Icon(
                    Icons.apartment,
                    color: widget.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        industri['nama'] ?? 'Industri',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people,
                              size: 12,
                              color: widget.primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$siswaCount Siswa',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: widget.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 12,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${industri['alamat'] ?? ''} (${industri['jenis_industri'] ?? ''})',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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

          if (tasks.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            'JENIS KEGIATAN',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'RENTANG WAKTU',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'STATUS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  ...tasks.map((taskData) {
                    final kegiatan = taskData['kegiatan'] ?? {};
                    final isActive = kegiatan['is_active'] ?? false;
                    final canSubmit = kegiatan['can_submit'] ?? false;
                    final kegiatanId = kegiatan['id'];
                    final industriId = industri['id'];
                    
                    final taskKey = '${industriId}_$kegiatanId';
                    final isUploading = _isUploading[taskKey] ?? false;
                    final isUploaded = _isTaskAlreadyUploaded(industriId, kegiatanId);

                    final startDate = kegiatan['tanggal_mulai'] ?? '';
                    final endDate = kegiatan['tanggal_selesai'] ?? '';
                    final rentangWaktu = '$startDate - $endDate';

                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  kegiatan['jenis'] ?? 'Kegiatan',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  kegiatan['deskripsi'] ?? '-',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rentangWaktu,
                                  style: const TextStyle(
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? Colors.green.withValues(alpha: 0.1)
                                        : Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isActive ? 'Aktif' : 'Tidak Aktif',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isActive ? Colors.green : Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isUploaded)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          size: 14,
                                          color: Colors.green,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Selesai',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.green,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else if (isUploading)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(widget.primaryColor),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Mengunggah...',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: widget.primaryColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  ElevatedButton(
                                    onPressed: canSubmit && isActive && !isUploaded
                                        ? () => _startUploadProcess(
                                            industriId: industriId,
                                            kegiatanId: kegiatanId,
                                            kegiatan: kegiatan,
                                          )
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: canSubmit && isActive && !isUploaded
                                          ? widget.primaryColor
                                          : Colors.grey,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      minimumSize: const Size(0, 0),
                                    ),
                                    child: Text(
                                      isUploaded ? 'Selesai' : 'Unggah',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Belum ada kegiatan untuk industri ini',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _riwayatCard(Map<String, dynamic> riwayat) {
    String industriNama = 'Industri';
    String kegiatanNama = 'Kegiatan';
    
    for (var industriData in _industriList) {
      final industri = industriData['industri'] ?? {};
      if (industri['id'] == riwayat['industri_id']) {
        industriNama = industri['nama'] ?? 'Industri';
        
        final tasks = (industriData['tasks'] as List?) ?? [];
        for (var task in tasks) {
          final kegiatan = task['kegiatan'] ?? {};
          if (kegiatan['id'] == riwayat['kegiatan_id']) {
            kegiatanNama = kegiatan['jenis'] ?? 'Kegiatan';
            break;
          }
        }
        break;
      }
    }

    List<String> imageUrls = [];
    try {
      if (riwayat['bukti_foto_urls'] is List) {
        imageUrls = List<String>.from(riwayat['bukti_foto_urls']);
      } else if (riwayat['bukti_foto'] is String) {
        imageUrls = [riwayat['bukti_foto']];
      } else if (riwayat['bukti_foto'] is List) {
        imageUrls = List<String>.from(riwayat['bukti_foto']);
      }
    } catch (e) {
      print('Error parsing image URLs: $e');
    }

    imageUrls = imageUrls.where((url) => url.isNotEmpty).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.cloud_done,
                    color: widget.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kegiatanNama,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        industriNama,
                        style: const TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: widget.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    riwayat['status'] ?? 'Sudah',
                    style: TextStyle(
                      color: widget.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (riwayat['catatan'] != null && riwayat['catatan'].toString().isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Catatan:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF666666),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    riwayat['catatan'].toString(),
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            if (imageUrls.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bukti Foto:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF666666),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: imageUrls.length,
                      itemBuilder: (context, index) {
                        final url = imageUrls[index];
                        return GestureDetector(
                          onTap: () => _showImagePreview(url),
                          child: Container(
                            width: 80,
                            height: 80,
                            margin: EdgeInsets.only(
                              right: index < imageUrls.length - 1 ? 8 : 0,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[100],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                url,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(Icons.broken_image, color: Colors.grey),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Color(0xFF666666)),
                    const SizedBox(width: 6),
                    Text(
                      riwayat['tanggal_realisasi'] ?? '-',
                      style: const TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Text(
                  riwayat['created_at']?.toString().split('T')[0] ?? '-',
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _catatanController.dispose();
    super.dispose();
  }
}

class KegiatanPkl {
  final int id;
  final String deskripsi;
  final String jenisKegiatan;
  final int tahunAjaranId;
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final String status;
  final int createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  KegiatanPkl({
    required this.id,
    required this.deskripsi,
    required this.jenisKegiatan,
    required this.tahunAjaranId,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory KegiatanPkl.fromJson(Map<String, dynamic> json) {
    return KegiatanPkl(
      id: json['id'],
      deskripsi: json['deskripsi'],
      jenisKegiatan: json['jenis_kegiatan'],
      tahunAjaranId: json['tahun_ajaran_id'],
      tanggalMulai: DateTime.parse(json['tanggal_mulai']),
      tanggalSelesai: DateTime.parse(json['tanggal_selesai']),
      status: json['status'],
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deskripsi': deskripsi,
      'jenis_kegiatan': jenisKegiatan,
      'tahun_ajaran_id': tahunAjaranId,
      'tanggal_mulai': tanggalMulai.toIso8601String(),
      'tanggal_selesai': tanggalSelesai.toIso8601String(),
      'status': status,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}