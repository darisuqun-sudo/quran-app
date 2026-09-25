class PrayerTimesData {
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;
  final String hijriDate;
  final String gregorianDate;
  final String cityName;

  const PrayerTimesData({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.hijriDate,
    required this.gregorianDate,
    required this.cityName,
  });

  static String _cleanTime(String raw) {
    return raw.split(' ').first.trim();
  }

  factory PrayerTimesData.fromAladhanJson(
    Map<String, dynamic> data, {
    required String cityName,
  }) {
    final timings = data['timings'] as Map<String, dynamic>? ?? {};
    final date = data['date'] as Map<String, dynamic>? ?? {};
    final hijri = date['hijri'] as Map<String, dynamic>? ?? {};
    final gregorian = date['gregorian'] as Map<String, dynamic>? ?? {};

    final hijriDay = hijri['day']?.toString() ?? '';
    final hijriMonthAr = (hijri['month'] as Map<String, dynamic>?)?['ar']?.toString() ?? '';
    final hijriYear = hijri['year']?.toString() ?? '';

    return PrayerTimesData(
      fajr: _cleanTime(timings['Fajr']?.toString() ?? '05:15'),
      sunrise: _cleanTime(timings['Sunrise']?.toString() ?? '06:45'),
      dhuhr: _cleanTime(timings['Dhuhr']?.toString() ?? '13:15'),
      asr: _cleanTime(timings['Asr']?.toString() ?? '17:30'),
      maghrib: _cleanTime(timings['Maghrib']?.toString() ?? '19:45'),
      isha: _cleanTime(timings['Isha']?.toString() ?? '21:15'),
      hijriDate: '$hijriYear-يىلى $hijriMonthAr $hijriDay-كۈنى',
      gregorianDate: gregorian['date']?.toString() ?? '',
      cityName: cityName,
    );
  }

  Map<String, String> get allPrayersMap => {
        'بامدات': fajr,
        'كۈن چىقىش': sunrise,
        'پېشىن': dhuhr,
        'ئەسىر': asr,
        'شام': maghrib,
        'خۇپتەن': isha,
      };

  /// Returns the name and time of the next upcoming prayer
  ({String name, String time, Duration remaining}) getNextPrayer(DateTime now) {
    final entries = [
      ('بامدات', fajr),
      ('كۈن چىقىش', sunrise),
      ('پېشىن', dhuhr),
      ('ئەسىر', asr),
      ('شام', maghrib),
      ('خۇپتەن', isha),
    ];

    for (final item in entries) {
      final parts = item.$2.split(':');
      if (parts.length >= 2) {
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        final dt = DateTime(now.year, now.month, now.day, h, m);
        if (dt.isAfter(now)) {
          return (name: item.$1, time: item.$2, remaining: dt.difference(now));
        }
      }
    }

    // Next is tomorrow's Fajr
    final parts = fajr.split(':');
    final h = int.tryParse(parts[0]) ?? 5;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    final tomorrowFajr =
        DateTime(now.year, now.month, now.day, h, m).add(const Duration(days: 1));
    return (
      name: 'بامدات (ئەتە)',
      time: fajr,
      remaining: tomorrowFajr.difference(now)
    );
  }
}
