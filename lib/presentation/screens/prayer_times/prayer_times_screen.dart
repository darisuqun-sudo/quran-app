import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/qibla_utils.dart';
import '../../providers/app_providers.dart';

class PrayerTimesScreen extends ConsumerStatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  ConsumerState<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends ConsumerState<PrayerTimesScreen> {
  bool _isLocatingGps = false;

  Future<void> _detectGpsLocation() async {
    setState(() => _isLocatingGps = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition();
        await ref.read(appSettingsProvider.notifier).setCity(
              CityLocation(
                nameUyghur: 'نۆۋەتتىكى ئورنىڭىز (GPS)',
                countryUyghur:
                    '${pos.latitude.toStringAsFixed(2)}°N, ${pos.longitude.toStringAsFixed(2)}°E',
                latitude: pos.latitude,
                longitude: pos.longitude,
                isAutoDetected: true,
              ),
            );
      } else {
        // Fallback to IP auto detection
        await ref.read(appSettingsProvider.notifier).autoDetectLocation(force: true);
      }
    } catch (_) {
      await ref.read(appSettingsProvider.notifier).autoDetectLocation(force: true);
    } finally {
      if (mounted) {
        setState(() => _isLocatingGps = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final prayerAsync = ref.watch(prayerTimesProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Location & Method Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: AppTheme.accentGold),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    settings.selectedCity.nameUyghur,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (settings.selectedCity.isAutoDetected) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentGold.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppTheme.accentGold.withValues(alpha: 0.6),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: const Text(
                                      'ئاپتوماتىك',
                                      style: TextStyle(
                                        color: AppTheme.accentGold,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (settings.selectedCity.countryUyghur.isNotEmpty)
                              Text(
                                settings.selectedCity.countryUyghur,
                                style: const TextStyle(fontSize: 12.5),
                              ),
                          ],
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _isLocatingGps || settings.isDetectingLocation
                            ? null
                            : _detectGpsLocation,
                        icon: settings.isDetectingLocation || _isLocatingGps
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location_rounded, size: 18),
                        label: const Text('ئورۇننى يېڭىلاش'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Auto detect quick button
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ActionChip(
                            avatar: const Icon(Icons.auto_awesome_rounded, size: 16),
                            label: const Text('ئاپتوماتىك ئورۇن (Auto Detect)'),
                            onPressed: () => ref
                                .read(appSettingsProvider.notifier)
                                .autoDetectLocation(force: true),
                          ),
                        ),
                        ...QiblaUtils.presetCities.map((city) {
                          final selected = !settings.selectedCity.isAutoDetected &&
                              city.nameUyghur == settings.selectedCity.nameUyghur;
                          return Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: ChoiceChip(
                              label: Text('${city.nameUyghur} (${city.countryUyghur})'),
                              selected: selected,
                              onSelected: (_) {
                                ref.read(appSettingsProvider.notifier).setCity(city);
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ئەسىر ۋاقتى ھېسابلاش ئۇسۇلى:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: true, label: Text('ھەنەفى')),
                          ButtonSegment(value: false, label: Text('شافىئىي')),
                        ],
                        selected: {settings.isHanafi},
                        onSelectionChanged: (s) {
                          ref.read(appSettingsProvider.notifier).setHanafi(s.first);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          prayerAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(36),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('ناماز ۋاقتىنى يۈكلەشتە خاتالىق كۆرۈلدى: $e'),
              ),
            ),
            data: (prayerData) {
              final next = prayerData.getNextPrayer(DateTime.now());
              final hours = next.remaining.inHours;
              final minutes = next.remaining.inMinutes.remainder(60);

              final icons = <String, IconData>{
                'بامدات': Icons.wb_twilight_rounded,
                'كۈن چىقىش': Icons.wb_sunny_outlined,
                'پېشىن': Icons.wb_sunny_rounded,
                'ئەسىر': Icons.light_mode_rounded,
                'شام': Icons.nights_stay_outlined,
                'خۇپتەن': Icons.dark_mode_rounded,
              };

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero Next Prayer Card
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.deepEmerald, AppTheme.primaryEmerald],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.accentGold.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          prayerData.hijriDate,
                          style: const TextStyle(
                            color: AppTheme.accentGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'مىلادىيە: ${prayerData.gregorianDate}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(color: Colors.white24),
                        ),
                        const Text(
                          'كېيىنكى ناماز ۋاقتى',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${next.name} — ${next.time}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'قالغان ۋاقىت: $hours سائەت $minutes مىنۇت',
                            style: const TextStyle(
                              color: AppTheme.accentGold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...prayerData.allPrayersMap.entries.map((entry) {
                    final isNext = next.name.startsWith(entry.key);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      color: isNext
                          ? AppTheme.accentGold.withValues(alpha: 0.16)
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isNext
                              ? AppTheme.accentGold
                              : AppTheme.accentGold.withValues(alpha: 0.2),
                          width: isNext ? 2 : 1,
                        ),
                      ),
                      child: ListTile(
                        leading: Icon(
                          icons[entry.key] ?? Icons.access_time_rounded,
                          color: isNext
                              ? AppTheme.accentGold
                              : Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                        title: Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight:
                                isNext ? FontWeight.bold : FontWeight.w600,
                          ),
                        ),
                        trailing: Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
