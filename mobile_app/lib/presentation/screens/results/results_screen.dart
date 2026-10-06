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


/*import 'dart:io';
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

  // ── Arguments from the camera screen ──────────────────────────────────────
  Map<String, dynamic>? _readArgs() {
    return ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
  }

  ClassificationResult? _resultFromArgs(Map<String, dynamic>? args) {
    if (args == null || args['label'] == null) return null;
    return ClassificationResult(
      label: args['label'] as String,
      confidence: (args['confidence'] as num).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(args['timestamp'] as int),
    );
  }

  Map<String, int> _countsFromArgs(Map<String, dynamic> args) {
    final raw = args['counts'];
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
    }
    return {};
  }

  Future<void> _generateRecommendations() async {
    final result = _resultFromArgs(_readArgs());
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
    final args = _readArgs();

    if (args == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('No arguments received')),
      );
    }

    final ClassificationResult? result = _resultFromArgs(args);
    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('No classification data')),
      );
    }

    final String? imagePath = args['imagePath'] as String?;
    final Uint8List? imageBytes = args['imageBytes'] as Uint8List?;

    // Grain counts per class (from the pile analysis)
    final counts = _countsFromArgs(args);
    final int healthy = counts['healthy'] ?? 0;
    final int earlyRisk = counts['early_risk'] ?? 0;
    final int spoiled = counts['spoiled'] ?? 0;
    final int total = healthy + earlyRisk + spoiled;

    String pct(int n) =>
        total == 0 ? '0.0' : (100 * n / total).toStringAsFixed(1);

    final int winnerCount = counts[result.label] ?? 0;
    final String winnerPct =
        total == 0 ? (result.confidence * 100).toStringAsFixed(1) : pct(winnerCount);
    final Color statusColor = _getStatusColor(result.label);

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
            // Whole pile photo (not cropped)
            if (imagePath != null || imageBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 420),
                  color: Colors.black,
                  child: imageBytes != null
                      ? Image.memory(
                          imageBytes,
                          fit: BoxFit.contain,
                          cacheWidth: 1280,
                        )
                      : Image.file(
                          File(imagePath!),
                          fit: BoxFit.contain,
                          cacheWidth: 1280,
                        ),
                ),
              ),
            const SizedBox(height: 16),

            // Status banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withOpacity(0.3),
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
                  const SizedBox(height: 6),
                  Text(
                    total > 0
                        ? '${_prettyLabel(result.label)}: $winnerPct% of grains ($winnerCount of $total)'
                        : '${_prettyLabel(result.label)}: $winnerPct%',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Detection details
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
                  children: _withDividers([
                    _buildDetailRow(
                      context,
                      'Classification',
                      result.label.toUpperCase().replaceAll('_', ' '),
                      Icons.category_outlined,
                      statusColor,
                    ),
                    if (total > 0)
                      _buildDetailRow(
                        context,
                        'Total grains',
                        '$total',
                        Icons.grain,
                        AppColors.primary,
                      ),
                    if (total > 0)
                      _buildDetailRow(
                        context,
                        'Healthy',
                        '$healthy (${pct(healthy)}%)',
                        Icons.check_circle_outline,
                        AppColors.healthy,
                      ),
                    if (total > 0)
                      _buildDetailRow(
                        context,
                        'Early risk',
                        '$earlyRisk (${pct(earlyRisk)}%)',
                        Icons.warning_amber_outlined,
                        AppColors.earlyRisk,
                      ),
                    if (total > 0)
                      _buildDetailRow(
                        context,
                        'Spoiled',
                        '$spoiled (${pct(spoiled)}%)',
                        Icons.dangerous_outlined,
                        AppColors.spoiled,
                      ),
                    _buildDetailRow(
                      context,
                      'Risk Level',
                      result.riskLevel,
                      Icons.warning_amber_outlined,
                      _getRiskColor(result.riskLevel),
                    ),
                    _buildDetailRow(
                      context,
                      'Scan Time',
                      _formatTime(result.timestamp),
                      Icons.access_time_outlined,
                      AppColors.textSecondary,
                    ),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // AI-generated recommendations
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
                      colors: [
                        AppColors.primary.withOpacity(0.1),
                        AppColors.primary.withOpacity(0.2),
                      ],
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
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.psychology_outlined,
                            color: statusColor,
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
                      content: Text('Saving to history will be added with the database phase'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save to History'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
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
                  side: BorderSide(color: statusColor),
                  foregroundColor: statusColor,
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
            Text('How this result is calculated'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('1. Each grain in the photo is found and cut out.'),
              SizedBox(height: 8),
              Text('2. Every grain is checked: healthy or mold. Mold grains are then split into early risk or spoiled.'),
              SizedBox(height: 8),
              Text('3. The grains of each class are counted.'),
              SizedBox(height: 8),
              Text('4. The class with the most grains is the result. If two classes tie, the more severe one is shown.'),
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

  List<Widget> _withDividers(List<Widget> rows) {
    final out = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) out.add(const Divider(height: 24));
      out.add(rows[i]);
    }
    return out;
  }

  String _prettyLabel(String label) {
    final t = label.replaceAll('_', ' ');
    return t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
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
  Recommendation? _recommendation;
  bool _isLoadingRecommendations = false;
  String? _recommendationError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateRecommendations();
    });
  }

  // ── Arguments from the camera screen ──────────────────────────────────────
  Map<String, dynamic>? _readArgs() {
    return ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
  }

  ClassificationResult? _resultFromArgs(Map<String, dynamic>? args) {
    if (args == null || args['label'] == null) return null;
    return ClassificationResult(
      label: args['label'] as String,
      confidence: (args['confidence'] as num).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(args['timestamp'] as int),
    );
  }

  Map<String, int> _countsFromArgs(Map<String, dynamic> args) {
    final raw = args['counts'];
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
    }
    return {};
  }

  Future<void> _generateRecommendations() async {
    final result = _resultFromArgs(_readArgs());
    if (result == null) return;

    setState(() {
      _isLoadingRecommendations = true;
      _recommendationError = null;
    });

    try {
      // Gemini only receives the final result: healthy / early_risk / spoiled
      final rec = await GenAIService.getRecommendation(label: result.label);

      if (mounted) {
        setState(() {
          _recommendation = rec;
          _isLoadingRecommendations = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _recommendationError = 'Could not load recommendations';
          _isLoadingRecommendations = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = _readArgs();

    if (args == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('No arguments received')),
      );
    }

    final ClassificationResult? result = _resultFromArgs(args);
    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('No classification data')),
      );
    }

    final String? imagePath = args['imagePath'] as String?;
    final Uint8List? imageBytes = args['imageBytes'] as Uint8List?;

    // Grain counts per class (from the pile analysis)
    final counts = _countsFromArgs(args);
    final int healthy = counts['healthy'] ?? 0;
    final int earlyRisk = counts['early_risk'] ?? 0;
    final int spoiled = counts['spoiled'] ?? 0;
    final int total = healthy + earlyRisk + spoiled;

    String pct(int n) =>
        total == 0 ? '0.0' : (100 * n / total).toStringAsFixed(1);

    final int winnerCount = counts[result.label] ?? 0;
    final String winnerPct =
        total == 0 ? (result.confidence * 100).toStringAsFixed(1) : pct(winnerCount);
    final Color statusColor = _getStatusColor(result.label);

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
            // Whole pile photo (not cropped)
            if (imagePath != null || imageBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 420),
                  color: Colors.black,
                  child: imageBytes != null
                      ? Image.memory(
                          imageBytes,
                          fit: BoxFit.contain,
                          cacheWidth: 1280,
                        )
                      : Image.file(
                          File(imagePath!),
                          fit: BoxFit.contain,
                          cacheWidth: 1280,
                        ),
                ),
              ),
            const SizedBox(height: 16),

            // Status banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withOpacity(0.3),
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
                  const SizedBox(height: 6),
                  Text(
                    total > 0
                        ? '${_prettyLabel(result.label)}: $winnerPct% of grains ($winnerCount of $total)'
                        : '${_prettyLabel(result.label)}: $winnerPct%',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Detection details
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
                  children: _withDividers([
                    _buildDetailRow(
                      context,
                      'Classification',
                      result.label.toUpperCase().replaceAll('_', ' '),
                      Icons.category_outlined,
                      statusColor,
                    ),
                    if (total > 0)
                      _buildDetailRow(
                        context,
                        'Total grains',
                        '$total',
                        Icons.grain,
                        AppColors.primary,
                      ),
                    if (total > 0)
                      _buildDetailRow(
                        context,
                        'Healthy',
                        '$healthy (${pct(healthy)}%)',
                        Icons.check_circle_outline,
                        AppColors.healthy,
                      ),
                    if (total > 0)
                      _buildDetailRow(
                        context,
                        'Early risk',
                        '$earlyRisk (${pct(earlyRisk)}%)',
                        Icons.warning_amber_outlined,
                        AppColors.earlyRisk,
                      ),
                    if (total > 0)
                      _buildDetailRow(
                        context,
                        'Spoiled',
                        '$spoiled (${pct(spoiled)}%)',
                        Icons.dangerous_outlined,
                        AppColors.spoiled,
                      ),
                    _buildDetailRow(
                      context,
                      'Risk Level',
                      result.riskLevel,
                      Icons.warning_amber_outlined,
                      _getRiskColor(result.riskLevel),
                    ),
                    _buildDetailRow(
                      context,
                      'Scan Time',
                      _formatTime(result.timestamp),
                      Icons.access_time_outlined,
                      AppColors.textSecondary,
                    ),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // AI-generated recommendations
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
                      colors: [
                        AppColors.primary.withOpacity(0.1),
                        AppColors.primary.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        (_recommendation != null && !_recommendation!.fromAi)
                            ? 'Offline guidance'
                            : 'AI Powered',
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
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.psychology_outlined,
                            color: statusColor,
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
                    else if (_recommendation != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            _recommendation!.text,
                            style: const TextStyle(fontSize: 14, height: 1.6),
                          ),
                          if (_recommendation!.note != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _recommendation!.note!,
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
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
                      content: Text('Saving to history will be added with the database phase'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save to History'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
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
                  side: BorderSide(color: statusColor),
                  foregroundColor: statusColor,
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
            Text('How this result is calculated'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('1. Each grain in the photo is found and cut out.'),
              SizedBox(height: 8),
              Text('2. Every grain is checked: healthy or mold. Mold grains are then split into early risk or spoiled.'),
              SizedBox(height: 8),
              Text('3. The grains of each class are counted.'),
              SizedBox(height: 8),
              Text('4. The class with the most grains is the result. If two classes tie, the more severe one is shown.'),
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

  List<Widget> _withDividers(List<Widget> rows) {
    final out = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) out.add(const Divider(height: 24));
      out.add(rows[i]);
    }
    return out;
  }

  String _prettyLabel(String label) {
    final t = label.replaceAll('_', ' ');
    return t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
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

