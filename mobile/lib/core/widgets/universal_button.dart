
import 'package:flutter/material.dart';

import '../constans/app_colors.dart';
import '../constans/app_sizes.dart';



class UniversalButton extends StatelessWidget {
  const UniversalButton.filled({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = AppColors.primaryDark,
    this.outlined = false,
    this.textColor = Colors.white,
    this.fontSize = 16,
    this.height = 55,
    this.child,
    this.svg = "",
    this.centerGravity = true,
    this.enabled = true,
    this.margin = EdgeInsets.zero,
    this.svgColor = Colors.white,
    this.isDisabled = false,
    this.width = double.infinity,
    this.textFontWeight = FontWeight.bold,
    this.borderSide = 1,
    this.cornerRadius = 16,
    this.borderColor = Colors.black,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
  });

  const UniversalButton.outline(
      {super.key,
        required this.text,
        required this.onPressed,
        this.backgroundColor = Colors.transparent,
        this.outlined = true,
        this.textColor = Colors.black,
        this.fontSize = 16,
        this.height = 55,
        this.child,
        this.svg = "",
        this.centerGravity = true,
        this.enabled = true,
        this.margin = EdgeInsets.zero,
        this.svgColor = Colors.white,
        this.textFontWeight = FontWeight.bold,
        this.width = double.infinity,
        this.isDisabled = false,
        this.borderSide = 1,
        this.cornerRadius = 16,
        this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        this.borderColor = Colors.black});

  final String text;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final double fontSize;
  final double height;
  final double borderSide;
  final double cornerRadius;
  final double width;
  final bool outlined;
  final Widget? child;
  final String svg;
  final Color svgColor;
  final bool centerGravity;
  final bool enabled;
  final EdgeInsets margin;
  final FontWeight textFontWeight;
  final EdgeInsets padding;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      width: width,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: padding,
          elevation: 0,
          overlayColor: isDisabled && !outlined
              ? Colors.transparent
              : outlined
              ? AppColors.lightTextPrimary
              : Colors.white,
          shadowColor: Colors.transparent,
          backgroundColor: outlined
              ? backgroundColor
              : isDisabled
              ? Colors.grey.shade300
              : backgroundColor,
          shape: RoundedRectangleBorder(
            side: outlined
                ? BorderSide(width: borderSide, color: borderColor)
                : BorderSide.none,
            borderRadius: BorderRadius.all(
              Radius.circular(cornerRadius),
            ),
          ),
        ),
        onPressed: (!enabled) ? null : onPressed,
        child: Row(
          spacing: AppDimens.s10,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (text != "" && child == null)
              Text(
                maxLines: 2,
                textAlign: TextAlign.center,
                text,
                style: TextStyle(
                  fontFamily: 'VelaSans',
                  fontWeight: textFontWeight,
                  fontSize: fontSize,
                  color: isDisabled ? Colors.grey.shade700 : textColor,
                ),
              ),
            if (child != null) child!
          ],
        ),
      ),
    );
  }
}