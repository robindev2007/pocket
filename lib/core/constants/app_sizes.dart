import 'package:flutter/material.dart';

/// Standard sizes, radius, and spacing tokens used throughout the app.
class AppSizes {
  AppSizes._();

  // Spacing
  static const double p4 = 4.0;
  static const double p8 = 8.0;
  static const double p12 = 12.0;
  static const double p14 = 14.0;
  static const double p16 = 16.0;
  static const double p20 = 20.0;
  static const double p24 = 24.0;
  static const double p32 = 32.0;
  static const double p40 = 40.0;

  // Gap Spacers
  static const SizedBox gapW4 = SizedBox(width: p4);
  static const SizedBox gapW8 = SizedBox(width: p8);
  static const SizedBox gapW10 = SizedBox(width: 10.0);
  static const SizedBox gapW12 = SizedBox(width: p12);
  static const SizedBox gapW16 = SizedBox(width: p16);

  static const SizedBox gapH4 = SizedBox(height: p4);
  static const SizedBox gapH6 = SizedBox(height: 6.0);
  static const SizedBox gapH8 = SizedBox(height: p8);
  static const SizedBox gapH10 = SizedBox(height: 10.0);
  static const SizedBox gapH12 = SizedBox(height: p12);
  static const SizedBox gapH16 = SizedBox(height: p16);
  static const SizedBox gapH20 = SizedBox(height: p20);
  static const SizedBox gapH24 = SizedBox(height: p24);
  static const SizedBox gapH32 = SizedBox(height: p32);

  // Radius
  static const double radiusSm = 6.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusFull = 9999.0;

  static final BorderRadius borderRadiusSm = BorderRadius.circular(radiusSm);
  static final BorderRadius borderRadiusMd = BorderRadius.circular(radiusMd);
  static final BorderRadius borderRadiusLg = BorderRadius.circular(radiusLg);
}
