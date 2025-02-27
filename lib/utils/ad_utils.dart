import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_tracker/model/groups_viewmodel.dart';

Widget bannerAd(
  GroupsViewModel viewModel,
) {
  return Container(
    alignment: Alignment.center,
    width: double.infinity,
    padding: const EdgeInsets.only(
      top: 20.0,
      bottom: 20.0,
    ),
    child: BannerAd(
      adUnitId: getBannerAdUnitId(viewModel),
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(),
    ),
  );
}

List<T> injectAd<T>(
  List<dynamic> list,
  dynamic ad, {
  int minEntriesNeeded = 10,
}) {
  if (list == null) {
    return null;
  }

  if (list.length > minEntriesNeeded) {
    List<T> _list = List<T>.from(list);
    _list.insert((_list.length ~/ 2), ad);
    return _list;
  }

  return list;
}

/*
Test Id's from:
@see https://developers.google.com/admob/ios/banner
@see https://developers.google.com/admob/android/banner
*/

String getAppId(
  String androidAppId,
  String iosAppId,
) {
  if (Platform.isAndroid) {
    return androidAppId;
  } else if (Platform.isIOS) {
    return iosAppId;
  }
  return null;
}

String getBannerAdUnitId(GroupsViewModel viewModel) {
  if (Platform.isAndroid) {
    return 'ca-app-pub-3940256099942544/6300978111'; // Test Ad Unit ID for Android
  } else if (Platform.isIOS) {
    return 'ca-app-pub-3940256099942544/2934735716'; // Test Ad Unit ID for iOS
  }
  return null;
}

String getInterstitialAdUnitId(
  GroupsViewModel viewModel,
) {
  if (Platform.isIOS) {
    return viewModel.configValue('admob_ios_interstitial');
  } else if (Platform.isAndroid) {
    return viewModel.configValue('admob_android_interstitial');
  }

  return null;
}

String getRewardBasedVideoAdUnitId(
  GroupsViewModel viewModel,
) {
  if (Platform.isIOS) {
    return viewModel.configValue('admob_ios_video_reward');
  } else if (Platform.isAndroid) {
    return viewModel.configValue('admob_android_video_reward');
  }

  return null;
}
