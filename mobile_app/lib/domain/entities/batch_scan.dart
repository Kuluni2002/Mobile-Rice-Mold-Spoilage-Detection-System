import 'package:equatable/equatable.dart';
import 'grain_classification.dart';

enum BatchStatus { healthy, earlyRisk, spoiled, caution }

class BatchScan extends Equatable {
  final String id;
  final String batchId;
  final DateTime scanDate;
  final String imagePath;
  final int totalGrains;
  final int healthyCount;
  final int earlyRiskCount;
  final int spoiledCount;
  final BatchStatus status;
  final List<GrainClassification> grainClassifications;
  final double? averageConfidence;
  
  const BatchScan({
    required this.id,
    required this.batchId,
    required this.scanDate,
    required this.imagePath,
    required this.totalGrains,
    required this.healthyCount,
    required this.earlyRiskCount,
    required this.spoiledCount,
    required this.status,
    required this.grainClassifications,
    this.averageConfidence,
  });
  
  double get healthyPercentage => (healthyCount / totalGrains) * 100;
  double get earlyRiskPercentage => (earlyRiskCount / totalGrains) * 100;
  double get spoiledPercentage => (spoiledCount / totalGrains) * 100;
  
  @override
  List<Object?> get props => [
    id,
    batchId,
    scanDate,
    imagePath,
    totalGrains,
    healthyCount,
    earlyRiskCount,
    spoiledCount,
    status,
    grainClassifications,
    averageConfidence,
  ];
}