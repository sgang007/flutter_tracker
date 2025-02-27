import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_tracker/model/groups_viewmodel.dart';
import 'package:flutter_tracker/state.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationPermissionFab extends StatefulWidget {
  final double bottomPosition;
  final VoidCallback? onTap;

  LocationPermissionFab({
    Key? key,
    this.bottomPosition = 0.0,
    this.onTap,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _LocationPermissionFabState();
}

class _LocationPermissionFabState extends State<LocationPermissionFab> {
  Permission _locationPermission = Permission.location;
  PermissionStatus _permissionStatus = PermissionStatus.denied;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await _locationPermission.status;
    setState(() {
      _permissionStatus = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, GroupsViewModel>(
      converter: (store) => GroupsViewModel.fromStore(store),
      builder: (_, viewModel) {
        if (_permissionStatus == PermissionStatus.granted) {
          return Container();
        }

        return Positioned(
          right: 10.0,
          bottom: widget.bottomPosition + 10.0,
          child: FloatingActionButton(
            heroTag: 'location_permission_fab',
            backgroundColor: Colors.white,
            child: Icon(
              Icons.location_off,
              color: Colors.red,
            ),
            onPressed: widget.onTap,
          ),
        );
      },
    );
  }
}
