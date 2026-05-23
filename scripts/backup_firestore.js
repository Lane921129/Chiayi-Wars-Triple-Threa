/**
 * backup_firestore.js
 * 將 Firestore 所有資料備份成本地 JSON 檔案
 *
 * 使用方式:
 *   node backup_firestore.js
 *
 * 輸出: ../data/backup_YYYYMMDD_HHMMSS/
 *   ├── users_public.json
 *   ├── missions.json
 *   ├── stores.json
 *   ├── point_logs.json
 *   ├── vouchers.json
 *   ├── route_sessions.json
 *   ├── achievements.json
 *   └── app_config.json
 *
 * ⚠️ 注意: users_private 含敏感資料，請妥善保存備份檔案。
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

if (!admin.apps.length) {
  const serviceAccount = require('./serviceAccountKey.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

// 備份的 Collection 清單（排除 users_private 可視需求自行加入）
const COLLECTIONS_TO_BACKUP = [
  'users_public',
  'missions',
  'stores',
  'point_logs',
  'vouchers',
  'route_sessions',
  'achievements',
  'user_achievements',
  'app_config',
];

// 產生備份目錄名稱
function getBackupDirName() {
  const now = new Date();
  const pad = (n) => String(n).padStart(2, '0');
  const dateStr = `${now.getFullYear()}${pad(now.getMonth() + 1)}${pad(now.getDate())}`;
  const timeStr = `${pad(now.getHours())}${pad(now.getMinutes())}${pad(now.getSeconds())}`;
  return `backup_${dateStr}_${timeStr}`;
}

async function backupCollection(collectionName, outputDir) {
  const snapshot = await db.collection(collectionName).get();

  if (snapshot.empty) {
    console.log(`  ⚠️  ${collectionName}: 無資料，跳過`);
    return 0;
  }

  const docs = {};
  snapshot.forEach((doc) => {
    docs[doc.id] = doc.data();
  });

  const outputPath = path.join(outputDir, `${collectionName}.json`);
  fs.writeFileSync(outputPath, JSON.stringify(docs, null, 2), 'utf8');
  console.log(`  ✅ ${collectionName}: ${snapshot.size} 筆 → ${outputPath}`);
  return snapshot.size;
}

async function backup() {
  const backupDirName = getBackupDirName();
  const backupDir = path.join(__dirname, '../data', backupDirName);

  fs.mkdirSync(backupDir, { recursive: true });
  console.log(`\n📂 備份目錄: ${backupDir}\n`);

  let totalDocs = 0;
  for (const col of COLLECTIONS_TO_BACKUP) {
    totalDocs += await backupCollection(col, backupDir);
  }

  // 寫入備份 metadata
  const meta = {
    backupAt: new Date().toISOString(),
    collections: COLLECTIONS_TO_BACKUP,
    totalDocuments: totalDocs,
  };
  fs.writeFileSync(
    path.join(backupDir, '_metadata.json'),
    JSON.stringify(meta, null, 2),
    'utf8'
  );

  console.log(`\n🎉 備份完成！共 ${totalDocs} 筆文件`);
  console.log(`📁 備份位置: data/${backupDirName}/`);
}

backup().catch((err) => {
  console.error('❌ 備份失敗:', err);
  process.exit(1);
});
