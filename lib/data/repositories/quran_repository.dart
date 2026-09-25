import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../models/ayah_model.dart';
import '../models/surah_model.dart';

class QuranRepository {
  final Dio _dio;
  static Map<int, List<Ayah>>? _bundledSalehQuran;

  QuranRepository({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 12),
                receiveTimeout: const Duration(seconds: 15),
              ),
            );

  Future<List<Surah>> getSurahs() async {
    return Surah.allSurahs;
  }

  /// Loads the bundled complete 6,236-verse Muhammad Saleh Uyghur Quran Translation
  /// (`assets/data/quran_uyghur_saleh.json`) into memory.
  Future<Map<int, List<Ayah>>> _ensureBundledQuranLoaded() async {
    if (_bundledSalehQuran != null && _bundledSalehQuran!.isNotEmpty) {
      return _bundledSalehQuran!;
    }
    try {
      final rawJson =
          await rootBundle.loadString('assets/data/quran_uyghur_saleh.json');
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      final Map<int, List<Ayah>> result = {};
      for (final entry in decoded.entries) {
        final sId = int.tryParse(entry.key) ?? 1;
        final list = entry.value as List<dynamic>;
        result[sId] = list
            .map((e) => Ayah.fromLocalJson(e as Map<String, dynamic>))
            .toList();
      }
      _bundledSalehQuran = result;
      return result;
    } catch (_) {
      return {};
    }
  }

  /// Fetches all verses of a Surah with Uthmani Arabic text and Muhammad Saleh Uyghur translation.
  /// Primary source: Bundled Muhammad Saleh Quran (`assets/data/quran_uyghur_saleh.json`).
  Future<List<Ayah>> getSurahAyahs(int surahId, {bool forceRefresh = false}) async {
    // 1. First use the embedded Muhammad Saleh Uyghur Quran Translation dataset (all 114 Surahs)
    final bundled = await _ensureBundledQuranLoaded();
    if (bundled.containsKey(surahId) && bundled[surahId]!.isNotEmpty) {
      return bundled[surahId]!;
    }

    // 2. Check SharedPreferences cache
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'cached_surah_v2_$surahId';

    if (!forceRefresh) {
      final cachedRaw = prefs.getString(cacheKey);
      if (cachedRaw != null && cachedRaw.isNotEmpty) {
        try {
          final List<dynamic> decoded = jsonDecode(cachedRaw) as List<dynamic>;
          if (decoded.isNotEmpty) {
            return decoded
                .map((e) => Ayah.fromLocalJson(e as Map<String, dynamic>))
                .toList();
          }
        } catch (_) {}
      }
    }

    // 3. Fallback to AlQuran.cloud API (ug.saleh)
    try {
      final response = await _dio.get(
        '${AppConstants.alQuranCloudBaseUrl}/surah/$surahId/editions/quran-uthmani,ug.saleh',
      );
      if (response.statusCode == 200 && response.data != null) {
        final dataList = response.data['data'] as List<dynamic>? ?? [];
        if (dataList.length >= 2) {
          final arabicAyahs =
              (dataList[0] as Map<String, dynamic>)['ayahs'] as List<dynamic>? ?? [];
          final uyghurAyahs =
              (dataList[1] as Map<String, dynamic>)['ayahs'] as List<dynamic>? ?? [];

          final List<Ayah> ayahs = [];
          for (int i = 0; i < arabicAyahs.length; i++) {
            final ar = arabicAyahs[i] as Map<String, dynamic>;
            final ug = i < uyghurAyahs.length
                ? (uyghurAyahs[i] as Map<String, dynamic>)
                : <String, dynamic>{};
            final numInSurah = (ar['numberInSurah'] as num?)?.toInt() ?? (i + 1);
            ayahs.add(
              Ayah(
                id: (ar['number'] as num?)?.toInt() ?? (i + 1),
                surahNumber: surahId,
                verseNumber: numInSurah,
                verseKey: '$surahId:$numInSurah',
                textUthmani: ar['text']?.toString() ?? '',
                uyghurTranslation:
                    Ayah.cleanHtmlTags(ug['text']?.toString() ?? ''),
                pageNumber: (ar['page'] as num?)?.toInt() ?? 1,
                juzNumber: (ar['juz'] as num?)?.toInt() ?? 1,
              ),
            );
          }
          if (ayahs.isNotEmpty) {
            await prefs.setString(
              cacheKey,
              jsonEncode(ayahs.map((a) => a.toJson()).toList()),
            );
            return ayahs;
          }
        }
      }
    } catch (_) {}

    throw Exception('ئايەتلەرنى يۈكلەشتە خاتالىق كۆرۈلدى.');
  }

  /// Searches instantaneously across all 6,236 verses of the bundled Muhammad Saleh Uyghur Translation
  /// and Uthmani Arabic text!
  Future<List<({Surah surah, Ayah ayah})>> searchVerses(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final List<({Surah surah, Ayah ayah})> results = [];
    final bundled = await _ensureBundledQuranLoaded();

    if (bundled.isNotEmpty) {
      for (final surah in Surah.allSurahs) {
        final verses = bundled[surah.id] ?? const [];
        for (final ayah in verses) {
          if (ayah.uyghurTranslation.contains(trimmed) ||
              ayah.textUthmani.contains(trimmed) ||
              surah.nameUyghur.contains(trimmed)) {
            results.add((surah: surah, ayah: ayah));
            if (results.length >= 60) {
              return results;
            }
          }
        }
      }
      return results;
    }

    return results;
  }

  /// Instant lookup of all verses on any of the 604 Mushaf pages
  Future<List<({Surah surah, Ayah ayah})>> getPageVerses(int pageNumber) async {
    final bundled = await _ensureBundledQuranLoaded();
    final List<({Surah surah, Ayah ayah})> results = [];
    if (bundled.isNotEmpty) {
      for (final surah in Surah.allSurahs) {
        final verses = bundled[surah.id] ?? const [];
        for (final ayah in verses) {
          if (ayah.pageNumber == pageNumber) {
            results.add((surah: surah, ayah: ayah));
          }
        }
      }
    }
    return results;
  }
}
