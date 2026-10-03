/*import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../models/classification_result.dart';
import 'dart:math' as math;

class TFLiteService {
  Interpreter? _interpreter;
  bool _isInitialized = false;
  List<int>? _inputShape;
  List<int>? _outputShape;
  TensorType? _inputType;
  TensorType? _outputType;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('=== TFLite Initialization ===');
      
      final modelData = await rootBundle.load('assets/models/rice_mold_final.tflite');
      print('Model file verified: ${modelData.lengthInBytes} bytes');
      
      _interpreter = await Interpreter.fromAsset(
        'assets/models/rice_mold_final.tflite',
      );
      print('Interpreter created successfully');
      
      _inputShape = _interpreter!.getInputTensor(0).shape;
      _outputShape = _interpreter!.getOutputTensor(0).shape;
      _inputType = _interpreter!.getInputTensor(0).type;
      _outputType = _interpreter!.getOutputTensor(0).type;
      
      print('=== Model Information ===');
      print('Input tensor shape: $_inputShape');
      print('Output tensor shape: $_outputShape');
      print('Input tensor type: $_inputType');
      print('Output tensor type: $_outputType');
      print('==========================');
      
      _isInitialized = true;
      print('TFLite service initialized successfully');
      
    } catch (e) {
      print('TFLite initialization failed: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  Future<ClassificationResult> classifyImage(Uint8List imageBytes) async {
    if (!_isInitialized || _interpreter == null) {
      throw Exception('TFLite service not initialized');
    }

    try {
      print('=== Starting Classification ===');
      print('Image bytes: ${imageBytes.length}');
      
      // Decode image
      final image = img.decodeImage(imageBytes);
      if (image == null) throw Exception('Failed to decode image');
      
      print('Original image: ${image.width}x${image.height}');
      
      // Resize to 224x224
      final resizedImage = img.copyResize(
        image,
        width: 224,
        height: 224,
        interpolation: img.Interpolation.linear,
      );
      print('Resized to: ${resizedImage.width}x${resizedImage.height}');

      // ── KEY FIX 1: Use Float32List instead of nested List ──
      final inputBuffer = Float32List(1 * 224 * 224 * 3);
      int pixelIndex = 0;

      for (int h = 0; h < 224; h++) {
        for (int w = 0; w < 224; w++) {
          final pixel = resizedImage.getPixel(w, h);
          // [0,1] normalization - matches your training rescale=1./255
          inputBuffer[pixelIndex++] = img.getRed(pixel) / 255.0;
          inputBuffer[pixelIndex++] = img.getGreen(pixel) / 255.0;
          inputBuffer[pixelIndex++] = img.getBlue(pixel) / 255.0;
        }
      }

      // Reshape to [1, 224, 224, 3]
      final input = inputBuffer.reshape([1, 224, 224, 3]);
      print('Input buffer created: ${inputBuffer.length} values');

      // // ── KEY FIX 2: Use Float32List for output too ──
      // final outputBuffer = Float32List(3);
      // final output = outputBuffer.reshape([1, 3]);

      // print('Running inference...');

      // // ── KEY FIX 3: Use runForMultipleInputs ──
      // _interpreter!.runForMultipleInputs([input], {0: output});

      // print('Inference completed!');
      // print('Raw output: $outputBuffer');
      // print('Output sum: ${outputBuffer.reduce((a, b) => a + b)}');

      // REPLACE WITH THIS
final outputBuffer = List.generate(1, (_) => List.filled(3, 0.0));
_interpreter!.run(input, outputBuffer);
print('Raw output: ${outputBuffer[0]}');
final result = _processOutput(outputBuffer[0]);

      // // Process results
      // final result = _processOutput(outputBuffer.toList());
      // print('Final result: ${result.label} (${result.confidencePercent})');

      return result;

    } catch (e, stackTrace) {
      print('=== Classification Error ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  ClassificationResult _processOutput(List<double> probabilities) {
    print('Probabilities: $probabilities');

    double sum = probabilities.fold(0.0, (a, b) => a + b);
    print('Probability sum: $sum (should be ~1.0)');

    if (probabilities.every((p) => p == 0.0)) {
      print('ERROR: All probabilities are 0.0');
    }

    // Find highest probability
    double maxProb = probabilities[0];
    int maxIndex = 0;
    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > maxProb) {
        maxProb = probabilities[i];
        maxIndex = i;
      }
    }

    // Class order from your training: 0=early-risk, 1=healthy, 2=spoiled
    final labels = ['early-risk', 'healthy', 'spoiled'];
    final label = labels[maxIndex];

    print('Predicted: $label (${(maxProb * 100).toStringAsFixed(1)}%)');

    return ClassificationResult(
      label: label,
      confidence: maxProb,
      timestamp: DateTime.now(),
    );
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
    print('TFLite service disposed');
  }
}*/


import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../core/constants/app_constants.dart';
import '../models/grain_models.dart';

class TFLiteService {
  Interpreter? _interpreter;
  bool _isLoaded = false;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        AppConstants.modelPath);
      _isLoaded = true;
      print(' TFLite model loaded');
    } catch (e) {
      print(' TFLite load error: $e');
    }
  }

  // EfficientNet preprocessing
    // EfficientNet preprocessing
  List<List<List<List<double>>>> _preprocess(Uint8List imageBytes) {
    img.Image? image = img.decodeImage(imageBytes);
    image = img.copyResize(image!,
        width: AppConstants.modelInputSize,
        height: AppConstants.modelInputSize);

    // Shape: [1, 224, 224, 3]
    var input = List.generate(1, (_) =>
      List.generate(AppConstants.modelInputSize, (y) =>
        List.generate(AppConstants.modelInputSize, (x) =>
          List.generate(3, (c) {
            final pixel = image!.getPixel(x, y);
            double pixelValue;
            
            if (c == 0) {
              pixelValue = img.getRed(pixel) / 255.0;
            } else if (c == 1) {
              pixelValue = img.getGreen(pixel) / 255.0;
            } else {
              pixelValue = img.getBlue(pixel) / 255.0;
            }
            
            // EfficientNet normalization
            return (pixelValue - AppConstants.mean[c]) / AppConstants.std[c];
          })
        )
      )
    );
    return input;
  }

  // Alias methods for backward compatibility with camera_screen.dart
Future<void> initialize() async {
  await loadModel();
}

Future<GrainResult> classifyImage(Uint8List imageBytes) async {
  return classify(imageBytes);
}

  GrainResult classify(Uint8List imageBytes) {
    if (!_isLoaded || _interpreter == null) {
      return GrainResult(
        className: 'unknown',
        confidence: 0.0,
        probabilities: [0, 0, 0],
      );
    }

    var input  = _preprocess(imageBytes);
    var output = List.generate(1, (_) => List.filled(3, 0.0));

    _interpreter!.run(input, output);

    List<double> probs = output[0];
    int predIdx        = probs.indexOf(probs.reduce(
                           (a, b) => a > b ? a : b));

    return GrainResult(
      className     : AppConstants.classNames[predIdx],
      confidence    : probs[predIdx],
      probabilities : probs,
    );
  }

  void dispose() => _interpreter?.close();
}