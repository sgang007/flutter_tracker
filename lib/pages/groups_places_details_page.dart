import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_tracker/actions.dart';
import 'package:flutter_tracker/colors.dart';
import 'package:flutter_tracker/model/group.dart';
import 'package:flutter_tracker/model/groups_viewmodel.dart';
import 'package:flutter_tracker/model/place.dart';
import 'package:flutter_tracker/routes.dart';
import 'package:flutter_tracker/state.dart';
import 'package:flutter_tracker/utils/app_utils.dart';
import 'package:flutter_tracker/utils/common_utils.dart';
import 'package:flutter_tracker/utils/group_utils.dart';
import 'package:flutter_tracker/utils/place_utils.dart';
import 'package:flutter_tracker/widgets/backdrop.dart';
import 'package:flutter_tracker/widgets/list_divider.dart';
import 'package:flutter_tracker/widgets/place_map.dart';
import 'package:flutter_tracker/widgets/section_header.dart';
import 'package:flutter_tracker/widgets/text_field.dart';
import 'package:flutter_tracker/widgets/user_avatar.dart';
import 'package:latlong2/latlong.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:sticky_headers/sticky_headers/widget.dart';

class GroupsPlacesDetailsPage extends StatefulWidget {
  GroupsPlacesDetailsPage({
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _GroupsPlacesDetailsPageState();
}

class _GroupsPlacesDetailsPageState extends State<GroupsPlacesDetailsPage>
    with TickerProviderStateMixin {
  late AnimationController _detailsBackdropAnimationController;
  late AnimationController _savingBackdropAnimationController;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _built = false;
  bool _isProcessing = false;
  bool _autoValidate = true;

  PlaceMap? _map;
  LatLng? _position;
  double? _zoneDistance;
  String? _name;
  String? _address;
  Map<dynamic, dynamic>? _notifications;

  @override
  void initState() {
    super.initState();

    setState(() {
      _detailsBackdropAnimationController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 350),
      );

      _savingBackdropAnimationController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 350),
      );

      _autoValidate = true;
    });
  }

  @override
  void dispose() {
    _detailsBackdropAnimationController.dispose();
    _savingBackdropAnimationController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return StoreConnector<AppState, GroupsViewModel>(
      converter: (store) => GroupsViewModel.fromStore(store),
      builder: (_, viewModel) {
        _isProcessing = _savingBackdropAnimationController.isCompleted;

        return WillPopScope(
          onWillPop: () {
            final store = StoreProvider.of<AppState>(context);
            store.dispatch(ClearActivePlaceAction());
            store.dispatch(CancelPlaceActivityAction());
            store.dispatch(NavigatePopAction());
            return Future.value(true);
          },
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: _buildBar(context, viewModel),
            body: _createContent(context, viewModel),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildBar(
    BuildContext context,
    GroupsViewModel viewModel,
  ) {
    return AppBar(
      title: Text(
        'Place Details',
        style: TextStyle(fontSize: 18.0),
      ),
      titleSpacing: 0.0,
      actions: <Widget>[
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primary,
            shape: CircleBorder(),
          ),
          onPressed: () => _tapSave(viewModel),
          child: Text('Save'),
        ),
      ],
    );
  }

  Widget _createContent(
    BuildContext context,
    GroupsViewModel viewModel,
  ) {
    List<Widget> children = [
      _buildDetails(viewModel),
      _buildNotifications(viewModel),
    ]..addAll(_buildDeleteButton(viewModel));

    if (_map == null) {
      _map = PlaceMap(
        initialDistance: ((viewModel.activePlace == null) ||
                (viewModel.activePlace?.distance == null))
            ? 100.0
            : viewModel.activePlace!.distance,
        positionCallback: (
          LatLng position,
          double zoneDistance,
        ) {
          _position = position;
          _zoneDistance = zoneDistance;
        },
      );
    }

    return Stack(
      children: [
        Form(
          key: _formKey,
          autovalidateMode: _autoValidate ? AutovalidateMode.always : AutovalidateMode.disabled,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _map!,
              ]..addAll(filterNullWidgets(children)),
            ),
          ),
        ),
        showLoadingBackdrop(
          _savingBackdropAnimationController,
          backdropColor: Colors.white,
          condition: _isProcessing,
        )
      ],
    );
  }

  Widget? _buildDetails(
    GroupsViewModel viewModel,
  ) {
    Place? activePlace = viewModel.activePlace;
    if (activePlace != null) {
      if (viewModel.searchingPlaces) {
        _detailsBackdropAnimationController.forward();
      } else if (_detailsBackdropAnimationController.isCompleted) {
        _detailsBackdropAnimationController.reverse();
        _updateForm(activePlace);
      }
    }

    if (!_built) {
      _updateForm(activePlace);
      _built = true;
    }

    return StickyHeader(
      header: SectionHeader(text: 'Place Details'),
      content: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 10.0,
              horizontal: 10.0,
            ),
            child: Column(
              children: [
                CustomTextField(
                  controller: _nameController,
                  hintText: 'Name this Place. Ex: Home',
                  icon: Icons.bookmark,
                  onSaved: (String? val) => _name = val,
                ),
                CustomTextField(
                  controller: _addressController,
                  hintText: 'Address',
                  icon: Icons.location_on,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  onSaved: (String? val) => _address = val,
                ),
              ],
            ),
          ),
          showLoadingBackdrop(
            _detailsBackdropAnimationController,
            condition: viewModel.searchingPlaces,
            backdropColor: Colors.white,
            opacity: 0.9,
          ),
        ],
      ),
    );
  }

  Widget? _buildNotifications(
    GroupsViewModel viewModel,
  ) {
    List<GroupMember>? filtered = filteredGroupMembers(
      viewModel.activeGroup,
      viewModel.user,
    );

    if ((filtered == null) || (filtered.isEmpty)) {
      return null;
    }

    if (_notifications == null) {
      _buildNotificationMap(viewModel, filtered);
    }

    return StickyHeader(
      header: SectionHeader(text: 'Notifications'),
      content: Container(
        child: Column(
          children: _buildMembers(viewModel, filtered),
        ),
      ),
    );
  }

  List<Widget> _buildMembers(
    GroupsViewModel viewModel,
    List<GroupMember> filtered,
  ) {
    List<Widget> tiles = [];

    if (filtered.isNotEmpty) {
      filtered.forEach((member) {
        tiles
          ..add(
            ListTile(
              title: Text(
                getGroupMemberName(member, viewModel: viewModel),
                style: TextStyle(fontSize: 16.0),
              ),
              leading: UserAvatar(
                user: member,
                imageUrl: member.imageUrl,
                avatarRadius: 24.0,
              ),
              trailing: _buildEnteringToggle(viewModel, member),
              contentPadding: const EdgeInsets.only(
                left: 10.0,
                right: 0.0,
                top: 5.0,
                bottom: 0.0,
              ),
            ),
          );

        tiles
          ..add(
            ListTile(
              trailing: _buildLeavingToggle(viewModel, member),
              contentPadding: const EdgeInsets.only(
                left: 10.0,
                right: 0.0,
                top: 0.0,
                bottom: 5.0,
              ),
            ),
          );

        tiles..add(ListDivider());
      });
    }

    return tiles;
  }

  Widget _buildEnteringToggle(
    GroupsViewModel viewModel,
    GroupMember member,
  ) {
    PlaceEventType type = PlaceEventType.ENTERING;
    return _buildToggle(
        viewModel, member, getEventText(type), getEventType(type));
  }

  Widget _buildLeavingToggle(
    GroupsViewModel viewModel,
    GroupMember member,
  ) {
    PlaceEventType type = PlaceEventType.LEAVING;
    return _buildToggle(
        viewModel, member, getEventText(type), getEventType(type));
  }

  Widget _buildToggle(
    GroupsViewModel viewModel,
    GroupMember member,
    String text,
    String type,
  ) {
    return SizedBox(
      width: 150.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Text(
            text,
            style: TextStyle(fontSize: 16.0),
          ),
          Switch(
            onChanged: (value) =>
                _onSwitchChanged(value, member, viewModel, type),
            value: _isToggled(viewModel, member, type),
            activeColor: AppTheme.primary,
            activeTrackColor: AppTheme.inactive(),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppTheme.inactive(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDeleteButton(GroupsViewModel viewModel) {
    if ((viewModel.activePlace == null) ||
        (viewModel.activePlace?.documentId == null)) {
      return [];
    }

    return [
      SectionHeader(text: 'Delete Place'),
      Row(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: StadiumBorder(),
                ),
                child: Text('Delete Place'),
                onPressed: () => _tapDelete(viewModel),
              ),
            ),
          ),
        ],
      ),
    ];
  }

  void _onSwitchChanged(
    bool value,
    GroupMember member,
    GroupsViewModel viewModel,
    String type,
  ) {
    setState(() {
      _notifications?[viewModel.user.documentId]?[member.uid]?[type] = value;
    });
  }

  bool _isToggled(
    GroupsViewModel viewModel,
    GroupMember member,
    String type,
  ) {
    dynamic notificationData = _notifications?[viewModel.user.documentId];
    if (notificationData?.containsKey(member.uid) ?? false) {
      bool? doNotification =
          _notifications?[viewModel.user.documentId]?[member.uid]?[type];
      return doNotification ?? false;
    }

    return false;
  }

  bool _tapSave(
    GroupsViewModel viewModel,
  ) {
    _savingBackdropAnimationController.forward();

    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      final store = StoreProvider.of<AppState>(context);
      Place? place = viewModel.activePlace;
      if (place != null) {
        place.name = _name;
        place.distance = _zoneDistance;

        if (_notifications != null) {
          if (place.notifications == null) {
            place.notifications = _notifications;
          } else {
            // Merge the maps to prevent data loss
            place.notifications = {}
              ..addAll(place.notifications!)
              ..addAll(_notifications!);
          }
        }

        if (place.details == null) {
          place.details = PlaceDetail.fromJson({
            'vicinity': _address,
          });
        } else {
          place.details.vicinity = _address;
        }

        // Allows the user to override the place position from the form
        if (_position != null) {
          place.details.position = [
            _position!.latitude,
            _position!.longitude,
          ];
        }

        if (place.documentId == null) {
          store.dispatch(
            SavePlaceAction(
              Place.create(
                _name!,
                place.details,
                groupId: viewModel.activeGroup!.documentId,
                distance: _zoneDistance,
                notifications: _notifications,
              ),
              _savingBackdropAnimationController,
            ),
          );
        } else {
          store.dispatch(
            UpdatePlaceAction(
              place.documentId!,
              Place().toMap(place),
              _savingBackdropAnimationController,
            ),
          );
        }

        closeKeyboard(context);
        return true;
      }
    }

    _isProcessing = false;
    _savingBackdropAnimationController.reverse();
    return false;
  }

  void _tapDelete(
    GroupsViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('DELETE PLACE'),
        content: Text('Are you sure you want to delete this place?'),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              final store = StoreProvider.of<AppState>(context);
              store.dispatch(
                DeletePlaceAction(
                  viewModel.activePlace!.documentId!,
                  _savingBackdropAnimationController,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
```
