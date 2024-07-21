import 'dart:io' show Platform;

import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  final String androidAppId;
  final String iosAppId;
  final AdRequest adRequest;
  final bool isDebugMode;

  AdService({
    required this.androidAppId,
    required this.iosAppId,
    required this.adRequest,
    this.isDebugMode = false,
  });

  RewardedAd? currentRewardedAd;
  int _numRewardedLoadAttempts = 0;
  static const int _maxFailedLoadAttempts = 3;

  Future<void> createRewardedAd(void Function() showCallback) async {
    await RewardedAd.load(
      adUnitId: Platform.isAndroid ? androidAppId : iosAppId,
      request: adRequest,
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          if (isDebugMode) {
            print('$ad loaded.');
          }
          currentRewardedAd = ad;
          _numRewardedLoadAttempts = 0;
          showCallback();
        },
        onAdFailedToLoad: (LoadAdError error) {
          if (isDebugMode) {
            print('RewardedAd failed to load: $error');
          }
          currentRewardedAd = null;
          _numRewardedLoadAttempts += 1;
          if (_numRewardedLoadAttempts < _maxFailedLoadAttempts) {
            createRewardedAd();
          }
        },
      ),
    );
  }

  void showRewardedAd(Function rewardCallback, Function beforeRewardCallback,
      Function(String message) errorMessageCallback) {
    if (currentRewardedAd == null) {
      errorMessageCallback("No ad available.");
      return;
    }
    currentRewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
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

    currentRewardedAd!.setImmersiveMode(true);
    currentRewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
      if (isDebugMode) {
        print('Rewarded $RewardItem(${reward.amount}, ${reward.type})');
      }
      await beforeRewardCallback();
    });
    currentRewardedAd = null;
  }
}
