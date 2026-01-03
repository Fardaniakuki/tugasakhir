import 'package:flutter/material.dart';

class RoleSelectionDialog extends StatelessWidget {
  final Map<String, dynamic> userData; // Data user dari API
  final String userName;
  final Function(String) onRoleSelected;

  const RoleSelectionDialog({
    super.key,
    required this.userData,
    required this.userName,
    required this.onRoleSelected,
  });

  // Warna utama - sama untuk semua role
  final Color primaryColor = const Color(0xFF3B060A); // Maroon tua

  // Mendapatkan list role yang tersedia dari userData
  List<String> get rolesAvailable {
    final List<String> roles = [];
    
    if (userData['is_koordinator'] == true) roles.add('Koordinator');
    if (userData['is_pembimbing'] == true) roles.add('Pembimbing');
    if (userData['is_wali_kelas'] == true) roles.add('Wali Kelas');
    if (userData['is_kaprog'] == true) roles.add('Kaprog');
    // Tidak ada role "Guru" sebagai default
    
    return roles;
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'Koordinator':
        return Icons.manage_accounts_rounded;
      case 'Pembimbing':
        return Icons.supervisor_account_rounded;
      case 'Wali Kelas':
        return Icons.class_rounded;
      case 'Kaprog':
        return Icons.engineering_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  String _getRoleDescription(String role) {
    switch (role) {
      case 'Koordinator':
        return 'Koordinasi program sekolah';
      case 'Pembimbing':
        return 'Bimbingan siswa PKL';
      case 'Wali Kelas':
        return 'Kelola kelas dan absensi';
      case 'Kaprog':
        return 'Manajemen program keahlian';
      default:
        return 'Akses umum';
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableRoles = rolesAvailable;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header yang minimalis
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 24,
                bottom: 20,
                left: 24,
                right: 24,
              ),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar minimal - PUTIH
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      size: 28,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Nama user
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // Subtitle - tampilkan jumlah role
                  Text(
                    '${availableRoles.length} peran tersedia',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Role Selection List
            Padding(
              padding: const EdgeInsets.all(20),
              child: availableRoles.isEmpty 
                ? _buildNoRolesAvailable()
                : Column(
                    children: availableRoles.map((role) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              onRoleSelected(role);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey[200]!,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Icon dengan background MAROON SAMA SEMUA
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _getRoleIcon(role),
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  
                                  // Role Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          role,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: primaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          _getRoleDescription(role),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Chevron Icon - warna maroon sama
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 20,
                                    color: primaryColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
            ),
            
            // Footer dengan tombol tutup
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  // Info kecil di atas tombol
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.grey[200]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Peran dapat diganti melalui menu profil',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Tombol tutup
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: Colors.grey[100],
                      ),
                      child: Text(
                        'Tutup',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: primaryColor,
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
  }

  Widget _buildNoRolesAvailable() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 50,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada peran tersedia',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hubungi admin untuk mendapatkan akses',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}