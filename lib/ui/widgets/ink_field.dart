import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Small mono caps heading above a block of content.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(text, style: Snag.label(size: 12, color: Snag.inkSoft)),
      );
}

/// A text field in the Snagboard style (the look comes from the theme).
/// Pass `obscure` for passwords: it adds a show/hide button.
class InkField extends StatefulWidget {
  const InkField({
    super.key,
    required this.label,
    this.controller,
    this.validator,
    this.obscure = false,
    this.keyboardType,
    this.onChanged,
    this.errorText,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.textInputAction,
    this.enabled = true,
    this.hint,
    this.icon,
  });

  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscure;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final int? minLines;
  final int? maxLines;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final bool enabled;
  final String? hint;
  final IconData? icon;

  @override
  State<InkField> createState() => _InkFieldState();
}

class _InkFieldState extends State<InkField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: widget.controller,
        validator: widget.validator,
        obscureText: _hidden,
        keyboardType: widget.keyboardType,
        onChanged: widget.onChanged,
        minLines: widget.minLines,
        maxLines: widget.obscure ? 1 : widget.maxLines,
        maxLength: widget.maxLength,
        textInputAction: widget.textInputAction,
        enabled: widget.enabled,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          errorText: widget.errorText,
          errorMaxLines: 3,
          prefixIcon: widget.icon == null ? null : Icon(widget.icon),
          suffixIcon: widget.obscure
              ? IconButton(
                  tooltip: _hidden ? 'Show password' : 'Hide password',
                  icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _hidden = !_hidden),
                )
              : null,
        ),
      );
}
