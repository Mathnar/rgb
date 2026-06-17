import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../game/game_config.dart';
import '../game/game_engine.dart';
import '../game/game_painter.dart';
import '../l10n/strings.dart';
import '../main.dart' show firebaseReady;
import '../services/ads_service.dart';
import '../services/audio_service.dart';
import '../services/auth_service.dart';
import '../services/leaderboard_service.dart';
import '../services/settings_service.dart';
import '../theme.dart';
import '../widgets/neon_button.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  final GameEngine _engine = GameEngine();
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  final Set<int> _pressed = {};
  bool _scoreSubmitted = false;
  bool _newRecord = false;

  static const _colColors = [RgbColors.red, RgbColors.green, RgbColors.blue];

  @override
  void initState() {
    super.initState();
    _engine.onResult = _onResult;
    _engine.onGameOver = _onGameOver;
    _ticker = createTicker(_tick)..start();
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 0.0
        : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    _engine.update(dt.clamp(0.0, 0.05));
  }

  void _onResult(PressResult result) {
    final haptics = context.read<SettingsService>().haptics;
    final audio = context.read<AudioService>();
    switch (result) {
      case PressResult.hit:
        if (haptics) HapticFeedback.lightImpact();
        audio.hit();
        break;
      case PressResult.combo:
        if (haptics) HapticFeedback.heavyImpact();
        audio.combo();
        break;
      case PressResult.wrong:
        if (haptics) HapticFeedback.heavyImpact();
        audio.fail();
        break;
      case PressResult.none:
        break;
    }
  }

  Future<void> _onGameOver() async {
    if (_scoreSubmitted) return;
    _scoreSubmitted = true;
    final score = _engine.score;

    _newRecord = context.read<SettingsService>().submitLocalScore(score);

    if (firebaseReady && score > 0) {
      try {
        final auth = context.read<AuthService>();
        final name = auth.user?.displayName?.trim();
        await context.read<LeaderboardService>().submitScore(
              uid: auth.uid,
              name: (name == null || name.isEmpty) ? 'Player' : name,
              score: score,
            );
      } catch (_) {/* offline — local best still saved */}
    }
    if (mounted) setState(() {});
  }

  void _start() {
    setState(() {
      _scoreSubmitted = false;
      _newRecord = false;
    });
    _engine.start();
  }

  Future<void> _retry() async {
    try {
      await context.read<AdsService>().maybeShowInterstitial();
    } catch (_) {}
    _start();
  }

  Future<void> _continueWithAd() async {
    final ads = context.read<AdsService>();
    bool earned = false;
    try {
      earned = await ads.showRewarded();
    } catch (_) {}
    if (earned) {
      _scoreSubmitted = false;
      _engine.revive();
      if (mounted) setState(() {});
    }
  }

  void _press(int col) {
    if (_engine.state == GameState.ready) {
      _start();
      return;
    }
    setState(() => _pressed.add(col));
    _engine.handlePress(col);
  }

  void _release(int col) {
    _engine.releaseColumn(col);
    if (mounted) setState(() => _pressed.remove(col));
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: GamePainter(_engine))),
          _buildHud(),
          _buildControls(),
          _buildReadyOverlay(),
          _buildGameOverOverlay(),
        ],
      ),
    );
  }

  Widget _buildHud() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, color: RgbColors.textDim),
            ),
            const Spacer(),
            AnimatedBuilder(
              animation: _engine,
              builder: (_, __) => Text(
                '${_engine.score}',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.white54, blurRadius: 16)],
                ),
              ),
            ),
            const Spacer(),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  /// Three large pointer-tracking lanes pinned to the bottom. Using raw
  /// [Listener] pointer events (not taps) is what makes simultaneous two-finger
  /// combo presses work reliably.
  Widget _buildControls() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * (1 - GameConfig.hitLineY) + 24,
        child: Row(
          children: [
            for (var c = 0; c < GameConfig.columns; c++)
              Expanded(
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (_) => _press(c),
                  onPointerUp: (_) => _release(c),
                  onPointerCancel: (_) => _release(c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 80),
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _colColors[c].withOpacity(_pressed.contains(c) ? 0.45 : 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _colColors[c], width: 2),
                      boxShadow: neonGlow(
                        _colColors[c],
                        blur: _pressed.contains(c) ? 34 : 14,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadyOverlay() {
    return AnimatedBuilder(
      animation: _engine,
      builder: (_, __) {
        if (_engine.state != GameState.ready) return const SizedBox.shrink();
        final s = Strings.of(context);
        return Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.55),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s.t('tapToStart'),
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    s.t('tutorial'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: RgbColors.textDim, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGameOverOverlay() {
    return AnimatedBuilder(
      animation: _engine,
      builder: (_, __) {
        if (_engine.state != GameState.gameOver) return const SizedBox.shrink();
        final s = Strings.of(context);
        final ads = context.read<AdsService>();
        return Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.72),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_newRecord)
                  Text(
                    s.t('newRecord'),
                    style: const TextStyle(
                      color: RgbColors.yellow,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  s.t('gameOver'),
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                Text(
                  '${s.t('score')}: ${_engine.score}',
                  style: const TextStyle(fontSize: 22, color: RgbColors.text),
                ),
                const SizedBox(height: 34),
                if (ads.rewardedReady)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: NeonButton(
                      label: s.t('continueAd'),
                      color: RgbColors.yellow,
                      icon: Icons.ondemand_video_rounded,
                      onTap: _continueWithAd,
                    ),
                  ),
                NeonButton(
                  label: s.t('retry'),
                  color: RgbColors.green,
                  icon: Icons.refresh_rounded,
                  onTap: _retry,
                ),
                const SizedBox(height: 14),
                NeonButton(
                  label: s.t('home'),
                  color: RgbColors.blue,
                  filled: false,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
