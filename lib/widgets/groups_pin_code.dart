import 'package:flutter/material.dart';
import 'package:flutter_tracker/colors.dart';

const int GROUP_INVITE_CODE_LENGTH = 6;
const String GROUP_INVITE_CODE_SPACER_CHAR = ' ';
const int GROUP_INVITE_CODE_INDEX = 3;

class GroupsPinCode extends StatefulWidget {
  final int maxLength;
  final TextEditingController? controller;
  final bool hideCharacter;
  final bool highlight;
  final Color highlightColor;
  final String maskCharacter;
  final String spacerCharacter;
  final int spacerIndex;
  final double pinBoxWidth;
  final double pinBoxHeight;
  final Color defaultBorderColor;
  final Color hasTextBorderColor;
  final bool hasError;
  final Color errorBorderColor;
  final ValueChanged<String>? onChanged;

  GroupsPinCode({
    Key? key,
    this.maxLength = GROUP_INVITE_CODE_LENGTH,
    this.controller,
    this.hideCharacter = false,
    this.highlight = true,
    this.highlightColor = AppTheme.primaryAccent,
    this.maskCharacter = ' ',
    this.spacerCharacter = GROUP_INVITE_CODE_SPACER_CHAR,
    this.spacerIndex = GROUP_INVITE_CODE_INDEX,
    this.pinBoxWidth = 40.0,
    this.pinBoxHeight = 50.0,
    this.defaultBorderColor = AppTheme.hint,
    this.hasTextBorderColor = AppTheme.primary,
    this.hasError = false,
    this.errorBorderColor = Colors.red,
    this.onChanged,
  }) : super(key: key);

  @override
  _GroupsPinCodeState createState() => _GroupsPinCodeState();
}

class _GroupsPinCodeState extends State<GroupsPinCode> {
  double pinWidth = 0.0;
  TextEditingController? _textController;

  @override
  void initState() {
    super.initState();
    _textController = widget.controller ?? TextEditingController();
    pinWidth = widget.pinBoxWidth * widget.maxLength;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _textController?.dispose();
    }
    super.dispose();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: pinWidth,
      child: TextField(
        controller: _textController,
        maxLength: widget.maxLength,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize:
