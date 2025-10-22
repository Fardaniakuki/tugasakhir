import 'package:flutter/material.dart';

class PersonTile extends StatelessWidget {
  final String name;
  final String nisn;
  final String tglLahir;
  final String? jurusan;
  final String? kelas;
  final String role;
  final String? kodeGuru;
  final String? userId;
  final VoidCallback onTap;

  const PersonTile({
    super.key,
    required this.name,
    required this.nisn,
    required this.tglLahir,
    this.jurusan,
    this.kelas,
    required this.role,
    this.kodeGuru,
    this.userId,
    required this.onTap,
  });

  // Pindahkan fungsi-fungsi ke luar build() dan optimalkan
  String get _displayIdentifier => nisn;

  String get _displayKelas {
    if (role.toLowerCase() == 'guru') {
      return (kodeGuru != null && kodeGuru!.isNotEmpty && kodeGuru != 'null')
          ? kodeGuru!
          : 'Tidak ada kode guru';
    } else {
      final String kelasText = kelas?.replaceAll('-', '').trim() ?? '';
      final String jurusanText = jurusan?.replaceAll('-', '').trim() ?? '';
      
      if (kelasText.isNotEmpty && jurusanText.isNotEmpty) {
        return '$kelasText $jurusanText';
      } else if (kelasText.isNotEmpty) {
        return kelasText;
      } else if (jurusanText.isNotEmpty) {
        return jurusanText;
      } else {
        return 'Tidak ada data';
      }
    }
  }

  String get _displayTglLahir {
    if (role.toLowerCase() == 'guru') {
      return (userId != null && userId!.isNotEmpty && userId != 'null')
          ? userId!
          : 'Tidak ada ID user';
    } else {
      return _formatTanggalLahir(tglLahir);
    }
  }

  String get _identifierTitle => role.toLowerCase() == 'guru' ? 'NIP' : 'NISN';
  
  String get _tglLahirTitle => role.toLowerCase() == 'guru' ? 'ID User' : 'Tanggal Lahir';
  
  String get _kelasTitle => role.toLowerCase() == 'guru' ? 'Kode Guru' : 'Kelas';
  
  IconData get _kelasIcon => role.toLowerCase() == 'guru' ? Icons.code : Icons.school;
  
  // PERBAIKAN: Icon untuk ID User guru diganti dari cake ke person
  IconData get _tglLahirIcon => role.toLowerCase() == 'guru' ? Icons.person : Icons.cake;
  
  IconData get _identifierIcon => role.toLowerCase() == 'guru' ? Icons.credit_card : Icons.badge;

  // Optimalkan format tanggal - gunakan cached atau sederhana
  String _formatTanggalLahir(String tanggal) {
    if (tanggal.isEmpty || tanggal == '-') return '-';
    
    // Jika sudah format yang diinginkan, return langsung
    if (tanggal.contains('/')) return tanggal;
    
    // Format sederhana untuk kasus umum
    try {
      if (tanggal.contains('-')) {
        final parts = tanggal.split('-');
        if (parts.length >= 3) {
          final year = parts[0];
          final month = parts[1];
          final day = parts[2].split('T')[0].split(' ')[0];
          return '$day/$month/$year';
        }
      }
      return tanggal;
    } catch (e) {
      return tanggal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF641E20),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _tag(
                          _identifierIcon,
                          '$_identifierTitle: $_displayIdentifier',
                          Colors.grey[300]!, 
                          Colors.grey[700]!
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoItem(Icons.format_list_numbered, 'Role', role),
              _infoItem(_kelasIcon, _kelasTitle, _displayKelas),
              // PERBAIKAN: Icon untuk ID User guru diganti dari cake ke person
              _infoItem(_tglLahirIcon, _tglLahirTitle, _displayTglLahir),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.arrow_forward, color: Color(0xFF641E20)),
              label: const Text(
                'Lihat profil lengkap',
                style: TextStyle(color: Color(0xFF641E20)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(IconData icon, String text, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: iconColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String title, String value) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFB22222)), // UBAH WARNA DI SINI
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class JurusanTile extends StatelessWidget {
  final String nama;
  final String kode;
  final int jumlahKelas; // TAMBAH INI
  final VoidCallback onTap;

  const JurusanTile({
    super.key,
    required this.nama,
    required this.kode,
    required this.jumlahKelas, // TAMBAH INI
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF641E20),
                ),
                child: const Icon(Icons.school, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // UBAH MENJADI 3 ITEM: ROLE, KODE, JUMLAH KELAS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoItem(Icons.format_list_numbered, 'Role', 'Jurusan'),
              _infoItem(Icons.code, 'Kode', kode),
              _infoItem(Icons.class_, 'Jumlah Kelas', '$jumlahKelas'), // TAMBAH INI
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.arrow_forward, color: Color(0xFF641E20)),
              label: const Text(
                'Lihat profil lengkap',
                style: TextStyle(color: Color(0xFF641E20)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String title, String value) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFB22222)), // UBAH WARNA DI SINI
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class KelasTile extends StatelessWidget {
  final String nama;
  final String jurusanNama;
  final int jumlahMurid; // TAMBAH INI
  final VoidCallback onTap;

  const KelasTile({
    super.key,
    required this.nama,
    required this.jurusanNama,
    required this.jumlahMurid, // TAMBAH INI
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF641E20),
                ),
                child: const Icon(Icons.class_, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // UBAH MENJADI 3 ITEM: ROLE, JURUSAN, JUMLAH MURID
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoItem(Icons.format_list_numbered, 'Role', 'Kelas'),
              _infoItem(Icons.school, 'Jurusan', jurusanNama),
              _infoItem(Icons.people, 'Jumlah Murid', '$jumlahMurid'), // TAMBAH INI
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.arrow_forward, color: Color(0xFF641E20)),
              label: const Text(
                'Lihat profil lengkap',
                style: TextStyle(color: Color(0xFF641E20)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String title, String value) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFB22222)), // UBAH WARNA DI SINI
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class IndustriTile extends StatelessWidget {
  final String nama;
  final String noTelp;
  final String alamat;
  final String bidang;
  final VoidCallback onTap;

  const IndustriTile({
    super.key,
    required this.nama,
    required this.noTelp,
    required this.alamat,
    required this.bidang,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF641E20),
                ),
                child: const Icon(Icons.factory, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _tag(
                          Icons.phone,
                          'Telp: $noTelp',
                          Colors.grey[300]!, 
                          Colors.grey[700]!
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoItem(Icons.format_list_numbered, 'Role', 'Industri'),
              _infoItem(Icons.location_on, 'Alamat', alamat),
              _infoItem(Icons.work, 'Bidang', bidang),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.arrow_forward, color: Color(0xFF641E20)),
              label: const Text(
                'Lihat profil lengkap',
                style: TextStyle(color: Color(0xFF641E20)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(IconData icon, String text, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: iconColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String title, String value) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFB22222)), // UBAH WARNA DI SINI
          const SizedBox(height: 4),
          Text(
            value.isNotEmpty ? value : '-',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}