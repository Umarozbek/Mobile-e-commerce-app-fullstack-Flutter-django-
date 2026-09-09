
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constans/app_colors.dart';
import '../constans/app_sizes.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    required this.hintText,
    this.maxLen,
    this.isEnabled,
    this.withDecoration = true,
    this.isDense,
    this.maxLines = 1,
    this.minLines = 1,
    this.suffix,
    this.suffixIcon,
    this.title,
    this.prefix,
    this.prefixIcon,
    this.formatter,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.readOnly = false,
    this.hintColor,
    this.textColor,
    this.isSearch = false,
    this.padding = EdgeInsets.zero,
    this.onComplete,
    this.obscureText = false,
    this.titleStyle,
    this.titleOptional,
    this.initialValue,
    this.isOnTapOutside = false,
  });

  final TextEditingController? controller;
  final bool? isEnabled;
  final bool? isDense;
  final Widget? suffix;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final Widget? prefix;
  final Widget? prefixIcon;
  final String? hintText;
  final String? title;
  final int? maxLen;
  final int? maxLines;
  final int? minLines;
  final bool withDecoration;
  final List<TextInputFormatter>? formatter;
  final FormFieldValidator<String?>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onComplete;
  final bool readOnly;
  final Color? hintColor;
  final Color? textColor;
  final bool isSearch;
  final EdgeInsets padding;
  final bool obscureText;
  final TextStyle? titleStyle;
  final String? titleOptional;
  final String? initialValue;
  final bool isOnTapOutside;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title != null) _buildTitle(),
          const SizedBox(height: 5),
          TextFormField(
            initialValue: widget.initialValue,
            controller: widget.controller,
            maxLength: widget.maxLen,
            minLines: widget.minLines,
            maxLines: widget.maxLines,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            readOnly: widget.readOnly,
            enabled: widget.isEnabled,
            onChanged: widget.onChanged,
            validator: widget.validator,
            focusNode: _focusNode,
            style: TextStyle(
              color: widget.textColor,
              fontSize: AppDimens.s16,
              fontWeight: FontWeight.w500,
            ),
            onEditingComplete: () => widget.onComplete?.call(""),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onFieldSubmitted: (value) => widget.onComplete?.call(value),
            onTapOutside: (event) {
              if (widget.isOnTapOutside) _focusNode.unfocus();
            },
            inputFormatters: widget.formatter,
            textInputAction: TextInputAction.done,
            decoration: _inputDecoration(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        SizedBox(width: AppDimens.s4),
        Text(
          widget.title!,
          style:
              widget.titleStyle ??
              const TextStyle(
                fontSize: AppDimens.s14,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(width: 8),
        if (widget.titleOptional != null)
          Text(
            widget.titleOptional!,
            style: const TextStyle(
              fontSize: AppDimens.s12,
              fontWeight: FontWeight.w400,
              color: Colors.grey,
            ),
          ),
      ],
    );
  }

  InputDecoration _inputDecoration(bool isDark) {
    final borderRadius = BorderRadius.circular(AppDimens.s10);

    OutlineInputBorder border(Color color, {double width = 1.5}) =>
        OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: color, width: width),
        );

    final fillColor = isDark
        ? AppColors.bgTertiaryDark
        : AppColors.lightBackground;
    final hintColor = _focusNode.hasFocus ? AppColors.disabledText :AppColors.disabledText;
    final enabledColor = isDark ? AppColors.borderDark : AppColors.border;

    return InputDecoration(
      hintText: widget.hintText,
      hintStyle: TextStyle(fontSize: AppDimens.s14, color: hintColor),
      prefix: widget.prefix,
      suffix: widget.suffix,
      suffixIcon: widget.suffixIcon,
      prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
      prefixIcon: widget.prefixIcon,
      filled: true,
      isDense: widget.isDense,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      counterText: "",
      border: border(enabledColor),
      enabledBorder: border(enabledColor),
      focusedBorder: border(AppColors.primary, width: 1.5),
      disabledBorder: border(enabledColor, width: 1.5),
      errorBorder: border(Colors.redAccent),
      focusedErrorBorder: border(Colors.redAccent),
      errorStyle: const TextStyle(
        fontSize: AppDimens.s10,
        fontWeight: FontWeight.w400,
        color: Colors.red,
      ),
    );
  }
}
