import 'dart:io' show Platform;

import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  final String androidAppId;
  final String iosAppId;
  final AdRequest adRequest;
  final Function beforeRewardCallback;
  final Function rewardCallback;
  final Function errorMessageCallback;
  final bool isDebugMode;

  AdService({
    required this.androidAppId,
    required this.iosAppId,
    required this.adRequest,
    required this.beforeRewardCallback,
    required this.rewardCallback,
    required this.errorMessageCallback,
    this.isDebugMode = false,
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
            if (isDebugMode) {
              print('$ad loaded.');
            }
            _rewardedAd = ad;
            _numRewardedLoadAttempts = 0;
          },
          onAdFailedToLoad: (LoadAdError error) {
            if (isDebugMode) {
              print('RewardedAd failed to load: $error');
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
        if (isDebugMode) {
          print('onAdShowedFullScreenContent.');
        }
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        if (isDebugMode) {
          print('onAdDismissedFullScreenContent.');
        }
        ad.dispose();
        createRewardedAd();
        rewardCallback();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        if (isDebugMode) {
          print('onAdFailedToShowFullScreenContent: $error');
        }
        ad.dispose();
        createRewardedAd();
      },
    );

    _rewardedAd!.setImmersiveMode(true);
    _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
      if (isDebugMode) {
        print('Rewarded $RewardItem(${reward.amount}, ${reward.type})');
      }
      await beforeRewardCallback();
    });
    _rewardedAd = null;
  }

  void showError(String message) {
    errorMessageCallback(message);
  }
}
