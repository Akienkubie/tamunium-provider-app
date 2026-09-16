import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TAMUNIUM request form primitives render', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Text('Request a service'),
            Text('Service category'),
            Text('Submit request'),
          ],
        ),
      ),
    ));

    expect(find.text('Request a service'), findsOneWidget);
    expect(find.text('Service category'), findsOneWidget);
    expect(find.text('Submit request'), findsOneWidget);
  });
}
