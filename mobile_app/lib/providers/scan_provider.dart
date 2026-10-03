import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../models/grain_models.dart';
import '../services/tflite_service.dart';
import '../services/sam_service.dart';
import '../services/gemini_service.dart';
import '../services/database_service.dart';

enum ScanStatus {
  idle, uploading, segmenting,
  classifying, generating, done, error
}

class ScanProvider extends ChangeNotifier {
  final TFLiteService   _tflite  = TFLiteService();
  final SAMService      _sam     = SAMService();
  final GeminiService   _gemini  = GeminiService();
  final DatabaseService _db      = DatabaseService();

  ScanStatus  status       = ScanStatus.idle;
  String      statusMsg    = '';
  BatchResult? batchResult;
  String?     errorMsg;
  int         currentGrain = 0;
  int         totalGrains  = 0;
  List<GrainBox> grainBoxes = [];

  Future<void> initialize() async {
    await _tflite.loadModel();
  }

  Future<void> analyzeBatch(File imageFile) async {
    try {
      batchResult = null;
      errorMsg    = null;
      grainBoxes  = [];

      // Step 1 — Upload to SAM
      _setStatus(ScanStatus.uploading, 'Uploading image...');
      final boxes = await _sam.segmentGrains(imageFile);
      grainBoxes  = boxes;
      totalGrains = boxes.length;

      if (boxes.isEmpty) {
        throw Exception(
          'No grains detected. Ensure grains are on a dark '
          'background with good lighting.');
      }

      // Step 2 — Classify each grain
      _setStatus(ScanStatus.segmenting,
                 'Detected ${boxes.length} grains...');

      final imageBytes = await imageFile.readAsBytes();
      final decoded    = img.decodeImage(imageBytes)!;
      final results    = <GrainResult>[];
      final counts     = {'healthy':0, 'early_risk':0, 'spoiled':0};

      for (int i = 0; i < boxes.length; i++) {
        currentGrain = i + 1;
        _setStatus(ScanStatus.classifying,
                   'Classifying grain $currentGrain of $totalGrains...');

                 // Crop grain from image
        final box = boxes[i];
        final crop = img.copyCrop(decoded, box.x.toInt(), box.y.toInt(), box.w.toInt(), box.h.toInt());
        final cropBytes = Uint8List.fromList(img.encodeJpg(crop));

        // Classify
        final result = _tflite.classify(cropBytes);
        results.add(result);
        counts[result.className] =
            (counts[result.className] ?? 0) + 1;
      }

      // Step 3 — Get recommendation from Gemini
      _setStatus(ScanStatus.generating,
                 'Generating recommendation...');
      final dominant = counts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      final recommendation = await _gemini.getRecommendation(
        dominantClass  : dominant,
        healthyCount   : counts['healthy']!,
        earlyRiskCount : counts['early_risk']!,
        spoiledCount   : counts['spoiled']!,
        total          : results.length,
      );

      // Step 4 — Build result
      batchResult = BatchResult(
        grains         : results,
        counts         : counts,
        dominant       : dominant,
        recommendation : recommendation,
        timestamp      : DateTime.now(),
        imagePath      : imageFile.path,
      );

      // Step 5 — Save to SQLite
      await _db.saveScan(batchResult!);

      _setStatus(ScanStatus.done, 'Analysis complete!');

    } catch (e) {
      errorMsg = e.toString();
      _setStatus(ScanStatus.error, 'Error: $e');
    }
  }

  void _setStatus(ScanStatus s, String msg) {
    status    = s;
    statusMsg = msg;
    notifyListeners();
  }

  void reset() {
    status       = ScanStatus.idle;
    statusMsg    = '';
    batchResult  = null;
    errorMsg     = null;
    currentGrain = 0;
    totalGrains  = 0;
    grainBoxes   = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _tflite.dispose();
    super.dispose();
  }
}
