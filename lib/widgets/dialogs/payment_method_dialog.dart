import 'package:flutter/material.dart';
import '../../data/payment_methods.dart';
import '../../services/theme_service.dart';

/// Result of [PaymentMethodDialog]: `null` means cancelled (do nothing).
/// [proceed] with [method] == null means "proceed without recording payment".
typedef PaymentMethodResult = ({bool proceed, String? method});

/// Shared payment-method picker used both when checking a booking out and
/// when marking an invoice Paid from the Invoices screen.
class PaymentMethodDialog extends StatefulWidget {
  final ThemeService theme;
  final String title;
  final String? amountLabel;
  final String confirmLabel;
  final String? skipLabel;

  const PaymentMethodDialog({
    super.key,
    required this.theme,
    this.title = 'Collect Payment',
    this.amountLabel,
    this.confirmLabel = 'Mark Paid',
    this.skipLabel,
  });

  @override
  State<PaymentMethodDialog> createState() => _PaymentMethodDialogState();
}

class _PaymentMethodDialogState extends State<PaymentMethodDialog> {
  String _method = paymentMethods.first;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return AlertDialog(
      backgroundColor: theme.cardBgColor,
      title: Text(widget.title, style: TextStyle(color: theme.textColor)),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.amountLabel != null) ...[
              Text(widget.amountLabel!,
                  style: TextStyle(
                      color: theme.primaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
            ],
            Text('Payment Method',
                style: TextStyle(color: theme.subtextColor, fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: paymentMethods.map((m) {
                final selected = m == _method;
                return ChoiceChip(
                  label: Text(m,
                      style: TextStyle(
                          color: selected ? Colors.white : theme.textColor,
                          fontSize: 13)),
                  selected: selected,
                  selectedColor: theme.primaryColor,
                  backgroundColor: theme.scaffoldBgColor,
                  side: BorderSide(color: theme.borderColor),
                  onSelected: (_) => setState(() => _method = m),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: theme.subtextColor)),
        ),
        if (widget.skipLabel != null)
          TextButton(
            onPressed: () => Navigator.pop(
                context, (proceed: true, method: null) as PaymentMethodResult),
            child:
                Text(widget.skipLabel!, style: TextStyle(color: theme.subtextColor)),
          ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white),
          onPressed: () => Navigator.pop(
              context, (proceed: true, method: _method) as PaymentMethodResult),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
