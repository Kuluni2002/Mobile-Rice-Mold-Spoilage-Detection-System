import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/batch.dart';
import '../../../models/scan_record.dart';
import '../../../services/database_service.dart';
import '../camera/camera_screen.dart';
import '../../widgets/common/scan_details_sheet.dart';
import 'batch_history_screen.dart';

class BatchDetailScreen extends StatefulWidget {
  final String batchId;

  const BatchDetailScreen({super.key, required this.batchId});

  @override
  State<BatchDetailScreen> createState() => _BatchDetailScreenState();
}

class _BatchDetailScreenState extends State<BatchDetailScreen> {
  Batch? _batch;
  List<ScanRecord> _scans = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final batch = await DatabaseService.instance.getBatch(widget.batchId);
      final scans = await DatabaseService.instance.getScansForBatch(widget.batchId);
      if (!mounted) return;
      if (batch == null) {
        setState(() {
          _loading = false;
          _error = 'This batch could not be found.';
        });
        return;
      }
      setState(() {
        _batch = batch;
        _scans = scans;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _errorMessage(error);
      });
    }
  }

  Future<void> _openAndReload(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (mounted) await _loadData();
  }

  Future<void> _deleteBatch() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete batch?'),
        content: const Text('This will also delete all scans saved for this batch.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await DatabaseService.instance.deleteBatch(widget.batchId);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) _showError(_errorMessage(error));
    }
  }

  Future<void> _showScanDetails(ScanRecord scan) async {
    final deleted = await showScanDetailsSheet(context, scan);
    if (deleted == true && mounted) await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Details'),
        actions: [
          IconButton(icon: const Icon(Icons.delete), onPressed: _deleteBatch),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final batch = _batch!;
    final scans = _scans;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(batch.batchNumber, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.grain, 'Variety', batch.variety),
                  _buildInfoRow(Icons.store, 'Source', batch.source),
                  _buildInfoRow(Icons.scale, 'Quantity', batch.quantity == null ? null : '${batch.quantity} kg'),
                  _buildInfoRow(Icons.calendar_today, 'Storage Date', DateFormat.yMd().format(batch.storageDate)),
                  _buildInfoRow(Icons.location_on, 'Location', batch.location),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Current Status', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _buildStatus(scans.isEmpty ? null : scans.first),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Scan History', style: Theme.of(context).textTheme.titleLarge),
              if (scans.isNotEmpty)
                TextButton(
                  onPressed: () => _openAndReload(BatchHistoryScreen(batchId: widget.batchId)),
                  child: const Text('View All'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (scans.isEmpty)
            _buildEmptyState()
          else
            ...scans.take(3).map((scan) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildScanCard(scan),
                )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openAndReload(
                CameraScreen(batchId: widget.batchId),
              ),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Scan This Batch'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatus(ScanRecord? scan) {
    if (scan == null) {
      return _statusContainer(
        color: AppColors.textSecondary,
        child: const Text('Not scanned yet', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      );
    }
    final color = _resultColor(scan.dominantClass);
    return _statusContainer(
      color: color,
      child: Row(
        children: [
          Icon(Icons.check_circle, color: color, size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _resultChip(scan.dominantClass),
              const SizedBox(height: 4),
              Text('Last scanned: ${DateFormat.yMd().add_jm().format(scan.timestamp)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusContainer({required Color color, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: child,
    );
  }

  Widget _buildScanCard(ScanRecord scan) {
    final color = _resultColor(scan.dominantClass);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 52,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.grain, color: color),
        ),
        title: Text(
          DateFormat.yMd().add_jm().format(scan.timestamp),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: _resultChip(scan.dominantClass),
        onTap: () => _showScanDetails(scan),
      ),
    );
  }

  Widget _resultChip(String result) {
    final color = _resultColor(result);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(_resultLabel(result), style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Text('$label:', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(child: Text(value == null || value.isEmpty ? '-' : value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('No scans yet - scan this batch', style: TextStyle(color: AppColors.textSecondary))),
      );

  Widget _buildErrorState() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.spoiled, size: 48),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );

  void _showError(String message) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.spoiled),
      );

  String _errorMessage(Object error) => error.toString().replaceFirst('DatabaseFailure: ', '');

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
