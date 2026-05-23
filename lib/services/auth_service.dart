import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // 取得當前用戶
  User? get currentUser => _auth.currentUser;

  // 監聽驗證狀態
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Google 登入
  Future<bool> signInWithGoogle() async {
    //  最新版規範：使用前必須先初始化
    await _googleSignIn.initialize();

    try {
      //  新版：必須透過 authorizationClient 額外要求權限來取得 accessToken
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      await _syncUserData(userCredential.user);
      return true; //  成功登入，回傳 true
    } catch (error) {
      print("Google 登入失敗: $error");
      return false;
    }
  }
  // 匿名登入 (給不想綁定 Google 的人)
  Future<bool> signInAnonymously() async {
    try {
      final UserCredential userCredential = await _auth.signInAnonymously();
      await _syncUserData(userCredential.user);
      return true;
    } catch (e) {
      print("Anonymous SignIn Error: $e");
      return false;
    }
  }

  // 登出
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // 同步用戶資料到 Firestore
  Future<void> _syncUserData(User? user) async {
    if (user == null) return;

    final publicRef = _firestore.collection('users_public').doc(user.uid);
    final privateRef = _firestore.collection('users_private').doc(user.uid);

    final publicDoc = await publicRef.get();
    
    // 如果是新用戶，初始化資料
    if (!publicDoc.exists) {
      await publicRef.set({
        'displayName': user.displayName ?? '探索者_${user.uid.substring(0, 4)}',
        'avatarUrl': user.photoURL ?? '',
        'faction': '', // 尚未選擇陣營
        'factionJoinedAt': null,
        'totalScore': 0,
        'redScore': 0,
        'greenScore': 0,
        'blueScore': 0,
        'totalRouteDistance': 0,
        'completedMissions': [], // 防止重複解任務
        'createdAt': FieldValue.serverTimestamp(),
      });

      await privateRef.set({
        'email': user.email ?? '',
        'encryptedApiKey': '',
        'notificationEnabled': true,
        'lastLoginAt': FieldValue.serverTimestamp(),
        'isAdmin': false, // 預設非管理員
      });
    } else {
      // 舊用戶更新最後登入時間
      await privateRef.update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    }
  }
  
  // 檢查是否為管理員
  Future<bool> isAdmin() async {
    if (currentUser == null) return false;
    try {
      final doc = await _firestore.collection('users_private').doc(currentUser!.uid).get();
      return doc.data()?['isAdmin'] == true;
    } catch (e) {
      return false;
    }
  }
}
