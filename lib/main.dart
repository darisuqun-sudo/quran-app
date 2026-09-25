import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/app_providers.dart';
import 'presentation/screens/admin/admin_dashboard_screen.dart';
import 'presentation/screens/bookmarks/bookmarks_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/prayer_times/prayer_times_screen.dart';
import 'presentation/screens/qibla/qibla_screen.dart';
import 'presentation/screens/search/search_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/screens/surah_list/surah_list_screen.dart';
import 'presentation/widgets/audio_player_bar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: settings.themeMode,
      home: const MainNavigationShell(),
    );
  }
}

class QuranApp extends MyApp {
  const QuranApp({super.key});
}

class MainNavigationShell extends ConsumerStatefulWidget {
  const MainNavigationShell({super.key});

  @override
  ConsumerState<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  int _selectedIndex = 0;

  void _setTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  static const List<({String label, IconData icon})> _destinations = [
    (label: 'باش بەت', icon: Icons.home_rounded),
    (label: 'سۈرىلەر', icon: Icons.menu_book_rounded),
    (label: 'ناماز ۋاقتى', icon: Icons.watch_later_rounded),
    (label: 'قىبلا', icon: Icons.explore_rounded),
    (label: 'خەتكۈچلەر', icon: Icons.bookmarks_rounded),
    (label: 'تەڭشەكلەر', icon: Icons.settings_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final screens = <Widget>[
      DashboardHomeScreen(onNavigateTab: _setTab),
      const SurahListScreen(),
      const PrayerTimesScreen(),
      const QiblaScreen(),
      const BookmarksScreen(),
      const SettingsScreen(),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWideWeb = constraints.maxWidth >= 860;

          return Scaffold(
            appBar: AppBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_stories_rounded,
                    color: AppTheme.accentGold,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${AppConstants.appName} — ${_destinations[_selectedIndex].label}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'قۇرئاندىن ئىزدەش',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    );
                  },
                  icon: const Icon(Icons.search_rounded),
                ),
                IconButton(
                  tooltip: 'ئارقا باشقۇرۇش سۇپىسى (Admin Panel)',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminDashboardScreen(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: AppTheme.accentGold,
                  ),
                ),
                IconButton(
                  tooltip: isDark ? 'يورۇق ھالەتكە ئالماشتۇرۇش' : 'قاراڭغۇ ھالەتكە ئالماشتۇرۇش',
                  onPressed: () {
                    ref.read(appSettingsProvider.notifier).setThemeMode(
                          isDark ? ThemeMode.light : ThemeMode.dark,
                        );
                  },
                  icon: Icon(
                    isDark ? Icons.wb_sunny_rounded : Icons.dark_mode_rounded,
                    color: AppTheme.accentGold,
                  ),
                ),
                const SizedBox(width: 6),
              ],
            ),
            body: Row(
              children: [
                if (isWideWeb)
                  NavigationRail(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _setTab,
                    labelType: NavigationRailLabelType.all,
                    leading: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: AppTheme.primaryEmerald,
                        child: Icon(
                          Icons.mosque_rounded,
                          color: AppTheme.accentGold,
                        ),
                      ),
                    ),
                    destinations: _destinations
                        .map(
                          (d) => NavigationRailDestination(
                            icon: Icon(d.icon),
                            label: Text(d.label),
                          ),
                        )
                        .toList(),
                  ),
                if (isWideWeb) const VerticalDivider(width: 1),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1050),
                            child: screens[_selectedIndex],
                          ),
                        ),
                      ),
                      const AudioPlayerBar(),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: isWideWeb
                ? null
                : NavigationBar(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _setTab,
                    destinations: _destinations
                        .map(
                          (d) => NavigationDestination(
                            icon: Icon(d.icon),
                            label: d.label,
                          ),
                        )
                        .toList(),
                  ),
          );
        },
      ),
    );
  }
}
