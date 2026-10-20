import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/image_quality_checker.dart';

class QualityIndicator extends StatelessWidget {
  final ImageQualityResult result;
  
  const QualityIndicator({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status icon
          Icon(
            _getStatusIcon(),
            color: _getStatusColor(),
            size: 32,
          ),
          const SizedBox(height: 8),
          
          // Status text
          Text(
            _getStatusText(),
            style: TextStyle(
              color: _getStatusColor(),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Individual checks
          _buildCheckItem(
            'Blur',
            !result.isBlurry,
            result.blurScore.toStringAsFixed(1),
          ),
          const SizedBox(height: 4),
          
          _buildCheckItem(
            'Light',
            !result.isTooDark && !result.isTooBright,
            result.brightness.toStringAsFixed(0),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCheckItem(String label, bool isPassed, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isPassed ? Icons.check_circle : Icons.cancel,
          color: isPassed ? AppColors.healthy : AppColors.spoiled,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
  
  Color _getStatusColor() {
    switch (result.status) {
      case ImageQualityStatus.good:
        return AppColors.healthy;
      case ImageQualityStatus.warning:
        return AppColors.earlyRisk;
      case ImageQualityStatus.error:
        return AppColors.spoiled;
    }
  }
  
  IconData _getStatusIcon() {
    switch (result.status) {
      case ImageQualityStatus.good:
        return Icons.check_circle;
      case ImageQualityStatus.warning:
        return Icons.warning;
      case ImageQualityStatus.error:
        return Icons.error;
    }
  }
  
  String _getStatusText() {
    switch (result.status) {
      case ImageQualityStatus.good:
        return 'Ready';
      case ImageQualityStatus.warning:
        return 'Warning';
      case ImageQualityStatus.error:
        return 'Poor';
    }
  }
}