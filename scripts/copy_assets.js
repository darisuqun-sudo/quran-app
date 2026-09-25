const fs = require('fs');
const path = require('path');

const brainDir = 'C:\\Users\\Administrator\\.gemini\\antigravity\\brain\\8c464925-2b46-4654-a715-6ec411f9ff39';
const destDir = 'c:\\Users\\Administrator\\OneDrive\\Desktop\\New folder (2)\\quran_app\\assets\\images';

if (!fs.existsSync(destDir)) {
  fs.mkdirSync(destDir, { recursive: true });
}

const files = fs.readdirSync(brainDir);

function findLatest(prefix) {
  const matches = files.filter(f => f.startsWith(prefix) && f.endsWith('.jpg'));
  matches.sort((a, b) => {
    return fs.statSync(path.join(brainDir, b)).mtimeMs - fs.statSync(path.join(brainDir, a)).mtimeMs;
  });
  return matches[0] ? path.join(brainDir, matches[0]) : null;
}

const mapping = {
  'feature_quran.jpg': findLatest('feature_quran_surah_'),
  'feature_prayer.jpg': findLatest('feature_prayer_times_'),
  'feature_qibla.jpg': findLatest('feature_qibla_compass_'),
  'feature_bookmarks.jpg': findLatest('feature_bookmarks_'),
  'feature_search.jpg': findLatest('feature_search_quran_'),
  'feature_reciter.jpg': findLatest('feature_reciter_settings_'),
};

for (const [targetName, srcPath] of Object.entries(mapping)) {
  if (srcPath && fs.existsSync(srcPath)) {
    const destPath = path.join(destDir, targetName);
    fs.copyFileSync(srcPath, destPath);
    console.log(`Copied ${path.basename(srcPath)} -> ${targetName} (${fs.statSync(destPath).size} bytes)`);
  } else {
    console.error(`Missing source for ${targetName}`);
  }
}
