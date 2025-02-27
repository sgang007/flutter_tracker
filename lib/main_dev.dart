import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'package:flutter_tracker/app.dart';
import 'package:flutter_tracker/config.dart';
import 'package:flutter_tracker/utils/ad_utils.dart';
import 'package:flutter_tracker/utils/location_utils.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  MobileAds.instance.initialize();

  // DEV Environment Specific Configuration
  AppConfig config = AppConfig(
    flavor: Flavor.DEVELOPMENT,
    userEndpointUrl: 'https://us-central1-flutter-tracker.cloudfunctions.net/endpoints/update', // TODO
    messageEndpointUrl: 'https://us-central1-flutter-tracker.cloudfunctions.net/endpoints/message', // TODO
    child: FlutterTrackerApp(),
  );

  runApp(config);
  bg.BackgroundGeolocation.registerHeadlessTask(onHeadlessTask);
}
