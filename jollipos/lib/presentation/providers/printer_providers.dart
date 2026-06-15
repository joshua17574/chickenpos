import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/printing/receipt_printer.dart';
import '../../data/printing/stub_receipt_printer.dart';

/// Active printer. Replace with a hardware-backed implementation here.
final receiptPrinterProvider =
    Provider<ReceiptPrinter>((ref) => StubReceiptPrinter());
