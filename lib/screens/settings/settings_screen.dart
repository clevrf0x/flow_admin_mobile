// lib/screens/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../models/game.dart';
import '../../widgets/common_toast.dart';

class SettingsScreen extends StatefulWidget {
  final String gameId;
  final String gameName;

  const SettingsScreen({
    super.key,
    required this.gameId,
    required this.gameName,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Time settings (stored as TimeOfDay)
  TimeOfDay _closeTime = const TimeOfDay(hour: 12, minute: 57);
  TimeOfDay _openTime = const TimeOfDay(hour: 23, minute: 45);
  TimeOfDay _deletionTime = const TimeOfDay(hour: 12, minute: 58);

  // Total Count Settings toggles
  bool _superLimitEnabled = true;
  bool _boxLimitEnabled = true;
  bool _doubleLimitEnabled = true;
  bool _singleLimitEnabled = true;

  // Limit values
  final TextEditingController _superLimitController =
      TextEditingController(text: '400');
  final TextEditingController _boxLimitController =
      TextEditingController(text: '200');
  final TextEditingController _doubleLimitController =
      TextEditingController(text: '300');
  final TextEditingController _singleLimitController =
      TextEditingController(text: '2500');

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
  void dispose() {
    _superLimitController.dispose();
    _boxLimitController.dispose();
    _doubleLimitController.dispose();
    _singleLimitController.dispose();
    super.dispose();
  }

  Future<void> _pickTime({
    required TimeOfDay initialTime,
    required Function(TimeOfDay) onTimePicked,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: _resolvedAccentColor(
                _game?.gradientColors ?? [AppColors.primaryBlue],
              ),
              surface: AppColors.dashboardSurface,
            ),
            dialogBackgroundColor: AppColors.dashboardSurface,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onTimePicked(picked);
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);

    // TODO: API call to save settings
    // Mock delay
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    setState(() => _isSaving = false);

    // Show success toast
    final game = _game;
    final gradientColors = game?.gradientColors ??
        [AppColors.primaryBlue, AppColors.primaryBlueDark];

    CommonToast.show(
      context,
      message: 'Settings saved successfully',
      type: ToastType.success,
      gradientColors: gradientColors,
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
      body: Column(
        children: [
          _SettingsHeader(
            gameName: widget.gameName,
            gameId: widget.gameId,
            headerColors: headerColors,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 28),
              children: [
                // Time settings group
                _buildTimeSettingsGroup(accentColor),
                const SizedBox(height: 20),
                // Total Count Settings group
                _buildTotalCountSettingsGroup(accentColor),
              ],
            ),
          ),
          _buildSaveButton(headerColors),
        ],
      ),
    );
  }

  Widget _buildTimeSettingsGroup(Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.dashboardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.dashboardBorder,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildTimeSettingRow(
            label: 'Close Time (Format 03:30 PM)',
            time: _closeTime,
            accentColor: accentColor,
            isFirst: true,
            onTap: () => _pickTime(
              initialTime: _closeTime,
              onTimePicked: (picked) => setState(() => _closeTime = picked),
            ),
          ),
          _buildDivider(),
          _buildTimeSettingRow(
            label: 'Open Time (Formate 7:00 PM)',
            time: _openTime,
            accentColor: accentColor,
            onTap: () => _pickTime(
              initialTime: _openTime,
              onTimePicked: (picked) => setState(() => _openTime = picked),
            ),
          ),
          _buildDivider(),
          _buildTimeSettingRow(
            label: 'Deletion Time (Format 03:30 PM)',
            time: _deletionTime,
            accentColor: accentColor,
            isLast: true,
            onTap: () => _pickTime(
              initialTime: _deletionTime,
              onTimePicked: (picked) => setState(() => _deletionTime = picked),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSettingRow({
    required String label,
    required TimeOfDay time,
    required Color accentColor,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        highlightColor: accentColor.withOpacity(0.06),
        splashColor: accentColor.withOpacity(0.09),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              // Icon box — matches menu row style
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: accentColor.withOpacity(0.22)),
                ),
                child: Icon(
                  Icons.access_time_rounded,
                  color: accentColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              // Label + value
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.dashboardTextPrim,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      time.format(context),
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Chevron
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.dashboardTextDim,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalCountSettingsGroup(Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'TOTAL COUNT SETTINGS',
            style: TextStyle(
              color: AppColors.dashboardTextDim,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.dashboardSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.dashboardBorder,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _buildLimitRow(
                label: 'Super Limit',
                isEnabled: _superLimitEnabled,
                onToggle: (val) => setState(() => _superLimitEnabled = val),
                controller: _superLimitController,
                accentColor: accentColor,
                isFirst: true,
              ),
              _buildDivider(),
              _buildLimitRow(
                label: 'Box Limit',
                isEnabled: _boxLimitEnabled,
                onToggle: (val) => setState(() => _boxLimitEnabled = val),
                controller: _boxLimitController,
                accentColor: accentColor,
              ),
              _buildDivider(),
              _buildLimitRow(
                label: 'Double Limit',
                isEnabled: _doubleLimitEnabled,
                onToggle: (val) => setState(() => _doubleLimitEnabled = val),
                controller: _doubleLimitController,
                accentColor: accentColor,
              ),
              _buildDivider(),
              _buildLimitRow(
                label: 'Single Limit',
                isEnabled: _singleLimitEnabled,
                onToggle: (val) => setState(() => _singleLimitEnabled = val),
                controller: _singleLimitController,
                accentColor: accentColor,
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLimitRow({
    required String label,
    required bool isEnabled,
    required ValueChanged<bool> onToggle,
    required TextEditingController controller,
    required Color accentColor,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          // Toggle switch
          GestureDetector(
            onTap: () => onToggle(!isEnabled),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: isEnabled
                    ? accentColor.withOpacity(0.3)
                    : AppColors.dashboardBorder,
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment:
                    isEnabled ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 26,
                  height: 26,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isEnabled ? accentColor : AppColors.dashboardTextDim,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Label and input
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.dashboardTextSub,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text(
                      'Limit',
                      style: TextStyle(
                        color: AppColors.dashboardTextDim,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        enabled: isEnabled,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: TextStyle(
                          color: isEnabled
                              ? AppColors.dashboardTextPrim
                              : AppColors.dashboardTextDim,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 84),
      color: AppColors.dashboardBorder,
    );
  }

  Widget _buildSaveButton(List<Color> gradientColors) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.dashboardSurface,
        border: Border(
          top: BorderSide(
            color: AppColors.dashboardBorder,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea(
        top: false,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isSaving ? null : _handleSave,
            borderRadius: BorderRadius.circular(12),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors.length >= 2
                      ? [gradientColors[0], gradientColors.last]
                      : [gradientColors[0], gradientColors[0]],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                height: 54,
                alignment: Alignment.center,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
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

class _SettingsHeader extends StatelessWidget {
  final String gameName;
  final String gameId;
  final List<Color> headerColors;

  const _SettingsHeader({
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
            // ← Back to others
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => context.go(
                  '/dashboard/$gameId/others?gameName=${Uri.encodeComponent(gameName)}',
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
            // Title — centered
            const Expanded(
              child: Text(
                'Settings',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            // Home button (frosted glass)
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => context.go('/game-selection'),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.35),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.home_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
