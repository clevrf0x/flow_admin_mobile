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

  const _TodayEntry({
    required this.no,
    required this.number,
    required this.lsk,
    required this.count,
  });
}

const List<_TodayEntry> _kMockEntries = [
  _TodayEntry(no: 1,  number: '586', lsk: 'SUPER', count: 10),
  _TodayEntry(no: 2,  number: '586', lsk: 'BOX',   count: 5),
  _TodayEntry(no: 3,  number: '125', lsk: 'SUPER', count: 20),
  _TodayEntry(no: 4,  number: '125', lsk: 'BOX',   count: 8),
  _TodayEntry(no: 5,  number: '340', lsk: 'BOTH',  count: 15),
  _TodayEntry(no: 6,  number: '77',  lsk: 'AB',    count: 12),
  _TodayEntry(no: 7,  number: '77',  lsk: 'AC',    count: 6),
  _TodayEntry(no: 8,  number: '99',  lsk: 'BC',    count: 25),
  _TodayEntry(no: 9,  number: '5',   lsk: 'A',     count: 30),
  _TodayEntry(no: 10, number: '5',   lsk: 'B',     count: 18),
  _TodayEntry(no: 11, number: '3',   lsk: 'C',     count: 22),
  _TodayEntry(no: 12, number: '812', lsk: 'BOX',   count: 4),
  _TodayEntry(no: 13, number: '461', lsk: 'SUPER', count: 7),
  _TodayEntry(no: 14, number: '23',  lsk: 'AB',    count: 9),
  _TodayEntry(no: 15, number: '908', lsk: 'BOTH',  count: 11),
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

  int get _totalCount =>
      _filteredEntries.fold(0, (sum, e) => sum + e.count);

  // Total for the summary header (uses all entries regardless of filter)
  // TODO: Total sales amount comes from API (dealer-specific pricing)
  int get _grandTotalCount =>
      _kMockEntries.fold(0, (sum, e) => sum + e.count);

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
            totalCount: _grandTotalCount,
            filteredCount: _totalCount,
            isFiltered: _selectedDigit != 0 ||
                _selectedLsk != 'ALL' ||
                _searchQuery.isNotEmpty,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Row(
              children: [
                _headerCell('Number', 0, TextAlign.center, flex: true),
                _headerCell('LSK', 72, TextAlign.center),
                _headerCell('Count', 72, TextAlign.center),
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
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    // Number
                    Expanded(
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
                      width: 72,
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
                      width: 72,
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
  final int totalCount;
  final int filteredCount;
  final bool isFiltered;

  const _SummaryCard({
    required this.headerColors,
    required this.accentColor,
    required this.totalCount,
    required this.filteredCount,
    required this.isFiltered,
  });

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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Left — date + big count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        color: Colors.white54, size: 11),
                    const SizedBox(width: 5),
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$totalCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Total Entries Today',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          // Right — filtered count chip, only shown when a filter is active
          if (isFiltered)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.22),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.18),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '$filteredCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Filtered',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _weekday(int d) =>
      ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d - 1];
  String _month(int m) => [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m - 1];
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final maxHeight = MediaQuery.of(ctx).size.height * 0.6;
        final bottomPad = MediaQuery.of(ctx).padding.bottom;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle + title — fixed, never scrolls
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
              // Scrollable list
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final lsk in _lskOptions)
                        InkWell(
                          onTap: () {
                            onLskChanged(lsk);
                            Navigator.of(ctx).pop();
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                    color: AppColors.dashboardBorder,
                                    width: 1),
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
                      SizedBox(height: bottomPad + 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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

