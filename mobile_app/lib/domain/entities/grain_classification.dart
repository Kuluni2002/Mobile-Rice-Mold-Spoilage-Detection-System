import 'package:equatable/equatable.dart';

enum GrainStatus { healthy, earlyRisk, spoiled }

class GrainClassification extends Equatable {
  final String id;
  final GrainStatus status;
  final double confidence;
  final int boundingBoxX;
  final int boundingBoxY;
  final int boundingBoxWidth;
  final int boundingBoxHeight;
  
  const GrainClassification({
    required this.id,
    required this.status,
    required this.confidence,
    required this.boundingBoxX,
    required this.boundingBoxY,
    required this.boundingBoxWidth,
    required this.boundingBoxHeight,
  });
  
  @override
  List<Object?> get props => [
    id,
    status,
    confidence,
    boundingBoxX,
    boundingBoxY,
    boundingBoxWidth,
    boundingBoxHeight,
  ];
  
  String get statusLabel {
    switch (status) {
      case GrainStatus.healthy:
        return 'Healthy';
      case GrainStatus.earlyRisk:
        return 'Early Risk';
      case GrainStatus.spoiled:
        return 'Spoiled';
    }
  }
}