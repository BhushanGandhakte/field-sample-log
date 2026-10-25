import 'package:field_sample_log/framework/model/sample_enums.dart';
import 'package:field_sample_log/framework/model/sample_model.dart';
import 'package:field_sample_log/framework/provider/sample_providers.dart';
import 'package:field_sample_log/ui/sample/screens/sample_form_screen.dart';
import 'package:field_sample_log/ui/sample/widgets/sample_status_chip.dart';
import 'package:field_sample_log/ui/utils/theme/app_spacing.dart';
import 'package:field_sample_log/ui/utils/widgets/common_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SampleDetailScreen extends ConsumerWidget {
  final SampleModel sample;

  const SampleDetailScreen({super.key, required this.sample});

  String _formatDateTime(DateTime dt) {
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const CommonText(data: 'Delete Sample'),
        content: const CommonText(
          data: 'Are you sure you want to delete this sample? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const CommonText(data: 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (sample.id != null) {
                ref.read(sampleListProvider.notifier).deleteSample(sample.id!);
              }
              Navigator.of(ctx).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to list
            },
            child: const CommonText(data: 'Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We watch the list provider so that if this sample gets updated (e.g. from the edit screen),
    // the detail screen automatically refreshes with the new data.
    final samples = ref.watch(sampleListProvider).value ?? [];
    
    // Find our current sample from the state to ensure we always display the latest data
    final currentSample = samples.firstWhere(
      (s) => s.id == sample.id,
      orElse: () => sample,
    );

    final canDelete = currentSample.status != SampleStatus.uploaded;

    return Scaffold(
      appBar: AppBar(
        title: const CommonText(data: 'Sample Details'),
        actions: [
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, ref),
              tooltip: 'Delete Sample',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CommonText(
                    data: currentSample.siteName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                SampleStatusChip(status: currentSample.status),
              ],
            ),
            const SizedBox(height: AppSpacing.large),

            // Details section
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.medium),
                child: Column(
                  children: [
                    _DetailRow(
                      label: 'Sample Type',
                      value: currentSample.sampleType.name.toUpperCase(),
                    ),
                    const Divider(),
                    _DetailRow(
                      label: 'Collected At',
                      value: _formatDateTime(currentSample.collectedAt),
                    ),
                    if (currentSample.depth != null) ...[
                      const Divider(),
                      _DetailRow(
                        label: 'Depth',
                        value: '${currentSample.depth} metres',
                      ),
                    ],
                    if (currentSample.ph != null) ...[
                      const Divider(),
                      _DetailRow(
                        label: 'pH',
                        value: currentSample.ph.toString(),
                      ),
                    ],
                    if (currentSample.receipt != null) ...[
                      const Divider(),
                      _DetailRow(
                        label: 'Receipt ID',
                        value: currentSample.receipt!,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            if (currentSample.notes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.large),
              CommonText(
                data: 'Notes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.small),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.medium),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CommonText(data: currentSample.notes),
              ),
            ],
            
            const SizedBox(height: AppSpacing.xLarge),

            // Action Buttons Based on Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (currentSample.status != SampleStatus.uploaded)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.small),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SampleFormScreen(sample: currentSample),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit),
                        label: const CommonText(data: 'Edit'),
                      ),
                    ),
                  ),
                
                if (currentSample.status == SampleStatus.failed)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.small),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Update status to pending for retry
                          final retrySample = currentSample.copyWith(
                            status: SampleStatus.pending
                          );
                          ref.read(sampleListProvider.notifier).updateSample(retrySample);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const CommonText(data: 'Retry Upload'),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CommonText(
            data: label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
          ),
          CommonText(
            data: value,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
