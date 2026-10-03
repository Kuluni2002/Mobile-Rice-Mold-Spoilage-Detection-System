import 'dart:typed_data';
import '../../core/utils/typedef.dart';
import '../entities/grain_classification.dart';

abstract class ClassificationRepository {
  // Segmentation (cloud-based)
  ResultFuture<List<Map<String, int>>> segmentGrains(String imagePath);
  
  // Classification (on-device)
  ResultFuture<List<GrainClassification>> classifyGrains(
    Uint8List imageBytes,
    List<Map<String, int>> boundingBoxes,
  );
  
  // Combined operation
  ResultFuture<List<GrainClassification>> processImage(String imagePath);
}