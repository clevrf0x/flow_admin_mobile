// lib/screens/booking/booking_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../models/dealer.dart';
import '../../models/game.dart';
import '../../services/booking_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ENUMS
// ─────────────────────────────────────────────────────────────────────────────

enum DigitMode { one, two, three }

enum BookType { book, range, set, tens, hundreds, triples }

extension BookTypeLabel on BookType {
  String get label {
    switch (this) {
      case BookType.book:
        return 'Book';
      case BookType.range:
        return 'Range';
      case BookType.set:
        return 'Set';
      case BookType.tens:
        return '10s';
      case BookType.hundreds:
        return '100s';
      case BookType.triples:
        return '111s';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOOKING ENTRY
//
// Stores only the ticket data — NO prices.
// Amounts are computed dynamically from the selected dealer's package so that
// switching dealers instantly reflects correct rates in the table.
// The server also never receives prices from the client; it recalculates
// everything from its own stored package data.
// ─────────────────────────────────────────────────────────────────────────────

class BookingEntry {
  final String lsk;
  final String number;
  final int count;

  const BookingEntry({
    required this.lsk,
    required this.number,
    required this.count,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// LSK COLOR HELPER
// ─────────────────────────────────────────────────────────────────────────────

Color lskColor(String lsk) {
  switch (lsk) {
    case 'AB':
      return AppColors.lskAB;
    case 'AC':
      return AppColors.lskAC;
    case 'BC':
      return const Color(0xFF8B949E);
    case 'A':
      return AppColors.lskA;
    case 'B':
      return AppColors.lskB;
    case 'C':
      return AppColors.lskC;
    case 'Box':
      return AppColors.lskBox;
    case 'Super':
      return const Color(0xFF8B949E);
    case 'Both':
      return AppColors.lskBoth;
    default:
      return const Color(0xFF8B949E);
  }
}

// Fallback preview rates when no dealer is selected yet.
// Mirrors server Package model field defaults (commission defaults to 0,
// so d_rate = price - 0 = price).
//   single_ticket_price default = 12, commission default = 0 → d=12, c=12
//   double/super/box_ticket_price default = 10, commission default = 0 → d=10, c=10
const double _kDefaultSingleDRate = 12.0;
const double _kDefaultSingleCRate = 12.0;
const double _kDefaultDoubleDRate = 10.0;
const double _kDefaultDoubleCRate = 10.0;
const double _kDefaultSuperDRate  = 10.0;
const double _kDefaultSuperCRate  = 10.0;
const double _kDefaultBoxDRate    = 10.0;
const double _kDefaultBoxCRate    = 10.0;

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class BookingScreen extends StatefulWidget {
  final String gameId;
  final String gameName;

  const BookingScreen({
    super.key,
    required this.gameId,
    required this.gameName,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DigitMode _digitMode = DigitMode.one;
  BookType _bookType = BookType.book;

  final _field1Controller = TextEditingController();
  final _field2Controller = TextEditingController();
  final _field3Controller = TextEditingController();
  final _field1Focus = FocusNode();
  final _field2Focus = FocusNode();
  final _field3Focus = FocusNode();

  // ── Dealer state ────────────────────────────────────────────────────────────
  List<Dealer> _dealers = [];
  bool _dealersLoading = false;
  String? _dealersError;
  Dealer? _selectedDealer;

  // ── Entries ─────────────────────────────────────────────────────────────────
  final List<BookingEntry> _entries = [];

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Game? get _game {
    try {
      return mockGames.firstWhere((g) => g.id == widget.gameId);
    } catch (_) {
      return null;
    }
  }

  Color _resolvedAccentColor(List<Color> colors) {
    if (colors.first.computeLuminance() < 0.08) return AppColors.gsAccentBlue;
    return colors.first;
  }

  // Amount helpers — select rate based on LSK type, mirrors server _ticket_rates().
  // A/B/C → single  |  AB/AC/BC → double  |  Super → super  |  Box → box
  double _dAmount(BookingEntry e) {
    final pkg = _selectedDealer?.package;
    if (e.lsk == 'A' || e.lsk == 'B' || e.lsk == 'C') {
      return e.count * (pkg?.singleDRate ?? _kDefaultSingleDRate);
    }
    if (e.lsk == 'AB' || e.lsk == 'AC' || e.lsk == 'BC') {
      return e.count * (pkg?.doubleDRate ?? _kDefaultDoubleDRate);
    }
    if (e.lsk == 'Super') {
      return e.count * (pkg?.superDRate ?? _kDefaultSuperDRate);
    }
    // Box
    return e.count * (pkg?.boxDRate ?? _kDefaultBoxDRate);
  }

  double _cAmount(BookingEntry e) {
    final pkg = _selectedDealer?.package;
    if (e.lsk == 'A' || e.lsk == 'B' || e.lsk == 'C') {
      return e.count * (pkg?.singleCRate ?? _kDefaultSingleCRate);
    }
    if (e.lsk == 'AB' || e.lsk == 'AC' || e.lsk == 'BC') {
      return e.count * (pkg?.doubleCRate ?? _kDefaultDoubleCRate);
    }
    if (e.lsk == 'Super') {
      return e.count * (pkg?.superCRate ?? _kDefaultSuperCRate);
    }
    // Box
    return e.count * (pkg?.boxCRate ?? _kDefaultBoxCRate);
  }

  /// Formats a money amount: no decimals when whole, 2 decimal places otherwise.
  /// e.g.  42.0 → "42"   |   42.5 → "42.50"
  String _fmtAmt(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  int get _digitCount => _digitMode == DigitMode.one
      ? 1
      : _digitMode == DigitMode.two
          ? 2
          : 3;

  List<BookType> get _availableBookTypes {
    switch (_digitMode) {
      case DigitMode.one:
        return [BookType.book];
      case DigitMode.two:
        return [BookType.book, BookType.range];
      case DigitMode.three:
        return [
          BookType.book,
          BookType.range,
          BookType.set,
          BookType.tens,
          BookType.hundreds,
          BookType.triples,
        ];
    }
  }

  List<String> get _actionButtons {
    switch (_digitMode) {
      case DigitMode.one:
        return ['A', 'B', 'C', 'ALL'];
      case DigitMode.two:
        return ['AB', 'AC', 'BC', 'ALL'];
      case DigitMode.three:
        return ['SUPER', 'BOX', 'BOTH'];
    }
  }

  List<String> get _fieldHints {
    switch (_bookType) {
      case BookType.book:
        return ['Number', 'Count', ''];
      case BookType.range:
      case BookType.tens:
      case BookType.hundreds:
      case BookType.triples:
        return ['Start', 'End', 'Count'];
      case BookType.set:
        return ['Number', 'Count (Super)', 'Count (Box)'];
    }
  }

  bool get _showThirdField => _bookType != BookType.book;

  String _pad(String raw) => raw.padLeft(_digitCount, '0');

  // ── Dealer fetching ─────────────────────────────────────────────────────────

  Future<void> _fetchDealers() async {
    setState(() {
      _dealersLoading = true;
      _dealersError = null;
    });
    try {
      // TODO: API call — GET /api/v1/dealers/?game_id=<gameId>
      final dealers = await BookingService.getDealers(widget.gameId);
      if (!mounted) return;
      setState(() {
        _dealers = dealers;
        _dealersLoading = false;
        // If previously selected dealer is still in the new list, keep it.
        // Otherwise clear the selection.
        if (_selectedDealer != null) {
          final stillExists =
              dealers.any((d) => d.id == _selectedDealer!.id);
          if (!stillExists) _selectedDealer = null;
        }
      });
    } on BookingException catch (e) {
      if (!mounted) return;
      setState(() {
        _dealersError = e.message;
        _dealersLoading = false;
      });
    }
  }

  // ── Entry generation ────────────────────────────────────────────────────────

  void _onActionButton(String action) {
    final f1 = _field1Controller.text.trim();
    final f2 = _field2Controller.text.trim();
    final f3 = _field3Controller.text.trim();

    if (f1.isEmpty || f2.isEmpty) return;
    if (_showThirdField && f3.isEmpty) return;

    List<BookingEntry> newEntries = [];

    switch (_bookType) {
      case BookType.book:
        newEntries = _generateBook(action, _pad(f1), int.tryParse(f2) ?? 0);
        break;
      case BookType.range:
        newEntries = _generateRange(
            action, int.parse(f1), int.parse(f2), int.tryParse(f3) ?? 1);
        break;
      case BookType.set:
        newEntries = _generateSet(
            _pad(f1), int.tryParse(f2) ?? 0, int.tryParse(f3) ?? 0);
        break;
      case BookType.tens:
        newEntries = _generateTens(
            action, int.parse(f1), int.parse(f2), int.tryParse(f3) ?? 1);
        break;
      case BookType.hundreds:
        newEntries = _generateHundreds(
            action, int.parse(f1), int.parse(f2), int.tryParse(f3) ?? 1);
        break;
      case BookType.triples:
        newEntries = _generateTriples(
            action, int.parse(f1), int.parse(f2), int.tryParse(f3) ?? 1);
        break;
    }

    setState(() => _entries.addAll(newEntries));
    _clearFields();
  }

  List<BookingEntry> _generateBook(String action, String number, int count) {
    final entries = <BookingEntry>[];
    if (_digitMode == DigitMode.one) {
      final lsks = action == 'ALL' ? ['A', 'B', 'C'] : [action];
      for (final lsk in lsks) {
        entries.add(BookingEntry(lsk: lsk, number: number, count: count));
      }
    } else if (_digitMode == DigitMode.two) {
      final lsks = action == 'ALL' ? ['AB', 'AC', 'BC'] : [action];
      for (final lsk in lsks) {
        entries.add(BookingEntry(lsk: lsk, number: number, count: count));
      }
    } else {
      if (action == 'BOX' || action == 'BOTH') {
        entries.add(BookingEntry(lsk: 'Box', number: number, count: count));
      }
      if (action == 'SUPER' || action == 'BOTH') {
        entries.add(BookingEntry(lsk: 'Super', number: number, count: count));
      }
    }
    return entries;
  }

  List<BookingEntry> _generateRange(
      String action, int start, int end, int count) {
    final entries = <BookingEntry>[];
    for (int n = start; n <= end; n++) {
      final numStr = n.toString().padLeft(_digitCount, '0');
      if (_digitMode == DigitMode.two) {
        final lsks = action == 'ALL' ? ['AB', 'AC', 'BC'] : [action];
        for (final lsk in lsks) {
          entries.add(BookingEntry(lsk: lsk, number: numStr, count: count));
        }
      } else {
        if (action == 'BOX' || action == 'BOTH') {
          entries.add(BookingEntry(lsk: 'Box', number: numStr, count: count));
        }
        if (action == 'SUPER' || action == 'BOTH') {
          entries
              .add(BookingEntry(lsk: 'Super', number: numStr, count: count));
        }
      }
    }
    return entries;
  }

  List<BookingEntry> _generateSet(String number, int superCount, int boxCount) {
    final digits = number.split('');
    if (digits.length != 3) return [];
    // Deduplicate by joined string — List.toSet() compares by reference, not
    // value, so '111' → ['1','1','1'] would produce 3 identical permutations.
    final seen = <String>{};
    final perms = _permutations(digits)
        .where((p) => seen.add(p.join()))
        .toList();
    final entries = <BookingEntry>[];
    for (final perm in perms) {
      final numStr = perm.join();
      if (boxCount > 0) {
        entries.add(BookingEntry(lsk: 'Box', number: numStr, count: boxCount));
      }
      if (superCount > 0) {
        entries
            .add(BookingEntry(lsk: 'Super', number: numStr, count: superCount));
      }
    }
    return entries;
  }

  List<BookingEntry> _generateTens(
      String action, int start, int end, int count) {
    final entries = <BookingEntry>[];
    final first = (start / 10).ceil() * 10;
    for (int n = first; n <= end; n += 10) {
      final numStr = n.toString().padLeft(3, '0');
      if (action == 'BOX' || action == 'BOTH') {
        entries.add(BookingEntry(lsk: 'Box', number: numStr, count: count));
      }
      if (action == 'SUPER' || action == 'BOTH') {
        entries.add(BookingEntry(lsk: 'Super', number: numStr, count: count));
      }
    }
    return entries;
  }

  List<BookingEntry> _generateHundreds(
      String action, int start, int end, int count) {
    final entries = <BookingEntry>[];
    final first = (start / 100).ceil() * 100;
    for (int n = first; n <= end; n += 100) {
      final numStr = n.toString().padLeft(3, '0');
      if (action == 'BOX' || action == 'BOTH') {
        entries.add(BookingEntry(lsk: 'Box', number: numStr, count: count));
      }
      if (action == 'SUPER' || action == 'BOTH') {
        entries.add(BookingEntry(lsk: 'Super', number: numStr, count: count));
      }
    }
    return entries;
  }

  List<BookingEntry> _generateTriples(
      String action, int start, int end, int count) {
    final entries = <BookingEntry>[];
    for (int d = 0; d <= 9; d++) {
      final n = d * 111;
      if (n < start || n > end) continue;
      final numStr = n.toString().padLeft(3, '0');
      if (action == 'BOX' || action == 'BOTH') {
        entries.add(BookingEntry(lsk: 'Box', number: numStr, count: count));
      }
      if (action == 'SUPER' || action == 'BOTH') {
        entries.add(BookingEntry(lsk: 'Super', number: numStr, count: count));
      }
    }
    return entries;
  }

  List<List<String>> _permutations(List<String> items) {
    if (items.length <= 1) return [items];
    final result = <List<String>>[];
    for (int i = 0; i < items.length; i++) {
      final rest = [...items]..removeAt(i);
      for (final p in _permutations(rest)) {
        result.add([items[i], ...p]);
      }
    }
    return result;
  }

  void _clearFields() {
    _field1Controller.clear();
    _field2Controller.clear();
    _field3Controller.clear();
    FocusScope.of(context).requestFocus(_field1Focus);
  }

  void _deleteEntry(int index) => setState(() => _entries.removeAt(index));

  int    get _totalCount   => _entries.fold(0,   (s, e) => s + e.count);
  double get _totalCAmount => _entries.fold(0.0, (s, e) => s + _cAmount(e));
  double get _totalDAmount => _entries.fold(0.0, (s, e) => s + _dAmount(e));

  // ── Save flow ───────────────────────────────────────────────────────────────

  void _showDealerPicker(Color accentColor) {
    if (_dealersLoading) return; // still fetching — ignore tap
    if (_dealersError != null) {
      _fetchDealers(); // tap retries the fetch
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => _DealerPickerDialog(
        dealers: _dealers,
        selectedDealer: _selectedDealer,
        accentColor: accentColor,
        onSelected: (dealer) {
          Navigator.of(ctx).pop();
          setState(() => _selectedDealer = dealer);
        },
      ),
    );
  }

  void _onSave(Color accentColor, List<Color> headerColors) {
    if (_entries.isEmpty) {
      _showResultBanner(
        message: 'No entries to save.',
        icon: Icons.info_outline_rounded,
        accentColor: accentColor,
        headerColors: [accentColor, accentColor],
        duration: const Duration(seconds: 2),
      );
      return;
    }
    if (_selectedDealer == null) {
      _showResultBanner(
        message: 'Please select a dealer before saving.',
        icon: Icons.person_outline_rounded,
        accentColor: accentColor,
        headerColors: [accentColor, accentColor],
        duration: const Duration(seconds: 2),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => _SaveConfirmDialog(
        entryCount: _entries.length,
        totalCount: _totalCount,
        totalCAmount: _fmtAmt(_totalCAmount),
        totalDAmount: _fmtAmt(_totalDAmount),
        gameName: widget.gameName,
        dealerName: _selectedDealer!.name,
        headerColors: headerColors,
        accentColor: accentColor,
        onConfirm: () {
          Navigator.of(ctx).pop();
          _submitSave(accentColor, headerColors);
        },
        onCancel: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  Future<void> _submitSave(Color accentColor, List<Color> headerColors) async {
    _showResultBanner(
      message: 'Saving ${_entries.length} entries...',
      icon: Icons.hourglass_top_rounded,
      accentColor: accentColor,
      headerColors: headerColors,
      duration: const Duration(seconds: 30), // dismissed on completion
    );

    try {
      // TODO: API call — POST /api/v1/bookings/
      // Prices are intentionally excluded from the payload; the server
      // calculates D.Amount and C.Amount from the dealer's stored package.
      final result = await BookingService.createBooking(
        gameId: widget.gameId,
        dealerId: _selectedDealer!.id,
        tickets: _entries
            .map((e) =>
                TicketPayload(lsk: e.lsk, number: e.number, count: e.count))
            .toList(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showResultBanner(
        message:
            '${result.ticketCount} entries saved · ₹${result.totalCAmount}',
        icon: Icons.check_circle_rounded,
        accentColor: const Color(0xFF3FB950),
        headerColors: [const Color(0xFF238636), const Color(0xFF1A6326)],
        duration: const Duration(seconds: 3),
        onDismissed: () {
          if (mounted) {
            context.go(
              '/dashboard/${widget.gameId}?gameName=${Uri.encodeComponent(widget.gameName)}',
            );
          }
        },
      );
    } on BookingException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showResultBanner(
        message: e.message,
        icon: Icons.error_outline_rounded,
        accentColor: AppColors.dashboardLogout,
        headerColors: [AppColors.dashboardLogout, const Color(0xFFB91C1C)],
        duration: const Duration(seconds: 4),
      );
    }
  }

  void _showResultBanner({
    required String message,
    required IconData icon,
    required Color accentColor,
    required List<Color> headerColors,
    required Duration duration,
    VoidCallback? onDismissed,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context)
        .showSnackBar(
          SnackBar(
            duration: duration,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: EdgeInsets.zero,
            backgroundColor: Colors.transparent,
            elevation: 0,
            content: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: headerColors.length >= 2
                      ? [headerColors[0], headerColors.last]
                      : [accentColor, accentColor],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .closed
        .then((_) => onDismissed?.call());
  }

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    if (!_availableBookTypes.contains(_bookType)) {
      _bookType = _availableBookTypes.first;
    }
    _fetchDealers();
  }

  @override
  void dispose() {
    _field1Controller.dispose();
    _field2Controller.dispose();
    _field3Controller.dispose();
    _field1Focus.dispose();
    _field2Focus.dispose();
    _field3Focus.dispose();
    super.dispose();
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    final game = _game;
    final headerColors = game?.gradientColors ??
        [AppColors.primaryBlue, AppColors.primaryBlueDark];
    final accentColor = _resolvedAccentColor(headerColors);

    return Scaffold(
      backgroundColor: AppColors.dashboardBg,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            _BookingHeader(
              gameName: widget.gameName,
              gameId: widget.gameId,
              headerColors: headerColors,
            ),
            Expanded(
              child: Column(
                children: [
                  _buildTopControls(accentColor),
                  _buildDivider(),
                  _buildInputRow(accentColor),
                  _buildPasteField(accentColor),
                  _buildActionButtons(accentColor),
                  _buildTableHeader(accentColor),
                  Expanded(child: _buildTableBody(accentColor)),
                ],
              ),
            ),
            _buildFooter(accentColor, headerColors),
          ],
        ),
      ),
    );
  }

  // ── Top controls ────────────────────────────────────────────────────────────

  Widget _buildTopControls(Color accentColor) {
    return Container(
      color: AppColors.dashboardSurface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Dealer row — tappable
          GestureDetector(
            onTap: () => _showDealerPicker(accentColor),
            child: Row(
              children: [
                const Text(
                  'Dealer',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dashboardTextSub,
                    letterSpacing: 1.0,
                  ),
                ),
                const Spacer(),
                _buildDealerTrailing(accentColor),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right,
                    size: 18, color: AppColors.dashboardTextDim),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Digit radios + book type dropdown
          Row(
            children: [
              for (final mode in DigitMode.values) ...[
                _DigitRadio(
                  value: mode,
                  groupValue: _digitMode,
                  accentColor: accentColor,
                  onChanged: (v) => setState(() {
                    _digitMode = v;
                    if (!_availableBookTypes.contains(_bookType)) {
                      _bookType = _availableBookTypes.first;
                    }
                    _clearFields();
                  }),
                ),
                const SizedBox(width: 12),
              ],
              const Spacer(),
              GestureDetector(
                onTap: () => _showBookTypeMenu(context, accentColor),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: accentColor.withOpacity(0.12),
                    border: Border.all(
                        color: accentColor.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _bookType.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(Icons.keyboard_arrow_down_rounded,
                          size: 16, color: accentColor),
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

  Widget _buildDealerTrailing(Color accentColor) {
    if (_dealersLoading) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: accentColor,
        ),
      );
    }
    if (_dealersError != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 16, color: AppColors.dashboardLogout),
          const SizedBox(width: 4),
          const Text(
            'Retry',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.dashboardLogout,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
    return Text(
      _selectedDealer?.name ?? 'Select Dealer',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: _selectedDealer == null
            ? AppColors.dashboardTextDim
            : AppColors.dashboardTextPrim,
      ),
    );
  }

  Widget _buildDivider() =>
      Container(height: 1, color: AppColors.dashboardBorder);

  void _showBookTypeMenu(BuildContext context, Color accentColor) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final offset = button.localToGlobal(Offset.zero, ancestor: overlay);

    showMenu<BookType>(
      context: context,
      color: AppColors.dashboardSurface2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.dashboardBorder, width: 1),
      ),
      position: RelativeRect.fromLTRB(
        offset.dx + button.size.width - 160,
        offset.dy + 130,
        offset.dx + button.size.width,
        offset.dy + 200,
      ),
      items: _availableBookTypes.map((type) {
        final selected = type == _bookType;
        return PopupMenuItem<BookType>(
          value: type,
          child: Text(
            type.label,
            style: TextStyle(
              color: selected ? accentColor : AppColors.dashboardTextPrim,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              fontSize: 14,
            ),
          ),
        );
      }).toList(),
    ).then((selected) {
      if (selected != null && selected != _bookType) {
        setState(() {
          _bookType = selected;
          _clearFields();
        });
      }
    });
  }

  // ── Input row ───────────────────────────────────────────────────────────────

  Widget _buildInputRow(Color accentColor) {
    final hints = _fieldHints;
    final show3 = _showThirdField;
    final numMax = _digitCount;
    final f2Max = _bookType == BookType.book ? null : numMax;

    return Container(
      color: AppColors.dashboardSurface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
              child: _DarkTextField(
            controller: _field1Controller,
            focusNode: _field1Focus,
            hint: hints[0],
            accentColor: accentColor,
            nextFocus: _field2Focus,
            maxLength: numMax,
            minLength: numMax,
          )),
          const SizedBox(width: 10),
          Expanded(
              child: _DarkTextField(
            controller: _field2Controller,
            focusNode: _field2Focus,
            hint: hints[1],
            accentColor: accentColor,
            nextFocus: show3 ? _field3Focus : null,
            maxLength: f2Max,
            minLength: _bookType == BookType.book ? null : numMax,
          )),
          if (show3) ...[
            const SizedBox(width: 10),
            Expanded(
                child: _DarkTextField(
              controller: _field3Controller,
              focusNode: _field3Focus,
              hint: hints[2],
              accentColor: accentColor,
              nextFocus: null,
              maxLength: null,
              minLength: null,
            )),
          ],
        ],
      ),
    );
  }

  // ── Paste field ─────────────────────────────────────────────────────────────

  Widget _buildPasteField(Color accentColor) {
    return Container(
      color: AppColors.dashboardSurface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: TextField(
        enabled: false,
        decoration: InputDecoration(
          hintText: 'Paste Tickets Here',
          hintStyle: const TextStyle(
              color: AppColors.dashboardTextDim, fontSize: 13),
          filled: true,
          fillColor: AppColors.dashboardBg,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: AppColors.dashboardBorder),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
                color: AppColors.dashboardBorder, width: 1),
          ),
        ),
      ),
    );
  }

  // ── Action buttons ──────────────────────────────────────────────────────────

  Widget _buildActionButtons(Color accentColor) {
    final buttons = _actionButtons;
    return Row(
      children: buttons.asMap().entries.map((entry) {
        final i = entry.key;
        final label = entry.value;
        final isLast = i == buttons.length - 1;
        return Expanded(
          child: Material(
            color: accentColor,
            child: InkWell(
              onTap: () => _onActionButton(label),
              splashColor: Colors.white.withOpacity(0.15),
              highlightColor: Colors.white.withOpacity(0.1),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  border: Border(
                    right: isLast
                        ? BorderSide.none
                        : BorderSide(
                            color: Colors.white.withOpacity(0.2), width: 1),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Table header ────────────────────────────────────────────────────────────

  Widget _buildTableHeader(Color accentColor) {
    return Container(
      color: AppColors.dashboardSurface2,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        children: [
          _TH('Lsk', flex: 2, color: accentColor),
          _TH('Number', flex: 3, color: accentColor),
          _TH('Count', flex: 2, color: accentColor),
          _TH('D.Amount', flex: 3, color: accentColor),
          _TH('C.Amount', flex: 3, color: accentColor),
          _TH('#', flex: 2, color: accentColor),
        ],
      ),
    );
  }

  // ── Table body ──────────────────────────────────────────────────────────────

  Widget _buildTableBody(Color accentColor) {
    if (_entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_rounded,
                size: 38, color: AppColors.dashboardTextDim),
            const SizedBox(height: 10),
            const Text(
              'No entries yet',
              style: TextStyle(
                color: AppColors.dashboardTextDim,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final entry = _entries[index];
        final color = lskColor(entry.lsk);
        final isEven = index.isEven;

        return Container(
          color: isEven
              ? AppColors.dashboardBg
              : AppColors.dashboardSurface.withOpacity(0.6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              _TC(entry.lsk, flex: 2, color: color, bold: true),
              _TC(entry.number, flex: 3, color: color),
              _TC('${entry.count}',
                  flex: 2, color: AppColors.dashboardTextSub),
              // Amounts are computed dynamically from the dealer's package
              _TC(_fmtAmt(_dAmount(entry)),
                  flex: 3, color: AppColors.dashboardTextSub),
              _TC(_fmtAmt(_cAmount(entry)),
                  flex: 3, color: AppColors.dashboardTextSub),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () => _deleteEntry(index),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: AppColors.dashboardLogout.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Footer ──────────────────────────────────────────────────────────────────

  Widget _buildFooter(Color accentColor, List<Color> headerColors) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.dashboardSurface,
        border: Border(
            top: BorderSide(color: AppColors.dashboardBorder, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
              child: _FooterStat(
                  label: 'COUNT',
                  value: '$_totalCount',
                  accentColor: accentColor)),
          Container(width: 1, height: 52, color: AppColors.dashboardBorder),
          Expanded(
              child: _FooterStat(
                  label: 'CAMOUNT',
                  value: _fmtAmt(_totalCAmount),
                  accentColor: accentColor)),
          Container(width: 1, height: 52, color: AppColors.dashboardBorder),
          Expanded(
              child: _FooterStat(
                  label: 'DAMOUNT',
                  value: _fmtAmt(_totalDAmount),
                  accentColor: accentColor)),
          GestureDetector(
            onTap: () => _onSave(accentColor, headerColors),
            child: Container(
              width: 110,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: headerColors.length >= 2
                      ? [headerColors[0], headerColors.last]
                      : [accentColor, accentColor],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'Save-${widget.gameName.replaceAll(' ', '')}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SAVE CONFIRM DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class _SaveConfirmDialog extends StatelessWidget {
  final int entryCount;
  final int totalCount;
  final String totalCAmount;
  final String totalDAmount;
  final String gameName;
  final String dealerName;
  final List<Color> headerColors;
  final Color accentColor;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _SaveConfirmDialog({
    required this.entryCount,
    required this.totalCount,
    required this.totalCAmount,
    required this.totalDAmount,
    required this.gameName,
    required this.dealerName,
    required this.headerColors,
    required this.accentColor,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.dashboardSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.dashboardBorder, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gradient header
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: headerColors.length >= 2
                      ? [headerColors[0], headerColors.last]
                      : [accentColor, accentColor],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Confirm Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$entryCount entries · $gameName · $dealerName',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Stats
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _DialogStat('Total Count', '$totalCount', accentColor),
                  const SizedBox(height: 10),
                  _DialogStat('Total C.Amount', totalCAmount, accentColor),
                  const SizedBox(height: 10),
                  _DialogStat('Total D.Amount', totalDAmount, accentColor),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: onCancel,
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: AppColors.dashboardBg,
                              border: Border.all(
                                  color: AppColors.dashboardBorder, width: 1),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: AppColors.dashboardTextSub,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: onConfirm,
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                colors: headerColors.length >= 2
                                    ? [headerColors[0], headerColors.last]
                                    : [accentColor, accentColor],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withOpacity(0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Save',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
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
      ),
    );
  }
}

class _DialogStat extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;

  const _DialogStat(this.label, this.value, this.accentColor);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.dashboardBg,
        border: Border.all(color: AppColors.dashboardBorder, width: 1),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.dashboardTextSub,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DEALER PICKER DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class _DealerPickerDialog extends StatefulWidget {
  final List<Dealer> dealers;
  final Dealer? selectedDealer;
  final Color accentColor;
  final ValueChanged<Dealer> onSelected;

  const _DealerPickerDialog({
    required this.dealers,
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

  List<Dealer> get _filtered {
    if (_query.isEmpty) return widget.dealers;
    final q = _query.toLowerCase();
    return widget.dealers
        .where((d) =>
            d.name.toLowerCase().contains(q) ||
            d.code.toLowerCase().contains(q))
        .toList();
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
                  hintText: 'Search by name or code',
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
                      child: Text(
                        'No dealers found',
                        style: TextStyle(
                          color: AppColors.dashboardTextDim,
                          fontSize: 14,
                        ),
                      ),
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
                            dealer.id == widget.selectedDealer?.id;

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
                                  // Dealer name + code
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dealer.name,
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
                                        Text(
                                          dealer.code,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.dashboardTextDim,
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
                      },
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

class _BookingHeader extends StatelessWidget {
  final String gameName;
  final String gameId;
  final List<Color> headerColors;

  const _BookingHeader({
    required this.gameName,
    required this.gameId,
    required this.headerColors,
  });

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final now = DateTime.now();
    final dateStr =
        '${gameName.split(' ').first}-${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

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
        padding: EdgeInsets.fromLTRB(6, statusBarHeight + 4, 6, 14),
        child: Row(
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
            Expanded(
              child: Text(
                'Sales - $dateStr',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => context.go('/game-selection'),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white.withOpacity(0.22),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.35), width: 1),
                    ),
                    child: const Icon(Icons.home_rounded,
                        color: Colors.white, size: 20),
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

// ─────────────────────────────────────────────────────────────────────────────
// SMALL REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _DigitRadio extends StatelessWidget {
  final DigitMode value;
  final DigitMode groupValue;
  final Color accentColor;
  final ValueChanged<DigitMode> onChanged;

  const _DigitRadio({
    required this.value,
    required this.groupValue,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    final label = value.index + 1;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? accentColor : AppColors.dashboardTextDim,
                width: selected ? 6 : 2,
              ),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '$label',
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              color: selected
                  ? AppColors.dashboardTextPrim
                  : AppColors.dashboardTextSub,
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final Color accentColor;
  final FocusNode? nextFocus;
  final int? maxLength;
  final int? minLength;

  const _DarkTextField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.accentColor,
    required this.nextFocus,
    this.maxLength,
    this.minLength,
  });

  void _advance(BuildContext context) {
    if (minLength != null && controller.text.isNotEmpty) {
      final padded = controller.text.padLeft(minLength!, '0');
      controller.value = controller.value.copyWith(
        text: padded,
        selection: TextSelection.collapsed(offset: padded.length),
      );
    }
    if (nextFocus != null) {
      FocusScope.of(context).requestFocus(nextFocus);
    } else {
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
      ],
      textInputAction:
          nextFocus != null ? TextInputAction.next : TextInputAction.done,
      onEditingComplete: () => _advance(context),
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.dashboardTextPrim,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            color: AppColors.dashboardTextDim, fontSize: 14),
        enabledBorder: const UnderlineInputBorder(
          borderSide:
              BorderSide(color: AppColors.dashboardBorder, width: 1.5),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
        contentPadding: const EdgeInsets.only(bottom: 6),
        isDense: true,
        counterText: '',
      ),
    );
  }
}

class _TH extends StatelessWidget {
  final String label;
  final int flex;
  final Color color;
  const _TH(this.label, {required this.flex, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color.withOpacity(0.8),
            letterSpacing: 0.5,
          ),
        ),
      );
}

class _TC extends StatelessWidget {
  final String text;
  final int flex;
  final Color? color;
  final bool bold;
  const _TC(this.text, {required this.flex, this.color, this.bold = false});

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: color ?? AppColors.dashboardTextPrim,
          ),
        ),
      );
}

class _FooterStat extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;
  const _FooterStat(
      {required this.label, required this.value, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.dashboardTextDim,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
