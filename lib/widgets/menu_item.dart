import 'package:flutter/material.dart';

class MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const MenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Ambil warna teks default dari tema
    final titleColor = Theme.of(context).textTheme.titleMedium?.color ?? const Color.fromARGB(255, 255, 255, 255);
    final subtitleColor = Theme.of(context).textTheme.bodySmall?.color ?? const Color.fromARGB(137, 255, 255, 255);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF641E20),
          child: Icon(icon, color: const Color(0xFF641E20)),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: titleColor, // otomatis menyesuaikan tema
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: subtitleColor, // otomatis menyesuaikan tema
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
