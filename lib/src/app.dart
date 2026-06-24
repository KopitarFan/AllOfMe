part of '../main.dart';

typedef CloudSaveDeviceRegistrar =
    Future<CloudSaveDeviceRegistration> Function(
      CloudSaveSession session, {
      String? deviceLabel,
    });

Future<CloudSaveDeviceRegistration> _defaultCloudSaveDeviceRegistrar(
  CloudSaveSession session, {
  String? deviceLabel,
}) {
  return RemoteCloudSaveAuthClient(
    baseUrl: session.baseUri,
  ).registerDevice(deviceLabel: deviceLabel);
}

class AllOfMeApp extends StatefulWidget {
  const AllOfMeApp({
    super.key,
    required this.store,
    this.cloudSaveAdapter,
    this.cloudSaveSessionStore = const SharedPreferencesCloudSaveSessionStore(),
    this.cloudSaveTokenStore = const SecureCloudSaveTokenStore(),
    this.cloudSaveDeviceRegistrar,
    this.cloudSavePayloadEncoder,
    this.cloudSavePayloadDecoder,
    this.authenticator = const LocalAppAuthenticator(),
    this.initialThemeMode = ThemeMode.light,
    this.initialThemePalette = AppThemePalette.sage,
  });

  final AppStore store;
  final CloudSaveAdapter? cloudSaveAdapter;
  final CloudSaveSessionStore cloudSaveSessionStore;
  final CloudSaveTokenStore cloudSaveTokenStore;
  final CloudSaveDeviceRegistrar? cloudSaveDeviceRegistrar;
  final CloudSavePayloadEncoder? cloudSavePayloadEncoder;
  final CloudSavePayloadDecoder? cloudSavePayloadDecoder;
  final AppAuthenticator authenticator;
  final ThemeMode initialThemeMode;
  final AppThemePalette initialThemePalette;

  @override
  State<AllOfMeApp> createState() => _AllOfMeAppState();
}

class _AllOfMeAppState extends State<AllOfMeApp> {
  late ThemeMode _themeMode;
  late AppThemePalette _themePalette;
  late CloudSaveAdapter _cloudSaveAdapter;
  CloudSaveSession? _cloudSaveSession;

  bool get _managesCloudSaveAdapter => widget.cloudSaveAdapter == null;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
    _themePalette = widget.initialThemePalette;
    _cloudSaveSession = _managesCloudSaveAdapter
        ? defaultCloudSaveSessionFromEnvironment()
        : null;
    _cloudSaveAdapter =
        widget.cloudSaveAdapter ??
        createCloudSaveAdapterForSession(
          _cloudSaveSession,
          tokenStore: widget.cloudSaveTokenStore,
        );
    _loadThemePreferences();
    _loadCloudSaveSession();
  }

  Future<void> _loadCloudSaveSession() async {
    if (!_managesCloudSaveAdapter) {
      return;
    }
    final storedSession = await widget.cloudSaveSessionStore.load();
    final session = storedSession ?? defaultCloudSaveSessionFromEnvironment();
    if (!mounted) {
      return;
    }
    setState(() {
      _cloudSaveSession = session;
      _cloudSaveAdapter = createCloudSaveAdapterForSession(
        session,
        tokenStore: widget.cloudSaveTokenStore,
      );
    });
  }

  Future<void> _loadThemePreferences() async {
    final preferences = await SharedPreferences.getInstance();
    final storedThemeMode = _themeModeFromPreference(
      preferences.getString(_themeModePreferenceKey),
    );
    final storedThemePalette = _themePaletteFromPreference(
      preferences.getString(_themePalettePreferenceKey),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _themeMode = storedThemeMode ?? _themeMode;
      _themePalette = storedThemePalette ?? _themePalette;
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

  Future<void> _setThemePalette(AppThemePalette palette) async {
    if (_themePalette != palette) {
      setState(() {
        _themePalette = palette;
      });
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themePalettePreferenceKey, palette.id);
  }

  Future<void> _connectCloudSave(CloudSaveConnection connection) async {
    if (!_managesCloudSaveAdapter) {
      return;
    }
    await widget.cloudSaveSessionStore.save(connection.session);
    await widget.cloudSaveTokenStore.save(connection.accessToken);
    if (!mounted) {
      return;
    }
    setState(() {
      _cloudSaveSession = connection.session;
      _cloudSaveAdapter = createCloudSaveAdapterForSession(
        connection.session,
        tokenStore: widget.cloudSaveTokenStore,
      );
    });
  }

  Future<void> _disconnectCloudSave() async {
    if (!_managesCloudSaveAdapter) {
      return;
    }
    await widget.cloudSaveSessionStore.clear();
    await widget.cloudSaveTokenStore.clear();
    if (!mounted) {
      return;
    }
    setState(() {
      _cloudSaveSession = null;
      _cloudSaveAdapter = createCloudSaveAdapterForSession(null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appDisplayName,
      debugShowCheckedModeBanner: false,
      theme: _buildAppTheme(_themePalette, Brightness.light),
      darkTheme: _buildAppTheme(_themePalette, Brightness.dark),
      themeMode: _themeMode,
      home: HomeScreen(
        store: widget.store,
        cloudSaveAdapter: _cloudSaveAdapter,
        cloudSaveSession: _cloudSaveSession,
        onCloudSaveConnect: _managesCloudSaveAdapter ? _connectCloudSave : null,
        onCloudSaveDisconnect: _managesCloudSaveAdapter
            ? _disconnectCloudSave
            : null,
        cloudSaveDeviceRegistrar:
            widget.cloudSaveDeviceRegistrar ?? _defaultCloudSaveDeviceRegistrar,
        cloudSavePayloadEncoder: widget.cloudSavePayloadEncoder,
        cloudSavePayloadDecoder: widget.cloudSavePayloadDecoder,
        authenticator: widget.authenticator,
        themeMode: _themeMode,
        themePalette: _themePalette,
        onThemeModeChanged: _setThemeMode,
        onThemePaletteChanged: _setThemePalette,
        onToggleThemeMode: _toggleThemeMode,
      ),
    );
  }
}

enum AppThemePalette {
  sage(
    id: 'sage',
    label: 'Sage',
    seedColor: Color(0xFF24786D),
    lightScaffold: Color(0xFFF7F8F5),
    darkScaffold: Color(0xFF101816),
  ),
  graphite(
    id: 'graphite',
    label: 'Graphite',
    seedColor: Color(0xFF6B7280),
    lightScaffold: Color(0xFFF5F6F8),
    darkScaffold: Color(0xFF090A0C),
  ),
  black(
    id: 'black',
    label: 'Black',
    seedColor: Color(0xFF9CA3AF),
    lightScaffold: Color(0xFFF6F6F6),
    darkScaffold: Color(0xFF000000),
  ),
  ocean(
    id: 'ocean',
    label: 'Ocean',
    seedColor: Color(0xFF1D70B8),
    lightScaffold: Color(0xFFF3F8FC),
    darkScaffold: Color(0xFF071522),
  ),
  electricBlue(
    id: 'electric_blue',
    label: 'Bright blue',
    seedColor: Color(0xFF0EA5E9),
    lightScaffold: Color(0xFFF0FAFF),
    darkScaffold: Color(0xFF02131E),
  ),
  green(
    id: 'green',
    label: 'Bright green',
    seedColor: Color(0xFF20A75A),
    lightScaffold: Color(0xFFF4FBF5),
    darkScaffold: Color(0xFF07180D),
  ),
  lime(
    id: 'lime',
    label: 'Bright lime',
    seedColor: Color(0xFF84CC16),
    lightScaffold: Color(0xFFFAFFEC),
    darkScaffold: Color(0xFF071200),
  ),
  pink(
    id: 'pink',
    label: 'Bright pink',
    seedColor: Color(0xFFDF4D8C),
    lightScaffold: Color(0xFFFFF6FA),
    darkScaffold: Color(0xFF1D0812),
  ),
  hotPink(
    id: 'hot_pink',
    label: 'Hot pink',
    seedColor: Color(0xFFEC4899),
    lightScaffold: Color(0xFFFFF3FA),
    darkScaffold: Color(0xFF210313),
  ),
  orange(
    id: 'orange',
    label: 'Bright orange',
    seedColor: Color(0xFFF97316),
    lightScaffold: Color(0xFFFFF8EF),
    darkScaffold: Color(0xFF1F0B00),
  ),
  purple(
    id: 'purple',
    label: 'Bright purple',
    seedColor: Color(0xFFA855F7),
    lightScaffold: Color(0xFFFCF6FF),
    darkScaffold: Color(0xFF160421),
  );

  const AppThemePalette({
    required this.id,
    required this.label,
    required this.seedColor,
    required this.lightScaffold,
    required this.darkScaffold,
  });

  final String id;
  final String label;
  final Color seedColor;
  final Color lightScaffold;
  final Color darkScaffold;
}

ThemeData _buildAppTheme(AppThemePalette palette, Brightness brightness) {
  final colorScheme = _appColorScheme(palette, brightness);
  final isDark = brightness == Brightness.dark;

  return ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: isDark
        ? palette.darkScaffold
        : palette.lightScaffold,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
    ),
    useMaterial3: true,
  );
}

ColorScheme _appColorScheme(AppThemePalette palette, Brightness brightness) {
  return ColorScheme.fromSeed(
    seedColor: palette.seedColor,
    brightness: brightness,
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

AppThemePalette? _themePaletteFromPreference(String? value) {
  for (final palette in AppThemePalette.values) {
    if (palette.id == value) {
      return palette;
    }
  }
  return null;
}
