import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/breeds.dart';
import '../../data/us_states.dart';
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
  final _cityCtrl = TextEditingController();
  final _zipCtrl = TextEditingController();
  String? _state;
  bool _saving = false;

  late List<Pet> _pets;
  final List<Pet> _deletedPets = [];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameCtrl.text = widget.existing!.name;
      _emailCtrl.text = widget.existing!.email.toLowerCase();
      _phoneCtrl.text = formatUSPhone(widget.existing!.phoneNumber);
      _addrCtrl.text = widget.existing!.address;
      _cityCtrl.text = widget.existing!.city;
      _state = widget.existing!.state.isEmpty ? null : widget.existing!.state;
      _zipCtrl.text = widget.existing!.zip;
    }
    _pets = List.from(widget.initialPets);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addrCtrl.dispose();
    _cityCtrl.dispose();
    _zipCtrl.dispose();
    super.dispose();
  }

  Future<void> _showAddPetDialog() async {
    final pet = await showDialog<Pet>(
      context: context,
      builder: (_) => _PetFormDialog(theme: widget.theme),
    );
    if (pet != null) setState(() => _pets.add(pet));
  }

  Future<void> _showEditPetDialog(int index) async {
    final existing = _pets[index];
    final photos = PrefsService.getPetPhotos(existing.id);
    final pet = await showDialog<Pet>(
      context: context,
      builder: (_) => _PetFormDialog(
        existing: existing,
        existingPhotos: photos,
        theme: widget.theme,
      ),
    );
    if (pet != null) setState(() => _pets[index] = pet);
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

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final customer = Customer(
      id: widget.existing?.id ?? '',
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim(),
      address: _addrCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      state: _state ?? '',
      zip: _zipCtrl.text.trim(),
      createdAt: widget.existing?.createdAt ?? DateTime.now().toUtc(),
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
            createdAt: p.createdAt,
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
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _Field(label: 'City', ctrl: _cityCtrl, theme: theme),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 92,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'State',
                        labelStyle: TextStyle(color: theme.subtextColor),
                        contentPadding:
                            const EdgeInsets.only(bottom: 4, top: 4),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: usStateAbbreviations.contains(_state)
                              ? _state
                              : null,
                          hint: Text('--',
                              style: TextStyle(color: theme.subtextColor)),
                          dropdownColor: theme.cardBgColor,
                          isExpanded: true,
                          isDense: true,
                          style: TextStyle(color: theme.textColor),
                          items: usStateAbbreviations
                              .map((s) =>
                                  DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onChanged: (v) => setState(() => _state = v),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _Field(
                        label: 'Zip',
                        ctrl: _zipCtrl,
                        theme: theme,
                        keyboard: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(5),
                        ]),
                  ),
                ],
              ),
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
                  TextButton.icon(
                    onPressed: _showAddPetDialog,
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

              if (_pets.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('No pets added yet',
                      style:
                          TextStyle(color: theme.subtextColor, fontSize: 13)),
                ),

              ..._pets.asMap().entries.map((e) => _PetRow(
                    pet: e.value,
                    photoCount: PrefsService.getPetPhotos(e.value.id).length,
                    theme: theme,
                    onEdit: () => _showEditPetDialog(e.key),
                    onRemove: () => _removePet(e.value),
                  )),
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

// ─── Pet form dialog ──────────────────────────────────────────────────────────

class _PetFormDialog extends StatefulWidget {
  final Pet? existing;
  final List<String> existingPhotos;
  final ThemeService theme;

  const _PetFormDialog({
    this.existing,
    this.existingPhotos = const [],
    required this.theme,
  });

  @override
  State<_PetFormDialog> createState() => _PetFormDialogState();
}

class _PetFormDialogState extends State<_PetFormDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _breedCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _notesCtrl;
  final FocusNode _breedFocusNode = FocusNode();
  late final TextEditingController _sourceCtrl;
  late String _species;
  String? _gender;
  late String _petId;
  late List<String> _photos;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _petId = p?.id ?? _genId();
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _breedCtrl = TextEditingController(text: p?.breed ?? '');
    _ageCtrl = TextEditingController(
        text: p != null && p.age > 0 ? p.age.toString() : '');
    _sourceCtrl = TextEditingController(text: p?.source ?? '');
    _notesCtrl = TextEditingController(text: p?.notes ?? '');
    _species = p?.species ?? 'Dog';
    _gender = (p?.gender.isEmpty ?? true) ? null : p!.gender;
    _photos = List.from(widget.existingPhotos);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _breedCtrl.dispose();
    _ageCtrl.dispose();
    _sourceCtrl.dispose();
    _notesCtrl.dispose();
    _breedFocusNode.dispose();
    super.dispose();
  }

  static bool _isImage(String path) {
    final ext = path.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
  }

  // Compresses an image file in-place (max 1500px, JPEG quality 75).
  // Non-image files are left untouched.
  static Future<void> _compressImage(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return;
      const maxDim = 1500;
      var output = decoded;
      if (decoded.width > maxDim || decoded.height > maxDim) {
        output = decoded.width >= decoded.height
            ? img.copyResize(decoded, width: maxDim)
            : img.copyResize(decoded, height: maxDim);
      }
      await File(path).writeAsBytes(img.encodeJpg(output, quality: 75));
    } catch (_) {}
  }

  Future<void> _addAttachment() async {
    if (Platform.isIOS || Platform.isAndroid) {
      // Use context before any await to satisfy the async-gap lint rule
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Library'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
      if (source == null || !mounted) return;
      // imageQuality pre-compresses; _compressImage enforces max dimensions
      final image = await ImagePicker()
          .pickImage(source: source, imageQuality: 70);
      if (image == null || !mounted) return;
      final docsDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${docsDir.path}/pet_photos/$_petId');
      await dir.create(recursive: true);
      final dest = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(image.path).copy(dest);
      await _compressImage(dest);
      if (mounted) setState(() => _photos.add(dest));
    } else {
      // Desktop: native file system picker — any file type
      final result = await FilePicker.platform.pickFiles(allowMultiple: false);
      if (result == null || result.files.isEmpty || !mounted) return;
      final picked = result.files.first;
      if (picked.path == null) return;
      final docsDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${docsDir.path}/pet_photos/$_petId');
      await dir.create(recursive: true);
      final ext = picked.extension != null ? '.${picked.extension}' : '';
      final dest = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}$ext';
      await File(picked.path!).copy(dest);
      if (_isImage(dest)) await _compressImage(dest);
      if (mounted) setState(() => _photos.add(dest));
    }
  }

  void _removePhoto(int i) {
    final path = _photos[i];
    try { File(path).delete(); } catch (_) {}
    setState(() => _photos.removeAt(i));
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) return;
    PrefsService.setPetPhotos(_petId, _photos);
    Navigator.pop(
      context,
      Pet(
        id: _petId,
        customerId: widget.existing?.customerId ?? '',
        name: _nameCtrl.text.trim(),
        species: _species,
        breed: _breedCtrl.text.trim(),
        age: int.tryParse(_ageCtrl.text.trim()) ?? 0,
        gender: _gender ?? '',
        source: _sourceCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
        createdAt: widget.existing?.createdAt ?? DateTime.now().toUtc(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isEdit = widget.existing != null;

    return AlertDialog(
      backgroundColor: theme.cardBgColor,
      title: Text(isEdit ? 'Edit Pet' : 'Add Pet',
          style: TextStyle(color: theme.textColor)),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Field(label: 'Pet Name *', ctrl: _nameCtrl, theme: theme),
              const SizedBox(height: 8),
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Species',
                  labelStyle: TextStyle(color: theme.subtextColor),
                ),
                child: DropdownButton<String>(
                  value: _species,
                  dropdownColor: theme.cardBgColor,
                  underline: const SizedBox.shrink(),
                  isExpanded: true,
                  style: TextStyle(color: theme.textColor),
                  items: ['Dog', 'Cat', 'Other']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _species = v ?? 'Dog';
                    _breedCtrl.clear();
                  }),
                ),
              ),
              const SizedBox(height: 8),
              if (_species == 'Dog' || _species == 'Cat')
                _BreedAutocomplete(
                  controller: _breedCtrl,
                  focusNode: _breedFocusNode,
                  breeds: _species == 'Dog' ? dogBreeds : catBreeds,
                  theme: theme,
                )
              else
                _Field(label: 'Breed', ctrl: _breedCtrl, theme: theme),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Field(
                        label: 'Age',
                        ctrl: _ageCtrl,
                        theme: theme,
                        keyboard: TextInputType.number),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        labelStyle: TextStyle(color: theme.subtextColor),
                        contentPadding:
                            const EdgeInsets.only(bottom: 4, top: 4),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _gender,
                          hint: Text('--',
                              style: TextStyle(color: theme.subtextColor)),
                          dropdownColor: theme.cardBgColor,
                          isExpanded: true,
                          isDense: true,
                          style: TextStyle(color: theme.textColor),
                          items: const [
                            'Male',
                            'Female',
                            'Male (Neutered)',
                            'Female (Spayed)',
                          ]
                              .map((g) =>
                                  DropdownMenuItem(value: g, child: Text(g)))
                              .toList(),
                          onChanged: (v) => setState(() => _gender = v),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _Field(
                  label: 'Source',
                  ctrl: _sourceCtrl,
                  theme: theme),
              const SizedBox(height: 8),
              _Field(label: 'Notes', ctrl: _notesCtrl, theme: theme),

              if (!kIsWeb) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.photo_library,
                        size: 14, color: theme.subtextColor),
                    const SizedBox(width: 6),
                    Text('Paperwork',
                        style: TextStyle(
                            color: theme.subtextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                    const Spacer(),
                    GestureDetector(
                      onTap: _addAttachment,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_a_photo,
                                size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Add',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (_photos.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _photos.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (_, i) => Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: _isImage(_photos[i])
                                ? Image.file(
                                    File(_photos[i]),
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
                                  )
                                : Container(
                                    width: 80,
                                    height: 80,
                                    color: theme.primaryColor
                                        .withValues(alpha: 0.1),
                                    padding: const EdgeInsets.all(6),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.insert_drive_file,
                                            size: 28,
                                            color: theme.primaryColor),
                                        const SizedBox(height: 2),
                                        Text(
                                          _photos[i]
                                              .split('/')
                                              .last
                                              .split('.')
                                              .last
                                              .toUpperCase(),
                                          style: TextStyle(
                                              fontSize: 9,
                                              color: theme.subtextColor),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
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
                                  borderRadius: BorderRadius.circular(10),
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
          onPressed: _save,
          child: Text(isEdit ? 'Save Changes' : 'Add Pet'),
        ),
      ],
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

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

class _BreedAutocomplete extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<String> breeds;
  final ThemeService theme;

  const _BreedAutocomplete({
    required this.controller,
    required this.focusNode,
    required this.breeds,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: controller,
      focusNode: focusNode,
      optionsBuilder: (value) {
        if (value.text.isEmpty) return const Iterable.empty();
        final query = value.text.toLowerCase();
        return breeds.where((b) => b.toLowerCase().contains(query));
      },
      fieldViewBuilder: (_, ctrl, fn, onSubmit) => TextField(
        controller: ctrl,
        focusNode: fn,
        onEditingComplete: onSubmit,
        decoration: InputDecoration(
          labelText: 'Breed',
          labelStyle: TextStyle(color: theme.subtextColor),
        ),
        style: TextStyle(color: theme.textColor),
      ),
      optionsViewBuilder: (_, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          color: theme.cardBgColor,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200, maxWidth: 340),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (_, i) {
                final breed = options.elementAt(i);
                return InkWell(
                  onTap: () => onSelected(breed),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Text(breed,
                        style: TextStyle(
                            color: theme.textColor, fontSize: 13)),
                  ),
                );
              },
            ),
          ),
        ),
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
