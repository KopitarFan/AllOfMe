part of '../main.dart';

List<FrontSession> _closeOpenFrontSessions(
  List<FrontSession> sessions,
  String memberId,
  DateTime endedAt,
) {
  return sessions
      .map((session) {
        if (session.memberId == memberId && session.isOpen) {
          return session.copyWith(endedAt: endedAt);
        }
        return session;
      })
      .toList(growable: false);
}

String _entryTitle(TimelineEntry entry) {
  if (entry.type == 'note') {
    return entry.note ?? entry.action;
  }
  final memberName = entry.memberName;
  return memberName == null ? entry.action : '$memberName - ${entry.action}';
}

String _entrySubtitle(TimelineEntry entry) {
  return _formatTime(entry.createdAt);
}

Duration _sessionDurationWithin(
  FrontSession session,
  DateTime start,
  DateTime end,
) {
  final clippedStart = session.startedAt.isBefore(start)
      ? start
      : session.startedAt;
  final rawEnd = session.endedAt ?? end;
  final clippedEnd = rawEnd.isAfter(end) ? end : rawEnd;

  if (!clippedEnd.isAfter(clippedStart)) {
    return Duration.zero;
  }
  return clippedEnd.difference(clippedStart);
}

String _frontingNameSummary(List<String> names) {
  if (names.isEmpty) {
    return 'No one';
  }
  if (names.length <= 2) {
    return names.join(', ');
  }
  return '${names.take(2).join(', ')} +${names.length - 2}';
}

String _formatDurationCompact(Duration duration) {
  if (duration <= Duration.zero) {
    return '0m';
  }

  final days = duration.inDays;
  final hours = duration.inHours.remainder(24);
  final minutes = duration.inMinutes.remainder(60);

  if (days > 0) {
    return hours > 0 ? '${days}d ${hours}h' : '${days}d';
  }
  if (hours > 0) {
    return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
  }
  if (minutes > 0) {
    return '${minutes}m';
  }
  return '<1m';
}

String _formatDateTime(DateTime value) {
  return '${value.month}/${value.day}/${value.year} ${_formatTime(value)}';
}

String _formatTime(DateTime value) {
  final hour = value.hour == 0
      ? 12
      : value.hour > 12
      ? value.hour - 12
      : value.hour;
  final minute = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

String _initialFromName(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? '?' : trimmed.characters.first;
}

Uint8List? _imageBytesFromDataUri(String? dataUri) {
  if (dataUri == null || dataUri.isEmpty) {
    return null;
  }

  final marker = dataUri.indexOf('base64,');
  final encoded = marker == -1 ? dataUri : dataUri.substring(marker + 7);
  try {
    return base64Decode(encoded);
  } catch (_) {
    return null;
  }
}

String? _mimeTypeFromPath(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.png')) {
    return 'image/png';
  }
  if (lower.endsWith('.webp')) {
    return 'image/webp';
  }
  if (lower.endsWith('.gif')) {
    return 'image/gif';
  }
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
    return 'image/jpeg';
  }
  return null;
}
