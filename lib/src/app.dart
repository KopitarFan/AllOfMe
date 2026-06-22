part of '../main.dart';

class AllOfMeApp extends StatefulWidget {
  const AllOfMeApp({
    super.key,
    required this.store,
    this.cloudSaveAdapter = const SharedPreferencesCloudSaveAdapter(),
    this.cloudSavePayloadEncoder,
    this.cloudSavePayloadDecoder,
    this.authenticator = const LocalAppAuthenticator(),
    this.initialThemeMode = ThemeMode.light,
  });

  final AppStore store;
  final CloudSaveAdapter cloudSaveAdapter;
  final CloudSavePayloadEncoder? cloudSavePayloadEncoder;
  final CloudSavePayloadDecoder? cloudSavePayloadDecoder;
  final AppAuthenticator authenticator;
  final ThemeMode initialThemeMode;

  @override
  State<AllOfMeApp> createState() => _AllOfMeAppState();
}

class _AllOfMeAppState extends State<AllOfMeApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final preferences = await SharedPreferences.getInstance();
    final storedThemeMode = _themeModeFromPreference(
      preferences.getString(_themeModePreferenceKey),
    );
    if (storedThemeMode == null || !mounted) {
      return;
    }
    setState(() {
      _themeMode = storedThemeMode;
    });
  }

  Future<void> _setThemeMode(ThemeMode themeMode) async {
    if (_themeMode != themeMode) {
      setState(() {
        _themeMode = themeMode;
      });
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _themeModePreferenceKey,
      _themeModePreferenceValue(themeMode),
    );
  }

  void _toggleThemeMode() {
    _setThemeMode(
      _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appDisplayName,
      debugShowCheckedModeBanner: false,
      theme: _buildAppTheme(Brightness.light),
      darkTheme: _buildAppTheme(Brightness.dark),
      themeMode: _themeMode,
      home: HomeScreen(
        store: widget.store,
        cloudSaveAdapter: widget.cloudSaveAdapter,
        cloudSavePayloadEncoder: widget.cloudSavePayloadEncoder,
        cloudSavePayloadDecoder: widget.cloudSavePayloadDecoder,
        authenticator: widget.authenticator,
        themeMode: _themeMode,
        onThemeModeChanged: _setThemeMode,
        onToggleThemeMode: _toggleThemeMode,
      ),
    );
  }
}

ThemeData _buildAppTheme(Brightness brightness) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF24786D),
    brightness: brightness,
  );
  final isDark = brightness == Brightness.dark;

  return ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: isDark
        ? const Color(0xFF101816)
        : const Color(0xFFF7F8F5),
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
    ),
    useMaterial3: true,
  );
}

ThemeMode? _themeModeFromPreference(String? value) {
  return switch (value) {
    'dark' => ThemeMode.dark,
    'light' => ThemeMode.light,
    _ => null,
  };
}

String _themeModePreferenceValue(ThemeMode themeMode) {
  return themeMode == ThemeMode.dark ? 'dark' : 'light';
}
