// lib/screens/daily_report/daily_report_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../models/game.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MOCK DATA — TODO: Replace with API call
// ─────────────────────────────────────────────────────────────────────────────

class _DailyRow {
  final DateTime date;
  final String dealer;
  final double tSale;  // total sale amount
  final double tWin;   // total winning payout
  // balance = tSale - tWin, computed property

  const _DailyRow({
    required this.date,
    required this.dealer,
    required this.tSale,
    required this.tWin,
  });

  double get balance => tSale - tWin;
}

// Mock dealer list — TODO: Replace with API call
const List<String> _kDealers = [
  'All Dealers',
  'Kurukkan',
  'BLT',
  'KTA',
  'SJ',
  'RANADEV',
  'AJAYAN',
  'SELF',
  'PATHRAM',
  'SALEEMV',
  'TB',
  'AKHII valli',
  'Anas',
  'Ambadi',
];

// Mock report rows — TODO: Replace with API call
// Each row = one dealer's summary for one date
// Uses today + yesterday so the table is visible with default date range.
final List<_DailyRow> _kMockRows = () {
  final today = DateTime.now();
  final yesterday = today.subtract(const Duration(days: 1));
  return [
    // Yesterday entries
    _DailyRow(date: yesterday, dealer: 'Kurukkan',  tSale: 4500,  tWin: 1200),
    _DailyRow(date: yesterday, dealer: 'BLT',       tSale: 3200,  tWin: 800),
    _DailyRow(date: yesterday, dealer: 'KTA',       tSale: 5100,  tWin: 2300),
    _DailyRow(date: yesterday, dealer: 'SJ',        tSale: 2800,  tWin: 400),
    _DailyRow(date: yesterday, dealer: 'RANADEV',   tSale: 6200,  tWin: 3100),
    _DailyRow(date: yesterday, dealer: 'AJAYAN',    tSale: 1900,  tWin: 0),
    _DailyRow(date: yesterday, dealer: 'SELF',      tSale: 7800,  tWin: 2200),
    // Today entries
    _DailyRow(date: today, dealer: 'Kurukkan',  tSale: 3900,  tWin: 1600),
    _DailyRow(date: today, dealer: 'BLT',       tSale: 2600,  tWin: 700),
    _DailyRow(date: today, dealer: 'KTA',       tSale: 4400,  tWin: 900),
    _DailyRow(date: today, dealer: 'PATHRAM',   tSale: 5500,  tWin: 1800),
    _DailyRow(date: today, dealer: 'SALEEMV',   tSale: 3300,  tWin: 550),
    _DailyRow(date: today, dealer: 'Anas',      tSale: 4200,  tWin: 1900),
    _DailyRow(date: today, dealer: 'Ambadi',    tSale: 3100,  tWin: 600),
  ];
}();

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
  String _selectedDealer = 'All Dealers';
  // Default dates = today (both FROM and TO)
  late DateTime _fromDate;
  late DateTime _toDate;
  // Game type selector — 'All Games' means no filter
  String _selectedGameId = 'All Games';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, now.day);
    _toDate   = DateTime(now.year, now.month, now.day);
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

  // ── Filtered rows ─────────────────────────────────────────────────────────

  List<_DailyRow> get _filteredRows {
    // TODO: API call — fetch rows filtered by dealer, date range, game type
    return _kMockRows.where((r) {
      // Dealer filter
      if (_selectedDealer != 'All Dealers' && r.dealer != _selectedDealer) {
        return false;
      }
      // Date range filter
      final d    = DateTime(r.date.year, r.date.month, r.date.day);
      final from = DateTime(_fromDate.year, _fromDate.month, _fromDate.day);
      final to   = DateTime(_toDate.year, _toDate.month, _toDate.day);
      if (d.isBefore(from) || d.isAfter(to)) return false;
      // Note: Game type filter sent as param in API call; not filterable on
      // mock data since _DailyRow doesn't carry a gameId field in this mock.
      return true;
    }).toList();
  }

  double get _totalSale =>
      _filteredRows.fold(0.0, (s, r) => s + r.tSale);
  double get _totalWin =>
      _filteredRows.fold(0.0, (s, r) => s + r.tWin);
  double get _totalBalance => _totalSale - _totalWin;

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

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// Formats a balance with explicit +/- sign.
  String _fmtBalance(double v) =>
      v >= 0 ? '+${v.toStringAsFixed(0)}' : v.toStringAsFixed(0);

  // ── Dealer picker ─────────────────────────────────────────────────────────

  void _showDealerPicker(Color accentColor) {
    showDialog(
      context: context,
      builder: (ctx) => _PickerDialog(
        title: 'Select Dealer',
        items: _kDealers,
        selected: _selectedDealer,
        accentColor: accentColor,
        onSelected: (v) {
          Navigator.of(ctx).pop();
          setState(() => _selectedDealer = v);
        },
      ),
    );
  }

  // ── Game type picker ──────────────────────────────────────────────────────

  void _showGamePicker(Color accentColor) {
    // Build display list: 'All Games' + each game's displayName
    final gameLabels = ['All Games', ...mockGames.map((g) => g.displayName)];
    showDialog(
      context: context,
      builder: (ctx) => _PickerDialog(
        title: 'Select Game',
        items: gameLabels,
        selected: _selectedGameId == 'All Games'
            ? 'All Games'
            : (mockGames
                    .cast<Game?>()
                    .firstWhere(
                      (g) => g!.id == _selectedGameId,
                      orElse: () => null,
                    )
                    ?.displayName ??
                'All Games'),
        accentColor: accentColor,
        onSelected: (label) {
          Navigator.of(ctx).pop();
          if (label == 'All Games') {
            setState(() => _selectedGameId = 'All Games');
          } else {
            final matched = mockGames.cast<Game?>().firstWhere(
                  (g) => g!.displayName == label,
                  orElse: () => null,
                );
            if (matched != null) {
              setState(() => _selectedGameId = matched.id);
            }
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

  void _onSearch() {
    // TODO: API call — pass _selectedDealer, _selectedGameId, _fromDate, _toDate
    setState(() {}); // re-filter mock data for now
  }

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
    final rows = _filteredRows;

    return Scaffold(
      backgroundColor: AppColors.dashboardBg,
      body: Column(
        children: [
          // ── Gradient header ──
          _DailyReportHeader(
            gameName: widget.gameName,
            gameId: widget.gameId,
            headerColors: headerColors,
          ),
          // ── Filters panel ──
          _buildFiltersPanel(accentColor, headerColors),
          // ── Table ──
          Expanded(
            child: rows.isEmpty
                ? _buildEmptyState()
                : _buildTable(rows, accentColor),
          ),
        ],
      ),
    );
  }

  // ── Filters panel ─────────────────────────────────────────────────────────

  Widget _buildFiltersPanel(Color accentColor, List<Color> headerColors) {
    final selectedGameLabel = _selectedGameId == 'All Games'
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
          // Row 1: Dealer + Game Type
          Row(
            children: [
              // Dealer selector
              Expanded(
                child: _SelectorButton(
                  icon: Icons.person_rounded,
                  label: 'Dealer',
                  value: _selectedDealer,
                  accentColor: accentColor,
                  isActive: _selectedDealer != 'All Dealers',
                  onTap: () => _showDealerPicker(accentColor),
                ),
              ),
              const SizedBox(width: 10),
              // Game type selector
              Expanded(
                child: _SelectorButton(
                  icon: Icons.sports_esports_rounded,
                  label: 'Game',
                  value: selectedGameLabel,
                  accentColor: accentColor,
                  isActive: _selectedGameId != 'All Games',
                  onTap: () => _showGamePicker(accentColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Row 2: Date range + Search button
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
              // Search button
              GestureDetector(
                onTap: _onSearch,
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
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_rounded,
                          color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text(
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

  // ── Table ─────────────────────────────────────────────────────────────────

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

  Widget _buildTable(List<_DailyRow> rows, Color accentColor) {
    const headerStyle = TextStyle(
      color: AppColors.dashboardTextDim,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.0,
    );

    // Totals for footer
    final totSale = rows.fold(0.0, (s, r) => s + r.tSale);
    final totWin  = rows.fold(0.0, (s, r) => s + r.tWin);
    final totBal  = totSale - totWin;

    return Column(
      children: [
        // ── Table header ──
        Container(
          color: AppColors.dashboardSurface2,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text('DATE', style: headerStyle),
              ),
              Expanded(
                flex: 3,
                child: Text('DEALER', style: headerStyle),
              ),
              Expanded(
                flex: 2,
                child: Text('T.SALE', textAlign: TextAlign.center, style: headerStyle),
              ),
              Expanded(
                flex: 2,
                child: Text('T.WIN', textAlign: TextAlign.center, style: headerStyle),
              ),
              Expanded(
                flex: 2,
                child: Text('BALANCE', textAlign: TextAlign.right, style: headerStyle),
              ),
            ],
          ),
        ),
        // ── Data rows ──
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
                    // Date
                    Expanded(
                      flex: 3,
                      child: Text(
                        _fmtDate(r.date),
                        style: const TextStyle(
                          color: AppColors.dashboardTextSub,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // Dealer
                    Expanded(
                      flex: 3,
                      child: Text(
                        r.dealer,
                        style: const TextStyle(
                          color: AppColors.dashboardTextPrim,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // T.Sale
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
                    // T.Win
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
                    // Balance
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
        // ── Totals footer ──
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
  final VoidCallback onTap;

  const _SelectorButton({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    required this.isActive,
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
            Icon(icon,
                color: isActive ? accentColor : AppColors.dashboardTextDim,
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
  final Color Function(String)? gameColorFn; // non-null → show game colour dots

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
            // Header
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
            // Search bar
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
                    borderSide: BorderSide(
                        color: widget.accentColor, width: 1.5),
                  ),
                ),
              ),
            ),
            Container(height: 1, color: AppColors.dashboardBorder),
            // List
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
                                  // Radio or game colour dot
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
