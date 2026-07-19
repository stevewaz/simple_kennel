import 'dart:math';
import 'package:flutter/material.dart';

String _pbId() {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final rng = Random();
  return List.generate(15, (_) => chars[rng.nextInt(chars.length)]).join();
}

class Invoice {
  String id;
  String customerId;
  String customerName;
  String invoiceNumber;
  String bookingId;
  DateTime issueDate;
  DateTime dueDate;
  String status; // Draft | Sent | Paid | Overdue
  String notes;
  double subTotal;
  double taxRate;
  double taxAmount;
  double totalAmount;
  String paymentMethod; // '' | Cash | Check | Credit Card | Other
  DateTime? paidAt;
  DateTime createdAt;

  Invoice({
    String id = '',
    this.customerId = '',
    this.customerName = '',
    this.invoiceNumber = '',
    this.bookingId = '',
    required this.issueDate,
    required this.dueDate,
    this.status = 'Draft',
    this.notes = '',
    this.subTotal = 0,
    this.taxRate = 0,
    this.taxAmount = 0,
    this.totalAmount = 0,
    this.paymentMethod = '',
    this.paidAt,
    required this.createdAt,
  }) : id = id.isEmpty ? _pbId() : id;

  Color get statusColor {
    switch (status) {
      case 'Sent':
        return const Color(0xFF2196F3);
      case 'Paid':
        return const Color(0xFF4CAF50);
      case 'Overdue':
        return const Color(0xFFD4714D);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String get amountDisplay => '\$${totalAmount.toStringAsFixed(2)}';

  String get initials {
    if (customerName.trim().isEmpty) return '?';
    final parts = customerName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return customerName[0].toUpperCase();
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'customerId': customerId,
        'customerName': customerName,
        'invoiceNumber': invoiceNumber,
        'bookingId': bookingId,
        'issueDate': issueDate.toIso8601String(),
        'dueDate': dueDate.toIso8601String(),
        'status': status,
        'notes': notes,
        'subTotal': subTotal,
        'taxRate': taxRate,
        'taxAmount': taxAmount,
        'totalAmount': totalAmount,
        'paymentMethod': paymentMethod,
        'paidAt': paidAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Invoice.fromMap(Map<String, dynamic> m) => Invoice(
        id: m['id'] as String,
        customerId: m['customerId'] as String? ?? '',
        customerName: m['customerName'] as String? ?? '',
        invoiceNumber: m['invoiceNumber'] as String? ?? '',
        bookingId: m['bookingId'] as String? ?? '',
        issueDate: DateTime.tryParse(m['issueDate'] as String? ?? '') ?? DateTime.now(),
        dueDate: DateTime.tryParse(m['dueDate'] as String? ?? '') ??
            DateTime.now().add(const Duration(days: 30)),
        status: m['status'] as String? ?? 'Draft',
        notes: m['notes'] as String? ?? '',
        subTotal: (m['subTotal'] as num?)?.toDouble() ?? 0,
        taxRate: (m['taxRate'] as num?)?.toDouble() ?? 0,
        taxAmount: (m['taxAmount'] as num?)?.toDouble() ?? 0,
        totalAmount: (m['totalAmount'] as num?)?.toDouble() ?? 0,
        paymentMethod: m['paymentMethod'] as String? ?? '',
        paidAt: DateTime.tryParse(m['paidAt'] as String? ?? ''),
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  Invoice copyWith({
    String? status,
    String? notes,
    String? paymentMethod,
    DateTime? paidAt,
  }) =>
      Invoice(
        id: id,
        customerId: customerId,
        customerName: customerName,
        invoiceNumber: invoiceNumber,
        bookingId: bookingId,
        issueDate: issueDate,
        dueDate: dueDate,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        subTotal: subTotal,
        taxRate: taxRate,
        taxAmount: taxAmount,
        totalAmount: totalAmount,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        paidAt: paidAt ?? this.paidAt,
        createdAt: createdAt,
      );
}

class InvoiceLineItem {
  String id;
  String invoiceId;
  String description;
  double quantity;
  double unitPrice;

  InvoiceLineItem({
    String id = '',
    required this.invoiceId,
    this.description = '',
    this.quantity = 1,
    this.unitPrice = 0,
  }) : id = id.isEmpty ? _pbId() : id;

  double get lineTotal => quantity * unitPrice;

  Map<String, dynamic> toMap() => {
        'id': id,
        'invoiceId': invoiceId,
        'description': description,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };

  factory InvoiceLineItem.fromMap(Map<String, dynamic> m) => InvoiceLineItem(
        id: m['id'] as String,
        invoiceId: m['invoiceId'] as String? ?? '',
        description: m['description'] as String? ?? '',
        quantity: (m['quantity'] as num?)?.toDouble() ?? 1,
        unitPrice: (m['unitPrice'] as num?)?.toDouble() ?? 0,
      );
}
