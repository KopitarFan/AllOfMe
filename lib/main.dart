import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_lock.dart';
import 'cloud_save.dart';
import 'models.dart';
import 'storage.dart';
import 'storage_factory.dart';

part 'src/app.dart';
part 'src/home_screen.dart';
part 'src/home.dart';
part 'src/insights.dart';
part 'src/members.dart';
part 'src/first_run.dart';
part 'src/forms.dart';
part 'src/recovery.dart';
part 'src/settings.dart';
part 'src/results.dart';
part 'src/shared_helpers.dart';

const String _frontingFilterId = '__fronting';
const String _allGroupsFilterId = '__all';
const String _ungroupedInsightGroupId = '__ungrouped';
const String _sampleInsightsSessionPrefix = 'sample-insights-session-';
const String _themeModePreferenceKey = 'all_of_me.theme_mode';
const String _supportUrl = 'https://kopitarfan.github.io/AllOfMe/support.html';
const String _issuesUrl = 'https://github.com/KopitarFan/AllOfMe/issues';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await createDefaultAppStore();
  runApp(AllOfMeApp(store: store));
}
