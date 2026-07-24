import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../services/theme_service.dart';
import '../models/booking.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = context.watch<ThemeService>();
    final today = DateTime.now();

    final occupied = app.occupiedRuns;
    const totalRuns = 15;
    final occupancyPct = totalRuns > 0 ? occupied / totalRuns : 0.0;

    final todayActivities = <_Activity>[];
    for (final b in app.bookings) {
      if (b.day == today.day && b.month == today.month && b.year == today.year) {
        todayActivities.add(_Activity(
          booking: b,
          type: 'Check-in',
          checkInTime: b.checkInTime,
          badgeColor: const Color(0xFF4CAF50),
        ));
      }
    }
    for (final b in app.bookings) {
      if (b.endDay == today.day &&
          b.month == today.month &&
          b.year == today.year &&
          b.day != today.day) {
        todayActivities.add(_Activity(
          booking: b,
          type: 'Check-out',
          checkInTime: null,
          badgeColor: const Color(0xFFD4714D),
        ));
      }
    }

    final upcoming = app.bookings
        .where((b) => DateTime(b.year, b.month, b.day).isAfter(today))
        .toList()
      ..sort((a, b) =>
          DateTime(a.year, a.month, a.day).compareTo(DateTime(b.year, b.month, b.day)));
    final upcomingSlice = upcoming.take(8).toList();

    final amCount = app.todayAmCheckIns;
    final pmCount = app.todayPmCheckIns;
    final checkInSub = amCount == 0 && pmCount == 0
        ? 'arrivals'
        : '$amCount AM · $pmCount PM';

    return Scaffold(
      backgroundColor: theme.scaffoldBgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, MMMM d').format(today),
                      style: TextStyle(color: theme.subtextColor, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Dashboard',
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Stat cards - 2x2 grid
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Occupancy',
                          value: '$occupied / $totalRuns',
                          sub: '${(occupancyPct * 100).toStringAsFixed(0)}% full',
                          valueColor: theme.primaryColor,
                          progress: occupancyPct,
                          progressColor: theme.primaryColor,
                          theme: theme,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Check-ins',
                          value: app.todayCheckIns.toString(),
                          sub: checkInSub,
                          valueColor: const Color(0xFF4CAF50),
                          theme: theme,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Check-outs',
                          value: app.todayCheckOuts.toString(),
                          sub: 'departures',
                          valueColor: const Color(0xFFD4714D),
                          theme: theme,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Customers',
                          value: app.customers.length.toString(),
                          sub: 'total',
                          valueColor: const Color(0xFF2196F3),
                          theme: theme,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Activity sections
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Card(
                      theme: theme,
                      title: "Today's Activity",
                      child: todayActivities.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: Text(
                                  'No activity',
                                  style: TextStyle(
                                    color: theme.subtextColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            )
                          : Column(
                              children: todayActivities
                                  .map((a) => _ActivityRow(
                                        a: a,
                                        theme: theme,
                                        onCheckIn: a.type == 'Check-in' &&
                                                a.booking.status != 'CheckedIn'
                                            ? () async {
                                                await app.checkInWithDraftInvoice(
                                                    a.booking);
                                                if (!kIsWeb) {
                                                  await app
                                                      .printRunSheetForBooking(
                                                          a.booking);
                                                }
                                              }
                                            : null,
                                      ))
                                  .toList(),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Card(
                      theme: theme,
                      title: 'Upcoming Bookings',
                      child: upcomingSlice.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: Text(
                                  'None scheduled',
                                  style: TextStyle(
                                    color: theme.subtextColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            )
                          : Column(
                              children: upcomingSlice
                                  .map((b) => _UpcomingRow(b: b, today: today, theme: theme))
                                  .toList(),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color valueColor;
  final ThemeService theme;
  final double? progress;
  final Color? progressColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.valueColor,
    required this.theme,
    this.progress,
    this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardBgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                color: theme.subtextColor,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              )),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: valueColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(sub,
              style: TextStyle(
                color: theme.subtextColor,
                fontSize: 11,
              )),
          if (progress != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                color: progressColor,
                backgroundColor: theme.borderColor,
                minHeight: 3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final ThemeService theme;
  final String title;
  final Widget child;

  const _Card({required this.theme, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardBgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Activity {
  final Booking booking;
  final String type;
  final String? checkInTime;
  final Color badgeColor;

  _Activity({
    required this.booking,
    required this.type,
    required this.checkInTime,
    required this.badgeColor,
  });

  String get customerName => booking.customerName;
  String get runName => booking.runName;

  String get initials {
    final parts = customerName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return customerName.isEmpty ? '?' : customerName[0].toUpperCase();
  }
}

class _ActivityRow extends StatelessWidget {
  final _Activity a;
  final ThemeService theme;
  final VoidCallback? onCheckIn;

  const _ActivityRow({
    required this.a,
    required this.theme,
    this.onCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    final isCheckedIn = a.booking.status == 'CheckedIn';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor:
                isCheckedIn ? const Color(0xFF4CAF50) : theme.primaryColor,
            child: Text(a.initials,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.customerName,
                    style: TextStyle(
                        color: theme.textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                Text(a.runName,
                    style: TextStyle(color: theme.subtextColor, fontSize: 11)),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // AM/PM pill
              if (a.checkInTime != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  decoration: BoxDecoration(
                    color: a.checkInTime == 'AM'
                        ? const Color(0xFF1976D2)
                        : const Color(0xFF7B1FA2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(a.checkInTime!,
                      style: const TextStyle(color: Colors.white, fontSize: 10)),
                ),
                const SizedBox(width: 6),
              ],
              // Check-in button / checked-in badge
              if (a.type == 'Check-in')
                isCheckedIn
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Checked In',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )
                    : ElevatedButton(
                        onPressed: onCheckIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                          elevation: 0,
                        ),
                        child: const Text('Check-In'),
                      )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: a.badgeColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(a.type,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 10)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpcomingRow extends StatelessWidget {
  final Booking b;
  final DateTime today;
  final ThemeService theme;
  const _UpcomingRow(
      {required this.b, required this.today, required this.theme});

  @override
  Widget build(BuildContext context) {
    final checkIn = DateTime(b.year, b.month, b.day);
    final checkOut = DateTime(b.year, b.month, b.endDay);
    final days = checkIn.difference(today).inDays;
    final dateRange = checkIn == checkOut
        ? DateFormat('MMM d').format(checkIn)
        : '${DateFormat('MMM d').format(checkIn)} – ${DateFormat('MMM d').format(checkOut)}';
    final daysLabel = days == 1 ? 'Tomorrow' : 'In $days days';

    final parts = b.customerName.trim().split(RegExp(r'\s+'));
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : (b.customerName.isEmpty ? '?' : b.customerName[0].toUpperCase());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF2196F3),
            child: Text(initials,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.customerName,
                    style: TextStyle(
                        color: theme.textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                Text(b.runName,
                    style: TextStyle(color: theme.subtextColor, fontSize: 11)),
                Text(dateRange,
                    style: TextStyle(color: theme.subtextColor, fontSize: 11)),
              ],
            ),
          ),
          Text(daysLabel,
              style: TextStyle(color: theme.primaryColor, fontSize: 11)),
        ],
      ),
    );
  }
}
