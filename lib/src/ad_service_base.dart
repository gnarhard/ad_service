import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  final String androidAppId;
  final String iosAppId;
  final AdRequest adRequest;
  final Function beforeRewardCallback;
  final Function rewardCallback;
  final Function errorMessageCallback;

  AdService({
    required this.androidAppId,
    required this.iosAppId,
    required this.adRequest,
    required this.beforeRewardCallback,
    required this.rewardCallback,
    required this.errorMessageCallback,
  });

  RewardedAd? _rewardedAd;
  int _numRewardedLoadAttempts = 0;
  static const int _maxFailedLoadAttempts = 3;

  Future<void> createRewardedAd() async {
    await RewardedAd.load(
        adUnitId: Platform.isAndroid ? androidAppId : iosAppId,
        request: adRequest,
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            if (kDebugMode) {
              debugPrint('$ad loaded.');
            }
            _rewardedAd = ad;
            _numRewardedLoadAttempts = 0;
          },
          onAdFailedToLoad: (LoadAdError error) {
            if (kDebugMode) {
              debugPrint('RewardedAd failed to load: $error');
            }
            _rewardedAd = null;
            _numRewardedLoadAttempts += 1;
            if (_numRewardedLoadAttempts < _maxFailedLoadAttempts) {
              createRewardedAd();
            }
          },
        ));
  }

  void showRewardedAd() {
    if (_rewardedAd == null) {
      errorMessageCallback("No ad available.");
      return;
    }
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
        if (kDebugMode) {
          debugPrint('onAdShowedFullScreenContent.');
        }
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        if (kDebugMode) {
          debugPrint('onAdDismissedFullScreenContent.');
        }
        ad.dispose();
        createRewardedAd();
        rewardCallback();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        if (kDebugMode) {
          debugPrint('onAdFailedToShowFullScreenContent: $error');
        }
        ad.dispose();
        createRewardedAd();
      },
    );

    _rewardedAd!.setImmersiveMode(true);
    _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
      if (kDebugMode) {
        debugPrint('Rewarded $RewardItem(${reward.amount}, ${reward.type})');
      }
      await beforeRewardCallback();
    });
    _rewardedAd = null;
  }

  void showError(String message) {
    errorMessageCallback(message);
  }
}
