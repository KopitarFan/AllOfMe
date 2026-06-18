part of '../main.dart';

class _FirstRunSetupScreen extends StatefulWidget {
  const _FirstRunSetupScreen({
    required this.initialName,
    required this.themeMode,
    required this.onToggleThemeMode,
    required this.onComplete,
  });

  final String initialName;
  final ThemeMode themeMode;
  final VoidCallback onToggleThemeMode;
  final Future<void> Function(_FirstRunSetupResult result) onComplete;

  @override
  State<_FirstRunSetupScreen> createState() => _FirstRunSetupScreenState();
}

class _FirstRunSetupScreenState extends State<_FirstRunSetupScreen> {
  late final TextEditingController _nameController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String get _systemName {
    final trimmed = _nameController.text.trim();
    return trimmed.isEmpty ? appDisplayName : trimmed;
  }

  Future<void> _complete(_FirstRunAction action) async {
    if (_submitting) {
      return;
    }
    setState(() {
      _submitting = true;
    });

    await widget.onComplete(
      _FirstRunSetupResult(action: action, systemName: _systemName),
    );

    if (mounted) {
      setState(() {
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight > 60
                  ? constraints.maxHeight - 60
                  : 0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton.filledTonal(
                          onPressed: widget.onToggleThemeMode,
                          icon: Icon(
                            widget.themeMode == ThemeMode.dark
                                ? Icons.light_mode_outlined
                                : Icons.dark_mode_outlined,
                          ),
                          tooltip: widget.themeMode == ThemeMode.dark
                              ? 'Switch to light mode'
                              : 'Switch to dark mode',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: colorScheme.primaryContainer,
                              child: Icon(
                                Icons.favorite_outline,
                                size: 34,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Welcome to All Of Me',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'A private place to start gently.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'System name',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) =>
                            _complete(_FirstRunAction.startFresh),
                      ),
                      const SizedBox(height: 16),
                      _SettingsNotice(
                        icon: Icons.cloud_off_outlined,
                        title: 'Local first',
                        message:
                            'This device keeps the main copy. Export, import, and app lock stay optional.',
                      ),
                      const SizedBox(height: 16),
                      _FirstRunChoiceTile(
                        icon: Icons.person_add_alt_1,
                        title: 'Start fresh',
                        subtitle: 'Begin with an empty system.',
                        color: colorScheme.primary,
                        onTap: _submitting
                            ? null
                            : () => _complete(_FirstRunAction.startFresh),
                      ),
                      _FirstRunChoiceTile(
                        icon: Icons.auto_awesome_outlined,
                        title: 'Use demo data',
                        subtitle: 'Explore with sample members and groups.',
                        color: colorScheme.tertiary,
                        onTap: _submitting
                            ? null
                            : () => _complete(_FirstRunAction.useDemoData),
                      ),
                      _FirstRunChoiceTile(
                        icon: Icons.upload_file_outlined,
                        title: 'Import backup',
                        subtitle: 'Restore a JSON backup from this device.',
                        color: colorScheme.secondary,
                        onTap: _submitting
                            ? null
                            : () => _complete(_FirstRunAction.importBackup),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _submitting
                              ? null
                              : () => _complete(_FirstRunAction.startFresh),
                          icon: _submitting
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check),
                          label: Text(
                            _submitting ? 'Setting up' : 'Start fresh',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FirstRunChoiceTile extends StatelessWidget {
  const _FirstRunChoiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minLeadingWidth: 32,
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
