import 'package:field_sample_log/framework/model/sample_enums.dart';
import 'package:field_sample_log/framework/model/sample_model.dart';
import 'package:field_sample_log/framework/provider/sample_form_provider.dart';
import 'package:field_sample_log/ui/utils/theme/app_spacing.dart';
import 'package:field_sample_log/ui/utils/widgets/common_icon.dart';
import 'package:field_sample_log/ui/utils/widgets/common_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SampleFormScreen extends ConsumerStatefulWidget {
  final SampleModel? sample;

  const SampleFormScreen({super.key, this.sample});

  @override
  ConsumerState<SampleFormScreen> createState() => _SampleFormScreenState();
}

class _SampleFormScreenState extends ConsumerState<SampleFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _siteController;
  late TextEditingController _depthController;
  late TextEditingController _phController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final s = widget.sample;

    _siteController = TextEditingController(text: s?.siteName ?? '');
    _depthController = TextEditingController(text: s?.depth?.toString() ?? '');
    _phController = TextEditingController(text: s?.ph?.toString() ?? '');
    _notesController = TextEditingController(text: s?.notes ?? '');

    _siteController.addListener(_markDirty);
    _depthController.addListener(_markDirty);
    _phController.addListener(_markDirty);
    _notesController.addListener(_markDirty);
  }

  void _markDirty() {
    ref.read(sampleFormProvider(widget.sample).notifier).markDirty();
  }

  @override
  void dispose() {
    _siteController.dispose();
    _depthController.dispose();
    _phController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(DateTime currentDateTime) async {
    final date = await showDatePicker(
      context: context,
      initialDate: currentDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date == null) return;

    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(currentDateTime),
    );
    if (time == null) return;

    final newDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    if (newDateTime.isAfter(DateTime.now())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: CommonText(
              data: 'Collection time cannot be in the future.',
            ),
          ),
        );
      }
      return;
    }

    ref
        .read(sampleFormProvider(widget.sample).notifier)
        .updateCollectedAt(newDateTime);
  }

  void _save(SampleStatus targetStatus) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Call the notifier to handle the saving business logic
    ref
        .read(sampleFormProvider(widget.sample).notifier)
        .saveSample(
          siteName: _siteController.text,
          depthStr: _depthController.text,
          phStr: _phController.text,
          notes: _notesController.text,
          targetStatus: targetStatus,
        );

    Navigator.of(context).pop();
  }

  Future<bool> _onWillPop(bool hasUnsavedChanges) async {
    if (!hasUnsavedChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const CommonText(data: 'Unsaved Changes'),
          content: const CommonText(
            data: 'You have unsaved changes. Are you sure you want to discard them?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const CommonText(data: 'Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const CommonText(data: 'Discard'),
            ),
          ],
        );
      },
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.sample != null;

    // Watch the form state for UI updates
    final formState = ref.watch(sampleFormProvider(widget.sample));
    final formNotifier = ref.read(sampleFormProvider(widget.sample).notifier);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop(formState.hasUnsavedChanges);
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: CommonText(data: isEditing ? 'Edit Sample' : 'Add Sample'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Site Name
                TextFormField(
                  controller: _siteController,
                  decoration: const InputDecoration(
                    labelText: 'Site Name *',
                    hintText: 'Enter site name',
                  ),
                  maxLength: 60,
                  validator: formNotifier.validateSite,
                ),
                const SizedBox(height: AppSpacing.medium),

                // Sample Type
                DropdownButtonFormField<SampleType>(
                  initialValue: formState.sampleType,
                  decoration: const InputDecoration(labelText: 'Sample Type *'),
                  items: SampleType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: CommonText(data: type.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      formNotifier.updateSampleType(value);
                      if (value != SampleType.water) {
                        _phController.clear();
                      }
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.medium),

                // Collected At Date/Time
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const CommonText(data: 'Collected At *'),
                  subtitle: CommonText(data: formNotifier.formatDateTime()),
                  trailing: const CommonIcon(icon: Icons.calendar_today),
                  onTap: () => _selectDateTime(formState.collectedAt),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),

                // Depth
                TextFormField(
                  controller: _depthController,
                  decoration: const InputDecoration(
                    labelText: 'Depth (metres)',
                    hintText: 'e.g. 10.5',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: formNotifier.validateDepth,
                ),
                const SizedBox(height: AppSpacing.medium),

                // Conditional pH
                if (formState.sampleType == SampleType.water) ...[
                  TextFormField(
                    controller: _phController,
                    decoration: const InputDecoration(
                      labelText: 'pH *',
                      hintText: '0 to 14',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: formNotifier.validatePh,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                ],

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Enter any additional details',
                  ),
                  maxLines: 4,
                  maxLength: 300,
                ),
                const SizedBox(height: AppSpacing.xLarge),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(
                      onPressed: () => _save(SampleStatus.draft),
                      child: const CommonText(data: 'Save draft'),
                    ),
                    ElevatedButton(
                      onPressed: () => _save(SampleStatus.pending),
                      child: const CommonText(data: 'Save & Queue'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.medium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
