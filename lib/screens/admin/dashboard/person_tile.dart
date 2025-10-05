import 'package:flutter/material.dart';

class PersonTile extends StatelessWidget {
  final String name;
  final String role;
  final String? jurusan;
  final String? kelas;
  final VoidCallback onTap;

  const PersonTile({super.key, 
    required this.name,
    required this.role,
    this.jurusan,
    this.kelas,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String subtitle = role;
    if (role == 'Murid' && jurusan != null && kelas != null && jurusan!.isNotEmpty && kelas!.isNotEmpty) {
      final String kelasRomawi = switch (kelas) {
        '10' => 'X',
        '11' => 'XI',
        '12' => 'XII',
        _ => kelas!,
      };
      subtitle = 'Kelas $kelasRomawi $jurusan';
    }

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: _getColorByRole(role),
        child: Icon(_getIconByRole(role), color: Colors.white),
      ),
      title: Text(name),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
    );
  }

  Color _getColorByRole(String role) {
    switch (role) {
      case 'Murid':
        return Colors.blue;
      case 'Guru':
        return Colors.purple;
      case 'Jurusan':
        return Colors.green;
      case 'Industri':
        return Colors.orange;
      case 'Kelas':
        return Colors.teal;
      default:
        return Colors.brown;
    }
  }

  IconData _getIconByRole(String role) {
    switch (role) {
      case 'Murid':
        return Icons.person;
      case 'Guru':
        return Icons.school;
      case 'Jurusan':
        return Icons.architecture;
      case 'Industri':
        return Icons.factory;
      case 'Kelas':
        return Icons.class_;
      default:
        return Icons.person;
    }
  }
}