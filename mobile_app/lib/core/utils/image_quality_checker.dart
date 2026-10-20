import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../constants/app_constants.dart';

class ImageQualityResult {
  final bool isBlurry;
  final bool isTooDark;
  final bool isTooBright;
  final double blurScore;
  final double brightness;
  final String? message;
  final ImageQualityStatus status;
  
  ImageQualityResult({
    required this.isBlurry,
    required this.isTooDark,
    required this.isTooBright,
    required this.blurScore,
    required this.brightness,
    this.message,
    required this.status,
  });
  
  bool get isGood => status == ImageQualityStatus.good;
}

enum ImageQualityStatus {
  good,
  warning,
  error,
}

class ImageQualityChecker {
  static List<int>? readDimensions(Uint8List imageBytes) {
    try {
      final image = img.decodeImage(imageBytes);
      return image == null ? null : [image.width, image.height];
    } catch (_) {
      return null;
    }
  }
  /// Check blur using Laplacian variance
  static Future<double> calculateBlurScore(Uint8List imageBytes) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return 0.0;
      
      // Convert to grayscale
      final grayscale = img.grayscale(image);
      
      // Calculate Laplacian variance (simplified)
      double variance = 0.0;
      int count = 0;
      
      for (int y = 1; y < grayscale.height - 1; y++) {
        for (int x = 1; x < grayscale.width - 1; x++) {
          // Laplacian kernel approximation
          final centerPixel = grayscale.getPixel(x, y);
          final topPixel = grayscale.getPixel(x, y - 1);
          final bottomPixel = grayscale.getPixel(x, y + 1);
          final leftPixel = grayscale.getPixel(x - 1, y);
          final rightPixel = grayscale.getPixel(x + 1, y);
          
          /*final center = img.getRed(centerPixel);
          final top = img.getRed(topPixel);
          final bottom = img.getRed(bottomPixel);
          final left = img.getRed(leftPixel);
          final right = img.getRed(rightPixel);*/

          final center = (centerPixel >> 16) & 0xFF;
          final top = (topPixel >> 16) & 0xFF;
          final bottom = (bottomPixel >> 16) & 0xFF;
          final left = (leftPixel >> 16) & 0xFF;
          final right = (rightPixel >> 16) & 0xFF;
          
          final laplacian = (4 * center - top - bottom - left - right).abs();
          variance += laplacian * laplacian;
          count++;
        }
      }
      
      return variance / count;
    } catch (e) {
      return 0.0;
    }
  }
  
  /// Calculate average brightness
  static Future<double> calculateBrightness(Uint8List imageBytes) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return 0.0;
      
      double totalBrightness = 0.0;
      int pixelCount = 0;
      
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          // Extract RGB values from packed integer
           final r = (pixel >> 16) & 0xFF;
          final g = (pixel >> 8) & 0xFF;
          final b = pixel & 0xFF;
          
          // Calculate perceived brightness
          final brightness = (0.299 * r + 0.587 * g + 0.114 * b);
          totalBrightness += brightness;
          pixelCount++;
        }
      }
      
      return totalBrightness / pixelCount;
    } catch (e) {
      return 0.0;
    }
  }
  
  /// Comprehensive quality check
  static Future<ImageQualityResult> checkQuality(Uint8List imageBytes) async {
    final blurScore = await calculateBlurScore(imageBytes);
    final brightness = await calculateBrightness(imageBytes);
    
    final isBlurry = blurScore < AppConstants.blurThreshold;
    final isTooDark = brightness < AppConstants.minBrightness;
    final isTooBright = brightness > AppConstants.maxBrightness;
    
    String? message;
    ImageQualityStatus status;
    
    if (isBlurry && (isTooDark || isTooBright)) {
      message = 'Image is blurry and lighting is poor';
      status = ImageQualityStatus.error;
    } else if (isBlurry) {
      message = 'Hold steady - image is blurry';
      status = ImageQualityStatus.warning;
    } else if (isTooDark) {
      message = 'Too dark - improve lighting';
      status = ImageQualityStatus.warning;
    } else if (isTooBright) {
      message = 'Too bright - reduce glare';
      status = ImageQualityStatus.warning;
    } else {
      message = 'Image quality is good';
      status = ImageQualityStatus.good;
    }
    
    return ImageQualityResult(
      isBlurry: isBlurry,
      isTooDark: isTooDark,
      isTooBright: isTooBright,
      blurScore: blurScore,
      brightness: brightness,
      message: message,
      status: status,
    );
  }
  
  /// Quick check for real-time feedback (less accurate but faster)
  static ImageQualityResult quickCheck(Uint8List imageBytes) {
    // Simplified check using image package
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        return ImageQualityResult(
          isBlurry: false,
          isTooDark: false,
          isTooBright: false,
          blurScore: 0,
          brightness: 0,
          message: 'Cannot analyze image',
          status: ImageQualityStatus.error,
        );
      }
      
      // Sample center region for quick brightness check
      double totalBrightness = 0;
      int sampleCount = 0;
      
      final centerX = image.width ~/ 2;
      final centerY = image.height ~/ 2;
      final sampleSize = 50;
      
      for (int y = centerY - sampleSize; y < centerY + sampleSize && y < image.height; y++) {
        for (int x = centerX - sampleSize; x < centerX + sampleSize && x < image.width; x++) {
          if (x >= 0 && y >= 0) {
            final pixel = image.getPixel(x, y);
            // Extract RGB values from packed integer
             final r = (pixel >> 16) & 0xFF;
            final g = (pixel >> 8) & 0xFF;
            final b = pixel & 0xFF;
            totalBrightness += (0.299 * r + 0.587 * g + 0.114 * b);
            sampleCount++;
          }
        }
      }
      
      final brightness = totalBrightness / sampleCount;
      final isTooDark = brightness < AppConstants.minBrightness;
      final isTooBright = brightness > AppConstants.maxBrightness;
      
      String message = 'Ready to capture';
      ImageQualityStatus status = ImageQualityStatus.good;
      
      if (isTooDark) {
        message = 'Too dark - improve lighting';
        status = ImageQualityStatus.warning;
      } else if (isTooBright) {
        message = 'Too bright - reduce glare';
        status = ImageQualityStatus.warning;
      }
      
      return ImageQualityResult(
        isBlurry: false, // Skip blur check for speed
        isTooDark: isTooDark,
        isTooBright: isTooBright,
        blurScore: 0,
        brightness: brightness,
        message: message,
        status: status,
      );
    } catch (e) {
      return ImageQualityResult(
        isBlurry: false,
        isTooDark: false,
        isTooBright: false,
        blurScore: 0,
        brightness: 0,
        message: 'Error analyzing image',
        status: ImageQualityStatus.error,
      );
    }
  }
}