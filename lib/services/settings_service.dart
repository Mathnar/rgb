import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted user settings. Exposed via [ChangeNotifier] so the UI reacts
/// instantly to changes (volume, language, etc.).
class SettingsService extends ChangeNotifier {
  SettingsService(this._prefs) {
    _musicVolume = _prefs.getDouble(_kMusic) ?? 0.7;
    _sfxVolume = _prefs.getDouble(_kSfx) ?? 1.0;
    _haptics = _prefs.getBool(_kHaptics) ?? true;
    final code = _prefs.getString(_kLang);
    _locale = code == null ? null : Locale(code);
    _bestScore = _prefs.getInt(_kBest) ?? 0;
  }

  static const _kMusic = 'music_volume';
  static const _kSfx = 'sfx_volume';
  static const _kHaptics = 'haptics';
  static const _kLang = 'lang';
  static const _kBest = 'best_score';

  final SharedPreferences _prefs;

  late double _musicVolume;
  late double _sfxVolume;
  late bool _haptics;
  Locale? _locale; // null => follow system
  late int _bestScore;

  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;
  bool get haptics => _haptics;
  Locale? get locale => _locale;
  int get bestScore => _bestScore;

  set musicVolume(double v) {
    _musicVolume = v;
    _prefs.setDouble(_kMusic, v);
    notifyListeners();
  }

  set sfxVolume(double v) {
    _sfxVolume = v;
    _prefs.setDouble(_kSfx, v);
    notifyListeners();
  }

  set haptics(bool v) {
    _haptics = v;
    _prefs.setBool(_kHaptics, v);
    notifyListeners();
  }

  void setLocale(Locale? l) {
    _locale = l;
    if (l == null) {
      _prefs.remove(_kLang);
    } else {
      _prefs.setString(_kLang, l.languageCode);
    }
    notifyListeners();
  }

  /// Returns true if this beat the stored best.
  bool submitLocalScore(int score) {
    if (score > _bestScore) {
      _bestScore = score;
      _prefs.setInt(_kBest, score);
      notifyListeners();
      return true;
    }
    return false;
  }
}
