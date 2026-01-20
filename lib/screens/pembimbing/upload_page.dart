import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:photo_view/photo_view.dart';

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

  // State management
  bool _isLoading = true;
  bool _isLoadingRiwayat = false;
  String _errorMessage = '';
  String? _accessToken;

  // Upload state - SIMPLE VERSION
  final Map<String, bool> _isUploading = {}; // Key: "${industriId}_${kegiatanId}"
  final Map<String, List<String>> _uploadedFiles = {}; // Key: "${industriId}_${kegiatanId}"
  
  // Untuk modal upload sementara
  List<XFile> _selectedImages = [];
  final TextEditingController _catatanController = TextEditingController();

  // Kalender
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _selectedFilter = 'Semua';

  // Statistik
  int _totalIndustri = 0;
  int _totalTasks = 0;
  int _completedTasks = 0;
  int _pendingTasks = 0;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadTokenAndData();
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
      _updateUploadedFilesFromRiwayat(); // Update uploaded files dari riwayat

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

  // Update uploaded files dari riwayat realisasi
  void _updateUploadedFilesFromRiwayat() {
    _uploadedFiles.clear(); // Clear dulu
    
    for (var riwayat in _riwayatRealisasi) {
      try {
        final taskKey = '${riwayat['industri_id']}_${riwayat['kegiatan_id']}';
        
        List<String> imageUrls = [];
        if (riwayat['bukti_foto_urls'] is List) {
          imageUrls = List<String>.from(riwayat['bukti_foto_urls']);
        } else if (riwayat['bukti_foto'] is String) {
          imageUrls = [riwayat['bukti_foto']];
        } else if (riwayat['bukti_foto'] is List) {
          imageUrls = List<String>.from(riwayat['bukti_foto']);
        }
        
        if (imageUrls.isNotEmpty) {
          _uploadedFiles[taskKey] = imageUrls;
        }
      } catch (e) {
        print('Error updating uploaded files: $e');
      }
    }
  }

  // Load data industri dengan tasks
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
            _totalIndustri = data['summary']['total_industri'] ?? 0;
            _totalTasks = data['summary']['total_tasks'] ?? 0;
            _completedTasks = data['summary']['completed_tasks'] ?? 0;
            _pendingTasks = data['summary']['pending_tasks'] ?? 0;
          });
        } else {
          // Jika tidak ada data
          setState(() {
            _industriList = [];
            _totalIndustri = 0;
            _totalTasks = 0;
            _completedTasks = 0;
            _pendingTasks = 0;
          });
        }
      } else if (response.statusCode == 404) {
        // Endpoint tidak ditemukan, coba endpoint alternatif
        await _loadIndustriDataAlternative();
      } else {
        print('Error load industri: ${response.statusCode}');
        setState(() {
          _industriList = [];
          _totalIndustri = 0;
          _totalTasks = 0;
          _completedTasks = 0;
          _pendingTasks = 0;
        });
      }
    } catch (e) {
      print('Error load industri: $e');
      setState(() {
        _industriList = [];
        _totalIndustri = 0;
        _totalTasks = 0;
        _completedTasks = 0;
        _pendingTasks = 0;
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
            _totalIndustri = _industriList.length;
            _totalTasks = _industriList.length; // Asumsi 1 task per industri
            _completedTasks = 0;
            _pendingTasks = _totalTasks;
          });
        }
      } else {
        setState(() {
          _industriList = [];
          _totalIndustri = 0;
          _totalTasks = 0;
          _completedTasks = 0;
          _pendingTasks = 0;
        });
      }
    } catch (e) {
      print('Error load industri alternative: $e');
      setState(() {
        _industriList = [];
        _totalIndustri = 0;
        _totalTasks = 0;
        _completedTasks = 0;
        _pendingTasks = 0;
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

  // ==================== FUNGSI UPLOAD SEDERHANA ====================
  // 1. Tombol upload ditekan -> Pilih gambar
  Future<void> _startUploadProcess({
    required int industriId,
    required int kegiatanId,
    required dynamic kegiatan,
  }) async {
    
    // VALIDASI: Cek apakah sudah pernah upload
    if (_isTaskAlreadyUploaded(industriId, kegiatanId)) {
      _showSnackBar('⚠️ Task ini sudah pernah diupload!', isError: true);
      
      // Tampilkan dialog konfirmasi untuk lihat bukti
      await _showAlreadyUploadedDialog(industriId, kegiatanId);
      return;
    }
    
    // Reset data sebelumnya
    _selectedImages.clear();
    _catatanController.clear();
    
    // Tampilkan dialog pilihan sumber gambar
    await _showImageSourceDialog(industriId, kegiatanId, kegiatan);
  }

  // Fungsi untuk mengecek apakah task sudah diupload
  bool _isTaskAlreadyUploaded(int industriId, int kegiatanId) {
    final taskKey = '${industriId}_$kegiatanId';
    
    // Cek di _uploadedFiles
    if (_uploadedFiles.containsKey(taskKey) && _uploadedFiles[taskKey]!.isNotEmpty) {
      return true;
    }
    
    // Cek di _riwayatRealisasi
    return _riwayatRealisasi.any((riwayat) {
      return riwayat['industri_id'] == industriId && 
             riwayat['kegiatan_id'] == kegiatanId;
    });
  }

  // Dialog jika sudah pernah upload
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

  // Dialog untuk memilih sumber gambar
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
          _selectedImages = [pickedFile]; // Simpan gambar
          
          // Tampilkan preview dan input catatan
          await _showPreviewAndCatatanDialog(industriId, kegiatanId, kegiatan);
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Gagal memilih gambar: ${e.toString()}', isError: true);
        }
      }
    }
  }

  // Dialog untuk preview dan input catatan
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
                'Upload Bukti ${kegiatan['jenis']}',
                style: TextStyle(color: widget.primaryColor),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Preview Gambar
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
                    
                    // Input Catatan
                    TextField(
                      controller: _catatanController,
                      decoration: const InputDecoration(
                        hintText: 'Tambahkan catatan (opsional)...',
                        border: OutlineInputBorder(),
                        labelText: 'Catatan',
                      ),
                      maxLines: 3,
                    ),
                    
                    // Status Upload
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
                      status = 'Mengupload gambar...';
                    });

                    try {
                      // Upload gambar
                      final url = await _uploadSingleImage(_selectedImages.first);
                      
                      if (url != null && url.isNotEmpty) {
                        setDialogState(() {
                          status = 'Menyimpan data realisasi...';
                        });

                        // Submit data
                        final success = await _submitRealisasiData(
                          industriId: industriId,
                          kegiatanId: kegiatanId,
                          tanggalRealisasi: _formatDate(DateTime.now()),
                          imageUrls: [url],
                          catatan: _catatanController.text,
                        );

                        if (success) {
                          setDialogState(() {
                            status = '✅ Upload berhasil!';
                          });

                          // Update state
                          if (mounted) {
                            setState(() {
                              if (_uploadedFiles[taskKey] == null) {
                                _uploadedFiles[taskKey] = [];
                              }
                              _uploadedFiles[taskKey]!.add(url);
                              _isUploading[taskKey] = false;
                            });
                          }

                          // Tunggu 2 detik lalu close
                          await Future.delayed(const Duration(seconds: 2));
                          
                          if (mounted) {
                            Navigator.pop(context);
                            _showSnackBar('✅ Bukti berhasil diunggah!');
                            
                            // Refresh data
                            await _loadRiwayatRealisasi();
                            _generateCalendarEvents();
                            _updateUploadedFilesFromRiwayat();
                            
                            // Update UI
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
                          status = '❌ Gagal upload gambar';
                          isUploading = false;
                        });
                        
                        if (mounted) {
                          _showSnackBar('❌ Gagal upload gambar', isError: true);
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
                      : const Text('Upload'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Upload gambar ke server - SESUAI DOKUMENTASI API
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

      // Baca file sebagai bytes
      final bytes = await imageFile.readAsBytes();
      
      // Debug: print file size
      print('🟡 Uploading file: ${imageFile.name}');
      print('🟡 File size: ${bytes.length} bytes');
      print('🟡 Access token: ${_accessToken!.substring(0, 20)}...');
      
      // Cek file size (5MB limit sesuai dokumentasi)
      if (bytes.length > 5 * 1024 * 1024) {
        print('❌ File terlalu besar (${bytes.length} bytes > 5MB)');
        if (mounted) {
          _showSnackBar('File terlalu besar (max 5MB)', isError: true);
        }
        return null;
      }

      // Dapatkan MIME type dari file
      String mimeType = 'image/jpeg';
      if (imageFile.name.toLowerCase().endsWith('.png')) {
        mimeType = 'image/png';
      } else if (imageFile.name.toLowerCase().endsWith('.gif')) {
        mimeType = 'image/gif';
      }

      print('🟡 Content-Type: $mimeType');

      // Buat request POST dengan raw binary data (sesuai dokumentasi)
      final uploadUrl = Uri.parse('$baseUrl/api/upload/image');
      
      print('🟡 Upload URL: $uploadUrl');
      
      final response = await http.post(
        uploadUrl,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': mimeType,
          'Accept': 'application/json',
        },
        body: bytes, // Langsung kirim binary data
      );

      print('🟡 Upload response status: ${response.statusCode}');
      print('🟡 Upload response headers: ${response.headers}');
      print('🟡 Upload response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = jsonDecode(response.body);
          print('✅ Upload success data: $data');
          
          // Cari URL di response
          if (data is Map<String, dynamic>) {
            // Coba berbagai kemungkinan key untuk URL
            if (data.containsKey('url') && data['url'] is String) {
              return data['url'] as String;
            } else if (data.containsKey('data') && data['data'] is String) {
              return data['data'] as String;
            } else if (data.containsKey('path') && data['path'] is String) {
              final path = data['path'] as String;
              // Jika path relative, gabungkan dengan base URL
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
            
            // Cari key yang mengandung 'url'
            for (var key in data.keys) {
              if (key.toString().toLowerCase().contains('url') &&
                  data[key] is String &&
                  (data[key] as String).isNotEmpty) {
                return data[key] as String;
              }
            }
          }
          
          // Jika response langsung URL string
          if (response.body.startsWith('http://') || response.body.startsWith('https://')) {
            return response.body;
          }
          
          print('⚠️ Tidak dapat menemukan URL dalam response');
          return null;
          
        } catch (e) {
          print('❌ Error parsing upload response: $e');
          print('❌ Raw response: ${response.body}');
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

  // Submit data ke API
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

      // Buat body dengan format yang benar
      final body = {
        'bukti_foto_urls': imageUrls,
        'catatan': catatan,
        'industri_id': industriId,
        'kegiatan_id': kegiatanId,
        'tanggal_realisasi': tanggalRealisasi,
      };

      print('🟡 Submitting to: $submitUrl');
      print('🟡 Request body: ${jsonEncode(body)}');

      final response = await http.post(
        submitUrl,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('🟡 Submit response status: ${response.statusCode}');
      print('🟡 Submit response body: ${response.body}');

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
            
            // Debug: print error details
            print('❌ Error details: $errorData');
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

  // ==================== WIDGETS ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage.isNotEmpty
              ? _buildErrorState()
              : _buildContentState(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(widget.primaryColor),
          ),
          const SizedBox(height: 16),
          const Text('Memuat data...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
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
    return Column(
      children: [
        // App Bar Custom
        Container(
          padding: const EdgeInsets.only(top: 40, bottom: 20, left: 20, right: 20),
          decoration: BoxDecoration(
            color: widget.primaryColor,
            boxShadow: [widget.heavyShadow],
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Kalender & Unggah Bukti',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            controller: widget.scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kalender
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFE5E5E5)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'Kalender Kegiatan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TableCalendar(
                          firstDay: DateTime.now().subtract(const Duration(days: 365)),
                          lastDay: DateTime.now().add(const Duration(days: 365)),
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          },
                          onPageChanged: (focusedDay) {
                            _focusedDay = focusedDay;
                          },
                          calendarFormat: _calendarFormat,
                          onFormatChanged: (format) {
                            setState(() {
                              _calendarFormat = format;
                            });
                          },
                          eventLoader: (day) {
                            return _events[day] ?? [];
                          },
                          calendarStyle: CalendarStyle(
                            selectedDecoration: BoxDecoration(
                              color: widget.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            todayDecoration: BoxDecoration(
                              color: widget.primaryColor.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            markerDecoration: BoxDecoration(
                              color: widget.accentColor,
                              shape: BoxShape.circle,
                            ),
                            markersMaxCount: 3,
                          ),
                          headerStyle: HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            titleTextStyle: TextStyle(
                              color: widget.primaryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _legendItem(widget.primaryColor, 'Hari Ini'),
                            _legendItem(widget.accentColor, 'Ada Bukti'),
                            _legendItem(widget.primaryColor.withValues(alpha: 0.3), 'Terpilih'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Statistik Cards
                SizedBox(
                  height: 115,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Industri',
                          '$_totalIndustri',
                          Icons.apartment,
                          widget.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Total Tugas',
                          '$_totalTasks',
                          Icons.assignment,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 115,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Tugas Selesai',
                          '$_completedTasks',
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Tugas Tertunda',
                          '$_pendingTasks',
                          Icons.pending,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Search and Filter
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[300]!, width: 1.5),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [widget.lightShadow],
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 44,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              Icon(Icons.search, color: Colors.grey[600], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: const InputDecoration.collapsed(
                                    hintText: 'Cari industri atau lokasi...',
                                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                                  ),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              if (_searchController.text.isNotEmpty)
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                    });
                                  },
                                  icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 40,
                        child: Row(
                          children: [
                            const Text(
                              'Filter',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: ['Semua', 'Aktif', 'Menunggu', 'Selesai'].map((filter) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedFilter = filter;
                                          });
                                        },
                                        child: Container(
                                          height: 36,
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: _selectedFilter == filter
                                                ? widget.primaryColor
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: widget.primaryColor),
                                          ),
                                          child: Text(
                                            filter,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: _selectedFilter == filter
                                                  ? Colors.white
                                                  : widget.primaryColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Daftar Industri dengan Tasks
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

                const SizedBox(height: 32),

                // RIWAYAT REALISASI
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
        ),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [widget.lightShadow],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: widget.blackColor,
                  ),
                ),
              ],
            ),
          ),
        ],
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
        boxShadow: [widget.lightShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Industri
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

          // Tabel Kegiatan
          if (tasks.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Header Tabel
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

                  // List Kegiatan
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
                          // Kolom Jenis Kegiatan
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

                          // Kolom Rentang Waktu
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

                          // Kolom Status
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
                                          'Uploading...',
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
    // Cari data industri dan kegiatan
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