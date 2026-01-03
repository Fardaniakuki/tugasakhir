import 'package:flutter/material.dart';

class StatGrid extends StatelessWidget {
  final VoidCallback onAddPressed;
  final Map<String, dynamic>? data;
  final void Function(String)? onBoxTap;

  const StatGrid({
    super.key,
    required this.onAddPressed,
    this.data,
    this.onBoxTap, required Map<String, Color> typeColors,
  });

  @override
  Widget build(BuildContext context) {
    final totalJurusan = data?['total_jurusan']?.toString() ?? '0';
    final totalSiswa = data?['total_siswa']?.toString() ?? '0';
    final totalGuru = data?['total_guru']?.toString() ?? '0';
    final totalIndustri = data?['total_industri']?.toString() ?? '0';
    final totalKelas = data?['total_kelas']?.toString() ?? '0';

    // Warna konsisten dengan desain dashboard (gradasi merah)

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Baris 1: Jurusan dan Peserta Didik
          Row(
            children: [
              Expanded(
                child: _ModernStatCard(
                  title: 'Jurusan',
                  count: totalJurusan,
                  icon: Icons.school,
                  color: const Color(0xFF8B0000),
                  height: 75,
                  onTap: () => onBoxTap?.call('Jurusan'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ModernStatCard(
                  title: 'Murid',
                  count: totalSiswa,
                  icon: Icons.menu_book,
                  color: const Color(0xFFB22222),
                  height: 75,
                  onTap: () => onBoxTap?.call('Murid'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // Baris 2: Pembimbing dan Industri
          Row(
            children: [
              Expanded(
                child: _ModernStatCard(
                  title: 'Guru',
                  count: totalGuru,
                  icon: Icons.people,
                  color: const Color(0xFFDC143C),
                  height: 75,
                  onTap: () => onBoxTap?.call('Guru'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ModernStatCard(
                  title: 'Industri',
                  count: totalIndustri,
                  icon: Icons.handshake,
                  color: const Color(0xFFCD5C5C),
                  height: 75,
                  onTap: () => onBoxTap?.call('Industri'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // Baris 3: Kelas (lebih panjang) dan tombol +
          Row(
            children: [
              Expanded(
                flex: 2, // Flex 2 untuk membuat lebih panjang
                child: _ModernStatCard(
                  title: 'Kelas',
                  count: totalKelas,
                  icon: Icons.class_,
                  color: const Color(0xFF5B1A1A),
                  height: 90,
                  onTap: () => onBoxTap?.call('Kelas'),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onAddPressed,
                child: Container(
                  width: 70,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B0000), Color(0xFF5B1A1A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5B1A1A).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.add, color: Colors.white, size: 32),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModernStatCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color color;
  final double height;
  final VoidCallback? onTap;

  const _ModernStatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    this.height = 75,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
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
}