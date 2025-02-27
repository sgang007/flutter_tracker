import 'package:flutter/material.dart';

enum MessageType { INFO, SUCCESS, WARNING, ERROR }

class Message {
  final String message;
  final int duration;
  final MessageType type;
  final double iconSize;
  final double padding;
  final double? bottomOffset;

  Message({
    required this.message,
    this.duration = 2,
    this.type = MessageType.INFO,
    this.iconSize = 28.0,
    this.padding = 8.0,
    this.bottomOffset,
  });

  IconData getIcon() {
    switch (type) {
      case MessageType.SUCCESS:
        return Icons.check_circle;
      case MessageType.WARNING:
        return Icons.warning;
      case MessageType.ERROR:
        return Icons.error;
      case MessageType.INFO:
      default:
        return Icons.info;
    }
  }

  Color getColor() {
    switch (type) {
      case MessageType.SUCCESS:
        return Colors.green;
      case MessageType.WARNING:
        return Colors.orange;
      case MessageType.ERROR:
        return Colors.red;
      case MessageType.INFO:
      default:
        return Colors.blue;
    }
  }
}

enum PushMessageType {
  CHECKIN,
  JOIN_GROUP,
  LEAVE_GROUP,
  ENTERING_GEOFENCE,
  LEAVING_GEOFENCE,
  ACCOUNT_SUBSCRIBED,
  ACCOUNT_SUBSCRIPTION_UPDATED,
  ACCOUNT_UNSUBSCRIBED,
}
