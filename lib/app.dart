import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/strings.dart';
import 'screens/home_screen.dart';
import 'services/settings_service.dart';
import 'theme.dart';

class RgbApp extends StatelessWidget {
  const RgbApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    return MaterialApp(
      title: 'RGB',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: settings.locale,
      supportedLocales: Strings.supported,
      localizationsDelegates: const [
        StringsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeScreen(),
    );
  }
}
