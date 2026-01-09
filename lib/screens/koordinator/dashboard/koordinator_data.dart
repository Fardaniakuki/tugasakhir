import 'package:flutter/material.dart';

class KoordinatorData extends StatefulWidget {
  const KoordinatorData({super.key});

  @override
  State<KoordinatorData> createState() => _KoordinatorDataState();
}

class _KoordinatorDataState extends State<KoordinatorData> {
  // Neo Brutalism Colors
  static const Color _primaryColor = Color(0xFFE63946);
  static const Color _secondaryColor = Color(0xFFF1FAEE);
  static const Color _accentColor = Color(0xFFA8DADC);
  static const Color _darkColor = Color(0xFF1D3557);
  static const Color _yellowColor = Color(0xFFFFB703);
  static const Color _greenColor = Color(0xFF06D6A0);
  static const Color _blackColor = Colors.black;

  // File upload state
  String? _fileName;
  double _uploadProgress = 0.0;
  bool _isUploading = false;

  // List of uploaded documents
  final List<Map<String, String>> _documents = [
    {
      'name': 'SURAT PERJANJIAN PKL 2024',
      'type': 'PDF',
      'date': '15 Jan 2024',
    },
    {
      'name': 'BERITA ACARA PEMBEKALAN',
      'type': 'DOCX',
      'date': '10 Jan 2024',
    },
    {
      'name': 'LAPORAN MONITORING SISWA',
      'type': 'PDF',
      'date': '22 Jan 2024',
    },
    {
      'name': 'DATA SISWA PKL RPL',
      'type': 'XLSX',
      'date': '5 Feb 2024',
    },
    {
      'name': 'JADWAL KEGIATAN PKL',
      'type': 'PDF',
      'date': '28 Jan 2024',
    },
  ];

  void _simulateUpload() {
    if (_isUploading) return;
    
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _fileName = 'dokumen_pkl_${DateTime.now().millisecondsSinceEpoch}.pdf';
    });

    // Simulate upload progress
    const totalSteps = 20;
    for (int i = 0; i <= totalSteps; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          setState(() {
            _uploadProgress = i / totalSteps;
            if (i == totalSteps) {
              _isUploading = false;
              // Add to documents list
              _documents.insert(0, {
                'name': _fileName!,
                'type': 'PDF',
                'date': '${DateTime.now().day} ${_getMonthName(DateTime.now().month)} ${DateTime.now().year}',
              });
            }
          });
        }
      });
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return months[month - 1];
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'PDF':
        return _primaryColor;
      case 'DOCX':
        return _darkColor;
      case 'XLSX':
        return _greenColor;
      default:
        return _accentColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _secondaryColor,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER NEO-BRUTALISM
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: _darkColor,
                border: Border(
                  bottom: BorderSide(color: _blackColor, width: 4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _blackColor,
                    offset: Offset(0, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      border: Border.all(color: _blackColor, width: 3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'UPLOAD DOKUMEN PKL',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: _yellowColor,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Kelola Dokumen & Surat Resmi',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // MAIN CONTENT
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // UPLOAD CARD
                    Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _secondaryColor,
                        border: Border.all(color: _blackColor, width: 4),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: _blackColor,
                            offset: Offset(6, 6),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // UPLOAD ICON
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: _primaryColor,
                                border: Border.all(color: _blackColor, width: 4),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(
                                    color: _blackColor,
                                    offset: Offset(4, 4),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.cloud_upload,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // TITLE
                            const Text(
                              'DRAG & DROP FILE',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: _darkColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // DESCRIPTION
                            Text(
                              'Seret file ke sini atau klik tombol upload',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: _darkColor.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // FILE INFO BOX
                            if (_fileName != null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _accentColor,
                                  border: Border.all(color: _blackColor, width: 3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: _primaryColor,
                                            border: Border.all(color: _blackColor, width: 2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              'PDF',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 12,
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
                                                _fileName!,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w900,
                                                  color: _darkColor,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Sedang diupload...',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: _darkColor.withValues(alpha: 0.7),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    if (_isUploading)
                                      Column(
                                        children: [
                                          const SizedBox(height: 16),
                                          Container(
                                            height: 20,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(color: _blackColor, width: 2),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Stack(
                                              children: [
                                                Container(
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  decoration: BoxDecoration(
                                                    color: _secondaryColor,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                                AnimatedContainer(
                                                  duration: const Duration(milliseconds: 200),
                                                  width: MediaQuery.of(context).size.width * 0.7 * _uploadProgress,
                                                  height: double.infinity,
                                                  decoration: BoxDecoration(
                                                    color: _greenColor,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${(_uploadProgress * 100).toInt()}%',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                              color: _darkColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            
                            const SizedBox(height: 24),
                            
                            // UPLOAD BUTTON
                            Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                color: _isUploading ? Colors.grey[400] : _greenColor,
                                border: Border.all(color: _blackColor, width: 3),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: _blackColor,
                                    offset: Offset(4, 4),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              child: TextButton.icon(
                                onPressed: _isUploading ? null : _simulateUpload,
                                icon: Icon(
                                  _isUploading ? Icons.hourglass_bottom : Icons.upload,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                label: Text(
                                  _isUploading ? 'SEDANG UPLOAD...' : 'PILIH FILE & UPLOAD',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // FILE TYPE INFO
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _yellowColor,
                                border: Border.all(color: _blackColor, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.info, color: Colors.white, size: 16),
                                  SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'PDF, DOC, DOCX, XLSX • MAKS. 10MB',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // DOCUMENTS LIST SECTION
                    Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _secondaryColor,
                        border: Border.all(color: _blackColor, width: 4),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: _blackColor,
                            offset: Offset(6, 6),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // SECTION HEADER
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: _darkColor,
                                border: Border.all(color: _blackColor, width: 3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.folder, color: _yellowColor, size: 24),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'DOKUMEN TERKIRIM',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: _yellowColor,
                                        letterSpacing: -0.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _primaryColor,
                                      border: Border.all(color: _blackColor, width: 2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${_documents.length} FILE',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // DOCUMENTS LIST - FIXED OVERFLOW
                            ..._documents.map((doc) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: _blackColor, width: 2),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: _blackColor,
                                      offset: Offset(3, 3),
                                      blurRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // FILE TYPE ICON
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: _getTypeColor(doc['type']!),
                                          border: Border.all(color: _blackColor, width: 3),
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: _blackColor,
                                              offset: Offset(2, 2),
                                              blurRadius: 0,
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            doc['type']!,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                      
                                      const SizedBox(width: 16),
                                      
                                      // FILE INFO - FIXED OVERFLOW
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              doc['name']!,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w900,
                                                color: _darkColor,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(Icons.calendar_today, 
                                                  size: 14, 
                                                  color: _darkColor.withValues(alpha: 0.6)
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  doc['date']!,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: _darkColor.withValues(alpha: 0.7),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      const SizedBox(width: 12),
                                      
                                      // ACTION BUTTONS - VERTICAL LAYOUT
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: _greenColor,
                                              border: Border.all(color: _blackColor, width: 2),
                                              borderRadius: BorderRadius.circular(8),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: _blackColor,
                                                  offset: Offset(2, 2),
                                                  blurRadius: 0,
                                                ),
                                              ],
                                            ),
                                            child: IconButton(
                                              onPressed: () {},
                                              icon: const Icon(Icons.download, 
                                                color: Colors.white, 
                                                size: 18
                                              ),
                                              padding: EdgeInsets.zero,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: _primaryColor,
                                              border: Border.all(color: _blackColor, width: 2),
                                              borderRadius: BorderRadius.circular(8),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: _blackColor,
                                                  offset: Offset(2, 2),
                                                  blurRadius: 0,
                                                ),
                                              ],
                                            ),
                                            child: IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  _documents.remove(doc);
                                                });
                                              },
                                              icon: const Icon(Icons.delete, 
                                                color: Colors.white, 
                                                size: 18
                                              ),
                                              padding: EdgeInsets.zero,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),

                            // EMPTY STATE
                            if (_documents.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(40),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.folder_open,
                                      size: 60,
                                      color: _darkColor.withValues(alpha: 0.3),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Belum ada dokumen',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: _darkColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}