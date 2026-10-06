import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/batch.dart';
import '../../../models/scan_record.dart';
import '../../../services/database_service.dart';
import '../../widgets/common/scan_details_sheet.dart';

class BatchHistoryScreen extends StatefulWidget {
  final String batchId;

  const BatchHistoryScreen({super.key, required this.batchId});

  @override
  State<BatchHistoryScreen> createState() => _BatchHistoryScreenState();
}

class _BatchHistoryScreenState extends State<BatchHistoryScreen> {
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
        _error = error.toString().replaceFirst('DatabaseFailure: ', '');
      });
    }
  }

  Future<void> _showDetails(ScanRecord scan) async {
    final deleted = await showScanDetailsSheet(context, scan);
    if (deleted == true && mounted) await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_batch?.batchNumber ?? 'Batch History')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _scans.isEmpty
                  ? _buildEmptyState()
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    final oldestFirst = _scans.reversed.toList();
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text('Quality Trend', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(height: 220, child: LineChart(_buildChartData(oldestFirst))),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    children: [
                      _buildLegendItem('Healthy', AppColors.healthy),
                      _buildLegendItem('Early risk', AppColors.earlyRisk),
                      _buildLegendItem('Spoiled', AppColors.spoiled),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_scans.length == 1)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('Scan this batch again to see how it changes over time', style: TextStyle(color: AppColors.textSecondary)),
            ),
          const SizedBox(height: 24),
          Text('Statistics', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatisticCard(
                title: 'Total Scans',
                value: '${_scans.length}',
                icon: Icons.camera_alt_outlined,
                color: AppColors.primary,
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildStatisticCard(
                title: 'Days in Storage',
                value: '${DateTime.now().difference(_batch!.storageDate).inDays}',
                icon: Icons.calendar_today_outlined,
                color: AppColors.earlyRisk,
              )),
            ],
          ),
          const SizedBox(height: 24),
          Text('All Scans', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ..._scans.map((scan) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildScanCard(scan),
              )),
        ],
      ),
    );
  }

  LineChartData _buildChartData(List<ScanRecord> scans) {
    return LineChartData(
      minX: 0,
      maxX: scans.length == 1 ? 1 : (scans.length - 1).toDouble(),
      minY: 0,
      maxY: 100,
      gridData: const FlGridData(show: true),
      borderData: FlBorderData(show: true),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: scans.length == 1 ? 1 : null,
            getTitlesWidget: (value, meta) {
              final index = value.round();
              if (index < 0 || index >= scans.length || value != index) return const SizedBox.shrink();
              return Text(DateFormat('d MMM').format(scans[index].timestamp), style: const TextStyle(fontSize: 10));
            },
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (spots) {
            final index = spots.first.x.round();
            if (index < 0 || index >= scans.length) return [];
            final scan = scans[index];
            return [
              LineTooltipItem(
                '${DateFormat.yMd().add_jm().format(scan.timestamp)}\n'
                'Healthy: ${scan.healthyPercentage.toStringAsFixed(1)}%\n'
                'Early risk: ${scan.earlyRiskPercentage.toStringAsFixed(1)}%\n'
                'Spoiled: ${scan.spoiledPercentage.toStringAsFixed(1)}%',
                const TextStyle(color: Colors.white),
              ),
            ];
          },
        ),
      ),
      lineBarsData: [
        _line(scans, (scan) => scan.healthyPercentage, AppColors.healthy),
        _line(scans, (scan) => scan.earlyRiskPercentage, AppColors.earlyRisk),
        _line(scans, (scan) => scan.spoiledPercentage, AppColors.spoiled),
      ],
    );
  }

  LineChartBarData _line(List<ScanRecord> scans, double Function(ScanRecord) value, Color color) {
    return LineChartBarData(
      spots: [
        for (var i = 0; i < scans.length; i++) FlSpot(i.toDouble(), value(scans[i])),
      ],
      color: color,
      barWidth: 3,
      isCurved: true,
      dotData: const FlDotData(show: true),
    );
  }

  Widget _buildScanCard(ScanRecord scan) {
    final color = _resultColor(scan.dominantClass);
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.only(left: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IntrinsicHeight(
              child: Row(
                children: [
                  Container(width: 4, color: color),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.grain, color: color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              DateFormat.yMd().add_jm().format(scan.timestamp),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          _resultChip(scan.dominantClass),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.divider.withOpacity(0.7)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 2, 8, 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showDetails(scan),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('More details'),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultChip(String result) {
    final color = _resultColor(result);
    return Chip(label: Text(_resultLabel(result)), labelStyle: TextStyle(color: color, fontSize: 12), backgroundColor: color.withOpacity(0.1));
  }

  Widget _buildLegendItem(String label, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      );

  Widget _buildStatisticCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withOpacity(0.78),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.22),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const Icon(Icons.arrow_outward, color: Colors.white70, size: 18),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() => const Center(child: Text('No scans yet - scan this batch', style: TextStyle(color: AppColors.textSecondary)));

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
