import 'package:flutter_test/flutter_test.dart';
import 'package:field_sample_log/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('shows the Field Sample Log empty state', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FieldSampleLogApp()));

    expect(find.text('Field Sample Log'), findsOneWidget);
    expect(find.text('No samples yet'), findsOneWidget);
    expect(find.text('Your field samples will appear here.'), findsOneWidget);
  });
}
