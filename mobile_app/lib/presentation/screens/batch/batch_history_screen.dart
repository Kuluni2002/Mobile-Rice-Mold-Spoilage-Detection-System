import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';

class BatchHistoryScreen extends StatelessWidget {
  final String batchId;
  
  const BatchHistoryScreen({
    super.key,
    required this.batchId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // TODO: Export history as PDF
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quality trend chart
            Text(
              'Quality Trend',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        _buildChartData(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendItem('Healthy', AppColors.healthy),
                        const SizedBox(width: 16),
                        _buildLegendItem('Early Risk', AppColors.earlyRisk),
                        const SizedBox(width: 16),
                        _buildLegendItem('Spoiled', AppColors.spoiled),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Statistics
            Text(
              'Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Scans',
                    '3',
                    Icons.camera_alt,
                    AppColors.primary,
                    context,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Avg Quality',
                    '96%',
                    Icons.trending_up,
                    AppColors.healthy,
                    context,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Scan list
            Text(
              'All Scans',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            
            _buildScanListItem(
              date: '20/01/2026',
              time: '14:30',
              healthy: 95,
              earlyRisk: 4,
              spoiled: 1,
              status: 'Healthy',
            ),
            const SizedBox(height: 8),
            
            _buildScanListItem(
              date: '18/01/2026',
              time: '09:15',
              healthy: 96,
              earlyRisk: 3,
              spoiled: 1,
              status: 'Healthy',
            ),
            const SizedBox(height: 8),
            
            _buildScanListItem(
              date: '15/01/2026',
              time: '16:45',
              healthy: 98,
              earlyRisk: 2,
              spoiled: 0,
              status: 'Healthy',
            ),
          ],
        ),
      ),
    );
  }
  
  LineChartData _buildChartData() {
    return LineChartData(
      gridData: FlGridData(show: true),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}%',
                style: const TextStyle(fontSize: 10),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              const dates = ['15 Jan', '18 Jan', '20 Jan'];
              if (value.toInt() >= 0 && value.toInt() < dates.length) {
                return Text(
                  dates[value.toInt()],
                  style: const TextStyle(fontSize: 10),
                );
              }
              return const Text('');
            },
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: true),
      minX: 0,
      maxX: 2,
      minY: 0,
      maxY: 100,
      lineBarsData: [
        LineChartBarData(
          spots: const [
            FlSpot(0, 98),
            FlSpot(1, 96),
            FlSpot(2, 95),
          ],
          isCurved: true,
          color: AppColors.healthy,
          barWidth: 3,
          dotData: const FlDotData(show: true),
        ),
      ],
    );
  }
  
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }
  
 Widget _buildStatCard(String label, String value, IconData icon, Color color, BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildScanListItem({
    required String date,
    required String time,
    required int healthy,
    required int earlyRisk,
    required int spoiled,
    required String status,
  }) {
    return Card(
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.healthy.withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.grain, color: AppColors.healthy),
        ),
        title: Text(date),
        subtitle: Text('$time • $healthy% healthy'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPercentage('Healthy', healthy, AppColors.healthy),
_buildPercentage('Early Risk', earlyRisk, AppColors.earlyRisk),
_buildPercentage('Spoiled', spoiled, AppColors.spoiled),
],
),
const SizedBox(height: 16),
SizedBox(
width: double.infinity,
child: OutlinedButton(
onPressed: () {
// TODO: View detailed scan results
},
child: const Text('View Details'),
),
),
],
),
),
],
),
);
}
Widget _buildPercentage(String label, int value, Color color) {
return Column(
children: [
Text(
'$value%',
style: TextStyle(
fontSize: 20,
fontWeight: FontWeight.bold,
color: color,
),
),
const SizedBox(height: 4),
Text(
label,
style: const TextStyle(fontSize: 12),
),
],
);
}
}