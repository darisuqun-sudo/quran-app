import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/core/constants/app_constants.dart';
import 'package:quran_app/core/utils/qibla_utils.dart';
import 'package:quran_app/data/models/surah_model.dart';
import 'package:quran_app/main.dart';

import 'package:quran_app/data/models/prayer_time_model.dart';
import 'package:quran_app/presentation/providers/app_providers.dart';

void main() {
  testWidgets('App loads with Uyghur Quran branding and navigation',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prayerTimesProvider.overrideWith(
            (ref) async => const PrayerTimesData(
              fajr: '05:15',
              sunrise: '06:45',
              dhuhr: '13:20',
              asr: '17:40',
              maghrib: '19:45',
              isha: '21:15',
              hijriDate: '1448-يىلى رەمىزان 1-كۈنى',
              gregorianDate: '25-09-2026',
              cityName: 'مەككە مۇكەررەمە',
            ),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppConstants.appName), findsWidgets);
    expect(find.text('سۈرىلەر'), findsWidgets);
    expect(find.text('604 بەتنى ئوقۇش'), findsOneWidget);
    expect(Surah.allSurahs.length, 114);

    final bearing = QiblaUtils.calculateQiblaBearing(41.0082, 28.9784);
    expect(bearing, inInclusiveRange(0.0, 360.0));
  });
}
