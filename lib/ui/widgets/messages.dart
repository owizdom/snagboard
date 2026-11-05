import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
