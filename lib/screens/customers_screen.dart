import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/theme_service.dart';
import '../models/customer.dart';
import '../widgets/dialogs/add_customer_dialog.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = context.watch<ThemeService>();
    final filtered = _search.isEmpty
        ? app.customers
        : app.customers
            .where((c) =>
                c.name.toLowerCase().contains(_search.toLowerCase()) ||
                c.email.toLowerCase().contains(_search.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search customers...',
                        prefixIcon:
                            Icon(Icons.search, color: theme.subtextColor),
                        hintStyle: TextStyle(color: theme.subtextColor),
                      ),
                      style: TextStyle(color: theme.textColor),
                      onChanged: (v) => setState(() => _search = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Customer'),
                    onPressed: () => _showAddDialog(context, null, app, theme),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text('No customers found',
                          style: TextStyle(color: theme.subtextColor)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) =>
                          _CustomerTile(c: filtered[i], theme: theme, app: app),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, Customer? existing, AppProvider app,
      ThemeService theme) {
    showDialog(
      context: context,
      builder: (_) => AddCustomerDialog(
        existing: existing,
        onSave: (c, toSave, toDelete) async {
          await app.saveCustomer(c);
          for (final p in toSave) {
            await app.savePet(p);
          }
        },
        theme: theme,
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  final Customer c;
  final ThemeService theme;
  final AppProvider app;
  const _CustomerTile(
      {required this.c, required this.theme, required this.app});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardBgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderColor),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.primaryColor,
          child: Text(c.initials,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ),
        title: Text(c.name,
            style: TextStyle(
                color: theme.textColor, fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (c.email.isNotEmpty)
              Text(c.email,
                  style: TextStyle(color: theme.subtextColor, fontSize: 12)),
            if (c.phoneNumber.isNotEmpty)
              Text(c.phoneNumber,
                  style: TextStyle(color: theme.subtextColor, fontSize: 12)),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: theme.subtextColor),
          onPressed: () => _confirmDelete(context),
        ),
        onTap: () => _showEdit(context),
      ),
    );
  }

  void _showEdit(BuildContext context) async {
    final pets = await app.getPets(c.id);
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (_) => AddCustomerDialog(
        existing: c,
        initialPets: pets,
        onSave: (updated, toSave, toDelete) async {
          await app.saveCustomer(updated);
          for (final p in toSave) {
            await app.savePet(p);
          }
          for (final p in toDelete) {
            await app.deletePet(p);
          }
        },
        theme: theme,
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.cardBgColor,
        title: Text('Delete ${c.name}?',
            style: TextStyle(color: theme.textColor)),
        content: Text('This will also delete all their pets.',
            style: TextStyle(color: theme.subtextColor)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: theme.subtextColor))),
          TextButton(
            onPressed: () {
              app.deleteCustomer(c);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Color(0xFFD4714D))),
          ),
        ],
      ),
    );
  }
}
