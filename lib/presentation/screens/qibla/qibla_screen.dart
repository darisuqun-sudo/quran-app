import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/qibla_utils.dart';
import '../../providers/app_providers.dart';

class QiblaScreen extends ConsumerStatefulWidget {
  const QiblaScreen({super.key});

  @override
  ConsumerState<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends ConsumerState<QiblaScreen> {
  double _deviceHeadingDegrees = 0.0;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final city = settings.selectedCity;

    final qiblaBearing = QiblaUtils.calculateQiblaBearing(
      city.latitude,
      city.longitude,
    );
    final distanceKm = QiblaUtils.calculateDistanceToKaabaKm(
      city.latitude,
      city.longitude,
    );
    final directionName = QiblaUtils.getCardinalDirectionUyghur(qiblaBearing);
    final relativeQiblaAngle =
        (qiblaBearing - _deviceHeadingDegrees) * (math.pi / 180.0);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.explore_rounded, color: AppTheme.accentGold),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                'ئورۇن: ${city.nameUyghur}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (city.isAutoDetected) ...[
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
                      ),
                      FilledButton.tonalIcon(
                        onPressed: settings.isDetectingLocation
                            ? null
                            : () => ref
                                .read(appSettingsProvider.notifier)
                                .autoDetectLocation(force: true),
                        icon: settings.isDetectingLocation
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
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
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
                        ...QiblaUtils.presetCities.map((c) {
                          final selected = !city.isAutoDetected &&
                              c.nameUyghur == city.nameUyghur;
                          return Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: ChoiceChip(
                              label: Text('${c.nameUyghur} (${c.countryUyghur})'),
                              selected: selected,
                              onSelected: (_) {
                                ref.read(appSettingsProvider.notifier).setCity(c);
                              },
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
          const SizedBox(height: 16),
          // Compass Dial Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'قىبلا بۇلۇڭى: ${qiblaBearing.toStringAsFixed(1)}° ($directionName)',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'كەئبە شەرىفكىچە بولغان ئارىلىق: ${distanceKm.toStringAsFixed(0)} كىلومېتىر',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: 260,
                    height: 260,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer Compass Ring
                        Transform.rotate(
                          angle: -_deviceHeadingDegrees * (math.pi / 180.0),
                          child: Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                colors: [
                                  AppTheme.primaryEmerald,
                                  AppTheme.deepEmerald,
                                ],
                              ),
                              border: Border.all(
                                color: AppTheme.accentGold,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: const [
                                Positioned(
                                  top: 12,
                                  child: Text(
                                    'شىمال (N)',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 12,
                                  child: Text(
                                    'جەنۇب (S)',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 14,
                                  child: Text(
                                    'شەرق (E)',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 14,
                                  child: Text(
                                    'غەرب (W)',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Qibla Needle pointing toward Kaaba
                        Transform.rotate(
                          angle: relativeQiblaAngle,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppTheme.accentGold,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.mosque_rounded,
                                  color: AppTheme.deepEmerald,
                                  size: 22,
                                ),
                              ),
                              Container(
                                width: 5,
                                height: 68,
                                decoration: BoxDecoration(
                                  color: AppTheme.accentGold,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              Container(
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(height: 68),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'كومپاس يۆنىلىشىنى قولدا تەڭشەش (تور بېكەت / كومپيۇتېر ئۈچۈن): ${_deviceHeadingDegrees.toInt()}°',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Slider(
                    value: _deviceHeadingDegrees,
                    min: 0,
                    max: 360,
                    onChanged: (val) => setState(() => _deviceHeadingDegrees = val),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
