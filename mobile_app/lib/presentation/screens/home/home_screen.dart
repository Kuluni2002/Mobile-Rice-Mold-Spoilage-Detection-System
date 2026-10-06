import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../domain/entities/batch.dart';
import '../../../services/database_service.dart';
import '../../widgets/common/recent_batch_card.dart';
import '../../widgets/common/stat_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _loading = true;
  String? _error;
  Map<String, int> _stats = {};
  List<Batch> _batches = [];
  List<Batch> _recentBatches = [];

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
      final results = await Future.wait([
        DatabaseService.instance.getDashboardStats(),
        DatabaseService.instance.getBatches(),
        DatabaseService.instance.getRecentBatches(),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = results[0] as Map<String, int>;
        _batches = results[1] as List<Batch>;
        _recentBatches = results[2] as List<Batch>;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rice Mold Detector'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.camera),
        icon: const Icon(Icons.camera_alt),
        label: const Text('Scan Grains'),
        backgroundColor: AppColors.primary,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Batches'),
          NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: 'Analytics'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _buildErrorState();
    switch (_selectedIndex) {
      case 1:
        return _buildBatchesTab();
      case 2:
        return _buildAnalyticsTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back!', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Monitor your rice quality and detect mold early',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            Text('Overview', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: StatCard(title: 'Total Batches', value: '${_stats['totalBatches'] ?? 0}', icon: Icons.inventory_2, color: AppColors.primary)),
              const SizedBox(width: 12),
              Expanded(child: StatCard(title: 'Total Scans', value: '${_stats['totalScans'] ?? 0}', icon: Icons.camera_alt, color: AppColors.primaryLight)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: StatCard(title: 'Healthy', value: '${_stats['healthy'] ?? 0}', icon: Icons.check_circle, color: AppColors.healthy)),
              const SizedBox(width: 12),
              Expanded(child: StatCard(title: 'At Risk', value: '${_stats['batchesNeedingAttention'] ?? 0}', icon: Icons.warning, color: AppColors.earlyRisk)),
            ]),
            const SizedBox(height: 24),
            Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _buildQuickAction('Create New Batch', Icons.add_box, AppColors.primary, () async {
              final created = await Navigator.pushNamed(context, AppRoutes.batchCreate);
              if (created != null) await _loadData();
            }),
            const SizedBox(height: 12),
            _buildQuickAction('Scan Grains', Icons.camera_alt, AppColors.primaryLight,
                () => Navigator.pushNamed(context, AppRoutes.camera)),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Recent Batches', style: Theme.of(context).textTheme.titleMedium),
              TextButton(onPressed: () => setState(() => _selectedIndex = 1), child: const Text('View All')),
            ]),
            const SizedBox(height: 12),
            if (_recentBatches.isEmpty)
              _buildEmptyState(Icons.inventory_2_outlined, 'No batches yet - create one')
            else
              ..._recentBatches.map((batch) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: RecentBatchCard(
                  batch: batch,
                  onTap: () async {
                    await Navigator.pushNamed(context, AppRoutes.batchDetail, arguments: {'batchId': batch.id});
                    if (mounted) await _loadData();
                  },
                ),
              )),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchesTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text('All Batches', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          if (_batches.isEmpty)
            _buildEmptyState(Icons.inventory_2_outlined, 'No batches yet - create one')
          else
            ..._batches.map(_buildBatchListTile),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildBatchListTile(Batch batch) {
    final color = _resultColor(batch.latestResult);
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(8, 12, 12, 12),
        leading: Container(
          width: 5,
          height: 82,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                batch.batchNumber,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _buildBatchStatusChip(batch.latestResult),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (batch.variety != null && batch.variety!.isNotEmpty)
                _buildBatchMetaRow(Icons.grain, batch.variety!),
              _buildBatchMetaRow(
                Icons.calendar_today_outlined,
                'Stored ${DateFormat.yMd().format(batch.storageDate)}',
              ),
              _buildBatchMetaRow(
                Icons.camera_alt_outlined,
                '${batch.scanCount} scan${batch.scanCount == 1 ? '' : 's'}',
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: () async {
          await Navigator.pushNamed(context, AppRoutes.batchDetail, arguments: {'batchId': batch.id});
          if (mounted) await _loadData();
        },
      ),
    );
  }

  Widget _buildBatchMetaRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchStatusChip(String? result) {
    final color = _resultColor(result);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _resultLabel(result),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() => _buildEmptyState(Icons.analytics_outlined, 'No data available yet.\nStart scanning batches to see analytics.');

  Widget _buildErrorState() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, color: AppColors.spoiled, size: 48),
      const SizedBox(height: 12),
      Text(_error ?? 'Unable to load data', textAlign: TextAlign.center),
      const SizedBox(height: 12),
      ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
    ]),
  );

  Widget _buildQuickAction(String title, IconData icon, Color color, VoidCallback onTap) => Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
          const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 16),
        ]),
      ),
    ),
  );

  Widget _buildEmptyState(IconData icon, String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(children: [
        Icon(icon, size: 80, color: AppColors.divider),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary)),
      ]),
    ),
  );

  String _resultLabel(String? result) {
    switch (result) {
      case 'healthy': return 'Healthy';
      case 'early_risk': return 'Early risk';
      case 'spoiled': return 'Spoiled';
      default: return 'Not scanned';
    }
  }

  Color _resultColor(String? result) {
    switch (result) {
      case 'healthy': return AppColors.healthy;
      case 'early_risk': return AppColors.earlyRisk;
      case 'spoiled': return AppColors.spoiled;
      default: return AppColors.textSecondary;
    }
  }
}
