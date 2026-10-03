import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';

class BatchDetailScreen extends StatelessWidget {
  final String batchId;
  
  const BatchDetailScreen({
    super.key,
    required this.batchId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navigate to edit batch
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              // TODO: Show delete confirmation
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Batch info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Warehouse A - Row 3',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildInfoRow(Icons.grain, 'Variety', 'Samba'),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.store, 'Source', 'Farmer Silva'),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.scale, 'Quantity', '500 kg'),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.calendar_today, 'Storage Date', '15/01/2026'),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.location_on, 'Location', 'Warehouse A, Section 2'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Current status
            Text(
              'Current Status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.healthy.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.healthy),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.healthy, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'HEALTHY',
                          style: TextStyle(
                            color: AppColors.healthy,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Last scanned: 2 days ago',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Scan history
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Scan History',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.batchHistory,
                      arguments: {'batchId': batchId},
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            _buildScanHistoryItem(
              date: '20/01/2026',
              status: 'Healthy',
              statusColor: AppColors.healthy,
              healthyPercent: 95,
            ),
            const SizedBox(height: 8),
            
            _buildScanHistoryItem(
              date: '15/01/2026',
              status: 'Healthy',
              statusColor: AppColors.healthy,
              healthyPercent: 98,
            ),
            const SizedBox(height: 24),
            
            // Actions
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.camera);
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Scan This Batch'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildScanHistoryItem({
    required String date,
    required String status,
    required Color statusColor,
    required int healthyPercent,
  }) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.grain, color: statusColor),
        ),
        title: Text(date),
        subtitle: Text('$healthyPercent% healthy grains'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        onTap: () {
          // TODO: Navigate to scan details
        },
      ),
    );
  }
}