import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/ads_service.dart';
import 'services/audio_service.dart';
import 'services/auth_service.dart';
import 'services/leaderboard_service.dart';
import 'services/settings_service.dart';

/// True once Firebase initialized successfully. Lets the app run (in offline /
/// guest mode) even before you've run `flutterfire configure`.
bool firebaseReady = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final prefs = await SharedPreferences.getInstance();
  final settings = SettingsService(prefs);

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    firebaseReady = true;
  } catch (e) {
    debugPrint('Firebase not configured yet ($e). Running in local mode.');
  }

  final auth = AuthService();
  if (firebaseReady) {
    try {
      await auth.ensureSignedIn();
    } catch (e) {
      debugPrint('Anonymous sign-in failed: $e');
    }
  }

  final ads = AdsService();
  try {
    await ads.init();
  } catch (e) {
    debugPrint('Ads init failed: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: auth),
        Provider<AudioService>(
          create: (_) => AudioService(settings),
          dispose: (_, a) => a.dispose(),
        ),
        Provider<AdsService>.value(value: ads),
        Provider<LeaderboardService>(create: (_) => LeaderboardService()),
      ],
      child: const RgbApp(),
    ),
  );
}
