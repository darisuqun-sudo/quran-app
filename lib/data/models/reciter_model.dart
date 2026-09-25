class Reciter {
  final String id;
  final String nameUyghur;
  final String nameArabic;
  final String styleUyghur;
  final String everyAyahFolder;

  const Reciter({
    required this.id,
    required this.nameUyghur,
    required this.nameArabic,
    required this.styleUyghur,
    required this.everyAyahFolder,
  });

  static const List<Reciter> defaultReciters = [
    Reciter(
      id: 'alafasy',
      nameUyghur: 'مىشارى راشىد ئەلئەفاسى',
      nameArabic: 'مشاري راشد العفاسي',
      styleUyghur: 'مۇرەتتەل (ئېنىق ۋە راۋان)',
      everyAyahFolder: 'Alafasy_128kbps',
    ),
    Reciter(
      id: 'husary',
      nameUyghur: 'مەھمۇد خەلىل ئەلھۇسەرى',
      nameArabic: 'محمود خليل الحصري',
      styleUyghur: 'مۇرەتتەل (تەجۋىد ئۆگىنىش ئۈچۈن)',
      everyAyahFolder: 'Husary_128kbps',
    ),
    Reciter(
      id: 'abdulbasit',
      nameUyghur: 'ئابدۇلباسىت ئابدۇسسەمەد',
      nameArabic: 'عبد الباسط عبد الصمد',
      styleUyghur: 'مۇرەتتەل',
      everyAyahFolder: 'Abdul_Basit_Murattal_192kbps',
    ),
    Reciter(
      id: 'sudais',
      nameUyghur: 'ئابدۇراھمان سۇدەيس',
      nameArabic: 'عبدالرحمن السديس',
      styleUyghur: 'ھەرەم ئىمامى تىلاۋىتى',
      everyAyahFolder: 'Abdurrahmaan_As-Sudais_192kbps',
    ),
  ];
}
