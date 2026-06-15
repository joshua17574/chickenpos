import 'package:flutter/widgets.dart';

import '../constants/app_constants.dart';

enum FormFactor { phone, tablet, desktop }

/// Helpers to branch tablet master-detail vs. phone stacked layouts.
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  FormFactor get formFactor {
    final w = screenWidth;
    if (w >= Breakpoints.tablet) return FormFactor.desktop;
    if (w >= Breakpoints.phone) return FormFactor.tablet;
    return FormFactor.phone;
  }

  bool get isPhone => formFactor == FormFactor.phone;
  bool get isTabletOrWider => formFactor != FormFactor.phone;
}
