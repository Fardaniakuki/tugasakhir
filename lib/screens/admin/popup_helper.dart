import 'package:flutter/material.dart';

class PopupHelper {
  static void showSuccessDialog(BuildContext context, String message, {VoidCallback? onOk}) {
    _showDialog(
      context,
      title: 'Berhasil!',
      message: message,
      icon: Icons.check_circle_outline,
      iconColor: Colors.green,
      buttonColor: const Color(0xFF5B1A1A),
      onOk: onOk,
    );
  }

  static void showErrorDialog(BuildContext context, String message, {VoidCallback? onOk}) {
    _showDialog(
      context,
      title: 'Gagal!',
      message: message,
      icon: Icons.error_outline,
      iconColor: Colors.red,
      buttonColor: Colors.red,
      onOk: onOk,
    );
  }

  static void showInfoDialog(BuildContext context, String message, {VoidCallback? onOk}) {
    _showDialog(
      context,
      title: 'Info',
      message: message,
      icon: Icons.info_outline,
      iconColor: Colors.blue,
      buttonColor: Colors.blue,
      onOk: onOk,
    );
  }

  static void _showDialog(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
    required Color buttonColor,
    VoidCallback? onOk,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        titlePadding: const EdgeInsets.only(top: 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 48),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (onOk != null) onOk();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: buttonColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Tutup'),
            ),
          ),
        ],
      ),
    );
  }
}
