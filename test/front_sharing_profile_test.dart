import 'package:flutter_test/flutter_test.dart';
import 'package:all_of_me_demo/front_sharing_profile.dart';
import 'package:all_of_me_demo/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('shares only current-front profiles and active group labels', () async {
    final snapshot = AppSnapshot.seeded();
    final front = snapshot.members.first;
    final group = snapshot.groups.first;
    final archived = group.copyWith(archived: true);
    final updated = snapshot.copyWith(
      members: [
        front.copyWith(
          role: 'Protector',
          note: 'My description.',
          groupIds: [group.id],
        ),
        ...snapshot.members.skip(1),
      ],
      frontingMemberIds: [front.id],
      groups: [group],
    );
    final profiles = await sharedFrontProfiles(updated);
    expect(profiles, hasLength(1));
    expect(profiles.single['id'], front.id);
    expect(profiles.single['description'], 'My description.');
    expect(profiles.single['role'], 'Protector');
    expect(profiles.single['groups'], [
      {'id': group.id, 'name': group.name, 'colorValue': group.colorValue},
    ]);
    final withoutGroup = await sharedFrontProfiles(
      updated.copyWith(groups: [archived]),
    );
    expect(withoutGroup.single['groups'], isEmpty);
    expect(profiles.single.containsKey('timeline'), isFalse);
    expect(profiles.single.containsKey('profileImageDataUri'), isFalse);
  });

  test('creates a bounded PNG thumbnail and omits malformed images', () async {
    final snapshot = AppSnapshot.seeded();
    final front = snapshot.members.first.copyWith(
      profileImageDataUri:
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    );
    final updated = snapshot.copyWith(
      members: [front],
      frontingMemberIds: [front.id],
    );
    final profiles = await sharedFrontProfiles(updated);
    final uri = UriData.parse(profiles.single['imageDataUri'] as String);
    final bytes = uri.contentAsBytes();
    expect(uri.mimeType, 'image/png');
    expect(bytes.length, lessThan(49500));
    expect(bytes.buffer.asByteData(bytes.offsetInBytes).getUint32(16), 96);
    expect(bytes.buffer.asByteData(bytes.offsetInBytes).getUint32(20), 96);
    final broken = await sharedFrontProfiles(
      updated.copyWith(
        members: [front.copyWith(profileImageDataUri: 'not an image')],
      ),
    );
    expect(broken.single.containsKey('imageDataUri'), isFalse);
    expect(broken.single['name'], front.name);
  });

  test(
    'profile signature ignores private timeline and inactive member edits',
    () {
      final snapshot = AppSnapshot.seeded().copyWith(frontingMemberIds: []);
      expect(sharedFrontProfileSignature(snapshot), '[]');
      expect(
        sharedFrontProfileSignature(snapshot.copyWith(timeline: [])),
        '[]',
      );
    },
  );
}
