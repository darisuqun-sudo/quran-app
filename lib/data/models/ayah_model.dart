import '../../core/constants/app_constants.dart';

class Ayah {
  final int id;
  final int surahNumber;
  final int verseNumber;
  final String verseKey; // e.g., "1:1"
  final String textUthmani;
  final String uyghurTranslation;
  final int pageNumber;
  final int juzNumber;

  const Ayah({
    required this.id,
    required this.surahNumber,
    required this.verseNumber,
    required this.verseKey,
    required this.textUthmani,
    required this.uyghurTranslation,
    this.pageNumber = 1,
    this.juzNumber = 1,
  });

  /// Generates EveryAyah MP3 URL for a given reciter subfolder (e.g. "Alafasy_128kbps")
  String getAudioUrl(String reciterFolder) {
    final s = surahNumber.toString().padLeft(3, '0');
    final v = verseNumber.toString().padLeft(3, '0');
    return '${AppConstants.everyAyahBaseUrl}/$reciterFolder/$s$v.mp3';
  }

  static String cleanHtmlTags(String raw) {
    // Strip <sup foot_note=...>...</sup> and any remaining HTML tags
    return raw
        .replaceAll(RegExp(r'<sup[^>]*>.*?<\/sup>', dotAll: true), '')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .trim();
  }

  factory Ayah.fromQuranComJson(int surahId, Map<String, dynamic> json) {
    final verseNum = (json['verse_number'] as num?)?.toInt() ?? 1;
    final verseKey = json['verse_key']?.toString() ?? '$surahId:$verseNum';
    String translationText = '';
    if (json['translations'] is List && (json['translations'] as List).isNotEmpty) {
      final firstTrans = (json['translations'] as List).first;
      if (firstTrans is Map<String, dynamic>) {
        translationText = cleanHtmlTags(firstTrans['text']?.toString() ?? '');
      }
    }

    return Ayah(
      id: (json['id'] as num?)?.toInt() ?? verseNum,
      surahNumber: surahId,
      verseNumber: verseNum,
      verseKey: verseKey,
      textUthmani: json['text_uthmani']?.toString() ?? '',
      uyghurTranslation: translationText,
      pageNumber: (json['page_number'] as num?)?.toInt() ?? 1,
      juzNumber: (json['juz_number'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'surahNumber': surahNumber,
        'verseNumber': verseNumber,
        'verseKey': verseKey,
        'textUthmani': textUthmani,
        'uyghurTranslation': uyghurTranslation,
        'pageNumber': pageNumber,
        'juzNumber': juzNumber,
      };

  factory Ayah.fromLocalJson(Map<String, dynamic> json) => Ayah(
        id: (json['id'] as num?)?.toInt() ?? 1,
        surahNumber: (json['surahNumber'] as num?)?.toInt() ?? 1,
        verseNumber: (json['verseNumber'] as num?)?.toInt() ?? 1,
        verseKey: json['verseKey']?.toString() ?? '1:1',
        textUthmani: json['textUthmani']?.toString() ?? '',
        uyghurTranslation: json['uyghurTranslation']?.toString() ?? '',
        pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 1,
        juzNumber: (json['juzNumber'] as num?)?.toInt() ?? 1,
      );
}
