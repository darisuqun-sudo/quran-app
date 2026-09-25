import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/ayah_model.dart';
import '../../../data/models/surah_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/audio_player_bar.dart';

final mushafPageAyahsProvider =
    FutureProvider.family<List<({Surah surah, Ayah ayah})>, int>(
        (ref, pageNumber) async {
  final repo = ref.watch(quranRepositoryProvider);
  return repo.getPageVerses(pageNumber);
});

enum MushafViewMode {
  mushafOnly, // Full Illuminated Sacred Mushaf Page
  mushafWithTranslation, // Mushaf Page + Translation Text Below
  cards, // Ayah-by-Ayah Luxury Cards
}

class MushafPagesScreen extends ConsumerStatefulWidget {
  final int initialPage;

  const MushafPagesScreen({
    super.key,
    this.initialPage = 1,
  });

  @override
  ConsumerState<MushafPagesScreen> createState() => _MushafPagesScreenState();
}

class _MushafPagesScreenState extends ConsumerState<MushafPagesScreen> {
  late int _currentPage;
  MushafViewMode _viewMode = MushafViewMode.mushafWithTranslation;
  final TextEditingController _jumpPageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.clamp(1, 604);
  }

  @override
  void dispose() {
    _jumpPageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= 604) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  void _showJumpDialog(BuildContext context) {
    _jumpPageController.text = _currentPage.toString();
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: const BorderSide(color: AppTheme.accentGold, width: 1.5),
            ),
            title: const Row(
              children: [
                Icon(Icons.explore_rounded, color: AppTheme.accentGold),
                SizedBox(width: 8),
                Text(
                  'بەت ياكى سۈرىگە سەكرەش',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '1-بەتلەردىن 604-بەتكىچە بولغان نومۇرنى كىرگۈزۈڭ:',
                    style: TextStyle(fontSize: 13.5),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _jumpPageController,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'مەسىلەن: 1, 100, 604',
                      prefixIcon: const Icon(Icons.menu_book_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onSubmitted: (val) {
                      final p = int.tryParse(val);
                      if (p != null && p >= 1 && p <= 604) {
                        _goToPage(p);
                        Navigator.pop(dialogCtx);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'ياكى بىر سۈرىنى تاللاڭ:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentGold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.accentGold.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListView.builder(
                      itemCount: Surah.allSurahs.length,
                      itemBuilder: (context, idx) {
                        final s = Surah.allSurahs[idx];
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor:
                                AppTheme.accentGold.withValues(alpha: 0.2),
                            child: Text(
                              '${s.id}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentGold,
                              ),
                            ),
                          ),
                          title: Text(
                            '${s.nameUyghur} (${s.nameArabic})',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                          ),
                          onTap: () async {
                            Navigator.pop(dialogCtx);
                            final ayahs = await ref
                                .read(quranRepositoryProvider)
                                .getSurahAyahs(s.id);
                            if (ayahs.isNotEmpty) {
                              _goToPage(ayahs.first.pageNumber);
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('بىكار قىلىش'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accentGold,
                  foregroundColor: AppTheme.deepEmerald,
                ),
                onPressed: () {
                  final p = int.tryParse(_jumpPageController.text);
                  if (p != null && p >= 1 && p <= 604) {
                    _goToPage(p);
                    Navigator.pop(dialogCtx);
                  }
                },
                child: const Text(
                  'كۆچۈش',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFontSettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Consumer(
          builder: (context, ref, _) {
            final settings = ref.watch(appSettingsProvider);
            final notifier = ref.read(appSettingsProvider.notifier);

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.format_size_rounded,
                          color: AppTheme.accentGold),
                      SizedBox(width: 8),
                      Text(
                        'خەت چوڭلۇقى ۋە كۆرۈنۈش تەڭشىكى',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'ئەرەبچە خەت چوڭلۇقى: ${settings.arabicFontSize.toInt()} px',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: settings.arabicFontSize,
                    min: 18,
                    max: 42,
                    divisions: 12,
                    label: '${settings.arabicFontSize.toInt()}',
                    onChanged: (val) => notifier.setArabicFontSize(val),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ئۇيغۇرچە تەرجىمە خەت چوڭلۇقى: ${settings.uyghurFontSize.toInt()} px',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: settings.uyghurFontSize,
                    min: 12,
                    max: 28,
                    divisions: 8,
                    label: '${settings.uyghurFontSize.toInt()}',
                    onChanged: (val) => notifier.setUyghurFontSize(val),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageAsync = ref.watch(mushafPageAyahsProvider(_currentPage));
    final settings = ref.watch(appSettingsProvider);
    final audioState = ref.watch(audioControllerProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '$_currentPage-بەت • قۇرئان كەرىم (604 بەت)',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              tooltip: 'سەكرەش (بەت ياكى سۈرە)',
              onPressed: () => _showJumpDialog(context),
              icon: const Icon(Icons.search_rounded),
            ),
            IconButton(
              tooltip: 'خەت چوڭلۇقى',
              onPressed: () => _showFontSettingsModal(context),
              icon: const Icon(Icons.text_fields_rounded),
            ),
          ],
        ),
        bottomNavigationBar: const AudioPlayerBar(),
        body: Column(
          children: [
            // Modern Top Tool Strip (View Mode Toggles & Page Details)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.accentGold.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Page & Juz Badges
                  pageAsync.maybeWhen(
                    data: (items) {
                      final juz = items.isNotEmpty
                          ? items.first.ayah.juzNumber
                          : ((_currentPage - 1) ~/ 20 + 1);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.accentGold.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Text(
                          '$juz-پارە • $_currentPage-بەت',
                          style: const TextStyle(
                            color: AppTheme.accentGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                      );
                    },
                    orElse: () => Text(
                      '$_currentPage-بەت',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  // View Mode Segmented Controls
                  SegmentedButton<MushafViewMode>(
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: AppTheme.accentGold,
                      selectedForegroundColor: AppTheme.deepEmerald,
                      visualDensity: VisualDensity.compact,
                    ),
                    segments: const [
                      ButtonSegment(
                        value: MushafViewMode.mushafOnly,
                        icon: Icon(Icons.menu_book_rounded, size: 16),
                        label: Text('مۇسھەف', style: TextStyle(fontSize: 12)),
                      ),
                      ButtonSegment(
                        value: MushafViewMode.mushafWithTranslation,
                        icon: Icon(Icons.auto_stories_rounded, size: 16),
                        label: Text('قوشۇلما', style: TextStyle(fontSize: 12)),
                      ),
                      ButtonSegment(
                        value: MushafViewMode.cards,
                        icon: Icon(Icons.view_agenda_rounded, size: 16),
                        label: Text('كارتىلار', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                    selected: {_viewMode},
                    onSelectionChanged: (set) {
                      setState(() {
                        _viewMode = set.first;
                      });
                    },
                  ),
                ],
              ),
            ),

            // Page Content Area
            Expanded(
              child: pageAsync.when(
                loading: () => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('مۇسھەف بېتى يۈكلىنىۋاتىدۇ...'),
                    ],
                  ),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('خاتالىق كۆرۈلدى: $e'),
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return Center(
                      child: Text('$_currentPage-بەتتە ئايەت تېپىلمىدى.'),
                    );
                  }

                  switch (_viewMode) {
                    case MushafViewMode.cards:
                      return _buildCardsView(
                          context, items, settings, audioState);
                    case MushafViewMode.mushafOnly:
                      return _buildMushafOnlyView(
                          context, items, settings, audioState);
                    case MushafViewMode.mushafWithTranslation:
                      return _buildUnifiedView(
                          context, items, settings, audioState);
                  }
                },
              ),
            ),

            // Modern Bottom Page Slider & Next/Previous Navigator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                border: Border(
                  top: BorderSide(
                    color: AppTheme.accentGold.withValues(alpha: 0.35),
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: AppTheme.accentGold.withValues(alpha: 0.6),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        onPressed: _currentPage > 1
                            ? () => _goToPage(_currentPage - 1)
                            : null,
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 14),
                        label: const Text(
                          'ئالدىنقى بەت',
                          style: TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppTheme.accentGold,
                            thumbColor: AppTheme.accentGold,
                            overlayColor:
                                AppTheme.accentGold.withValues(alpha: 0.2),
                            trackHeight: 3,
                          ),
                          child: Slider(
                            value: _currentPage.toDouble(),
                            min: 1,
                            max: 604,
                            divisions: 603,
                            label: '$_currentPage-بەت',
                            onChanged: (val) {
                              setState(() {
                                _currentPage = val.round();
                              });
                            },
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.accentGold,
                          foregroundColor: AppTheme.deepEmerald,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        onPressed: _currentPage < 604
                            ? () => _goToPage(_currentPage + 1)
                            : null,
                        icon: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 14),
                        label: const Text(
                          'كېيىنكى بەت',
                          style: TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 1. Authentic Illuminated Sacred Mushaf Page View
  Widget _buildMushafOnlyView(
    BuildContext context,
    List<({Surah surah, Ayah ayah})> items,
    AppSettingsState settings,
    AudioPlaybackState audioState,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: _buildIlluminatedMushafCard(
            context,
            items,
            settings,
            audioState,
            showTranslation: false,
          ),
        ),
      ),
    );
  }

  /// 2. Unified Mushaf Page + Full Translation
  Widget _buildUnifiedView(
    BuildContext context,
    List<({Surah surah, Ayah ayah})> items,
    AppSettingsState settings,
    AudioPlaybackState audioState,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sacred Mushaf Page Card
              _buildIlluminatedMushafCard(
                context,
                items,
                settings,
                audioState,
                showTranslation: false,
              ),
              const SizedBox(height: 18),
              // Uyghur Muhammad Saleh Translation Block
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.accentGold.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.translate_rounded,
                                color: AppTheme.accentGold, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'ئۇيغۇرچە تەرجىمىسى (مۇھەممەد سالىھ):',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentGold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () {
                            final first = items.first;
                            ref.read(audioControllerProvider.notifier).playAyah(
                                  surah: first.surah,
                                  verseNumber: first.ayah.verseNumber,
                                  playlist: items.map((i) => i.ayah).toList(),
                                );
                          },
                          icon: const Icon(Icons.volume_up_rounded, size: 16),
                          label: const Text('بۇ بەتنى ئاڭلاش'),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(),
                    ),
                    ...items.map((item) {
                      final isPlaying =
                          audioState.currentSurah?.id == item.surah.id &&
                              audioState.currentVerseNumber ==
                                  item.ayah.verseNumber;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isPlaying
                              ? AppTheme.accentGold.withValues(alpha: 0.12)
                              : null,
                          borderRadius: BorderRadius.circular(12),
                          border: isPlaying
                              ? Border.all(
                                  color: AppTheme.accentGold
                                      .withValues(alpha: 0.7),
                                )
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentGold
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${item.surah.nameUyghur} • ${item.ayah.verseNumber}-ئايەت',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.accentGold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  tooltip: 'بۇ ئايەتنى ئاڭلاش',
                                  onPressed: () {
                                    ref
                                        .read(audioControllerProvider.notifier)
                                        .playAyah(
                                          surah: item.surah,
                                          verseNumber: item.ayah.verseNumber,
                                          playlist:
                                              items.map((i) => i.ayah).toList(),
                                        );
                                  },
                                  icon: Icon(
                                    isPlaying && audioState.isPlaying
                                        ? Icons.pause_circle_filled_rounded
                                        : Icons.play_circle_fill_rounded,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 20,
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  tooltip: 'كۆچۈرۈۋېلىش',
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(
                                        text:
                                            '${item.ayah.textUthmani}\n[${item.surah.nameUyghur} ${item.ayah.verseNumber}-ئايەت]: ${item.ayah.uyghurTranslation}',
                                      ),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('ئايەت كۆچۈرۈۋېلىندى!'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.copy_rounded,
                                      size: 16, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SelectableText(
                              item.ayah.uyghurTranslation,
                              style: TextStyle(
                                fontSize: settings.uyghurFontSize,
                                height: 1.75,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 3. Luxury Ayah-by-Ayah Cards View
  Widget _buildCardsView(
    BuildContext context,
    List<({Surah surah, Ayah ayah})> items,
    AppSettingsState settings,
    AudioPlaybackState audioState,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, idx) {
        final item = items[idx];
        final isPlaying = audioState.currentSurah?.id == item.surah.id &&
            audioState.currentVerseNumber == item.ayah.verseNumber;
        final isBookmarked =
            settings.isBookmarked(item.surah.id, item.ayah.verseNumber);

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: isPlaying
                  ? AppTheme.accentGold
                  : AppTheme.accentGold.withValues(alpha: 0.3),
              width: isPlaying ? 2 : 1.2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${item.surah.nameUyghur} (${item.surah.nameArabic}) • ${item.ayah.verseNumber}-ئايەت',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentGold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'ئاڭلاش',
                          onPressed: () {
                            ref.read(audioControllerProvider.notifier).playAyah(
                                  surah: item.surah,
                                  verseNumber: item.ayah.verseNumber,
                                  playlist: items.map((i) => i.ayah).toList(),
                                );
                          },
                          icon: Icon(
                            isPlaying && audioState.isPlaying
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_fill_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 26,
                          ),
                        ),
                        IconButton(
                          tooltip: isBookmarked ? 'خەتكۈچتىن ئۆچۈرۈش' : 'خەتكۈچ',
                          onPressed: () {
                            ref
                                .read(appSettingsProvider.notifier)
                                .toggleBookmark(
                                  surah: item.surah,
                                  ayah: item.ayah,
                                );
                          },
                          icon: Icon(
                            isBookmarked
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            color: AppTheme.accentGold,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Arabic Uthmani Text
                SelectableText(
                  item.ayah.textUthmani,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'NotoNaskhArabic',
                    fontSize: settings.arabicFontSize + 2,
                    height: 2.1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(),
                ),
                // Uyghur Translation Text
                SelectableText(
                  item.ayah.uyghurTranslation,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: settings.uyghurFontSize,
                    height: 1.75,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Master Illuminated Holy Quran Mushaf Page Card
  Widget _buildIlluminatedMushafCard(
    BuildContext context,
    List<({Surah surah, Ayah ayah})> items,
    AppSettingsState settings,
    AudioPlaybackState audioState, {
    required bool showTranslation,
  }) {
    // Detect all unique surahs on this page
    final uniqueSurahs = <int, Surah>{};
    for (final i in items) {
      uniqueSurahs[i.surah.id] = i.surah;
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.accentGold,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentGold.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.accentGold.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ornate Page Header Bar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.deepEmerald, AppTheme.primaryEmerald],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.accentGold.withValues(alpha: 0.8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      uniqueSurahs.values.map((s) => s.nameArabic).join(' • '),
                      style: const TextStyle(
                        color: AppTheme.accentGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${items.first.ayah.juzNumber}-جُزْء',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Surah Header Banners if any surah starts on this page
              ...uniqueSurahs.values.expand((surah) {
                final isStartOfSurah = items.any(
                    (i) => i.surah.id == surah.id && i.ayah.verseNumber == 1);
                if (!isStartOfSurah) return <Widget>[];

                return [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF144D37),
                          Color(0xFF0A261B),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.accentGold,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'سُورَةُ ${surah.nameArabic}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${surah.revelationPlaceUyghur} • ${surah.versesCount} ئايەت',
                          style: const TextStyle(
                            color: AppTheme.accentGold,
                            fontSize: 12,
                          ),
                        ),
                        if (surah.bismillahPre) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ];
              }),

              // Mushaf Page Uthmani Arabic Text
              SelectableText.rich(
                TextSpan(
                  style: TextStyle(
                    fontFamily: 'NotoNaskhArabic',
                    fontSize: settings.arabicFontSize + 2,
                    height: 2.25,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  children: items.map((item) {
                    final isPlaying =
                        audioState.currentSurah?.id == item.surah.id &&
                            audioState.currentVerseNumber ==
                                item.ayah.verseNumber;

                    return TextSpan(
                      text:
                          '${item.ayah.textUthmani} ﴿${item.ayah.verseNumber}﴾  ',
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          ref.read(audioControllerProvider.notifier).playAyah(
                                surah: item.surah,
                                verseNumber: item.ayah.verseNumber,
                                playlist: items.map((i) => i.ayah).toList(),
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
                textAlign: TextAlign.justify,
                textDirection: TextDirection.rtl,
              ),

              const SizedBox(height: 20),
              // Ornate Golden Page Number Footer
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.accentGold.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '— $_currentPage —',
                    style: const TextStyle(
                      color: AppTheme.accentGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
