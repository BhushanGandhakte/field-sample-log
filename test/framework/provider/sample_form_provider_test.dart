import 'package:field_sample_log/framework/model/sample_enums.dart';
import 'package:field_sample_log/framework/provider/sample_form_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ProviderContainer makeProviderContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  group('SampleFormNotifier Validation Tests', () {
    test('validateSite requires 2 to 60 characters', () {
      final container = makeProviderContainer();
      final notifier = container.read(sampleFormProvider(null).notifier);

      expect(
        notifier.validateSite(null),
        'Site name must be between 2 and 60 characters.',
      );
      expect(
        notifier.validateSite('A'),
        'Site name must be between 2 and 60 characters.',
      );
      expect(
        notifier.validateSite('A' * 61),
        'Site name must be between 2 and 60 characters.',
      );
      expect(notifier.validateSite('Valid Site Name'), isNull);
    });

    test('validateDepth accepts null, validates range and decimals', () {
      final container = makeProviderContainer();
      final notifier = container.read(sampleFormProvider(null).notifier);

      expect(notifier.validateDepth(null), isNull); // Optional
      expect(notifier.validateDepth(''), isNull); // Optional
      expect(notifier.validateDepth('abc'), 'Must be a valid number.');
      expect(notifier.validateDepth('-1'), 'Depth must be between 0 and 100.');
      expect(notifier.validateDepth('101'), 'Depth must be between 0 and 100.');
      expect(
        notifier.validateDepth('10.123'),
        'Maximum 2 decimal places allowed.',
      );
      expect(notifier.validateDepth('10.5'), isNull); // Valid
    });

    test(
      'validatePh is only required for Water, validates range and decimals',
      () {
        final container = makeProviderContainer();

        // Test with Water
        final waterNotifier = container.read(sampleFormProvider(null).notifier);
        // Ensure state is Water (default for new sample)
        waterNotifier.updateSampleType(SampleType.water);

        expect(
          waterNotifier.validatePh(null),
          'pH is required for Water samples.',
        );
        expect(
          waterNotifier.validatePh(''),
          'pH is required for Water samples.',
        );
        expect(waterNotifier.validatePh('abc'), 'Must be a valid number.');
        expect(waterNotifier.validatePh('-1'), 'pH must be between 0 and 14.');
        expect(waterNotifier.validatePh('15'), 'pH must be between 0 and 14.');
        expect(
          waterNotifier.validatePh('7.123'),
          'Maximum 2 decimal places allowed.',
        );
        expect(waterNotifier.validatePh('7.5'), isNull);

        // Test with Soil
        final soilNotifier = container.read(sampleFormProvider(null).notifier);
        soilNotifier.updateSampleType(SampleType.soil);
        expect(
          soilNotifier.validatePh(null),
          isNull,
        ); // Should just return null since it's not water
      },
    );

    test('markDirty updates state', () {
      final container = makeProviderContainer();
      final notifier = container.read(sampleFormProvider(null).notifier);

      expect(container.read(sampleFormProvider(null)).hasUnsavedChanges, false);

      notifier.markDirty();

      expect(container.read(sampleFormProvider(null)).hasUnsavedChanges, true);
    });
  });
}
