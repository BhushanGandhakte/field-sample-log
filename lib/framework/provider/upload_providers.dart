import 'package:field_sample_log/framework/model/sample_enums.dart';
import 'package:field_sample_log/framework/model/sample_model.dart';
import 'package:field_sample_log/framework/provider/sample_providers.dart';
import 'package:field_sample_log/framework/service/fake_upload_service.dart';
import 'package:field_sample_log/ui/utils/app_constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provides a singleton instance of the FakeUploadService
final uploadServiceProvider = Provider<FakeUploadService>((ref) {
  return FakeUploadService();
});

// A notifier to manage the uploading queue state
final uploadQueueProvider = NotifierProvider<UploadQueueNotifier, Set<int>>(() {
  return UploadQueueNotifier();
});

class UploadQueueNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() {
    // The state is a set of Sample IDs currently being uploaded.
    return {};
  }

  // Prevents starting an upload if it's already in progress.
  bool _isUploading(int sampleId) => state.contains(sampleId);

  // Uploads a single sample
  Future<void> uploadSample(SampleModel sample) async {
    if (sample.id == null || _isUploading(sample.id!)) {
      return;
    }

    final sampleId = sample.id!;
    final uploadService = ref.read(uploadServiceProvider);
    final listNotifier = ref.read(sampleListProvider.notifier);

    // 1. Mark as currently uploading in memory queue and DB
    state = {...state, sampleId};
    final uploadingSample = sample.copyWith(status: SampleStatus.uploading);
    await listNotifier.updateSample(uploadingSample);

    try {
      // 2. Perform the actual network request
      final receiptId = await uploadService.uploadSample(uploadingSample);

      // 3. On success, mark as uploaded and save receipt
      final successSample = uploadingSample.copyWith(
        status: SampleStatus.uploaded,
        receipt: receiptId,
      );
      await listNotifier.updateSample(successSample);
    } catch (e) {
      AppConstants.showLog('Upload failed for sample $sampleId: $e');

      // 4. On failure, mark as failed
      final failedSample = uploadingSample.copyWith(
        status: SampleStatus.failed,
      );
      await listNotifier.updateSample(failedSample);
    } finally {
      // 5. Always remove from the active upload queue, regardless of outcome
      state = state.where((id) => id != sampleId).toSet();
    }
  }

  // Convenience method to upload all pending samples concurrently
  Future<void> uploadAllPending() async {
    final samplesAsync = ref.read(sampleListProvider);
    if (!samplesAsync.hasValue) return;

    final allSamples = samplesAsync.value!;

    // Find all samples that are either 'pending' or 'failed'
    final pendingSamples = allSamples
        .where(
          (s) =>
              s.status == SampleStatus.pending ||
              s.status == SampleStatus.failed,
        )
        .toList();

    // Trigger all uploads. They will run concurrently and each handles its own DB/State updates.
    for (final sample in pendingSamples) {
      uploadSample(sample);
    }
  }
}
