part of '../main.dart';

class _InsightsDialog extends StatelessWidget {
  const _InsightsDialog({required this.snapshot, required this.now});

  final AppSnapshot snapshot;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final summary = _InsightsSummary.fromSnapshot(snapshot, now);
    final maxContentHeight = MediaQuery.sizeOf(context).height * 0.72;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.insights_outlined),
          SizedBox(width: 10),
          Text('Insights'),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: maxContentHeight < 340 ? 340 : maxContentHeight,
        ),
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Last 7 days',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _InsightMetricCard(
                      icon: Icons.timer_outlined,
                      label: 'Front time',
                      value: _formatDurationCompact(summary.frontTime7Days),
                      detail: 'Tracked locally',
                    ),
                    _InsightMetricCard(
                      icon: Icons.swap_horiz_outlined,
                      label: 'Switches',
                      value: summary.switches7Days.toString(),
                      detail: 'Session starts',
                    ),
                    _InsightMetricCard(
                      icon: Icons.radio_button_checked,
                      label: 'Active now',
                      value: _frontingNameSummary(summary.activeFrontNames),
                      detail: _formatDurationCompact(summary.activeFrontTime),
                    ),
                    _InsightMetricCard(
                      icon: Icons.history_toggle_off_outlined,
                      label: 'All time',
                      value: _formatDurationCompact(summary.totalTracked),
                      detail: '${snapshot.frontSessions.length} sessions',
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _InsightBarSection(
                  title: 'Member front time',
                  slices: summary.memberSlices,
                  emptyLabel: 'No member front time in this window',
                ),
                const SizedBox(height: 22),
                _InsightBarSection(
                  title: 'Group front time',
                  slices: summary.groupSlices,
                  emptyLabel: 'No group front time in this window',
                ),
                const SizedBox(height: 22),
                Text(
                  'Recent sessions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (summary.recentSessions.isEmpty)
                  const _EmptySurface(label: 'No front sessions yet')
                else
                  ...summary.recentSessions.map(
                    (session) => _InsightSessionTile(
                      session: session,
                      colorValue: summary.colorForMember(session.memberId),
                      now: now,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (snapshot.frontSessions.any(_isSampleInsightsSession))
          TextButton.icon(
            onPressed: () =>
                Navigator.of(context).pop(_InsightsAction.clearSampleData),
            icon: const Icon(Icons.delete_sweep_outlined),
            label: const Text('Clear samples'),
          ),
        TextButton.icon(
          onPressed: () =>
              Navigator.of(context).pop(_InsightsAction.refreshSampleData),
          icon: const Icon(Icons.auto_graph_outlined),
          label: Text(
            snapshot.frontSessions.any(_isSampleInsightsSession)
                ? 'Refresh samples'
                : 'Sample data',
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

enum _InsightsAction { refreshSampleData, clearSampleData }

class _InsightsSummary {
  const _InsightsSummary({
    required this.frontTime7Days,
    required this.switches7Days,
    required this.activeFrontTime,
    required this.totalTracked,
    required this.activeFrontNames,
    required this.memberSlices,
    required this.groupSlices,
    required this.recentSessions,
    required this.memberColorsById,
  });

  final Duration frontTime7Days;
  final int switches7Days;
  final Duration activeFrontTime;
  final Duration totalTracked;
  final List<String> activeFrontNames;
  final List<_InsightSlice> memberSlices;
  final List<_InsightSlice> groupSlices;
  final List<FrontSession> recentSessions;
  final Map<String, int> memberColorsById;

  int colorForMember(String memberId) {
    return memberColorsById[memberId] ?? memberColorChoices.first;
  }

  factory _InsightsSummary.fromSnapshot(AppSnapshot snapshot, DateTime now) {
    final windowStart = now.subtract(const Duration(days: 7));
    final membersById = {
      for (final member in snapshot.members) member.id: member,
    };
    final groupsById = {for (final group in snapshot.groups) group.id: group};
    final sessionNamesByMemberId = <String, String>{};
    final memberDurations = <String, Duration>{};
    final groupDurations = <String, Duration>{};
    var frontTime7Days = Duration.zero;
    var activeFrontTime = Duration.zero;
    var totalTracked = Duration.zero;

    for (final session in snapshot.frontSessions) {
      sessionNamesByMemberId[session.memberId] = session.memberName;
      final totalDuration = session.durationUntil(now);
      totalTracked += totalDuration;
      if (session.isOpen) {
        activeFrontTime += totalDuration;
      }

      final windowDuration = _sessionDurationWithin(session, windowStart, now);
      if (windowDuration == Duration.zero) {
        continue;
      }

      frontTime7Days += windowDuration;
      memberDurations[session.memberId] =
          (memberDurations[session.memberId] ?? Duration.zero) + windowDuration;

      final member = membersById[session.memberId];
      final groupIds = member?.groupIds ?? const <String>[];
      if (groupIds.isEmpty) {
        groupDurations[_ungroupedInsightGroupId] =
            (groupDurations[_ungroupedInsightGroupId] ?? Duration.zero) +
            windowDuration;
      } else {
        for (final groupId in groupIds) {
          groupDurations[groupId] =
              (groupDurations[groupId] ?? Duration.zero) + windowDuration;
        }
      }
    }

    final memberSlices = memberDurations.entries.map((entry) {
      final member = membersById[entry.key];
      return _InsightSlice(
        label:
            member?.name ??
            sessionNamesByMemberId[entry.key] ??
            'Unknown member',
        colorValue: member?.colorValue ?? memberColorChoices.first,
        duration: entry.value,
      );
    }).toList()..sort((left, right) => right.duration.compareTo(left.duration));

    final groupSlices = groupDurations.entries.map((entry) {
      if (entry.key == _ungroupedInsightGroupId) {
        return _InsightSlice(
          label: 'Ungrouped',
          colorValue: memberColorChoices.last,
          duration: entry.value,
        );
      }
      final group = groupsById[entry.key];
      return _InsightSlice(
        label: group?.name ?? 'Unknown group',
        colorValue: group?.colorValue ?? memberColorChoices.first,
        duration: entry.value,
      );
    }).toList()..sort((left, right) => right.duration.compareTo(left.duration));

    final recentSessions = [...snapshot.frontSessions]
      ..sort((left, right) => right.startedAt.compareTo(left.startedAt));
    final switches7Days = snapshot.frontSessions
        .where(
          (session) =>
              !session.startedAt.isBefore(windowStart) &&
              !session.startedAt.isAfter(now),
        )
        .length;
    final activeFrontNames = snapshot.frontingMemberIds
        .map((memberId) {
          return membersById[memberId]?.name ??
              sessionNamesByMemberId[memberId] ??
              'Unknown member';
        })
        .toList(growable: false);

    return _InsightsSummary(
      frontTime7Days: frontTime7Days,
      switches7Days: switches7Days,
      activeFrontTime: activeFrontTime,
      totalTracked: totalTracked,
      activeFrontNames: activeFrontNames,
      memberSlices: memberSlices.take(6).toList(growable: false),
      groupSlices: groupSlices.take(6).toList(growable: false),
      recentSessions: recentSessions.take(5).toList(growable: false),
      memberColorsById: {
        for (final member in snapshot.members) member.id: member.colorValue,
      },
    );
  }
}

class _InsightSlice {
  const _InsightSlice({
    required this.label,
    required this.colorValue,
    required this.duration,
  });

  final String label;
  final int colorValue;
  final Duration duration;
}

class _InsightMetricCard extends StatelessWidget {
  const _InsightMetricCard({
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
      width: 142,
      constraints: const BoxConstraints(minHeight: 108),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 4),
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

class _InsightBarSection extends StatelessWidget {
  const _InsightBarSection({
    required this.title,
    required this.slices,
    required this.emptyLabel,
  });

  final String title;
  final List<_InsightSlice> slices;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final maxDuration = slices.isEmpty ? Duration.zero : slices.first.duration;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        if (slices.isEmpty)
          _EmptySurface(label: emptyLabel)
        else
          ...slices.map(
            (slice) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _InsightBar(slice: slice, maxDuration: maxDuration),
            ),
          ),
      ],
    );
  }
}

class _InsightBar extends StatelessWidget {
  const _InsightBar({required this.slice, required this.maxDuration});

  final _InsightSlice slice;
  final Duration maxDuration;

  @override
  Widget build(BuildContext context) {
    final color = Color(slice.colorValue);
    final fraction = maxDuration.inMilliseconds == 0
        ? 0.0
        : (slice.duration.inMilliseconds / maxDuration.inMilliseconds)
              .clamp(0.0, 1.0)
              .toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                slice.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _formatDurationCompact(slice.duration),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Stack(
            children: [
              Container(height: 10, color: color.withValues(alpha: 0.16)),
              FractionallySizedBox(
                widthFactor: fraction,
                child: Container(height: 10, color: color),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InsightSessionTile extends StatelessWidget {
  const _InsightSessionTile({
    required this.session,
    required this.colorValue,
    required this.now,
  });

  final FrontSession session;
  final int colorValue;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final duration = session.durationUntil(now);
    final trailing = session.isOpen ? 'Ongoing' : 'Ended';

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(radius: 10, backgroundColor: Color(colorValue)),
      title: Text(session.memberName),
      subtitle: Text(
        '${_formatDateTime(session.startedAt)} - ${_formatDurationCompact(duration)}',
      ),
      trailing: Text(trailing, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

AppSnapshot _snapshotWithSampleInsightsData(
  AppSnapshot snapshot,
  DateTime now,
) {
  final members = snapshot.activeMembers.isEmpty
      ? snapshot.members
      : snapshot.activeMembers;
  if (members.isEmpty) {
    return snapshot;
  }

  final realSessions = snapshot.frontSessions
      .where((session) => !_isSampleInsightsSession(session))
      .toList(growable: false);
  final sampleSessions = _sampleInsightsSessions(members, now);
  final frontSessions = [...sampleSessions, ...realSessions]
    ..sort((left, right) => right.startedAt.compareTo(left.startedAt));

  return snapshot.copyWith(frontSessions: frontSessions);
}

AppSnapshot _snapshotWithoutSampleInsightsData(AppSnapshot snapshot) {
  return snapshot.copyWith(
    frontSessions: snapshot.frontSessions
        .where((session) => !_isSampleInsightsSession(session))
        .toList(growable: false),
  );
}

List<FrontSession> _sampleInsightsSessions(List<Member> members, DateTime now) {
  const startOffsets = [
    Duration(hours: 7, minutes: 45),
    Duration(hours: 10, minutes: 30),
    Duration(hours: 14, minutes: 15),
    Duration(hours: 19),
  ];
  const durations = [
    Duration(hours: 1, minutes: 35),
    Duration(hours: 2, minutes: 20),
    Duration(hours: 3, minutes: 5),
    Duration(hours: 1, minutes: 10),
  ];

  final today = DateTime(now.year, now.month, now.day);
  final sessions = <FrontSession>[];

  for (var dayOffset = 0; dayOffset < 14; dayOffset += 1) {
    final slotsForDay = 2 + (dayOffset % 3);
    final day = today.subtract(Duration(days: dayOffset));

    for (var slot = 0; slot < slotsForDay; slot += 1) {
      final startedAt = day.add(startOffsets[slot]);
      if (!startedAt.isBefore(now)) {
        continue;
      }

      var endedAt = startedAt.add(
        durations[(dayOffset + slot) % durations.length],
      );
      if (endedAt.isAfter(now)) {
        endedAt = now.subtract(const Duration(minutes: 5));
      }
      if (!endedAt.isAfter(startedAt)) {
        continue;
      }

      final member = members[(dayOffset + (slot * 2)) % members.length];
      sessions.add(
        FrontSession(
          id: '$_sampleInsightsSessionPrefix${dayOffset.toString().padLeft(2, '0')}-$slot',
          memberId: member.id,
          memberName: member.name,
          startedAt: startedAt,
          endedAt: endedAt,
        ),
      );
    }
  }

  return sessions;
}

bool _isSampleInsightsSession(FrontSession session) {
  return session.id.startsWith(_sampleInsightsSessionPrefix);
}
