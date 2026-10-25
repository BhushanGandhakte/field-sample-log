import 'package:field_sample_log/framework/model/sample_enums.dart';
import 'package:field_sample_log/framework/model/sample_model.dart';
import 'package:field_sample_log/framework/provider/sample_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SampleFormState {
  final SampleType sampleType;
  final DateTime collectedAt;
  final bool hasUnsavedChanges;

  SampleFormState({
    required this.sampleType,
    required this.collectedAt,
    this.hasUnsavedChanges = false,
  });

  SampleFormState copyWith({
    SampleType? sampleType,
    DateTime? collectedAt,
    bool? hasUnsavedChanges,
  }) {
    return SampleFormState(
      sampleType: sampleType ?? this.sampleType,
      collectedAt: collectedAt ?? this.collectedAt,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
    );
  }
}

// A family provider so that we can initialize the state with an existing sample if editing
final sampleFormProvider = NotifierProvider.autoDispose
    .family<SampleFormNotifier, SampleFormState, SampleModel?>(
  (arg) => SampleFormNotifier(arg),
);

class SampleFormNotifier extends Notifier<SampleFormState> {
  final SampleModel? arg;

  SampleFormNotifier(this.arg);
  
  @override
  SampleFormState build() {
    return SampleFormState(
      sampleType: arg?.sampleType ?? SampleType.water,
      collectedAt: arg?.collectedAt ?? DateTime.now(),
      hasUnsavedChanges: false,
    );
  }

  void markDirty() {
    if (!state.hasUnsavedChanges) {
      state = state.copyWith(hasUnsavedChanges: true);
    }
  }

  void updateSampleType(SampleType type) {
    state = state.copyWith(sampleType: type, hasUnsavedChanges: true);
  }

  void updateCollectedAt(DateTime date) {
    state = state.copyWith(collectedAt: date, hasUnsavedChanges: true);
  }

  void saveSample({
    required String siteName,
    required String depthStr,
    required String phStr,
    required String notes,
    required SampleStatus targetStatus,
  }) {
    final newSample = SampleModel(
      id: arg?.id,
      siteName: siteName.trim(),
      sampleType: state.sampleType,
      collectedAt: state.collectedAt,
      depth: double.tryParse(depthStr),
      ph: state.sampleType == SampleType.water ? double.tryParse(phStr) : null,
      notes: notes.trim(),
      status: targetStatus,
    );

    // Call the global list provider to actually persist to the DB and update the app's state
    if (arg == null) {
      ref.read(sampleListProvider.notifier).addSample(newSample);
    } else {
      ref.read(sampleListProvider.notifier).updateSample(newSample);
    }

    state = state.copyWith(hasUnsavedChanges: false);
  }

  String formatDateTime() {
    final dt = state.collectedAt;
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  // --- Validators ---

  String? validateSite(String? value) {
    if (value == null || value.trim().length < 2 || value.trim().length > 60) {
      return 'Site name must be between 2 and 60 characters.';
    }
    return null;
  }

  String? validateDepth(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = double.tryParse(value);
    if (parsed == null) return 'Must be a valid number.';
    if (parsed < 0 || parsed > 100) return 'Depth must be between 0 and 100.';
    final parts = value.split('.');
    if (parts.length > 1 && parts[1].length > 2) {
      return 'Maximum 2 decimal places allowed.';
    }
    return null;
  }

  String? validatePh(String? value) {
    if (state.sampleType != SampleType.water) return null;
    if (value == null || value.trim().isEmpty) {
      return 'pH is required for Water samples.';
    }
    final parsed = double.tryParse(value);
    if (parsed == null) return 'Must be a valid number.';
    if (parsed < 0 || parsed > 14) return 'pH must be between 0 and 14.';
    final parts = value.split('.');
    if (parts.length > 1 && parts[1].length > 2) {
      return 'Maximum 2 decimal places allowed.';
    }
    return null;
  }
}
