part of '../main.dart';

class _FrontSharingPage extends StatefulWidget {
  const _FrontSharingPage({required this.sharing, required this.snapshot});
  final FrontSharing sharing;
  final AppSnapshot snapshot;
  @override
  State<_FrontSharingPage> createState() => _FrontSharingPageState();
}

class _FrontSharingPageState extends State<_FrontSharingPage> {
  Map<String, dynamic>? _settings;
  String? _error;
  String? _invitation;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _run(() async {
      _settings = await widget.sharing.settings();
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (_) {
      if (mounted) {
        _error =
            'Could not reach sharing. Please try again. Changes are not confirmed.';
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final paused = _settings?['paused'] as bool? ?? true;
    final recipients = _settings?['recipients'] as List? ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('Front sharing')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Share your current front with people you choose. Front names and the update time are stored on the sharing service and shown to your recipients. Notes, profiles, and backups are not shared.',
          ),
          const SizedBox(height: 16),
          if (_busy) const LinearProgressIndicator(),
          if (_error != null) ...[
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                      _settings = await widget.sharing.settings();
                    }),
              child: const Text('Retry'),
            ),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Share front updates'),
            subtitle: Text(
              paused
                  ? 'Paused — current front is hidden from recipients'
                  : 'On — front changes are shared automatically',
            ),
            value: !paused,
            onChanged: _busy || _settings == null
                ? null
                : (enabled) => _run(() async {
                    await widget.sharing.setPaused(!enabled, widget.snapshot);
                    _invitation = null;
                    _settings = await widget.sharing.settings();
                  }),
          ),
          if (_settings != null && _settings!['pushConfigured'] == false)
            const Text('Notification delivery has not been configured yet.'),
          const SizedBox(height: 20),
          Text(
            'People with access',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (recipients.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No one is connected yet.'),
            ),
          for (final person in recipients)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(person['label'] as String),
              trailing: TextButton(
                onPressed: _busy
                    ? null
                    : () => _run(() async {
                        await widget.sharing.revoke(person['id'] as String);
                        _settings = await widget.sharing.settings();
                      }),
                child: const Text('Revoke'),
              ),
            ),
          FilledButton.icon(
            icon: const Icon(Icons.person_add_alt),
            label: const Text('Invite someone'),
            onPressed: _busy || _settings == null
                ? null
                : () async {
                    var draftLabel = '';
                    final label = await showDialog<String>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Who are you inviting?'),
                        content: TextField(
                          onChanged: (value) => draftLabel = value,
                          maxLength: 80,
                          autofocus: true,
                          decoration: const InputDecoration(labelText: 'Name'),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              if (draftLabel.trim().isNotEmpty) {
                                Navigator.pop(context, draftLabel.trim());
                              }
                            },
                            child: const Text('Create invitation'),
                          ),
                        ],
                      ),
                    );
                    if (label == null || !mounted) return;
                    await _run(() async {
                      final invitation = await widget.sharing.invite(label);
                      _invitation = invitation['code'] as String;
                      _settings = await widget.sharing.settings();
                    });
                  },
          ),
          if (_invitation != null) ...[
            const SizedBox(height: 16),
            const Text(
              'Enter this one-time code in the companion app within 10 minutes. Creating another invitation replaces this one.',
            ),
            const SizedBox(height: 8),
            SelectableText(_invitation!),
            TextButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Copy invitation'),
              onPressed: () =>
                  Clipboard.setData(ClipboardData(text: _invitation!)),
            ),
          ],
        ],
      ),
    );
  }
}
