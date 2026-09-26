import 'package:fitlyfe_frontend/providers/translation_provider.dart';
import 'package:fitlyfe_frontend/screens/ai_assistant_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets(
    'the AI coach is presented as coming soon, not as a working chat',
    (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => TranslationProvider(),
          child: const MaterialApp(home: AIAssistantPage()),
        ),
      );

      expect(find.text('COMING SOON'), findsOneWidget);
      expect(find.text('Your AI coach is on its way'), findsOneWidget);
      // No input to type a question into, so nothing can get a canned reply
      expect(find.byType(TextField), findsNothing);
    },
  );
}
