import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/customer.dart';
import '../../models/pet.dart';
import '../../services/theme_service.dart';
import '../../services/prefs_service.dart';
import '../../utils/input_formatters.dart';

String _genId() {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final rng = Random();
  return List.generate(15, (_) => chars[rng.nextInt(chars.length)]).join();
}

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

  // Pet form state
  bool _showPetForm = false;
  int? _editingIndex;
  String _formPetId = '';
  final _petNameCtrl = TextEditingController();
  final _petBreedCtrl = TextEditingController();
  final _petAgeCtrl = TextEditingController();
  final _petNotesCtrl = TextEditingController();
  String _petSpecies = 'Dog';
  List<String> _formPhotos = [];

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

  void _openAddPet() {
    setState(() {
      _showPetForm = true;
      _editingIndex = null;
      _formPetId = _genId();
      _petNameCtrl.clear();
      _petBreedCtrl.clear();
      _petAgeCtrl.clear();
      _petNotesCtrl.clear();
      _petSpecies = 'Dog';
      _formPhotos = [];
    });
  }

  void _openEditPet(int index) {
    final p = _pets[index];
    setState(() {
      _showPetForm = true;
      _editingIndex = index;
      _formPetId = p.id;
      _petNameCtrl.text = p.name;
      _petBreedCtrl.text = p.breed;
      _petAgeCtrl.text = p.age > 0 ? p.age.toString() : '';
      _petNotesCtrl.text = p.notes;
      _petSpecies = p.species;
      _formPhotos = List.from(PrefsService.getPetPhotos(p.id));
    });
  }

  void _closePetForm() {
    setState(() {
      _showPetForm = false;
      _editingIndex = null;
      _formPetId = '';
      _formPhotos = [];
      _petNameCtrl.clear();
      _petBreedCtrl.clear();
      _petAgeCtrl.clear();
      _petNotesCtrl.clear();
      _petSpecies = 'Dog';
    });
  }

  void _savePetForm() {
    if (_petNameCtrl.text.trim().isEmpty) return;
    PrefsService.setPetPhotos(_formPetId, _formPhotos);
    final pet = Pet(
      id: _formPetId,
      customerId: widget.existing?.id ?? '',
      name: _petNameCtrl.text.trim(),
      species: _petSpecies,
      breed: _petBreedCtrl.text.trim(),
      age: int.tryParse(_petAgeCtrl.text.trim()) ?? 0,
      notes: _petNotesCtrl.text.trim(),
    );
    setState(() {
      if (_editingIndex != null) {
        _pets[_editingIndex!] = pet;
      } else {
        _pets.add(pet);
      }
      _showPetForm = false;
      _editingIndex = null;
      _formPetId = '';
      _formPhotos = [];
      _petNameCtrl.clear();
      _petBreedCtrl.clear();
      _petAgeCtrl.clear();
      _petNotesCtrl.clear();
      _petSpecies = 'Dog';
    });
  }

  void _removePet(Pet p) {
    setState(() {
      _pets.remove(p);
      if (widget.initialPets.any((ip) => ip.id == p.id)) {
        _deletedPets.add(p);
      }
    });
    final photos = PrefsService.getPetPhotos(p.id);
    for (final path in photos) {
      try { File(path).delete(); } catch (_) {}
    }
    PrefsService.removePetPhotos(p.id);
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${docsDir.path}/pet_photos/$_formPetId');
    await dir.create(recursive: true);
    final dest =
        '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(image.path).copy(dest);
    setState(() => _formPhotos.add(dest));
  }

  void _removePhoto(int index) {
    final path = _formPhotos[index];
    try { File(path).delete(); } catch (_) {}
    setState(() => _formPhotos.removeAt(index));
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
        width: 420,
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

              // Pets header
              Row(
                children: [
                  Text('Pets',
                      style: TextStyle(
                          color: theme.textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  const Spacer(),
                  if (!_showPetForm)
                    TextButton.icon(
                      onPressed: _openAddPet,
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

              if (_pets.isEmpty && !_showPetForm)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('No pets added yet',
                      style: TextStyle(
                          color: theme.subtextColor, fontSize: 13)),
                ),

              ..._pets.asMap().entries.map((e) => _PetRow(
                    pet: e.value,
                    photoCount: PrefsService.getPetPhotos(e.value.id).length,
                    theme: theme,
                    onEdit: () => _openEditPet(e.key),
                    onRemove: () => _removePet(e.value),
                  )),

              // Pet form (add or edit)
              if (_showPetForm) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.primaryColor.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _editingIndex != null ? 'Edit Pet' : 'New Pet',
                        style: TextStyle(
                            color: theme.textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      _Field(label: 'Pet Name *', ctrl: _petNameCtrl, theme: theme),
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
                              .map((s) =>
                                  DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _petSpecies = v ?? 'Dog'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _Field(label: 'Breed', ctrl: _petBreedCtrl, theme: theme),
                      const SizedBox(height: 8),
                      _Field(
                          label: 'Age',
                          ctrl: _petAgeCtrl,
                          theme: theme,
                          keyboard: TextInputType.number),
                      const SizedBox(height: 8),
                      _Field(label: 'Notes', ctrl: _petNotesCtrl, theme: theme),

                      // Photos (native only)
                      if (!kIsWeb) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.photo_library,
                                size: 14, color: theme.subtextColor),
                            const SizedBox(width: 6),
                            Text('Paperwork Photos',
                                style: TextStyle(
                                    color: theme.subtextColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500)),
                            const Spacer(),
                            GestureDetector(
                              onTap: _pickPhoto,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.add_a_photo,
                                        size: 12, color: Colors.white),
                                    const SizedBox(width: 4),
                                    const Text('Add',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 11)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_formPhotos.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 80,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _formPhotos.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 6),
                              itemBuilder: (_, i) => Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.file(
                                      File(_formPhotos[i]),
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Container(
                                        width: 80,
                                        height: 80,
                                        color: theme.borderColor,
                                        child: Icon(Icons.broken_image,
                                            color: theme.subtextColor),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: GestureDetector(
                                      onTap: () => _removePhoto(i),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        padding: const EdgeInsets.all(2),
                                        child: const Icon(Icons.close,
                                            size: 12, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],

                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _closePetForm,
                            child: Text('Cancel',
                                style:
                                    TextStyle(color: theme.subtextColor)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primaryColor,
                                foregroundColor: Colors.white),
                            onPressed: _savePetForm,
                            child: Text(_editingIndex != null
                                ? 'Save Changes'
                                : 'Add Pet'),
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
          child: Text(
              _saving ? 'Saving…' : (isEdit ? 'Update' : 'Add Customer')),
        ),
      ],
    );
  }
}

class _PetRow extends StatelessWidget {
  final Pet pet;
  final int photoCount;
  final ThemeService theme;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  const _PetRow({
    required this.pet,
    required this.photoCount,
    required this.theme,
    required this.onEdit,
    required this.onRemove,
  });

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
          if (photoCount > 0) ...[
            Icon(Icons.photo_library, size: 14, color: theme.subtextColor),
            const SizedBox(width: 2),
            Text('$photoCount',
                style: TextStyle(color: theme.subtextColor, fontSize: 11)),
            const SizedBox(width: 6),
          ],
          IconButton(
            icon: Icon(Icons.edit, size: 16, color: theme.primaryColor),
            onPressed: onEdit,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Edit pet',
          ),
          const SizedBox(width: 4),
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
