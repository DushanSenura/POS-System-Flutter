import 'package:flutter/material.dart';

/// Helper class for showing snackbars
class SnackBarHelper {
  /// Shows a snackbar at the top of the screen
  static void showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top; // Status bar height
    final screenHeight = mediaQuery.size.height;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: screenHeight - topPadding - 150, // Position below app bar
          left: 10,
          right: 10,
        ),
        action: action,
      ),
    );
  }

  /// Shows a success snackbar at the top
  static void showSuccess(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: Colors.green);
  }

  /// Shows an error snackbar at the top
  static void showError(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: Colors.red);
  }

  /// Shows an info snackbar at the top
  static void showInfo(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: Colors.blue);
  }

  /// Shows a warning snackbar at the top
  static void showWarning(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: Colors.orange);
  }
}
