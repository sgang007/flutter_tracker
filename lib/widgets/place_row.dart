import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_tracker/model/groups_viewmodel.dart';
import 'package:flutter_tracker/state.dart';
import 'package:flutter_tracker/model/place.dart';
import 'package:flutter_tracker/utils/place_utils.dart';
import 'package:flutter_tracker/widgets/list_show_more.dart';
import 'package:flutter_tracker/widgets/place_icon.dart';

class PlaceRow extends StatefulWidget {
  final Place? place;
  final VoidCallback? tap;

  PlaceRow({
    this.place,
    this.tap,
  });

  @override
  State createState() => PlaceRowState();
}

class PlaceRowState extends State<PlaceRow> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return StoreConnector<AppState, GroupsViewModel>(
      converter: (store) => GroupsViewModel.fromStore(store),
      builder: (_, viewModel) => Container(
        color: Colors.white,
        child: Material(
          child: InkWell(
            onTap: widget.tap,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 8,
                    child: Container(
                      child: Wrap(
                        direction: Axis.vertical,
                        children: [
                          Text(
                            widget.place?.name ?? '',
                            style: TextStyle(fontSize: 18.0),
                          ),
                          if (widget.place?.details?.vicinity != null)
                            Text(
                              widget.place!.details.vicinity,
                              style: TextStyle(fontSize: 12.0),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
