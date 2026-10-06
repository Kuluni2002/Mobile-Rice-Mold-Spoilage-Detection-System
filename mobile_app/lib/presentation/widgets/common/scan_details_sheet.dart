import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/scan_record.dart';
import '../../../services/database_service.dart';

Future<bool?> showScanDetailsSheet(BuildContext context, ScanRecord scan) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ScanDetailsSheet(scan: scan),
  );
}

class _ScanDetailsSheet extends StatefulWidget {
  final ScanRecord scan;

  const _ScanDetailsSheet({required this.scan});

  @override
  State<_ScanDetailsSheet> createState() => _ScanDetailsSheetState();
}

class _ScanDetailsSheetState extends State<_ScanDetailsSheet> {
  bool _deleting = false;

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete scan?'),
        content: const Text('This saved scan will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || widget.scan.id == null) return;
    setState(() => _deleting = true);
    try {
      await DatabaseService.instance.deleteScan(widget.scan.id!);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete scan: $error'), backgroundColor: AppColors.spoiled),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scan = widget.scan;
    final imagePath = scan.imagePath;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Scan Details', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat.yMd().add_jm().format(scan.timestamp),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                IconButton(
                  tooltip: 'Delete scan',
                  onPressed: _deleting ? null : _delete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (imagePath != null && File(imagePath).existsSync())
              Card(
                clipBehavior: Clip.antiAlias,
                margin: EdgeInsets.zero,
                child: Image.file(File(imagePath), height: 180, width: double.infinity, fit: BoxFit.cover),
              )
            else
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Icon(Icons.image_not_supported, size: 48, color: AppColors.textSecondary),
              ),
            const SizedBox(height: 16),
            _statusPanel(scan),
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Grain composition', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 14),
                    _countRow('Healthy', scan.healthyCount, scan.healthyPercentage, AppColors.healthy),
                    _countRow('Early risk', scan.earlyRiskCount, scan.earlyRiskPercentage, AppColors.earlyRisk),
                    _countRow('Spoiled', scan.spoiledCount, scan.spoiledPercentage, AppColors.spoiled),
                    const Divider(height: 20),
                    Text('Total grains: ${scan.totalGrains}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            if (scan.recommendation != null && scan.recommendation!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                margin: EdgeInsets.zero,
                color: AppColors.primary.withOpacity(0.06),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lightbulb_outline, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            scan.recommendationSource == 'ai' ? 'AI' : 'Offline guidance',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(scan.recommendation!),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusPanel(ScanRecord scan) {
    final color = _resultColor(scan.dominantClass);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: color, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Scan result',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          _resultChip(scan.dominantClass),
        ],
      ),
    );
  }

  Widget _countRow(String label, int count, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600))),
          Text('$count grains (${percentage.toStringAsFixed(1)}%)'),
        ],
      ),
    );
  }

  Widget _resultChip(String result) {
    final color = _resultColor(result);
    return Chip(
      label: Text(_resultLabel(result)),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      backgroundColor: color.withOpacity(0.1),
    );
  }

  String _resultLabel(String result) {
    switch (result) {
      case AppConstants.classHealthy:
        return 'Healthy';
      case AppConstants.classEarlyRisk:
        return 'Early risk';
      case AppConstants.classSpoiled:
        return 'Spoiled';
      default:
        return result;
    }
  }

  Color _resultColor(String result) {
    switch (result) {
      case AppConstants.classHealthy:
        return AppColors.healthy;
      case AppConstants.classEarlyRisk:
        return AppColors.earlyRisk;
      case AppConstants.classSpoiled:
        return AppColors.spoiled;
      default:
        return AppColors.textSecondary;
    }
  }
}
