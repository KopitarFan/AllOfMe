part of '../main.dart';

class _RecentlyDeletedDialog extends StatelessWidget {
  const _RecentlyDeletedDialog({required this.snapshot});

  final AppSnapshot snapshot;

  void _restore(BuildContext context, _DeletedItemReference item) {
    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    final archivedMembers = snapshot.archivedMembers;
    final archivedGroups = snapshot.archivedGroups;
    final deletedNotes = snapshot.deletedNotes;
    final deletedTimeline = snapshot.deletedTimelineEntries;
    final hasItems =
        archivedMembers.isNotEmpty ||
        archivedGroups.isNotEmpty ||
        deletedNotes.isNotEmpty ||
        deletedTimeline.isNotEmpty;
    final maxContentHeight = MediaQuery.sizeOf(context).height * 0.72;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.restore_from_trash_outlined),
          SizedBox(width: 10),
          Expanded(child: Text('Recently deleted')),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: maxContentHeight < 320 ? 320 : maxContentHeight,
        ),
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            child: hasItems
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (archivedMembers.isNotEmpty)
                        _DeletedItemsSection(
                          title: 'Members',
                          children: archivedMembers
                              .map(
                                (member) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: _MemberAvatar(
                                    member: member,
                                    size: 36,
                                  ),
                                  title: Text(
                                    member.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    'Archived ${_formatDateTime(member.updatedAt)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: IconButton(
                                    onPressed: () => _restore(
                                      context,
                                      _DeletedItemReference(
                                        _DeletedItemKind.member,
                                        member.id,
                                      ),
                                    ),
                                    icon: const Icon(Icons.restore_outlined),
                                    tooltip: 'Restore member',
                                  ),
                                  onTap: () => _restore(
                                    context,
                                    _DeletedItemReference(
                                      _DeletedItemKind.member,
                                      member.id,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      if (archivedGroups.isNotEmpty)
                        _DeletedItemsSection(
                          title: 'Groups',
                          children: archivedGroups
                              .map(
                                (group) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Color(group.colorValue),
                                  ),
                                  title: Text(
                                    group.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    'Archived ${_formatDateTime(group.updatedAt)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: IconButton(
                                    onPressed: () => _restore(
                                      context,
                                      _DeletedItemReference(
                                        _DeletedItemKind.group,
                                        group.id,
                                      ),
                                    ),
                                    icon: const Icon(Icons.restore_outlined),
                                    tooltip: 'Restore group',
                                  ),
                                  onTap: () => _restore(
                                    context,
                                    _DeletedItemReference(
                                      _DeletedItemKind.group,
                                      group.id,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      if (deletedNotes.isNotEmpty)
                        _DeletedItemsSection(
                          title: 'Notes',
                          children: deletedNotes
                              .map(
                                (entry) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(
                                    Icons.sticky_note_2_outlined,
                                  ),
                                  title: Text(
                                    _entryTitle(entry),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    'Deleted ${_formatDateTime(entry.deletedAt!)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: IconButton(
                                    onPressed: () => _restore(
                                      context,
                                      _DeletedItemReference(
                                        _DeletedItemKind.timelineEntry,
                                        entry.id,
                                      ),
                                    ),
                                    icon: const Icon(Icons.restore_outlined),
                                    tooltip: 'Restore note',
                                  ),
                                  onTap: () => _restore(
                                    context,
                                    _DeletedItemReference(
                                      _DeletedItemKind.timelineEntry,
                                      entry.id,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      if (deletedTimeline.isNotEmpty)
                        _DeletedItemsSection(
                          title: 'Timeline',
                          children: deletedTimeline
                              .map(
                                (entry) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.bolt_outlined),
                                  title: Text(
                                    _entryTitle(entry),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    'Deleted ${_formatDateTime(entry.deletedAt!)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: IconButton(
                                    onPressed: () => _restore(
                                      context,
                                      _DeletedItemReference(
                                        _DeletedItemKind.timelineEntry,
                                        entry.id,
                                      ),
                                    ),
                                    icon: const Icon(Icons.restore_outlined),
                                    tooltip: 'Restore timeline entry',
                                  ),
                                  onTap: () => _restore(
                                    context,
                                    _DeletedItemReference(
                                      _DeletedItemKind.timelineEntry,
                                      entry.id,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  )
                : const _EmptySurface(label: 'No deleted items'),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _DeletedItemsSection extends StatelessWidget {
  const _DeletedItemsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < children.length; index += 1) ...[
                  children[index],
                  if (index < children.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
