import 'package:flutter/material.dart';
import 'package:flutter_tracker/colors.dart';
import 'package:flutter_tracker/model/user.dart';
import 'package:flutter_tracker/utils/common_utils.dart';
import 'package:flutter_tracker/widgets/user_image.dart';

class UserAvatar extends StatefulWidget {
  final User? user;
  final String? imageUrl;
  final double avatarRadius;
  final bool canUpdate;
  final VoidCallback? onTap;

  UserAvatar({
    Key? key,
    this.user,
    this.imageUrl,
    this.avatarRadius = 28.0,
    this.canUpdate = false,
    this.onTap,
  }) : super(key: key);

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];

    if (widget.user != null || widget.imageUrl != null) {
      widgets.add(
        UserImage(
          imageUrl: widget.imageUrl ?? widget.user?.imageUrl,
          radius: widget.avatarRadius,
        ),
      );
    } else {
      widgets.add(
        Container(
          width: widget.avatarRadius * 2,
          height: widget.avatarRadius * 2,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              getInitials(widget.user?.displayName) ?? '',
              style: TextStyle(
                color: Colors.white,
                fontSize: widget.avatarRadius * 0.8,
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: widgets,
    );
  }

  void _tapPhoto() {
    if (widget.onTap != null) {
      widget.onTap!();
    }
  }
}
