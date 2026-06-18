part of '../main.dart';

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.snapshot,
    required this.storeInfo,
    required this.loadError,
    required this.saving,
    required this.onEditProfile,
    required this.onEditMember,
    required this.onEditGroup,
    required this.selectedGroupId,
    required this.onSelectGroup,
    required this.onToggleFront,
    required this.onAddTimelineNote,
    required this.onShowInsights,
    required this.onDeleteTimelineEntry,
  });

  final AppSnapshot snapshot;
  final AppStoreInfo? storeInfo;
  final String? loadError;
  final bool saving;
  final VoidCallback onEditProfile;
  final ValueChanged<Member?> onEditMember;
  final ValueChanged<MemberGroup?> onEditGroup;
  final String? selectedGroupId;
  final ValueChanged<String?> onSelectGroup;
  final ValueChanged<Member> onToggleFront;
  final VoidCallback onAddTimelineNote;
  final VoidCallback onShowInsights;
  final ValueChanged<TimelineEntry> onDeleteTimelineEntry;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
      children: [
        if (loadError != null) ...[
          _InlineNotice(message: loadError!),
          const SizedBox(height: 12),
        ],
        _DailyOverview(
          snapshot: snapshot,
          onEditProfile: onEditProfile,
          onAddMember: () => onEditMember(null),
          onAddGroup: () => onEditGroup(null),
          onAddTimelineNote: onAddTimelineNote,
          onShowInsights: onShowInsights,
        ),
        if (snapshot.activeMembers.isEmpty) ...[
          const SizedBox(height: 12),
          const _GettingStartedPanel(),
        ],
        const SizedBox(height: 18),
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _MembersSection(
                  snapshot: snapshot,
                  onEditMember: onEditMember,
                  onEditGroup: onEditGroup,
                  selectedGroupId: selectedGroupId,
                  onSelectGroup: onSelectGroup,
                  onToggleFront: onToggleFront,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                flex: 2,
                child: _TimelineSection(
                  events: snapshot.activeTimeline,
                  onAddNote: onAddTimelineNote,
                  onDeleteEntry: onDeleteTimelineEntry,
                ),
              ),
            ],
          )
        else ...[
          _MembersSection(
            snapshot: snapshot,
            onEditMember: onEditMember,
            onEditGroup: onEditGroup,
            selectedGroupId: selectedGroupId,
            onSelectGroup: onSelectGroup,
            onToggleFront: onToggleFront,
          ),
          const SizedBox(height: 18),
          _TimelineSection(
            events: snapshot.activeTimeline,
            onAddNote: onAddTimelineNote,
            onDeleteEntry: onDeleteTimelineEntry,
          ),
        ],
        const SizedBox(height: 18),
        _DataSafetyStrip(storeInfo: storeInfo, saving: saving),
      ],
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: TextStyle(color: colorScheme.onErrorContainer),
      ),
    );
  }
}

class _DataSafetyStrip extends StatelessWidget {
  const _DataSafetyStrip({required this.storeInfo, required this.saving});

  final AppStoreInfo? storeInfo;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final info = storeInfo;
    final detail = saving
        ? 'Saving changes'
        : info?.lastSavedAt == null
        ? 'Preparing local store'
        : 'Saved ${_formatDateTime(info!.lastSavedAt!)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            saving ? Icons.save_outlined : Icons.health_and_safety_outlined,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info?.label ?? 'Local storage',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GettingStartedPanel extends StatelessWidget {
  const _GettingStartedPanel();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route_outlined, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Start your system',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _GuideStepChip(
                icon: Icons.person_add_alt_1,
                label: 'Create member',
              ),
              _GuideStepChip(
                icon: Icons.folder_shared_outlined,
                label: 'Add group',
              ),
              _GuideStepChip(
                icon: Icons.radio_button_checked,
                label: 'Mark fronting',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GuideStepChip extends StatelessWidget {
  const _GuideStepChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Chip(
      avatar: Icon(icon, size: 17),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: colorScheme.outlineVariant),
      backgroundColor: colorScheme.surface,
    );
  }
}

class _DailyOverview extends StatelessWidget {
  const _DailyOverview({
    required this.snapshot,
    required this.onEditProfile,
    required this.onAddMember,
    required this.onAddGroup,
    required this.onAddTimelineNote,
    required this.onShowInsights,
  });

  final AppSnapshot snapshot;
  final VoidCallback onEditProfile;
  final VoidCallback onAddMember;
  final VoidCallback onAddGroup;
  final VoidCallback onAddTimelineNote;
  final VoidCallback onShowInsights;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final profile = snapshot.profile;
    final frontingMembers = snapshot.members
        .where((member) => snapshot.frontingMemberIds.contains(member.id))
        .toList(growable: false);
    final latestEntry = snapshot.activeTimeline.firstOrNull;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (profile.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        profile.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: onEditProfile,
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit system',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: onAddMember,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Add member'),
              ),
              OutlinedButton.icon(
                onPressed: onAddGroup,
                icon: const Icon(Icons.folder_shared_outlined),
                label: const Text('Add group'),
              ),
              TextButton.icon(
                onPressed: onAddTimelineNote,
                icon: const Icon(Icons.note_add_outlined),
                label: const Text('Add note'),
              ),
              TextButton.icon(
                onPressed: onShowInsights,
                icon: const Icon(Icons.insights_outlined),
                label: const Text('View insights'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _OverviewTile(
                icon: Icons.radio_button_checked,
                label: 'Current front',
                value: _frontingSummary(frontingMembers),
                detail: '${snapshot.activeMembers.length} active members',
              ),
              _OverviewTile(
                icon: Icons.history,
                label: 'Latest update',
                value: latestEntry == null
                    ? 'No timeline entries'
                    : _entryTitle(latestEntry),
                detail: latestEntry == null
                    ? 'Add a note or front change'
                    : _entrySubtitle(latestEntry),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewTile extends StatelessWidget {
  const _OverviewTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 190,
      constraints: const BoxConstraints(minHeight: 78),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

String _frontingSummary(List<Member> frontingMembers) {
  if (frontingMembers.isEmpty) {
    return 'No one fronting';
  }
  if (frontingMembers.length <= 2) {
    return frontingMembers.map((member) => member.name).join(', ');
  }
  return '${frontingMembers.take(2).map((member) => member.name).join(', ')} +${frontingMembers.length - 2}';
}
