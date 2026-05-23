/**
 * restore_firestore.js
 * 從本地備份 JSON 檔案還原 Firestore 資料
 *
 * 使用方式:
 *   node restore_firestore.js --from data/backup_20260523_090000
 *
 * ⚠️ 警告: 此腳本會覆蓋 Firestore 內現有的同名文件，請謹慎使用！
 * 建議在還原前先手動備份一次現有資料。
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// ── 解析命令列參數 ──────────────────────────────────────
const args = process.argv.slice(2);
const fromIndex = args.indexOf('--from');
if (fromIndex === -1 || !args[fromIndex + 1]) {
  console.error('❌ 請指定備份目錄，例如: node restore_firestore.js --from data/backup_20260523_090000');
  process.exit(1);
}
const backupDirRelative = args[fromIndex + 1];
const backupDir = path.resolve(__dirname, '..', backupDirRelative);

if (!fs.existsSync(backupDir)) {
  console.error(`❌ 備份目錄不存在: ${backupDir}`);
  process.exit(1);
}

// ── 初始化 Firebase Admin ──────────────────────────────
if (!admin.apps.length) {
  const serviceAccount = require('./serviceAccountKey.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

// ── 還原單一 Collection ──────────────────────────────────
async function restoreCollection(collectionName, filePath) {
  if (!fs.existsSync(filePath)) {
    console.log(`  ⚠️  ${collectionName}: 備份檔不存在，跳過`);
    return 0;
  }

  const docs = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  const docIds = Object.keys(docs);

  if (docIds.length === 0) {
    console.log(`  ⚠️  ${collectionName}: 備份為空，跳過`);
    return 0;
  }

  // 每 500 筆一批（Firestore batch 上限）
  const BATCH_SIZE = 400;
  let count = 0;

  for (let i = 0; i < docIds.length; i += BATCH_SIZE) {
    const batch = db.batch();
    const chunk = docIds.slice(i, i + BATCH_SIZE);

    chunk.forEach((docId) => {
      const docRef = db.collection(collectionName).doc(docId);
      batch.set(docRef, docs[docId], { merge: true });
    });

    await batch.commit();
    count += chunk.length;
  }

  console.log(`  ✅ ${collectionName}: ${count} 筆還原完成`);
  return count;
}

async function restore() {
  // 讀取 metadata
  const metaPath = path.join(backupDir, '_metadata.json');
  const meta = fs.existsSync(metaPath)
    ? JSON.parse(fs.readFileSync(metaPath, 'utf8'))
    : null;

  console.log(`\n📂 從備份目錄還原: ${backupDir}`);
  if (meta) {
    console.log(`📅 備份時間: ${meta.backupAt}`);
    console.log(`📊 預計還原: ${meta.totalDocuments} 筆文件\n`);
  }

  // 取得目錄中所有 .json 檔（排除 _metadata.json）
  const files = fs.readdirSync(backupDir)
    .filter((f) => f.endsWith('.json') && !f.startsWith('_'));

  let totalRestored = 0;
  for (const file of files) {
    const collectionName = path.basename(file, '.json');
    const filePath = path.join(backupDir, file);
    totalRestored += await restoreCollection(collectionName, filePath);
  }

  console.log(`\n🎉 還原完成！共 ${totalRestored} 筆文件`);
}

restore().catch((err) => {
  console.error('❌ 還原失敗:', err);
  process.exit(1);
});
