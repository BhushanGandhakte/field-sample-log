import 'package:field_sample_log/ui/utils/app_constants/app_constants.dart';
import 'package:field_sample_log/ui/utils/widgets/common_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: FieldSampleLogApp()));
}

class FieldSampleLogApp extends StatelessWidget {
  const FieldSampleLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: AppConstants.appTitle,
      home: SampleListScreen(),
    );
  }
}

class SampleListScreen extends ConsumerWidget {
  const SampleListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const CommonText(data: AppConstants.appTitle),
      ),
      body: const Center(
        child: CommonText(data: AppConstants.welcomeText),
      ),
    );
  }
}
