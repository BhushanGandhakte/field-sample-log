import 'package:field_sample_log/framework/model/sample_enums.dart';
import 'package:field_sample_log/ui/utils/theme/app_colors.dart';
import 'package:flutter/material.dart';

class SampleStatusChip extends StatelessWidget {
  final SampleStatus status;

  const SampleStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        _getStatusText(),
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: _getStatusColor(),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }

  String _getStatusText() {
    switch (status) {
      case SampleStatus.draft:
        return 'Draft';
      case SampleStatus.pending:
        return 'Pending upload';
      case SampleStatus.uploading:
        return 'Uploading';
      case SampleStatus.uploaded:
        return 'Uploaded';
      case SampleStatus.failed:
        return 'Upload failed';
    }
  }

  Color _getStatusColor() {
    switch (status) {
      case SampleStatus.draft:
        return AppColors.statusDraft;
      case SampleStatus.pending:
        return AppColors.statusPending;
      case SampleStatus.uploading:
        return AppColors.statusUploading;
      case SampleStatus.uploaded:
        return AppColors.statusUploaded;
      case SampleStatus.failed:
        return AppColors.statusFailed;
    }
  }
}
