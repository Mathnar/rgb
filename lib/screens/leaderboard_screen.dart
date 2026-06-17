import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../main.dart' show firebaseReady;
import '../services/auth_service.dart';
import '../services/leaderboard_service.dart';
import '../theme.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(s.t('leaderboard'), style: const TextStyle(fontWeight: FontWeight.w800)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: RgbColors.magenta,
          tabs: [Tab(text: s.t('global')), Tab(text: s.t('daily'))],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _Board(daily: false),
          _Board(daily: true),
        ],
      ),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({required this.daily});
  final bool daily;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    if (!firebaseReady) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Connect Firebase to enable global leaderboards.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: RgbColors.textDim),
          ),
        ),
      );
    }

    final service = context.read<LeaderboardService>();
    final myUid = context.read<AuthService>().uid;

    return FutureBuilder<List<ScoreEntry>>(
      future: daily ? service.topDaily() : service.topAllTime(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text(s.t('loading'), style: const TextStyle(color: RgbColors.textDim)));
        }
        final entries = snap.data ?? [];
        if (entries.isEmpty) {
          return const Center(
            child: Text('—', style: TextStyle(color: RgbColors.textDim, fontSize: 32)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: entries.length,
          itemBuilder: (context, i) {
            final e = entries[i];
            final me = e.uid == myUid;
            final medal = i < 3
                ? [RgbColors.yellow, RgbColors.textDim, RgbColors.magenta][i]
                : RgbColors.textDim;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: me ? RgbColors.blue.withOpacity(0.12) : RgbColors.bgPanel,
                borderRadius: BorderRadius.circular(14),
                border: me ? Border.all(color: RgbColors.blue, width: 1.5) : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      '${e.rank}',
                      style: TextStyle(fontWeight: FontWeight.w900, color: medal),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '${e.score}',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
