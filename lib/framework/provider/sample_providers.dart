import 'package:field_sample_log/framework/model/sample_enums.dart';
import 'package:field_sample_log/framework/model/sample_model.dart';
import 'package:field_sample_log/framework/repository/sample_repository.dart';
import 'package:field_sample_log/ui/utils/app_constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Base Providers

// Provides a single, shared instance of our repository.
// This is the bridge between our database and the state management.
final sampleRepositoryProvider = Provider<SampleRepository>((ref) {
  return SampleRepository();
});

// State Providers

// The main state provider that holds our list of samples.
// We use a NotifierProvider to handle loading, saving, and deleting samples,
// so the UI just needs to watch this provider and react to state changes.
final sampleListProvider =
    NotifierProvider<SampleListNotifier, AsyncValue<List<SampleModel>>>(() {
      return SampleListNotifier();
    });

class SampleListNotifier extends Notifier<AsyncValue<List<SampleModel>>> {
  // We use the repository instance directly from the ref when the notifier is built.
  SampleRepository get _repository => ref.read(sampleRepositoryProvider);

  @override
  AsyncValue<List<SampleModel>> build() {
    // When the notifier is created, we return a loading state immediately
    // and trigger the background fetch.
    loadSamples();
    return const AsyncValue.loading();
  }

  // Fetches all samples from the local database and updates the state.
  // As a critical startup step, it also detects any samples that were stuck in the "uploading"
  // state (if the app was killed mid-upload) and automatically recovers them back to "pending".
  Future<void> loadSamples() async {
    state = const AsyncValue.loading();
    try {
      final samples = await _repository.getAllSamples();

      // Look for any samples stuck in 'uploading' due to a previous app kill/crash.
      final stuckUploads = samples
          .where((s) => s.status == SampleStatus.uploading)
          .toList();

      if (stuckUploads.isNotEmpty) {
        // Recover them back to pending so they can be tried again.
        for (final stuck in stuckUploads) {
          final recovered = stuck.copyWith(status: SampleStatus.pending);
          await _repository.updateSample(recovered);
        }

        // Re-fetch the clean list to ensure our memory state perfectly matches the database
        final recoveredSamples = await _repository.getAllSamples();
        state = AsyncValue.data(recoveredSamples);
      } else {
        state = AsyncValue.data(samples);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Adds a new sample to the database and updates the local state list.
  Future<void> addSample(SampleModel sample) async {
    try {
      final id = await _repository.insertSample(sample);
      final newSample = sample.copyWith(id: id);

      // If we already have data loaded, just append the new sample to the front of the list.
      // This saves us from doing a full database read just for one new item.
      if (state.hasValue) {
        state = AsyncValue.data([newSample, ...state.value!]);
      } else {
        // Fallback to reloading everything if our state was somehow empty/error.
        await loadSamples();
      }
    } catch (e) {
      // Re-throw or handle error properly depending on UI requirements.
      // For now, we will just print to console, but a real app might
      // want to broadcast a scaffold messenger error.
      AppConstants.showLog('Error saving sample: $e');
    }
  }

  // Updates an existing sample in the database and the local list.
  Future<void> updateSample(SampleModel sample) async {
    if (sample.id == null) return; // Can't update without an ID!

    try {
      await _repository.updateSample(sample);

      // Swap out the old sample with the new one in our state list.
      if (state.hasValue) {
        final currentSamples = state.value!;
        final index = currentSamples.indexWhere((s) => s.id == sample.id);

        if (index != -1) {
          final updatedList = List<SampleModel>.from(currentSamples);
          updatedList[index] = sample;
          state = AsyncValue.data(updatedList);
        }
      }
    } catch (e) {
      AppConstants.showLog('Error updating sample: $e');
    }
  }

  // Removes a sample from the database and the UI.
  Future<void> deleteSample(int id) async {
    try {
      await _repository.deleteSample(id);

      // Filter out the deleted item from our state list.
      if (state.hasValue) {
        final currentSamples = state.value!;
        state = AsyncValue.data(
          currentSamples.where((s) => s.id != id).toList(),
        );
      }
    } catch (e) {
      AppConstants.showLog('Error deleting sample: $e');
    }
  }
}
