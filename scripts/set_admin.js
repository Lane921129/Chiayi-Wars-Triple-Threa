/**
 * set_admin.js
 * 透過 Email 將特定使用者設為管理員
 * 
 * 使用方式:
 *   node set_admin.js "admin@gmail.com"
 */

const admin = require('firebase-admin');

const email = process.argv[2];
if (!email) {
  console.error("❌ 請提供 Email，例如: node set_admin.js admin@gmail.com");
  process.exit(1);
}

// 初始化
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const auth = admin.auth();

async function setAdmin() {
  try {
    // 1. 透過 Email 找到用戶
    const userRecord = await auth.getUserByEmail(email);
    const uid = userRecord.uid;
    console.log(`✅ 找到用戶: ${email} (UID: ${uid})`);

    // 2. 寫入 users_private 設為管理員
    const privateRef = db.collection('users_private').doc(uid);
    await privateRef.set({
      email: email,
      isAdmin: true,
      lastLoginAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true }); // 使用 merge 避免覆蓋其他資料

    // 3. 確保 users_public 也存在
    const publicRef = db.collection('users_public').doc(uid);
    const publicDoc = await publicRef.get();
    if (!publicDoc.exists) {
      await publicRef.set({
        displayName: '管理員',
        avatarUrl: '',
        faction: 'red',
        factionJoinedAt: null,
        totalScore: 0,
        redScore: 0,
        greenScore: 0,
        blueScore: 0,
        totalRouteDistance: 0,
        completedMissions: [],
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log('✅ 已為管理員初始化公開資料 (users_public)');
    }

    console.log(`🎉 成功！已將 ${email} 設為管理員！`);
    console.log('請在 App 中使用該帳號登入。');

  } catch (error) {
    console.error('❌ 設定失敗:', error.message);
  } finally {
    process.exit(0);
  }
}

setAdmin();
