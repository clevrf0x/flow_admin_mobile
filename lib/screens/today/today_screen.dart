// lib/screens/today/today_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../models/game.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MOCK DATA — TODO: Replace with API call
// ─────────────────────────────────────────────────────────────────────────────

class _TodayEntry {
  final int no;
  final String number;
  final String lsk;
  final int count;
  final double dAmt;
  final double cAmt;

  const _TodayEntry({
    required this.no,
    required this.number,
    required this.lsk,
    required this.count,
    required this.dAmt,
    required this.cAmt,
  });
}

const List<_TodayEntry> _kMockEntries = [
  _TodayEntry(no: 1,  number: '586', lsk: 'SUPER', count: 10,  dAmt: 90,   cAmt: 100),
  _TodayEntry(no: 2,  number: '586', lsk: 'BOX',   count: 5,   dAmt: 270,  cAmt: 300),
  _TodayEntry(no: 3,  number: '125', lsk: 'SUPER', count: 20,  dAmt: 180,  cAmt: 200),
  _TodayEntry(no: 4,  number: '125', lsk: 'BOX',   count: 8,   dAmt: 432,  cAmt: 480),
  _TodayEntry(no: 5,  number: '340', lsk: 'BOTH',  count: 15,  dAmt: 135,  cAmt: 150),
  _TodayEntry(no: 6,  number: '77',  lsk: 'AB',    count: 12,  dAmt: 108,  cAmt: 120),
  _TodayEntry(no: 7,  number: '77',  lsk: 'AC',    count: 6,   dAmt: 54,   cAmt: 60),
  _TodayEntry(no: 8,  number: '99',  lsk: 'BC',    count: 25,  dAmt: 225,  cAmt: 250),
  _TodayEntry(no: 9,  number: '5',   lsk: 'A',     count: 30,  dAmt: 270,  cAmt: 300),
  _TodayEntry(no: 10, number: '5',   lsk: 'B',     count: 18,  dAmt: 162,  cAmt: 180),
  _TodayEntry(no: 11, number: '3',   lsk: 'C',     count: 22,  dAmt: 198,  cAmt: 220),
  _TodayEntry(no: 12, number: '812', lsk: 'BOX',   count: 4,   dAmt: 216,  cAmt: 240),
  _TodayEntry(no: 13, number: '461', lsk: 'SUPER', count: 7,   dAmt: 63,   cAmt: 70),
  _TodayEntry(no: 14, number: '23',  lsk: 'AB',    count: 9,   dAmt: 81,   cAmt: 90),
  _TodayEntry(no: 15, number: '908', lsk: 'BOTH',  count: 11,  dAmt: 99,   cAmt: 110),
];

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class TodayScreen extends StatefulWidget {
  final String gameId;
  final String gameName;

  const TodayScreen({
    super.key,
    required this.gameId,
    required this.gameName,
  });

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  // Filter state
  int _selectedDigit = 0; // 0 = All, 1, 2, 3
  String _selectedLsk = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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
    _searchController.dispose();
    super.dispose();
  }

  // Filter entries based on digit mode, LSK type, and search query
  List<_TodayEntry> get _filteredEntries {
    return _kMockEntries.where((e) {
      // Digit filter
      if (_selectedDigit != 0 && e.number.length != _selectedDigit) return false;
      // LSK filter
      if (_selectedLsk != 'ALL' && e.lsk != _selectedLsk) return false;
      // Search filter
      if (_searchQuery.isNotEmpty &&
          !e.number.contains(_searchQuery) &&
          !e.lsk.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  double get _totalDAmount =>
      _filteredEntries.fold(0, (sum, e) => sum + e.dAmt);
  double get _totalCAmount =>
      _filteredEntries.fold(0, (sum, e) => sum + e.cAmt);
  int get _totalCount =>
      _filteredEntries.fold(0, (sum, e) => sum + e.count);

  // Total for the summary header (uses all entries regardless of filter)
  double get _grandTotalSales =>
      _kMockEntries.fold(0, (sum, e) => sum + e.cAmt);
  int get _grandTotalCount =>
      _kMockEntries.fold(0, (sum, e) => sum + e.count);
  double get _grandTotalDAmount =>
      _kMockEntries.fold(0, (sum, e) => sum + e.dAmt);
  double get _grandTotalCAmount =>
      _kMockEntries.fold(0, (sum, e) => sum + e.cAmt);

  Color _lskColor(String lsk) {
    switch (lsk.toUpperCase()) {
      case 'AB':    return AppColors.lskAB;
      case 'AC':    return AppColors.lskAC;
      case 'BC':    return AppColors.dashboardTextSub;
      case 'BOX':   return AppColors.lskBox;
      case 'C':     return AppColors.lskC;
      case 'BOTH':  return AppColors.lskBoth;
      case 'SUPER': return AppColors.dashboardTextSub;
      case 'A':     return AppColors.lskA;
      case 'B':     return AppColors.lskB;
      default:      return AppColors.dashboardTextSub;
    }
  }

  String _formatAmount(double amt) {
    if (amt == amt.truncateToDouble()) {
      return amt.toInt().toString();
    }
    return amt.toStringAsFixed(2);
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
    final filtered = _filteredEntries;

    return Scaffold(
      backgroundColor: AppColors.dashboardBg,
      body: Column(
        children: [
          // Header
          _TodayHeader(
            gameName: widget.gameName,
            gameId: widget.gameId,
            headerColors: headerColors,
          ),
          // Summary card
          _SummaryCard(
            headerColors: headerColors,
            accentColor: accentColor,
            totalSales: _grandTotalSales,
            totalCount: _grandTotalCount,
            totalDAmount: _grandTotalDAmount,
            totalCAmount: _grandTotalCAmount,
          ),
          // Filter bar
          _FilterBar(
            accentColor: accentColor,
            selectedDigit: _selectedDigit,
            selectedLsk: _selectedLsk,
            searchController: _searchController,
            onDigitChanged: (d) => setState(() => _selectedDigit = d),
            onLskChanged: (l) => setState(() => _selectedLsk = l),
            onSearchChanged: (q) => setState(() => _searchQuery = q),
          ),
          // Table
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState(accentColor)
                : _buildTable(filtered, accentColor),
          ),
          // Footer totals
          _FooterTotals(
            accentColor: accentColor,
            count: _totalCount,
            dAmount: _totalDAmount,
            cAmount: _totalCAmount,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color accentColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_rounded,
            color: AppColors.dashboardTextDim,
            size: 48,
          ),
          const SizedBox(height: 12),
          const Text(
            'No entries found',
            style: TextStyle(
              color: AppColors.dashboardTextSub,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try adjusting your filters',
            style: TextStyle(
              color: AppColors.dashboardTextDim,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<_TodayEntry> entries, Color accentColor) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Table header row
          Container(
            color: AppColors.dashboardSurface2,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                _headerCell('No', 32, TextAlign.center),
                _headerCell('Number', 60, TextAlign.center),
                _headerCell('LSK', 56, TextAlign.center),
                _headerCell('Count', 48, TextAlign.center),
                _headerCell('D.Amt', 0, TextAlign.right, flex: true),
                _headerCell('C.Amt', 0, TextAlign.right, flex: true),
              ],
            ),
          ),
          // Rows
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final isEven = index % 2 == 0;
              return Container(
                color: isEven
                    ? AppColors.dashboardBg
                    : AppColors.dashboardSurface.withOpacity(0.6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    // No
                    SizedBox(
                      width: 32,
                      child: Text(
                        '${entry.no}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.dashboardTextDim,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // Number
                    SizedBox(
                      width: 60,
                      child: Text(
                        entry.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.dashboardTextPrim,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    // LSK
                    SizedBox(
                      width: 56,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _lskColor(entry.lsk).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: _lskColor(entry.lsk).withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            entry.lsk,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _lskColor(entry.lsk),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Count
                    SizedBox(
                      width: 48,
                      child: Text(
                        '${entry.count}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.dashboardTextSub,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // D.Amt
                    Expanded(
                      child: Text(
                        _formatAmount(entry.dAmt),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: AppColors.dashboardTextSub,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // C.Amt
                    Expanded(
                      child: Text(
                        _formatAmount(entry.cAmt),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: AppColors.dashboardTextPrim,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String label, double width, TextAlign align,
      {bool flex = false}) {
    final text = Text(
      label,
      textAlign: align,
      style: const TextStyle(
        color: AppColors.dashboardTextDim,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
    if (flex) {
      return Expanded(child: text);
    }
    return SizedBox(width: width, child: text);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _TodayHeader extends StatelessWidget {
  final String gameName;
  final String gameId;
  final List<Color> headerColors;

  const _TodayHeader({
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
                'Today',
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

// ─────────────────────────────────────────────────────────────────────────────
// SUMMARY CARD
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final List<Color> headerColors;
  final Color accentColor;
  final double totalSales;
  final int totalCount;
  final double totalDAmount;
  final double totalCAmount;

  const _SummaryCard({
    required this.headerColors,
    required this.accentColor,
    required this.totalSales,
    required this.totalCount,
    required this.totalDAmount,
    required this.totalCAmount,
  });

  String _fmt(double v) => v == v.truncateToDouble()
      ? v.toInt().toString()
      : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr =
        '${_weekday(now.weekday)}, ${now.day} ${_month(now.month)} ${now.year}';

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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          // Date row
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  color: Colors.white54, size: 12),
              const SizedBox(width: 6),
              Text(
                dateStr,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Total sales big number
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${_fmt(totalSales)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  'Total Sales',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Stat chips row
          Row(
            children: [
              _StatChip(
                label: 'Count',
                value: '$totalCount',
                accentColor: accentColor,
              ),
              const SizedBox(width: 10),
              _StatChip(
                label: 'D.Amount',
                value: '₹${_fmt(totalDAmount)}',
                accentColor: accentColor,
              ),
              const SizedBox(width: 10),
              _StatChip(
                label: 'C.Amount',
                value: '₹${_fmt(totalCAmount)}',
                accentColor: accentColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _weekday(int d) => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d - 1];
  String _month(int m) => [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m - 1];
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;

  const _StatChip({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTER BAR
// ─────────────────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final Color accentColor;
  final int selectedDigit;
  final String selectedLsk;
  final TextEditingController searchController;
  final ValueChanged<int> onDigitChanged;
  final ValueChanged<String> onLskChanged;
  final ValueChanged<String> onSearchChanged;

  static const List<String> _lskOptions = [
    'ALL', 'SUPER', 'BOX', 'BOTH', 'AB', 'AC', 'BC', 'A', 'B', 'C',
  ];

  const _FilterBar({
    required this.accentColor,
    required this.selectedDigit,
    required this.selectedLsk,
    required this.searchController,
    required this.onDigitChanged,
    required this.onLskChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.dashboardSurface,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        children: [
          // Search field
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.dashboardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.dashboardBorder),
            ),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              style: const TextStyle(
                color: AppColors.dashboardTextPrim,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                border: InputBorder.none,
                hintText: 'Search number or type...',
                hintStyle: const TextStyle(
                  color: AppColors.dashboardTextDim,
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.dashboardTextDim,
                  size: 16,
                ),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 34, minHeight: 0),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Digit tabs + LSK dropdown row
          Row(
            children: [
              // Digit tabs
              _DigitTab(
                label: 'All',
                value: 0,
                selected: selectedDigit == 0,
                accentColor: accentColor,
                onTap: () => onDigitChanged(0),
              ),
              const SizedBox(width: 6),
              _DigitTab(
                label: '1',
                value: 1,
                selected: selectedDigit == 1,
                accentColor: accentColor,
                onTap: () => onDigitChanged(1),
              ),
              const SizedBox(width: 6),
              _DigitTab(
                label: '2',
                value: 2,
                selected: selectedDigit == 2,
                accentColor: accentColor,
                onTap: () => onDigitChanged(2),
              ),
              const SizedBox(width: 6),
              _DigitTab(
                label: '3',
                value: 3,
                selected: selectedDigit == 3,
                accentColor: accentColor,
                onTap: () => onDigitChanged(3),
              ),
              const SizedBox(width: 10),
              // LSK dropdown
              Expanded(
                child: GestureDetector(
                  onTap: () => _showLskPicker(context),
                  child: Container(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: accentColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedLsk,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: accentColor,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLskPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.dashboardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.dashboardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Filter by LSK Type',
            style: TextStyle(
              color: AppColors.dashboardTextPrim,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          for (final lsk in _lskOptions)
            InkWell(
              onTap: () {
                onLskChanged(lsk);
                Navigator.of(context).pop();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                        color: AppColors.dashboardBorder, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      lsk,
                      style: TextStyle(
                        color: lsk == selectedLsk
                            ? accentColor
                            : AppColors.dashboardTextPrim,
                        fontSize: 13,
                        fontWeight: lsk == selectedLsk
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    if (lsk == selectedLsk) ...[
                      const Spacer(),
                      Icon(Icons.check_rounded,
                          color: accentColor, size: 16),
                    ],
                  ],
                ),
              ),
            ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

class _DigitTab extends StatelessWidget {
  final String label;
  final int value;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  const _DigitTab({
    required this.label,
    required this.value,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected
              ? accentColor.withOpacity(0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? accentColor.withOpacity(0.5)
                : AppColors.dashboardBorder,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? accentColor : AppColors.dashboardTextSub,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FOOTER TOTALS
// ─────────────────────────────────────────────────────────────────────────────

class _FooterTotals extends StatelessWidget {
  final Color accentColor;
  final int count;
  final double dAmount;
  final double cAmount;

  const _FooterTotals({
    required this.accentColor,
    required this.count,
    required this.dAmount,
    required this.cAmount,
  });

  String _fmt(double v) => v == v.truncateToDouble()
      ? v.toInt().toString()
      : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.dashboardSurface,
        border: Border(
          top: BorderSide(color: AppColors.dashboardBorder, width: 1),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Row(
        children: [
          _FooterStat(label: 'COUNT', value: '$count', accentColor: accentColor),
          _vDivider(),
          _FooterStat(
              label: 'D.AMOUNT',
              value: '₹${_fmt(dAmount)}',
              accentColor: accentColor),
          _vDivider(),
          _FooterStat(
              label: 'C.AMOUNT',
              value: '₹${_fmt(cAmount)}',
              accentColor: accentColor),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
        width: 1,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        color: AppColors.dashboardBorder,
      );
}

class _FooterStat extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;

  const _FooterStat({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.dashboardTextDim,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
