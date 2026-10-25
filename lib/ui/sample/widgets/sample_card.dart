import 'package:field_sample_log/framework/model/sample_model.dart';
import 'package:field_sample_log/ui/sample/screens/sample_detail_screen.dart';
import 'package:field_sample_log/ui/utils/theme/app_spacing.dart';
import 'package:field_sample_log/ui/utils/widgets/common_text.dart';
import 'package:flutter/material.dart';
import 'sample_status_chip.dart';

class SampleCard extends StatelessWidget {
  final SampleModel sample;

  const SampleCard({super.key, required this.sample});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small,
      ),
      child: InkWell(
        onTap: () {
          // Navigate to details passing the selected sample
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SampleDetailScreen(sample: sample),
            ),
          );
        },
        child: ConstrainedBox(
          // Ensures tap target is adequate
          constraints: const BoxConstraints(minHeight: AppSpacing.minTapTarget),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: CommonText(
                        data: sample.siteName,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SampleStatusChip(status: sample.status),
                  ],
                ),
                const SizedBox(height: AppSpacing.small),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CommonText(
                      data: 'Type: ${sample.sampleType.name.toUpperCase()}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    CommonText(
                      data: _formatDate(sample.collectedAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Simple format like "2023-10-27 14:30"
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }
}
