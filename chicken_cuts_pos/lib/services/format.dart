import 'package:intl/intl.dart';

final _peso = NumberFormat.currency(
  locale: 'en_PH',
  symbol: 'PHP ',
  decimalDigits: 2,
);
final _dt = DateFormat('MMM d, y - h:mm a');

String peso(num n) => _peso.format(n);
String formatDate(DateTime d) => _dt.format(d);
