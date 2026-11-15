import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'models.dart';

/// Only the current front's explicitly shared profile fields participate.
String sharedFrontProfileSignature(AppSnapshot snapshot) => jsonEncode(
  snapshot.activeMembers
      .where((member) => snapshot.frontingMemberIds.contains(member.id))
      .map(
        (member) => {
          'id': member.id,
          'name': member.name,
          'role': member.role,
          'description': member.note,
          'colorValue': member.colorValue,
          'image': member.profileImageDataUri,
          'scale': member.profileImageScale,
          'offsetX': member.profileImageOffsetX,
          'offsetY': member.profileImageOffsetY,
          'groups': snapshot.activeGroups
              .where((group) => member.groupIds.contains(group.id))
              .map(
                (group) => {
                  'id': group.id,
                  'name': group.name,
                  'colorValue': group.colorValue,
                },
              )
              .toList(),
        },
      )
      .toList(),
);

Future<List<Map<String, Object?>>> sharedFrontProfiles(
  AppSnapshot snapshot,
) async {
  final profiles = <Map<String, Object?>>[];
  for (final member
      in snapshot.activeMembers
          .where((member) => snapshot.frontingMemberIds.contains(member.id))
          .take(50)) {
    final image = await _thumbnail(member);
    profiles.add({
      'id': _bounded(member.id, 160),
      'name': _bounded(member.name, 100),
      'role': _bounded(member.role, 1000),
      'description': _bounded(member.note, 16000),
      'colorValue': member.colorValue & 0xffffffff,
      'groups': snapshot.activeGroups
          .where((group) => member.groupIds.contains(group.id))
          .take(50)
          .map(
            (group) => {
              'id': _bounded(group.id, 160),
              'name': _bounded(group.name, 100),
              'colorValue': group.colorValue & 0xffffffff,
            },
          )
          .toList(),
      'imageDataUri': ?image,
    });
  }
  return profiles;
}

String _bounded(String value, int maximum) =>
    value.length > maximum ? value.substring(0, maximum) : value;

Future<String?> _thumbnail(Member member) async {
  final uri = member.profileImageDataUri;
  if (uri == null || uri.length > 28 * 1024 * 1024) return null;
  ui.ImmutableBuffer? buffer;
  ui.ImageDescriptor? descriptor;
  ui.Codec? codec;
  ui.Image? image;
  ui.Picture? picture;
  ui.Image? thumbnail;
  try {
    final data = UriData.parse(uri);
    if (!data.mimeType.startsWith('image/')) return null;
    final Uint8List bytes = data.contentAsBytes();
    if (bytes.length > 20 * 1024 * 1024) return null;
    buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    final downsample = math.min(
      1.0,
      512 / math.max(descriptor.width, descriptor.height),
    );
    codec = await descriptor.instantiateCodec(
      targetWidth: math.max(1, (descriptor.width * downsample).round()),
      targetHeight: math.max(1, (descriptor.height * downsample).round()),
    );
    image = (await codec.getNextFrame()).image;
    final scale = member.profileImageScale.isFinite
        ? member.profileImageScale.clamp(1.0, 3.0)
        : 1.0;
    final x = member.profileImageOffsetX.isFinite
        ? member.profileImageOffsetX.clamp(-1.0, 1.0)
        : 0.0;
    final y = member.profileImageOffsetY.isFinite
        ? member.profileImageOffsetY.clamp(-1.0, 1.0)
        : 0.0;
    const size = 96.0;
    final scaledSize = size * scale;
    final pan = (scaledSize - size) / 2;
    final sourceSize = math.min(image.width, image.height).toDouble();
    final source = ui.Rect.fromLTWH(
      (image.width - sourceSize) * (x + 1) / 2,
      (image.height - sourceSize) * (y + 1) / 2,
      sourceSize,
      sourceSize,
    );
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    // Match AOM's cover, alignment, zoom and pan framing.
    canvas.drawImageRect(
      image,
      source,
      ui.Rect.fromLTWH(-pan + x * pan, -pan + y * pan, scaledSize, scaledSize),
      ui.Paint()..filterQuality = ui.FilterQuality.medium,
    );
    picture = recorder.endRecording();
    thumbnail = await picture.toImage(size.toInt(), size.toInt());
    final encoded = await thumbnail.toByteData(format: ui.ImageByteFormat.png);
    if (encoded == null) return null;
    return 'data:image/png;base64,${base64Encode(encoded.buffer.asUint8List(encoded.offsetInBytes, encoded.lengthInBytes))}';
  } catch (_) {
    // A missing or unreadable photo must not prevent the front update.
    return null;
  } finally {
    thumbnail?.dispose();
    picture?.dispose();
    image?.dispose();
    codec?.dispose();
    descriptor?.dispose();
    buffer?.dispose();
  }
}
