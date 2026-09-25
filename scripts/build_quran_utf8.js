const https = require('https');
const fs = require('fs');
const path = require('path');

function fetchJson(url) {
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      const chunks = [];
      res.on('data', (d) => chunks.push(d));
      res.on('end', () => {
        try {
          const raw = Buffer.concat(chunks).toString('utf8').replace(/^\uFEFF/, '');
          resolve(JSON.parse(raw));
        } catch (e) {
          reject(e);
        }
      });
    }).on('error', reject);
  });
}

async function main() {
  console.log('Fetching UTF-8 Quran Uthmani & Muhammad Saleh Uyghur translation...');
  const [arRes, ugRes] = await Promise.all([
    fetchJson('https://api.alquran.cloud/v1/quran/quran-uthmani'),
    fetchJson('https://api.alquran.cloud/v1/quran/ug.saleh'),
  ]);

  const surahs = {};
  const arSurahs = arRes.data.surahs;
  const ugSurahs = ugRes.data.surahs;

  for (let i = 0; i < arSurahs.length; i++) {
    const sAr = arSurahs[i];
    const sUg = ugSurahs[i];
    const sId = String(sAr.number);
    const verses = [];

    for (let j = 0; j < sAr.ayahs.length; j++) {
      const vAr = sAr.ayahs[j];
      const vUg = sUg.ayahs[j];
      verses.push({
        id: vAr.number,
        surahNumber: sAr.number,
        verseNumber: vAr.numberInSurah,
        verseKey: `${sAr.number}:${vAr.numberInSurah}`,
        textUthmani: vAr.text,
        uyghurTranslation: vUg.text,
        pageNumber: vAr.page,
        juzNumber: vAr.juz,
      });
    }
    surahs[sId] = verses;
  }

  const jsonStr = JSON.stringify(surahs);
  const target1 = path.join(__dirname, 'quran_app', 'assets', 'data', 'quran_uyghur_saleh.json');
  const target2 = path.join(__dirname, 'quran_app', 'build', 'web', 'assets', 'assets', 'data', 'quran_uyghur_saleh.json');

  fs.mkdirSync(path.dirname(target1), { recursive: true });
  fs.writeFileSync(target1, jsonStr, 'utf8');

  if (fs.existsSync(path.dirname(target2))) {
    fs.writeFileSync(target2, jsonStr, 'utf8');
  }

  // Verify sample output
  console.log('Sample Ayah 1:1 Arabic:', surahs['1'][0].textUthmani);
  console.log('Sample Ayah 1:1 Uyghur:', surahs['1'][0].uyghurTranslation);
  console.log('SUCCESS: UTF-8 quran_uyghur_saleh.json written to both assets and build/web!');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
