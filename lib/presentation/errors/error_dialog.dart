import 'package:flutter/material.dart';

/// The apology shown once when an error escapes the widget tree. The user
/// must tap through it — it cannot be dismissed by tapping the barrier —
/// since [showErrorDialog] always follows it with a return to the home page.
class ErrorDialog extends StatelessWidget {
  const ErrorDialog({super.key});

  static const String title = 'Oops, something went wrong';
  static const String message =
      'Something unexpected happened, and we are taking you back to the '
      'home page.';
  static const String acknowledge = 'Understand';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(title),
      content: const Text(message),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(acknowledge),
        ),
      ],
    );
  }
}

/// Shows [ErrorDialog] above [context], blocking barrier dismissal so the
/// user must explicitly acknowledge it.
Future<void> showErrorDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const ErrorDialog(),
  );
}
