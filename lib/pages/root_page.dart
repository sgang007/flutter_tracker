import 'dart:async';
import 'dart:io';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:logger/logger.dart';
import 'package:flutter_tracker/actions.dart';
import 'package:flutter_tracker/colors.dart';
import 'package:flutter_tracker/model/app.dart';
import 'package:flutter_tracker/model/auth.dart';
import 'package:flutter_tracker/model/groups_viewmodel.dart';
import 'package:flutter_tracker/pages/groups_home_page.dart';
import 'package:flutter_tracker/pages/login_signup_page.dart';
import 'package:flutter_tracker/pages/onboarding_page.dart';
import 'package:flutter_tracker/services/authentication.dart';
import 'package:flutter_tracker/state.dart';
import 'package:flutter_tracker/utils/auth_utils.dart';
import 'package:flutter_tracker/utils/battery_utils.dart';
import 'package:flutter_tracker/utils/connectivity_utils.dart';
import 'package:flutter_tracker/utils/device_utils.dart';
import 'package:flutter_tracker/utils/location_utils.dart';
import 'package:flutter_tracker/utils/message_utils.dart';
import 'package:flutter_tracker/utils/rc_utils.dart';
import 'package:flutter_tracker/widgets/backdrop.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:redux/redux.dart';

class RootPage extends StatefulWidget {
  final BaseAuthService authService;
  final Store<AppState> store;
  final RemoteConfig remoteConfig;

  RootPage({
    Key? key,
    this.authService,
    this.store,
    this.remoteConfig,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> with WidgetsBindingObserver {
  bool _userDataRequested = false;
  bool _userLoaded = false;
  bool _pushMessagesListening = false;
  AuthStatus _authStatus = AuthStatus.NOT_DETERMINED;
  Logger logger = Logger();

  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  final Connectivity _connectivity = Connectivity();
  final Battery _battery = Battery();

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    initRemoteConfig(widget.remoteConfig, widget.store);

    _connectivity.onConnectivityChanged.listen((result) =>
        updateConnectionStatus(result, widget.remoteConfig, widget.store));

    _battery.onBatteryStateChanged.listen((state) =>
        updateBatteryState(_battery, state, widget.remoteConfig, widget.store));

    updateConnectionStatus(null, widget.remoteConfig, widget.store);
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    widget.store.dispatch(SetAppStateAction(state));
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return StoreConnector<AppState, GroupsViewModel>(
      converter: (store) => GroupsViewModel.fromStore(store),
      builder: (_, viewModel) {
        if ((viewModel.authStatus != null) &&
            (viewModel.authStatus != _authStatus)) {
          _authStatus = viewModel.authStatus;
        }

        _checkUser(viewModel);
        listenForToastMessages(context, widget.store);

        if (!_pushMessagesListening && (viewModel.user != null)) {
          listenFormPushMessages(
            context,
            widget.store,
            userId: viewModel.user.documentId,
          );

          _pushMessagesListening = true;
        }

        switch (_authStatus) {
          case AuthStatus.NOT_DETERMINED:
            return showScaffoldLoadingBackdrop();

          case AuthStatus.ONBOARDING:
            return OnboardingPage();

          case AuthStatus.NEEDS_ACCOUNT_VERIFICATION:
          case AuthStatus.NOT_LOGGED_IN:
            _userDataRequested = false;
            _userLoaded = false;

            return LoginSignUpPage(
              authService: widget.authService,
              onSignedIn: (email, password) => _checkUser(
                viewModel,
                email: email,
                password: password,
              ),
              onVerify: _onVerify,
            );

          case AuthStatus.LOGGED_IN:
            return GroupsHomePage(
              authService: widget.authService,
              onSignedOut: () => onSignedOut(widget.store),
            );

          default:
            return showScaffoldLoadingBackdrop();
        }
      },
    );
  }

  void _checkUser(
    GroupsViewModel viewModel, {
    String? email,
    String? password,
  }) async {
    User? user = await widget.authService.getCurrentUser();
    if (user == null) {
      setState(() {
        _authStatus = AuthStatus.ONBOARDING;
      });
    } else if ((user != null) &&
        (!_userDataRequested ||
            !_userLoaded ||
            (_authStatus == AuthStatus.NOT_LOGGED_IN))) {
      setState(() {
        _authStatus = AuthStatus.LOGGED_IN;
        widget.store.dispatch(SetAuthStatusAction(_authStatus));
      });

      if (user.emailVerified) {
        if (!_userDataRequested) {
          widget.store.dispatch(CancelFamilyDataEventsAction());
          widget.store.dispatch(RequestFamilyDataAction(user.uid));
          widget.store.dispatch(CancelGroupsDataEventsAction());
          widget.store.dispatch(RequestGroupsDataAction(user.uid));

          setState(() {
            _userDataRequested = true;
          });
        }

        if ((viewModel != null) && (viewModel.user != null)) {
          widget.store.dispatch(RequestProductsAction());
          widget.store.dispatch(RequestPlacesAction(user.uid));
          widget.store.dispatch(RequestMapsAction());
          widget.store.dispatch(RequestPlansAction());

          _listenForAppVersion(user);
          _listenForDevice(user);
          _listenForTimezone(user);

          initLocation(context, widget.store);
          configureLocationSharing(viewModel);

          if (viewModel.user.activeGroup == null) {
            widget.store
                .dispatch(ActivateGroupAction(viewModel.user.primaryGroup));
          } else if (viewModel.user.activeGroupMember != null) {
            widget.store.dispatch(CancelUserActivityAction());
            widget.store.dispatch(RequestUserActivityDataAction(
                viewModel.user.activeGroupMember));
          } else if (viewModel.user.activeGroup != null) {
            widget.store
                .dispatch(RequestGroupPlacesAction(viewModel.user.activeGroup));
          }

          setState(() {
            _userLoaded = true;
          });

          await checkLocationPermissionStatus(widget.store, context);
        }
      } else {
        setState(() {
          _authStatus = AuthStatus.NEEDS_ACCOUNT_VERIFICATION;
          widget.store.dispatch(SetAuthStatusAction(_authStatus));
        });
      }
    }
  }

  void _onVerify() {
    widget.authService.getCurrentUser().then((user) {
      setState(() {
        _authStatus = AuthStatus.LOGGED_IN;
        widget.store.dispatch(SetAuthStatusAction(_authStatus));
      });

      widget.store.dispatch(RequestFamilyDataAction(user!.uid));
      widget.store.dispatch(RequestPlacesAction(user.uid));

      widget.store.dispatch(UpdateFamilyDataEventAction(
        family: {
          'name': user.displayName,
        },
        userId: user.uid,
      ));
    });
  }

  Future<void> _listenForAppVersion(
    User user,
  ) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    AppVersion version = AppVersion().fromPackageInfo(packageInfo);

    if (!mounted) return;

    widget.store.dispatch(UpdateFamilyDataEventAction(
      family: {
        'version': AppVersion().toMap(version),
      },
      userId: user.uid,
    ));
  }

  Future<void> _listenForDevice(
    User user,
  ) async {
    Map<String, dynamic> deviceData = <String, dynamic>{};

    try {
      if (Platform.isAndroid) {
        deviceData = readAndroidBuildData(await _deviceInfoPlugin.androidInfo);
      } else if (Platform.isIOS) {
        deviceData = readIosDeviceInfo(await _deviceInfoPlugin.iosInfo);
      }
    } on PlatformException {
      deviceData = <String, dynamic>{
        'error:': 'Failed to get platform version.',
      };
    }

    if (!mounted) return;

    widget.store.dispatch(UpdateFamilyDataEventAction(
      family: {
        'device': deviceData,
      },
      userId: user.uid,
    ));
  }

  Future<void> _listenForTimezone(
    User user,
  ) async {
    String timezone;

    try {
      timezone = await FlutterNativeTimezone.getLocalTimezone();
    } on PlatformException {
      timezone = 'Failed to get the timezone.';
    }

    if (!mounted) return;

    widget.store.dispatch(UpdateFamilyDataEventAction(
      family: {
        'timezone': timezone,
      },
      userId: user.uid,
    ));
  }
}
