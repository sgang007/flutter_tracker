import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_tracker/actions.dart';
import 'package:flutter_tracker/colors.dart';
import 'package:flutter_tracker/model/group.dart';
import 'package:flutter_tracker/model/groups_viewmodel.dart';
import 'package:flutter_tracker/model/place.dart';
import 'package:flutter_tracker/model/user.dart';
import 'package:flutter_tracker/routes.dart';
import 'package:flutter_tracker/state.dart';
import 'package:flutter_tracker/utils/group_utils.dart';
import 'package:flutter_tracker/utils/common_utils.dart';
import 'package:flutter_tracker/utils/date_utils.dart';
import 'package:flutter_tracker/utils/location_utils.dart';
import 'package:flutter_tracker/utils/map_utils.dart';
import 'package:flutter_tracker/utils/slide_panel_utils.dart';
import 'package:flutter_tracker/utils/user_utils.dart';
import 'package:flutter_tracker/widgets/active_driver_data.dart';
import 'package:flutter_tracker/widgets/backdrop.dart';
import 'package:flutter_tracker/widgets/location_permission_fab.dart';
import 'package:flutter_tracker/widgets/map_center.dart';
import 'package:flutter_tracker/widgets/map_type_fab.dart';
import 'package:flutter_tracker/widgets/place_pin.dart';
import 'package:flutter_tracker/utils/place_utils.dart';
import 'package:flutter_tracker/widgets/user_pin.dart';
import 'package:latlong2/latlong.dart';

class GroupsMap extends StatefulWidget {
  final String mapType;
  final GroupsMapState appState = GroupsMapState();

  const GroupsMap({
    Key? key,
    this.mapType = 'STREETS',
  }) : super(key: key);

  @override
  State createState() => appState;

  bool isPanning() {
    return appState._mapPanning;
  }

  void centerMap({
    bool clearPanning = true,
  }) {
    if (clearPanning) {
      appState._panningPosition = null;
      appState._mapPanning = false;
    }

    fitMarkerBounds(
      appState._mapController,
      appState._mapBounds,
      padding: const EdgeInsets.symmetric(
        vertical: 180.0,
        horizontal: 100.0,
      ),
    );
  }
}

class GroupsMapState extends State<GroupsMap> with TickerProviderStateMixin {
  late AnimationController _mapAnimationController;
  late AnimationController _backdropAnimationController;

  final MapController _mapController = MapController();
  List<Marker> _mapMarkers = [];
  List<CircleMarker> _mapGroupMarkers = [];
  late LatLngBounds _mapBounds;
  MapPosition? _panningPosition;
  bool _mapPanning = false;

  Group? _currentGroup;
  GroupMember? _currentGroupMember;
  Place? _currentPlace;
  LatLng? _currentPosition;

  double _markerSize = 74.0;
  double _markerPadding = 10.0;
  double _currentZoomLevel = 13.0;
  double _maxZoomLevel = 17.0;
  double _minZoomLevel = 10.0;
  bool _isLoaded = false;
  Timer? _panningDebounce;

  late Animation<double> _mapAnimation;
  late Tween<double> _latTween;
  late Tween<double> _lngTween;
  late Tween<double> _zoomTween;

  @override
  void initState() {
    super.initState();

    _mapBounds = LatLngBounds(LatLng(0, 0), LatLng(0, 0));
    _mapAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _backdropAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _latTween = Tween<double>();
    _lngTween = Tween<double>();
    _zoomTween = Tween<double>();

    _mapAnimation = CurvedAnimation(
      parent: _mapAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return StoreConnector<AppState, GroupsViewModel>(
      converter: (store) => GroupsViewModel.fromStore(store),
      builder: (_, viewModel) {
        if (viewModel.user == null) {
          _currentPosition = _defaultPosition();
        } else {
          if (!_isLoaded && (_currentPosition == null)) {
            _setInitialPosition(viewModel.user);
          }

          _isLoaded = true;
        }

        if (_isLoaded) {
          _setMapData(viewModel);
        }

        List<Widget> children = [
          _buildMap(viewModel),
          ActiveDriverData(
            member: viewModel.activeGroupMember,
          ),
          MapCenter(
            mapPanning: widget.isPanning(),
            bottomPosition: DEFAULT_PANEL_FAB_OFFSET,
            onTap: widget.centerMap,
          ),
          LocationPermissionFab(
            bottomPosition: DEFAULT_PANEL_FAB_OFFSET,
            onTap: () => _tapRequestLocationPermission(),
          ),
          MapTypeFab(
            bottomPosition: DEFAULT_PANEL_FAB_OFFSET,
            onTap: () => _tapMapType(),
          ),
          showLoadingBackdrop(
            _backdropAnimationController,
            condition: !_isLoaded,
          ),
        ];

        double offset = 0.0;
        if ((viewModel.activeGroupMember != null) ||
            (viewModel.activePlace != null)) {
          offset = APPBAR_HEIGHT;
        }

        return Padding(
          padding: EdgeInsets.only(bottom: offset),
          child: Stack(
            children: filterNullWidgets(children),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _currentGroup = null;
    _currentGroupMember = null;
    _currentPlace = null;
    _panningPosition = null;
    _mapPanning = false;
    _mapAnimationController.dispose();
    _backdropAnimationController.dispose();
    super.dispose();
  }

  Widget _buildMap(
    GroupsViewModel viewModel,
  ) {
    if (_mapMarkers.isEmpty) {
      _buildMarkers(viewModel);
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: _currentPosition ?? LatLng(0, 0),
        zoom: _currentZoomLevel,
        onPositionChanged: (position, hasGesture) =>
            _positionChanged(position, hasGesture, viewModel),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: ['a', 'b', 'c'],
        ),
        CircleLayer(
          circles: _mapGroupMarkers,
        ),
        MarkerLayer(
          markers: _mapMarkers,
        ),
      ],
    );
  }

  void _moveToPosition({
    required LatLng position,
    double zoom = 18.0,
  }) {
    _latTween = Tween<double>(
      begin: _mapController.center.latitude,
      end: position.latitude,
    );

    _lngTween = Tween<double>(
      begin: _mapController.center.longitude,
      end: position.longitude,
    );

    _zoomTween = Tween<double>(
      begin: _mapController.zoom,
      end: zoom,
    );

    _mapController.move(
      LatLng(
        _latTween.evaluate(_mapAnimation),
        _lngTween.evaluate(_mapAnimation),
      ),
      _zoomTween.evaluate(_mapAnimation),
    );

    _mapAnimationController.forward();
  }

  void _positionChanged(
    MapPosition position,
    bool hasGesture,
    GroupsViewModel viewModel,
  ) {
    if (position.center != null &&
        viewModel.user.mapData.currentPosition != null &&
        (viewModel.user.mapData.currentPosition.latitude !=
                position.center!.latitude ||
            viewModel.user.mapData.currentPosition.longitude !=
                position.center!.longitude)) {
      double zoomLevel = position.zoom ?? _currentZoomLevel;
      if (zoomLevel > _maxZoomLevel) {
        _currentZoomLevel = _maxZoomLevel;
      } else if (zoomLevel < _minZoomLevel) {
        _currentZoomLevel = _minZoomLevel;
      } else {
        _currentZoomLevel = zoomLevel;
      }

      _panningDebounce?.cancel();

      _panningDebounce = Timer(const Duration(milliseconds: 250), () {
        if (hasGesture) {
          _panningPosition = position;
          _mapPanning = true;
        }

        _saveCurrentPosition(position.center!);
      });
    }
  }

  void _buildMarkers(
    GroupsViewModel viewModel,
  ) {
    _mapMarkers = [];
    _mapGroupMarkers = [];
    _mapBounds = LatLngBounds(LatLng(0, 0), LatLng(0, 0));

    if (!_mapController.ready) {
      return;
    }

    if (viewModel.groupPlaces != null) {
      for (var place in viewModel.groupPlaces) {
        double groupOpacity = (viewModel.activePlace != null &&
                viewModel.activePlace.documentId == place.documentId)
            ? 0.2
            : 0.05;

        _mapGroupMarkers.add(
          buildPlaceRadiusMarker(
            place,
            opacity: groupOpacity,
          ),
        );

        _mapMarkers.add(
          _buildPlaceMarker(viewModel, place),
        );
      }

      if (viewModel.activePlace != null) {
        LatLng latLng = LatLng(
          viewModel.activePlace.details.position[0],
          viewModel.activePlace.details.position[1],
        );

        _mapBounds.extend(latLng);
      }
    }

    if (viewModel.activeGroup != null) {
      List<GroupMember> members =
          List<GroupMember>.from(viewModel.activeGroup.members);

      if (viewModel.activeGroupMember != null) {
        final activeMember = members.firstWhere(
            (member) => member.uid == viewModel.activeGroupMember!.uid);
        members.remove(activeMember);
        members.add(activeMember);
      }

      for (var member in members.where((member) =>
          member.location != null && member.location.coords != null)) {
        LatLng latLng = LatLng(
          member.location.coords.latitude,
          member.location.coords.longitude,
        );

        if (viewModel.activePlace == null) {
          if (viewModel.activeGroupMember != null &&
              viewModel.activeGroupMember!.uid == member.uid) {
            _mapBounds.extend(latLng);
          } else if (viewModel.activeGroupMember == null && isOnline(member)) {
            _mapBounds.extend(latLng);
          }
        }

        _mapMarkers.add(_buildGroupMemberMarker(latLng, viewModel, member));
      }
    }

    if (_mapBounds.isValid && _panningPosition == null) {
      fitMarkerBounds(
        _mapController,
        _mapBounds,
        padding: const EdgeInsets.symmetric(
          vertical: 180.0,
          horizontal: 100.0,
        ),
      );
    }
  }

  Marker _buildGroupMemberMarker(
    LatLng latLng,
    GroupsViewModel viewModel,
    GroupMember member,
  ) {
    double paddedMarkerSize = (_markerSize + _markerPadding);

    return Marker(
      width: paddedMarkerSize,
      height: paddedMarkerSize,
      point: latLng,
      rotate: true,
      builder: (context) => InkWell(
        onTap: (viewModel.activeGroupMember?.uid != viewModel.user.documentId)
            ? () => _tapGroupMemberMarker(viewModel, member)
            : null,
        child: Tooltip(
          message: getGroupMemberName(member, viewModel: viewModel),
          preferBelow: false,
          margin: const EdgeInsets.only(bottom: 10.0),
          child: _buildUserPin(viewModel, member),
        ),
      ),
    );
  }

  Marker _buildPlaceMarker(
    GroupsViewModel viewModel,
    Place place,
  ) {
    const double iconSize = 30.0;

    return Marker(
      width: iconSize,
      height: iconSize,
      point: LatLng(
        place.details.position[0],
        place.details.position[1],
      ),
      rotate: true,
      builder: (context) => InkWell(
        onTap: (viewModel.activePlace == null)
            ? () => _tapPlaceMarker(viewModel, place)
            : null,
        child: Tooltip(
          message: place.name,
          preferBelow: false,
          child: PlacePin(
            color: place.active ? AppTheme.active() : AppTheme.primaryAccent,
            size: iconSize,
            showDot: true,
          ),
        ),
      ),
    );
  }

  UserPin _buildUserPin(
    GroupsViewModel viewModel,
    GroupMember member,
  ) {
    return UserPin(
      member: member,
      glow: _getUserGlow(viewModel, member),
    );
  }

  UserPinGlow? _getUserGlow(
    GroupsViewModel viewModel,
    GroupMember member,
  ) {
    bool locationSharingEnabled = member.hasLocationSharingEnabled();
    if (!locationSharingEnabled) {
      return UserPinGlow(
        color: AppTheme.alert(),
        innerColor: AppTheme.alertAccent(),
      );
    }

    bool driving = ActivityType.isDriving(member.location.activity.type);
    if (driving) {
      return UserPinGlow(
        outerColor: AppTheme.active(),
        innerColor: AppTheme.activeAccent(),
      );
    } else if (viewModel.activeGroupMember?.uid == member.uid) {
      return UserPinGlow(
        color: AppTheme.still(),
        innerColor: AppTheme.stillAccent(),
      );
    }

    return null;
  }

  void _saveCurrentPosition(LatLng position) {
    if (context != null) {
      final store = StoreProvider.of<AppState>(context);
      final user = store.state.user;
      if (user != null) {
        Map<String, dynamic> mapData = user.mapData?.toJson() ?? {
          'map_type': widget.mapType,
        };

        mapData['last_updated'] = getNow();
        mapData['current_position'] = {
          'latitude': position.latitude,
          'longitude': position.longitude
        };

        store.dispatch(UpdateUserMapData(mapData));
      }
    }
  }

  void _tapRequestLocationPermission() async {
    final store = StoreProvider.of<AppState>(context);
    await checkLocationPermissionStatus(store, context);
  }

  void _tapPlaceMarker(
    GroupsViewModel viewModel,
    Place place,
  ) {
    final store = StoreProvider.of<AppState>(context);
    store.dispatch(ClearActiveGroupMemberAction());
    store.dispatch(CancelUserActivityAction());
    store.dispatch(ActivatePlaceAction(place));
    store.dispatch(CancelPlaceActivityAction());
    store.dispatch(RequestPlaceActivityAction(place.documentId));
  }

  void _tapGroupMemberMarker(
    GroupsViewModel viewModel,
    GroupMember member,
  ) {
    final store = StoreProvider.of<AppState>(context);
    store.dispatch(ClearActivePlaceAction());
    store.dispatch(CancelPlaceActivityAction());
    store.dispatch(ActivateGroupMemberAction(member));
    store.dispatch(CancelUserActivityAction());
    store.dispatch(RequestUserActivityAction(member.uid));
  }

  void _tapMapType() {
    Navigator.pushNamed(context, MAP_TYPE_PAGE);
  }

  void _setMapData(GroupsViewModel viewModel) {
    if (viewModel.activeGroup != _currentGroup ||
        viewModel.activeGroupMember != _currentGroupMember ||
        viewModel.activePlace != _currentPlace) {
      setState(() {
        _currentGroup = viewModel.activeGroup;
        _currentGroupMember = viewModel.activeGroupMember;
        _currentPlace = viewModel.activePlace;
        _mapMarkers = [];
      });
    }
  }

  void _setInitialPosition(User user) {
    LatLng? position;

    if (user.mapData?.currentPosition != null) {
      position = LatLng(
        user.mapData!.currentPosition.latitude,
        user.mapData!.currentPosition.longitude,
      );
    } else if (user.location?.coords != null) {
      position = LatLng(
        user.location!.coords.latitude,
        user.location!.coords.longitude,
      );
    }

    _currentPosition = position ?? _defaultPosition();
  }

  LatLng _defaultPosition() {
    return LatLng(0, 0);
  }
}
