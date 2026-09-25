import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../providers/app_providers.dart';

class AudioPlayerBar extends ConsumerWidget {
  const AudioPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioControllerProvider);
    final settings = ref.watch(appSettingsProvider);

    if (audioState.currentSurah == null ||
        audioState.currentVerseNumber == null) {
      return const SizedBox.shrink();
    }

    final surah = audioState.currentSurah!;
    final verseNum = audioState.currentVerseNumber!;
    final notifier = ref.read(audioControllerProvider.notifier);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.deepEmerald, AppTheme.primaryEmerald],
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppTheme.accentGold.withValues(alpha: 0.55),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.accentGold, width: 1),
              ),
              child: const Icon(
                Icons.graphic_eq_rounded,
                color: AppTheme.accentGold,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${surah.nameUyghur} (${surah.nameArabic}) • $verseNum-ئايەت',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'قارىئى: ${settings.selectedReciter.nameUyghur}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'ئالدىنقى ئايەت',
              visualDensity: VisualDensity.compact,
              onPressed: notifier.playPrevious,
              icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
            ),
            Container(
              decoration: const BoxDecoration(
                color: AppTheme.accentGold,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                tooltip: audioState.isPlaying ? 'توختىتىش' : 'داۋاملاشتۇرۇش',
                visualDensity: VisualDensity.compact,
                onPressed: notifier.togglePlayPause,
                icon: audioState.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppTheme.deepEmerald,
                        ),
                      )
                    : Icon(
                        audioState.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: AppTheme.deepEmerald,
                      ),
              ),
            ),
            IconButton(
              tooltip: 'كېيىنكى ئايەت',
              visualDensity: VisualDensity.compact,
              onPressed: notifier.playNext,
              icon: const Icon(Icons.skip_previous_rounded, color: Colors.white),
            ),
            IconButton(
              tooltip: audioState.repeatCurrentAyah
                  ? 'يەككە ئايەتنى تەكرارلاش ھالىتى (چەكسىڭىز ئۈزلۈكسىز پۈتۈن سۈرىگە ئۆتىدۇ)'
                  : 'ئۈزلۈكسىز سۈرە ئوقۇش ھالىتى (چەكسىڭىز بىرلا ئايەتنى تەكرارلايدۇ)',
              visualDensity: VisualDensity.compact,
              onPressed: notifier.toggleRepeatAyah,
              icon: Icon(
                audioState.repeatCurrentAyah
                    ? Icons.repeat_one_rounded
                    : Icons.repeat_rounded,
                color: audioState.repeatCurrentAyah
                    ? AppTheme.accentGold
                    : Colors.white,
              ),
            ),
            InkWell(
              onTap: notifier.cycleSpeed,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  '${audioState.playbackSpeed}x',
                  style: const TextStyle(
                    color: AppTheme.accentGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'پىلاگىرنى تاقاش',
              visualDensity: VisualDensity.compact,
              onPressed: notifier.stop,
              icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
