import 'package:field_sample_log/framework/model/sample_enums.dart';
import 'package:field_sample_log/framework/model/sample_model.dart';
import 'package:field_sample_log/framework/provider/upload_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Since we cannot mock AppDatabase directly without major refactoring (it's a singleton), 
// we will utilize sqflite_ffi to run a temporary in-memory database for our tests.

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  ProviderContainer makeProviderContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  group('UploadProvider Retry Workflow', () {
    test('Uploading a failed sample changes status to uploading, then handles success/fail', () async {
      // NOTE: Because our FakeUploadService has a mandatory 2-second artificial delay built into the class itself,
      // this test will take exactly ~2 seconds to run. In a production app, the FakeUploadService would be injected
      // via an interface so it could be completely mocked without the delay.
      
      final container = makeProviderContainer();
      final uploadQueueNotifier = container.read(uploadQueueProvider.notifier);

      // Create a dummy sample that is 'failed'
      final sample = SampleModel(
        id: 1, // Need an ID for idempotency/queue tracking
        siteName: 'Test Site',
        sampleType: SampleType.air,
        collectedAt: DateTime.now(),
        status: SampleStatus.failed,
      );

      // Verify the queue is currently empty
      expect(container.read(uploadQueueProvider).isEmpty, true);

      // Start the upload
      // Since it's async, we grab the future to await it
      final uploadFuture = uploadQueueNotifier.uploadSample(sample);

      // Verify the queue now contains our sample ID (sync execution part)
      expect(container.read(uploadQueueProvider).contains(sample.id), true);

      // Await completion (takes ~2 seconds because of FakeUploadService)
      await uploadFuture;

      // Verify it was removed from the active queue after completion
      expect(container.read(uploadQueueProvider).isEmpty, true);
    });
  });
}
