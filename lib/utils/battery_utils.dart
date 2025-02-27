import 'package:battery_plus/battery_plus.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_tracker/actions.dart';
import 'package:redux/redux.dart';
import 'package:flutter_tracker/state.dart';

void updateBatteryState(
  Battery battery,
  BatteryState state,
  RemoteConfig remoteConfig,
  Store<AppState> store,
) async {
  int batteryLevel = await battery.batteryLevel;
  store.dispatch(UpdateBatteryStateAction(
    batteryLevel: batteryLevel,
    batteryState: state,
  ));
}
