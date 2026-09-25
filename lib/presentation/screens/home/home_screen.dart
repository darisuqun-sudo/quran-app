import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/surah_model.dart';
import '../../providers/app_providers.dart';
import '../admin/admin_dashboard_screen.dart';
import '../pdf_book/mushaf_pages_screen.dart';
import '../reader/reader_screen.dart';
import '../search/search_screen.dart';

class DashboardHomeScreen extends ConsumerWidget {
  final ValueChanged<int> onNavigateTab;

  const DashboardHomeScreen({
    super.key,
    required this.onNavigateTab,
  });

  static const List<int> _featuredSurahIds = [1, 36, 18, 67, 55, 56, 112, 114];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final prayerAsync = ref.watch(prayerTimesProvider);

    final lastSurah = Surah.allSurahs.firstWhere(
      (s) => s.id == settings.lastReadSurahId,
      orElse: () => Surah.allSurahs.first,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hero Banner Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.deepEmerald, AppTheme.primaryEmerald],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppTheme.accentGold.withValues(alpha: 0.65),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.accentGold.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 15,
                            color: AppTheme.accentGold,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            settings.selectedCity.nameUyghur,
                            style: const TextStyle(
                              color: AppTheme.accentGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    prayerAsync.maybeWhen(
                      data: (p) {
                        final next = p.getNextPrayer(DateTime.now());
                        return Text(
                          'كېيىنكى ناماز: ${next.name} (${next.time})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  AppConstants.appName,
                  style: TextStyle(
                    color: AppTheme.accentGold,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  AppConstants.appTagline,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 18),
                // Last Read Resume Card inside Hero
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_stories_rounded,
                        color: AppTheme.accentGold,
                        size: 30,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ئاخىرقى ئوقۇغان ئورۇن:',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${lastSurah.nameUyghur} (${lastSurah.nameArabic}) • ${settings.lastReadVerseNumber}-ئايەت',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.accentGold,
                          foregroundColor: AppTheme.deepEmerald,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReaderScreen(
                                surah: lastSurah,
                                initialVerse: settings.lastReadVerseNumber,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.menu_book_rounded, size: 18),
                        label: const Text(
                          'داۋاملاشتۇرۇش',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Modern Premium Muhammad Saleh Quran Translation Banner
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0A261B),
                  Color(0xFF144D37),
                  Color(0xFF1B5E20),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.accentGold.withValues(alpha: 0.7),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGold.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.accentGold.withValues(alpha: 0.6),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_stories_rounded,
                            size: 16,
                            color: AppTheme.accentGold,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'مۇسھەف ۋە ئۇيغۇرچە تەرجىمە ساندىنى',
                            style: TextStyle(
                              color: AppTheme.accentGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '100% تورسىز (Offline)',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'قۇرئان كەرىم ئۇيغۇرچە تەرجىمىسى',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'مەرھۇم مۇھەممەد سالىھ داموللامنىڭ قۇرئان كەرىم ئۇيغۇرچە تەرجىمىسى تولۇق تېكىستى ۋە 604 بەتلىك ئەسلى مۇسھەف كىتابى',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13.5,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
                // Feature Stat Badges
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _buildStatPill('114 سۈرە'),
                    _buildStatPill('6236 ئايەت'),
                    _buildStatPill('604 بەتلىك مۇسھەف'),
                    _buildStatPill('ئەسلى PDF كىتاب'),
                  ],
                ),
                const SizedBox(height: 18),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.accentGold,
                          foregroundColor: AppTheme.deepEmerald,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const MushafPagesScreen(initialPage: 1),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.menu_book_rounded,
                          size: 20,
                          color: AppTheme.deepEmerald,
                        ),
                        label: const Text(
                          '604 بەتنى مۇسھەفتەك ئوقۇش',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: AppTheme.accentGold.withValues(alpha: 0.6),
                          width: 1.3,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => onNavigateTab(1),
                      icon: const Icon(Icons.list_alt_rounded, size: 18),
                      label: const Text(
                        'سۈرىلەر تىزىملىكى',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick Search Trigger Bar
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.accentGold.withValues(alpha: 0.35),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search_rounded, color: AppTheme.accentGold),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'قۇرئان ئايەتلىرى ۋە ئۇيغۇرچە تەرجىمىسىدىن ئىزدەش...',
                      style: TextStyle(fontSize: 14.5),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 15),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Modern Featured / Popular Surahs Section with Artwork Cards
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.stars_rounded, color: AppTheme.accentGold, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'كۆپ ئوقۇلىدىغان سۈرىلەر',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => onNavigateTab(1),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                label: const Text(
                  'بارلىق 114 سۈرە',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 950
                  ? 4
                  : constraints.maxWidth > 560
                      ? 3
                      : 2;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _featuredSurahIds.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: constraints.maxWidth > 600 ? 1.08 : 0.96,
                ),
                itemBuilder: (context, index) {
                  final surah = Surah.allSurahs
                      .firstWhere((s) => s.id == _featuredSurahIds[index]);

                  final isDark = Theme.of(context).brightness == Brightness.dark;

                  return Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color ?? Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.accentGold.withValues(alpha: 0.55),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentGold.withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReaderScreen(surah: surah),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Surah Themed Artwork (Top)
                          Expanded(
                            flex: 5,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  'assets/images/surah_${surah.id}.jpg',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.primaryEmerald,
                                          AppTheme.deepEmerald,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                // Surah Number Badge (Top Right)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.95),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppTheme.accentGold,
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.15),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      '${surah.id}',
                                      style: const TextStyle(
                                        color: AppTheme.deepEmerald,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                // Arabic Name Glass Capsule (Top Left)
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.92),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppTheme.accentGold.withValues(alpha: 0.6),
                                        width: 0.8,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.12),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      surah.nameArabic,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.deepEmerald,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Surah Uyghur Info (Bottom)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardTheme.color ?? Colors.white,
                              border: Border(
                                top: BorderSide(
                                  color: AppTheme.accentGold.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  surah.nameUyghur,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark ? Colors.white : AppTheme.deepEmerald,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  '${surah.revelationPlaceUyghur} • ${surah.versesCount} ئايەت',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87.withValues(alpha: 0.65),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),

          // Main Feature Sections (Bright, Vibrant & Lively Modern Cards)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.dashboard_customize_rounded, color: AppTheme.accentGold, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'ئاساسلىق بۆلەكلەر',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminDashboardScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.admin_panel_settings_rounded,
                    size: 16, color: AppTheme.accentGold),
                label: const Text(
                  'ئارقا باشقۇرۇش (Admin)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 900
                  ? 3
                  : constraints.maxWidth > 520
                      ? 2
                      : 2;
              final features = [
                (
                  title: 'سۈرە تىزىملىكى',
                  subtitle: '114 سۈرە، ئەرەبچە + ئۇيغۇرچە',
                  icon: Icons.menu_book_rounded,
                  image: 'assets/images/feature_quran.jpg',
                  onTap: () => onNavigateTab(1),
                ),
                (
                  title: 'ناماز ۋاقتى',
                  subtitle: 'بەش ۋاقىت ناماز ۋە ھىجرىيە تەقۋىم',
                  icon: Icons.watch_later_rounded,
                  image: 'assets/images/feature_prayer.jpg',
                  onTap: () => onNavigateTab(2),
                ),
                (
                  title: 'قىبلا كومپاس',
                  subtitle: 'كەئبە يۆنىلىشى ۋە ئارىلىق',
                  icon: Icons.explore_rounded,
                  image: 'assets/images/feature_qibla.jpg',
                  onTap: () => onNavigateTab(3),
                ),
                (
                  title: 'ساقلانغان ئايەتلەر',
                  subtitle: 'خەتكۈچلەر (${settings.bookmarks.length})',
                  icon: Icons.bookmarks_rounded,
                  image: 'assets/images/feature_bookmarks.jpg',
                  onTap: () => onNavigateTab(4),
                ),
                (
                  title: 'ئىزدەش سۇپىسى',
                  subtitle: 'تەرجىمە ۋە ئايەت ئىزدەش',
                  icon: Icons.manage_search_rounded,
                  image: 'assets/images/feature_search.jpg',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    );
                  },
                ),
                (
                  title: 'تەڭشەكلەر ۋە قارىئى',
                  subtitle: settings.selectedReciter.nameUyghur,
                  icon: Icons.settings_suggest_rounded,
                  image: 'assets/images/feature_reciter.jpg',
                  onTap: () => onNavigateTab(5),
                ),
              ];

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: features.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: constraints.maxWidth > 600 ? 1.35 : 1.18,
                ),
                itemBuilder: (context, index) {
                  final item = features[index];
                  final isDark = Theme.of(context).brightness == Brightness.dark;

                  return Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color ?? Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.accentGold.withValues(alpha: 0.55),
                        width: 1.3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentGold.withValues(alpha: 0.14),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: item.onTap,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Vivid High-Quality Artwork (Top, no dark mud)
                          Expanded(
                            flex: 5,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  item.image,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: AppTheme.deepEmerald,
                                      child: const Icon(
                                        Icons.image_not_supported_rounded,
                                        color: Colors.white24,
                                      ),
                                    );
                                  },
                                ),
                                // Icon Capsule (Top Right)
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.95),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppTheme.accentGold,
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.16),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      item.icon,
                                      color: AppTheme.primaryEmerald,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                // Arrow Action Capsule (Top Left)
                                Positioned(
                                  top: 10,
                                  left: 10,
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.12),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: AppTheme.deepEmerald,
                                      size: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Bright, Clean Info Footer (Bottom)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardTheme.color ?? Colors.white,
                              border: Border(
                                top: BorderSide(
                                  color: AppTheme.accentGold.withValues(alpha: 0.35),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item.title,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : AppTheme.deepEmerald,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.subtitle,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87.withValues(alpha: 0.68),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accentGold.withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
