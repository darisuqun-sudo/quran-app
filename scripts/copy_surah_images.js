const fs = require('fs');
const path = require('path');

const brainDir = 'C:\\Users\\Administrator\\.gemini\\antigravity\\brain\\8c464925-2b46-4654-a715-6ec411f9ff39';
const destDirs = [
  'c:\\Users\\Administrator\\OneDrive\\Desktop\\New folder (2)\\quran_app\\assets\\images',
  'c:\\Users\\Administrator\\OneDrive\\Desktop\\New folder (2)\\quran_app\\build\\web\\assets\\assets\\images'
];

for (const dir of destDirs) {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

const files = fs.readdirSync(brainDir);

function findLatest(prefix) {
  const matches = files.filter(f => f.startsWith(prefix) && f.endsWith('.jpg'));
  matches.sort((a, b) => {
    return fs.statSync(path.join(brainDir, b)).mtimeMs - fs.statSync(path.join(brainDir, a)).mtimeMs;
  });
  return matches[0] ? path.join(brainDir, matches[0]) : null;
}

const surahMap = {
  'surah_1.jpg': findLatest('surah_fatiha_'),
  'surah_36.jpg': findLatest('surah_yasin_'),
  'surah_18.jpg': findLatest('surah_kahf_'),
  'surah_67.jpg': findLatest('surah_mulk_'),
  'surah_55.jpg': findLatest('surah_rahman_'),
  'surah_56.jpg': findLatest('surah_waqiah_'),
  'surah_112.jpg': findLatest('surah_ikhlas_'),
  'surah_114.jpg': findLatest('surah_fatiha_'), // Fallback beautiful illuminated frame
};

for (const [targetName, srcPath] of Object.entries(surahMap)) {
  if (srcPath && fs.existsSync(srcPath)) {
    for (const d of destDirs) {
      const destPath = path.join(d, targetName);
      fs.copyFileSync(srcPath, destPath);
    }
    console.log(`Copied ${path.basename(srcPath)} -> ${targetName}`);
  }
}

console.log('All Surah image assets synchronized successfully!');
