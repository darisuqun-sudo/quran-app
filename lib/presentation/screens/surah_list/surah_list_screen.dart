import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/surah_model.dart';
import '../reader/reader_screen.dart';

class SurahListScreen extends ConsumerStatefulWidget {
  const SurahListScreen({super.key});

  @override
  ConsumerState<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends ConsumerState<SurahListScreen> {
  String _searchQuery = '';
  String _filterPlace = 'all'; // 'all', 'makkah', 'madinah'

  @override
  Widget build(BuildContext context) {
    final filteredSurahs = Surah.allSurahs.where((s) {
      final matchesPlace = _filterPlace == 'all' ||
          s.revelationPlace.toLowerCase() == _filterPlace;
      if (!matchesPlace) return false;
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.trim().toLowerCase();
      return s.nameUyghur.contains(q) ||
          s.nameArabic.contains(q) ||
          s.nameSimple.toLowerCase().contains(q) ||
          s.id.toString() == q;
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'سۈرە ئىسمى ياكى رەت نومۇرى بويىچە ئىزدەڭ (مەسىلەن: ياسىن، 36)...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () => setState(() => _searchQuery = ''),
                        icon: const Icon(Icons.clear_rounded),
                      )
                    : null,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildFilterChip('ھەممىسى (114)', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('مەككى (86)', 'makkah'),
                const SizedBox(width: 8),
                _buildFilterChip('مەدىنە (28)', 'madinah'),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              itemCount: filteredSurahs.length,
              itemBuilder: (context, index) {
                final surah = filteredSurahs[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReaderScreen(surah: surah),
                        ),
                      );
                    },
                    leading: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.accentGold.withValues(alpha: 0.6),
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        '${surah.id}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    title: Text(
                      surah.nameUyghur,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      '${surah.revelationPlaceUyghur} • ${surah.versesCount} ئايەت',
                      style: const TextStyle(fontSize: 13),
                    ),
                    trailing: Text(
                      surah.nameArabic,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final selected = _filterPlace == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filterPlace = value),
    );
  }
}
