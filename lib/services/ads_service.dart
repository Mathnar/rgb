import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob integration: banner (home), interstitial (game over), rewarded
/// (continue after death).
///
/// The IDs below are GOOGLE'S OFFICIAL TEST IDs — safe to develop with.
/// Before publishing, replace [_androidIds]/[_iosIds] with your real unit IDs
/// from the AdMob console, and set your real App ID in the native manifests
/// (see README). Showing real ads on test devices, or test ads in production,
/// both violate AdMob policy.
class AdsService {
  AdsService();

  static const _test = {
    'banner_android': 'ca-app-pub-3940256099942544/6300978111',
    'banner_ios': 'ca-app-pub-3940256099942544/2934735716',
    'interstitial_android': 'ca-app-pub-3940256099942544/1033173712',
    'interstitial_ios': 'ca-app-pub-3940256099942544/4411468910',
    'rewarded_android': 'ca-app-pub-3940256099942544/5224354917',
    'rewarded_ios': 'ca-app-pub-3940256099942544/1712485313',
  };

  // TODO(publish): replace with your real AdMob unit IDs.
  static const bool useTestAds = true;

  String _unit(String kind) => _test['${kind}_${Platform.isIOS ? 'ios' : 'android'}']!;

  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  int _gamesSinceInterstitial = 0;

  Future<void> init() async {
    await MobileAds.instance.initialize();
    _loadInterstitial();
    _loadRewarded();
  }

  // ---- Banner ----------------------------------------------------------
  BannerAd createBanner() {
    return BannerAd(
      adUnitId: _unit('banner'),
      size: AdSize.banner,
      request: const AdRequest(),
      listener: const BannerAdListener(),
    )..load();
  }

  // ---- Interstitial ----------------------------------------------------
  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: _unit('interstitial'),
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  /// Show an interstitial roughly every 3 games so we monetize without
  /// nuking retention.
  Future<void> maybeShowInterstitial() async {
    _gamesSinceInterstitial++;
    if (_gamesSinceInterstitial < 3 || _interstitial == null) return;
    _gamesSinceInterstitial = 0;
    final ad = _interstitial!;
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _loadInterstitial();
      },
    );
    await ad.show();
  }

  // ---- Rewarded (continue) --------------------------------------------
  void _loadRewarded() {
    RewardedAd.load(
      adUnitId: _unit('rewarded'),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (_) => _rewarded = null,
      ),
    );
  }

  bool get rewardedReady => _rewarded != null;

  /// Returns true if the user earned the reward (watched to the end).
  Future<bool> showRewarded() async {
    final ad = _rewarded;
    if (ad == null) return false;
    _rewarded = null;
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _loadRewarded();
      },
    );
    await ad.show(onUserEarnedReward: (_, __) => earned = true);
    return earned;
  }
}
