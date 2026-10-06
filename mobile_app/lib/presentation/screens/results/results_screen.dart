

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../domain/entities/batch.dart';
import '../../../models/classification_result.dart';
import '../../../models/scan_record.dart';
import '../../../services/database_service.dart';
import '../../../services/genai_service.dart';
import '../../screens/batch/batch_detail_screen.dart';

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
  bool _isSaving = false;
  bool _isSaved = false;

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

  Future<void> _saveToHistory() async {
    if (_isSaving || _isSaved || _recommendation == null) return;

    final args = _readArgs();
    if (args == null) return;

    setState(() => _isSaving = true);
    try {
      final batches = await DatabaseService.instance.getBatches();
      if (!mounted) return;
      setState(() => _isSaving = false);

      if (batches.isEmpty) {
        await _createAndConfirmBatch(args);
        return;
      }

      final requestedBatchId = args['batchId'] as String?;
      Batch? requestedBatch;
      if (requestedBatchId != null) {
        for (final batch in batches) {
          if (batch.id == requestedBatchId) {
            requestedBatch = batch;
            break;
          }
        }
      }
      if (requestedBatch != null) {
        await _confirmBatch(requestedBatch, args);
        return;
      }

      final selected = await _showBatchPicker(batches);
      if (selected != null && mounted) {
        await _confirmBatch(selected, args);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showDatabaseError('Unable to load batches: $error',
          retry: _saveToHistory);
    }
  }

  Future<Batch?> _showBatchPicker(List<Batch> batches) async {
    return showModalBottomSheet<Batch>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            const ListTile(
              title: Text('Save scan to batch'),
              subtitle: Text('Select a batch for this scan'),
            ),
            ...batches.map(
              (batch) => ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text(batch.batchNumber),
                subtitle: Text(batch.variety ?? 'Variety not specified'),
                onTap: () => Navigator.of(sheetContext).pop(batch),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Create new batch'),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final args = _readArgs();
                if (args != null) await _createAndConfirmBatch(args);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<Batch?> _createBatch() async {
    final created = await Navigator.of(context).pushNamed(AppRoutes.batchCreate);
    return created is Batch ? created : null;
  }

  Future<void> _createAndConfirmBatch(Map<String, dynamic> args) async {
    final created = await _createBatch();
    if (created == null || !mounted) return;
    try {
      final batches = await DatabaseService.instance.getBatches();
      Batch? selected;
      for (final batch in batches) {
        if (batch.id == created.id) {
          selected = batch;
          break;
        }
      }
      if (selected != null && mounted) {
        await _confirmBatch(selected, args);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showDatabaseError('Unable to reload batches: $error',
          retry: () => _createAndConfirmBatch(args));
    }
  }

  Future<void> _confirmBatch(Batch batch, Map<String, dynamic> args) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Save scan to ${batch.batchNumber}?',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(batch.variety ?? 'Variety not specified'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(sheetContext).pop(true),
                  child: const Text('Confirm'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true && mounted) {
      await _insertScan(batch, args);
    }
  }

  Future<void> _insertScan(Batch batch, Map<String, dynamic> args) async {
    setState(() => _isSaving = true);
    final scanTime = DateTime.fromMillisecondsSinceEpoch(
      (args['timestamp'] as num).toInt(),
      isUtc: true,
    ).toUtc();
    String? copiedImagePath;
    final sourceImagePath = args['imagePath'] as String?;
    if (sourceImagePath != null) {
      try {
        final documents = await getApplicationDocumentsDirectory();
        final scansDirectory = Directory(path.join(documents.path, 'scans'));
        await scansDirectory.create(recursive: true);
        final destination = path.join(
          scansDirectory.path,
          '${scanTime.millisecondsSinceEpoch}.jpg',
        );
        copiedImagePath = (await File(sourceImagePath).copy(destination)).path;
      } catch (_) {
        copiedImagePath = null;
      }
    }

    final counts = _countsFromArgs(args);
    final totalGrains = (args['totalGrains'] as num?)?.toInt() ?? 0;
    final result = _resultFromArgs(args);
    if (result == null) {
      if (mounted) setState(() => _isSaving = false);
      return;
    }

    try {
      await DatabaseService.instance.insertScan(
        ScanRecord(
          batchId: batch.id,
          timestamp: scanTime,
          imagePath: copiedImagePath,
          totalGrains: totalGrains,
          healthyCount: counts[AppConstants.classHealthy] ?? 0,
          earlyRiskCount: counts[AppConstants.classEarlyRisk] ?? 0,
          spoiledCount: counts[AppConstants.classSpoiled] ?? 0,
          dominantClass: result.label,
          recommendation: _recommendation!.text,
          recommendationSource: _recommendation!.fromAi ? 'ai' : 'offline',
        ),
      );
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _isSaved = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved to batch ${batch.batchNumber}'),
          action: SnackBarAction(
            label: 'View batch',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BatchDetailScreen(batchId: batch.id),
              ),
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showDatabaseError('Unable to save scan: $error');
    }
  }

  void _showDatabaseError(String message, {VoidCallback? retry}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.spoiled,
        action: retry == null
            ? null
            : SnackBarAction(label: 'Retry', onPressed: retry),
      ),
    );
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
                    '${_prettyLabel(result.label)} Detected',
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
                      _prettyLabel(result.label),
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
                onPressed: (_recommendation == null ||
                        _isLoadingRecommendations ||
                        _isSaving ||
                        _isSaved)
                    ? null
                    : _saveToHistory,
                icon: const Icon(Icons.save_outlined),
                label: Text(_isSaved ? 'Saved' : 'Save to History'),
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
        return AppColors.healthy;
      case 'early_risk':
        return AppColors.earlyRisk;
      case 'spoiled':
        return AppColors.spoiled;
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
    return DateFormat('HH:mm - dd/MM/yyyy').format(timestamp.toLocal());
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
