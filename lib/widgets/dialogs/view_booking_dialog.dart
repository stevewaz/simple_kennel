import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/booking.dart';
import '../../services/theme_service.dart';

class ViewBookingDialog extends StatelessWidget {
  final Booking booking;
  final Future<void> Function(Booking) onUpdate;
  final Future<void> Function() onDelete;
  final ThemeService theme;

  const ViewBookingDialog({
    super.key,
    required this.booking,
    required this.onUpdate,
    required this.onDelete,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isCheckedIn = booking.status == 'CheckedIn';
    final checkIn = booking.checkInDate;
    final checkOut = booking.checkOutDate;

    return AlertDialog(
      backgroundColor: theme.cardBgColor,
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.primaryColor,
            radius: 20,
            child: Text(_initials(booking.customerName),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.customerName,
                    style: TextStyle(
                        color: theme.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Text(booking.runName,
                    style: TextStyle(
                        color: theme.subtextColor, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _InfoRow('Check-in',
                DateFormat('MMM d, yyyy').format(checkIn), theme),
            _InfoRow('Check-out',
                DateFormat('MMM d, yyyy').format(checkOut), theme),
            _InfoRow('Status', booking.status, theme),
            if (booking.notes.isNotEmpty)
              _InfoRow('Notes', booking.notes, theme),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Close', style: TextStyle(color: theme.subtextColor))),
        TextButton(
          onPressed: () {
            onDelete();
            Navigator.pop(context);
          },
          child: const Text('Delete',
              style: TextStyle(color: Color(0xFFD4714D))),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor:
                  isCheckedIn ? const Color(0xFFD4714D) : const Color(0xFF4CAF50),
              foregroundColor: Colors.white),
          onPressed: () {
            onUpdate(booking.copyWith(
                status: isCheckedIn ? 'Scheduled' : 'CheckedIn'));
            Navigator.pop(context);
          },
          child: Text(isCheckedIn ? 'Check Out' : 'Check In'),
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isEmpty ? '?' : name[0].toUpperCase();
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeService theme;
  const _InfoRow(this.label, this.value, this.theme);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: TextStyle(color: theme.subtextColor, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    color: theme.textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
