import 'package:flutter/material.dart';

class SiswaRekap extends StatelessWidget {
  const SiswaRekap({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1FAEE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE63946),
        title: const Text(
          'REKAP HARIAN PKL',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: Colors.black, width: 3),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFB703),
              border: Border.all(color: Colors.black, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(3, 3),
                  blurRadius: 0,
                ),
              ],
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.download,
              color: Colors.black,
              size: 22,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==== INFO MINGGU INI ====
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFA8DADC),
                border: Border.all(color: Colors.black, width: 4),
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
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'MINGGU INI',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        '24-30 Des 2024',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoBox(
                          'HADIR',
                          '4',
                          Icons.check_circle,
                          const Color(0xFF06D6A0),
                          'HARI',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoBox(
                          'IZIN',
                          '1',
                          Icons.pending,
                          const Color(0xFFFFB703),
                          'KALI',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoBox(
                          'SAKIT',
                          '0',
                          Icons.medical_services,
                          const Color(0xFFE63946),
                          'KALI',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==== PRESENSI BULANAN ====
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF06D6A0),
                border: Border.all(color: Colors.black, width: 4),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_month,
                            color: Colors.black,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'PRESENSI DESEMBER',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '85% Hadir',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem('H', const Color(0xFF06D6A0), 'Hadir'),
                      const SizedBox(width: 16),
                      _buildLegendItem('I', const Color(0xFFFFB703), 'Izin'),
                      const SizedBox(width: 16),
                      _buildLegendItem('S', const Color(0xFFE63946), 'Sakit'),
                      const SizedBox(width: 16),
                      _buildLegendItem('A', Colors.grey, 'Alpha'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Calendar Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: 31, // Days in December
                    itemBuilder: (context, index) {
                      final day = index + 1;
                      final status = _getAttendanceStatus(day);
                      final isToday = day == 26; // Today's date

                      return Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: status == 'H'
                              ? const Color(0xFF06D6A0)
                              : status == 'I'
                                  ? const Color(0xFFFFB703)
                                  : status == 'S'
                                      ? const Color(0xFFE63946)
                                      : Colors.grey,
                          border: Border.all(
                            color: isToday ? Colors.white : Colors.black,
                            width: isToday ? 3 : 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black,
                              offset: isToday
                                  ? const Offset(3, 3)
                                  : const Offset(2, 2),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '$day',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),


            const SizedBox(height: 20),

            // ==== CATATAN HARIAN ====
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB703),
                border: Border.all(color: Colors.black, width: 4),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.note,
                        color: Colors.black,
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'CATATAN HARIAN',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDailyNote(
                    'Senin, 23 Des 2024',
                    'Membuat dashboard monitoring dengan Flutter. Mempelajari state management dengan Riverpod.',
                    '08:00 - 16:00',
                    'HADIR',
                  ),
                  const SizedBox(height: 12),
                  _buildDailyNote(
                    'Selasa, 24 Des 2024',
                    'Debugging API integration. Meeting dengan tim developer untuk review code.',
                    '08:30 - 15:30',
                    'IZIN SETENGAH HARI',
                  ),
                  const SizedBox(height: 12),
                  _buildDailyNote(
                    'Rabu, 25 Des 2024',
                    'Implementasi authentication system. Testing aplikasi di berbagai device.',
                    '08:00 - 16:00',
                    'HADIR',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==== LIST IZIN ====
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE63946),
                border: Border.all(color: Colors.black, width: 4),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.pending_actions,
                        color: Colors.white,
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'RIWAYAT IZIN',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPermissionItem(
                    'Izin Keluarga',
                    'Acara keluarga penting',
                    '24 Des 2024',
                    'DISETUJUI',
                    Icons.family_restroom,
                  ),
                  const SizedBox(height: 12),
                  _buildPermissionItem(
                    'Sakit',
                    'Demam dan flu',
                    '15 Des 2024',
                    'DISETUJUI',
                    Icons.medical_services,
                  ),
                  const SizedBox(height: 12),
                  _buildPermissionItem(
                    'Izin Dinas',
                    'Surat dari sekolah',
                    '5 Des 2024',
                    'DISETUJUI',
                    Icons.school,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==== PENCAPAIAN ====
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF1FAEE),
                border: Border.all(color: Colors.black, width: 4),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.emoji_events,
                        color: Color(0xFFE63946),
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'PENCAPAIAN',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAchievementItem(
                          'Perfect Week',
                          '1 minggu full hadir',
                          Icons.check_circle_outline,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildAchievementItem(
                          'On Time King',
                          'Selalu tepat waktu',
                          Icons.access_time_filled,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAchievementItem(
                          'Task Master',
                          'Selesaikan 50 task',
                          Icons.assignment_turned_in,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildAchievementItem(
                          '3 Month Streak',
                          'PKL 3 bulan aktif',
                          Icons.timeline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(
      String title, String value, IconData icon, Color color, String unit) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.black, width: 3),
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            unit,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.black54,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDailyNote(String date, String note, String time, String status) {
    Color statusColor;
    switch (status) {
      case 'HADIR':
        statusColor = const Color(0xFF06D6A0);
        break;
      case 'IZIN SETENGAH HARI':
        statusColor = const Color(0xFFFFB703);
        break;
      default:
        statusColor = const Color(0xFFE63946);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.access_time,
                size: 14,
                color: Colors.black54,
              ),
              const SizedBox(width: 4),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem(
      String type, String reason, String date, String status, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF1D3557),
              border: Border.all(color: Colors.black, width: 3),
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      type,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: status == 'DISETUJUI'
                            ? const Color(0xFF06D6A0)
                            : const Color(0xFFFFB703),
                        border: Border.all(color: Colors.black, width: 2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String letter, Color color, String label) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              letter,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementItem(
      String title, String description, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFE63946),
              border: Border.all(color: Colors.black, width: 3),
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center, // PERBAIKAN: textAlign di sini
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            textAlign: TextAlign.center, // PERBAIKAN: textAlign di sini
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getAttendanceStatus(int day) {
    // Simulasi data kehadiran (ini bisa diganti dengan data real)
    final Map<int, String> attendanceData = {
      1: 'H',
      2: 'H',
      3: 'H',
      4: 'I',
      5: 'H',
      8: 'H',
      9: 'H',
      10: 'H',
      11: 'H',
      12: 'S',
      15: 'H',
      16: 'H',
      17: 'H',
      18: 'H',
      19: 'H',
      22: 'H',
      23: 'H',
      24: 'I',
      25: 'H',
      26: 'H',
      29: 'H',
      30: 'H',
      31: 'H',
    };

    return attendanceData[day] ?? 'A'; // A untuk Alpha/tidak ada data
  }
}
