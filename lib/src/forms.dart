part of '../main.dart';

class _ProfileDialog extends StatefulWidget {
  const _ProfileDialog({required this.profile});

  final SystemProfile profile;

  @override
  State<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<_ProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.displayName);
    _descriptionController = TextEditingController(
      text: widget.profile.description,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }
    Navigator.of(context).pop(
      widget.profile.copyWith(
        displayName: name,
        description: _descriptionController.text.trim(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('System'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _MemberDialog extends StatefulWidget {
  const _MemberDialog({this.member, required this.groups});

  final Member? member;
  final List<MemberGroup> groups;

  @override
  State<_MemberDialog> createState() => _MemberDialogState();
}

class _MemberDialogState extends State<_MemberDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _roleController;
  late final TextEditingController _noteController;
  late int _colorValue;
  String? _profileImageId;
  String? _profileImageDataUri;
  double _profileImageScale = defaultProfileImageScale;
  double _profileImageOffsetX = defaultProfileImageOffset;
  double _profileImageOffsetY = defaultProfileImageOffset;
  late Set<String> _groupIds;
  bool _pickingImage = false;

  bool get _isEditing => widget.member != null;

  @override
  void initState() {
    super.initState();
    final member = widget.member;
    _nameController = TextEditingController(text: member?.name ?? '');
    _roleController = TextEditingController(text: member?.role ?? '');
    _noteController = TextEditingController(text: member?.note ?? '');
    _colorValue = member?.colorValue ?? memberColorChoices.first;
    _profileImageId = member?.profileImageId;
    _profileImageDataUri = member?.profileImageDataUri;
    _profileImageScale = member?.profileImageScale ?? defaultProfileImageScale;
    _profileImageOffsetX =
        member?.profileImageOffsetX ?? defaultProfileImageOffset;
    _profileImageOffsetY =
        member?.profileImageOffsetY ?? defaultProfileImageOffset;
    _groupIds = {...?member?.groupIds};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final existing = widget.member;
    Navigator.of(context).pop(
      _MemberFormResult(
        member: Member(
          id: existing?.id ?? createId('member'),
          name: name,
          role: _roleController.text.trim().isEmpty
              ? 'Member'
              : _roleController.text.trim(),
          note: _noteController.text.trim(),
          groupIds: _groupIds.toList(growable: false),
          colorValue: _colorValue,
          archived: existing?.archived ?? false,
          createdAt: existing?.createdAt ?? now,
          updatedAt: now,
          profileImageId: _profileImageDataUri == null ? null : _profileImageId,
          profileImageDataUri: _profileImageDataUri,
          profileImageScale: _profileImageScale,
          profileImageOffsetX: _profileImageOffsetX,
          profileImageOffsetY: _profileImageOffsetY,
        ),
      ),
    );
  }

  Future<void> _pickProfileImage() async {
    if (_pickingImage) {
      return;
    }

    setState(() {
      _pickingImage = true;
    });

    try {
      final pickedImage = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 82,
      );
      if (pickedImage == null) {
        return;
      }

      final bytes = await pickedImage.readAsBytes();
      final mimeType =
          pickedImage.mimeType ?? _mimeTypeFromPath(pickedImage.name);
      setState(() {
        _profileImageId = null;
        _profileImageDataUri =
            'data:${mimeType ?? 'image/jpeg'};base64,${base64Encode(bytes)}';
        _profileImageScale = defaultProfileImageScale;
        _profileImageOffsetX = defaultProfileImageOffset;
        _profileImageOffsetY = defaultProfileImageOffset;
      });
      await _adjustProfileImage();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load that image.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _pickingImage = false;
        });
      }
    }
  }

  void _clearProfileImage() {
    setState(() {
      _profileImageId = null;
      _profileImageDataUri = null;
      _profileImageScale = defaultProfileImageScale;
      _profileImageOffsetX = defaultProfileImageOffset;
      _profileImageOffsetY = defaultProfileImageOffset;
    });
  }

  Future<void> _adjustProfileImage() async {
    final dataUri = _profileImageDataUri;
    if (dataUri == null || dataUri.isEmpty) {
      return;
    }

    final frame = await showDialog<_ProfileImageFrame>(
      context: context,
      builder: (context) => _ProfileImageFrameDialog(
        imageDataUri: dataUri,
        colorValue: _colorValue,
        initial: _initialFromName(_nameController.text),
        initialFrame: _ProfileImageFrame(
          scale: _profileImageScale,
          offsetX: _profileImageOffsetX,
          offsetY: _profileImageOffsetY,
        ),
      ),
    );
    if (frame == null || !mounted) {
      return;
    }

    setState(() {
      _profileImageScale = frame.scale;
      _profileImageOffsetX = frame.offsetX;
      _profileImageOffsetY = frame.offsetY;
    });
  }

  void _archiveToggle() {
    final member = widget.member;
    if (member == null) {
      return;
    }
    Navigator.of(context).pop(_MemberFormResult(archive: !member.archived));
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.member;

    return AlertDialog(
      title: Text(_isEditing ? 'Member' : 'New member'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _nameController,
                      builder: (context, value, _) {
                        return _AvatarPreview(
                          imageDataUri: _profileImageDataUri,
                          colorValue: _colorValue,
                          initial: _initialFromName(value.text),
                          size: 88,
                          imageScale: _profileImageScale,
                          imageOffsetX: _profileImageOffsetX,
                          imageOffsetY: _profileImageOffsetY,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: _pickingImage ? null : _pickProfileImage,
                          icon: Icon(
                            _pickingImage
                                ? Icons.hourglass_empty
                                : Icons.add_photo_alternate_outlined,
                          ),
                          label: Text(_pickingImage ? 'Loading' : 'Image'),
                        ),
                        if (_profileImageDataUri != null)
                          TextButton.icon(
                            onPressed: _adjustProfileImage,
                            icon: const Icon(Icons.crop_free),
                            label: const Text('Adjust'),
                          ),
                        if (_profileImageDataUri != null)
                          TextButton.icon(
                            onPressed: _clearProfileImage,
                            icon: const Icon(Icons.close),
                            label: const Text('Remove'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _roleController,
                decoration: const InputDecoration(labelText: 'Role'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Notes'),
                minLines: 2,
                maxLines: 4,
              ),
              if (widget.groups.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text('Groups', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.groups.map((group) {
                    final selected = _groupIds.contains(group.id);
                    return _GroupChip(
                      group: group,
                      selected: selected,
                      onPressed: () {
                        setState(() {
                          if (selected) {
                            _groupIds.remove(group.id);
                          } else {
                            _groupIds.add(group.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 18),
              Text('Color', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: memberColorChoices.map((value) {
                  final selected = value == _colorValue;
                  return Tooltip(
                    message: selected ? 'Selected color' : 'Color',
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _colorValue = value;
                        });
                      },
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(value),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? Theme.of(context).colorScheme.onSurface
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: selected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (member != null)
          TextButton.icon(
            onPressed: _archiveToggle,
            icon: Icon(
              member.archived
                  ? Icons.unarchive_outlined
                  : Icons.archive_outlined,
            ),
            label: Text(member.archived ? 'Restore' : 'Archive'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _ProfileImageFrame {
  const _ProfileImageFrame({
    required this.scale,
    required this.offsetX,
    required this.offsetY,
  });

  final double scale;
  final double offsetX;
  final double offsetY;

  _ProfileImageFrame normalized() {
    return _ProfileImageFrame(
      scale: _clampDouble(scale, 1, 3),
      offsetX: _clampDouble(offsetX, -1, 1),
      offsetY: _clampDouble(offsetY, -1, 1),
    );
  }
}

class _ProfileImageFrameDialog extends StatefulWidget {
  const _ProfileImageFrameDialog({
    required this.imageDataUri,
    required this.colorValue,
    required this.initial,
    required this.initialFrame,
  });

  final String imageDataUri;
  final int colorValue;
  final String initial;
  final _ProfileImageFrame initialFrame;

  @override
  State<_ProfileImageFrameDialog> createState() =>
      _ProfileImageFrameDialogState();
}

class _ProfileImageFrameDialogState extends State<_ProfileImageFrameDialog> {
  late double _scale;
  late double _offsetX;
  late double _offsetY;

  @override
  void initState() {
    super.initState();
    final frame = widget.initialFrame.normalized();
    _scale = frame.scale;
    _offsetX = frame.offsetX;
    _offsetY = frame.offsetY;
  }

  void _reset() {
    setState(() {
      _scale = defaultProfileImageScale;
      _offsetX = defaultProfileImageOffset;
      _offsetY = defaultProfileImageOffset;
    });
  }

  void _save() {
    Navigator.of(context).pop(
      _ProfileImageFrame(
        scale: _scale,
        offsetX: _offsetX,
        offsetY: _offsetY,
      ).normalized(),
    );
  }

  void _panImage(DragUpdateDetails details) {
    setState(() {
      _offsetX = _clampDouble(_offsetX - details.delta.dx / 90, -1, 1);
      _offsetY = _clampDouble(_offsetY - details.delta.dy / 90, -1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Adjust image'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onPanUpdate: _panImage,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _AvatarPreview(
                    imageDataUri: widget.imageDataUri,
                    colorValue: widget.colorValue,
                    initial: widget.initial,
                    size: 184,
                    imageScale: _scale,
                    imageOffsetX: _offsetX,
                    imageOffsetY: _offsetY,
                  ),
                  IgnorePointer(
                    child: Container(
                      width: 184,
                      height: 184,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.primary,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _ProfileImageFrameSlider(
              label: 'Zoom',
              value: _scale,
              min: 1,
              max: 3,
              divisions: 20,
              onChanged: (value) => setState(() {
                _scale = value;
              }),
            ),
            _ProfileImageFrameSlider(
              label: 'Horizontal',
              value: _offsetX,
              min: -1,
              max: 1,
              divisions: 20,
              onChanged: (value) => setState(() {
                _offsetX = value;
              }),
            ),
            _ProfileImageFrameSlider(
              label: 'Vertical',
              value: _offsetY,
              min: -1,
              max: 1,
              divisions: 20,
              onChanged: (value) => setState(() {
                _offsetY = value;
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _reset, child: const Text('Reset')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Done')),
      ],
    );
  }
}

class _ProfileImageFrameSlider extends StatelessWidget {
  const _ProfileImageFrameSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 82,
          child: Text(label, style: Theme.of(context).textTheme.labelMedium),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _GroupDialog extends StatefulWidget {
  const _GroupDialog({this.group});

  final MemberGroup? group;

  @override
  State<_GroupDialog> createState() => _GroupDialogState();
}

class _GroupDialogState extends State<_GroupDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late int _colorValue;

  bool get _isEditing => widget.group != null;

  @override
  void initState() {
    super.initState();
    final group = widget.group;
    _nameController = TextEditingController(text: group?.name ?? '');
    _descriptionController = TextEditingController(
      text: group?.description ?? '',
    );
    _colorValue = group?.colorValue ?? memberColorChoices.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final existing = widget.group;
    Navigator.of(context).pop(
      _GroupFormResult(
        group: MemberGroup(
          id: existing?.id ?? createId('group'),
          name: name,
          description: _descriptionController.text.trim(),
          colorValue: _colorValue,
          archived: existing?.archived ?? false,
          createdAt: existing?.createdAt ?? now,
          updatedAt: now,
        ),
      ),
    );
  }

  void _archiveToggle() {
    final group = widget.group;
    if (group == null) {
      return;
    }
    Navigator.of(context).pop(_GroupFormResult(archive: !group.archived));
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;

    return AlertDialog(
      title: Text(_isEditing ? 'Group' : 'New group'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                minLines: 2,
                maxLines: 3,
              ),
              const SizedBox(height: 18),
              Text('Color', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: memberColorChoices.map((value) {
                  final selected = value == _colorValue;
                  return Tooltip(
                    message: selected ? 'Selected color' : 'Color',
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _colorValue = value;
                        });
                      },
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(value),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? Theme.of(context).colorScheme.onSurface
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: selected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (group != null)
          TextButton.icon(
            onPressed: _archiveToggle,
            icon: Icon(
              group.archived
                  ? Icons.unarchive_outlined
                  : Icons.archive_outlined,
            ),
            label: Text(group.archived ? 'Restore' : 'Archive'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _TimelineNoteDialog extends StatefulWidget {
  const _TimelineNoteDialog();

  @override
  State<_TimelineNoteDialog> createState() => _TimelineNoteDialogState();
}

class _TimelineNoteDialogState extends State<_TimelineNoteDialog> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.of(context).pop(_noteController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Timeline note'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: TextField(
          controller: _noteController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Note'),
          minLines: 3,
          maxLines: 6,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
