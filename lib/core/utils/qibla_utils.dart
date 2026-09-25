import 'dart:math' as math;
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';

class CityLocation {
  final String nameUyghur;
  final String countryUyghur;
  final double latitude;
  final double longitude;
  final bool isAutoDetected;

  const CityLocation({
    required this.nameUyghur,
    required this.countryUyghur,
    required this.latitude,
    required this.longitude,
    this.isAutoDetected = false,
  });
}

class QiblaUtils {
  QiblaUtils._();

  static const CityLocation defaultCity = CityLocation(
    nameUyghur: 'مەككە مۇكەررەمە',
    countryUyghur: 'سەئۇدى ئەرەبىستان',
    latitude: 21.4225,
    longitude: 39.8262,
  );

  static const List<CityLocation> presetCities = [
    CityLocation(
      nameUyghur: 'مەككە مۇكەررەمە',
      countryUyghur: 'سەئۇدى ئەرەبىستان',
      latitude: 21.4225,
      longitude: 39.8262,
    ),
    CityLocation(
      nameUyghur: 'مەدىنە مۇنەۋۋەرە',
      countryUyghur: 'سەئۇدى ئەرەبىستان',
      latitude: 24.4672,
      longitude: 39.6112,
    ),
    CityLocation(
      nameUyghur: 'قۇددۇس شەرىف',
      countryUyghur: 'پەلەستىن',
      latitude: 31.7683,
      longitude: 35.2137,
    ),
    CityLocation(
      nameUyghur: 'دەمەشق',
      countryUyghur: 'سۈرىيە',
      latitude: 33.5138,
      longitude: 36.2765,
    ),
    CityLocation(
      nameUyghur: 'ھەلەب',
      countryUyghur: 'سۈرىيە',
      latitude: 36.2021,
      longitude: 37.1343,
    ),
    CityLocation(
      nameUyghur: 'ئىستانبۇل',
      countryUyghur: 'تۈركىيە',
      latitude: 41.0082,
      longitude: 28.9784,
    ),
    CityLocation(
      nameUyghur: 'ئەنقەرە',
      countryUyghur: 'تۈركىيە',
      latitude: 39.9334,
      longitude: 32.8597,
    ),
    CityLocation(
      nameUyghur: 'قاھىرە',
      countryUyghur: 'مىسىر',
      latitude: 30.0444,
      longitude: 31.2357,
    ),
    CityLocation(
      nameUyghur: 'دۇبەي',
      countryUyghur: 'ئەرەب بىرلەشمە خەلىپىلىكى',
      latitude: 25.2048,
      longitude: 55.2708,
    ),
    CityLocation(
      nameUyghur: 'تاشكەنت',
      countryUyghur: 'ئۆزبېكىستان',
      latitude: 41.2995,
      longitude: 69.2401,
    ),
    CityLocation(
      nameUyghur: 'بىشكەك',
      countryUyghur: 'قىرغىزىستان',
      latitude: 42.8746,
      longitude: 74.5698,
    ),
    CityLocation(
      nameUyghur: 'ئالماتا',
      countryUyghur: 'قازاقىستان',
      latitude: 43.2220,
      longitude: 76.8512,
    ),
    CityLocation(
      nameUyghur: 'كۇئالالۇمپۇر',
      countryUyghur: 'مالايسىيا',
      latitude: 3.1390,
      longitude: 101.6869,
    ),
    CityLocation(
      nameUyghur: 'لوندون',
      countryUyghur: 'ئەنگلىيە',
      latitude: 51.5074,
      longitude: -0.1278,
    ),
    CityLocation(
      nameUyghur: 'بېرلىن',
      countryUyghur: 'گېرمانىيە',
      latitude: 52.5200,
      longitude: 13.4050,
    ),
    CityLocation(
      nameUyghur: 'نيۇ-يورك',
      countryUyghur: 'ئامېرىكا',
      latitude: 40.7128,
      longitude: -74.0060,
    ),
  ];

  /// Automatically detects the user's location via IP Geolocation APIs (works on Web & Mobile without permission prompts)
  static Future<CityLocation?> detectLocationFromIp() async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 6),
        receiveTimeout: const Duration(seconds: 6),
      ),
    );

    // 1. Try freeipapi.com
    try {
      final res = await dio.get('https://freeipapi.com/api/json');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        final data = res.data as Map<String, dynamic>;
        final cityName = data['cityName']?.toString() ?? '';
        final countryName = data['countryName']?.toString() ?? '';
        final lat = (data['latitude'] as num?)?.toDouble();
        final lon = (data['longitude'] as num?)?.toDouble();
        if (lat != null && lon != null && cityName.isNotEmpty) {
          return CityLocation(
            nameUyghur: cityName,
            countryUyghur: countryName,
            latitude: lat,
            longitude: lon,
            isAutoDetected: true,
          );
        }
      }
    } catch (_) {}

    // 2. Fallback: ipapi.co
    try {
      final res = await dio.get('https://ipapi.co/json/');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        final data = res.data as Map<String, dynamic>;
        final cityName = data['city']?.toString() ?? '';
        final countryName = data['country_name']?.toString() ?? '';
        final lat = (data['latitude'] as num?)?.toDouble();
        final lon = (data['longitude'] as num?)?.toDouble();
        if (lat != null && lon != null && cityName.isNotEmpty) {
          return CityLocation(
            nameUyghur: cityName,
            countryUyghur: countryName,
            latitude: lat,
            longitude: lon,
            isAutoDetected: true,
          );
        }
      }
    } catch (_) {}

    return null;
  }

  /// Calculates the Great-Circle bearing from (lat, lon) to the Kaaba in degrees [0, 360).
  static double calculateQiblaBearing(double latitude, double longitude) {
    final lat1 = _degToRad(latitude);
    final lon1 = _degToRad(longitude);
    final lat2 = _degToRad(AppConstants.kaabaLatitude);
    final lon2 = _degToRad(AppConstants.kaabaLongitude);

    final dLon = lon2 - lon1;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final bearingRad = math.atan2(y, x);
    final bearingDeg = (_radToDeg(bearingRad) + 360.0) % 360.0;
    return bearingDeg;
  }

  /// Calculates the Haversine distance to the Kaaba in kilometers.
  static double calculateDistanceToKaabaKm(double latitude, double longitude) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(AppConstants.kaabaLatitude - latitude);
    final dLon = _degToRad(AppConstants.kaabaLongitude - longitude);

    final lat1 = _degToRad(latitude);
    final lat2 = _degToRad(AppConstants.kaabaLatitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLon / 2) *
            math.sin(dLon / 2) *
            math.cos(lat1) *
            math.cos(lat2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static String getCardinalDirectionUyghur(double degree) {
    if (degree >= 337.5 || degree < 22.5) return 'شىمال (N)';
    if (degree >= 22.5 && degree < 67.5) return 'شەرقىي شىمال (NE)';
    if (degree >= 67.5 && degree < 112.5) return 'شەرق (E)';
    if (degree >= 112.5 && degree < 157.5) return 'شەرقىي جەنۇب (SE)';
    if (degree >= 157.5 && degree < 202.5) return 'جەنۇب (S)';
    if (degree >= 202.5 && degree < 247.5) return 'غەربىي جەنۇب (SW)';
    if (degree >= 247.5 && degree < 292.5) return 'غەرب (W)';
    return 'غەربىي شىمال (NW)';
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);
  static double _radToDeg(double rad) => rad * (180.0 / math.pi);
}
