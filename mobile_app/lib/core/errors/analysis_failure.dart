import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum FailureKind {
  permission,
  imageUnreadable,
  imageTooLarge,
  imageTooSmall,
  noGrains,
  segmentation,
  model,
  timeout,
  unknown,
}

class AnalysisFailure implements Exception {
  final FailureKind kind;
  final String title;
  final String message;
  final String hint;
  final bool canOpenSettings;

  const AnalysisFailure({
    required this.kind,
    required this.title,
    required this.message,
    required this.hint,
    this.canOpenSettings = false,
  });

  factory AnalysisFailure.from(Object error) {
    debugPrint('Analysis failure: $error');
    if (error is AnalysisFailure) return error;
    if (error is TimeoutException) {
      return const AnalysisFailure(
        kind: FailureKind.timeout,
        title: 'Analysis timed out',
        message: 'The photo took too long to analyse.',
        hint: 'Try a clear photo with the grains spread farther apart.',
      );
    }
    if (error is PlatformException &&
        (error.code.toLowerCase().contains('permission') ||
            error.code.toLowerCase().contains('denied'))) {
      return const AnalysisFailure(
        kind: FailureKind.permission,
        title: 'Permission needed',
        message: 'Camera or photo permission is needed to continue.',
        hint: 'Allow access in Settings, or choose another photo.',
        canOpenSettings: true,
      );
    }
    if (error is CameraException) {
      return const AnalysisFailure(
        kind: FailureKind.permission,
        title: 'Camera unavailable',
        message: 'The camera could not be started.',
        hint: 'Close other camera apps and try again, or use the gallery.',
      );
    }
    if (error is FileSystemException) {
      return const AnalysisFailure(
        kind: FailureKind.imageUnreadable,
        title: 'Photo could not be read',
        message: 'This photo could not be opened.',
        hint: 'Use a JPEG or PNG photo.',
      );
    }
    final description = error.toString().toLowerCase();
    if (description.contains('cannot decode') ||
        description.contains('unsupported') ||
        description.contains('damaged image')) {
      return const AnalysisFailure(
        kind: FailureKind.imageUnreadable,
        title: 'Photo could not be read',
        message: 'Unsupported or damaged image.',
        hint: 'Use a JPEG or PNG photo.',
      );
    }
    if (error is StateError) {
      return const AnalysisFailure(
        kind: FailureKind.segmentation,
        title: 'Segmentation failed',
        message: 'The grains could not be separated from this photo.',
        hint: 'Use a plain background and spread the grains apart.',
      );
    }
    return const AnalysisFailure(
      kind: FailureKind.unknown,
      title: 'Analysis failed',
      message: 'The photo could not be analysed.',
      hint: 'Try another photo or try again.',
    );
  }

  @override
  String toString() => '$title: $message';
}
