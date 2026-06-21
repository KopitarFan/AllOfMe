part of '../main.dart';

class AllOfMeApp extends StatefulWidget {
  const AllOfMeApp({
    super.key,
    required this.store,
    this.authenticator = const LocalAppAuthenticator(),
    this.initialThemeMode = ThemeMode.light,
    this.initialThemePaletteId = _defaultThemePaletteId,
  });

  final AppStore store;
  final AppAuthenticator authenticator;
  final ThemeMode initialThemeMode;
  final String initialThemePaletteId;

  @override
  State<AllOfMeApp> createState() => _AllOfMeAppState();
}

class _AllOfMeAppState extends State<AllOfMeApp> {
  late ThemeMode _themeMode;
  late AppThemePalette _themePalette;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
    _themePalette = _themePaletteForId(widget.initialThemePaletteId);
    _loadAppearancePreferences();
  }

  Future<void> _loadAppearancePreferences() async {
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

  Future<void> _setThemePalette(AppThemePalette themePalette) async {
    if (_themePalette.id != themePalette.id) {
      setState(() {
        _themePalette = themePalette;
      });
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themePalettePreferenceKey, themePalette.id);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appDisplayName,
      debugShowCheckedModeBanner: false,
      theme: _buildAppTheme(Brightness.light, _themePalette),
      darkTheme: _buildAppTheme(Brightness.dark, _themePalette),
      themeMode: _themeMode,
      home: HomeScreen(
        store: widget.store,
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

ThemeData _buildAppTheme(Brightness brightness, AppThemePalette themePalette) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: themePalette.seedColor,
    brightness: brightness,
  );
  final isDark = brightness == Brightness.dark;

  return ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: isDark
        ? colorScheme.surface
        : colorScheme.surfaceContainerLowest,
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

const String _defaultThemePaletteId = 'evergreen';

class AppThemePalette {
  const AppThemePalette({
    required this.id,
    required this.name,
    required this.seedColor,
    required this.description,
    this.previewColors,
  });

  final String id;
  final String name;
  final Color seedColor;
  final String description;
  final List<Color>? previewColors;
}

const List<AppThemePalette> _themePalettes = [
  AppThemePalette(
    id: _defaultThemePaletteId,
    name: 'Evergreen',
    seedColor: Color(0xFF24786D),
    description: 'Calm green and teal',
  ),
  AppThemePalette(
    id: 'ocean',
    name: 'Ocean',
    seedColor: Color(0xFF2F80A0),
    description: 'Clear blue and aqua',
  ),
  AppThemePalette(
    id: 'violet',
    name: 'Violet',
    seedColor: Color(0xFF6D5BD0),
    description: 'Soft violet accents',
  ),
  AppThemePalette(
    id: 'rose',
    name: 'Rose',
    seedColor: Color(0xFFB64B6B),
    description: 'Warm rose highlights',
  ),
  AppThemePalette(
    id: 'amber',
    name: 'Amber',
    seedColor: Color(0xFFE0A11B),
    description: 'Golden and bright',
  ),
  AppThemePalette(
    id: 'forest',
    name: 'Forest',
    seedColor: Color(0xFF4F6F52),
    description: 'Grounded natural green',
  ),
  AppThemePalette(
    id: 'graphite',
    name: 'Graphite',
    seedColor: Color(0xFF202124),
    description: 'Dark black and grey',
    previewColors: [
      Color(0xFF050505),
      Color(0xFF1A1A1A),
      Color(0xFF5F6368),
      Color(0xFFDADCE0),
    ],
  ),
  AppThemePalette(
    id: 'bright-green',
    name: 'Bright Green',
    seedColor: Color(0xFF00C853),
    description: 'Vivid green accents',
    previewColors: [
      Color(0xFF00C853),
      Color(0xFF2EFF7B),
      Color(0xFF00A846),
      Color(0xFFB9FFD0),
    ],
  ),
  AppThemePalette(
    id: 'hot-pink',
    name: 'Hot Pink',
    seedColor: Color(0xFFFF2D95),
    description: 'Bright pink accents',
    previewColors: [
      Color(0xFFFF2D95),
      Color(0xFFFF5CB3),
      Color(0xFFD9006C),
      Color(0xFFFFC1DE),
    ],
  ),
  AppThemePalette(
    id: 'electric-blue',
    name: 'Electric Blue',
    seedColor: Color(0xFF008CFF),
    description: 'Bright blue accents',
    previewColors: [
      Color(0xFF008CFF),
      Color(0xFF47B6FF),
      Color(0xFF006AD1),
      Color(0xFFC2E7FF),
    ],
  ),
  AppThemePalette(
    id: 'citrus',
    name: 'Citrus',
    seedColor: Color(0xFFFF6D00),
    description: 'Bright orange accents',
    previewColors: [
      Color(0xFFFF6D00),
      Color(0xFFFFA726),
      Color(0xFFE65100),
      Color(0xFFFFD180),
    ],
  ),
  AppThemePalette(
    id: 'solar',
    name: 'Solar',
    seedColor: Color(0xFFFFC400),
    description: 'Bright yellow accents',
    previewColors: [
      Color(0xFFFFC400),
      Color(0xFFFFE082),
      Color(0xFFD99A00),
      Color(0xFFFFF4B8),
    ],
  ),
];

AppThemePalette _themePaletteForId(String id) {
  return _themePalettes.firstWhere(
    (themePalette) => themePalette.id == id,
    orElse: () => _themePalettes.first,
  );
}

AppThemePalette? _themePaletteFromPreference(String? value) {
  if (value == null) {
    return null;
  }
  return _themePaletteForId(value);
}
