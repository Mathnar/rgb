import 'package:audioplayers/audioplayers.dart';
import 'settings_service.dart';

/// Thin wrapper around audioplayers for short SFX + looping music.
///
/// Audio files are expected under assets/audio/. The app degrades gracefully
/// (silently) if a file is missing, so you can ship sound later without
/// breaking the build. See assets/audio/README for the expected filenames.
class AudioService {
  AudioService(this._settings);

  final SettingsService _settings;
  final AudioPlayer _music = AudioPlayer(playerId: 'music')..setReleaseMode(ReleaseMode.loop);
  final List<AudioPlayer> _sfxPool = List.generate(6, (_) => AudioPlayer());
  int _sfxIndex = 0;
  bool _musicStarted = false;

  Future<void> startMusic() async {
    if (_musicStarted) {
      await _music.setVolume(_settings.musicVolume);
      await _music.resume();
      return;
    }
    try {
      _musicStarted = true;
      await _music.setVolume(_settings.musicVolume);
      await _music.play(AssetSource('audio/music_loop.mp3'));
    } catch (_) {
      // No music asset yet — ignore.
    }
  }

  Future<void> setMusicVolume(double v) async {
    try {
      await _music.setVolume(v);
    } catch (_) {}
  }

  Future<void> stopMusic() async {
    try {
      await _music.pause();
    } catch (_) {}
  }

  Future<void> _sfx(String file) async {
    if (_settings.sfxVolume <= 0) return;
    final player = _sfxPool[_sfxIndex];
    _sfxIndex = (_sfxIndex + 1) % _sfxPool.length;
    try {
      await player.stop();
      await player.setVolume(_settings.sfxVolume);
      await player.play(AssetSource('audio/$file'));
    } catch (_) {}
  }

  void hit() => _sfx('hit.wav');
  void combo() => _sfx('combo.wav');
  void fail() => _sfx('fail.wav');

  void dispose() {
    _music.dispose();
    for (final p in _sfxPool) {
      p.dispose();
    }
  }
}
