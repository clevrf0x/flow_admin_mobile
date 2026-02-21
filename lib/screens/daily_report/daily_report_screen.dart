// lib/screens/daily_report/daily_report_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../models/game.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MOCK DATA — TODO: Replace with API call
// ─────────────────────────────────────────────────────────────────────────────

class _ReportEntry {
  final int no;
  final String number;
  final String lsk;
  final int count;
  final double dAmt; // TODO: from API (dealer-specific rate)
  final double cAmt; // TODO: from API (customer-specific rate)

  const _ReportEntry({
    required this.no,
    required this.number,
    required this.lsk,
    required this.count,
    required this.dAmt,
    required this.cAmt,
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
    _ReportEntry(no: 1,  number: '586', lsk: 'SUPER', count: 35, dAmt: 315.0,  cAmt: 350.0),
    _ReportEntry(no: 2,  number: '586', lsk: 'BOX',   count: 18, dAmt: 162.0,  cAmt: 180.0),
    _ReportEntry(no: 3,  number: '125', lsk: 'SUPER', count: 42, dAmt: 378.0,  cAmt: 420.0),
    _ReportEntry(no: 4,  number: '125', lsk: 'BOX',   count: 14, dAmt: 126.0,  cAmt: 140.0),
    _ReportEntry(no: 5,  number: '340', lsk: 'BOTH',  count: 27, dAmt: 243.0,  cAmt: 270.0),
    _ReportEntry(no: 6,  number: '77',  lsk: 'AB',    count: 20, dAmt: 180.0,  cAmt: 200.0),
    _ReportEntry(no: 7,  number: '77',  lsk: 'AC',    count: 9,  dAmt: 81.0,   cAmt: 90.0),
    _ReportEntry(no: 8,  number: '99',  lsk: 'BC',    count: 33, dAmt: 297.0,  cAmt: 330.0),
    _ReportEntry(no: 9,  number: '5',   lsk: 'A',     count: 50, dAmt: 450.0,  cAmt: 500.0),
    _ReportEntry(no: 10, number: '5',   lsk: 'B',     count: 26, dAmt: 234.0,  cAmt: 260.0),
    _ReportEntry(no: 11, number: '3',   lsk: 'C',     count: 31, dAmt: 279.0,  cAmt: 310.0),
    _ReportEntry(no: 12, number: '812', lsk: 'BOX',   count: 8,  dAmt: 72.0,   cAmt: 80.0),
    _ReportEntry(no: 13, number: '461', lsk: 'SUPER', count: 15, dAmt: 135.0,  cAmt: 150.0),
    _ReportEntry(no: 14, number: '23',  lsk: 'AB',    count: 11, dAmt: 99.0,   cAmt: 110.0),
    _ReportEntry(no: 15, number: '908', lsk: 'BOTH',  count: 19, dAmt: 171.0,  cAmt: 190.0),
    _ReportEntry(no: 16, number: '444', lsk: 'SUPER', count: 22, dAmt: 198.0,  cAmt: 220.0),
    _ReportEntry(no: 17, number: '321', lsk: 'BOX',   count: 7,  dAmt: 63.0,   cAmt: 70.0),
    _ReportEntry(no: 18, number: '67',  lsk: 'AC',    count: 13, dAmt: 117.0,  cAmt: 130.0),
    _ReportEntry(no: 19, number: '890', lsk: 'BOTH',  count: 28, dAmt: 252.0,  cAmt: 280.0),
    _ReportEntry(no: 20, number: '11',  lsk: 'AB',    count: 16, dAmt: 144.0,  cAmt: 160.0),
  ],
  'Kurukkan': [
    _ReportEntry(no: 1, number: '586', lsk: 'SUPER', count: 10, dAmt: 90.0,  cAmt: 100.0),
    _ReportEntry(no: 2, number: '125', lsk: 'BOX',   count: 5,  dAmt: 45.0,  cAmt: 50.0),
    _ReportEntry(no: 3, number: '77',  lsk: 'AB',    count: 8,  dAmt: 72.0,  cAmt: 80.0),
    _ReportEntry(no: 4, number: '340', lsk: 'BOTH',  count: 12, dAmt: 108.0, cAmt: 120.0),
    _ReportEntry(no: 5, number: '99',  lsk: 'BC',    count: 6,  dAmt: 54.0,  cAmt: 60.0),
  ],
  'BLT': [
    _ReportEntry(no: 1, number: '461', lsk: 'SUPER', count: 7,  dAmt: 63.0,  cAmt: 70.0),
    _ReportEntry(no: 2, number: '908', lsk: 'BOTH',  count: 9,  dAmt: 81.0,  cAmt: 90.0),
    _ReportEntry(no: 3, number: '5',   lsk: 'A',     count: 15, dAmt: 135.0, cAmt: 150.0),
    _ReportEntry(no: 4, number: '23',  lsk: 'AB',    count: 4,  dAmt: 36.0,  cAmt: 40.0),
  ],
  'SELF': [
    _ReportEntry(no: 1, number: '812', lsk: 'BOX',   count: 3,  dAmt: 27.0,  cAmt: 30.0),
    _ReportEntry(no: 2, number: '3',   lsk: 'C',     count: 11, dAmt: 99.0,  cAmt: 110.0),
    _ReportEntry(no: 3, number: '444', lsk: 'SUPER', count: 8,  dAmt: 72.0,  cAmt: 80.0),
    _ReportEntry(no: 4, number: '67',  lsk: 'AC',    count: 6,  dAmt: 54.0,  cAmt: 60.0),
    _ReportEntry(no: 5, number: '890', lsk: 'BOTH',  count: 14, dAmt: 126.0, cAmt: 140.0),
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
  String _selectedDealer = 'All Dealers';
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 6));
  DateTime _toDate = DateTime.now();
  String _selectedLsk = 'ALL';

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

  // ── Data ──────────────────────────────────────────────────────────────────

  List<_ReportEntry> get _sourceEntries {
    // TODO: API call — fetch entries by dealer + date range
    if (_kMockData.containsKey(_selectedDealer)) {
      return _kMockData[_selectedDealer]!;
    }
    return _kMockData['All Dealers']!;
  }

  List<_ReportEntry> get _filteredEntries {
    if (_selectedLsk == 'ALL') return _sourceEntries;
    return _sourceEntries.where((e) => e.lsk == _selectedLsk).toList();
  }

  int get _totalCount =>
      _filteredEntries.fold(0, (sum, e) => sum + e.count);
  double get _totalDamt =>
      _filteredEntries.fold(0.0, (sum, e) => sum + e.dAmt);
  double get _totalCamt =>
      _filteredEntries.fold(0.0, (sum, e) => sum + e.cAmt);

  // ── Date pickers ──────────────────────────────────────────────────────────

  Future<void> _pickFromDate(Color accentColor) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate,
      firstDate: DateTime(2020),
      lastDate: _toDate,
      builder: (context, child) => _darkDateTheme(accentColor, child!),
    );
    if (picked != null) setState(() => _fromDate = picked);
  }

  Future<void> _pickToDate(Color accentColor) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate,
      firstDate: _fromDate,
      lastDate: DateTime.now(),
      builder: (context, child) => _darkDateTheme(accentColor, child!),
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

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  // ── Dealer picker ─────────────────────────────────────────────────────────

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

  // ── LSK color ─────────────────────────────────────────────────────────────

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
    final filtered = _filteredEntries;

    return Scaffold(
      backgroundColor: AppColors.dashboardBg,
      body: Column(
        children: [
          // ── Header ──
          _DailyReportHeader(
            gameName: widget.gameName,
            gameId: widget.gameId,
            headerColors: headerColors,
          ),
          // ── Controls panel ──
          _buildControlsPanel(accentColor, headerColors),
          // ── LSK tabs ──
          _buildLskTabs(accentColor),
          // ── Table ──
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState()
                : _buildTable(filtered, accentColor),
          ),
        ],
      ),
    );
  }

  // ── Controls panel (dealer + dates + summary stats) ───────────────────────

  Widget _buildControlsPanel(Color accentColor, List<Color> headerColors) {
    return Container(
      color: AppColors.dashboardSurface,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Dealer button ──
          GestureDetector(
            onTap: () => _showDealerPicker(accentColor),
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.dashboardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _selectedDealer != 'All Dealers'
                      ? accentColor.withOpacity(0.5)
                      : AppColors.dashboardBorder,
                  width: _selectedDealer != 'All Dealers' ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(Icons.person_rounded,
                        color: accentColor, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dealer',
                          style: TextStyle(
                            color: AppColors.dashboardTextDim,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _selectedDealer,
                          style: TextStyle(
                            color: _selectedDealer != 'All Dealers'
                                ? accentColor
                                : AppColors.dashboardTextPrim,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.dashboardTextSub, size: 20),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ── Date range row ──
          Row(
            children: [
              // From date
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickFromDate(accentColor),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.dashboardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.dashboardBorder, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            color: accentColor, size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'FROM',
                                style: TextStyle(
                                  color: AppColors.dashboardTextDim,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Text(
                                _fmt(_fromDate),
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '→',
                  style: TextStyle(
                    color: AppColors.dashboardTextDim,
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              // To date
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickToDate(accentColor),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.dashboardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.dashboardBorder, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            color: accentColor, size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TO',
                                style: TextStyle(
                                  color: AppColors.dashboardTextDim,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Text(
                                _fmt(_toDate),
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Summary stats row ──
          Row(
            children: [
              _StatBox(
                label: 'Total Entries',
                value: '$_totalCount',
                accentColor: accentColor,
              ),
              const SizedBox(width: 8),
              _StatBox(
                label: 'D. Amount',
                value: _totalDamt.toStringAsFixed(0),
                accentColor: accentColor,
              ),
              const SizedBox(width: 8),
              _StatBox(
                label: 'C. Amount',
                value: _totalCamt.toStringAsFixed(0),
                accentColor: accentColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── LSK filter tabs ───────────────────────────────────────────────────────

  Widget _buildLskTabs(Color accentColor) {
    return Container(
      color: AppColors.dashboardSurface,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      child: Column(
        children: [
          Container(height: 1, color: AppColors.dashboardBorder),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: _kAllLsk.map((lsk) {
                final isSelected = lsk == _selectedLsk;
                final color =
                    lsk == 'ALL' ? accentColor : _lskColor(lsk);
                return GestureDetector(
                  onTap: () => setState(() => _selectedLsk = lsk),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
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
                        fontSize: 11,
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
        ],
      ),
    );
  }

  // ── Table ─────────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_rounded,
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
            'Try changing the dealer, date range, or LSK filter',
            style: TextStyle(
                color: AppColors.dashboardTextDim, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<_ReportEntry> entries, Color accentColor) {
    // Fixed widths for the 6 columns
    const double wNo = 40;
    const double wNum = 72;
    const double wLsk = 68;
    const double wCount = 56;
    const double wDamt = 72;
    const double wCamt = 72;
    const double totalW = wNo + wNum + wLsk + wCount + wDamt + wCamt;

    const headerStyle = TextStyle(
      color: AppColors.dashboardTextDim,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.0,
    );

    // Totals footer
    final totCount = entries.fold(0, (s, e) => s + e.count);
    final totDamt = entries.fold(0.0, (s, e) => s + e.dAmt);
    final totCamt = entries.fold(0.0, (s, e) => s + e.cAmt);

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: totalW,
          child: Column(
            children: [
              // ── Header row ──
              Container(
                color: AppColors.dashboardSurface2,
                padding:
                    const EdgeInsets.symmetric(horizontal: 0, vertical: 9),
                child: Row(
                  children: [
                    _hCell('NO', wNo, TextAlign.center, headerStyle),
                    _hCell('NUMBER', wNum, TextAlign.center, headerStyle),
                    _hCell('LSK', wLsk, TextAlign.center, headerStyle),
                    _hCell('COUNT', wCount, TextAlign.center, headerStyle),
                    _hCell('D.AMT', wDamt, TextAlign.center, headerStyle),
                    _hCell('C.AMT', wCamt, TextAlign.center, headerStyle),
                  ],
                ),
              ),
              // ── Data rows ──
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final e = entries[index];
                  final isEven = index % 2 == 0;
                  final lskColor = _lskColor(e.lsk);
                  return Container(
                    color: isEven
                        ? AppColors.dashboardBg
                        : AppColors.dashboardSurface.withOpacity(0.6),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        // No
                        SizedBox(
                          width: wNo,
                          child: Text(
                            '${e.no}',
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
                          width: wNum,
                          child: Text(
                            e.number,
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
                        SizedBox(
                          width: wLsk,
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
                                e.lsk,
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
                        SizedBox(
                          width: wCount,
                          child: Text(
                            '${e.count}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.dashboardTextPrim,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // D.Amt
                        SizedBox(
                          width: wDamt,
                          child: Text(
                            e.dAmt.toStringAsFixed(0),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.dashboardTextSub,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        // C.Amt
                        SizedBox(
                          width: wCamt,
                          child: Text(
                            e.cAmt.toStringAsFixed(0),
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
              // ── Totals footer ──
              Container(
                color: AppColors.dashboardSurface2,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: wNo + wNum + wLsk,
                      child: const Text(
                        'TOTAL',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.dashboardTextDim,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: wCount,
                      child: Text(
                        '$totCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.dashboardTextPrim,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: wDamt,
                      child: Text(
                        totDamt.toStringAsFixed(0),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.dashboardTextSub,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: wCamt,
                      child: Text(
                        totCamt.toStringAsFixed(0),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.dashboardTextSub,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hCell(
      String label, double width, TextAlign align, TextStyle style) {
    return SizedBox(
      width: width,
      child: Text(label, textAlign: align, style: style),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAT BOX
// ─────────────────────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;

  const _StatBox({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.dashboardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.dashboardBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.dashboardTextDim,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: accentColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1,
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
// DEALER PICKER DIALOG
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
                                    dealer,
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
