// lib/screens/sales_report/sales_report_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../models/game.dart';
import '../../models/dealer.dart';
import '../../services/booking_service.dart';
import '../../services/sales_report_service.dart';
import '../../widgets/common_toast.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Table column widths (logical px)
// ─────────────────────────────────────────────────────────────────────────────

const double _kColDate   = 55.0;
const double _kColDealer = 88.0;
const double _kColBill   = 64.0;
const double _kColCount  = 46.0;
const double _kColDAmt   = 68.0;
const double _kColCAmt   = 68.0;
const double _kColDel    = 38.0;
const double _kTableWidth =
    _kColDate + _kColDealer + _kColBill + _kColCount + _kColDAmt + _kColCAmt + _kColDel;

/// LSK sub-type options that appear as checkboxes for each digit mode.
const Map<int, List<String>> _kLskOptions = {
  1: ['A', 'B', 'C'],
  2: ['AB', 'AC', 'BC'],
  3: ['Super', 'Box'],
};

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Compact display date from "YYYY-MM-DD" → "DD/MM"
String _tableDate(String apiDate) {
  final p = apiDate.split('-');
  if (p.length != 3) return apiDate;
  return '${p[2]}/${p[1]}';
}

/// "YYYY-MM-DD" string from a DateTime
String _apiDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Display date for filter picker button: "dd/MM/yy"
String _fmtDateDisplay(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/'
    '${d.year.toString().substring(2)}';

/// Amount formatted to 2 decimal places (no currency prefix)
String _fmtAmt(double v) => v.toStringAsFixed(2);

/// Amount with RM prefix and comma thousands separator
String _fmtRm(double v) {
  final rounded  = v.toStringAsFixed(2);
  final parts    = rounded.split('.');
  final intStr   = parts[0];
  final decStr   = parts[1];
  final buffer   = StringBuffer();
  for (int i = 0; i < intStr.length; i++) {
    if (i > 0 && (intStr.length - i) % 3 == 0) buffer.write(',');
    buffer.write(intStr[i]);
  }
  return 'RM${buffer.toString()}.$decStr';
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class SalesReportScreen extends StatefulWidget {
  final String gameId;
  final String gameName;

  const SalesReportScreen({
    super.key,
    required this.gameId,
    required this.gameName,
  });

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  // ── Dealer state ─────────────────────────────────────────────────────────
  List<Dealer> _dealers        = [];
  bool         _dealersLoading = true;
  Dealer?      _selectedDealer;

  // ── Filter state ─────────────────────────────────────────────────────────
  late DateTime    _startDate;
  late DateTime    _endDate;
  int              _selectedDigit    = 0;         // 0=All, 1, 2, 3
  Set<String>      _selectedLskTypes = {};        // empty = all types for that digit
  bool             _isExpanded       = false;

  // ── Report state ─────────────────────────────────────────────────────────
  SalesReport? _report;
  bool         _initialLoading = true;
  bool         _isLoading      = false;
  String?      _error;

  // ── Game ─────────────────────────────────────────────────────────────────
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

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate   = DateTime(now.year, now.month, now.day);
    _fetchDealers();
    _fetchReport();
  }

  // ── Data fetching ──────────────────────────────────────────────────────────
  Future<void> _fetchDealers() async {
    try {
      final dealers = await BookingService.getDealers(widget.gameId);
      if (!mounted) return;
      setState(() {
        _dealers        = dealers;
        _dealersLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _dealersLoading = false);
    }
  }

  Future<void> _fetchReport() async {
    setState(() {
      _isLoading = true;
      _error     = null;
    });
    try {
      final report = await SalesReportService.fetchReport(
        gameId:    widget.gameId,
        startDate: _apiDate(_startDate),
        endDate:   _apiDate(_endDate),
        dealerId:  _selectedDealer?.id,
        digit:     _selectedDigit == 0 ? null : _selectedDigit,
        lskTypes:  _selectedLskTypes.isEmpty ? null : _selectedLskTypes.toList(),
        expanded:  _isExpanded,
      );
      if (!mounted) return;
      setState(() {
        _report         = report;
        _isLoading      = false;
        _initialLoading = false;
      });
    } on SalesException catch (e) {
      if (!mounted) return;
      setState(() {
        _error          = e.message;
        _isLoading      = false;
        _initialLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error          = 'Could not reach the server. Check your connection.';
        _isLoading      = false;
        _initialLoading = false;
      });
    }
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
    _fetchReport();
  }

  // ── Optimistic state updates ───────────────────────────────────────────────
  // Update local _report immediately on delete so the UI responds instantly
  // without waiting for a re-fetch (which would also block expand/search via
  // _isLoading = true).

  void _optimisticDeleteBooking(int bookingId) {
    if (_report == null) return;
    SalesBookingRow? found;
    for (final b in _report!.bookings) {
      if (b.id == bookingId) { found = b; break; }
    }
    if (found == null) return;
    setState(() {
      _report = SalesReport(
        bookings: _report!.bookings.where((b) => b.id != bookingId).toList(),
        totals: SalesReportTotals(
          count:   _report!.totals.count   - found!.count,
          dAmount: _report!.totals.dAmount - found.dAmount,
          cAmount: _report!.totals.cAmount - found.cAmount,
        ),
      );
    });
  }

  void _optimisticDeleteEntry(int entryId) {
    if (_report == null) return;
    SalesBookingRow? targetBooking;
    SalesEntryRow?  targetEntry;
    for (final booking in _report!.bookings) {
      if (booking.entries == null) continue;
      for (final entry in booking.entries!) {
        if (entry.id == entryId) {
          targetBooking = booking;
          targetEntry   = entry;
          break;
        }
      }
      if (targetBooking != null) break;
    }
    if (targetBooking == null || targetEntry == null) return;

    final newEntries =
        targetBooking.entries!.where((e) => e.id != entryId).toList();

    final List<SalesBookingRow> newBookings;
    if (newEntries.isEmpty) {
      // Last entry removed — drop the whole booking row
      newBookings =
          _report!.bookings.where((b) => b.id != targetBooking!.id).toList();
    } else {
      final updated = SalesBookingRow(
        id:         targetBooking.id,
        date:       targetBooking.date,
        time:       targetBooking.time,
        dealerId:   targetBooking.dealerId,
        dealerName: targetBooking.dealerName,
        dealerCode: targetBooking.dealerCode,
        count:      targetBooking.count   - targetEntry.count,
        dAmount:    targetBooking.dAmount - targetEntry.dAmount,
        cAmount:    targetBooking.cAmount - targetEntry.cAmount,
        entries:    newEntries,
      );
      newBookings = _report!.bookings
          .map((b) => b.id == targetBooking!.id ? updated : b)
          .toList();
    }

    setState(() {
      _report = SalesReport(
        bookings: newBookings,
        totals: SalesReportTotals(
          count:   _report!.totals.count   - targetEntry!.count,
          dAmount: _report!.totals.dAmount - targetEntry.dAmount,
          cAmount: _report!.totals.cAmount - targetEntry.cAmount,
        ),
      );
    });
  }

  // ── Delete handlers ────────────────────────────────────────────────────────

  Future<void> _deleteBooking(int bookingId, List<Color> headerColors) async {
    final confirmed = await _showDeleteDialog(
      headerColors: headerColors,
      title:        'Delete Booking',
      subtitle:     'Booking #$bookingId',
      body:         'This will permanently delete the booking and all its ticket entries. This action cannot be undone.',
    );
    if (!confirmed || !mounted) return;

    // Clear any queued toasts before showing loading — prevents the queue
    // from stacking loading toasts behind lingering success/error toasts.
    ScaffoldMessenger.of(context).clearSnackBars();
    CommonToast.showLoading(context, 'Deleting booking…',
        gradientColors: [headerColors.first, headerColors.last]);

    try {
      await SalesReportService.deleteBooking(bookingId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      _optimisticDeleteBooking(bookingId); // instant UI update, no re-fetch
      CommonToast.showSuccess(context, 'Booking #$bookingId deleted.');
    } on SalesException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      CommonToast.showError(context, e.message);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      CommonToast.showError(context, 'Delete failed. Please try again.');
    }
  }

  Future<void> _deleteEntry(int entryId, String label, List<Color> headerColors) async {
    final confirmed = await _showDeleteDialog(
      headerColors: headerColors,
      title:        'Delete Entry',
      subtitle:     label,
      body:         'This will permanently delete this ticket entry. If it is the only entry in the booking, the booking will also be removed.',
    );
    if (!confirmed || !mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    CommonToast.showLoading(context, 'Deleting entry…',
        gradientColors: [headerColors.first, headerColors.last]);

    try {
      await SalesReportService.deleteEntry(entryId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      _optimisticDeleteEntry(entryId); // instant UI update, no re-fetch
      CommonToast.showSuccess(context, 'Entry deleted successfully.');
    } on SalesException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      CommonToast.showError(context, e.message);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      CommonToast.showError(context, 'Delete failed. Please try again.');
    }
  }

  /// Shows a themed confirmation dialog.
  /// Returns [true] if the user confirmed, [false] if cancelled.
  Future<bool> _showDeleteDialog({
    required List<Color> headerColors,
    required String title,
    required String subtitle,
    required String body,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color:        AppColors.dashboardSurface,
            borderRadius: BorderRadius.circular(18),
            border:       Border.all(color: AppColors.dashboardBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Gradient header band ──────────────────────────────────────
              Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [headerColors.first, headerColors.last],
                    begin:  Alignment.topLeft,
                    end:    Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18)),
                ),
              ),
              // ── Icon + title ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                child: Column(
                  children: [
                    Container(
                      width:  52,
                      height: 52,
                      decoration: BoxDecoration(
                        color:        AppColors.dashboardLogout.withOpacity(0.12),
                        shape:        BoxShape.circle,
                        border: Border.all(
                          color: AppColors.dashboardLogout.withOpacity(0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.dashboardLogout,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      title,
                      style: const TextStyle(
                        color:      AppColors.dashboardTextPrim,
                        fontSize:   17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color:    AppColors.dashboardTextSub,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // ── Body ─────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:        AppColors.dashboardBg,
                    borderRadius: BorderRadius.circular(10),
                    border:       Border.all(color: AppColors.dashboardBorder),
                  ),
                  child: Text(
                    body,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color:    AppColors.dashboardTextSub,
                      fontSize: 12,
                      height:   1.5,
                    ),
                  ),
                ),
              ),
              // ── Buttons ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Row(
                  children: [
                    // Cancel
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(ctx).pop(false),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color:        AppColors.dashboardBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.dashboardBorder),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color:      AppColors.dashboardTextSub,
                              fontSize:   14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Delete
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(ctx).pop(true),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color:        AppColors.dashboardLogout.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.dashboardLogout.withOpacity(0.5),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.delete_rounded,
                                  color: AppColors.dashboardLogout, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Delete',
                                style: TextStyle(
                                  color:      AppColors.dashboardLogout,
                                  fontSize:   14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
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
    return result ?? false;
  }

  // ── Date picker ────────────────────────────────────────────────────────────
  Future<void> _pickDate(BuildContext context, bool isStart,
      Color accentColor) async {
    final initial   = isStart ? _startDate : _endDate;
    final firstDate = DateTime(2020);
    final lastDate  = DateTime(2030);

    final picked = await showDatePicker(
      context:     context,
      initialDate: initial,
      firstDate:   firstDate,
      lastDate:    lastDate,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary:   accentColor,
            onPrimary: Colors.white,
            surface:   AppColors.dashboardSurface,
          ),
          dialogBackgroundColor: AppColors.dashboardSurface,
        ),
        child: child!,
      ),
    );

    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
      } else {
        _endDate = picked;
        if (_startDate.isAfter(_endDate)) _startDate = _endDate;
      }
    });
  }

  // ── LSK color ──────────────────────────────────────────────────────────────
  Color _lskColor(String lsk) {
    switch (lsk.toUpperCase()) {
      case 'AB':    return AppColors.lskAB;
      case 'AC':    return AppColors.lskAC;
      case 'BC':    return AppColors.dashboardTextSub;
      case 'BOX':   return AppColors.lskBox;
      case 'C':     return AppColors.lskC;
      case 'SUPER': return AppColors.dashboardTextSub;
      case 'A':     return AppColors.lskA;
      case 'B':     return AppColors.lskB;
      case 'BOTH':  return AppColors.lskBoth;
      default:      return AppColors.dashboardTextSub;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor:          Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    final game         = _game;
    final headerColors = game?.gradientColors ??
        [AppColors.primaryBlue, AppColors.primaryBlueDark];
    final accentColor  = _resolvedAccentColor(headerColors);

    return Scaffold(
      backgroundColor: AppColors.dashboardBg,
      body: Column(
        children: [
          // ── Gradient block: header + summary card ──────────────────────────
          _buildGradientBlock(headerColors, accentColor),
          // ── Filter bar ────────────────────────────────────────────────────
          _buildFilterBar(headerColors, accentColor),
          // ── Content ───────────────────────────────────────────────────────
          Expanded(
            child: _initialLoading
                ? _buildLoadingState(accentColor)
                : _error != null && _report == null
                    ? _buildErrorState(accentColor)
                    : _report!.bookings.isEmpty
                        ? _buildEmptyState(accentColor)
                        : _buildTable(headerColors, accentColor),
          ),
        ],
      ),
    );
  }

  // ── Gradient header + summary block ───────────────────────────────────────
  Widget _buildGradientBlock(List<Color> headerColors, Color accentColor) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
          colors: headerColors.length >= 2
              ? [headerColors[0], headerColors.last]
              : [headerColors[0], headerColors[0]],
        ),
      ),
      child: Column(
        children: [
          // Universal header row
          Padding(
            padding: EdgeInsets.fromLTRB(6, statusBarHeight + 4, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ← Back
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => context.go(
                      '/dashboard/${widget.gameId}'
                      '?gameName=${Uri.encodeComponent(widget.gameName)}',
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
                            widget.gameName,
                            style: TextStyle(
                              color:      Colors.white.withOpacity(0.9),
                              fontSize:   13,
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
                    'Sales Report',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:       Colors.white,
                      fontSize:    18,
                      fontWeight:  FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                // Home
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => context.go('/game-selection'),
                    child: Container(
                      width:  38,
                      height: 38,
                      decoration: BoxDecoration(
                        color:        Colors.white.withOpacity(0.22),
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
          // Summary card (3 stats in one row)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Total count — big number
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_report?.totals.count ?? 0}',
                        style: const TextStyle(
                          color:       Colors.white,
                          fontSize:    44,
                          fontWeight:  FontWeight.w800,
                          letterSpacing: -1,
                          height:      1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Total Entries',
                        style: TextStyle(
                          color:      Colors.white.withOpacity(0.55),
                          fontSize:   11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // D.Amt + C.Amt chips
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildAmtChip(
                      label: 'D',
                      value: _report?.totals.dAmount ?? 0,
                    ),
                    const SizedBox(height: 6),
                    _buildAmtChip(
                      label: 'C',
                      value: _report?.totals.cAmount ?? 0,
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

  Widget _buildAmtChip({required String label, required double value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color:        Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width:  18,
            height: 18,
            decoration: BoxDecoration(
              color:        Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                color:      Colors.white,
                fontSize:   10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.payments_rounded,
            color:  Colors.white54,
            size:   12,
          ),
          const SizedBox(width: 3),
          Text(
            // comma-formatted amount without currency prefix
            _fmtRm(value).replaceFirst('RM', ''),
            style: const TextStyle(
              color:      Colors.white,
              fontSize:   13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter bar ─────────────────────────────────────────────────────────────
  Widget _buildFilterBar(List<Color> headerColors, Color accentColor) {
    return Container(
      color: AppColors.dashboardSurface,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Dealer picker | Expand toggle
          Row(
            children: [
              // Dealer picker
              Expanded(child: _buildDealerPicker(accentColor)),
              const SizedBox(width: 8),
              // Expand/Summary toggle
              _buildExpandToggle(accentColor),
            ],
          ),
          const SizedBox(height: 8),
          // Row 2: Digit tabs
          _buildDigitTabs(accentColor),
          // Row 2b: LSK sub-type checkboxes — animated in/out per digit selection
          _buildLskChips(accentColor),
          const SizedBox(height: 8),
          // Row 3: Date range + SEARCH
          Row(
            children: [
              // From date
              Expanded(
                child: _buildDateButton(
                  context:     context,
                  date:        _startDate,
                  label:       'From',
                  accentColor: accentColor,
                  onTap:       () => _pickDate(context, true, accentColor),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '→',
                  style: TextStyle(
                    color:   AppColors.dashboardTextDim,
                    fontSize: 14,
                  ),
                ),
              ),
              // To date
              Expanded(
                child: _buildDateButton(
                  context:     context,
                  date:        _endDate,
                  label:       'To',
                  accentColor: accentColor,
                  onTap:       () => _pickDate(context, false, accentColor),
                ),
              ),
              const SizedBox(width: 8),
              // SEARCH button
              GestureDetector(
                onTap: _isLoading ? null : _fetchReport,
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin:  Alignment.topLeft,
                      end:    Alignment.bottomRight,
                      colors: [headerColors.first, headerColors.last],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: _isLoading
                      ? const SizedBox(
                          width:  14,
                          height: 14,
                          child:  CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          'SEARCH',
                          style: TextStyle(
                            color:      Colors.white,
                            fontSize:   12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
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

  Widget _buildDealerPicker(Color accentColor) {
    return GestureDetector(
      onTap: () => _showDealerSheet(accentColor),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color:        AppColors.dashboardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.dashboardBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.person_outline_rounded,
                color: AppColors.dashboardTextDim, size: 15),
            const SizedBox(width: 6),
            Expanded(
              child: _dealersLoading
                  ? Text(
                      'Loading…',
                      style: const TextStyle(
                          color: AppColors.dashboardTextDim, fontSize: 12),
                    )
                  : Text(
                      _selectedDealer?.name ?? 'All Dealers',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color:      _selectedDealer != null
                            ? AppColors.dashboardTextPrim
                            : AppColors.dashboardTextSub,
                        fontSize:   12,
                        fontWeight: _selectedDealer != null
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
            ),
            if (_selectedDealer != null)
              GestureDetector(
                onTap: () => setState(() => _selectedDealer = null),
                child: const Icon(Icons.close_rounded,
                    color: AppColors.dashboardTextDim, size: 14),
              )
            else
              const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.dashboardTextDim, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandToggle(Color accentColor) {
    return GestureDetector(
      onTap: _isLoading ? null : _toggleExpanded,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: _isExpanded
              ? accentColor.withOpacity(0.15)
              : AppColors.dashboardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isExpanded
                ? accentColor.withOpacity(0.45)
                : AppColors.dashboardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isExpanded
                  ? Icons.table_rows_rounded
                  : Icons.unfold_more_rounded,
              color:    _isExpanded ? accentColor : AppColors.dashboardTextSub,
              size:     16,
            ),
            const SizedBox(width: 5),
            Text(
              _isExpanded ? 'Summary' : 'Expand',
              style: TextStyle(
                color:      _isExpanded
                    ? accentColor
                    : AppColors.dashboardTextSub,
                fontSize:   12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDigitTabs(Color accentColor) {
    const labels = ['All', '1', '2', '3'];
    return Row(
      children: List.generate(
        labels.length,
        (i) => Padding(
          padding: EdgeInsets.only(right: i < labels.length - 1 ? 6 : 0),
          child: GestureDetector(
            onTap: () => setState(() {
              _selectedDigit    = i;
              _selectedLskTypes = {}; // reset sub-type selection on digit change
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height:  30,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _selectedDigit == i
                    ? accentColor.withOpacity(0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _selectedDigit == i
                      ? accentColor.withOpacity(0.5)
                      : AppColors.dashboardBorder,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                labels[i],
                style: TextStyle(
                  color: _selectedDigit == i
                      ? accentColor
                      : AppColors.dashboardTextSub,
                  fontSize:   12,
                  fontWeight: _selectedDigit == i
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── LSK sub-type chips ─────────────────────────────────────────────────────
  /// Animated row of multi-select LSK checkboxes.
  /// Visible only when a specific digit (1/2/3) is selected.
  /// Returns a collapsed zero-height widget when digit = 0 (All).
  Widget _buildLskChips(Color accentColor) {
    final options = _kLskOptions[_selectedDigit];
    return AnimatedSize(
      duration:  const Duration(milliseconds: 180),
      curve:     Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: options == null
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: options
                    .map((lsk) => _buildLskChip(lsk, accentColor))
                    .toList(),
              ),
            ),
    );
  }

  Widget _buildLskChip(String lsk, Color accentColor) {
    final selected = _selectedLskTypes.contains(lsk);
    final color    = _lskColor(lsk);

    return GestureDetector(
      onTap: () => setState(() {
        if (selected) {
          _selectedLskTypes.remove(lsk);
        } else {
          _selectedLskTypes.add(lsk);
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin:   const EdgeInsets.only(right: 6),
        padding:  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? color.withOpacity(0.55) : AppColors.dashboardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mini checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width:  14,
              height: 14,
              decoration: BoxDecoration(
                color:        selected ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: selected ? color : AppColors.dashboardTextDim,
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: selected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 10)
                  : null,
            ),
            const SizedBox(width: 6),
            Text(
              lsk,
              style: TextStyle(
                color:      selected ? color : AppColors.dashboardTextSub,
                fontSize:   12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateButton({
    required BuildContext context,
    required DateTime date,
    required String label,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color:        AppColors.dashboardBg,
          borderRadius: BorderRadius.circular(8),
          border:       Border.all(color: AppColors.dashboardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_rounded,
                color: accentColor, size: 13),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                _fmtDateDisplay(date),
                overflow:   TextOverflow.ellipsis,
                style: const TextStyle(
                  color:      AppColors.dashboardTextPrim,
                  fontSize:   12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDealerSheet(Color accentColor) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    showModalBottomSheet(
      context:          context,
      backgroundColor:  AppColors.dashboardSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width:  36,
                height: 4,
                decoration: BoxDecoration(
                  color:        AppColors.dashboardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Filter by Dealer',
                style: TextStyle(
                  color:      AppColors.dashboardTextPrim,
                  fontSize:   14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // "All Dealers" option
                      _dealerSheetRow(
                        ctx:        ctx,
                        name:       'All Dealers',
                        code:       '',
                        isSelected: _selectedDealer == null,
                        accentColor: accentColor,
                        onTap: () {
                          setState(() => _selectedDealer = null);
                          Navigator.of(ctx).pop();
                        },
                      ),
                      ...List.generate(
                        _dealers.length,
                        (i) => _dealerSheetRow(
                          ctx:        ctx,
                          name:       _dealers[i].name,
                          code:       _dealers[i].code,
                          isSelected: _selectedDealer?.id == _dealers[i].id,
                          accentColor: accentColor,
                          onTap: () {
                            setState(() => _selectedDealer = _dealers[i]);
                            Navigator.of(ctx).pop();
                          },
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

  Widget _dealerSheetRow({
    required BuildContext ctx,
    required String name,
    required String code,
    required bool isSelected,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.dashboardBorder, width: 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color:      isSelected
                          ? accentColor
                          : AppColors.dashboardTextPrim,
                      fontSize:   13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  if (code.isNotEmpty)
                    Text(
                      code,
                      style: const TextStyle(
                        color:    AppColors.dashboardTextDim,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_rounded, color: accentColor, size: 16),
          ],
        ),
      ),
    );
  }

  // ── State widgets ──────────────────────────────────────────────────────────
  Widget _buildLoadingState(Color accentColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width:  28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Loading sales report…',
            style: TextStyle(
              color:    AppColors.dashboardTextSub,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Color accentColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                color: AppColors.dashboardTextDim, size: 48),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color:    AppColors.dashboardTextSub,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _fetchReport,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color:        accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accentColor.withOpacity(0.35)),
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(
                    color:      accentColor,
                    fontSize:   13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color accentColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.receipt_long_rounded,
              color: AppColors.dashboardTextDim, size: 48),
          const SizedBox(height: 12),
          const Text(
            'No sales found',
            style: TextStyle(
              color:      AppColors.dashboardTextSub,
              fontSize:   14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try adjusting your filters or date range',
            style: TextStyle(
              color:    AppColors.dashboardTextDim,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ── Table ──────────────────────────────────────────────────────────────────
  Widget _buildTable(List<Color> headerColors, Color accentColor) {
    final bookings = _report!.bookings;
    final flatRows = _buildTableRows(bookings, headerColors, accentColor);

    // Dealer column is Expanded — fills all remaining screen width — so the
    // table always fits exactly. No horizontal scroll needed.
    return Column(
      children: [
        _buildTableHeader(),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: flatRows,
          ),
        ),
      ],
    );
  }

  // Header row
  Widget _buildTableHeader() {
    return Container(
      color: AppColors.dashboardSurface2,
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          _hCell('Date',   _kColDate),
          // Dealer — Expanded: fills remaining width between fixed columns
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                'DEALER',
                textAlign: TextAlign.left,
                style: const TextStyle(
                  color:         AppColors.dashboardTextDim,
                  fontSize:      10,
                  fontWeight:    FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
          _hCell('Bill #', _kColBill),
          _hCell('Count',  _kColCount),
          _hCell('D.Amt',  _kColDAmt),
          _hCell('C.Amt',  _kColCAmt),
          SizedBox(width: _kColDel),
        ],
      ),
    );
  }

  Widget _hCell(String label, double width,
      {TextAlign align = TextAlign.center, double leftPad = 0}) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: EdgeInsets.only(left: leftPad),
        child: Text(
          label,
          textAlign: align,
          style: const TextStyle(
            color:         AppColors.dashboardTextDim,
            fontSize:      10,
            fontWeight:    FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  // Booking + entry rows
  List<Widget> _buildTableRows(
      List<SalesBookingRow> bookings, List<Color> headerColors, Color accentColor) {
    final rows = <Widget>[];

    for (int i = 0; i < bookings.length; i++) {
      final booking = bookings[i];
      final isEven  = i % 2 == 0;
      rows.add(_buildBookingRow(booking, isEven, headerColors, accentColor));

      if (_isExpanded && booking.entries != null) {
        for (final entry in booking.entries!) {
          rows.add(_buildEntryRow(entry, headerColors, accentColor));
        }
      }
    }

    return rows;
  }

  // One booking summary row
  Widget _buildBookingRow(
      SalesBookingRow b, bool isEven, List<Color> headerColors, Color accentColor) {
    return Container(
      color: isEven
          ? AppColors.dashboardBg
          : AppColors.dashboardSurface.withOpacity(0.6),
      child: Row(
        children: [
          // Date / Time
          SizedBox(
            width: _kColDate,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _tableDate(b.date),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color:      AppColors.dashboardTextPrim,
                      fontSize:   11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    b.time,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color:    AppColors.dashboardTextDim,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Dealer name / code — Expanded fills remaining screen width
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    b.dealerName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color:      AppColors.dashboardTextPrim,
                      fontSize:   11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    b.dealerCode,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color:    AppColors.dashboardTextDim,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bill number (booking ID)
          SizedBox(
            width: _kColBill,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Text(
                '#${b.id}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color:    AppColors.dashboardTextSub,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          // Count
          SizedBox(
            width: _kColCount,
            child: Text(
              '${b.count}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color:      AppColors.dashboardTextPrim,
                fontSize:   12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // D.Amt
          SizedBox(
            width: _kColDAmt,
            child: Text(
              _fmtAmt(b.dAmount),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color:    AppColors.dashboardTextSub,
                fontSize: 11,
              ),
            ),
          ),
          // C.Amt
          SizedBox(
            width: _kColCAmt,
            child: Text(
              _fmtAmt(b.cAmount),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color:    AppColors.dashboardTextSub,
                fontSize: 11,
              ),
            ),
          ),
          // Delete
          SizedBox(
            width: _kColDel,
            child: Center(
              child: GestureDetector(
                onTap: () => _deleteBooking(b.id, headerColors),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.delete_outline_rounded,
                      color: AppColors.dashboardLogout, size: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // One ticket entry sub-row (expanded mode)
  Widget _buildEntryRow(SalesEntryRow e, List<Color> headerColors, Color accentColor) {
    final lskColor = _lskColor(e.lsk);
    // Use Stack so the 3-px left accent stripe is overlaid on top of the row
    // rather than drawn inside the Container (which would steal 3px from the
    // content area and cause a right-side overflow).
    return Stack(
      children: [
        Container(
          color: AppColors.dashboardSurface2,
          child: Row(
            children: [
              // Date col → "#"
              SizedBox(
                width: _kColDate,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '#',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color:      AppColors.dashboardTextDim,
                      fontSize:   12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              // Dealer col → LSK chip — Expanded fills remaining screen width
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: lskColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: lskColor.withOpacity(0.3), width: 0.5),
                      ),
                      child: Text(
                        e.lsk,
                        style: TextStyle(
                          color:         lskColor,
                          fontSize:      10,
                          fontWeight:    FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Bill col → ticket number
              SizedBox(
                width: _kColBill,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    e.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color:         AppColors.dashboardTextPrim,
                      fontSize:      12,
                      fontWeight:    FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              // Count
              SizedBox(
                width: _kColCount,
                child: Text(
                  '${e.count}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color:    AppColors.dashboardTextSub,
                    fontSize: 11,
                  ),
                ),
              ),
              // D.Amt
              SizedBox(
                width: _kColDAmt,
                child: Text(
                  _fmtAmt(e.dAmount),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color:    AppColors.dashboardTextDim,
                    fontSize: 11,
                  ),
                ),
              ),
              // C.Amt
              SizedBox(
                width: _kColCAmt,
                child: Text(
                  _fmtAmt(e.cAmount),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color:    AppColors.dashboardTextDim,
                    fontSize: 11,
                  ),
                ),
              ),
              // Delete
              SizedBox(
                width: _kColDel,
                child: Center(
                  child: GestureDetector(
                    onTap: () => _deleteEntry(
                      e.id,
                      '${e.number} · ${e.lsk}',
                      headerColors,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.delete_outline_rounded,
                          color: AppColors.dashboardLogout, size: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Left accent stripe — overlaid so it doesn't affect layout width
        Positioned(
          left: 0,
          top:  0,
          bottom: 0,
          child: Container(
            width: 3,
            color: accentColor.withOpacity(0.45),
          ),
        ),
      ],
    );
  }

  // Totals footer row
  Widget _buildTotalsRow(SalesReportTotals totals, Color accentColor) {
    return Container(
      color: AppColors.dashboardSurface2,
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          // "TOTAL" label
          SizedBox(
            width: _kColDate,
            child: const Text(
              'TOTAL',
              textAlign: TextAlign.center,
              style: TextStyle(
                color:         AppColors.dashboardTextDim,
                fontSize:      9,
                fontWeight:    FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          SizedBox(width: _kColDealer),
          SizedBox(width: _kColBill),
          // Count total
          SizedBox(
            width: _kColCount,
            child: Text(
              '${totals.count}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color:      accentColor,
                fontSize:   13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          // D.Amt total
          SizedBox(
            width: _kColDAmt,
            child: Text(
              _fmtAmt(totals.dAmount),
              textAlign: TextAlign.center,
              style: TextStyle(
                color:      accentColor,
                fontSize:   11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // C.Amt total
          SizedBox(
            width: _kColCAmt,
            child: Text(
              _fmtAmt(totals.cAmount),
              textAlign: TextAlign.center,
              style: TextStyle(
                color:      accentColor,
                fontSize:   11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: _kColDel),
        ],
      ),
    );
  }
}
