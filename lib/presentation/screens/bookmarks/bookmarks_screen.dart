import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/ayah_model.dart';
import '../../../data/models/surah_model.dart';
import '../../providers/app_providers.dart';
import '../reader/reader_screen.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final bookmarksList = settings.bookmarks.toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: bookmarksList.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bookmarks_outlined,
                      size: 64,
                      color: AppTheme.accentGold,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'تېخى خەتكۈچكە ساقلانغان ئايەتلەر يوق',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'سۈرە ئوقۇش بېتىدە ھەر بىر ئايەتنىڭ يېنىدىكى خەتكۈچ بەلگىسىنى بېسىپ ساقلىۋالالايسىز.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookmarksList.length,
              itemBuilder: (context, index) {
                final raw = bookmarksList[index];
                final parts = raw.split('|');
                final keyPart = parts.first; // "surahId:verseNumber"
                final keyNums = keyPart.split(':');
                final surahId = int.tryParse(keyNums.first) ?? 1;
                final verseNum =
                    keyNums.length > 1 ? (int.tryParse(keyNums[1]) ?? 1) : 1;

                final surah = Surah.allSurahs.firstWhere(
                  (s) => s.id == surahId,
                  orElse: () => Surah.allSurahs.first,
                );
                final preview = parts.length > 2 ? parts[2] : '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReaderScreen(
                            surah: surah,
                            initialVerse: verseNum,
                          ),
                        ),
                      );
                    },
                    leading: const CircleAvatar(
                      backgroundColor: AppTheme.primaryEmerald,
                      child: Icon(Icons.bookmark_rounded, color: AppTheme.accentGold),
                    ),
                    title: Text(
                      '${surah.nameUyghur} (${surah.nameArabic}) • $verseNum-ئايەت',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: preview.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              preview,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        : null,
                    trailing: IconButton(
                      tooltip: 'ئۆچۈرۈش',
                      onPressed: () {
                        ref.read(appSettingsProvider.notifier).toggleBookmark(
                              surah: surah,
                              ayah: Ayah(
                                id: verseNum,
                                surahNumber: surahId,
                                verseNumber: verseNum,
                                verseKey: '$surahId:$verseNum',
                                textUthmani: '',
                                uyghurTranslation: preview,
                              ),
                            );
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
