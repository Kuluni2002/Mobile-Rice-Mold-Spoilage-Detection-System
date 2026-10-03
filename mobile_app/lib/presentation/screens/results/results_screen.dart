/*import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/classification_result.dart';

class ResultsScreen extends StatelessWidget {
  final String? scanId;
  
  const ResultsScreen({
    super.key,
    this.scanId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Results'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              // TODO: Implement save functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.healthy,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 60,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'HEALTHY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Batch quality is good',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Grain count summary
            Text(
              'Grain Analysis',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatRow(
                      'Total Grains Detected',
                      '87',
                      Icons.grain,
                      AppColors.primary,
                    ),
                    const Divider(height: 24),
                    _buildStatRow(
                      'Healthy',
                      '60 (69%)',
                      Icons.check_circle,
                      AppColors.healthy,
                    ),
                    const Divider(height: 24),
                    _buildStatRow(
                      'Early Risk',
                      '23 (26%)',
                      Icons.warning,
                      AppColors.earlyRisk,
                    ),
                    const Divider(height: 24),
                    _buildStatRow(
                      'Spoiled',
                      '4 (5%)',
                      Icons.cancel,
                      AppColors.spoiled,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Recommendations
            Text(
              'Recommendations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.healthy.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.lightbulb_outline,
                            color: AppColors.healthy,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Maintenance Guidance',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    _buildRecommendationItem(
                      '• Maintain proper ventilation in storage area',
                    ),
                    _buildRecommendationItem(
                      '• Keep moisture content below 14%',
                    ),
                    _buildRecommendationItem(
                      '• Schedule next scan in 30 days',
                    ),
                    _buildRecommendationItem(
                      '• Continue current storage practices',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Action buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Save to batch
                },
                child: const Text('Save to Batch History'),
              ),
            ),
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Scan Another Batch'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildRecommendationItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, height: 1.5),
      ),
    );
  }
}*/


import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/classification_result.dart';
import '../../../services/genai_service.dart';

class ResultsScreen extends StatefulWidget {
  final String? scanId;
  
  const ResultsScreen({
    super.key,
    this.scanId,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  String? _aiRecommendations;
  bool _isLoadingRecommendations = false;
  String? _recommendationError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateRecommendations();
    });
  }

  Future<void> _generateRecommendations() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final ClassificationResult? result = args?['classification'];
    
    if (result == null) return;
    
    setState(() {
      _isLoadingRecommendations = true;
      _recommendationError = null;
    });
    
    try {
      final recommendations = await GenAIService.generateRecommendations(result);
      
      if (mounted) {
        setState(() {
          _aiRecommendations = recommendations;
          _isLoadingRecommendations = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _recommendationError = 'Failed to generate AI recommendations';
          _isLoadingRecommendations = false;
        });
      }
    }
  }

    @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    debugPrint('=== Results Screen Debug ===');
    debugPrint('Arguments: $args');
    
    if (args == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('No arguments received')),
      );
    }
    
    // Reconstruct ClassificationResult from individual properties
    final ClassificationResult? result = args['label'] != null 
        ? ClassificationResult(
            label: args['label'] as String,
            confidence: args['confidence'] as double,
            timestamp: DateTime.fromMillisecondsSinceEpoch(args['timestamp'] as int),
          )
        : null;
    
    final String? imagePath = args['imagePath'];
    final Uint8List? imageBytes = args['imageBytes'];
    
    debugPrint('Reconstructed result: ${result?.label} (${result?.confidence})');
    
    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('No classification data')),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Results'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoadingRecommendations ? null : _generateRecommendations,
            tooltip: 'Regenerate recommendations',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview Mode Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.blue.shade100],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade300, width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.science_outlined, color: Colors.blue.shade700, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preview Mode: TFLite Testing',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Whole image classification. Individual grain analysis coming with SAM integration.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Show captured image
            if (imagePath != null || imageBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: imageBytes != null
                    ? Image.memory(imageBytes, height: 200, width: double.infinity, fit: BoxFit.cover)
                    : Image.file(File(imagePath!), height: 200, width: double.infinity, fit: BoxFit.cover),
              ),
            const SizedBox(height: 16),
            
            // Status banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getStatusColor(result.label),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _getStatusColor(result.label).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    _getStatusIcon(result.label),
                    color: Colors.white,
                    size: 60,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${result.label.toUpperCase().replaceAll('_', ' ')} DETECTED',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Model Confidence: ${result.confidencePercent}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Whole Image Classification',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Current Analysis Explanation
            Card(
              color: Colors.amber.shade50,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.amber.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.analytics_outlined, color: Colors.amber.shade700, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Current Analysis Method',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'The TFLite model analyzed the entire image and detected characteristics of "${result.label.replaceAll('_', ' ')}" rice with ${result.confidencePercent} confidence.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.amber.shade900,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.upcoming, color: Colors.amber.shade800, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Next Phase: SAM will segment individual grains for exact counts',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.amber.shade800,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Analysis Details
            Text(
              'Detection Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDetailRow(
                      context,
                      'Classification',
                      result.label.toUpperCase().replaceAll('_', ' '),
                      Icons.category_outlined,
                      _getStatusColor(result.label),
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      context,
                      'Confidence',
                      result.confidencePercent,
                      Icons.verified_outlined,
                      AppColors.primary,
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      context,
                      'Risk Level',
                      result.riskLevel,
                      Icons.warning_amber_outlined,
                      _getRiskColor(result.riskLevel),
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      context,
                      'Scan Time',
                      _formatTime(result.timestamp),
                      Icons.access_time_outlined,
                      AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // AI-Generated Recommendations
            Row(
              children: [
                Text(
                  'AI Recommendations',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary.withOpacity(0.1), AppColors.primary.withOpacity(0.2)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'AI Powered',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getStatusColor(result.label).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.psychology_outlined,
                            color: _getStatusColor(result.label),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _getRecommendationTitle(result.label),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    if (_isLoadingRecommendations)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text(
                                'Generating personalized recommendations...',
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_recommendationError != null)
                      Column(
                        children: [
                          Text(
                            _recommendationError!,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _generateRecommendations,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      )
                    else if (_aiRecommendations != null)
                      SelectableText(
                        _aiRecommendations!,
                        style: const TextStyle(fontSize: 14, height: 1.6),
                      )
                    else
                      const Text('No recommendations available'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Action buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Save functionality will be added in Phase 3 (SQLite)'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save to History'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getStatusColor(result.label),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Scan Another Batch'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: _getStatusColor(result.label)),
                  foregroundColor: _getStatusColor(result.label),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 12),
            Text('Analysis Information'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '📊 Current Mode: Preview',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              SizedBox(height: 12),
              Text('✓ Analyzes whole image with TFLite'),
              Text('✓ Shows dominant rice condition'),
              Text('✓ Confidence score (model certainty)'),
              Text('✓ AI-generated recommendations'),
              SizedBox(height: 16),
              Text(
                '🔬 Next Phase: SAM Integration',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              SizedBox(height: 12),
              Text('→ Segments individual grains'),
              Text('→ Classifies each grain separately'),
              Text('→ Exact counts per category'),
              Text('→ Example: "60 healthy, 23 early_risk, 4 spoiled"'),
              SizedBox(height: 16),
              Text(
                '💾 Future Phase: Data Storage',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              SizedBox(height: 12),
              Text('→ Save scan history'),
              Text('→ Track batch trends'),
              Text('→ Export reports'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
  
 Color _getStatusColor(String classification) {
  switch (classification.toLowerCase()) {
    case 'healthy':
      return Colors.green;
    case 'early_risk':
      return Colors.orange;
    case 'spoiled':
      return Colors.red;
    default:
      return Colors.grey;
  }
}
  
  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'low':
        return AppColors.healthy;
      case 'medium':
        return AppColors.earlyRisk;
      case 'high':
        return AppColors.spoiled;
      default:
        return AppColors.textSecondary;
    }
  }
  
  IconData _getStatusIcon(String label) {
    switch (label.toLowerCase()) {
      case 'healthy':
        return Icons.check_circle_outline;
      case 'early_risk':
        return Icons.warning_amber_outlined;
      case 'spoiled':
        return Icons.dangerous_outlined;
      default:
        return Icons.help_outline;
    }
  }
  
  String _getRecommendationTitle(String label) {
    switch (label.toLowerCase()) {
      case 'healthy':
        return 'Maintenance Guidance';
      case 'early_risk':
        return 'Early Intervention Required';
      case 'spoiled':
        return 'Immediate Action Required';
      default:
        return 'Recommendations';
    }
  }
  
  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final day = timestamp.day.toString().padLeft(2, '0');
    final month = timestamp.month.toString().padLeft(2, '0');
    final year = timestamp.year;
    return '$hour:$minute - $day/$month/$year';
  }
  
  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}