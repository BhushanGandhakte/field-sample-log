import 'package:field_sample_log/ui/sample/screens/sample_list_screen.dart';
import 'package:field_sample_log/ui/utils/app_constants/app_constants.dart';
import 'package:field_sample_log/ui/utils/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: FieldSampleLogApp()));
}

class FieldSampleLogApp extends StatelessWidget {
  const FieldSampleLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appTitle,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      // Uses the system theme by default
      themeMode: ThemeMode.system, 
      home: const SampleListScreen(),
    );
  }
}
