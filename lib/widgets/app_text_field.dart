import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';

class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final String? Function(String?)? validator;
  final bool obscure;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? formatters;
  final TextInputAction? action;

  /// Optional left-aligned title shown above the field. When set, [label] is
  /// used as the in-field hint instead of a floating label.
  final String? title;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.validator,
    this.obscure = false,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.formatters,
    this.action,
    this.title,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final titled = widget.title != null;
    final field = TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      obscureText: _hidden,
      keyboardType: widget.keyboardType,
      maxLines: _hidden ? 1 : widget.maxLines,
      maxLength: widget.maxLength,
      inputFormatters: widget.formatters,
      textInputAction: widget.action,
      decoration: InputDecoration(
        labelText: titled ? null : widget.label,
        hintText: titled ? widget.label : null,
        counterText: '',
        prefixIcon: widget.icon == null ? null : Icon(widget.icon),
        suffixIcon: widget.obscure
            ? IconButton(
                icon: Icon(_hidden ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _hidden = !_hidden),
              )
            : null,
      ),
    );
    if (!titled) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            widget.title!,
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        field,
      ],
    );
  }
}
