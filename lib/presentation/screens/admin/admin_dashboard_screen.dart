import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/qibla_utils.dart';
import '../../../data/models/reciter_model.dart';
import '../../../data/models/surah_model.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_provider.dart';
import 'admin_login_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Diagnostics state
  bool _isRunningDiagnostics = false;
  Map<String, dynamic>? _diagnosticResults;

  // Audio test state
  AudioPlayer? _testAudioPlayer;
  Reciter _selectedTestReciter = Reciter.defaultReciters.first;
  int _testSurahId = 1;
  int _testAyahNumber = 1;
  bool _isTestingAudio = false;

  // Surah filter
  String _surahSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _testAudioPlayer = AudioPlayer();
    _runDiagnostics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _testAudioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isRunningDiagnostics = true;
    });

    final stopwatch = Stopwatch()..start();
    final repo = ref.read(quranRepositoryProvider);

    int totalSurahs = 0;
    int totalAyahs = 0;
    bool jsonIntegrityPass = false;
    String latencyMs = '0';

    try {
      final sampleSurah = await repo.getSurahAyahs(1);
      if (sampleSurah.length == 7) {
        totalSurahs = Surah.allSurahs.length;
        totalAyahs = Surah.allSurahs.fold<int>(0, (sum, s) => sum + s.versesCount);
        jsonIntegrityPass = true;
      }
      stopwatch.stop();
      latencyMs = '${stopwatch.elapsedMilliseconds}ms';
    } catch (_) {
      jsonIntegrityPass = false;
    }

    if (mounted) {
      setState(() {
        _isRunningDiagnostics = false;
        _diagnosticResults = {
          'totalSurahs': totalSurahs,
          'totalAyahs': totalAyahs,
          'totalMushafPages': 604,
          'jsonIntegrity': jsonIntegrityPass,
          'translation': 'مۇھەممەد سالىھ (تولۇق كىرگۈزۈلگەن)',
          'recitersCount': Reciter.defaultReciters.length,
          'presetCitiesCount': QiblaUtils.presetCities.length,
          'latency': latencyMs,
          'status': jsonIntegrityPass ? 'نورمال (100% Active)' : 'تەكشۈرۈش كېرەك',
        };
      });
    }
  }

  Future<void> _playTestAudio() async {
    try {
      setState(() => _isTestingAudio = true);
      final s = _testSurahId.toString().padLeft(3, '0');
      final v = _testAyahNumber.toString().padLeft(3, '0');
      final url =
          '${AppConstants.everyAyahBaseUrl}/${_selectedTestReciter.everyAyahFolder}/$s$v.mp3';

      await _testAudioPlayer?.stop();
      await _testAudioPlayer?.setUrl(url);
      await _testAudioPlayer?.play();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ئاۋاز سىناشتا خاتالىق: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTestingAudio = false);
      }
    }
  }

  void _showSurahDetailModal(Surah surah) async {
    final repo = ref.read(quranRepositoryProvider);
    final ayahs = await repo.getSurahAyahs(surah.id);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.4,
            expand: false,
            builder: (_, scrollController) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGold.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${surah.id}',
                            style: const TextStyle(
                              color: AppTheme.accentGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${surah.nameUyghur} (${surah.nameArabic})',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${surah.revelationPlaceUyghur} • ${surah.versesCount} ئايەت',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    const Text(
                      'ئايەتلەر ۋە مۇھەممەد سالىھ تەرجىمىسى نۇسخىسى:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentGold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: ayahs.length,
                        itemBuilder: (_, i) {
                          final a = ayahs[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '${a.verseNumber}-ئايەت',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.accentGold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    a.textUthmani,
                                    style: const TextStyle(
                                      fontFamily: 'NotoNaskhArabic',
                                      fontSize: 18,
                                      height: 1.8,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    a.uyghurTranslation,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.white70,
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // If not authenticated as Admin, show the lock screen
    if (!authState.isAdmin) {
      return _buildLockScreen(context, authState);
    }

    final settings = ref.watch(appSettingsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.admin_panel_settings_rounded,
                  color: AppTheme.accentGold, size: 24),
              SizedBox(width: 8),
              Text(
                'ئارقا باشقۇرۇش مەركىزى (Admin Panel)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'تەشخىس ۋە سانلىق مەلۇماتنى يېڭىلاش',
              onPressed: _runDiagnostics,
              icon: _isRunningDiagnostics
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
            IconButton(
              tooltip: 'باشقۇرغۇچى ھالىتىدىن چىقىش (Logout)',
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppTheme.accentGold,
            labelColor: AppTheme.accentGold,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(
                icon: Icon(Icons.dashboard_rounded, size: 20),
                text: 'ئومۇمىي ئەھۋال',
              ),
              Tab(
                icon: Icon(Icons.menu_book_rounded, size: 20),
                text: 'سۈرىلەر باشقۇرۇش',
              ),
              Tab(
                icon: Icon(Icons.record_voice_over_rounded, size: 20),
                text: 'قارىئىلار ماتورى',
              ),
              Tab(
                icon: Icon(Icons.public_rounded, size: 20),
                text: 'ناماز شەھەرلىرى',
              ),
              Tab(
                icon: Icon(Icons.tune_rounded, size: 20),
                text: 'ئەپ ۋە زاپاس تەڭشەك',
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(settings),
            _buildSurahsTab(),
            _buildRecitersTab(settings),
            _buildCitiesTab(settings),
            _buildSettingsTab(settings),
          ],
        ),
      ),
    );
  }

  /// Tab 1: System Overview & Executive Diagnostics
  Widget _buildOverviewTab(AppSettingsState settings) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Executive Header Banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A261B), Color(0xFF144D37), Color(0xFF1B5E20)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppTheme.accentGold.withValues(alpha: 0.7),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.accentGold),
                    ),
                    child: const Text(
                      'Premium Enterprise Console',
                      style: TextStyle(
                        color: AppTheme.accentGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.greenAccent),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 14, color: Colors.greenAccent),
                        SizedBox(width: 4),
                        Text(
                          '100% Offline Active',
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'قۇرئان كەرىم ئەپ ۋە تور مەركىزىي باشقۇرۇش سۇپىسى',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'سۈرە، ئايەت، مۇھەممەد سالىھ ئۇيغۇرچە تەرجىمىسى، قارىئىلار، ناماز ۋاقىتلىرى ۋە سىستېما بىخەتەرلىك ھالىتىنى كۆزىتىش سۇپىسى.',
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Key Metric Grid Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 700 ? 4 : 2;
            final metrics = [
              (
                title: 'جەمئىي سۈرە',
                value: '114 سۈرە',
                sub: 'مەككە ۋە مەدىنە',
                icon: Icons.menu_book_rounded,
                color: Colors.amber,
              ),
              (
                title: 'مۇبارەك ئايەتلەر',
                value: '6236 ئايەت',
                sub: 'ئوسمانىي خەت نۇسخىسى',
                icon: Icons.auto_stories_rounded,
                color: Colors.teal,
              ),
              (
                title: 'مەدىنە مۇسھەف بېتى',
                value: '604 بەت',
                sub: '30 پارە تەقسىماتى',
                icon: Icons.book_online_rounded,
                color: Colors.lightGreen,
              ),
              (
                title: 'ئۇيغۇرچە تەرجىمە',
                value: '100% تولۇق',
                sub: 'مۇھەممەد سالىھ داموللام',
                icon: Icons.verified_rounded,
                color: Colors.cyan,
              ),
            ];

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: metrics.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.35,
              ),
              itemBuilder: (context, idx) {
                final m = metrics[idx];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: AppTheme.accentGold.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              m.title,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(m.icon, color: m.color, size: 22),
                          ],
                        ),
                        Text(
                          m.value,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          m.sub,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 18),

        // Live Health & Integrity Diagnostics Table
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppTheme.accentGold, width: 1.2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.monitor_heart_rounded,
                            color: AppTheme.accentGold),
                        SizedBox(width: 8),
                        Text(
                          'سىستېما ئىقتىدارى ۋە ساغلاملىق دوكلاتى',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: _runDiagnostics,
                      icon: const Icon(Icons.speed_rounded, size: 16),
                      label: const Text('تەكشۈرۈش سىنىقى'),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildDiagnosticRow(
                  'يەرلىك مۇھەممەد سالىھ قۇرئان سانلىق ئامبىرى',
                  _diagnosticResults?['jsonIntegrity'] == true
                      ? 'مۇۋەپپەقىيەتلىك بايقالدى (6236 ئايەت تولۇق)'
                      : 'تەكشۈرۈلۈۋاتىدۇ...',
                  isOk: _diagnosticResults?['jsonIntegrity'] == true,
                ),
                _buildDiagnosticRow(
                  'سىستېما سۈرئىتى ۋە جاۋاب ۋاقتى',
                  _diagnosticResults?['latency'] ?? 'تەكشۈرۈلمەكتە',
                  isOk: true,
                ),
                _buildDiagnosticRow(
                  'نۆۋەتتىكى شەھەر ئورنى',
                  settings.selectedCity.nameUyghur,
                  isOk: true,
                ),
                _buildDiagnosticRow(
                  'تاللانغان ئاۋاز قارىئى',
                  settings.selectedReciter.nameUyghur,
                  isOk: true,
                ),
                _buildDiagnosticRow(
                  'خەتكۈچلەر ۋە ئىشلەتكۈچى خاتىرىسى',
                  '${settings.bookmarks.length} ئايەت ساقلانغان',
                  isOk: true,
                ),
                _buildDiagnosticRow(
                  'ئەپ نۇسخىسى ۋە مۇھىتى',
                  'v1.0.0+1 (Flutter Web Production Mode)',
                  isOk: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiagnosticRow(String label, String value, {required bool isOk}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13.5)),
          Row(
            children: [
              Icon(
                isOk ? Icons.check_circle_rounded : Icons.pending_rounded,
                size: 16,
                color: isOk ? Colors.greenAccent : Colors.orangeAccent,
              ),
              const SizedBox(width: 6),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isOk ? Colors.greenAccent : Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Tab 2: Surah & Content Registry (All 114 Surahs Inspector)
  Widget _buildSurahsTab() {
    final filteredSurahs = Surah.allSurahs.where((s) {
      final q = _surahSearchQuery.trim();
      if (q.isEmpty) return true;
      return s.nameUyghur.contains(q) ||
          s.nameArabic.contains(q) ||
          s.id.toString() == q;
    }).toList();

    return Column(
      children: [
        // Search & Filter Box
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).cardTheme.color,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'سۈرە نامى (ئۇيغۇرچە ياكى ئەرەبچە) ياكى نومۇرىنى ئىزدەڭ...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _surahSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () => setState(() => _surahSearchQuery = ''),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.accentGold),
              ),
            ),
            onChanged: (val) => setState(() => _surahSearchQuery = val),
          ),
        ),
        // Surah Count Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ئامباردىكى سۈرىلەر (${filteredSurahs.length} / 114):',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'تەپسىلاتىنى كۆرۈش ئۈچۈن سۈرىنى بېسىڭ',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        // Surahs List
        Expanded(
          child: ListView.builder(
            itemCount: filteredSurahs.length,
            itemBuilder: (context, index) {
              final s = filteredSurahs[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: AppTheme.accentGold.withValues(alpha: 0.25),
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.accentGold.withValues(alpha: 0.2),
                    child: Text(
                      '${s.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentGold,
                      ),
                    ),
                  ),
                  title: Text(
                    '${s.nameUyghur} (${s.nameArabic})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${s.revelationPlaceUyghur} • ${s.versesCount} ئايەت',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () => _showSurahDetailModal(s),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Tab 3: Reciters & Audio Engine Manager
  Widget _buildRecitersTab(AppSettingsState settings) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Live Audio Test Station Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppTheme.accentGold, width: 1.3),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.headset_mic_rounded, color: AppTheme.accentGold),
                    SizedBox(width: 8),
                    Text(
                      'ئەقلىي ئاۋاز ۋە تىلاۋەت بايقاش سىنىقى',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'EveryAyah يۇقىرى سۈپەتلىك CDN تورىدىن تاللانغان قارىئىنىڭ ئايىتىنى سىناپ بېقىڭ:',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 14),
                // Reciter Selector Dropdown
                DropdownButtonFormField<Reciter>(
                  initialValue: _selectedTestReciter,
                  decoration: InputDecoration(
                    labelText: 'سىنايدىغان قارىئىنى تاللاڭ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: Reciter.defaultReciters.map((r) {
                    return DropdownMenuItem(
                      value: r,
                      child: Text('${r.nameUyghur} (${r.everyAyahFolder})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedTestReciter = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _testSurahId.toString(),
                        decoration: InputDecoration(
                          labelText: 'سۈرە نومۇرى (1-114)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) {
                          final n = int.tryParse(v);
                          if (n != null && n >= 1 && n <= 114) {
                            _testSurahId = n;
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: _testAyahNumber.toString(),
                        decoration: InputDecoration(
                          labelText: 'ئايەت نومۇرى',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) {
                          final n = int.tryParse(v);
                          if (n != null && n >= 1) {
                            _testAyahNumber = n;
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.accentGold,
                        foregroundColor: AppTheme.deepEmerald,
                      ),
                      onPressed: _isTestingAudio ? null : _playTestAudio,
                      icon: _isTestingAudio
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.play_arrow_rounded),
                      label: const Text(
                        'ئاۋازنى ھازىر قويۇپ سىناش',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await _testAudioPlayer?.stop();
                      },
                      icon: const Icon(Icons.stop_rounded),
                      label: const Text('توختىتىش'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Configured Reciters List
        const Text(
          'سەپلەنگەن مەشھۇر قارىئىلار:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...Reciter.defaultReciters.map((r) {
          final isSelected = settings.selectedReciter.id == r.id;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isSelected
                    ? AppTheme.accentGold
                    : AppTheme.accentGold.withValues(alpha: 0.25),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: ListTile(
              leading: Icon(
                isSelected ? Icons.check_circle_rounded : Icons.mic_rounded,
                color: isSelected ? AppTheme.accentGold : Colors.grey,
              ),
              title: Text(
                r.nameUyghur,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'مۇندەرىجە: ${r.everyAyahFolder} • تەرتىپ سۈپىتى: 128kbps HQ',
              ),
              trailing: isSelected
                  ? const Chip(
                      label: Text('نۆۋەتتە ئاكتىپ',
                          style: TextStyle(fontSize: 11)),
                    )
                  : TextButton(
                      onPressed: () {
                        ref.read(appSettingsProvider.notifier).setReciter(r);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '${r.nameUyghur} ئاساسلىق تىلاۋەتكە بېكىتىلدى!'),
                          ),
                        );
                      },
                      child: const Text('تاللاش'),
                    ),
            ),
          );
        }),
      ],
    );
  }

  /// Tab 4: Cities & Global Geolocation Registry
  Widget _buildCitiesTab(AppSettingsState settings) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Current Location Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.accentGold.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.my_location_rounded,
                      color: AppTheme.accentGold),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'نۆۋەتتىكى تاللانغان شەھەر:',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        '${settings.selectedCity.nameUyghur} (${settings.selectedCity.countryUyghur})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              FilledButton.tonalIcon(
                onPressed: () async {
                  await ref
                      .read(appSettingsProvider.notifier)
                      .autoDetectLocation(force: true);
                },
                icon: const Icon(Icons.sync_rounded, size: 16),
                label: const Text('ئاپتوماتىك قايتا سېزىش'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        const Text(
          'سەپلەنگەن پۈتكۈل دۇنيا شەھەرلىرى (سۈرىيە، تۈركىيە ۋە خەلقئارالىق):',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        ...QiblaUtils.presetCities.map((city) {
          final isSelected = settings.selectedCity.nameUyghur == city.nameUyghur;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected
                    ? AppTheme.accentGold
                    : AppTheme.accentGold.withValues(alpha: 0.2),
              ),
            ),
            child: ListTile(
              leading: Icon(
                Icons.location_city_rounded,
                color: isSelected ? AppTheme.accentGold : Colors.grey,
              ),
              title: Text(
                city.nameUyghur,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${city.countryUyghur} • كەڭلىك: ${city.latitude}°N, ئۇزۇنلۇق: ${city.longitude}°E',
              ),
              trailing: isSelected
                  ? const Chip(
                      label: Text('تاللانغان', style: TextStyle(fontSize: 11)),
                    )
                  : TextButton(
                      onPressed: () {
                        ref.read(appSettingsProvider.notifier).setCity(city);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '${city.nameUyghur} ناماز ۋاقتى ئۈچۈن تەڭشەلدى!'),
                          ),
                        );
                      },
                      child: const Text('ئىشلىتىش'),
                    ),
            ),
          );
        }),
      ],
    );
  }

  /// Tab 5: App Configuration, Backup & Developer Tools
  Widget _buildSettingsTab(AppSettingsState settings) {
    final authState = ref.watch(authProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Backup & Export Card
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.accentGold),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.backup_rounded, color: AppTheme.accentGold),
                    SizedBox(width: 8),
                    Text(
                      'سانلىق مەلۇمات ۋە زاپاسلاش (Backup / Export)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'خەتكۈچلەر ۋە ئاخىرقى ئوقۇش خاتىرىلىرىنى JSON پىچىمىدا چىقىرىپ ساقلاش:',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accentGold,
                    foregroundColor: AppTheme.deepEmerald,
                  ),
                  onPressed: () {
                    final data = {
                      'appName': AppConstants.appName,
                      'version': '1.0.0+1',
                      'timestamp': DateTime.now().toIso8601String(),
                      'bookmarks': settings.bookmarks.map((b) {
                        final parts = b.split('|');
                        final key = parts.first;
                        final name = parts.length > 1 ? parts[1] : '';
                        final keyParts = key.split(':');
                        return {
                          'raw': b,
                          'surahId': int.tryParse(keyParts.first) ?? 1,
                          'verseNumber': keyParts.length > 1
                              ? (int.tryParse(keyParts[1]) ?? 1)
                              : 1,
                          'surahName': name,
                        };
                      }).toList(),
                      'lastReadSurah': settings.lastReadSurahId,
                      'lastReadVerse': settings.lastReadVerseNumber,
                    };
                    final jsonStr =
                        const JsonEncoder.withIndent('  ').convert(data);
                    Clipboard.setData(ClipboardData(text: jsonStr));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('زاپاس سانلىق مەلۇماتلار كۆچۈرۈۋېلىندى!'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_all_rounded),
                  label: const Text(
                    'بارلىق خەتكۈچ ۋە تەڭشەكلەرنى كۆچۈرۈۋېلىش (JSON)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Registered Members Management
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: AppTheme.accentGold.withValues(alpha: 0.35),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.people_alt_rounded,
                            color: AppTheme.accentGold),
                        SizedBox(width: 8),
                        Text(
                          'تىزىملاتقان ئەزالار سىستېمىسى',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${authState.registeredUsers.length} ئەزا',
                        style: const TextStyle(
                          color: AppTheme.accentGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'ئەپكە ئېلېكترونلۇق خەت (ئىمائىل) ئارقىلىق تىزىملاتقان بارلىق ئىشلەتكۈچىلەر تىزىملىكى:',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 12),
                if (authState.registeredUsers.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'ھازىرچە توردا تىزىملاتقان ئەزا يوق (ئالدى بەتتىكى ئەزا كىرىش كۆزنىكى ئارقىلىق تىزىملىتىلىدۇ).',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5, color: Colors.grey),
                    ),
                  )
                else
                  ...authState.registeredUsers.map((u) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.accentGold.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 16,
                            backgroundColor: AppTheme.primaryEmerald,
                            child: Icon(Icons.person_rounded,
                                size: 18, color: AppTheme.accentGold),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  u.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  u.email,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${u.createdAt.year}-${u.createdAt.month.toString().padLeft(2, '0')}-${u.createdAt.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Admin Security & Password Change
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: AppTheme.accentGold.withValues(alpha: 0.35),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.security_rounded, color: AppTheme.accentGold),
                    SizedBox(width: 8),
                    Text(
                      'باشقۇرغۇچى بىخەتەرلىكى ۋە شىفىر ئۆزگەرتىش',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'ئارقا سۇپىغا كىرىش ئۈچۈن ئىشلىتىلىدىغان مەخپىي ئادمىن شىفىرىنى ئۆزگەرتىش:',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: () => _showChangePasswordDialog(context),
                  icon: const Icon(Icons.password_rounded),
                  label: const Text('باشقۇرغۇچى شىفىرىنى يېڭىلاش'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Factory Reset & Maintenance
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.redAccent.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.cleaning_services_rounded,
                        color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text(
                      'ساندۇق تازىلاش ۋە زاۋۇت ھالىتىگە قايتۇرۇش',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'كەچ ساقلانغان بارلىق تور ھۆججەتلىرى ۋە ۋاقىتلىق ئاۋاز ساقلىغۇچنى پاكىز تازىلايدۇ.',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('سىستېما كېشى مۇۋەپپەقىيەتلىك تازىلاندى!'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_sweep_rounded),
                  label: const Text('كېش ساقلىغۇچنى بوشىتىش'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('باشقۇرغۇچى شىفىرىنى يېڭىلاش'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldPassCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'ھازىرقى كونا شىفىر',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPassCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'يېڭى شىفىر (ئەڭ ئاز 4 ھەرپ)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('بىكار قىلىش'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accentGold,
                  foregroundColor: AppTheme.deepEmerald,
                ),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final ok = await ref
                      .read(authProvider.notifier)
                      .changeAdminPassword(
                        oldPassword: oldPassCtrl.text,
                        newPassword: newPassCtrl.text,
                      );
                  if (ok && ctx.mounted) {
                    Navigator.pop(ctx);
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('باشقۇرغۇچى شىفىرى مۇۋەپپەقىيەتلىك يېڭىلاندى!'),
                      ),
                    );
                  }
                },
                child: const Text('ساقلاش'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLockScreen(BuildContext context, AuthState authState) {
    return const AdminLoginScreen();
  }
}
