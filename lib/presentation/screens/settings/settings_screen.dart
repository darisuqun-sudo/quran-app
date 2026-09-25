import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/reciter_model.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_provider.dart';
import '../admin/admin_dashboard_screen.dart';
import '../auth/auth_modal.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User / Admin Account Profile Card
          Builder(
            builder: (context) {
              final authState = ref.watch(authProvider);
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: authState.isAdmin
                        ? AppTheme.accentGold
                        : (authState.isLoggedIn
                            ? AppTheme.primaryEmerald
                            : AppTheme.accentGold.withValues(alpha: 0.3)),
                    width: 1.2,
                  ),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: authState.isAdmin
                        ? AppTheme.accentGold
                        : (authState.isLoggedIn
                            ? AppTheme.primaryEmerald
                            : Colors.grey.withValues(alpha: 0.2)),
                    child: Icon(
                      authState.isAdmin
                          ? Icons.admin_panel_settings_rounded
                          : (authState.isLoggedIn
                              ? Icons.person_rounded
                              : Icons.person_outline_rounded),
                      color: authState.isAdmin ? AppTheme.deepEmerald : Colors.white,
                    ),
                  ),
                  title: Text(
                    authState.isLoggedIn
                        ? authState.currentUser!.name
                        : 'ئەزا بولۇش / كىرىش (ھېسابات)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    authState.isLoggedIn
                        ? '${authState.currentUser!.email} • ${authState.isAdmin ? 'باشقۇرغۇچى' : 'ئەزا'}'
                        : 'خەتكۈچ ۋە نىشانلارنى ساقلاش ئۈچۈن تىزىملىتىڭ',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                  trailing: FilledButton.tonal(
                    onPressed: () => AuthModal.show(context),
                    child: Text(
                      authState.isLoggedIn ? 'باشقۇرۇش' : 'كىرىش',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.palette_outlined, color: AppTheme.accentGold),
                      SizedBox(width: 8),
                      Text(
                        'كۆرۈنمە يۈزى ۋە تېما تەڭشىكى',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto_rounded),
                        label: Text('ئاپتوماتىك'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.wb_sunny_rounded),
                        label: Text('يورۇق'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_rounded),
                        label: Text('قاراڭغۇ'),
                      ),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (s) => notifier.setThemeMode(s.first),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.text_fields_rounded, color: AppTheme.accentGold),
                      SizedBox(width: 8),
                      Text(
                        'قۇرئان ۋە تەرجىمە خەت تەڭشەكلىرى',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('ئۇيغۇرچە تەرجىمىسىنى كۆرسىتىش'),
                    subtitle: const Text('مۇھەممەد سالىھ تەرجىمىسى (ID: 76)'),
                    value: settings.showTranslation,
                    onChanged: notifier.toggleShowTranslation,
                  ),
                  const Divider(),
                  Text('ئەرەبچە ئايەت خەت چوڭلۇقى: ${settings.arabicFontSize.toInt()}'),
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.accentGold.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ ﴿١﴾',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: settings.arabicFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (settings.showTranslation) ...[
                          const SizedBox(height: 6),
                          Text(
                            'ناھايتى شەپقەتلىك ۋە مېھرىبان ئاللاھنىڭ ئىسمى بىلەن باشلايمەن.',
                            style: TextStyle(fontSize: settings.uyghurFontSize),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.record_voice_over_rounded, color: AppTheme.accentGold),
                      SizedBox(width: 8),
                      Text(
                        'ئاۋازلىق تىلاۋەت قارىئىسى',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...Reciter.defaultReciters.map((r) {
                    final selected = r.id == settings.selectedReciter.id;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: () => notifier.setReciter(r),
                      leading: Icon(
                        selected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      title: Text(
                        '${r.nameUyghur} (${r.nameArabic})',
                        style: TextStyle(
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(r.styleUyghur),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Builder(
            builder: (context) {
              final authState = ref.watch(authProvider);
              if (authState.isAdmin) {
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppTheme.accentGold, width: 1.5),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGold.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: AppTheme.accentGold,
                        size: 24,
                      ),
                    ),
                    title: const Text(
                      'ئارقا باشقۇرۇش مەركىزى (Admin Dashboard)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    subtitle: const Text(
                      'سۈرە، قارىئىلار، شەھەرلەر ۋە ئەپ تەكشۈرۈش مەركىزى',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing:
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminDashboardScreen(),
                        ),
                      );
                    },
                  ),
                );
              } else {
                return Center(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.withValues(alpha: 0.7),
                    ),
                    icon: const Icon(Icons.lock_outline_rounded, size: 16),
                    label: const Text(
                      'باشقۇرغۇچى كىرىش ئېغىزى (Admin Portal)',
                      style: TextStyle(fontSize: 12),
                    ),
                    onPressed: () => AuthModal.show(context),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
