import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../services/audio_service.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../theme.dart';
import 'auth_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _langs = {
    null: 'System',
    'en': 'English',
    'it': 'Italiano',
    'es': 'Español',
  };

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final settings = context.watch<SettingsService>();
    final auth = context.watch<AuthService>();
    final audio = context.read<AudioService>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(s.t('settings'), style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _section(s.t('music')),
          Slider(
            value: settings.musicVolume,
            activeColor: RgbColors.red,
            onChanged: (v) {
              settings.musicVolume = v;
              audio.setMusicVolume(v);
            },
          ),
          _section(s.t('sfx')),
          Slider(
            value: settings.sfxVolume,
            activeColor: RgbColors.green,
            onChanged: (v) => settings.sfxVolume = v,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: Text(s.t('haptics')),
            value: settings.haptics,
            activeColor: RgbColors.blue,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => settings.haptics = v,
          ),
          const Divider(height: 32),
          _section(s.t('language')),
          DropdownButton<String?>(
            value: settings.locale?.languageCode,
            isExpanded: true,
            dropdownColor: RgbColors.bgPanel,
            items: _langs.entries
                .map((e) => DropdownMenuItem<String?>(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (code) =>
                settings.setLocale(code == null ? null : Locale(code)),
          ),
          const Divider(height: 32),
          _section(s.t('account')),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.person_rounded, color: RgbColors.textDim),
            title: Text(
              auth.isAnonymous
                  ? s.t('guest')
                  : (auth.user?.displayName?.isNotEmpty == true
                      ? auth.user!.displayName!
                      : (auth.user?.email ?? s.t('player'))),
            ),
            trailing: TextButton(
              onPressed: () {
                if (auth.isAnonymous) {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AuthScreen()));
                } else {
                  auth.signOut();
                }
              },
              child: Text(auth.isAnonymous ? s.t('signIn') : s.t('signOut')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 4, top: 8),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: RgbColors.textDim,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            fontSize: 12,
          ),
        ),
      );
}
