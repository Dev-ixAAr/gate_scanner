// Subtle top glow for dark screens — adds depth without hurting OLED contrast.

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Layered background: near-black base + soft brand glow at the top.
class AppScreenBackground extends StatelessWidget {
  const AppScreenBackground({
    super.key,
    required this.child,
    this.showTopGlow = true,
  });

  final Widget child;
  final bool showTopGlow;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.backgroundPrimary),
        if (showTopGlow)
          Positioned(
            top: -80,
            left: -40,
            right: -40,
            height: 280,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.1,
                  colors: [
                    AppColors.brandPrimary.withAlpha(28),
                    AppColors.brandPrimary.withAlpha(8),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
        child,
      ],
    );
  }
}
