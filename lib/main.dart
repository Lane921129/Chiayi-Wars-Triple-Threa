import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/faction_select_screen.dart';
import 'theme/app_theme.dart';
import 'theme/simplified_theme.dart';
import 'theme/theme_provider.dart';

import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'services/map_cache_service.dart';
import 'services/api_key_service.dart';
import 'services/weather_service.dart';
import 'services/bus_service.dart';
import 'services/ai_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FMTCObjectBoxBackend().initialise();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => MapCacheService()),
        ChangeNotifierProvider(create: (_) => ApiKeyService()),
        ChangeNotifierProxyProvider<ApiKeyService, WeatherService>(
          create: (context) => WeatherService(Provider.of<ApiKeyService>(context, listen: false)),
          update: (context, apiKeyService, previous) => previous ?? WeatherService(apiKeyService),
        ),
        ChangeNotifierProxyProvider<ApiKeyService, BusService>(
          create: (context) => BusService(Provider.of<ApiKeyService>(context, listen: false)),
          update: (context, apiKeyService, previous) => previous ?? BusService(apiKeyService),
        ),
        ChangeNotifierProxyProvider<ApiKeyService, AiService>(
          create: (context) => AiService(Provider.of<ApiKeyService>(context, listen: false)),
          update: (context, apiKeyService, previous) => previous ?? AiService(apiKeyService),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: '探索諸羅：三國爭霸',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.isDarkMode 
          ? (themeProvider.isSimplifiedMode ? SimplifiedTheme.darkTheme : AppTheme.darkTheme)
          : (themeProvider.isSimplifiedMode ? SimplifiedTheme.lightTheme : AppTheme.lightTheme),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          final user = snapshot.data!;
          // 檢查使用者是否已經選擇陣營
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users_public').doc(user.uid).get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              
              if (userSnapshot.hasError) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('載入失敗: ${userSnapshot.error}', style: const TextStyle(color: Colors.white)),
                        ElevatedButton(
                          onPressed: () => FirebaseAuth.instance.signOut(),
                          child: const Text('重新登入'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (userSnapshot.hasData) {
                if (!userSnapshot.data!.exists) {
                  // 發生異常：有登入狀態，但 Firestore 裡沒有他的資料
                  // （通常是因為之前的 Bug 導致沒寫入成功）
                  // 提供按鈕讓他重新登入觸發建立資料
                  return Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('帳號資料初始化異常，請重新登入。', style: TextStyle(color: Colors.white)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => FirebaseAuth.instance.signOut(),
                            child: const Text('登出並重新登入'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                final faction = userData['faction'] as String?;
                
                // 如果 faction 是空的，代表是新手，進入選擇頁面
                if (faction == null || faction.isEmpty) {
                  return const FactionSelectScreen();
                }
                
                // 已選擇陣營，進入主畫面
                return const HomeScreen();
              }
              
              // 找不到資料（可能正準備初始化），先回傳載入中
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            },
          );
        }
        return const LoginScreen();
      },
    );
  }
}