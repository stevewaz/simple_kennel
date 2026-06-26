import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/theme_service.dart';
import '../models/service.dart';
import '../widgets/dialogs/add_service_dialog.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = context.watch<ThemeService>();

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
                    child: Text('Service Catalog',
                        style: TextStyle(
                            color: theme.textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),
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
                    label: const Text('Add Service'),
                    onPressed: () => _showAdd(context, null, app, theme),
                  ),
                ],
              ),
            ),
            Expanded(
              child: app.services.isEmpty
                  ? Center(
                      child: Text('No services yet',
                          style: TextStyle(color: theme.subtextColor)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: app.services.length,
                      itemBuilder: (_, i) => _ServiceTile(
                          s: app.services[i], theme: theme, app: app),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdd(BuildContext context, Service? existing, AppProvider app,
      ThemeService theme) {
    showDialog(
      context: context,
      builder: (_) => AddServiceDialog(
        existing: existing,
        onSave: (s) => app.saveService(s),
        theme: theme,
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final Service s;
  final ThemeService theme;
  final AppProvider app;
  const _ServiceTile(
      {required this.s, required this.theme, required this.app});

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
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.pets, color: theme.primaryColor, size: 20),
        ),
        title: Row(
          children: [
            Text(s.name,
                style: TextStyle(
                    color: theme.textColor, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('\$${s.defaultPrice.toStringAsFixed(2)}',
                style: TextStyle(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('per ${s.unit}',
                style: TextStyle(color: theme.subtextColor, fontSize: 12)),
            if (s.description.isNotEmpty)
              Text(s.description,
                  style: TextStyle(color: theme.subtextColor, fontSize: 12)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: s.isActive,
              activeThumbColor: theme.primaryColor,
              onChanged: (v) {
                final updated = Service(
                  id: s.id,
                  name: s.name,
                  description: s.description,
                  defaultPrice: s.defaultPrice,
                  unit: s.unit,
                  isActive: v,
                );
                app.saveService(updated);
              },
            ),
            IconButton(
              icon: Icon(Icons.edit_outlined, color: theme.subtextColor),
              onPressed: () => _showEdit(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFFD4714D)),
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showEdit(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AddServiceDialog(
        existing: s,
        onSave: (updated) => app.saveService(updated),
        theme: theme,
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.cardBgColor,
        title: Text('Delete ${s.name}?',
            style: TextStyle(color: theme.textColor)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: TextStyle(color: theme.subtextColor))),
          TextButton(
            onPressed: () {
              app.deleteService(s);
              Navigator.pop(context);
            },
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFD4714D))),
          ),
        ],
      ),
    );
  }
}
