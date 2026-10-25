import 'package:field_sample_log/framework/model/sample_enums.dart';
import 'package:field_sample_log/framework/model/sample_model.dart';
import 'package:field_sample_log/framework/provider/sample_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// State Notifiers for Filters

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String query) {
    state = query.toLowerCase();
  }
}

class StatusFilterNotifier extends Notifier<SampleStatus?> {
  @override
  SampleStatus? build() => null;

  void updateStatus(SampleStatus? status) {
    state = status;
  }
}

// Providers

// Exposes the search text query
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

// Exposes the selected status filter
final statusFilterProvider =
    NotifierProvider<StatusFilterNotifier, SampleStatus?>(
      StatusFilterNotifier.new,
    );

// Computed Provider

// Reactively combines the raw samples list with the selected filters.
// By doing this here, the UI doesn't have to perform any business logic!
final filteredSamplesProvider = Provider<AsyncValue<List<SampleModel>>>((ref) {
  final samplesAsyncValue = ref.watch(sampleListProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  final statusFilter = ref.watch(statusFilterProvider);

  return samplesAsyncValue.whenData((samples) {
    return samples.where((sample) {
      final matchesSearch = sample.siteName.toLowerCase().contains(searchQuery);
      final matchesFilter =
          statusFilter == null || sample.status == statusFilter;
      return matchesSearch && matchesFilter;
    }).toList();
  });
});
