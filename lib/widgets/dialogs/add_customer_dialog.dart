import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/customer.dart';
import '../../models/pet.dart';
import '../../services/theme_service.dart';
import '../../utils/input_formatters.dart';

class AddCustomerDialog extends StatefulWidget {
  final Customer? existing;
  final List<Pet> initialPets;
  final Future<void> Function(Customer, List<Pet> toSave, List<Pet> toDelete) onSave;
  final ThemeService theme;

  const AddCustomerDialog({
    super.key,
    this.existing,
    this.initialPets = const [],
    required this.onSave,
    required this.theme,
  });

  @override
  State<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<AddCustomerDialog> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  bool _saving = false;

  late List<Pet> _pets;
  final List<Pet> _deletedPets = [];
  bool _addingPet = false;
  final _petNameCtrl = TextEditingController();
  final _petBreedCtrl = TextEditingController();
  final _petAgeCtrl = TextEditingController();
  final _petNotesCtrl = TextEditingController();
  String _petSpecies = 'Dog';

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameCtrl.text = widget.existing!.name;
      _emailCtrl.text = widget.existing!.email.toLowerCase();
      _phoneCtrl.text = formatUSPhone(widget.existing!.phoneNumber);
      _addrCtrl.text = widget.existing!.address;
    }
    _pets = List.from(widget.initialPets);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addrCtrl.dispose();
    _petNameCtrl.dispose();
    _petBreedCtrl.dispose();
    _petAgeCtrl.dispose();
    _petNotesCtrl.dispose();
    super.dispose();
  }

  void _addPet() {
    if (_petNameCtrl.text.trim().isEmpty) return;
    setState(() {
      _pets.add(Pet(
        customerId: widget.existing?.id ?? '',
        name: _petNameCtrl.text.trim(),
        species: _petSpecies,
        breed: _petBreedCtrl.text.trim(),
        age: int.tryParse(_petAgeCtrl.text.trim()) ?? 0,
        notes: _petNotesCtrl.text.trim(),
      ));
      _petNameCtrl.clear();
      _petBreedCtrl.clear();
      _petAgeCtrl.clear();
      _petNotesCtrl.clear();
      _petSpecies = 'Dog';
      _addingPet = false;
    });
  }

  void _removePet(Pet p) {
    setState(() {
      _pets.remove(p);
      if (widget.initialPets.any((ip) => ip.id == p.id)) {
        _deletedPets.add(p);
      }
    });
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final customer = Customer(
      id: widget.existing?.id,
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim(),
      address: _addrCtrl.text.trim(),
      createdAt: widget.existing?.createdAt,
    );
    final petsToSave = _pets.map((p) => p.customerId.isEmpty
        ? Pet(
            id: p.id,
            customerId: customer.id,
            name: p.name,
            species: p.species,
            breed: p.breed,
            age: p.age,
            notes: p.notes,
          )
        : p).toList();
    await widget.onSave(customer, petsToSave, _deletedPets);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isEdit = widget.existing != null;

    return AlertDialog(
      backgroundColor: theme.cardBgColor,
      title: Text(isEdit ? 'Edit Customer' : 'New Customer',
          style: TextStyle(color: theme.textColor)),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Field(label: 'Name *', ctrl: _nameCtrl, theme: theme),
              const SizedBox(height: 10),
              _Field(
                  label: 'Email',
                  ctrl: _emailCtrl,
                  theme: theme,
                  keyboard: TextInputType.emailAddress,
                  inputFormatters: [LowercaseEmailFormatter()]),
              const SizedBox(height: 10),
              _Field(
                  label: 'Phone',
                  ctrl: _phoneCtrl,
                  theme: theme,
                  keyboard: TextInputType.phone,
                  inputFormatters: [USPhoneInputFormatter()]),
              const SizedBox(height: 10),
              _Field(
                  label: 'Address',
                  ctrl: _addrCtrl,
                  theme: theme,
                  keyboard: TextInputType.streetAddress),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text('Pets',
                      style: TextStyle(
                          color: theme.textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  const Spacer(),
                  if (!_addingPet)
                    TextButton.icon(
                      onPressed: () => setState(() => _addingPet = true),
                      icon: Icon(Icons.add, size: 16, color: theme.primaryColor),
                      label: Text('Add Pet',
                          style: TextStyle(
                              color: theme.primaryColor, fontSize: 13)),
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    ),
                ],
              ),
              if (_pets.isEmpty && !_addingPet)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('No pets added yet',
                      style: TextStyle(
                          color: theme.subtextColor, fontSize: 13)),
                ),
              ..._pets.map((p) =>
                  _PetRow(pet: p, theme: theme, onRemove: () => _removePet(p))),
              if (_addingPet) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Field(
                          label: 'Pet Name *',
                          ctrl: _petNameCtrl,
                          theme: theme),
                      const SizedBox(height: 8),
                      InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Species',
                          labelStyle: TextStyle(color: theme.subtextColor),
                        ),
                        child: DropdownButton<String>(
                          value: _petSpecies,
                          dropdownColor: theme.cardBgColor,
                          underline: const SizedBox.shrink(),
                          isExpanded: true,
                          style: TextStyle(color: theme.textColor),
                          items: ['Dog', 'Cat', 'Other']
                              .map((s) => DropdownMenuItem(
                                  value: s, child: Text(s)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _petSpecies = v ?? 'Dog'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _Field(
                          label: 'Breed',
                          ctrl: _petBreedCtrl,
                          theme: theme),
                      const SizedBox(height: 8),
                      _Field(
                          label: 'Age',
                          ctrl: _petAgeCtrl,
                          theme: theme,
                          keyboard: TextInputType.number),
                      const SizedBox(height: 8),
                      _Field(
                          label: 'Notes',
                          ctrl: _petNotesCtrl,
                          theme: theme),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => setState(() {
                              _addingPet = false;
                              _petNameCtrl.clear();
                              _petBreedCtrl.clear();
                              _petAgeCtrl.clear();
                              _petNotesCtrl.clear();
                              _petSpecies = 'Dog';
                            }),
                            child: Text('Cancel',
                                style:
                                    TextStyle(color: theme.subtextColor)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primaryColor,
                                foregroundColor: Colors.white),
                            onPressed: _addPet,
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Cancel', style: TextStyle(color: theme.subtextColor))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white),
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : (isEdit ? 'Update' : 'Add Customer')),
        ),
      ],
    );
  }
}

class _PetRow extends StatelessWidget {
  final Pet pet;
  final ThemeService theme;
  final VoidCallback onRemove;
  const _PetRow(
      {required this.pet, required this.theme, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.scaffoldBgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.pets, size: 16, color: theme.subtextColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pet.name,
                    style: TextStyle(
                        color: theme.textColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 13)),
                Text(
                    pet.breed.isEmpty
                        ? pet.species
                        : '${pet.species} · ${pet.breed}',
                    style: TextStyle(
                        color: theme.subtextColor, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 16, color: theme.subtextColor),
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final ThemeService theme;
  final TextInputType keyboard;
  final List<TextInputFormatter>? inputFormatters;

  const _Field({
    required this.label,
    required this.ctrl,
    required this.theme,
    this.keyboard = TextInputType.text,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: theme.subtextColor)),
      style: TextStyle(color: theme.textColor),
    );
  }
}
