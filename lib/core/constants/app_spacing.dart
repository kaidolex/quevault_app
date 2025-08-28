import 'package:flutter/material.dart';

/// App-wide spacing constants for consistent design
class AppSpacing {
  // Base spacing units
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // Common padding values
  static const EdgeInsets paddingXS = EdgeInsets.all(xs);
  static const EdgeInsets paddingSM = EdgeInsets.all(sm);
  static const EdgeInsets paddingMD = EdgeInsets.all(md);
  static const EdgeInsets paddingLG = EdgeInsets.all(lg);
  static const EdgeInsets paddingXL = EdgeInsets.all(xl);
  static const EdgeInsets paddingXXL = EdgeInsets.all(xxl);

  // Horizontal padding
  static const EdgeInsets paddingHorizontalXS = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets paddingHorizontalSM = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets paddingHorizontalMD = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingHorizontalLG = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets paddingHorizontalXL = EdgeInsets.symmetric(horizontal: xl);

  // Vertical padding
  static const EdgeInsets paddingVerticalXS = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets paddingVerticalSM = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets paddingVerticalMD = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets paddingVerticalLG = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets paddingVerticalXL = EdgeInsets.symmetric(vertical: xl);

  // Common margin values
  static const EdgeInsets marginXS = EdgeInsets.all(xs);
  static const EdgeInsets marginSM = EdgeInsets.all(sm);
  static const EdgeInsets marginMD = EdgeInsets.all(md);
  static const EdgeInsets marginLG = EdgeInsets.all(lg);
  static const EdgeInsets marginXL = EdgeInsets.all(xl);
  static const EdgeInsets marginXXL = EdgeInsets.all(xxl);

  // Common spacing widgets (SizedBox)
  static const Widget spacingXS = SizedBox(height: xs, width: xs);
  static const Widget spacingSM = SizedBox(height: sm, width: sm);
  static const Widget spacingMD = SizedBox(height: md, width: md);
  static const Widget spacingLG = SizedBox(height: lg, width: lg);
  static const Widget spacingXL = SizedBox(height: xl, width: xl);
  static const Widget spacingXXL = SizedBox(height: xxl, width: xxl);
  static const Widget spacingXXXL = SizedBox(height: xxxl, width: xxxl);

  // Horizontal spacing widgets
  static const Widget horizontalSpacingXS = SizedBox(width: xs);
  static const Widget horizontalSpacingSM = SizedBox(width: sm);
  static const Widget horizontalSpacingMD = SizedBox(width: md);
  static const Widget horizontalSpacingLG = SizedBox(width: lg);
  static const Widget horizontalSpacingXL = SizedBox(width: xl);

  // Vertical spacing widgets
  static const Widget verticalSpacingXS = SizedBox(height: xs);
  static const Widget verticalSpacingSM = SizedBox(height: sm);
  static const Widget verticalSpacingMD = SizedBox(height: md);
  static const Widget verticalSpacingLG = SizedBox(height: lg);
  static const Widget verticalSpacingXL = SizedBox(height: xl);
  static const Widget verticalSpacingXXL = SizedBox(height: xxl);
  static const Widget verticalSpacingXXXL = SizedBox(height: xxxl);

  // Screen padding (for main content areas)
  static const EdgeInsets screenPadding = EdgeInsets.all(lg);
  static const EdgeInsets screenPaddingHorizontal = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets screenPaddingVertical = EdgeInsets.symmetric(vertical: lg);

  // Card and container spacing
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets containerPadding = EdgeInsets.all(md);
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(horizontal: md, vertical: sm);

  // Form spacing
  static const double formFieldSpacing = lg;
  static const double formSectionSpacing = xl;
  static const EdgeInsets formFieldPadding = EdgeInsets.all(xs);

  // Icon and button spacing
  static const double iconSpacing = sm;
  static const double buttonSpacing = md;
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: md, vertical: sm);

  // Layout constraints
  static const double maxContentWidth = 400.0;
  static const double maxCardWidth = 600.0;
  static const double minTouchTarget = 44.0;

  // Border radius (though not strictly spacing, often used together)
  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;

  // Common BorderRadius values
  static const BorderRadius borderRadiusXS = BorderRadius.all(Radius.circular(radiusXS));
  static const BorderRadius borderRadiusSM = BorderRadius.all(Radius.circular(radiusSM));
  static const BorderRadius borderRadiusMD = BorderRadius.all(Radius.circular(radiusMD));
  static const BorderRadius borderRadiusLG = BorderRadius.all(Radius.circular(radiusLG));
  static const BorderRadius borderRadiusXL = BorderRadius.all(Radius.circular(radiusXL));
}
