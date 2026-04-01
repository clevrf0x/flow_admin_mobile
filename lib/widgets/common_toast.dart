// lib/widgets/common_toast.dart

import 'package:flutter/material.dart';

enum ToastType {
  success,
  error,
  info,
  loading,
}

class CommonToast {
  CommonToast._();

  /// Show a toast with solid background color and optional icon
  ///
  /// [message] - The text to display
  /// [type] - The type of toast (success, error, info, loading)
  /// [backgroundColor] - Custom background color (uses type default if null)
  /// [duration] - How long to show the toast (default 3s, 0 = persistent)
  static void show(
    BuildContext context, {
    required String message,
    required ToastType type,
    Color? backgroundColor,
    Duration? duration,
  }) {
    final effectiveDuration = duration ?? const Duration(seconds: 3);
    final color = backgroundColor ?? _getDefaultColor(type);
    final icon = _getIcon(type);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: effectiveDuration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.25),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show a success toast with green background
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    show(
      context,
      message: message,
      type: ToastType.success,
      duration: duration,
    );
  }

  /// Show an error toast with red background
  static void showError(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    show(
      context,
      message: message,
      type: ToastType.error,
      duration: duration ?? const Duration(seconds: 4),
    );
  }

  /// Show an info toast with blue background
  static void showInfo(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    show(
      context,
      message: message,
      type: ToastType.info,
      duration: duration,
    );
  }

  /// Show a loading toast with custom background color
  /// Returns immediately - caller should dismiss manually if needed
  static void showLoading(
    BuildContext context,
    String message, {
    required Color backgroundColor,
  }) {
    show(
      context,
      message: message,
      type: ToastType.loading,
      backgroundColor: backgroundColor,
      duration: const Duration(seconds: 10), // Long duration for loading
    );
  }

  static Color _getDefaultColor(ToastType type) {
    switch (type) {
      case ToastType.success:
        return const Color(0xFF2E7D32); // Green
      case ToastType.error:
        return const Color(0xFFD32F2F); // Red
      case ToastType.info:
        return const Color(0xFF1976D2); // Blue
      case ToastType.loading:
        return const Color(0xFF1976D2); // Blue
    }
  }

  static IconData? _getIcon(ToastType type) {
    switch (type) {
      case ToastType.success:
        return Icons.check_circle_rounded;
      case ToastType.error:
        return Icons.error_rounded;
      case ToastType.info:
        return Icons.info_rounded;
      case ToastType.loading:
        return Icons.hourglass_empty_rounded;
    }
  }
}
