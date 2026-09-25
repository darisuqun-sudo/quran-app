import 'package:dio/dio.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../models/prayer_time_model.dart';

class PrayerRepository {
  final Dio _dio;

  PrayerRepository({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 12),
              ),
            );

  /// Fetches daily prayer times from Aladhan API (`school = 1` for Hanafi by default)
  Future<PrayerTimesData> getPrayerTimes({
    required double latitude,
    required double longitude,
    required String cityName,
    bool isHanafi = true,
  }) async {
    try {
      final response = await _dio.get(
        '${AppConstants.prayerApiBaseUrl}/timings',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'method': 3, // Muslim World League
          'school': isHanafi ? 1 : 0, // 1 = Hanafi (ئەسىر ۋاقتى ھەنەفى مەزھىپى بويىچە)
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>?;
        if (data != null) {
          return PrayerTimesData.fromAladhanJson(data, cityName: cityName);
        }
      }
    } catch (_) {}

    // Offline fallback with Hijri calendar computation
    final now = DateTime.now();
    final hijri = HijriCalendar.fromDate(now);
    return PrayerTimesData(
      fajr: '05:18',
      sunrise: '06:48',
      dhuhr: '13:20',
      asr: isHanafi ? '17:42' : '16:45',
      maghrib: '19:48',
      isha: '21:15',
      hijriDate: '${hijri.hYear}-يىلى ${hijri.hMonth}-ئاي ${hijri.hDay}-كۈنى',
      gregorianDate: DateFormat('dd-MM-yyyy').format(now),
      cityName: cityName,
    );
  }
}
