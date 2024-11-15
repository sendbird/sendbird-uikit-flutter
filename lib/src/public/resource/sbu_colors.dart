// Copyright (c) 2024 Sendbird, Inc. All rights reserved.

import 'dart:ui';

/// SBUColors
class SBUColors {
  static Color primaryExtraDark = const Color(0xFF491389); // Primary-500
  static Color primaryDark = const Color(0xFF6211C8); // Primary-400
  static Color primaryMain = const Color(0xFF742DDD); // Primary-300
  static Color primaryLight = const Color(0xFFC2A9FA); // Primary-200
  static Color primaryExtraLight = const Color(0xFFDBD1FF); // Primary-100

  static Color secondaryExtraDark = const Color(0xFF066858); // Secondary-500
  static Color secondaryDark = const Color(0xFF027D69); // Secondary-400
  static Color secondaryMain = const Color(0xFF259C72); // Secondary-300
  static Color secondaryLight = const Color(0xFF69C085); // Secondary-200
  static Color secondaryExtraLight = const Color(0xFFA8E2AB); // Secondary-100

  static Color errorExtraDark = const Color(0xFF9D091E); // Error-500
  static Color errorDark = const Color(0xFFBF0711); // Error-400
  static Color errorMain = const Color(0xFFDE360B); // Error-300
  static Color errorLight = const Color(0xFFF66161); // Error-200
  static Color errorExtraLight = const Color(0xFFFDAAAA); // Error-100

  static Color background700 = const Color(0xFF000000);
  static Color background600 = const Color(0xFF161616);
  static Color background500 = const Color(0xFF2C2C2C);
  static Color background400 = const Color(0xFF393939);
  static Color background300 = const Color(0xFFBDBDBD);
  static Color background200 = const Color(0xFFE0E0E0);
  static Color background100 = const Color(0xFFEEEEEE);
  static Color background50 = const Color(0xFFFFFFFF);

  static Color overlayDark = const Color(0x8C000000); // Overlay-01
  static Color overlayLight = const Color(0x52161616); // Overlay-02

  static Color informationExtraDark = const Color(0xFF241389); // Info-500
  static Color informationDark = const Color(0xFF362CA9); // Info-400
  static Color informationMain = const Color(0xFF4A48CD); // Info-300
  static Color informationLight = const Color(0xFFA9BBFA); // Info-200
  static Color informationExtraLight = const Color(0xFFD1DBFF); // Info-100

  static Color highlight = const Color(0xFFFFF2B6);

  static Color lightThemeTextHighEmphasis = const Color(0xE0000000); // Light-01
  static Color lightThemeTextMidEmphasis = const Color(0x80000000); // Light-02
  static Color lightThemeTextLowEmphasis = const Color(0x61000000); // Light-03
  static Color lightThemeTextDisabled = const Color(0x1F000000); // Light-04

  static Color darkThemeTextHighEmphasis = const Color(0xE0FFFFFF); // Dark-01
  static Color darkThemeTextMidEmphasis = const Color(0x80FFFFFF); // Dark-02
  static Color darkThemeTextLowEmphasis = const Color(0x61FFFFFF); // Dark-03
  static Color darkThemeTextDisabled = const Color(0x1FFFFFFF); // Dark-04

  /// Sets colors.
  static void setColors({
    required Color primaryExtraDark,
    required Color primaryDark,
    required Color primaryMain,
    required Color primaryLight,
    required Color primaryExtraLight,
    required Color secondaryExtraDark,
    required Color secondaryDark,
    required Color secondaryMain,
    required Color secondaryLight,
    required Color secondaryExtraLight,
    required Color errorExtraDark,
    required Color errorDark,
    required Color errorMain,
    required Color errorLight,
    required Color errorExtraLight,
    required Color background700,
    required Color background600,
    required Color background500,
    required Color background400,
    required Color background300,
    required Color background200,
    required Color background100,
    required Color background50,
    required Color overlayDark,
    required Color overlayLight,
    required Color informationExtraDark,
    required Color informationDark,
    required Color informationMain,
    required Color informationLight,
    required Color informationExtraLight,
    required Color highlight,
    required Color lightThemeTextHighEmphasis,
    required Color lightThemeTextMidEmphasis,
    required Color lightThemeTextLowEmphasis,
    required Color lightThemeTextDisabled,
    required Color darkThemeTextHighEmphasis,
    required Color darkThemeTextMidEmphasis,
    required Color darkThemeTextLowEmphasis,
    required Color darkThemeTextDisabled,
  }) {
    SBUColors.primaryExtraDark = primaryExtraDark;
    SBUColors.primaryDark = primaryDark;
    SBUColors.primaryMain = primaryMain;
    SBUColors.primaryLight = primaryLight;
    SBUColors.primaryExtraLight = primaryExtraLight;
    SBUColors.secondaryExtraDark = secondaryExtraDark;
    SBUColors.secondaryDark = secondaryDark;
    SBUColors.secondaryMain = secondaryMain;
    SBUColors.secondaryLight = secondaryLight;
    SBUColors.secondaryExtraLight = secondaryExtraLight;
    SBUColors.errorExtraDark = errorExtraDark;
    SBUColors.errorDark = errorDark;
    SBUColors.errorMain = errorMain;
    SBUColors.errorLight = errorLight;
    SBUColors.errorExtraLight = errorExtraLight;
    SBUColors.background700 = background700;
    SBUColors.background600 = background600;
    SBUColors.background500 = background500;
    SBUColors.background400 = background400;
    SBUColors.background300 = background300;
    SBUColors.background200 = background200;
    SBUColors.background100 = background100;
    SBUColors.background50 = background50;
    SBUColors.overlayDark = overlayDark;
    SBUColors.overlayLight = overlayLight;
    SBUColors.informationExtraDark = informationExtraDark;
    SBUColors.informationDark = informationDark;
    SBUColors.informationMain = informationMain;
    SBUColors.informationLight = informationLight;
    SBUColors.informationExtraLight = informationExtraLight;
    SBUColors.highlight = highlight;
    SBUColors.lightThemeTextHighEmphasis = lightThemeTextHighEmphasis;
    SBUColors.lightThemeTextMidEmphasis = lightThemeTextMidEmphasis;
    SBUColors.lightThemeTextLowEmphasis = lightThemeTextLowEmphasis;
    SBUColors.lightThemeTextDisabled = lightThemeTextDisabled;
    SBUColors.darkThemeTextHighEmphasis = darkThemeTextHighEmphasis;
    SBUColors.darkThemeTextMidEmphasis = darkThemeTextMidEmphasis;
    SBUColors.darkThemeTextLowEmphasis = darkThemeTextLowEmphasis;
    SBUColors.darkThemeTextDisabled = darkThemeTextDisabled;
  }
}
