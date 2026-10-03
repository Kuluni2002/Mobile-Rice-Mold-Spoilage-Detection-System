import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';

class DistanceIndicator extends StatelessWidget {
  final double distance; // Distance in cm
  
  const DistanceIndicator({
    super.key,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    final isOptimal = _isOptimalDistance();
    final statusColor = _getDistanceColor();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Distance icon
          Icon(
            Icons.height,
            color: statusColor,
            size: 28,
          ),
          const SizedBox(height: 8),
          
          // Distance value
          Text(
            '${distance.toStringAsFixed(1)} cm',
            style: TextStyle(
              color: statusColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          
          // Status indicator
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isOptimal ? Icons.check_circle : Icons.arrow_upward,
                color: statusColor,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                _getDistanceHint(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Visual scale
          _buildDistanceScale(),
        ],
      ),
    );
  }
  
  bool _isOptimalDistance() {
    return distance >= 25 && distance <= 30;
  }
  
  Color _getDistanceColor() {
    if (distance < 20) {
      return AppColors.spoiled; // Too close
    } else if (distance > 35) {
      return AppColors.spoiled; // Too far
    } else if (distance >= 25 && distance <= 30) {
      return AppColors.healthy; // Optimal
    } else {
      return AppColors.earlyRisk; // Warning range
    }
  }
  
  String _getDistanceHint() {
    if (distance < 20) {
      return 'Move up';
    } else if (distance > 35) {
      return 'Move down';
    } else if (_isOptimalDistance()) {
      return 'Optimal';
    } else {
      return 'Adjust';
    }
  }
  
  Widget _buildDistanceScale() {
    return SizedBox(
      width: 60,
      child: Column(
        children: [
          _buildScaleMarker(35, 'Far', distance > 30),
          const SizedBox(height: 2),
          Container(
            height: 40,
            width: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.spoiled.withOpacity(0.3),
                  AppColors.healthy,
                  AppColors.spoiled.withOpacity(0.3),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Stack(
              children: [
                // Current position indicator
                Positioned(
                  top: _getIndicatorPosition(),
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          _buildScaleMarker(20, 'Close', distance < 25),
        ],
      ),
    );
  }
  
  double _getIndicatorPosition() {
    // Map distance (20-35cm) to position (0-40px)
    final clampedDistance = distance.clamp(20.0, 35.0);
    final normalized = (clampedDistance - 20) / 15; // 0.0 to 1.0
    return (1 - normalized) * 34; // Inverted (far = top, close = bottom)
  }
  
  Widget _buildScaleMarker(double value, String label, bool isActive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${value.toInt()}',
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
            fontSize: 9,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}