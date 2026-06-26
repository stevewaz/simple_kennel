import 'package:flutter/material.dart';
import '../../models/service.dart';
import '../../services/theme_service.dart';

class AddServiceDialog extends StatefulWidget {
  final Service? existing;
  final Future<void> Function(Service) onSave;
  final ThemeService theme;

  const AddServiceDialog({
    super.key,
    this.existing,
    required this.onSave,
    required this.theme,
  });

  @override
  State<AddServiceDialog> createState() => _AddServiceDialogState();
}

class _AddServiceDialogState extends State<AddServiceDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  bool _isActive = true;
  bool _saving = false;

  static const _unitOptions = [
    'flat fee', 'per night', 'per day', 'per hour', 'per visit'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameCtrl.text = widget.existing!.name;
      _descCtrl.text = widget.existing!.description;
      _priceCtrl.text = widget.existing!.defaultPrice.toStringAsFixed(2);
      _unitCtrl.text = widget.existing!.unit;
      _isActive = widget.existing!.isActive;
    } else {
      _unitCtrl.text = 'flat fee';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final service = Service(
      id: widget.existing?.id,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      defaultPrice: double.tryParse(_priceCtrl.text) ?? 0,
      unit: _unitCtrl.text.trim(),
      isActive: _isActive,
    );
    await widget.onSave(service);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isEdit = widget.existing != null;

    return AlertDialog(
      backgroundColor: theme.cardBgColor,
      title: Text(isEdit ? 'Edit Service' : 'New Service',
          style: TextStyle(color: theme.textColor)),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                  labelText: 'Name *',
                  labelStyle: TextStyle(color: theme.subtextColor)),
              style: TextStyle(color: theme.textColor),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descCtrl,
              decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: theme.subtextColor)),
              style: TextStyle(color: theme.textColor),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                        labelText: 'Price (\$)',
                        prefixText: '\$',
                        labelStyle: TextStyle(color: theme.subtextColor)),
                    style: TextStyle(color: theme.textColor),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _unitOptions.contains(_unitCtrl.text)
                        ? _unitCtrl.text
                        : _unitOptions.first,
                    decoration: InputDecoration(
                        labelText: 'Unit',
                        labelStyle: TextStyle(color: theme.subtextColor)),
                    dropdownColor: theme.cardBgColor,
                    style: TextStyle(color: theme.textColor),
                    items: _unitOptions
                        .map((u) =>
                            DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) => _unitCtrl.text = v ?? 'flat fee',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Active',
                    style: TextStyle(color: theme.textColor, fontSize: 14)),
                const Spacer(),
                Switch(
                  value: _isActive,
                  activeThumbColor: theme.primaryColor,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: theme.subtextColor))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white),
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : (isEdit ? 'Update' : 'Add Service')),
        ),
      ],
    );
  }
}
