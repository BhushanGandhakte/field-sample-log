import 'package:field_sample_log/framework/model/sample_enums.dart';
import 'package:field_sample_log/framework/provider/sample_list_filter_provider.dart';
import 'package:field_sample_log/framework/provider/sample_providers.dart';
import 'package:field_sample_log/framework/provider/upload_providers.dart';
import 'package:field_sample_log/ui/sample/screens/sample_form_screen.dart';
import 'package:field_sample_log/ui/sample/widgets/sample_card.dart';
import 'package:field_sample_log/ui/utils/app_constants/app_constants.dart';
import 'package:field_sample_log/ui/utils/theme/app_spacing.dart';
import 'package:field_sample_log/ui/utils/widgets/common_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SampleListScreen extends ConsumerWidget {
  const SampleListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We watch the filtered list instead of the raw list
    final filteredSamplesAsyncValue = ref.watch(filteredSamplesProvider);

    // We also need the raw list to know the pending count and if the database is truly empty
    final allSamplesAsyncValue = ref.watch(sampleListProvider);

    final currentStatusFilter = ref.watch(statusFilterProvider);

    // Watch the upload queue just so the UI rebuilds if anything changes state during upload
    ref.watch(uploadQueueProvider);

    return Scaffold(
      appBar: AppBar(title: const CommonText(data: AppConstants.appTitle)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search and Filter Area
          Padding(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Full-width Search Bar
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search site name...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    ref.read(searchQueryProvider.notifier).updateQuery(value);
                  },
                ),
                const SizedBox(height: AppSpacing.medium),

                // Horizontally Scrollable Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const CommonText(data: 'All'),
                        selected: currentStatusFilter == null,
                        onSelected: (selected) {
                          if (selected) {
                            ref
                                .read(statusFilterProvider.notifier)
                                .updateStatus(null);
                          }
                        },
                      ),
                      const SizedBox(width: AppSpacing.small),
                      ...SampleStatus.values.map(
                        (status) => Padding(
                          padding: const EdgeInsets.only(
                            right: AppSpacing.small,
                          ),
                          child: ChoiceChip(
                            label: CommonText(data: status.name.toUpperCase()),
                            selected: currentStatusFilter == status,
                            onSelected: (selected) {
                              // If they tap the active one, it clears the filter back to 'All'
                              ref
                                  .read(statusFilterProvider.notifier)
                                  .updateStatus(selected ? status : null);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main List Area
          Expanded(
            child: filteredSamplesAsyncValue.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
              data: (filteredSamples) {
                // If there are no samples at all in the database, show the empty state
                final allSamples = allSamplesAsyncValue.value ?? [];
                if (allSamples.isEmpty) {
                  return _buildEmptyState(context);
                }

                // If samples exist but the filter excluded all of them
                if (filteredSamples.isEmpty) {
                  return const Center(
                    child: Text('No samples match your filters.'),
                  );
                }

                final pendingCount = allSamples
                    .where(
                      (s) =>
                          s.status == SampleStatus.pending ||
                          s.status == SampleStatus.failed,
                    )
                    .length;

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(sampleListProvider.notifier).loadSamples(),
                  child: Column(
                    children: [
                      if (pendingCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.small,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$pendingCount sample(s) pending upload',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.medium),
                              ElevatedButton(
                                onPressed: () {
                                  ref
                                      .read(uploadQueueProvider.notifier)
                                      .uploadAllPending();
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(
                                    0,
                                    36,
                                  ), // slightly smaller button
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                ),
                                child: const CommonText(data: 'Upload All'),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: filteredSamples.length,
                          itemBuilder: (context, index) {
                            return SampleCard(sample: filteredSamples[index]);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add form
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SampleFormScreen()));
        },
        tooltip: 'Add Sample',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.science_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: AppSpacing.medium),
          Text(
            'No samples yet.',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            'Tap + to record your first field sample.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
