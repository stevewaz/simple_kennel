import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/tenant_settings_service.dart';
import '../services/theme_service.dart';
import '../providers/app_provider.dart';
import '../models/service.dart';
import 'package:flutter/services.dart';
import '../services/runs_service.dart';
import '../utils/input_formatters.dart';
import '../utils/tenant_providers.dart';
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
                  Text('Business Info',
                      style: TextStyle(
                          color: theme.textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
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
                  _LabeledField(label: 'Phone', ctrl: _phoneCtrl, hint: '(555) 123-4567', keyboard: TextInputType.phone, theme: theme, onChanged: (_) => _save(), inputFormatters: [USPhoneInputFormatter()]),
                  Divider(color: theme.borderColor, height: 12),
                  _LabeledField(label: 'Email', ctrl: _emailCtrl, hint: 'hello@yourbusiness.com', keyboard: TextInputType.emailAddress, theme: theme, onChanged: (_) => _save(), inputFormatters: [LowercaseEmailFormatter()]),
                  Divider(color: theme.borderColor, height: 24),
                  Text('Taxes',
                      style: TextStyle(
                          color: theme.textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Nightly Rate',
                                style: TextStyle(
                                    color: theme.textColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold)),
                            Text('Pre-filled on auto-generated invoices',
                                style: TextStyle(
                                    color: theme.subtextColor, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text('\$',
                          style: TextStyle(
                              color: theme.primaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: _nightlyRateCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.right,
                          decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: '0.00',
                              contentPadding: EdgeInsets.zero),
                          style: TextStyle(
                              color: theme.primaryColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                          onChanged: (_) => _save(),
                        ),
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
                  _TeamCard(theme: theme, tenantId: settings.tenantId),
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
