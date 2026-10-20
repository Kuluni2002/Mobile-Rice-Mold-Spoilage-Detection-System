import '../core/constants/app_constants.dart';

class ScanRecord {
  final int? id;
  final String batchId;
  final DateTime timestamp;
  final String? imagePath;
  final int totalGrains;
  final int healthyCount;
  final int earlyRiskCount;
  final int spoiledCount;
  final String dominantClass;
  final String? recommendation;
  final String? recommendationSource;

  const ScanRecord({
    this.id,
    required this.batchId,
    required this.timestamp,
    this.imagePath,
    required this.totalGrains,
    required this.healthyCount,
    required this.earlyRiskCount,
    required this.spoiledCount,
    required this.dominantClass,
    this.recommendation,
    this.recommendationSource,
  });

  double _percentage(int count) =>
      totalGrains == 0 ? 0 : count / totalGrains * 100;

  double get healthyPercentage => _percentage(healthyCount);
  double get earlyRiskPercentage => _percentage(earlyRiskCount);
  double get spoiledPercentage => _percentage(spoiledCount);

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'batch_id': batchId,
    'timestamp': timestamp.toUtc().toIso8601String(),
    'image_path': imagePath,
    'total_grains': totalGrains,
    'healthy_count': healthyCount,
    'early_risk_count': earlyRiskCount,
    'spoiled_count': spoiledCount,
    'dominant_class': dominantClass,
    'recommendation': recommendation,
    'recommendation_source': recommendationSource,
  };

  factory ScanRecord.fromMap(Map<String, dynamic> map) => ScanRecord(
    id: (map['id'] as num?)?.toInt(),
    batchId: map['batch_id'] as String,
    timestamp: DateTime.parse(map['timestamp'] as String).toLocal(),
    imagePath: map['image_path'] as String?,
    totalGrains: (map['total_grains'] as num).toInt(),
    healthyCount: (map['healthy_count'] as num).toInt(),
    earlyRiskCount: (map['early_risk_count'] as num).toInt(),
    spoiledCount: (map['spoiled_count'] as num).toInt(),
    dominantClass: map['dominant_class'] as String,
    recommendation: map['recommendation'] as String?,
    recommendationSource: map['recommendation_source'] as String?,
  );

  String get healthyClass => AppConstants.classHealthy;
  String get earlyRiskClass => AppConstants.classEarlyRisk;
  String get spoiledClass => AppConstants.classSpoiled;
}
