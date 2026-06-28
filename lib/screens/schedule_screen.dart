import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../services/theme_service.dart';
import '../services/runs_service.dart';
import '../models/booking.dart';
import '../models/pet.dart';
import '../widgets/dialogs/add_booking_dialog.dart';
import '../widgets/dialogs/view_booking_dialog.dart';
import '../widgets/dialogs/add_customer_dialog.dart';

const int kTotalRuns = 15;
const double kCellW = 52;
const double kCellH = 44;
const double kHeaderH = 36;
const double kRunColW = 110;

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late DateTime _month;
  final _hScroll = ScrollController();
  final _leftScroll = ScrollController();
  final _transform = TransformationController();

  // customerId -> pets, populated lazily per visible month
  final Map<String, List<Pet>> _petsCache = {};
  final Set<String> _fetchedIds = {};

  @override
  void initState() {
    super.initState();
    _month = DateTime(DateTime.now().year, DateTime.now().month);
    _transform.addListener(_onTransform);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadPetsForMonth(context.read<AppProvider>());
  }

  Future<void> _loadPetsForMonth(AppProvider app) async {
    final ids = app.bookings
        .where((b) =>
            b.month == _month.month &&
            b.year == _month.year &&
            b.customerId.isNotEmpty)
        .map((b) => b.customerId)
        .toSet()
        .difference(_fetchedIds);

    for (final id in ids) {
      _fetchedIds.add(id);
      final pets = await app.getPets(id);
      if (mounted) setState(() => _petsCache[id] = pets);
    }
  }

  void _onTransform() {
    final t = _transform.value.getTranslation();
    final hOff = (-t.x).clamp(0.0, double.infinity);
    final vOff = (-t.y).clamp(0.0, double.infinity);
    if (_hScroll.hasClients) {
      final max = _hScroll.position.maxScrollExtent;
      _hScroll.jumpTo(hOff.clamp(0.0, max));
    }
    if (_leftScroll.hasClients) {
      final max = _leftScroll.position.maxScrollExtent;
      _leftScroll.jumpTo(vOff.clamp(0.0, max));
    }
  }

  @override
  void dispose() {
    _hScroll.dispose();
    _leftScroll.dispose();
    _transform.dispose();
    super.dispose();
  }

  int get _daysInMonth =>
      DateUtils.getDaysInMonth(_month.year, _month.month);

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = context.watch<ThemeService>();
    final runs = context.watch<RunsService>();
    final days = _daysInMonth;
    final today = DateTime.now();
    final runCount = runs.count;
    final runNames = runs.names;

    // Build lookup: key -> booking
    final Map<String, Booking> cellMap = {};
    for (final b in app.bookings) {
      if (b.month == _month.month && b.year == _month.year) {
        for (int d = b.day; d <= b.endDay && d <= days; d++) {
          final key = Booking.generateKey(b.year, b.month, d, b.runIndex);
          cellMap[key] = b;
        }
      }
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Month navigation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  _NavBtn(
                    icon: Icons.chevron_left,
                    color: theme.primaryColor,
                    onTap: () {
                      setState(() => _month =
                          DateTime(_month.year, _month.month - 1));
                      _loadPetsForMonth(app);
                    },
                  ),
                  Expanded(
                    child: Text(
                      DateFormat('MMMM yyyy').format(_month),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _NavBtn(
                    icon: Icons.chevron_right,
                    color: theme.primaryColor,
                    onTap: () {
                      setState(() => _month =
                          DateTime(_month.year, _month.month + 1));
                      _loadPetsForMonth(app);
                    },
                  ),
                ],
              ),
            ),

            // Pinned header row
            Row(
              children: [
                Container(
                  width: kRunColW,
                  height: kHeaderH,
                  color: theme.lightBgColor,
                  alignment: Alignment.center,
                  child: Text('Run',
                      style: TextStyle(
                          color: theme.subtextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
                Container(width: 1, height: kHeaderH, color: theme.borderColor),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _hScroll,
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: SizedBox(
                      width: kCellW * days,
                      child: Row(
                        children: List.generate(days, (d) {
                          final date =
                              DateTime(_month.year, _month.month, d + 1);
                          final isToday = date.day == today.day &&
                              date.month == today.month &&
                              date.year == today.year;
                          return Container(
                            width: kCellW,
                            height: kHeaderH,
                            color: isToday
                                ? theme.primaryColor.withValues(alpha: 0.15)
                                : theme.lightBgColor,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(DateFormat('E').format(date),
                                    style: TextStyle(
                                        color: theme.subtextColor,
                                        fontSize: 9)),
                                Text('${d + 1}',
                                    style: TextStyle(
                                      color: isToday
                                          ? theme.primaryColor
                                          : theme.textColor,
                                      fontSize: 13,
                                      fontWeight: isToday
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    )),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Grid body — vertical outer, horizontal inner
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Frozen run-name column
                  SizedBox(
                    width: kRunColW,
                    child: SingleChildScrollView(
                      controller: _leftScroll,
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        children: List.generate(
                          runCount,
                          (i) => Container(
                            height: kCellH,
                            decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      color: theme.gridLineColor)),
                            ),
                            alignment: Alignment.centerLeft,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(runNames[i],
                                style: TextStyle(
                                    color: theme.textColor, fontSize: 13)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(width: 1, color: theme.borderColor),
                  // Scrollable body: InteractiveViewer handles both axes
                  Expanded(
                    child: InteractiveViewer(
                      transformationController: _transform,
                      constrained: false,
                      scaleEnabled: false,
                      boundaryMargin: EdgeInsets.zero,
                      child: SizedBox(
                          width: kCellW * days,
                          height: runCount * kCellH,
                          child: Column(
                            children: List.generate(runCount, (runI) {
                              return Row(
                                children: List.generate(days, (dayI) {
                                  final d = dayI + 1;
                                  final key = Booking.generateKey(
                                      _month.year, _month.month, d, runI);
                                  final booking = cellMap[key];
                                  final isCheckedIn =
                                      booking?.status == 'CheckedIn';
                                  final date =
                                      DateTime(_month.year, _month.month, d);
                                  final isToday = date.day == today.day &&
                                      date.month == today.month &&
                                      date.year == today.year;

                                  Color cellColor;
                                  if (booking != null) {
                                    cellColor = isCheckedIn
                                        ? const Color(0xFF4CAF50)
                                        : theme.primaryColor;
                                  } else {
                                    cellColor = isToday
                                        ? theme.primaryColor
                                            .withValues(alpha: 0.08)
                                        : theme.cardBgColor;
                                  }

                                  return GestureDetector(
                                    onTap: () => booking != null
                                        ? _viewBooking(
                                            context, booking, app, theme)
                                        : _addBooking(context, d, runI,
                                            runNames[runI], app, theme),
                                    child: Container(
                                      width: kCellW,
                                      height: kCellH,
                                      decoration: BoxDecoration(
                                        color: cellColor,
                                        border: Border(
                                          right: BorderSide(
                                              color: theme.gridLineColor,
                                              width: 0.5),
                                          bottom: BorderSide(
                                              color: theme.gridLineColor,
                                              width: 0.5),
                                        ),
                                      ),
                                      child: booking != null && booking.day == d
                                          ? Padding(
                                              padding: const EdgeInsets.all(4),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    _cellLabel(booking),
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    booking.checkInTime,
                                                    style: TextStyle(
                                                        color: Colors.white
                                                            .withValues(
                                                                alpha: 0.8),
                                                        fontSize: 8),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : null,
                                    ),
                                  );
                                }),
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Legend
            Container(
              color: theme.cardBgColor,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LegendItem(
                      color: theme.cardBgColor,
                      border: theme.borderColor,
                      label: 'Available',
                      theme: theme),
                  const SizedBox(width: 20),
                  _LegendItem(
                      color: theme.primaryColor,
                      label: 'Booked',
                      theme: theme),
                  const SizedBox(width: 20),
                  _LegendItem(
                      color: const Color(0xFF4CAF50),
                      label: 'Checked In',
                      theme: theme),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        onPressed: () =>
            _addBooking(context, DateTime.now().day, 0, 'Run 1', app, theme),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _cellLabel(Booking booking) {
    final pets = _petsCache[booking.customerId];
    if (pets != null && pets.isNotEmpty) {
      return pets.map((p) => p.name).join(', ');
    }
    return booking.customerName;
  }

  void _addBooking(BuildContext context, int day, int runIndex, String runName,
      AppProvider app, ThemeService theme) {
    showDialog(
      context: context,
      builder: (_) => AddBookingDialog(
        initialDay: day,
        initialMonth: _month.month,
        initialYear: _month.year,
        initialRunIndex: runIndex,
        initialRunName: runName,
        customers: app.customers,
        onSave: (b) => app.saveBooking(b),
        theme: theme,
      ),
    );
  }

  void _viewBooking(
      BuildContext context, Booking b, AppProvider app, ThemeService theme) {
    showDialog(
      context: context,
      builder: (_) => ViewBookingDialog(
        booking: b,
        onUpdate: (updated) => app.saveBooking(updated),
        onDelete: () => app.deleteBooking(b),
        theme: theme,
        getPets: (customerId) => app.getPets(customerId),
        onEditCustomer: (customerId) async {
          final customer =
              app.customers.where((c) => c.id == customerId).firstOrNull;
          if (customer == null) return;
          final pets = await app.getPets(customerId);
          if (!context.mounted) return;
          Navigator.pop(context);
          showDialog(
            context: context,
            builder: (_) => AddCustomerDialog(
              existing: customer,
              initialPets: pets,
              onSave: (c, toSave, toDelete) async {
                await app.saveCustomer(c);
                for (final p in toSave) {
                  await app.savePet(p);
                }
                for (final p in toDelete) {
                  await app.deletePet(p);
                }
                // Evict cache so the grid re-fetches updated pet names
                _fetchedIds.remove(customerId);
                _petsCache.remove(customerId);
                await _loadPetsForMonth(app);
              },
              theme: theme,
            ),
          );
        },
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _NavBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final Color? border;
  final String label;
  final ThemeService theme;
  const _LegendItem(
      {required this.color, this.border, required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: border != null ? Border.all(color: border!) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(color: theme.subtextColor, fontSize: 12)),
      ],
    );
  }
}
