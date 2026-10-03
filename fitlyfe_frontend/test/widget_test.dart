import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitlyfe_frontend/models/food.dart';

void main() {
  group('Widget Tests', () {
    group('Food model', () {
      test('Food.copyWith creates correct copy', () {
        final original = Food(
          id: 'test-1',
          name: 'Original',
          calories: 100,
          protein: 10,
          carbs: 20,
          fats: 5,
          dateAdded: DateTime(2026, 3, 9),
        );

        final copy = original.copyWith(
          name: 'Modified',
          calories: 200,
        );

        expect(copy.id, 'test-1'); // unchanged
        expect(copy.name, 'Modified'); // changed
        expect(copy.calories, 200); // changed
        expect(copy.protein, 10); // unchanged
      });

      test('Food has correct meal type', () {
        final food = Food(
          id: 'test-1',
          name: 'Test',
          calories: 100,
          protein: 10,
          carbs: 20,
          fats: 5,
          dateAdded: DateTime.now(),
          mealType: 'Breakfast',
        );

        expect(food.mealType, 'Breakfast');
      });
    });

    group('Basic Widget Tests', () {
      testWidgets('MaterialApp can be created', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text('FitLyfe Test'),
              ),
            ),
          ),
        );

        expect(find.text('FitLyfe Test'), findsOneWidget);
      });

      testWidgets('Text widget renders correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Text('Calories: 2000'),
                  Text('Protein: 150g'),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Calories: 2000'), findsOneWidget);
        expect(find.text('Protein: 150g'), findsOneWidget);
      });

      testWidgets('Button can be tapped', (WidgetTester tester) async {
        var tapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ElevatedButton(
                onPressed: () => tapped = true,
                child: const Text('Add Food'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Add Food'));
        await tester.pump();

        expect(tapped, true);
      });
    });
  });
}
