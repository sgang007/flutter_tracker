import 'package:flutter/material.dart';
import 'package:flutter_tracker/colors.dart';
import 'package:flutter_tracker/model/user.dart';
import 'package:flutter_tracker/utils/icon_utils.dart';

class ActivityIcon extends StatelessWidget {
  final ActivityType type;
  final double iconSize;
  final double radius;
  final Color? color;

  ActivityIcon({
    required this.type,
    this.iconSize = 22.0,
    this.radius = 20.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: color ?? AppTheme.primary,
        shape: BoxShape.circle,
      ),
      child: Icon(
        getActivityIcon(type),
        color: Colors.white,
        size: iconSize,
      ),
    );
  }
}
