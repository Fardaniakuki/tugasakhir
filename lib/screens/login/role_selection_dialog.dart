import 'package:flutter/material.dart';

class RoleSelectionDialog extends StatelessWidget {
  final Map<String, dynamic> userData;
  final String userName;
  final Function(String) onRoleSelected;

  RoleSelectionDialog({
    super.key,
    required this.userData,
    required this.userName,
    required this.onRoleSelected,
  });

  final Color primaryColor = const Color(0xFF3B060A);

  // PERBAIKAN: Sederhanakan mapping
  final Map<String, Map<String, dynamic>> roleConfig = {
    'koordinator': {
      'key': 'koordinator',
      'display': 'Koordinator',
      'icon': Icons.manage_accounts_rounded,
      'desc': 'Koordinasi program sekolah',
    },
    'pembimbing': {
      'key': 'pembimbing',
      'display': 'Pembimbing',
      'icon': Icons.supervisor_account_rounded,
      'desc': 'Bimbingan siswa PKL',
    },
    'wali_kelas': {
      'key': 'wali_kelas',
      'display': 'Wali Kelas',
      'icon': Icons.class_rounded,
      'desc': 'Kelola kelas dan absensi',
    },
    'kaprog': {
      'key': 'kaprog',
      'display': 'Kepala Konsentrasi',
      'icon': Icons.engineering_rounded,
      'desc': 'Manajemen konsentrasi keahlian',
    },
  };

  List<Map<String, dynamic>> get rolesAvailable {
    final List<Map<String, dynamic>> roles = [];

    if (userData['is_koordinator'] == true) {
      roles.add(roleConfig['koordinator']!);
    }

    if (userData['is_pembimbing'] == true) {
      roles.add(roleConfig['pembimbing']!);
    }

    if (userData['is_wali_kelas'] == true) {
      roles.add(roleConfig['wali_kelas']!);
    }

    if (userData['is_kaprog'] == true) {
      roles.add(roleConfig['kaprog']!);
    }

    return roles;
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
              color: Colors.black.withValues(alpha:0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
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
                  // Avatar
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha:0.1),
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

                  // Subtitle
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
                      children: availableRoles.map((roleData) {
                        final roleKey = roleData['key'] as String;
                        final displayName = roleData['display'] as String;
                        final iconData = roleData['icon'] as IconData;
                        final description = roleData['desc'] as String;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                // DEBUG: Tampilkan log
                                print('[LOGIN DEBUG] Role selected: $roleKey');
                                print(
                                    '[LOGIN DEBUG] Display name: $displayName');

                                // Tutup dialog terlebih dahulu
                                Navigator.pop(context);

                                // Beri sedikit delay untuk UI stabil
                                Future.delayed(
                                    const Duration(milliseconds: 100), () {
                                  // Kirim role key yang dipilih
                                  onRoleSelected(roleKey);
                                });
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
                                      color: Colors.black.withValues(alpha:0.03),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Icon
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        iconData,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    // Role Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            displayName,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: primaryColor,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            description,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Chevron Icon
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

            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  // Info
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
