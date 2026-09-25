import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/qibla_utils.dart';
import '../../data/models/ayah_model.dart';
import '../../data/models/prayer_time_model.dart';
import '../../data/models/reciter_model.dart';
import '../../data/models/surah_model.dart';
import '../../data/repositories/prayer_repository.dart';
import '../../data/repositories/quran_repository.dart';

final quranRepositoryProvider = Provider<QuranRepository>((ref) {
  return QuranRepository();
});

final prayerRepositoryProvider = Provider<PrayerRepository>((ref) {
  return PrayerRepository();
});

class AppSettingsState {
  final ThemeMode themeMode;
  final double arabicFontSize;
  final double uyghurFontSize;
  final bool showTranslation;
  final Reciter selectedReciter;
  final CityLocation selectedCity;
  final bool isHanafi;
  final Set<String> bookmarks; // Format: "surahId:verseNumber|surahName|previewText"
  final int lastReadSurahId;
  final int lastReadVerseNumber;
  final bool isDetectingLocation;

  const AppSettingsState({
    this.themeMode = ThemeMode.system,
    this.arabicFontSize = 28.0,
    this.uyghurFontSize = 16.5,
    this.showTranslation = true,
    this.selectedReciter = const Reciter(
      id: 'alafasy',
      nameUyghur: 'مىشارى راشىد ئەلئەفاسى',
      nameArabic: 'مشاري راشد العفاسي',
      styleUyghur: 'مۇرەتتەل (ئېنىق ۋە راۋان)',
      everyAyahFolder: 'Alafasy_128kbps',
    ),
    this.selectedCity = QiblaUtils.defaultCity,
    this.isHanafi = true,
    this.bookmarks = const {},
    this.lastReadSurahId = 1,
    this.lastReadVerseNumber = 1,
    this.isDetectingLocation = false,
  });

  bool isBookmarked(int surahId, int verseNumber) {
    final prefix = '$surahId:$verseNumber|';
    return bookmarks.any((b) => b.startsWith(prefix) || b == '$surahId:$verseNumber');
  }

  AppSettingsState copyWith({
    ThemeMode? themeMode,
    double? arabicFontSize,
    double? uyghurFontSize,
    bool? showTranslation,
    Reciter? selectedReciter,
    CityLocation? selectedCity,
    bool? isHanafi,
    Set<String>? bookmarks,
    int? lastReadSurahId,
    int? lastReadVerseNumber,
    bool? isDetectingLocation,
  }) {
    return AppSettingsState(
      themeMode: themeMode ?? this.themeMode,
      arabicFontSize: arabicFontSize ?? this.arabicFontSize,
      uyghurFontSize: uyghurFontSize ?? this.uyghurFontSize,
      showTranslation: showTranslation ?? this.showTranslation,
      selectedReciter: selectedReciter ?? this.selectedReciter,
      selectedCity: selectedCity ?? this.selectedCity,
      isHanafi: isHanafi ?? this.isHanafi,
      bookmarks: bookmarks ?? this.bookmarks,
      lastReadSurahId: lastReadSurahId ?? this.lastReadSurahId,
      lastReadVerseNumber: lastReadVerseNumber ?? this.lastReadVerseNumber,
      isDetectingLocation: isDetectingLocation ?? this.isDetectingLocation,
    );
  }
}

class AppSettingsNotifier extends Notifier<AppSettingsState> {
  @override
  AppSettingsState build() {
    _loadFromPrefs();
    return const AppSettingsState();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_mode') ?? 0;
    final arabicSize = prefs.getDouble('arabic_font_size') ?? 28.0;
    final uyghurSize = prefs.getDouble('uyghur_font_size') ?? 16.5;
    final showTrans = prefs.getBool('show_translation') ?? true;
    final reciterId = prefs.getString('reciter_id') ?? 'alafasy';
    final savedCityName = prefs.getString('city_name');
    final savedCountryName = prefs.getString('city_country') ?? '';
    final savedLat = prefs.getDouble('city_lat');
    final savedLon = prefs.getDouble('city_lon');
    final isAuto = prefs.getBool('city_is_auto') ?? true;
    final hanafi = prefs.getBool('is_hanafi') ?? true;
    final savedBookmarks = prefs.getStringList('bookmarks')?.toSet() ?? {};
    final lastSurah = prefs.getInt('last_read_surah') ?? 1;
    final lastVerse = prefs.getInt('last_read_verse') ?? 1;

    final reciter = Reciter.defaultReciters.firstWhere(
      (r) => r.id == reciterId,
      orElse: () => Reciter.defaultReciters.first,
    );

    CityLocation city = QiblaUtils.defaultCity;
    if (savedCityName != null && savedLat != null && savedLon != null) {
      city = CityLocation(
        nameUyghur: savedCityName,
        countryUyghur: savedCountryName,
        latitude: savedLat,
        longitude: savedLon,
        isAutoDetected: isAuto,
      );
    }

    state = state.copyWith(
      themeMode: ThemeMode.values[themeIndex.clamp(0, 2)],
      arabicFontSize: arabicSize,
      uyghurFontSize: uyghurSize,
      showTranslation: showTrans,
      selectedReciter: reciter,
      selectedCity: city,
      isHanafi: hanafi,
      bookmarks: savedBookmarks,
      lastReadSurahId: lastSurah,
      lastReadVerseNumber: lastVerse,
    );

    // Auto-detect location automatically on startup if no manual city was locked
    if (isAuto || savedCityName == null) {
      autoDetectLocation();
    }
  }

  Future<void> autoDetectLocation({bool force = false}) async {
    state = state.copyWith(isDetectingLocation: true);
    try {
      final detected = await QiblaUtils.detectLocationFromIp();
      if (detected != null) {
        state = state.copyWith(
          selectedCity: detected,
          isDetectingLocation: false,
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('city_name', detected.nameUyghur);
        await prefs.setString('city_country', detected.countryUyghur);
        await prefs.setDouble('city_lat', detected.latitude);
        await prefs.setDouble('city_lon', detected.longitude);
        await prefs.setBool('city_is_auto', true);
      } else {
        state = state.copyWith(isDetectingLocation: false);
      }
    } catch (_) {
      state = state.copyWith(isDetectingLocation: false);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
  }

  Future<void> setArabicFontSize(double size) async {
    state = state.copyWith(arabicFontSize: size);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('arabic_font_size', size);
  }

  Future<void> setUyghurFontSize(double size) async {
    state = state.copyWith(uyghurFontSize: size);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('uyghur_font_size', size);
  }

  Future<void> toggleShowTranslation(bool value) async {
    state = state.copyWith(showTranslation: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_translation', value);
  }

  Future<void> setReciter(Reciter reciter) async {
    state = state.copyWith(selectedReciter: reciter);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reciter_id', reciter.id);
  }

  Future<void> setCity(CityLocation city) async {
    state = state.copyWith(selectedCity: city);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('city_name', city.nameUyghur);
    await prefs.setString('city_country', city.countryUyghur);
    await prefs.setDouble('city_lat', city.latitude);
    await prefs.setDouble('city_lon', city.longitude);
    await prefs.setBool('city_is_auto', city.isAutoDetected);
  }

  Future<void> setHanafi(bool value) async {
    state = state.copyWith(isHanafi: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_hanafi', value);
  }

  Future<void> saveLastRead(int surahId, int verseNumber) async {
    state = state.copyWith(
      lastReadSurahId: surahId,
      lastReadVerseNumber: verseNumber,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_read_surah', surahId);
    await prefs.setInt('last_read_verse', verseNumber);
  }

  Future<void> toggleBookmark({
    required Surah surah,
    required Ayah ayah,
  }) async {
    final prefix = '${surah.id}:${ayah.verseNumber}|';
    final updated = Set<String>.from(state.bookmarks);
    final existing = updated
        .where((b) => b.startsWith(prefix) || b == '${surah.id}:${ayah.verseNumber}')
        .toList();

    if (existing.isNotEmpty) {
      updated.removeAll(existing);
    } else {
      final preview = ayah.uyghurTranslation.isNotEmpty
          ? ayah.uyghurTranslation
          : ayah.textUthmani;
      updated.add('${surah.id}:${ayah.verseNumber}|${surah.nameUyghur}|$preview');
    }

    state = state.copyWith(bookmarks: updated);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('bookmarks', updated.toList());
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettingsState>(
  AppSettingsNotifier.new,
);

final surahAyahsProvider =
    FutureProvider.family<List<Ayah>, int>((ref, surahId) async {
  final repo = ref.watch(quranRepositoryProvider);
  return repo.getSurahAyahs(surahId);
});

final prayerTimesProvider = FutureProvider<PrayerTimesData>((ref) async {
  final settings = ref.watch(appSettingsProvider);
  final repo = ref.watch(prayerRepositoryProvider);
  return repo.getPrayerTimes(
    latitude: settings.selectedCity.latitude,
    longitude: settings.selectedCity.longitude,
    cityName: settings.selectedCity.nameUyghur,
    isHanafi: settings.isHanafi,
  );
});

class AudioPlaybackState {
  final Surah? currentSurah;
  final int? currentVerseNumber;
  final List<Ayah> currentPlaylist;
  final bool isPlaying;
  final bool isLoading;
  final bool repeatCurrentAyah;
  final double playbackSpeed;
  final String? errorMessage;

  const AudioPlaybackState({
    this.currentSurah,
    this.currentVerseNumber,
    this.currentPlaylist = const [],
    this.isPlaying = false,
    this.isLoading = false,
    this.repeatCurrentAyah = false,
    this.playbackSpeed = 1.0,
    this.errorMessage,
  });

  AudioPlaybackState copyWith({
    Surah? currentSurah,
    int? currentVerseNumber,
    List<Ayah>? currentPlaylist,
    bool? isPlaying,
    bool? isLoading,
    bool? repeatCurrentAyah,
    double? playbackSpeed,
    String? errorMessage,
  }) {
    return AudioPlaybackState(
      currentSurah: currentSurah ?? this.currentSurah,
      currentVerseNumber: currentVerseNumber ?? this.currentVerseNumber,
      currentPlaylist: currentPlaylist ?? this.currentPlaylist,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      repeatCurrentAyah: repeatCurrentAyah ?? this.repeatCurrentAyah,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      errorMessage: errorMessage,
    );
  }
}

class AudioControllerNotifier extends Notifier<AudioPlaybackState> {
  AudioPlayer? _player;
  bool _isTransitioning = false;

  @override
  AudioPlaybackState build() {
    _initPlayer();
    ref.onDispose(() {
      _player?.dispose();
    });
    return const AudioPlaybackState();
  }

  void _initPlayer() {
    _player = AudioPlayer();
    _player!.playerStateStream.listen((playerState) {
      final playing = playerState.playing;
      final processing = playerState.processingState;

      if (processing == ProcessingState.completed) {
        _onAyahFinished();
      } else {
        state = state.copyWith(
          isPlaying: playing,
          isLoading: processing == ProcessingState.loading ||
              processing == ProcessingState.buffering,
        );
      }
    });
  }

  Future<void> _onAyahFinished() async {
    if (_isTransitioning) return;
    _isTransitioning = true;

    try {
      if (state.repeatCurrentAyah &&
          state.currentSurah != null &&
          state.currentVerseNumber != null) {
        await playAyah(
          surah: state.currentSurah!,
          verseNumber: state.currentVerseNumber!,
          playlist: state.currentPlaylist,
        );
        return;
      }

      final surah = state.currentSurah;
      final currentVerse = state.currentVerseNumber ?? 1;

      if (surah != null && currentVerse < surah.versesCount) {
        // Automatically advance to the next Ayah continuously
        await playAyah(
          surah: surah,
          verseNumber: currentVerse + 1,
          playlist: state.currentPlaylist,
        );
      } else if (surah != null && surah.id < 114) {
        // Surah complete -> seamlessly advance to the next Surah!
        final nextSurah =
            Surah.allSurahs.firstWhere((s) => s.id == surah.id + 1);
        final nextAyahs = await ref
            .read(quranRepositoryProvider)
            .getSurahAyahs(nextSurah.id);
        await playAyah(
          surah: nextSurah,
          verseNumber: 1,
          playlist: nextAyahs,
        );
      } else {
        state = state.copyWith(isPlaying: false, isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(isPlaying: false, isLoading: false);
    } finally {
      _isTransitioning = false;
    }
  }

  Future<void> playAyah({
    required Surah surah,
    required int verseNumber,
    required List<Ayah> playlist,
  }) async {
    try {
      final settings = ref.read(appSettingsProvider);

      List<Ayah> activePlaylist = playlist;
      if (activePlaylist.isEmpty) {
        activePlaylist =
            await ref.read(quranRepositoryProvider).getSurahAyahs(surah.id);
      }

      final ayah = activePlaylist.firstWhere(
        (a) => a.verseNumber == verseNumber,
        orElse: () => Ayah(
          id: verseNumber,
          surahNumber: surah.id,
          verseNumber: verseNumber,
          verseKey: '${surah.id}:$verseNumber',
          textUthmani: '',
          uyghurTranslation: '',
        ),
      );

      state = state.copyWith(
        currentSurah: surah,
        currentVerseNumber: verseNumber,
        currentPlaylist: activePlaylist,
        isLoading: true,
        errorMessage: null,
      );

      ref
          .read(appSettingsProvider.notifier)
          .saveLastRead(surah.id, verseNumber);

      final url = ayah.getAudioUrl(settings.selectedReciter.everyAyahFolder);
      if (_player == null) _initPlayer();
      await _player?.stop();
      await _player?.seek(Duration.zero);
      await _player?.setUrl(url);
      await _player?.setSpeed(state.playbackSpeed);
      await _player?.play();
    } catch (e) {
      state = state.copyWith(
        isPlaying: false,
        isLoading: false,
        errorMessage: 'ئاۋاز ھۆججىتىنى قويۇشتا خاتالىق كۆرۈلدى.',
      );
    }
  }

  Future<void> togglePlayPause() async {
    if (_player == null) return;
    if (state.isPlaying) {
      await _player!.pause();
    } else {
      await _player!.play();
    }
  }

  Future<void> playNext() async {
    if (state.currentSurah == null || state.currentVerseNumber == null) return;
    final nextVerse = state.currentVerseNumber! + 1;
    if (nextVerse <= state.currentSurah!.versesCount) {
      await playAyah(
        surah: state.currentSurah!,
        verseNumber: nextVerse,
        playlist: state.currentPlaylist,
      );
    } else if (state.currentSurah!.id < 114) {
      final nextSurah =
          Surah.allSurahs.firstWhere((s) => s.id == state.currentSurah!.id + 1);
      final nextAyahs = await ref
          .read(quranRepositoryProvider)
          .getSurahAyahs(nextSurah.id);
      await playAyah(
        surah: nextSurah,
        verseNumber: 1,
        playlist: nextAyahs,
      );
    }
  }

  Future<void> playPrevious() async {
    if (state.currentSurah == null || state.currentVerseNumber == null) return;
    final prevVerse = state.currentVerseNumber! - 1;
    if (prevVerse >= 1) {
      await playAyah(
        surah: state.currentSurah!,
        verseNumber: prevVerse,
        playlist: state.currentPlaylist,
      );
    } else if (state.currentSurah!.id > 1) {
      final prevSurah =
          Surah.allSurahs.firstWhere((s) => s.id == state.currentSurah!.id - 1);
      final prevAyahs = await ref
          .read(quranRepositoryProvider)
          .getSurahAyahs(prevSurah.id);
      await playAyah(
        surah: prevSurah,
        verseNumber: prevSurah.versesCount,
        playlist: prevAyahs,
      );
    }
  }

  void toggleRepeatAyah() {
    state = state.copyWith(repeatCurrentAyah: !state.repeatCurrentAyah);
  }

  Future<void> cycleSpeed() async {
    const speeds = [0.75, 1.0, 1.25, 1.5];
    final idx = speeds.indexOf(state.playbackSpeed);
    final nextSpeed = speeds[(idx + 1) % speeds.length];
    state = state.copyWith(playbackSpeed: nextSpeed);
    await _player?.setSpeed(nextSpeed);
  }

  Future<void> stop() async {
    await _player?.stop();
    state = const AudioPlaybackState();
  }
}

final audioControllerProvider =
    NotifierProvider<AudioControllerNotifier, AudioPlaybackState>(
  AudioControllerNotifier.new,
);
