import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fazlaka_pay/main.dart';

void main() {
  testWidgets('FazlakaApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FazlakaApp());
    await tester.pump();
    expect(find.byType(FazlakaApp), findsOneWidget);
  });
}
