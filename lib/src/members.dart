part of '../main.dart';

enum _MemberSortMode { nameAscending, recentlyFronted, mostUsed }

extension _MemberSortModeLabel on _MemberSortMode {
  String get label {
    return switch (this) {
      _MemberSortMode.nameAscending => 'A-Z',
      _MemberSortMode.recentlyFronted => 'Recently fronted',
      _MemberSortMode.mostUsed => 'Most used',
    };
  }

  IconData get icon {
    return switch (this) {
      _MemberSortMode.nameAscending => Icons.sort_by_alpha,
      _MemberSortMode.recentlyFronted => Icons.history,
      _MemberSortMode.mostUsed => Icons.timer_outlined,
    };
  }
}

List<Member> _visibleMembers(
  AppSnapshot snapshot,
  String? selectedGroupId,
  _MemberSortMode sortMode,
) {
  final activeMembers = snapshot.activeMembers;
  final filteredMembers = selectedGroupId == null
      ? activeMembers
      : selectedGroupId == _frontingFilterId
      ? activeMembers
            .where((member) => snapshot.frontingMemberIds.contains(member.id))
            .toList(growable: false)
      : activeMembers
            .where((member) => member.groupIds.contains(selectedGroupId))
            .toList(growable: false);

  return _sortMembers(filteredMembers, snapshot, sortMode);
}

List<Member> _sortMembers(
  List<Member> members,
  AppSnapshot snapshot,
  _MemberSortMode sortMode,
) {
  final sortedMembers = members.toList(growable: false);
  final now = DateTime.now();
  final latestFrontedAtByMemberId = _latestFrontedAtByMemberId(
    snapshot.frontSessions,
  );
  final frontDurationByMemberId = _frontDurationByMemberId(
    snapshot.frontSessions,
    now,
  );

  sortedMembers.sort((first, second) {
    return switch (sortMode) {
      _MemberSortMode.nameAscending => _compareMembersByName(first, second),
      _MemberSortMode.recentlyFronted => _compareMembersByRecentFront(
        first,
        second,
        latestFrontedAtByMemberId,
      ),
      _MemberSortMode.mostUsed => _compareMembersByFrontDuration(
        first,
        second,
        frontDurationByMemberId,
      ),
    };
  });

  return sortedMembers;
}

int _compareMembersByName(Member first, Member second) {
  final firstName = first.name.trim().toLowerCase();
  final secondName = second.name.trim().toLowerCase();
  final nameComparison = firstName.compareTo(secondName);
  if (nameComparison != 0) {
    return nameComparison;
  }
  return first.id.compareTo(second.id);
}

int _compareMembersByRecentFront(
  Member first,
  Member second,
  Map<String, DateTime> latestFrontedAtByMemberId,
) {
  final firstStartedAt = latestFrontedAtByMemberId[first.id];
  final secondStartedAt = latestFrontedAtByMemberId[second.id];

  if (firstStartedAt == null && secondStartedAt != null) {
    return 1;
  }
  if (firstStartedAt != null && secondStartedAt == null) {
    return -1;
  }
  if (firstStartedAt != null && secondStartedAt != null) {
    final recentComparison = secondStartedAt.compareTo(firstStartedAt);
    if (recentComparison != 0) {
      return recentComparison;
    }
  }
  return _compareMembersByName(first, second);
}

int _compareMembersByFrontDuration(
  Member first,
  Member second,
  Map<String, Duration> frontDurationByMemberId,
) {
  final firstDuration = frontDurationByMemberId[first.id] ?? Duration.zero;
  final secondDuration = frontDurationByMemberId[second.id] ?? Duration.zero;
  final durationComparison = secondDuration.inMicroseconds.compareTo(
    firstDuration.inMicroseconds,
  );
  if (durationComparison != 0) {
    return durationComparison;
  }
  return _compareMembersByName(first, second);
}

Map<String, DateTime> _latestFrontedAtByMemberId(
  List<FrontSession> frontSessions,
) {
  final latestFrontedAtByMemberId = <String, DateTime>{};
  for (final session in frontSessions) {
    final latestStartedAt = latestFrontedAtByMemberId[session.memberId];
    if (latestStartedAt == null || session.startedAt.isAfter(latestStartedAt)) {
      latestFrontedAtByMemberId[session.memberId] = session.startedAt;
    }
  }
  return latestFrontedAtByMemberId;
}

Map<String, Duration> _frontDurationByMemberId(
  List<FrontSession> frontSessions,
  DateTime now,
) {
  final frontDurationByMemberId = <String, Duration>{};
  for (final session in frontSessions) {
    frontDurationByMemberId[session.memberId] =
        (frontDurationByMemberId[session.memberId] ?? Duration.zero) +
        session.durationUntil(now);
  }
  return frontDurationByMemberId;
}

List<Member> _archivedMembers(AppSnapshot snapshot, _MemberSortMode sortMode) {
  return _sortMembers(snapshot.archivedMembers, snapshot, sortMode);
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _MembersSection extends StatelessWidget {
  const _MembersSection({
    required this.snapshot,
    required this.onEditMember,
    required this.onEditGroup,
    required this.selectedGroupId,
    required this.sortMode,
    required this.onSelectGroup,
    required this.onSortModeChanged,
    required this.onToggleFront,
  });

  final AppSnapshot snapshot;
  final ValueChanged<Member?> onEditMember;
  final ValueChanged<MemberGroup?> onEditGroup;
  final String? selectedGroupId;
  final _MemberSortMode sortMode;
  final ValueChanged<String?> onSelectGroup;
  final ValueChanged<_MemberSortMode> onSortModeChanged;
  final ValueChanged<Member> onToggleFront;

  @override
  Widget build(BuildContext context) {
    final activeGroups = snapshot.activeGroups;
    final visibleMembers = _visibleMembers(snapshot, selectedGroupId, sortMode);
    final archivedMembers = _archivedMembers(snapshot, sortMode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.radio_button_checked,
          title: 'Members',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MemberSortMenu(value: sortMode, onChanged: onSortModeChanged),
              IconButton(
                onPressed: () => onEditGroup(null),
                icon: const Icon(Icons.folder_shared_outlined),
                tooltip: 'Add group',
              ),
              IconButton(
                onPressed: () => onEditMember(null),
                icon: const Icon(Icons.person_add_alt_1),
                tooltip: 'Add member',
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _GroupFilterRow(
          groups: activeGroups,
          selectedGroupId: selectedGroupId,
          onSelectGroup: onSelectGroup,
          onEditGroup: onEditGroup,
        ),
        if (snapshot.archivedGroups.isNotEmpty) ...[
          const SizedBox(height: 8),
          _ArchivedGroupsRow(
            groups: snapshot.archivedGroups,
            onEditGroup: onEditGroup,
          ),
        ],
        const SizedBox(height: 10),
        if (visibleMembers.isEmpty)
          _EmptySurface(
            icon: selectedGroupId == _frontingFilterId
                ? Icons.radio_button_unchecked
                : Icons.person_add_alt_1,
            label: selectedGroupId == null
                ? 'No members yet'
                : selectedGroupId == _frontingFilterId
                ? 'No one is fronting'
                : 'No members in this group',
            message: selectedGroupId == null
                ? 'Add a member to begin.'
                : selectedGroupId == _frontingFilterId
                ? 'Use the Front button on a member when someone is active.'
                : 'Assign members from their profiles.',
            action: selectedGroupId == null
                ? FilledButton.icon(
                    onPressed: () => onEditMember(null),
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Add member'),
                  )
                : TextButton.icon(
                    onPressed: () => onSelectGroup(null),
                    icon: const Icon(Icons.all_inclusive),
                    label: const Text('Show all'),
                  ),
          )
        else
          ...visibleMembers.map(
            (member) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MemberTile(
                member: member,
                groups: activeGroups
                    .where((group) => member.groupIds.contains(group.id))
                    .toList(growable: false),
                isFronting: snapshot.frontingMemberIds.contains(member.id),
                onToggleFront: () => onToggleFront(member),
                onEdit: () => onEditMember(member),
                onSelectGroup: (group) => onSelectGroup(group.id),
              ),
            ),
          ),
        if (archivedMembers.isNotEmpty) ...[
          const SizedBox(height: 8),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text('Archived (${archivedMembers.length})'),
            children: archivedMembers
                .map(
                  (member) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _MemberTile(
                      member: member,
                      groups: activeGroups
                          .where((group) => member.groupIds.contains(group.id))
                          .toList(growable: false),
                      isFronting: false,
                      onToggleFront: () {},
                      onEdit: () => onEditMember(member),
                      onSelectGroup: (group) => onSelectGroup(group.id),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _MemberSortMenu extends StatelessWidget {
  const _MemberSortMenu({required this.value, required this.onChanged});

  final _MemberSortMode value;
  final ValueChanged<_MemberSortMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_MemberSortMode>(
      icon: Icon(value.icon),
      tooltip: 'Sort members: ${value.label}',
      onSelected: onChanged,
      itemBuilder: (context) => _MemberSortMode.values
          .map(
            (mode) => CheckedPopupMenuItem<_MemberSortMode>(
              key: ValueKey('member-sort-${mode.name}'),
              value: mode,
              checked: mode == value,
              child: Text(mode.label),
            ),
          )
          .toList(),
    );
  }
}

class _GroupFilterRow extends StatefulWidget {
  const _GroupFilterRow({
    required this.groups,
    required this.selectedGroupId,
    required this.onSelectGroup,
    required this.onEditGroup,
  });

  final List<MemberGroup> groups;
  final String? selectedGroupId;
  final ValueChanged<String?> onSelectGroup;
  final ValueChanged<MemberGroup?> onEditGroup;

  @override
  State<_GroupFilterRow> createState() => _GroupFilterRowState();
}

class _GroupFilterRowState extends State<_GroupFilterRow> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _chipKeys = {};

  @override
  void initState() {
    super.initState();
    _scrollSelectedChipIntoView();
  }

  @override
  void didUpdateWidget(_GroupFilterRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedGroupId != widget.selectedGroupId) {
      _scrollSelectedChipIntoView();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  GlobalKey _keyFor(String chipId) {
    return _chipKeys.putIfAbsent(chipId, GlobalKey.new);
  }

  void _scrollSelectedChipIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final selectedChipId = widget.selectedGroupId ?? _allGroupsFilterId;
      final selectedContext = _chipKeys[selectedChipId]?.currentContext;
      if (selectedContext == null) {
        return;
      }

      Scrollable.ensureVisible(
        selectedContext,
        alignment: 0.5,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            key: _keyFor(_allGroupsFilterId),
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: widget.selectedGroupId == null,
              avatar: const Icon(Icons.all_inclusive, size: 18),
              label: const Text('All'),
              onSelected: (_) => widget.onSelectGroup(null),
            ),
          ),
          Padding(
            key: _keyFor(_frontingFilterId),
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: widget.selectedGroupId == _frontingFilterId,
              avatar: const Icon(Icons.radio_button_checked, size: 18),
              label: const Text('Fronting'),
              onSelected: (_) => widget.onSelectGroup(_frontingFilterId),
            ),
          ),
          ...widget.groups.map(
            (group) => Padding(
              key: _keyFor(group.id),
              padding: const EdgeInsets.only(right: 8),
              child: InputChip(
                selected: widget.selectedGroupId == group.id,
                avatar: CircleAvatar(backgroundColor: Color(group.colorValue)),
                label: Text(group.name),
                onPressed: () => widget.onSelectGroup(group.id),
                onDeleted: () => widget.onEditGroup(group),
                deleteIcon: const Icon(Icons.edit_outlined, size: 18),
                deleteButtonTooltipMessage: 'Edit group',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchivedGroupsRow extends StatelessWidget {
  const _ArchivedGroupsRow({required this.groups, required this.onEditGroup});

  final List<MemberGroup> groups;
  final ValueChanged<MemberGroup?> onEditGroup;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text('Archived groups (${groups.length})'),
      children: groups.map((group) {
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 8,
            backgroundColor: Color(group.colorValue),
          ),
          title: Text(group.name),
          subtitle: group.description.isEmpty ? null : Text(group.description),
          trailing: IconButton(
            onPressed: () => onEditGroup(group),
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit group',
          ),
        );
      }).toList(),
    );
  }
}

class _GroupChip extends StatelessWidget {
  const _GroupChip({
    required this.group,
    this.compact = false,
    this.selected = false,
    this.onPressed,
  });

  final MemberGroup group;
  final bool compact;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final label = Text(group.name);
    final avatar = CircleAvatar(backgroundColor: Color(group.colorValue));

    if (onPressed != null) {
      return FilterChip(
        selected: selected,
        avatar: avatar,
        label: label,
        onSelected: (_) => onPressed?.call(),
        visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      );
    }

    return Chip(
      avatar: avatar,
      label: label,
      side: BorderSide.none,
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.groups,
    required this.isFronting,
    required this.onToggleFront,
    required this.onEdit,
    required this.onSelectGroup,
  });

  final Member member;
  final List<MemberGroup> groups;
  final bool isFronting;
  final VoidCallback onToggleFront;
  final VoidCallback onEdit;
  final ValueChanged<MemberGroup> onSelectGroup;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final note = member.note.trim().isEmpty ? member.role : member.note;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 430;
            final details = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  note,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (groups.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: groups
                        .map(
                          (group) => _GroupChip(
                            group: group,
                            compact: true,
                            onPressed: () => onSelectGroup(group),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            );
            final actions = Wrap(
              spacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (!member.archived)
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 112),
                    child: FilledButton.tonalIcon(
                      onPressed: onToggleFront,
                      icon: Icon(
                        isFronting ? Icons.check_circle : Icons.login,
                        color: isFronting ? colorScheme.primary : null,
                      ),
                      label: Text(isFronting ? 'Fronting' : 'Front'),
                    ),
                  ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit member',
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MemberAvatar(member: member, size: 44),
                      const SizedBox(width: 14),
                      Expanded(child: details),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(alignment: Alignment.centerRight, child: actions),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MemberAvatar(member: member, size: 44),
                const SizedBox(width: 14),
                Expanded(child: details),
                const SizedBox(width: 10),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TimelineSection extends StatelessWidget {
  const _TimelineSection({
    required this.events,
    required this.onAddNote,
    required this.onDeleteEntry,
  });

  final List<TimelineEntry> events;
  final VoidCallback onAddNote;
  final ValueChanged<TimelineEntry> onDeleteEntry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.history,
          title: 'Timeline',
          trailing: IconButton(
            onPressed: onAddNote,
            icon: const Icon(Icons.note_add_outlined),
            tooltip: 'Add note',
          ),
        ),
        const SizedBox(height: 10),
        if (events.isEmpty)
          _EmptySurface(
            icon: Icons.history_toggle_off_outlined,
            label: 'No timeline entries yet',
            message: 'Front changes and notes will show here.',
            action: TextButton.icon(
              onPressed: onAddNote,
              icon: const Icon(Icons.note_add_outlined),
              label: const Text('Add note'),
            ),
          )
        else
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.separated(
              itemCount: events.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final event = events[index];
                return ListTile(
                  leading: Icon(
                    event.type == 'note'
                        ? Icons.sticky_note_2_outlined
                        : Icons.bolt_outlined,
                  ),
                  title: Text(_entryTitle(event)),
                  subtitle: Text(_entrySubtitle(event)),
                  trailing: IconButton(
                    onPressed: () => onDeleteEntry(event),
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete timeline entry',
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.member, required this.size});

  final Member member;
  final double size;

  @override
  Widget build(BuildContext context) {
    return _AvatarPreview(
      imageDataUri: member.profileImageDataUri,
      colorValue: member.colorValue,
      initial: member.initial,
      size: size,
      imageScale: member.profileImageScale,
      imageOffsetX: member.profileImageOffsetX,
      imageOffsetY: member.profileImageOffsetY,
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({
    required this.imageDataUri,
    required this.colorValue,
    required this.initial,
    required this.size,
    this.imageScale = defaultProfileImageScale,
    this.imageOffsetX = defaultProfileImageOffset,
    this.imageOffsetY = defaultProfileImageOffset,
  });

  final String? imageDataUri;
  final int colorValue;
  final String initial;
  final double size;
  final double imageScale;
  final double imageOffsetX;
  final double imageOffsetY;

  @override
  Widget build(BuildContext context) {
    final bytes = _imageBytesFromDataUri(imageDataUri);

    if (bytes == null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: Color(colorValue),
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: Transform.scale(
          scale: _clampDouble(imageScale, 1, 3),
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            alignment: Alignment(
              _clampDouble(imageOffsetX, -1, 1),
              _clampDouble(imageOffsetY, -1, 1),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptySurface extends StatelessWidget {
  const _EmptySurface({
    required this.label,
    this.message,
    this.icon,
    this.action,
  });

  final String label;
  final String? message;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                icon,
                size: 18,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (message != null) ...[
            const SizedBox(height: 4),
            Text(message!, style: Theme.of(context).textTheme.bodySmall),
          ],
          if (action != null) ...[const SizedBox(height: 10), action!],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        ?trailing,
      ],
    );
  }
}
