import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/ayah_model.dart';
import '../../../data/models/reciter_model.dart';
import '../../../data/models/surah_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/audio_player_bar.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final Surah surah;
  final int initialVerse;

  const ReaderScreen({
    super.key,
    required this.surah,
    this.initialVerse = 1,
  });

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late Surah _currentSurah;
  bool _isMushafMode = false; // false = ئايەت-ئايەت, true = مۇسھەف بېتى

  @override
  void initState() {
    super.initState();
    _currentSurah = widget.surah;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(appSettingsProvider.notifier)
          .saveLastRead(_currentSurah.id, widget.initialVerse);
    });
  }

  void _switchSurah(int newSurahId) {
    final next = Surah.allSurahs.firstWhere(
      (s) => s.id == newSurahId,
      orElse: () => _currentSurah,
    );
    setState(() {
      _currentSurah = next;
    });
    ref.read(appSettingsProvider.notifier).saveLastRead(next.id, 1);
  }

  void _showFontSettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final settings = ref.watch(appSettingsProvider);
            final notifier = ref.read(appSettingsProvider.notifier);
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ئوقۇش ۋە قارىئى تەڭشەكلىرى',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const Divider(),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('ئۇيغۇرچە تەرجىمىسىنى كۆرسىتىش'),
                      value: settings.showTranslation,
                      onChanged: notifier.toggleShowTranslation,
                    ),
                    const SizedBox(height: 6),
                    Text('ئەرەبچە قۇرئان خەت چوڭلۇقى: ${settings.arabicFontSize.toInt()}'),
                    Slider(
                      value: settings.arabicFontSize,
                      min: 20,
                      max: 44,
                      divisions: 12,
                      onChanged: notifier.setArabicFontSize,
                    ),
                    Text('ئۇيغۇرچە تەرجىمە خەت چوڭلۇقى: ${settings.uyghurFontSize.toInt()}'),
                    Slider(
                      value: settings.uyghurFontSize,
                      min: 13,
                      max: 26,
                      divisions: 13,
                      onChanged: notifier.setUyghurFontSize,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'قارىئى تاللاش:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: Reciter.defaultReciters.map((r) {
                        final selected = r.id == settings.selectedReciter.id;
                        return ChoiceChip(
                          label: Text(r.nameUyghur),
                          selected: selected,
                          onSelected: (_) => notifier.setReciter(r),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ayahsAsync = ref.watch(surahAyahsProvider(_currentSurah.id));
    final settings = ref.watch(appSettingsProvider);
    final audioState = ref.watch(audioControllerProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            children: [
              Text(
                '${_currentSurah.id}. ${_currentSurah.nameUyghur}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_currentSurah.nameArabic} • ${_currentSurah.revelationPlaceUyghur} • ${_currentSurah.versesCount} ئايەت',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: _isMushafMode ? 'ئايەت-ئايەت ھالىتى' : 'مۇسھەف بەت ھالىتى',
              onPressed: () {
                setState(() {
                  _isMushafMode = !_isMushafMode;
                });
              },
              icon: Icon(
                _isMushafMode
                    ? Icons.view_agenda_rounded
                    : Icons.auto_stories_rounded,
              ),
            ),
            IconButton(
              tooltip: 'خەت چوڭلۇقى ۋە تەڭشەكلەر',
              onPressed: () => _showFontSettingsModal(context),
              icon: const Icon(Icons.text_fields_rounded),
            ),
          ],
        ),
        bottomNavigationBar: const AudioPlayerBar(),
        body: ayahsAsync.when(
          loading: () => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('سۈرە ۋە ئۇيغۇرچە تەرجىمىسى يۈكلىنىۋاتىدۇ...'),
              ],
            ),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off_rounded, size: 54, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  Text(
                    err.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => ref.invalidate(surahAyahsProvider(_currentSurah.id)),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('قايتا يۈكلەش'),
                  ),
                ],
              ),
            ),
          ),
          data: (ayahs) {
            return Column(
              children: [
                Expanded(
                  child: _isMushafMode
                      ? _buildMushafView(context, ayahs, settings, audioState)
                      : _buildVerseByVerseView(context, ayahs, settings, audioState),
                ),
                _buildSurahBottomNav(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSurahHeaderBanner(List<Ayah> ayahs, AudioPlaybackState audioState) {
    final isPlayingThisSurah =
        audioState.currentSurah?.id == _currentSurah.id && audioState.isPlaying;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.deepEmerald, AppTheme.primaryEmerald],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.5)),
                ),
                child: Text(
                  '${_currentSurah.revelationPlaceUyghur} • ${_currentSurah.versesCount} ئايەت',
                  style: const TextStyle(color: AppTheme.accentGold, fontSize: 12.5),
                ),
              ),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accentGold,
                  foregroundColor: AppTheme.deepEmerald,
                ),
                onPressed: () {
                  final audioNotifier = ref.read(audioControllerProvider.notifier);
                  if (isPlayingThisSurah) {
                    audioNotifier.togglePlayPause();
                  } else if (ayahs.isNotEmpty) {
                    audioNotifier.playAyah(
                      surah: _currentSurah,
                      verseNumber: 1,
                      playlist: ayahs,
                    );
                  }
                },
                icon: Icon(
                  isPlayingThisSurah ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
                label: Text(
                  isPlayingThisSurah ? 'تىلاۋەتنى توختىتىش' : 'پۈتۈن سۈرىنى ئاڭلاش',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'سُورَةُ ${_currentSurah.nameArabic}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _currentSurah.nameUyghur,
            style: const TextStyle(
              color: AppTheme.accentGold,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_currentSurah.bismillahPre) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: Colors.white24),
            ),
            const Text(
              'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ناھايتى شەپقەتلىك ۋە مېھرىبان ئاللاھنىڭ ئىسمى بىلەن باشلايمەن',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVerseByVerseView(
    BuildContext context,
    List<Ayah> ayahs,
    AppSettingsState settings,
    AudioPlaybackState audioState,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: ayahs.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildSurahHeaderBanner(ayahs, audioState);
        }

        final ayah = ayahs[index - 1];
        final isPlayingThisAyah =
            audioState.currentSurah?.id == _currentSurah.id &&
            audioState.currentVerseNumber == ayah.verseNumber;
        final isBookmarked =
            settings.isBookmarked(_currentSurah.id, ayah.verseNumber);

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          color: isPlayingThisAyah
              ? AppTheme.accentGold.withValues(alpha: 0.14)
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isPlayingThisAyah
                  ? AppTheme.accentGold
                  : AppTheme.accentGold.withValues(alpha: 0.25),
              width: isPlayingThisAyah ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top action bar for each verse
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentSurah.id}:${ayah.verseNumber} • پارە ${ayah.juzNumber}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'ئايەتنى ئاڭلاش',
                      onPressed: () {
                        ref.read(audioControllerProvider.notifier).playAyah(
                              surah: _currentSurah,
                              verseNumber: ayah.verseNumber,
                              playlist: ayahs,
                            );
                      },
                      icon: Icon(
                        isPlayingThisAyah && audioState.isPlaying
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_fill_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                    ),
                    IconButton(
                      tooltip: isBookmarked ? 'خەتكۈچتىن چىقىرىش' : 'خەتكۈچكە ساقلاش',
                      onPressed: () {
                        ref.read(appSettingsProvider.notifier).toggleBookmark(
                              surah: _currentSurah,
                              ayah: ayah,
                            );
                      },
                      icon: Icon(
                        isBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: isBookmarked ? AppTheme.accentGold : null,
                      ),
                    ),
                    IconButton(
                      tooltip: 'ئايەت ۋە تەرجىمىسىنى كۆچۈرۈش',
                      onPressed: () {
                        final copyText =
                            '${ayah.textUthmani}\n\n${ayah.uyghurTranslation}\n— [${_currentSurah.nameUyghur}، ${ayah.verseNumber}-ئايەت]';
                        Clipboard.setData(ClipboardData(text: copyText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('ئايەت ۋە ئۇيغۇرچە تەرجىمىسى كۆچۈرۈلدى!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Uthmani Arabic Text
                SelectableText(
                  '${ayah.textUthmani} ﴿${ayah.verseNumber}﴾',
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: settings.arabicFontSize,
                    height: 2.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (settings.showTranslation &&
                    ayah.uyghurTranslation.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1),
                  ),
                  SelectableText(
                    ayah.uyghurTranslation,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: settings.uyghurFontSize,
                      height: 1.75,
                      color: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.color
                          ?.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMushafView(
    BuildContext context,
    List<Ayah> ayahs,
    AppSettingsState settings,
    AudioPlaybackState audioState,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSurahHeaderBanner(ayahs, audioState),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppTheme.accentGold, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RichText(
                  textAlign: TextAlign.justify,
                  textDirection: TextDirection.rtl,
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily: 'NotoNaskhArabic',
                      fontSize: settings.arabicFontSize + 2,
                      height: 2.25,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    children: ayahs.map((ayah) {
                      final isPlaying =
                          audioState.currentSurah?.id == _currentSurah.id &&
                          audioState.currentVerseNumber == ayah.verseNumber;
                      return TextSpan(
                        text: '${ayah.textUthmani} ﴿${ayah.verseNumber}﴾  ',
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            ref
                                .read(audioControllerProvider.notifier)
                                .playAyah(
                                  surah: _currentSurah,
                                  verseNumber: ayah.verseNumber,
                                  playlist: ayahs,
                                );
                          },
                        style: TextStyle(
                          backgroundColor: isPlaying
                              ? AppTheme.accentGold.withValues(alpha: 0.35)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (settings.showTranslation) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(),
                  ),
                  const Text(
                    'ئۇيغۇرچە تەرجىمىسى (مۇھەممەد سالىھ):',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentGold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...ayahs.map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '(${a.verseNumber}) ${a.uyghurTranslation}',
                        style: TextStyle(
                          fontSize: settings.uyghurFontSize,
                          height: 1.7,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSurahBottomNav(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: Border(
          top: BorderSide(color: AppTheme.accentGold.withValues(alpha: 0.25)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            onPressed: _currentSurah.id > 1
                ? () => _switchSurah(_currentSurah.id - 1)
                : null,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
            label: const Text('ئالدىنقى سۈرە'),
          ),
          Text(
            'سۈرە ${_currentSurah.id} / 114',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          FilledButton.icon(
            onPressed: _currentSurah.id < 114
                ? () => _switchSurah(_currentSurah.id + 1)
                : null,
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            label: const Text('كېيىنكى سۈرە'),
          ),
        ],
      ),
    );
  }
}
