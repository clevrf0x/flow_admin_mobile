// lib/screens/add_results/add_results_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../models/game.dart';
import '../../widgets/common_toast.dart';

class AddResultsScreen extends StatefulWidget {
  final String gameId;
  final String gameName;

  const AddResultsScreen({
    super.key,
    required this.gameId,
    required this.gameName,
  });

  @override
  State<AddResultsScreen> createState() => _AddResultsScreenState();
}

class _AddResultsScreenState extends State<AddResultsScreen> {
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _resultController = TextEditingController();
  final FocusNode _resultFocus = FocusNode();

  // TODO: Replace with API response
  final List<String> _addedResults = [];

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
    _resultController.dispose();
    _resultFocus.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final game = _game;
        final accentColor = _resolvedAccentColor(
          game?.gradientColors ?? [AppColors.primaryBlue],
        );
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: accentColor,
              onPrimary: Colors.white,
              surface: AppColors.dashboardSurface,
              onSurface: AppColors.dashboardTextPrim,
            ),
            dialogBackgroundColor: AppColors.dashboardSurface,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _handleAddResult() async {
    final value = _resultController.text.trim();
    if (value.isEmpty) {
      CommonToast.showError(context, 'Please enter a result number.');
      return;
    }

    setState(() => _isSaving = true);

    // TODO: API call to save result for _selectedDate
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    setState(() {
      _addedResults.add(value);
      _resultController.clear();
      _isSaving = false;
    });

    _resultFocus.unfocus();

    final game = _game;
    CommonToast.show(
      context,
      message: 'Result "$value" added successfully',
      type: ToastType.success,
      gradientColors: game?.gradientColors ??
          [AppColors.primaryBlue, AppColors.primaryBlueDark],
    );
  }

  Future<void> _handleDelete(int index) async {
    final value = _addedResults[index];

    // TODO: API call to delete result
    setState(() => _addedResults.removeAt(index));

    CommonToast.showInfo(context, 'Result "$value" removed.');
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day-$month-$year';
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

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: AppColors.dashboardBg,
        body: Column(
          children: [
            // Header
            _AddResultsHeader(
              gameName: widget.gameName,
              gameId: widget.gameId,
              headerColors: headerColors,
            ),
            // Scrollable body
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 28),
                children: [
                  // Date picker row
                  _buildDateRow(accentColor),
                  const SizedBox(height: 16),
                  // Result input card
                  _buildInputCard(accentColor),
                  // Results list (only shown when entries exist)
                  if (_addedResults.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildResultsList(accentColor),
                  ],
                ],
              ),
            ),
            // Add Result button
            _buildAddButton(headerColors),
          ],
        ),
      ),
    );
  }

  // ── Date picker row ──────────────────────────────────────────────────────

  Widget _buildDateRow(Color accentColor) {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.dashboardSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.dashboardBorder),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon box
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.13),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accentColor.withOpacity(0.22)),
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                color: accentColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            // Label + date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Draw Date',
                    style: const TextStyle(
                      color: AppColors.dashboardTextSub,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(_selectedDate),
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            // Tap hint
            Text(
              'Change',
              style: TextStyle(
                color: accentColor.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.dashboardTextDim,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ── Result input card ────────────────────────────────────────────────────

  Widget _buildInputCard(Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.dashboardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dashboardBorder),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label
          Text(
            'RESULT NUMBER',
            style: const TextStyle(
              color: AppColors.dashboardTextDim,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 12),
          // Input field
          Container(
            decoration: BoxDecoration(
              color: AppColors.dashboardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.dashboardBorder),
            ),
            child: TextField(
              controller: _resultController,
              focusNode: _resultFocus,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: TextStyle(
                color: accentColor,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: 6,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                hintText: '—',
                hintStyle: TextStyle(
                  color: AppColors.dashboardTextDim,
                  fontSize: 32,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 6,
                ),
              ),
              onSubmitted: (_) => _handleAddResult(),
            ),
          ),
          const SizedBox(height: 10),
          // Helper text
          Center(
            child: Text(
              'Enter the winning number for ${_formatDate(_selectedDate)}',
              style: const TextStyle(
                color: AppColors.dashboardTextDim,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Added results list ───────────────────────────────────────────────────

  Widget _buildResultsList(Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'ADDED RESULTS',
            style: const TextStyle(
              color: AppColors.dashboardTextDim,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.dashboardSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.dashboardBorder),
          ),
          child: Column(
            children: [
              for (int i = 0; i < _addedResults.length; i++) ...[
                _ResultRow(
                  index: i,
                  value: _addedResults[i],
                  accentColor: accentColor,
                  onDelete: () => _handleDelete(i),
                ),
                if (i < _addedResults.length - 1)
                  Container(
                    height: 1,
                    margin: const EdgeInsets.only(left: 68),
                    color: AppColors.dashboardBorder,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Add button ───────────────────────────────────────────────────────────

  Widget _buildAddButton(List<Color> headerColors) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.dashboardSurface,
        border: Border(
          top: BorderSide(color: AppColors.dashboardBorder, width: 1),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: _isSaving ? null : _handleAddResult,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: headerColors.length >= 2
                    ? [headerColors[0], headerColors.last]
                    : [headerColors[0], headerColors[0]],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              height: 52,
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
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded,
                            color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Add Result',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
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
// RESULT ROW
// ─────────────────────────────────────────────────────────────────────────────

class _ResultRow extends StatelessWidget {
  final int index;
  final String value;
  final Color accentColor;
  final VoidCallback onDelete;

  const _ResultRow({
    required this.index,
    required this.value,
    required this.accentColor,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          // Index badge
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.13),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accentColor.withOpacity(0.22)),
            ),
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: accentColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Result number
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.dashboardTextPrim,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ),
          // Delete button
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.dashboardLogout.withOpacity(0.1),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: AppColors.dashboardLogout.withOpacity(0.25),
                ),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: AppColors.dashboardLogout.withOpacity(0.8),
                size: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _AddResultsHeader extends StatelessWidget {
  final String gameName;
  final String gameId;
  final List<Color> headerColors;

  const _AddResultsHeader({
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
                      horizontal: 10, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chevron_left_rounded,
                          color: Colors.white, size: 22),
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
            // Title
            const Expanded(
              child: Text(
                'Add Results',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            // Home button
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
                  child: const Icon(Icons.home_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
