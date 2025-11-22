import 'package:flutter/material.dart';

extension ColorOpacityX on Color {
  Color withOpacityFactor(double opacity) => withValues(
        alpha: (opacity.clamp(0.0, 1.0) * 255).toDouble(),
      );
}

