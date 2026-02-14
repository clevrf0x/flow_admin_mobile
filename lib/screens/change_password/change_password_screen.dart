// lib/screens/change_password/change_password_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../models/game.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String gameId;
  final String gameName;

  const ChangePasswordScreen({
    super.key,
    required this.gameId,
    required this.gameName,
  });

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _currentFocus = FocusNode();
  final _newFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _currentVisible = false;
  bool _newVisible = false;
  bool _confirmVisible = false;

  bool _currentFocused = false;
  bool _newFocused = false;
  bool _confirmFocused = false;

  // Validation state
  String? _errorMessage;
  bool _isSaving = false;

  Game? get _game {
    try {
      return mockGames.firstWhere((g) => g.id == widget.gameId);
    } catch (_) {
      return null;
    }
  }

  Color _resolvedAccentColor(List<Color> headerColors) {
    final luminance = headerColors.first.computeLuminance();
    if (luminance < 0.08) return AppColors.gsAccentBlue;
    return headerColors.first;
  }

  @override
  void initState() {
    super.initState();
    _currentFocus.addListener(
        () => setState(() => _currentFocused = _currentFocus.hasFocus));
    _newFocus
        .addListener(() => setState(() => _newFocused = _newFocus.hasFocus));
    _confirmFocus.addListener(
        () => setState(() => _confirmFocused = _confirmFocus.hasFocus));
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _currentFocus.dispose();
    _newFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _onSave() {
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);

    final current = _currentPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      setState(() => _errorMessage = 'All fields are required.');
      return;
    }
    if (newPass.length < 6) {
      setState(
          () => _errorMessage = 'New password must be at least 6 characters.');
      return;
    }
    if (newPass != confirm) {
      setState(() => _errorMessage = 'New passwords do not match.');
      return;
    }

    // TODO: API call to change password
    setState(() => _isSaving = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSuccessDialog();
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.dashboardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded,
                color: Color(0xFF3FB950), size: 22),
            SizedBox(width: 10),
            Text(
              'Password Changed',
              style: TextStyle(
                color: AppColors.dashboardTextPrim,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: const Text(
          'Your password has been updated successfully.',
          style: TextStyle(color: AppColors.dashboardTextSub),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go(
                '/dashboard/${widget.gameId}?gameName=${Uri.encodeComponent(widget.gameName)}',
              );
            },
            child: const Text(
              'Done',
              style: TextStyle(
                color: AppColors.gsAccentBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    final game = _game;
    final headerColors = game?.gradientColors ??
        [AppColors.primaryBlue, AppColors.primaryBlueDark];
    final accentColor = _resolvedAccentColor(headerColors);

    return Scaffold(
      backgroundColor: AppColors.dashboardBg,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            _ChangePasswordHeader(
              gameName: widget.gameName,
              gameId: widget.gameId,
              headerColors: headerColors,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel('CURRENT PASSWORD'),
                    const SizedBox(height: 8),
                    _buildPasswordField(
                      controller: _currentPasswordController,
                      focusNode: _currentFocus,
                      isFocused: _currentFocused,
                      isVisible: _currentVisible,
                      placeholder: 'Enter current password',
                      accentColor: accentColor,
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () =>
                          FocusScope.of(context).requestFocus(_newFocus),
                      onToggleVisibility: () =>
                          setState(() => _currentVisible = !_currentVisible),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionLabel('NEW PASSWORD'),
                    const SizedBox(height: 8),
                    _buildPasswordField(
                      controller: _newPasswordController,
                      focusNode: _newFocus,
                      isFocused: _newFocused,
                      isVisible: _newVisible,
                      placeholder: 'Enter new password',
                      accentColor: accentColor,
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () =>
                          FocusScope.of(context).requestFocus(_confirmFocus),
                      onToggleVisibility: () =>
                          setState(() => _newVisible = !_newVisible),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionLabel('CONFIRM NEW PASSWORD'),
                    const SizedBox(height: 8),
                    _buildPasswordField(
                      controller: _confirmPasswordController,
                      focusNode: _confirmFocus,
                      isFocused: _confirmFocused,
                      isVisible: _confirmVisible,
                      placeholder: 'Re-enter new password',
                      accentColor: accentColor,
                      textInputAction: TextInputAction.done,
                      onEditingComplete: _onSave,
                      onToggleVisibility: () =>
                          setState(() => _confirmVisible = !_confirmVisible),
                    ),
                    // Error message
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      _buildErrorBanner(_errorMessage!),
                    ],
                    const SizedBox(height: 32),
                    _buildSaveButton(accentColor),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.dashboardTextDim,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.0,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isFocused,
    required bool isVisible,
    required String placeholder,
    required Color accentColor,
    required TextInputAction textInputAction,
    required VoidCallback onEditingComplete,
    required VoidCallback onToggleVisibility,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.dashboardSurface,
        border: Border.all(
          color: isFocused
              ? accentColor.withOpacity(0.6)
              : AppColors.dashboardBorder,
          width: isFocused ? 1.5 : 1,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: accentColor.withOpacity(0.12),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: !isVisible,
        textInputAction: textInputAction,
        onEditingComplete: onEditingComplete,
        style: const TextStyle(
          color: AppColors.dashboardTextPrim,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Icon(
              Icons.lock_outline_rounded,
              color: isFocused ? accentColor : AppColors.dashboardTextDim,
              size: 20,
            ),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
          hintText: placeholder,
          hintStyle: const TextStyle(
            color: AppColors.dashboardTextDim,
            fontSize: 15,
          ),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: Icon(
                isVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.dashboardTextDim,
                size: 20,
              ),
              onPressed: onToggleVisibility,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.dashboardLogout.withOpacity(0.1),
        border: Border.all(
          color: AppColors.dashboardLogout.withOpacity(0.35),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.dashboardLogout,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.dashboardLogout,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(Color accentColor) {
    return Material(
      borderRadius: BorderRadius.circular(14),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _isSaving ? null : _onSave,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                accentColor,
                accentColor.withOpacity(0.75),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.35),
                blurRadius: 14,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: Center(
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'SAVE PASSWORD',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _ChangePasswordHeader extends StatelessWidget {
  final String gameName;
  final String gameId;
  final List<Color> headerColors;

  const _ChangePasswordHeader({
    required this.gameName,
    required this.gameId,
    required this.headerColors,
  });

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: headerColors.length >= 2
              ? [headerColors[0], headerColors.last]
              : [headerColors[0], headerColors[0]],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(6, statusBarHeight + 4, 16, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ← Back to dashboard
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => context.go(
                  '/dashboard/$gameId?gameName=${Uri.encodeComponent(gameName)}',
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        gameName,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Centered title
            const Expanded(
              child: Text(
                'Change Password',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            // Balance spacer
            const SizedBox(width: 80),
          ],
        ),
      ),
    );
  }
}
