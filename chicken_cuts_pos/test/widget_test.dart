import 'package:chicken_cuts_pos/main.dart';
import 'package:chicken_cuts_pos/services/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders the seeded sell screen', (tester) async {
    final store = Store();
    await store.init();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: store, child: const PosApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chicken Cuts'), findsOneWidget);
    expect(find.text('Sell'), findsWidgets);
    expect(find.text('MAGIC SARAP'), findsOneWidget);
    expect(find.text('Current Sale'), findsOneWidget);
  });
}
