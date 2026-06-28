import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/booking.dart';
import '../../models/pet.dart';
import '../../services/prefs_service.dart';
import '../../services/theme_service.dart';

class ViewBookingDialog extends StatefulWidget {
  final Booking booking;
  final Future<void> Function(Booking) onUpdate;
  final Future<void> Function() onDelete;
  final ThemeService theme;
  final Future<List<Pet>> Function(String customerId) getPets;
  final Future<void> Function(String customerId)? onEditCustomer;

  const ViewBookingDialog({
    super.key,
    required this.booking,
    required this.onUpdate,
    required this.onDelete,
    required this.theme,
    required this.getPets,
    this.onEditCustomer,
  });

  @override
  State<ViewBookingDialog> createState() => _ViewBookingDialogState();
}

class _ViewBookingDialogState extends State<ViewBookingDialog> {
  List<Pet> _pets = [];
  Map<String, List<String>> _petPhotos = {};
  bool _loadingPets = false;

  @override
  void initState() {
    super.initState();
    if (widget.booking.customerId.isNotEmpty) {
      _loadingPets = true;
      widget.getPets(widget.booking.customerId).then((pets) {
        if (mounted) {
          setState(() {
            _pets = pets;
            _petPhotos = {
              for (final p in pets)
                p.id: PrefsService.getPetPhotos(p.id),
            };
            _loadingPets = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final b = widget.booking;
    final isCheckedIn = b.status == 'CheckedIn';

    return AlertDialog(
      backgroundColor: theme.cardBgColor,
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.primaryColor,
            radius: 20,
            child: Text(_initials(b.customerName),
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
                Text(b.customerName,
                    style: TextStyle(
                        color: theme.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Text(b.runName,
                    style:
                        TextStyle(color: theme.subtextColor, fontSize: 12)),
              ],
            ),
          ),
          if (widget.onEditCustomer != null && b.customerId.isNotEmpty)
            IconButton(
              icon: Icon(Icons.edit, size: 18, color: theme.subtextColor),
              tooltip: 'Edit customer',
              onPressed: () => widget.onEditCustomer!(b.customerId),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(
              'Check-in',
              '${DateFormat('MMM d, yyyy').format(b.checkInDate)} · ${b.checkInTime}',
              theme,
            ),
            _InfoRow('Check-out',
                DateFormat('MMM d, yyyy').format(b.checkOutDate), theme),
            _InfoRow('Status', b.status, theme),
            if (b.notes.isNotEmpty) _InfoRow('Notes', b.notes, theme),

            const SizedBox(height: 12),
            Divider(color: theme.borderColor),
            const SizedBox(height: 8),

            // Pets section
            Row(
              children: [
                Icon(Icons.pets, size: 14, color: theme.subtextColor),
                const SizedBox(width: 6),
                Text('Pets',
                    style: TextStyle(
                        color: theme.subtextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5)),
              ],
            ),
            const SizedBox(height: 8),

            if (_loadingPets)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: theme.primaryColor),
                ),
              )
            else if (_pets.isEmpty)
              Text('No pets on file',
                  style:
                      TextStyle(color: theme.subtextColor, fontSize: 13))
            else
              ..._pets.map((p) => _PetCard(
                    pet: p,
                    photos: _petPhotos[p.id] ?? [],
                    theme: theme,
                  )),
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
            widget.onDelete();
            Navigator.pop(context);
          },
          child: const Text('Delete',
              style: TextStyle(color: Color(0xFFD4714D))),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: isCheckedIn
                  ? const Color(0xFFD4714D)
                  : const Color(0xFF4CAF50),
              foregroundColor: Colors.white),
          onPressed: () {
            widget.onUpdate(b.copyWith(
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

class _PetCard extends StatelessWidget {
  final Pet pet;
  final List<String> photos;
  final ThemeService theme;
  const _PetCard({required this.pet, required this.photos, required this.theme});

  @override
  Widget build(BuildContext context) {
    final details = [
      if (pet.species.isNotEmpty) pet.species,
      if (pet.breed.isNotEmpty) pet.breed,
      if (pet.age > 0) '${pet.age} yr${pet.age == 1 ? '' : 's'}',
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(pet.name,
              style: TextStyle(
                  color: theme.textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
          if (details.isNotEmpty)
            Text(details,
                style: TextStyle(color: theme.subtextColor, fontSize: 11)),
          if (pet.notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(pet.notes,
                  style:
                      TextStyle(color: theme.subtextColor, fontSize: 11)),
            ),
          if (!kIsWeb && photos.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.file(
                    File(photos[i]),
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 72,
                      height: 72,
                      color: theme.borderColor,
                      child: Icon(Icons.broken_image,
                          size: 20, color: theme.subtextColor),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
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
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
