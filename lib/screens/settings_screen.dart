import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/tenant_settings_service.dart';
import '../services/theme_service.dart';
import '../providers/app_provider.dart';
import '../models/service.dart';
import '../models/invoice.dart';
import 'package:flutter/services.dart';
import '../services/runs_service.dart';
import '../utils/input_formatters.dart';
import '../utils/tenant_providers.dart';
import '../utils/payments_csv.dart';
import '../widgets/dialogs/add_service_dialog.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

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
  final _nightlyRateCtrl = TextEditingController();
  late final TenantSettingsService _settings;
  late final bool _isOwner;

  @override
  void initState() {
    super.initState();
    final settings = _settings = context.read<TenantSettingsService>();
    _isOwner =
        context.read<AuthService>().currentUser?.uid == settings.tenantId;
    _nameCtrl.text = settings.businessName;
    _addrCtrl.text = settings.businessAddress;
    _phoneCtrl.text = formatUSPhone(settings.businessPhone);
    _emailCtrl.text = settings.businessEmail.toLowerCase();
    final rate = settings.defaultTaxRate;
    _taxCtrl.text = rate > 0 ? rate.toString() : '';
    final nightly = settings.nightlyRate;
    _nightlyRateCtrl.text = nightly > 0 ? nightly.toStringAsFixed(2) : '';
  }

  @override
  void dispose() {
    _save();
    _nameCtrl.dispose();
    _addrCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _taxCtrl.dispose();
    _nightlyRateCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_isOwner) return;
    final settings = _settings;
    settings.updateBusinessInfo(
      name: _nameCtrl.text.trim(),
      address: _addrCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
    );
    final rate = double.tryParse(_taxCtrl.text);
    if (rate != null) settings.setTaxRate(rate);
    final nightly = double.tryParse(_nightlyRateCtrl.text);
    if (nightly != null) settings.setNightlyRate(nightly);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeService>();
    final runs = context.watch<RunsService>();
    final settings = context.watch<TenantSettingsService>();
    final app = context.watch<AppProvider>();

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
            if (_isOwner) ...[
            _SectionLabel('ADMIN CENTER', theme),
            _Card(
              theme: theme,
              child: Column(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _showBusinessInfoSheet(context, theme),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.business_outlined,
                              color: theme.primaryColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Business Info',
                                  style: TextStyle(
                                      color: theme.textColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold)),
                              Text('Manage business details and settings',
                                  style: TextStyle(
                                      color: theme.subtextColor, fontSize: 12)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: theme.subtextColor),
                      ],
                    ),
                  ),
                  Divider(color: theme.borderColor, height: 24),
                  GestureDetector(
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
                  Divider(color: theme.borderColor, height: 24),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _showTeamSheet(context, theme, settings.tenantId),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.people_outlined,
                              color: theme.primaryColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Team',
                                  style: TextStyle(
                                      color: theme.textColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold)),
                              Text('Manage staff members',
                                  style: TextStyle(
                                      color: theme.subtextColor, fontSize: 12)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: theme.subtextColor),
                      ],
                    ),
                  ),
                  Divider(color: theme.borderColor, height: 24),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _showReportsSheet(context, theme),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.assessment_outlined,
                              color: theme.primaryColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Reports',
                                  style: TextStyle(
                                      color: theme.textColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold)),
                              Text('View and export payment reports',
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
            ],

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

            _SectionLabel('ACCOUNT', theme),
            _Card(
              theme: theme,
              child: InkWell(
                onTap: () => _confirmSignOut(context),
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: Color(0xFFD4714D)),
                    const SizedBox(width: 10),
                    const Text('Sign Out',
                        style: TextStyle(
                            color: Color(0xFFD4714D),
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            _SectionLabel('ABOUT', theme),
            _Card(
              theme: theme,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Runbook',
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
      builder: (_) =>
          withTenantProviders(context, _ServicesSheet(theme: theme)),
    );
  }

  void _showReportsSheet(BuildContext context, ThemeService theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          withTenantProviders(context, _ReportsBottomSheet(theme: theme)),
    );
  }

  void _showBusinessInfoSheet(BuildContext context, ThemeService theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BusinessInfoBottomSheet(
        theme: theme,
        nameCtrl: _nameCtrl,
        addrCtrl: _addrCtrl,
        phoneCtrl: _phoneCtrl,
        emailCtrl: _emailCtrl,
        taxCtrl: _taxCtrl,
        onSave: _save,
      ),
    );
  }

  void _showTeamSheet(BuildContext context, ThemeService theme, String tenantId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TeamBottomSheet(theme: theme, tenantId: tenantId),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final theme = context.read<ThemeService>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.cardBgColor,
        title: Text('Sign Out?', style: TextStyle(color: theme.textColor)),
        content: Text(
            'You\'ll need to sign back in to access this business\'s data.',
            style: TextStyle(color: theme.subtextColor)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel',
                  style: TextStyle(color: theme.subtextColor))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sign Out',
                  style: TextStyle(color: Color(0xFFD4714D)))),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    context.read<AppProvider>().reset();
    await context.read<AuthService>().signOut();
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}

class _TeamCard extends StatefulWidget {
  final ThemeService theme;
  final String tenantId;
  const _TeamCard({required this.theme, required this.tenantId});

  @override
  State<_TeamCard> createState() => _TeamCardState();
}

class _TeamCardState extends State<_TeamCard> {
  final _inviteCtrl = TextEditingController();
  bool _inviting = false;
  String? _error;

  @override
  void dispose() {
    _inviteCtrl.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    final email = _inviteCtrl.text.trim();
    if (email.isEmpty) return;
    setState(() {
      _inviting = true;
      _error = null;
    });
    try {
      await context
          .read<AuthService>()
          .inviteStaff(widget.tenantId, email);
      _inviteCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                '$email can now sign up to join — send them the app link.')));
      }
    } catch (e) {
      setState(() => _error = 'Could not send invite. Try again.');
    } finally {
      if (mounted) setState(() => _inviting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return _Card(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, size: 16, color: theme.subtextColor),
              const SizedBox(width: 8),
              Text('You (Owner)',
                  style: TextStyle(color: theme.textColor, fontSize: 13)),
            ],
          ),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream:
                context.read<AuthService>().staffMembers(widget.tenantId),
            builder: (context, snapshot) {
              final members = snapshot.data ?? const [];
              if (members.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  ...members.map((m) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(Icons.person_outline,
                                size: 16, color: theme.subtextColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(m['email'] as String? ?? '',
                                  style: TextStyle(
                                      color: theme.textColor, fontSize: 13)),
                            ),
                            IconButton(
                              icon: Icon(Icons.close,
                                  size: 16, color: theme.subtextColor),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Remove',
                              onPressed: () => context
                                  .read<AuthService>()
                                  .removeStaffMember(
                                      widget.tenantId, m['uid'] as String),
                            ),
                          ],
                        ),
                      )),
                ],
              );
            },
          ),
          Divider(color: theme.borderColor, height: 24),
          Text('Invite a staff member',
              style: TextStyle(
                  color: theme.textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('They\'ll sign up with this email to join your business.',
              style: TextStyle(color: theme.subtextColor, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inviteCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: theme.textColor, fontSize: 13),
                  decoration: const InputDecoration(
                      labelText: 'Email', isDense: true),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white),
                onPressed: _inviting ? null : _invite,
                child: Text(_inviting ? 'Sending…' : 'Invite'),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(_error!,
                style: const TextStyle(
                    color: Color(0xFFD4714D), fontSize: 12)),
          ],
        ],
      ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Products & Services',
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
                  const SizedBox(height: 12),
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
  final List<TextInputFormatter>? inputFormatters;

  const _LabeledField({
    required this.label,
    required this.ctrl,
    required this.hint,
    required this.keyboard,
    required this.theme,
    required this.onChanged,
    this.inputFormatters,
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
            inputFormatters: inputFormatters,
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

class _ReportsCard extends StatefulWidget {
  final ThemeService theme;
  final AppProvider app;
  const _ReportsCard({required this.theme, required this.app});

  @override
  State<_ReportsCard> createState() => _ReportsCardState();
}

class _ReportsCardState extends State<_ReportsCard> {
  late DateTime _start;
  late DateTime _end;
  bool _exporting = false;

  static final _dateFmt = DateFormat('MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _start = DateTime(now.year, now.month, 1);
    _end = DateTime(now.year, now.month + 1, 0);
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _start : _end,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = DateTime(picked.year, picked.month, picked.day);
        if (_end.isBefore(_start)) _end = _start;
      } else {
        _end = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        if (_start.isAfter(_end)) _start = _end;
      }
    });
  }

  Future<void> _export(List<Invoice> invoices) async {
    setState(() => _exporting = true);
    try {
      final csv = buildPaymentsCsv(invoices);
      final bytes = Uint8List.fromList(utf8.encode(csv));
      final fileName =
          'runbook-payments-${DateFormat('yyyyMMdd').format(_start)}-${DateFormat('yyyyMMdd').format(_end)}.csv';
      await FilePicker.saveFile(
        dialogTitle: 'Save payments report',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: bytes,
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final endOfDay = DateTime(_end.year, _end.month, _end.day, 23, 59, 59);
    final invoices = widget.app.paidInvoicesBetween(_start, endOfDay);
    final total = invoices.fold<double>(0, (sum, i) => sum + i.totalAmount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reports',
            style: TextStyle(
                color: widget.theme.textColor,
                fontSize: 14,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text('View and export payment reports',
            style: TextStyle(
                color: widget.theme.subtextColor, fontSize: 12)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _pickDate(isStart: true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: widget.theme.formBgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: widget.theme.inputBorderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('From',
                          style: TextStyle(
                              color: widget.theme.subtextColor, fontSize: 11)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(_dateFmt.format(_start),
                                style: TextStyle(
                                    color: widget.theme.textColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                          ),
                          Icon(Icons.calendar_today,
                              size: 14, color: widget.theme.subtextColor),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => _pickDate(isStart: false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: widget.theme.formBgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: widget.theme.inputBorderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('To',
                          style: TextStyle(
                              color: widget.theme.subtextColor, fontSize: 11)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(_dateFmt.format(_end),
                                style: TextStyle(
                                    color: widget.theme.textColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                          ),
                          Icon(Icons.calendar_today,
                              size: 14, color: widget.theme.subtextColor),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.theme.cardBgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: widget.theme.borderColor),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      '${invoices.length} payment${invoices.length == 1 ? '' : 's'}',
                      style: TextStyle(
                          color: widget.theme.textColor,
                          fontWeight: FontWeight.w600)),
                  Text('\$${total.toStringAsFixed(2)} total',
                      style: TextStyle(
                          color: widget.theme.primaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: widget.theme.primaryColor,
                    foregroundColor: Colors.white),
                icon: _exporting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.download, size: 16),
                label: const Text('Export CSV'),
                onPressed: invoices.isEmpty || _exporting
                    ? null
                    : () => _export(invoices),
              ),
            ],
          ),
        ),
        if (invoices.isNotEmpty)
          ...[
            const SizedBox(height: 12),
            ...invoices.map((inv) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: widget.theme.cardBgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: widget.theme.borderColor),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(inv.customerName,
                                style: TextStyle(
                                    color: widget.theme.textColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            Text(
                                '${inv.invoiceNumber} · ${inv.paymentMethod} · ${_dateFmt.format(inv.paidAt!)}',
                                style: TextStyle(
                                    color: widget.theme.subtextColor,
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                      Text(inv.amountDisplay,
                          style: TextStyle(
                              color: widget.theme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                    ],
                  ),
                )),
          ]
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('No paid invoices in this range',
                  style: TextStyle(color: widget.theme.subtextColor)),
            ),
          ),
      ],
    );
  }
}

class ReportsSheet extends StatefulWidget {
  const ReportsSheet({super.key});

  @override
  State<ReportsSheet> createState() => _ReportsSheetState();
}

class _ReportsSheetState extends State<ReportsSheet> {
  late DateTime _start;
  late DateTime _end;
  bool _exporting = false;

  static final _dateFmt = DateFormat('MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _start = DateTime(now.year, now.month, 1);
    _end = DateTime(now.year, now.month + 1, 0);
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _start : _end,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = DateTime(picked.year, picked.month, picked.day);
        if (_end.isBefore(_start)) _end = _start;
      } else {
        _end = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        if (_start.isAfter(_end)) _start = _end;
      }
    });
  }

  Future<void> _export(List<Invoice> invoices) async {
    setState(() => _exporting = true);
    try {
      final csv = buildPaymentsCsv(invoices);
      final bytes = Uint8List.fromList(utf8.encode(csv));
      final fileName =
          'runbook-payments-${DateFormat('yyyyMMdd').format(_start)}-${DateFormat('yyyyMMdd').format(_end)}.csv';
      await FilePicker.saveFile(
        dialogTitle: 'Save payments report',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: bytes,
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = context.watch<ThemeService>();
    final endOfDay = DateTime(_end.year, _end.month, _end.day, 23, 59, 59);
    final invoices = app.paidInvoicesBetween(_start, endOfDay);
    final total = invoices.fold<double>(0, (sum, i) => sum + i.totalAmount);

    return Scaffold(
      backgroundColor: theme.scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Payment Reports',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Payments',
              style: TextStyle(
                  color: theme.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Paid invoices in the selected date range, ready to export for QuickBooks or your bookkeeper.',
              style: TextStyle(color: theme.subtextColor, fontSize: 12)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardBgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.borderColor),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Start Date',
                              style: TextStyle(
                                  color: theme.textColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(_dateFmt.format(_start),
                              style: TextStyle(
                                  color: theme.subtextColor, fontSize: 13)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _pickDate(isStart: true),
                      child: Text('Change',
                          style: TextStyle(color: theme.primaryColor)),
                    ),
                  ],
                ),
                Divider(color: theme.borderColor, height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('End Date',
                              style: TextStyle(
                                  color: theme.textColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(_dateFmt.format(_end),
                              style: TextStyle(
                                  color: theme.subtextColor, fontSize: 13)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _pickDate(isStart: false),
                      child: Text('Change',
                          style: TextStyle(color: theme.primaryColor)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardBgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Revenue',
                              style: TextStyle(
                                  color: theme.textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold)),
                          Text('${invoices.length} invoices',
                              style: TextStyle(
                                  color: theme.subtextColor, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text('\$${total.toStringAsFixed(2)}',
                        style: TextStyle(
                            color: theme.primaryColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                if (invoices.isNotEmpty) ...[
                  Divider(color: theme.borderColor, height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.download),
                      label: Text(_exporting ? 'Exporting...' : 'Export as CSV'),
                      onPressed: _exporting ? null : () => _export(invoices),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ReportsBottomSheet extends StatefulWidget {
  final ThemeService theme;
  const _ReportsBottomSheet({required this.theme});

  @override
  State<_ReportsBottomSheet> createState() => _ReportsBottomSheetState();
}

class _ReportsBottomSheetState extends State<_ReportsBottomSheet> {
  late DateTime _start;
  late DateTime _end;
  bool _exporting = false;

  static final _dateFmt = DateFormat('MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _start = DateTime(now.year, now.month, 1);
    _end = DateTime(now.year, now.month + 1, 0);
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _start : _end,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = DateTime(picked.year, picked.month, picked.day);
        if (_end.isBefore(_start)) _end = _start;
      } else {
        _end = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        if (_start.isAfter(_end)) _start = _end;
      }
    });
  }

  Future<void> _export(List<Invoice> invoices) async {
    setState(() => _exporting = true);
    try {
      final csv = buildPaymentsCsv(invoices);
      final bytes = Uint8List.fromList(utf8.encode(csv));
      final fileName =
          'runbook-payments-${DateFormat('yyyyMMdd').format(_start)}-${DateFormat('yyyyMMdd').format(_end)}.csv';
      await FilePicker.saveFile(
        dialogTitle: 'Save payments report',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: bytes,
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final endOfDay = DateTime(_end.year, _end.month, _end.day, 23, 59, 59);
    final invoices = app.paidInvoicesBetween(_start, endOfDay);
    final total = invoices.fold<double>(0, (sum, i) => sum + i.totalAmount);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: widget.theme.scaffoldBgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: widget.theme.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Payment Reports',
                        style: TextStyle(
                            color: widget.theme.textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Done',
                        style: TextStyle(
                            color: widget.theme.primaryColor,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Divider(color: widget.theme.borderColor, height: 1),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _pickDate(isStart: true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: widget.theme.formBgColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: widget.theme.inputBorderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('From',
                                    style: TextStyle(
                                        color: widget.theme.subtextColor, fontSize: 11)),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(_dateFmt.format(_start),
                                          style: TextStyle(
                                              color: widget.theme.textColor,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500)),
                                    ),
                                    Icon(Icons.calendar_today,
                                        size: 14, color: widget.theme.subtextColor),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _pickDate(isStart: false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: widget.theme.formBgColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: widget.theme.inputBorderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('To',
                                    style: TextStyle(
                                        color: widget.theme.subtextColor, fontSize: 11)),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(_dateFmt.format(_end),
                                          style: TextStyle(
                                              color: widget.theme.textColor,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500)),
                                    ),
                                    Icon(Icons.calendar_today,
                                        size: 14, color: widget.theme.subtextColor),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: widget.theme.cardBgColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: widget.theme.borderColor),
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${invoices.length} payment${invoices.length == 1 ? '' : 's'}',
                                style: TextStyle(
                                    color: widget.theme.textColor,
                                    fontWeight: FontWeight.w600)),
                            Text('\$${total.toStringAsFixed(2)} total',
                                style: TextStyle(
                                    color: widget.theme.primaryColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: widget.theme.primaryColor,
                              foregroundColor: Colors.white),
                          icon: _exporting
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.download, size: 16),
                          label: const Text('Export CSV'),
                          onPressed: invoices.isEmpty || _exporting
                              ? null
                              : () => _export(invoices),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (invoices.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text('No paid invoices in this range',
                            style: TextStyle(color: widget.theme.subtextColor)),
                      ),
                    )
                  else
                    ...invoices.map((inv) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: widget.theme.cardBgColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: widget.theme.borderColor),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(inv.customerName,
                                        style: TextStyle(
                                            color: widget.theme.textColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13)),
                                    Text(
                                        '${inv.invoiceNumber} · ${inv.paymentMethod} · ${_dateFmt.format(inv.paidAt!)}',
                                        style: TextStyle(
                                            color: widget.theme.subtextColor,
                                            fontSize: 11)),
                                  ],
                                ),
                              ),
                              Text(inv.amountDisplay,
                                  style: TextStyle(
                                      color: widget.theme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                            ],
                          ),
                        )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BusinessInfoBottomSheet extends StatefulWidget {
  final ThemeService theme;
  final TextEditingController nameCtrl;
  final TextEditingController addrCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController taxCtrl;
  final VoidCallback onSave;

  const _BusinessInfoBottomSheet({
    required this.theme,
    required this.nameCtrl,
    required this.addrCtrl,
    required this.phoneCtrl,
    required this.emailCtrl,
    required this.taxCtrl,
    required this.onSave,
  });

  @override
  State<_BusinessInfoBottomSheet> createState() => _BusinessInfoBottomSheetState();
}

class _BusinessInfoBottomSheetState extends State<_BusinessInfoBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: widget.theme.scaffoldBgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: widget.theme.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Business Info',
                        style: TextStyle(
                            color: widget.theme.textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Done',
                        style: TextStyle(
                            color: widget.theme.primaryColor,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Divider(color: widget.theme.borderColor, height: 1),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Business Details',
                      style: TextStyle(
                          color: widget.theme.textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: widget.nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Business Name',
                      hintText: 'Your business name',
                      hintStyle: TextStyle(color: widget.theme.subtextColor),
                      isDense: true,
                    ),
                    style: TextStyle(color: widget.theme.textColor, fontSize: 15),
                    onChanged: (_) => widget.onSave(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: widget.addrCtrl,
                    decoration: InputDecoration(
                      labelText: 'Address',
                      hintText: '123 Main St',
                      hintStyle: TextStyle(color: widget.theme.subtextColor),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.streetAddress,
                    style: TextStyle(color: widget.theme.textColor, fontSize: 13),
                    onChanged: (_) => widget.onSave(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: widget.phoneCtrl,
                    decoration: InputDecoration(
                      labelText: 'Phone',
                      hintText: '(555) 123-4567',
                      hintStyle: TextStyle(color: widget.theme.subtextColor),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [USPhoneInputFormatter()],
                    style: TextStyle(color: widget.theme.textColor, fontSize: 13),
                    onChanged: (_) => widget.onSave(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: widget.emailCtrl,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'hello@yourbusiness.com',
                      hintStyle: TextStyle(color: widget.theme.subtextColor),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    inputFormatters: [LowercaseEmailFormatter()],
                    style: TextStyle(color: widget.theme.textColor, fontSize: 13),
                    onChanged: (_) => widget.onSave(),
                  ),
                  const SizedBox(height: 20),
                  Text('Tax Settings',
                      style: TextStyle(
                          color: widget.theme.textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Default Tax Rate',
                                style: TextStyle(
                                    color: widget.theme.textColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            Text('Applied automatically to new invoices',
                                style: TextStyle(
                                    color: widget.theme.subtextColor, fontSize: 11)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: widget.taxCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          decoration: InputDecoration(
                            suffixText: '%',
                            hintText: '0',
                            hintStyle: TextStyle(color: widget.theme.subtextColor),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          style: TextStyle(
                              color: widget.theme.primaryColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w600),
                          onChanged: (_) => widget.onSave(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamBottomSheet extends StatefulWidget {
  final ThemeService theme;
  final String tenantId;

  const _TeamBottomSheet({
    required this.theme,
    required this.tenantId,
  });

  @override
  State<_TeamBottomSheet> createState() => _TeamBottomSheetState();
}

class _TeamBottomSheetState extends State<_TeamBottomSheet> {
  final _inviteCtrl = TextEditingController();
  bool _inviting = false;
  String? _error;

  @override
  void dispose() {
    _inviteCtrl.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    final email = _inviteCtrl.text.trim();
    if (email.isEmpty) return;
    setState(() {
      _inviting = true;
      _error = null;
    });
    try {
      await context
          .read<AuthService>()
          .inviteStaff(widget.tenantId, email);
      _inviteCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                '$email can now sign up to join — send them the app link.')));
      }
    } catch (e) {
      setState(() => _error = 'Could not send invite. Try again.');
    } finally {
      if (mounted) setState(() => _inviting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: widget.theme.scaffoldBgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: widget.theme.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Team',
                        style: TextStyle(
                            color: widget.theme.textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Done',
                        style: TextStyle(
                            color: widget.theme.primaryColor,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Divider(color: widget.theme.borderColor, height: 1),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: widget.theme.subtextColor),
                      const SizedBox(width: 8),
                      Text('You (Owner)',
                          style: TextStyle(color: widget.theme.textColor, fontSize: 13)),
                    ],
                  ),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream:
                        context.read<AuthService>().staffMembers(widget.tenantId),
                    builder: (context, snapshot) {
                      final members = snapshot.data ?? const [];
                      if (members.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          ...members.map((m) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    Icon(Icons.person_outline,
                                        size: 16, color: widget.theme.subtextColor),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(m['email'] as String? ?? '',
                                          style: TextStyle(
                                              color: widget.theme.textColor, fontSize: 13)),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.close,
                                          size: 16, color: widget.theme.subtextColor),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      tooltip: 'Remove',
                                      onPressed: () => context
                                          .read<AuthService>()
                                          .removeStaffMember(
                                              widget.tenantId, m['uid'] as String),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Text('Invite a staff member',
                      style: TextStyle(
                          color: widget.theme.textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('They\'ll sign up with this email to join your business.',
                      style: TextStyle(color: widget.theme.subtextColor, fontSize: 12)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _inviteCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: widget.theme.textColor, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'staff@example.com',
                      hintStyle: TextStyle(color: widget.theme.subtextColor),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: widget.theme.primaryColor,
                          foregroundColor: Colors.white),
                      onPressed: _inviting ? null : _invite,
                      child: Text(_inviting ? 'Sending…' : 'Invite'),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: const TextStyle(
                            color: Color(0xFFD4714D), fontSize: 12)),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
