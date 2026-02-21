// lib/screens/daily_report/daily_report_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../models/game.dart';
import '../../widgets/common_toast.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MOCK DATA — TODO: Replace with API call
// ─────────────────────────────────────────────────────────────────────────────

class _ReportEntry {
  final String number;
  final String lsk;
  final int count;

  const _ReportEntry({
    required this.number,
    required this.lsk,
    required this.count,
  });
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

// Mock report entries per dealer — TODO: Replace with API call
const Map<String, List<_ReportEntry>> _kMockData = {
  'All Dealers': [
    _ReportEntry(number: '586', lsk: 'SUPER', count: 35),
    _ReportEntry(number: '586', lsk: 'BOX',   count: 18),
    _ReportEntry(number: '125', lsk: 'SUPER', count: 42),
    _ReportEntry(number: '125', lsk: 'BOX',   count: 14),
    _ReportEntry(number: '340', lsk: 'BOTH',  count: 27),
    _ReportEntry(number: '77',  lsk: 'AB',    count: 20),
    _ReportEntry(number: '77',  lsk: 'AC',    count: 9),
    _ReportEntry(number: '99',  lsk: 'BC',    count: 33),
    _ReportEntry(number: '5',   lsk: 'A',     count: 50),
    _ReportEntry(number: '5',   lsk: 'B',     count: 26),
    _ReportEntry(number: '3',   lsk: 'C',     count: 31),
    _ReportEntry(number: '812', lsk: 'BOX',   count: 8),
    _ReportEntry(number: '461', lsk: 'SUPER', count: 15),
    _ReportEntry(number: '23',  lsk: 'AB',    count: 11),
    _ReportEntry(number: '908', lsk: 'BOTH',  count: 19),
    _ReportEntry(number: '444', lsk: 'SUPER', count: 22),
    _ReportEntry(number: '321', lsk: 'BOX',   count: 7),
    _ReportEntry(number: '67',  lsk: 'AC',    count: 13),
    _ReportEntry(number: '890', lsk: 'BOTH',  count: 28),
    _ReportEntry(number: '11',  lsk: 'AB',    count: 16),
  ],
  'Kurukkan': [
    _ReportEntry(number: '586', lsk: 'SUPER', count: 10),
    _ReportEntry(number: '125', lsk: 'BOX',   count: 5),
    _ReportEntry(number: '77',  lsk: 'AB',    count: 8),
    _ReportEntry(number: '340', lsk: 'BOTH',  count: 12),
    _ReportEntry(number: '99',  lsk: 'BC',    count: 6),
  ],
  'BLT': [
    _ReportEntry(number: '461', lsk: 'SUPER', count: 7),
    _ReportEntry(number: '908', lsk: 'BOTH',  count: 9),
    _ReportEntry(number: '5',   lsk: 'A',     count: 15),
    _ReportEntry(number: '23',  lsk: 'AB',    count: 4),
  ],
  'SELF': [
    _ReportEntry(number: '812', lsk: 'BOX',   count: 3),
    _ReportEntry(number: '3',   lsk: 'C',     count: 11),
    _ReportEntry(number: '444', lsk: 'SUPER', count: 8),
    _ReportEntry(number: '67',  lsk: 'AC',    count: 6),
    _ReportEntry(number: '890', lsk: 'BOTH',  count: 14),
  ],
};

const List<String> _kAllLsk = [
  'ALL', 'SUPER', 'BOX', 'BOTH', 'AB', 'AC', 'BC', 'A', 'B', 'C',
];

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
  // Dealer filter
  String _selectedDealer = 'All Dealers';

  // Date range
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 6));
  DateTime _toDate = DateTime.now();

  // LSK filter
  String _selectedLsk = 'ALL';

  // Search
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

  // ── Filtered data ──────────────────────────────────────────────────────────

  List<_ReportEntry> get _sourceEntries {
    // TODO: API call — fetch entries by dealer + date range
    if (_kMockData.containsKey(_selectedDealer)) {
      return _kMockData[_selectedDealer]!;
    }
    return _kMockData['All Dealers']!;
  }

  List<_ReportEntry> get _filteredEntries {
    return _sourceEntries.where((e) {
      if (_selectedLsk != 'ALL' && e.lsk != _selectedLsk) return false;
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

  int get _grandTotalCount =>
      _sourceEntries.fold(0, (sum, e) => sum + e.count);

  bool get _isFiltered =>
      _selectedLsk != 'ALL' || _searchQuery.isNotEmpty;

  // ── Date pickers ───────────────────────────────────────────────────────────

  Future<void> _pickFromDate(Color accentColor) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate,
      firstDate: DateTime(2020),
      lastDate: _toDate,
      builder: (context, child) => _darkDatePickerTheme(accentColor, child!),
    );
    if (picked != null) setState(() => _fromDate = picked);
  }

  Future<void> _pickToDate(Color accentColor) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate,
      firstDate: _fromDate,
      lastDate: DateTime.now(),
      builder: (context, child) => _darkDatePickerTheme(accentColor, child!),
    );
    if (picked != null) setState(() => _toDate = picked);
  }

  Widget _darkDatePickerTheme(Color accentColor, Widget child) {
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
      child: child,
    );
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/${m}/${date.year}';
  }

  // ── Dealer picker ──────────────────────────────────────────────────────────

  void _showDealerPicker(Color accentColor) {
    showDialog(
      context: context,
      builder: (ctx) => _DealerPickerDialog(
        selectedDealer: _selectedDealer,
        accentColor: accentColor,
        onSelected: (dealer) {
          Navigator.of(ctx).pop();
          setState(() => _selectedDealer = dealer);
        },
      ),
    );
  }

  // ── LSK picker ────────────────────────────────────────────────────────────

  void _showLskPicker(Color accentColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.dashboardSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.dashboardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    const Text(
                      'Filter by LSK Type',
                      style: TextStyle(
                        color: AppColors.dashboardTextPrim,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedLsk != 'ALL')
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() => _selectedLsk = 'ALL');
                        },
                        child: Text(
                          'Clear',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(height: 1, color: AppColors.dashboardBorder),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _kAllLsk.map((lsk) {
                        final isSelected = lsk == _selectedLsk;
                        final color = _lskColor(lsk);
                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            setState(() => _selectedLsk = lsk);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 10),
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withOpacity(0.18)
                                  : AppColors.dashboardBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? color.withOpacity(0.6)
                                    : AppColors.dashboardBorder,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              lsk,
                              style: TextStyle(
                                color: isSelected
                                    ? color
                                    : AppColors.dashboardTextSub,
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        );
      },
    );
  }

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

  // ── Build ──────────────────────────────────────────────────────────────────

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
          // ── Page header ──
          _DailyReportHeader(
            gameName: widget.gameName,
            gameId: widget.gameId,
            headerColors: headerColors,
          ),
          // ── Summary card ──
          _buildSummaryCard(headerColors, accentColor),
          // ── Filter bar ──
          _buildFilterBar(accentColor),
          // ── Table ──
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState(accentColor)
                : _buildTable(filtered, accentColor),
          ),
        ],
      ),
    );
  }

  // ── Summary card ──────────────────────────────────────────────────────────

  Widget _buildSummaryCard(
      List<Color> headerColors, Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: headerColors.length >= 2
              ? [
                  headerColors[0].withOpacity(0.92),
                  headerColors.last.withOpacity(0.85),
                ]
              : [headerColors[0].withOpacity(0.92), headerColors[0].withOpacity(0.85)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: Row(
        children: [
          // Left: dealer + date range + entry count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_rounded,
                        color: Colors.white70, size: 13),
                    const SizedBox(width: 5),
                    Text(
                      _selectedDealer,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.date_range_rounded,
                        color: Colors.white60, size: 13),
                    const SizedBox(width: 5),
                    Text(
                      '${_formatDate(_fromDate)}  –  ${_formatDate(_toDate)}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$_grandTotalCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text(
                        'total entries',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Right: filtered chip (only when active)
          if (_isFiltered)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: Colors.white.withOpacity(0.3), width: 1),
              ),
              child: Column(
                children: [
                  const Text(
                    'Filtered',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$_totalCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Filter bar ────────────────────────────────────────────────────────────

  Widget _buildFilterBar(Color accentColor) {
    return Container(
      color: AppColors.dashboardSurface,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        children: [
          // Row 1: Dealer + Date Range
          Row(
            children: [
              // Dealer button
              Expanded(
                child: _FilterChip(
                  icon: Icons.person_outline_rounded,
                  label: _selectedDealer == 'All Dealers'
                      ? 'All Dealers'
                      : _selectedDealer,
                  accentColor: _selectedDealer != 'All Dealers'
                      ? accentColor
                      : AppColors.dashboardTextSub,
                  isActive: _selectedDealer != 'All Dealers',
                  onTap: () => _showDealerPicker(accentColor),
                ),
              ),
              const SizedBox(width: 8),
              // From date
              _FilterChip(
                icon: Icons.calendar_today_rounded,
                label: _formatDate(_fromDate),
                accentColor: accentColor,
                isActive: true,
                onTap: () => _pickFromDate(accentColor),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '–',
                  style: TextStyle(
                    color: AppColors.dashboardTextDim,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // To date
              _FilterChip(
                icon: Icons.calendar_today_rounded,
                label: _formatDate(_toDate),
                accentColor: accentColor,
                isActive: true,
                onTap: () => _pickToDate(accentColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Row 2: Search + LSK
          Row(
            children: [
              // Search field
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(
                        color: AppColors.dashboardTextPrim, fontSize: 13),
                    onChanged: (q) => setState(() => _searchQuery = q),
                    decoration: InputDecoration(
                      hintText: 'Search number...',
                      hintStyle: const TextStyle(
                          color: AppColors.dashboardTextDim, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppColors.dashboardTextDim, size: 16),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: const Icon(Icons.close_rounded,
                                  color: AppColors.dashboardTextDim, size: 16),
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.dashboardBg,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: AppColors.dashboardBorder, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: accentColor, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // LSK filter button
              _FilterChip(
                icon: Icons.filter_list_rounded,
                label: _selectedLsk == 'ALL' ? 'LSK' : _selectedLsk,
                accentColor: _selectedLsk != 'ALL'
                    ? _lskColor(_selectedLsk)
                    : AppColors.dashboardTextSub,
                isActive: _selectedLsk != 'ALL',
                onTap: () => _showLskPicker(accentColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Table ─────────────────────────────────────────────────────────────────

  Widget _buildEmptyState(Color accentColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_rounded,
              color: AppColors.dashboardTextDim, size: 48),
          const SizedBox(height: 12),
          const Text(
            'No entries found',
            style: TextStyle(
                color: AppColors.dashboardTextSub,
                fontSize: 14,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try adjusting your filters',
            style: TextStyle(
                color: AppColors.dashboardTextDim, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<_ReportEntry> entries, Color accentColor) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Table header
          Container(
            color: AppColors.dashboardSurface2,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: const Row(
              children: [
                Expanded(
                  child: Text(
                    'NUMBER',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.dashboardTextDim,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'LSK',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.dashboardTextDim,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'COUNT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.dashboardTextDim,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Data rows
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final isEven = index % 2 == 0;
              final lskColor = _lskColor(entry.lsk);
              return Container(
                color: isEven
                    ? AppColors.dashboardBg
                    : AppColors.dashboardSurface.withOpacity(0.6),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
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
                    // LSK badge
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: lskColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: lskColor.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            entry.lsk,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: lskColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Count
                    Expanded(
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
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTER CHIP WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.icon,
    required this.label,
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? accentColor.withOpacity(0.1)
              : AppColors.dashboardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? accentColor.withOpacity(0.45)
                : AppColors.dashboardBorder,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: accentColor, size: 13),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? accentColor
                    : AppColors.dashboardTextSub,
                fontSize: 12,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.w400,
              ),
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
// DEALER PICKER DIALOG (reused from booking screen pattern)
// ─────────────────────────────────────────────────────────────────────────────

class _DealerPickerDialog extends StatefulWidget {
  final String selectedDealer;
  final Color accentColor;
  final ValueChanged<String> onSelected;

  const _DealerPickerDialog({
    required this.selectedDealer,
    required this.accentColor,
    required this.onSelected,
  });

  @override
  State<_DealerPickerDialog> createState() => _DealerPickerDialogState();
}

class _DealerPickerDialogState extends State<_DealerPickerDialog> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';

  List<String> get _filtered {
    if (_query.isEmpty) return _kDealers;
    final q = _query.toLowerCase();
    return _kDealers.where((d) => d.toLowerCase().contains(q)).toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
        () => setState(() => _query = _searchController.text));
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
    final dealers = _filtered;
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
                  const Text(
                    'Select Dealer',
                    style: TextStyle(
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
                  hintText: 'Search dealer...',
                  hintStyle: const TextStyle(
                      color: AppColors.dashboardTextDim, fontSize: 15),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.dashboardTextDim, size: 20),
                  filled: true,
                  fillColor: AppColors.dashboardBg,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
            // Dealer list
            Expanded(
              child: dealers.isEmpty
                  ? const Center(
                      child: Text('No dealers found',
                          style: TextStyle(
                              color: AppColors.dashboardTextDim,
                              fontSize: 14)),
                    )
                  : ListView.separated(
                      padding:
                          const EdgeInsets.only(top: 8, bottom: 24),
                      itemCount: dealers.length,
                      separatorBuilder: (_, __) => Container(
                        height: 1,
                        margin: const EdgeInsets.only(left: 56),
                        color: AppColors.dashboardBorder,
                      ),
                      itemBuilder: (context, index) {
                        final dealer = dealers[index];
                        final isSelected =
                            dealer == widget.selectedDealer;
                        final isPlaceholder =
                            dealer == 'All Dealers' && index == 0;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => widget.onSelected(dealer),
                            highlightColor:
                                widget.accentColor.withOpacity(0.06),
                            splashColor:
                                widget.accentColor.withOpacity(0.09),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  // Radio indicator
                                  AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 150),
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
                                    dealer,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isPlaceholder
                                          ? AppColors.dashboardTextSub
                                          : isSelected
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
