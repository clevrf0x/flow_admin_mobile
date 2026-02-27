// lib/screens/add_results/add_results_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../models/game.dart';
import '../../services/results_service.dart';
import '../../widgets/common_toast.dart';

// Number of complimentary prize fields
const int _kCompCount = 30;

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

  // 5 main prize controllers
  final List<TextEditingController> _mainControllers =
      List.generate(5, (_) => TextEditingController());
  final List<FocusNode> _mainFocusNodes =
      List.generate(5, (_) => FocusNode());

  // 30 complimentary prize controllers
  final List<TextEditingController> _compControllers =
      List.generate(_kCompCount, (_) => TextEditingController());
  final List<FocusNode> _compFocusNodes =
      List.generate(_kCompCount, (_) => FocusNode());

  bool _isSaving = false;
  bool _isLoadingResult = false;

  static const List<String> _mainLabels = [
    'First Prize',
    'Second Prize',
    'Third Prize',
    'Fourth Prize',
    'Fifth Prize',
  ];

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
    // Fetch any existing results for today on screen open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAndFill(_selectedDate);
    });
  }

  /// Fetches saved results for [date] and pre-fills all prize fields.
  /// Clears all fields if no results exist for that date.
  Future<void> _fetchAndFill(DateTime date) async {
    setState(() => _isLoadingResult = true);

    try {
      final result = await ResultsService.fetchResult(
        gameId: widget.gameId,
        date: date,
      );

      if (!mounted) return;

      if (result != null) {
        // Pre-fill with existing results
        for (int i = 0; i < 5; i++) {
          _mainControllers[i].text = result['prize_${i + 1}'] ?? '';
        }
        for (int i = 0; i < _kCompCount; i++) {
          _compControllers[i].text = result['comp_${i + 1}'] ?? '';
        }
      } else {
        // No results saved for this date — clear all fields
        for (final c in _mainControllers) {
          c.clear();
        }
        for (final c in _compControllers) {
          c.clear();
        }
      }
    } on ResultsException catch (e) {
      if (!mounted) return;
      CommonToast.showError(context, e.message);
    } catch (_) {
      // Silently ignore unexpected errors — leave fields as-is
    } finally {
      if (mounted) setState(() => _isLoadingResult = false);
    }
  }

  @override
  void dispose() {
    for (final c in _mainControllers) c.dispose();
    for (final f in _mainFocusNodes) f.dispose();
    for (final c in _compControllers) c.dispose();
    for (final f in _compFocusNodes) f.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final game = _game;
    final accentColor = _resolvedAccentColor(
      game?.gradientColors ?? [AppColors.primaryBlue],
    );
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
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
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      await _fetchAndFill(picked);
    }
  }

  Future<void> _handleSave() async {
    // Validate — first prize must be exactly 3 digits
    final firstPrize = _mainControllers[0].text.trim();
    if (firstPrize.length != 3) {
      CommonToast.showError(context, 'First Prize must be exactly 3 digits.');
      return;
    }

    setState(() => _isSaving = true);

    // Build named prize map — explicit key names, no positional array risk.
    // Each key ('prize_1'…'prize_5', 'comp_1'…'comp_30') maps directly to
    // the server field and DB column of the same name.
    final prizes = <String, String>{
      for (int i = 0; i < 5; i++)
        'prize_${i + 1}': _mainControllers[i].text.trim(),
      for (int i = 0; i < _kCompCount; i++)
        'comp_${i + 1}': _compControllers[i].text.trim(),
    };

    try {
      await ResultsService.saveResults(
        gameId: widget.gameId,
        date: _selectedDate,
        prizes: prizes,
      );

      if (!mounted) return;
      setState(() => _isSaving = false);

      final game = _game;
      CommonToast.show(
        context,
        message: 'Results saved for ${_formatDate(_selectedDate)}',
        type: ToastType.success,
        gradientColors: game?.gradientColors ??
            [AppColors.primaryBlue, AppColors.primaryBlueDark],
      );
    } on ResultsException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      CommonToast.showError(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      CommonToast.showError(context, 'Failed to save results. Please try again.');
    }
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d-$m-${date.year}';
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
            _AddResultsHeader(
              gameName: widget.gameName,
              gameId: widget.gameId,
              headerColors: headerColors,
            ),
            Expanded(
              child: Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(14, 18, 14, 28),
                    children: [
                      // Date picker
                      _buildDateRow(accentColor),
                      const SizedBox(height: 16),
                      // Main prizes card
                      _buildSectionLabel('MAIN PRIZES'),
                      const SizedBox(height: 8),
                      _buildMainPrizesCard(accentColor),
                      const SizedBox(height: 20),
                      // Complimentary prizes card
                      _buildSectionLabel('COMPLIMENTARY PRIZES'),
                      const SizedBox(height: 8),
                      _buildCompPrizesCard(accentColor),
                    ],
                  ),
                  // Loading overlay while fetching existing results
                  if (_isLoadingResult)
                    Container(
                      color: AppColors.dashboardBg.withOpacity(0.75),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: accentColor,
                          strokeWidth: 2.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Save button
            _buildSaveButton(headerColors),
          ],
        ),
      ),
    );
  }

  // ── Section label ────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.dashboardTextDim,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 2.0,
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
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.13),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accentColor.withOpacity(0.22)),
              ),
              child: Icon(Icons.calendar_month_rounded,
                  color: accentColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Win Date',
                    style: TextStyle(
                      color: AppColors.dashboardTextSub,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
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
            Text(
              'Change',
              style: TextStyle(
                color: accentColor.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.dashboardTextDim, size: 18),
          ],
        ),
      ),
    );
  }

  // ── Main prizes card (5 rows) ────────────────────────────────────────────

  Widget _buildMainPrizesCard(Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.dashboardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dashboardBorder),
      ),
      child: Column(
        children: [
          for (int i = 0; i < 5; i++) ...[
            _buildMainPrizeRow(
              index: i,
              label: _mainLabels[i],
              controller: _mainControllers[i],
              focusNode: _mainFocusNodes[i],
              nextFocus: i < 4 ? _mainFocusNodes[i + 1] : _compFocusNodes[0],
              accentColor: accentColor,
              isFirst: i == 0,
            ),
            if (i < 4)
              Container(
                height: 1,
                margin: const EdgeInsets.only(left: 68),
                color: AppColors.dashboardBorder,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildMainPrizeRow({
    required int index,
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required FocusNode nextFocus,
    required Color accentColor,
    bool isFirst = false,
  }) {
    // First prize gets a slightly highlighted treatment
    final isTop = index == 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Prize badge
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isTop
                  ? accentColor.withOpacity(0.22)
                  : accentColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isTop
                    ? accentColor.withOpacity(0.45)
                    : accentColor.withOpacity(0.18),
              ),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: accentColor,
                  fontSize: isTop ? 16 : 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isTop
                        ? AppColors.dashboardTextPrim
                        : AppColors.dashboardTextSub,
                    fontSize: isTop ? 13 : 12,
                    fontWeight:
                        isTop ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Number input — right-aligned, compact
          SizedBox(
            width: 90,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              maxLength: 3,
              textAlign: TextAlign.center,
              textInputAction: TextInputAction.next,
              onEditingComplete: () =>
                  FocusScope.of(context).requestFocus(nextFocus),
              style: TextStyle(
                color: accentColor,
                fontSize: isTop ? 22 : 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
              decoration: InputDecoration(
                isDense: true,
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 8),
                border: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.dashboardBorder,
                    width: 1.5,
                  ),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.dashboardBorder,
                    width: 1.5,
                  ),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: accentColor,
                    width: 2,
                  ),
                ),
                hintText: '000',
                hintStyle: const TextStyle(
                  color: AppColors.dashboardTextDim,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Complimentary prizes card (5-column grid of 30) ───────────────────────

  Widget _buildCompPrizesCard(Color accentColor) {
    const cols = 5;
    final rows = (_kCompCount / cols).ceil();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.dashboardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dashboardBorder),
      ),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
      child: Column(
        children: [
          for (int row = 0; row < rows; row++) ...[
            if (row > 0) const SizedBox(height: 10),
            Row(
              children: [
                for (int col = 0; col < cols; col++) ...[
                  if (col > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _buildCompCell(
                      index: row * cols + col,
                      accentColor: accentColor,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompCell({required int index, required Color accentColor}) {
    if (index >= _kCompCount) return const SizedBox.shrink();

    final isLast = index == _kCompCount - 1;
    final nextNode = isLast ? null : _compFocusNodes[index + 1];

    return Column(
      children: [
        // Cell number label
        Text(
          '${index + 1}',
          style: const TextStyle(
            color: AppColors.dashboardTextDim,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        // Input
        TextField(
          controller: _compControllers[index],
          focusNode: _compFocusNodes[index],
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(3),
          ],
          maxLength: 3,
          textAlign: TextAlign.center,
          textInputAction:
              isLast ? TextInputAction.done : TextInputAction.next,
          onEditingComplete: nextNode != null
              ? () => FocusScope.of(context).requestFocus(nextNode)
              : () => FocusScope.of(context).unfocus(),
          style: TextStyle(
            color: accentColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
          decoration: InputDecoration(
            isDense: true,
            counterText: '',
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            border: UnderlineInputBorder(
              borderSide: BorderSide(
                  color: AppColors.dashboardBorder, width: 1),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                  color: AppColors.dashboardBorder, width: 1),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: accentColor, width: 1.5),
            ),
            hintText: '—',
            hintStyle: const TextStyle(
              color: AppColors.dashboardTextDim,
              fontSize: 13,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
      ],
    );
  }

  // ── Save button ──────────────────────────────────────────────────────────

  Widget _buildSaveButton(List<Color> headerColors) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.dashboardSurface,
        border: Border(
            top: BorderSide(color: AppColors.dashboardBorder, width: 1)),
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
          onTap: (_isSaving || _isLoadingResult) ? null : _handleSave,
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
                        Icon(Icons.save_rounded,
                            color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Save Results',
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
                        color: Colors.white.withOpacity(0.35), width: 1),
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
