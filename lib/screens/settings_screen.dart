import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../services/prefs_service.dart';
import '../providers/app_provider.dart';
import '../models/service.dart';
import '../services/runs_service.dart';
import '../widgets/dialogs/add_service_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _taxCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = PrefsService.businessName;
    _addrCtrl.text = PrefsService.businessAddress;
    _phoneCtrl.text = PrefsService.businessPhone;
    _emailCtrl.text = PrefsService.businessEmail;
    final rate = PrefsService.defaultTaxRate;
    _taxCtrl.text = rate > 0 ? rate.toString() : '';
  }

  @override
  void dispose() {
    _save();
    _nameCtrl.dispose();
    _addrCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _taxCtrl.dispose();
    super.dispose();
  }

  void _save() {
    PrefsService.businessName = _nameCtrl.text.trim();
    PrefsService.businessAddress = _addrCtrl.text.trim();
    PrefsService.businessPhone = _phoneCtrl.text.trim();
    PrefsService.businessEmail = _emailCtrl.text.trim();
    final rate = double.tryParse(_taxCtrl.text);
    if (rate != null) PrefsService.defaultTaxRate = rate;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeService>();
    final runs = context.watch<RunsService>();

    return Scaffold(
      backgroundColor: theme.scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _save();
              Navigator.pop(context);
            },
            child: const Text(
              'Done',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SectionLabel('BRANDING', theme),
            _Card(
              theme: theme,
              child: Column(
                children: [
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                        hintText: 'Business name',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero),
                    style: TextStyle(
                        color: theme.textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold),
                    onChanged: (_) => _save(),
                  ),
                  Divider(color: theme.borderColor, height: 24),
                  _LabeledField(label: 'Address', ctrl: _addrCtrl, hint: '123 Main St', keyboard: TextInputType.streetAddress, theme: theme, onChanged: (_) => _save()),
                  Divider(color: theme.borderColor, height: 12),
                  _LabeledField(label: 'Phone', ctrl: _phoneCtrl, hint: '(555) 123-4567', keyboard: TextInputType.phone, theme: theme, onChanged: (_) => _save()),
                  Divider(color: theme.borderColor, height: 12),
                  _LabeledField(label: 'Email', ctrl: _emailCtrl, hint: 'hello@yourbusiness.com', keyboard: TextInputType.emailAddress, theme: theme, onChanged: (_) => _save()),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _SectionLabel('BILLING', theme),
            _Card(
              theme: theme,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Default Tax Rate',
                            style: TextStyle(
                                color: theme.textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                        Text('Applied automatically to new invoices',
                            style: TextStyle(
                                color: theme.subtextColor, fontSize: 12)),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 72,
                    child: TextField(
                      controller: _taxCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '0',
                          contentPadding: EdgeInsets.zero),
                      style: TextStyle(
                          color: theme.primaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                      onChanged: (_) => _save(),
                    ),
                  ),
                  Text('%',
                      style: TextStyle(
                          color: theme.primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _SectionLabel('APPEARANCE', theme),
            _Card(
              theme: theme,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Color Theme',
                      style: TextStyle(
                          color: theme.textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    children: List.generate(ThemeService.presets.length, (i) {
                      final p = ThemeService.presets[i];
                      final selected = theme.index == i;
                      return GestureDetector(
                        onTap: () => theme.setIndex(i),
                        child: Column(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: p.primary,
                                shape: BoxShape.circle,
                                border: selected
                                    ? Border.all(color: theme.textColor, width: 3)
                                    : null,
                              ),
                              child: selected
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 18)
                                  : null,
                            ),
                            const SizedBox(height: 4),
                            Text(p.name,
                                style: TextStyle(
                                    color: theme.subtextColor, fontSize: 10)),
                          ],
                        ),
                      );
                    }),
                  ),
                  Divider(color: theme.borderColor, height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dark Mode',
                                style: TextStyle(
                                    color: theme.textColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold)),
                            Text('Switch between light and dark appearance',
                                style: TextStyle(
                                    color: theme.subtextColor, fontSize: 12)),
                          ],
                        ),
                      ),
                      Switch(
                        value: theme.isDark,
                        activeThumbColor: theme.primaryColor,
                        onChanged: (v) => theme.setDark(v),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _SectionLabel('CATALOG', theme),
            _Card(
              theme: theme,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _showServicesSheet(context, theme),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.storefront_outlined,
                          color: theme.primaryColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Products & Services',
                              style: TextStyle(
                                  color: theme.textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold)),
                          Text('Manage your billing catalog',
                              style: TextStyle(
                                  color: theme.subtextColor, fontSize: 12)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: theme.subtextColor),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            _SectionLabel('RUNS', theme),
            _Card(
              theme: theme,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Number of Runs',
                                style: TextStyle(
                                    color: theme.textColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold)),
                            Text('Total kennel runs on the schedule',
                                style: TextStyle(
                                    color: theme.subtextColor, fontSize: 12)),
                          ],
                        ),
                      ),
                      _Stepper(
                        value: runs.count,
                        min: 1,
                        max: 50,
                        theme: theme,
                        onChanged: (v) => runs.setCount(v),
                      ),
                    ],
                  ),
                  Divider(color: theme.borderColor, height: 24),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _showRunNamesSheet(context, theme, runs),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.edit_outlined,
                              color: theme.primaryColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Run Names',
                                  style: TextStyle(
                                      color: theme.textColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold)),
                              Text('Customize the label for each run',
                                  style: TextStyle(
                                      color: theme.subtextColor, fontSize: 12)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: theme.subtextColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _SectionLabel('ABOUT', theme),
            _Card(
              theme: theme,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SimpleKennel',
                      style: TextStyle(
                          color: theme.textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('Version 1.0',
                      style:
                          TextStyle(color: theme.subtextColor, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showRunNamesSheet(
      BuildContext context, ThemeService theme, RunsService runs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RunNamesSheet(theme: theme, runs: runs),
    );
  }

  void _showServicesSheet(BuildContext context, ThemeService theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ServicesSheet(theme: theme),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final ThemeService theme;
  const _SectionLabel(this.text, this.theme);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(text,
          style: TextStyle(
              color: theme.subtextColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2)),
    );
  }
}

class _Card extends StatelessWidget {
  final ThemeService theme;
  final Widget child;
  const _Card({required this.theme, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderColor),
      ),
      child: child,
    );
  }
}

class _ServicesSheet extends StatelessWidget {
  final ThemeService theme;
  const _ServicesSheet({required this.theme});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Products & Services',
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
                    onPressed: () => _showAdd(context, null, app),
                  ),
                ],
              ),
            ),
            Divider(color: theme.borderColor, height: 1),
            Expanded(
              child: app.services.isEmpty
                  ? Center(
                      child: Text('No services yet',
                          style: TextStyle(color: theme.subtextColor)))
                  : ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.all(16),
                      itemCount: app.services.length,
                      itemBuilder: (_, i) => _SheetServiceTile(
                          s: app.services[i], theme: theme, app: app),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdd(BuildContext context, Service? existing, AppProvider app) {
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

class _SheetServiceTile extends StatelessWidget {
  final Service s;
  final ThemeService theme;
  final AppProvider app;
  const _SheetServiceTile(
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
            Expanded(
              child: Text(s.name,
                  style: TextStyle(
                      color: theme.textColor, fontWeight: FontWeight.bold)),
            ),
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
              onChanged: (v) => app.saveService(Service(
                id: s.id,
                name: s.name,
                description: s.description,
                defaultPrice: s.defaultPrice,
                unit: s.unit,
                isActive: v,
              )),
            ),
            IconButton(
              icon: Icon(Icons.edit_outlined, color: theme.subtextColor),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AddServiceDialog(
                  existing: s,
                  onSave: (updated) => app.saveService(updated),
                  theme: theme,
                ),
              ),
            ),
            IconButton(
              icon:
                  const Icon(Icons.delete_outline, color: Color(0xFFD4714D)),
              onPressed: () => showDialog(
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final String hint;
  final TextInputType keyboard;
  final ThemeService theme;
  final ValueChanged<String> onChanged;

  const _LabeledField({
    required this.label,
    required this.ctrl,
    required this.hint,
    required this.keyboard,
    required this.theme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 58,
          child: Text(label,
              style: TextStyle(color: theme.subtextColor, fontSize: 12)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: ctrl,
            keyboardType: keyboard,
            decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: theme.subtextColor),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero),
            style: TextStyle(color: theme.textColor, fontSize: 13),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ThemeService theme;
  final ValueChanged<int> onChanged;

  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.theme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepBtn(
          icon: Icons.remove,
          enabled: value > min,
          theme: theme,
          onTap: () => onChanged(value - 1),
        ),
        SizedBox(
          width: 36,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: theme.primaryColor,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
        ),
        _StepBtn(
          icon: Icons.add,
          enabled: value < max,
          theme: theme,
          onTap: () => onChanged(value + 1),
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final ThemeService theme;
  final VoidCallback onTap;

  const _StepBtn(
      {required this.icon,
      required this.enabled,
      required this.theme,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled
              ? theme.primaryColor.withValues(alpha: 0.15)
              : theme.borderColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 18,
            color: enabled ? theme.primaryColor : theme.subtextColor),
      ),
    );
  }
}

class _RunNamesSheet extends StatefulWidget {
  final ThemeService theme;
  final RunsService runs;

  const _RunNamesSheet({required this.theme, required this.runs});

  @override
  State<_RunNamesSheet> createState() => _RunNamesSheetState();
}

class _RunNamesSheetState extends State<_RunNamesSheet> {
  late List<TextEditingController> _ctrls;

  @override
  void initState() {
    super.initState();
    _buildControllers();
  }

  void _buildControllers() {
    _ctrls = List.generate(
      widget.runs.count,
      (i) => TextEditingController(text: widget.runs.getName(i)),
    );
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final count = widget.runs.count;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Run Names',
                        style: TextStyle(
                            color: theme.textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Done',
                        style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Divider(color: theme.borderColor, height: 1),
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.all(16),
                itemCount: count,
                itemBuilder: (_, i) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.cardBgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text('${i + 1}',
                            style: TextStyle(
                                color: theme.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _ctrls[i],
                          decoration: InputDecoration(
                            hintText: 'Run ${i + 1}',
                            hintStyle:
                                TextStyle(color: theme.subtextColor),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style:
                              TextStyle(color: theme.textColor, fontSize: 14),
                          onChanged: (v) => widget.runs.setName(i, v),
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
    );
  }
}
