import 'package:cloud_firestore/cloud_firestore.dart';

class ScoreEntry {
  ScoreEntry({required this.uid, required this.name, required this.score, this.rank = 0});
  final String uid;
  final String name;
  final int score;
  final int rank;
}

/// Firestore-backed leaderboards.
///
/// Data model:
///   scores/{uid}              -> all-time best  { name, score, updatedAt }
///   daily/{yyyy-MM-dd}/scores/{uid} -> best of the day { name, score }
///
/// "All-time" is the player's lifetime best; "daily" resets naturally because
/// each day is its own subcollection. No server cron needed.
class LeaderboardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String _todayKey([DateTime? now]) {
    final d = (now ?? DateTime.now()).toUtc();
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  /// Submit a finished game. Updates all-time best (only if higher) and the
  /// daily best (only if higher than today's best).
  Future<void> submitScore({
    required String uid,
    required String name,
    required int score,
  }) async {
    final safeName = name.trim().isEmpty ? 'Player' : name.trim();

    final allTimeRef = _db.collection('scores').doc(uid);
    final dailyRef =
        _db.collection('daily').doc(_todayKey()).collection('scores').doc(uid);

    await _db.runTransaction((tx) async {
      final allTime = await tx.get(allTimeRef);
      if (!allTime.exists || (allTime.data()?['score'] ?? 0) < score) {
        tx.set(allTimeRef, {
          'name': safeName,
          'score': score,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      final daily = await tx.get(dailyRef);
      if (!daily.exists || (daily.data()?['score'] ?? 0) < score) {
        tx.set(dailyRef, {'name': safeName, 'score': score});
      }
    });
  }

  Future<List<ScoreEntry>> topAllTime({int limit = 100}) async {
    final snap = await _db
        .collection('scores')
        .orderBy('score', descending: true)
        .limit(limit)
        .get();
    return _rank(snap);
  }

  Future<List<ScoreEntry>> topDaily({int limit = 100}) async {
    final snap = await _db
        .collection('daily')
        .doc(_todayKey())
        .collection('scores')
        .orderBy('score', descending: true)
        .limit(limit)
        .get();
    return _rank(snap);
  }

  List<ScoreEntry> _rank(QuerySnapshot<Map<String, dynamic>> snap) {
    var i = 0;
    return snap.docs.map((d) {
      i++;
      return ScoreEntry(
        uid: d.id,
        name: (d.data()['name'] ?? 'Player') as String,
        score: (d.data()['score'] ?? 0) as int,
        rank: i,
      );
    }).toList();
  }
}
