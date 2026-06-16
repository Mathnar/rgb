import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../services/ads_service.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme.dart';
import '../widgets/neon_button.dart';
import 'game_screen.dart';
import 'leaderboard_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  BannerAd? _banner;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AudioService>().startMusic();
      _loadBanner();
    });
  }

  void _loadBanner() {
    try {
      setState(() => _banner = context.read<AdsService>().createBanner());
    } catch (_) {}
  }

  @override
  void dispose() {
    _pulse.dispose();
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final best = context.watch<SettingsService>().bestScore;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _iconBtn(Icons.leaderboard_rounded, RgbColors.green, () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const LeaderboardScreen()));
                    }),
                    const SizedBox(width: 8),
                    _iconBtn(Icons.settings_rounded, RgbColors.blue, () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const SettingsScreen()));
                    }),
                  ],
                ),
              ),
            ),
            const Spacer(),
            _AnimatedTitle(pulse: _pulse),
            const SizedBox(height: 14),
            Text(
              '${s.t('best')}: $best',
              style: const TextStyle(color: RgbColors.textDim, fontSize: 16, letterSpacing: 1),
            ),
            const SizedBox(height: 46),
            NeonButton(
              label: s.t('play'),
              color: RgbColors.green,
              icon: Icons.play_arrow_rounded,
              width: 220,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GameScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                s.t('comboHint'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: RgbColors.textDim, fontSize: 12, height: 1.5),
              ),
            ),
            const Spacer(),
            if (_banner != null)
              SizedBox(
                height: _banner!.size.height.toDouble(),
                width: _banner!.size.width.toDouble(),
                child: AdWidget(ad: _banner!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.6), width: 1.5),
          boxShadow: neonGlow(color, blur: 12),
        ),
        child: Icon(icon, color: color),
      ),
    );
  }
}

class _AnimatedTitle extends StatelessWidget {
  const _AnimatedTitle({required this.pulse});
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final letters = [
      ('R', RgbColors.red),
      ('G', RgbColors.green),
      ('B', RgbColors.blue),
    ];
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < letters.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _GlowLetter(
                  char: letters[i].$1,
                  color: letters[i].$2,
                  glow: 0.5 +
                      0.5 *
                          (0.5 + 0.5 * (1 + i) * 0.33) *
                          (0.6 + 0.4 * _wave(pulse.value, i)),
                ),
              ),
          ],
        );
      },
    );
  }

  double _wave(double t, int i) {
    final phase = (t + i / 3) % 1.0;
    return (phase < 0.5 ? phase : 1 - phase) * 2;
  }
}

class _GlowLetter extends StatelessWidget {
  const _GlowLetter({required this.char, required this.color, required this.glow});
  final String char;
  final Color color;
  final double glow;

  @override
  Widget build(BuildContext context) {
    return Text(
      char,
      style: TextStyle(
        fontSize: 88,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        shadows: [
          Shadow(color: color.withOpacity(glow.clamp(0, 1)), blurRadius: 28),
          Shadow(color: color.withOpacity((glow * 0.6).clamp(0, 1)), blurRadius: 54),
        ],
      ),
    );
  }
}
