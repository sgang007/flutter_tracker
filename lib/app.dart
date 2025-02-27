import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_tracker/colors.dart';
import 'package:flutter_tracker/model/app.dart';
import 'package:flutter_tracker/model/auth.dart';
import 'package:flutter_tracker/routes.dart';
import 'package:flutter_tracker/services/authentication.dart';
import 'package:flutter_tracker/state.dart';
import 'package:redux/redux.dart';

class App extends StatefulWidget {
  final Store<AppState> store;

  App({Key? key, required this.store}) : super(key: key);

  @override
  State<StatefulWidget> createState() => AppState();

class AppState extends State<App> {
  AuthService _authService = AuthService();
  List<CameraDescription> _cameras = [];

  @override
  void initState() {
    super.initState();
    _initCameras();
  }

  Future<void> _initCameras() async {
    try {
      _cameras = await availableCameras();
    } catch (e) {
      print('Error initializing cameras: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StoreProvider<AppState>(
      store: widget.store,
      child: MaterialApp(
        title: 'Flutter Tracker',
        theme: ThemeData(
          primarySwatch: AppTheme.primarySwatch,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        initialRoute: AppRoutes.root,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
