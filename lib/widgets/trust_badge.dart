import 'package:flutter/material.dart';

import '../models/trust_score.dart';
import '../theme/app_colors.dart';

/// Circular verification badge that visualises a [TrustScore].
class TrustBadge extends StatelessWidget {
  const TrustBadge({super.key, required this.score, this.size = 160});

  final TrustScore score;
  final double size;

  Color get _color => switch (score.band) {
        TrustBand.high => AppColors.trustHigh,
        TrustBand.medium => AppColors.trustMedium,
        TrustBand.low => AppColors.trustLow,
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: score.value / 100,
                  strokeWidth: 12,
                  backgroundColor: AppColors.divider,
                  valueColor: AlwaysStoppedAnimation(_color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${score.value}',
                    style: TextStyle(
                      fontSize: size * 0.3,
                      fontWeight: FontWeight.bold,
                      color: _color,
                    ),
                  ),
                  Text('/ 100',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: size * 0.09,),),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _color),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified, color: _color, size: 18),
              const SizedBox(width: 6),
              Text(score.band.label,
                  style: TextStyle(color: _color, fontWeight: FontWeight.w600),),
            ],
          ),
        ),
      ],
    );
  }
}
