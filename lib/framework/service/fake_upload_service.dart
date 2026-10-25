import 'dart:math';

import 'package:field_sample_log/framework/model/sample_model.dart';

/// Thrown when the fake upload service simulates a network failure.
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

/// A fake service to simulate uploading samples to a server.
class FakeUploadService {
  // Keeps track of the number of calls to simulate a failure every 3rd call.
  int _callCount = 0;

  // Remembers successfully uploaded samples during the current app session.
  // Maps sample ID to the generated receipt ID.
  // It forgets everything when the app restarts, simulating a server reset as per requirements.
  final Map<int, String> _sessionReceipts = {};

  final Random _random = Random();

  /// Uploads a sample and returns a receipt ID.
  ///
  /// - Takes about 2 seconds.
  /// - Throws a network error every 3rd call.
  /// - Idempotent during the same session, calling it again with the same sample ID returns the same receipt.
  Future<String> uploadSample(SampleModel sample) async {
    // 1. Simulate network delay, approx 2 seconds
    // Add a slight randomization to make it feel like a real network call (1800ms - 2200ms)
    final delayMillis = 1800 + _random.nextInt(400);
    await Future.delayed(Duration(milliseconds: delayMillis));

    // We must have an ID to track idempotency/receipts.
    // If somehow a sample without an ID is passed, we throw.
    if (sample.id == null) {
      throw ArgumentError('Cannot upload a sample without an ID.');
    }

    // 2. Increment call count and fail every 3rd call.
    _callCount++;
    if (_callCount % 3 == 0) {
      throw NetworkException('Simulated network failure on call #$_callCount');
    }

    // 3. Idempotency check: if we already generated a receipt for this ID in this session, return it.
    if (_sessionReceipts.containsKey(sample.id)) {
      return _sessionReceipts[sample.id]!;
    }

    // 4. Success! Generate a new receipt ID and save it in the session map.
    final newReceipt =
        'rcpt_${DateTime.now().millisecondsSinceEpoch}_${sample.id}';
    _sessionReceipts[sample.id!] = newReceipt;

    return newReceipt;
  }
}
