import 'package:flutter/material.dart';

class SearchAndFilter extends StatelessWidget {
  final TextEditingController searchController;
  final String selectedStatus;
  final String selectedKelasName;
  final String selectedJurusanName;
  final List<Map<String, String>> kelasList;
  final List<Map<String, String>> jurusanList;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<Map<String, String>?> onKelasChangedMap;
  final ValueChanged<Map<String, String>?> onJurusanChangedMap;
  final bool showClassMajorFilters;

  const SearchAndFilter({super.key, 
    required this.searchController,
    required this.selectedStatus,
    required this.selectedKelasName,
    required this.selectedJurusanName,
    required this.kelasList,
    required this.jurusanList,
    required this.onStatusChanged,
    required this.onKelasChangedMap,
    required this.onJurusanChangedMap,
    required this.showClassMajorFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              icon: Icon(Icons.search),
              hintText: 'Cari berdasarkan nama',
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            DropdownButton<String>(
              value: selectedStatus,
              items: const ['Murid', 'Guru', 'Jurusan', 'Industri', 'Kelas']
                  .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                  .toList(),
              onChanged: onStatusChanged,
            ),

            if (showClassMajorFilters) ...[
              DropdownButton<Map<String, String>>(
                value: kelasList.firstWhere(
                  (e) => e['name'] == selectedKelasName,
                  orElse: () => kelasList.first,
                ),
                items: kelasList
                    .map((item) => DropdownMenuItem<Map<String, String>>(
                          value: item,
                          child: Text(item['name'] ?? ''),
                        ))
                    .toList(),
                onChanged: onKelasChangedMap,
              ),

              DropdownButton<Map<String, String>>(
                value: jurusanList.firstWhere(
                  (e) => e['name'] == selectedJurusanName,
                  orElse: () => jurusanList.first,
                ),
                items: jurusanList
                    .map((item) => DropdownMenuItem<Map<String, String>>(
                          value: item,
                          child: Text(item['name'] ?? ''),
                        ))
                    .toList(),
                onChanged: onJurusanChangedMap,
              ),
            ],
          ],
        ),
      ],
    );
  }
}