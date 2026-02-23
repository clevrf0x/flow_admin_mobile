// lib/screens/daily_report/daily_report_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../models/dealer.dart';
import '../../models/game.dart';
import '../../services/booking_service.dart';
import '../../services/daily_report_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class DailyReportScreen extends StatefulWidget {
  final String gameId;
  final String gameName;

  const DailyReportScreen({
    super.key,
    required this.gameId,
    required this.gameName,
  });

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  // ── Dealer state ─────────────────────────────────────────────────────────
  List<Dealer> _dealers = [];
  bool _dealersLoading = false;
  Dealer? _selectedDealer; // null = All Dealers

  // ── Report rows ──────────────────────────────────────────────────────────
  List<DailyReportRow> _rows = [];
  bool _isLoading = false;
  String? _error;

  // ── Date range (default: today → today) ──────────────────────────────────
  late DateTime _fromDate;
  late DateTime _toDate;

  // ── Game type selector ────────────────────────────────────────────────────
  String _selectedGameId = 'all'; // 'all' or one of VALID_GAME_IDS

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, now.day);
    _toDate   = DateTime(now.year, now.month, now.day);
    _fetchDealers();
    _fetchReport(); // load today's data immediately
  }

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

  // ── Formatting ────────────────────────────────────────────────────────────

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// Formats a balance with explicit +/- sign. Never shows decimals.
  String _fmtBalance(double v) =>
      v >= 0 ? '+${v.toStringAsFixed(0)}' : v.toStringAsFixed(0);

  /// Converts a "YYYY-MM-DD" string from the API to DD/MM/YYYY for display.
  String _fmtApiDate(String apiDate) {
    final parts = apiDate.split('-');
    if (parts.length != 3) return apiDate;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  // ── API calls ─────────────────────────────────────────────────────────────

  Future<void> _fetchDealers() async {
    setState(() => _dealersLoading = true);
    try {
      // TODO: API call — getDealers filtered by game access
      final dealers = await BookingService.getDealers(widget.gameId);
      if (!mounted) return;
      setState(() {
        _dealers = dealers;
        _dealersLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _dealersLoading = false);
      // Non-critical — user can still search without dealer filter
    }
  }

  Future<void> _fetchReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // TODO: API call
      final rows = await DailyReportService.fetchReport(
        startDate: '${_fromDate.year}-'
            '${_fromDate.month.toString().padLeft(2, '0')}-'
            '${_fromDate.day.toString().padLeft(2, '0')}',
        endDate: '${_toDate.year}-'
            '${_toDate.month.toString().padLeft(2, '0')}-'
            '${_toDate.day.toString().padLeft(2, '0')}',
        gameId: _selectedGameId == 'all' ? null : _selectedGameId,
        dealerId: _selectedDealer?.id,
      );
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _isLoading = false;
      });
    } on DailyReportException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load report. Please try again.';
        _isLoading = false;
      });
    }
  }

  // ── Date pickers ──────────────────────────────────────────────────────────

  Future<void> _pickFromDate(Color accentColor) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate,
      firstDate: DateTime(2020),
      lastDate: _toDate,
      builder: (ctx, child) => _darkDateTheme(accentColor, child!),
    );
    if (picked != null) setState(() => _fromDate = picked);
  }

  Future<void> _pickToDate(Color accentColor) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate,
      firstDate: _fromDate,
      lastDate: DateTime.now(),
      builder: (ctx, child) => _darkDateTheme(accentColor, child!),
    );
    if (picked != null) setState(() => _toDate = picked);
  }

  Widget _darkDateTheme(Color accentColor, Widget child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary: accentColor,
            onPrimary: Colors.white,
            surface: AppColors.dashboardSurface,
            onSurface: AppColors.dashboardTextPrim,
          ),
          dialogBackgroundColor: AppColors.dashboardSurface,
        ),
        child: child,
      );

  // ── Dealer picker ─────────────────────────────────────────────────────────

  void _showDealerPicker(Color accentColor) {
    final items = ['All Dealers', ..._dealers.map((d) => d.name)];
    final selected = _selectedDealer?.name ?? 'All Dealers';

    showDialog(
      context: context,
      builder: (ctx) => _PickerDialog(
        title: 'Select Dealer',
        items: items,
        selected: selected,
        accentColor: accentColor,
        onSelected: (name) {
          Navigator.of(ctx).pop();
          if (name == 'All Dealers') {
            setState(() => _selectedDealer = null);
          } else {
            final matched = _dealers.cast<Dealer?>().firstWhere(
                  (d) => d!.name == name,
                  orElse: () => null,
                );
            setState(() => _selectedDealer = matched);
          }
        },
      ),
    );
  }

  // ── Game type picker ──────────────────────────────────────────────────────

  void _showGamePicker(Color accentColor) {
    final gameLabels = ['All Games', ...mockGames.map((g) => g.displayName)];
    final selectedLabel = _selectedGameId == 'all'
        ? 'All Games'
        : (mockGames
                .cast<Game?>()
                .firstWhere(
                  (g) => g!.id == _selectedGameId,
                  orElse: () => null,
                )
                ?.displayName ??
            'All Games');

    showDialog(
      context: context,
      builder: (ctx) => _PickerDialog(
        title: 'Select Game',
        items: gameLabels,
        selected: selectedLabel,
        accentColor: accentColor,
        onSelected: (label) {
          Navigator.of(ctx).pop();
          if (label == 'All Games') {
            setState(() => _selectedGameId = 'all');
          } else {
            final matched = mockGames.cast<Game?>().firstWhere(
                  (g) => g!.displayName == label,
                  orElse: () => null,
                );
            if (matched != null) setState(() => _selectedGameId = matched.id);
          }
        },
        gameColorFn: (label) {
          if (label == 'All Games') return accentColor;
          final g = mockGames.cast<Game?>().firstWhere(
                (g) => g!.displayName == label,
                orElse: () => null,
              );
          if (g == null) return accentColor;
          final lum = g.gradientColors.first.computeLuminance();
          return lum < 0.08 ? AppColors.gsAccentBlue : g.gradientColors.first;
        },
      ),
    );
  }

  // ── Search ────────────────────────────────────────────────────────────────

  void _onSearch() => _fetchReport();

  // ── Build ─────────────────────────────────────────────────────────────────

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
          _DailyReportHeader(
            gameName: widget.gameName,
            gameId: widget.gameId,
            headerColors: headerColors,
          ),
          _buildFiltersPanel(accentColor, headerColors),
          Expanded(child: _buildBody(accentColor)),
        ],
      ),
    );
  }

  // ── Filters panel ─────────────────────────────────────────────────────────

  Widget _buildFiltersPanel(Color accentColor, List<Color> headerColors) {
    final selectedGameLabel = _selectedGameId == 'all'
        ? 'All Games'
        : (mockGames
                .cast<Game?>()
                .firstWhere(
                  (g) => g!.id == _selectedGameId,
                  orElse: () => null,
                )
                ?.displayName ??
            'All Games');

    return Container(
      color: AppColors.dashboardSurface,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        children: [
          // Row 1: Dealer + Game type
          Row(
            children: [
              Expanded(
                child: _SelectorButton(
                  icon: Icons.person_rounded,
                  label: 'Dealer',
                  value: _selectedDealer?.name ?? 'All Dealers',
                  accentColor: accentColor,
                  isActive: _selectedDealer != null,
                  isLoading: _dealersLoading,
                  onTap: _dealers.isEmpty
                      ? null
                      : () => _showDealerPicker(accentColor),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SelectorButton(
                  icon: Icons.sports_esports_rounded,
                  label: 'Game',
                  value: selectedGameLabel,
                  accentColor: accentColor,
                  isActive: _selectedGameId != 'all',
                  onTap: () => _showGamePicker(accentColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Row 2: Date range + Search
          Row(
            children: [
              Expanded(
                child: _DateButton(
                  label: 'FROM',
                  date: _fmtDate(_fromDate),
                  accentColor: accentColor,
                  onTap: () => _pickFromDate(accentColor),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '→',
                  style: TextStyle(
                    color: AppColors.dashboardTextDim,
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              Expanded(
                child: _DateButton(
                  label: 'TO',
                  date: _fmtDate(_toDate),
                  accentColor: accentColor,
                  onTap: () => _pickToDate(accentColor),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _isLoading ? null : _onSearch,
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: headerColors.length >= 2
                          ? [headerColors[0], headerColors.last]
                          : [headerColors[0], headerColors[0]],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.30),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      else
                        const Icon(Icons.search_rounded,
                            color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      const Text(
                        'Search',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Body (table / loading / error / empty) ────────────────────────────────

  Widget _buildBody(Color accentColor) {
    if (_isLoading && _rows.isEmpty) {
      return Center(child: CircularProgressIndicator(color: accentColor));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.dashboardLogout, size: 40),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(
                  color: AppColors.dashboardTextSub, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _fetchReport,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.dashboardBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                      color: AppColors.dashboardTextPrim,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (_rows.isEmpty) return _buildEmptyState();
    return _buildTable(_rows, accentColor);
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_rounded,
              color: AppColors.dashboardTextDim, size: 48),
          SizedBox(height: 12),
          Text(
            'No entries found',
            style: TextStyle(
                color: AppColors.dashboardTextSub,
                fontSize: 14,
                fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 4),
          Text(
            'Adjust filters and tap Search',
            style: TextStyle(
                color: AppColors.dashboardTextDim, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Table ─────────────────────────────────────────────────────────────────

  Widget _buildTable(List<DailyReportRow> rows, Color accentColor) {
    const headerStyle = TextStyle(
      color: AppColors.dashboardTextDim,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.0,
    );

    final totSale = rows.fold(0.0, (s, r) => s + r.tSale);
    final totWin  = rows.fold(0.0, (s, r) => s + r.tWin);
    final totBal  = totSale - totWin;

    return Column(
      children: [
        // Table header
        Container(
          color: AppColors.dashboardSurface2,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            children: [
              Expanded(flex: 3, child: Text('DATE', style: headerStyle)),
              Expanded(flex: 3, child: Text('DEALER', style: headerStyle)),
              Expanded(
                  flex: 2,
                  child: Text('T.SALE',
                      textAlign: TextAlign.center, style: headerStyle)),
              Expanded(
                  flex: 2,
                  child: Text('T.WIN',
                      textAlign: TextAlign.center, style: headerStyle)),
              Expanded(
                  flex: 2,
                  child: Text('BALANCE',
                      textAlign: TextAlign.right, style: headerStyle)),
            ],
          ),
        ),
        // Data rows
        Expanded(
          child: ListView.builder(
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final r = rows[index];
              final isEven = index % 2 == 0;
              final bal = r.balance;
              return Container(
                color: isEven
                    ? AppColors.dashboardBg
                    : AppColors.dashboardSurface.withOpacity(0.6),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 11),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        _fmtApiDate(r.date),
                        style: const TextStyle(
                          color: AppColors.dashboardTextSub,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        r.dealerName,
                        style: const TextStyle(
                          color: AppColors.dashboardTextPrim,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        r.tSale.toStringAsFixed(0),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.dashboardTextPrim,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        r.tWin.toStringAsFixed(0),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.dashboardLogout,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        _fmtBalance(bal),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: bal >= 0
                              ? AppColors.lskBox
                              : AppColors.dashboardLogout,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // Totals footer
        Container(
          decoration: const BoxDecoration(
            color: AppColors.dashboardSurface2,
            border: Border(
              top: BorderSide(color: AppColors.dashboardBorder, width: 1),
            ),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              const Expanded(
                flex: 6,
                child: Text(
                  'TOTAL',
                  style: TextStyle(
                    color: AppColors.dashboardTextDim,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  totSale.toStringAsFixed(0),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.dashboardTextPrim,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  totWin.toStringAsFixed(0),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.dashboardLogout,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  _fmtBalance(totBal),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: totBal >= 0
                        ? AppColors.lskBox
                        : AppColors.dashboardLogout,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SELECTOR BUTTON (dealer / game type)
// ─────────────────────────────────────────────────────────────────────────────

class _SelectorButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;
  final bool isActive;
  final bool isLoading;
  final VoidCallback? onTap;

  const _SelectorButton({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    required this.isActive,
    this.isLoading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? accentColor.withOpacity(0.08)
              : AppColors.dashboardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? accentColor.withOpacity(0.45)
                : AppColors.dashboardBorder,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            isLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      color: AppColors.dashboardTextDim,
                      strokeWidth: 1.5,
                    ),
                  )
                : Icon(icon,
                    color:
                        isActive ? accentColor : AppColors.dashboardTextDim,
                    size: 14),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.dashboardTextDim,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      color: isActive
                          ? accentColor
                          : AppColors.dashboardTextPrim,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.dashboardTextDim, size: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATE BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _DateButton extends StatelessWidget {
  final String label;
  final String date;
  final Color accentColor;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.date,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.dashboardBg,
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: AppColors.dashboardBorder, width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                color: accentColor, size: 13),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.dashboardTextDim,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _DailyReportHeader extends StatelessWidget {
  final String gameName;
  final String gameId;
  final List<Color> headerColors;

  const _DailyReportHeader({
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
        padding:
            EdgeInsets.fromLTRB(6, statusBarHeight + 4, 16, 14),
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
                'Daily Report',
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

// ─────────────────────────────────────────────────────────────────────────────
// GENERIC PICKER DIALOG (dealer + game type share the same widget)
// ─────────────────────────────────────────────────────────────────────────────

class _PickerDialog extends StatefulWidget {
  final String title;
  final List<String> items;
  final String selected;
  final Color accentColor;
  final ValueChanged<String> onSelected;
  final Color Function(String)? gameColorFn;

  const _PickerDialog({
    required this.title,
    required this.items,
    required this.selected,
    required this.accentColor,
    required this.onSelected,
    this.gameColorFn,
  });

  @override
  State<_PickerDialog> createState() => _PickerDialogState();
}

class _PickerDialogState extends State<_PickerDialog> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';

  List<String> get _filtered {
    if (_query.isEmpty) return widget.items;
    final q = _query.toLowerCase();
    return widget.items
        .where((i) => i.toLowerCase().contains(q))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController
        .addListener(() => setState(() => _query = _searchController.text));
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => FocusScope.of(context).requestFocus(_searchFocus));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    final screenH = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        height: screenH * 0.88,
        decoration: const BoxDecoration(
          color: AppColors.dashboardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              color: AppColors.dashboardSurface,
              padding: const EdgeInsets.fromLTRB(6, 14, 16, 14),
              child: Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => Navigator.of(context).pop(),
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.arrow_back_rounded,
                            color: AppColors.dashboardTextPrim, size: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: AppColors.dashboardTextPrim,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: AppColors.dashboardSurface,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                style: const TextStyle(
                    color: AppColors.dashboardTextPrim, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: const TextStyle(
                      color: AppColors.dashboardTextDim, fontSize: 15),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.dashboardTextDim, size: 20),
                  filled: true,
                  fillColor: AppColors.dashboardBg,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: AppColors.dashboardBorder, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: widget.accentColor, width: 1.5),
                  ),
                ),
              ),
            ),
            Container(height: 1, color: AppColors.dashboardBorder),
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Text('No results',
                          style: TextStyle(
                              color: AppColors.dashboardTextDim,
                              fontSize: 14)),
                    )
                  : ListView.separated(
                      padding:
                          const EdgeInsets.only(top: 8, bottom: 24),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => Container(
                        height: 1,
                        margin: const EdgeInsets.only(left: 56),
                        color: AppColors.dashboardBorder,
                      ),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isSelected = item == widget.selected;
                        final dotColor = widget.gameColorFn != null
                            ? widget.gameColorFn!(item)
                            : null;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => widget.onSelected(item),
                            highlightColor:
                                widget.accentColor.withOpacity(0.06),
                            splashColor:
                                widget.accentColor.withOpacity(0.09),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  if (dotColor != null)
                                    AnimatedContainer(
                                      duration: const Duration(
                                          milliseconds: 150),
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected
                                            ? dotColor.withOpacity(0.2)
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: isSelected
                                              ? dotColor
                                              : AppColors.dashboardBorder,
                                          width: isSelected ? 5 : 2,
                                        ),
                                      ),
                                    )
                                  else
                                    AnimatedContainer(
                                      duration: const Duration(
                                          milliseconds: 150),
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? widget.accentColor
                                              : AppColors.dashboardBorder,
                                          width: isSelected ? 6 : 2,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 18),
                                  Text(
                                    item,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isSelected
                                          ? AppColors.dashboardTextPrim
                                          : AppColors.dashboardTextSub,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
