import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snagboard/data/models.dart';
import 'package:snagboard/ui/theme.dart';

/// Full-width flat button: ink by default, flare when [accent] is true.
/// While [loading] it shows a spinner and cannot be pressed.
class InkButton extends StatelessWidget {
  const InkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.accent = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final style = accent
        ? FilledButton.styleFrom(
            backgroundColor: Snag.flare,
            foregroundColor: Snag.ink,
            side: Snag.border,
          )
        : null;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: style,
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Text(label),
      ),
    );
  }
}

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
              icon: Icon(
                _hidden
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () => setState(() => _hidden = !_hidden),
            )
          : null,
    ),
  );
}

/// Turns an exception into the short text a person should read.
String errorMessage(Object error) {
  var text = error.toString();
  for (final prefix in ['Exception: ', 'Bad state: ']) {
    if (text.startsWith(prefix)) text = text.substring(prefix.length);
  }
  return text;
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Runs a controller action and returns the error message, or null on
/// success. Controllers may either throw or put the failure in their state,
/// so both are checked. [read] returns the controller's AsyncValue.
Future<String?> runAction(
  ProviderContainer container,
  Future<void> Function() action,
  AsyncValue<void> Function(ProviderContainer) read,
) async {
  try {
    await action();
  } catch (e) {
    return errorMessage(e);
  }
  final state = read(container);
  if (state.hasError) return errorMessage(state.error!);
  return null;
}

/// An error message with a retry button. [retryKey] goes on the button.
class ErrorPanel extends StatelessWidget {
  const ErrorPanel({
    super.key,
    required this.message,
    required this.onRetry,
    this.retryKey,
    this.extra,
  });
  final String message;
  final VoidCallback onRetry;
  final Key? retryKey;

  /// Optional second action under RETRY (e.g. sign out).
  final Widget? extra;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SOMETHING WENT WRONG',
            style: Snag.label(size: 14, color: Snag.danger),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Snag.inkSoft),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            key: retryKey,
            onPressed: onRetry,
            child: const Text('RETRY'),
          ),
          if (extra != null) ...[const SizedBox(height: 8), extra!],
        ],
      ),
    ),
  );
}

/// Shown when a list has nothing to show. Optional [action] sits below.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.action,
  });
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: Snag.label(size: 14), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Snag.inkSoft),
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    ),
  );
}

/// Typographic page header: big mono caps title and a small line under it.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.child,
  });
  final String title;
  final String? subtitle;
  final Widget? child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            height: 1.05,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: Snag.label(size: 12, color: Snag.inkSoft)),
        ],
        if (child != null) ...[const SizedBox(height: 16), child!],
      ],
    ),
  );
}

/// A square profile picture with an ink outline: the photo if there is one,
/// otherwise the user's initials.
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.user, this.size = 72});
  final AppUser user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = user.photoUrl;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Snag.paperDeep,
        border: Border.all(color: Snag.ink, width: Snag.outline),
        borderRadius: BorderRadius.circular(Snag.radius),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: url == null
          ? Text(user.initials, style: Snag.label(size: size / 3))
          : Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  Text(user.initials, style: Snag.label(size: size / 3)),
            ),
    );
  }
}

/// An outlined, tappable option that turns ink when chosen. Used for
/// locations and urgency.
class ChoiceBox extends StatelessWidget {
  const ChoiceBox({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    excludeSemantics: true,
    label: label,
    child: InkWell(
      onTap: onTap,
      splashFactory: NoSplash.splashFactory,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? Snag.ink : null,
          border: Border.all(color: Snag.ink, width: Snag.outline),
          borderRadius: BorderRadius.circular(Snag.radius),
        ),
        child: Text(
          label,
          style: Snag.label(size: 13, color: selected ? Snag.paper : Snag.ink),
        ),
      ),
    ),
  );
}

/// A red, bold error line, used under forms and actions.
class ErrorText extends StatelessWidget {
  const ErrorText(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) => Text(
    message,
    style: const TextStyle(color: Snag.danger, fontWeight: FontWeight.w700),
  );
}
