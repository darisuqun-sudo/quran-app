import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/ayah_model.dart';
import '../../../data/models/surah_model.dart';
import '../../providers/app_providers.dart';
import '../reader/reader_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  List<({Surah surah, Ayah ayah})> _results = [];
  String _lastQuery = '';

  static const List<String> _suggestedKeywords = [
    'رەھمەت',
    'سەۋر',
    'جەننەت',
    'ناماز',
    'تەقۋا',
    'دۇئا',
    'ئىلىم',
    'مەغپىرەت',
  ];

  Future<void> _performSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;

    setState(() {
      _isLoading = true;
      _lastQuery = q;
    });

    final repo = ref.read(quranRepositoryProvider);
    final res = await repo.searchVerses(q);

    if (mounted) {
      setState(() {
        _results = res;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('قۇرئان ۋە تەرجىمىدىن ئىزدەش'),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                onSubmitted: _performSearch,
                decoration: InputDecoration(
                  hintText: 'ئۇيغۇرچە سۆز ياكى ئەرەبچە ئايەت كىرگۈزۈڭ...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: FilledButton(
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _performSearch(_controller.text),
                    child: const Text('ئىزدەش'),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestedKeywords.map((word) {
                  return ActionChip(
                    avatar: const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: Text(word),
                    onPressed: () {
                      _controller.text = word;
                      _performSearch(word);
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _lastQuery.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'قۇرئان كەرىمدىكى ئايەتلەرنى ۋە مۇھەممەد سالىھ ئۇيغۇرچە تەرجىمىسىنى ئاچقۇچلۇق سۆز ئارقىلىق ئىزدىيەلەيسىز.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        )
                      : _results.isEmpty
                          ? Center(
                              child: Text(
                                '«$_lastQuery» غا مۇناسىۋەتلىك نەتىجە تېپىلمىدى.',
                                style: const TextStyle(fontSize: 16),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _results.length,
                              itemBuilder: (context, index) {
                                final item = _results[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ReaderScreen(
                                            surah: item.surah,
                                            initialVerse: item.ayah.verseNumber,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.accentGold
                                                      .withValues(alpha: 0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  '${item.surah.nameUyghur} • ${item.ayah.verseNumber}-ئايەت',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                              const Icon(
                                                Icons.open_in_new_rounded,
                                                size: 18,
                                              ),
                                            ],
                                          ),
                                          if (item.ayah.textUthmani.isNotEmpty) ...[
                                            const SizedBox(height: 10),
                                            Text(
                                              item.ayah.textUthmani,
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(
                                                fontSize: 22,
                                                height: 1.8,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                          if (item.ayah.uyghurTranslation
                                              .isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              item.ayah.uyghurTranslation,
                                              style: const TextStyle(
                                                fontSize: 15.5,
                                                height: 1.65,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
