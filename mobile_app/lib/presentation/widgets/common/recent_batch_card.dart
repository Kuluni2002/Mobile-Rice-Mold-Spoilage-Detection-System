import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/batch.dart';

class RecentBatchCard extends StatelessWidget {
  final Batch batch;
  final VoidCallback onTap;
  
  const RecentBatchCard({
    super.key,
    required this.batch,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      batch.batchNumber,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _resultColor(batch.latestResult).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _resultLabel(batch.latestResult),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _resultColor(batch.latestResult),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              if (batch.variety != null)
                Row(
                  children: [
                    Icon(Icons.grain, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      batch.variety!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              
              const SizedBox(height: 4),
              
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Stored: ${_formatDate(batch.storageDate)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return DateFormat.yMd().format(date.toLocal());
  }

  String _resultLabel(String? result) {
    switch (result) {
      case 'early_risk':
        return 'Early risk';
      case 'spoiled':
        return 'Spoiled';
      case 'healthy':
        return 'Healthy';
      default:
        return 'Not scanned';
    }
  }

  Color _resultColor(String? result) {
    switch (result) {
      case 'early_risk':
        return AppColors.earlyRisk;
      case 'spoiled':
        return AppColors.spoiled;
      case 'healthy':
        return AppColors.healthy;
      default:
        return AppColors.textSecondary;
    }
  }
}