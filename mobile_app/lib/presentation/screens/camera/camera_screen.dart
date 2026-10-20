


import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/image_quality_checker.dart';
import '../../../core/utils/permission_handler.dart';
import '../../../core/errors/analysis_failure.dart';
import '../../widgets/camera/camera_overlay.dart';
import '../../widgets/camera/distance_indicator.dart';
import '../../../services/tflite_service.dart';
import '../../../services/grain_segmenter.dart';
import '../results/results_screen.dart';
import '../../widgets/common/error_dialog.dart';

class CameraScreen extends StatefulWidget {
  final String? batchId;

  const CameraScreen({
    super.key,
    this.batchId,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> 
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  String? _error;
  bool _permissionPermanentlyDenied = false;
  
  // Image picker
  final ImagePicker _imagePicker = ImagePicker();
  
  // Real-time quality feedback
  bool _showGuides = true;
  bool _cancelRequested = false;

  // Picked / captured photo shown in the scan area while it is analysed
  Uint8List? _pickedBytes;
  bool _isAnalyzing = false;
  String _analysisStage = 'Preparing image...';

  void _setStage(String text) {
    if (mounted) setState(() => _analysisStage = text);
  }

  void _resetAnalysis() {
    if (!mounted) return;
    setState(() {
      _pickedBytes = null;
      _isAnalyzing = false;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }
  
  @override
  void dispose() {
    _cancelRequested = true;
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? controller = _cameraController;
    
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }
  
  Future<void> _checkPermissions() async {
    final hasPermission = await PermissionHandlerUtil.checkCameraPermission();
    
    if (!hasPermission) {
      _permissionPermanentlyDenied =
          await PermissionHandlerUtil.isCameraPermissionPermanentlyDenied();
      final granted = await PermissionHandlerUtil.requestCameraPermission();
      
      if (!granted) {
        if (!mounted) return;
        setState(() {
          _error = 'Camera permission is required to scan grains';
        });
        return;
      }
    }
    
    _initializeCamera();
  }
  
  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _error = 'No cameras available';
        });
        return;
      }
      
      // Use back camera
      final camera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );
      
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg, // Changed from yuv420 to jpeg
      );
      
      await _cameraController!.initialize();
      
      if (!mounted) return;
      
      if (!mounted) return;
      setState(() {
        _isInitialized = true;
        _error = null;
      });
      
      // Start real-time quality checks
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = AnalysisFailure.from(e).message);
    }
  }
  
  Future<void> _captureImage() async {
    if (_isAnalyzing ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final image = await _cameraController!.takePicture();
      final imageBytes = await image.readAsBytes();

      if (!mounted) return;
      setState(() {
        _pickedBytes = imageBytes;
        _isAnalyzing = true;
        _analysisStage = 'Preparing image...';
      });

      await _processImage(image.path, imageBytes);
    } catch (e) {
      if (!mounted) return;
      _resetAnalysis();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error capturing image: $e'),
          backgroundColor: AppColors.spoiled,
        ),
      );
      await _showFailure(AnalysisFailure.from(e), onRetry: _captureImage);
    }
  }

  Future<void> _pickImageFromGallery() async {
    if (_isAnalyzing) return;

    try {
      final XFile? pickedFile =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      final Uint8List imageBytes = await File(pickedFile.path).readAsBytes();
      if (!mounted) return;

      setState(() {
        _pickedBytes = imageBytes;
        _isAnalyzing = true;
        _analysisStage = 'Preparing image...';
      });

      await _processImage(pickedFile.path, imageBytes);
    } catch (e) {
      if (!mounted) return;
      _resetAnalysis();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: AppColors.spoiled,
        ),
      );
      await _showFailure(AnalysisFailure.from(e), onChooseAnotherPhoto: _pickImageFromGallery);
    }
  }

  // Full pile pipeline: MobileSAM segmentation -> Stage 1 / Stage 2 per grain
  // -> counts -> highest count wins (tie: the more severe class wins).
  Future<void> _processImage(String imagePath, Uint8List imageBytes) async {
    GrainSegmenter? segmenter;
    TFLiteService? tflite;
    final sw = Stopwatch()..start();

    try {
      if (imageBytes.length > AppConstants.maxImageBytes) {
        throw const AnalysisFailure(
          kind: FailureKind.imageTooLarge,
          title: 'Photo is too large',
          message: 'This photo is larger than 25 MB.',
          hint: 'Choose a smaller JPEG or PNG photo.',
        );
      }
      final dimensions = ImageQualityChecker.readDimensions(imageBytes);
      if (dimensions == null) {
        throw const AnalysisFailure(
          kind: FailureKind.imageUnreadable,
          title: 'Photo could not be read',
          message: 'Unsupported or damaged image.',
          hint: 'Use a JPEG or PNG photo.',
        );
      }
      final longSide = dimensions.reduce((a, b) => a > b ? a : b);
      if (longSide < 600) {
        throw const AnalysisFailure(
          kind: FailureKind.imageTooSmall,
          title: 'Photo is too small',
          message: 'The photo needs a longer side of at least 600 pixels.',
          hint: 'Move closer or choose a higher-resolution photo.',
        );
      }
      debugPrint('=== Pile analysis start: ${imageBytes.length} bytes ===');

      // 1. Segment grains (MobileSAM ONNX, runs in an isolate)
      _setStage('Finding grains... this can take up to a minute');
      segmenter = GrainSegmenter();
      await segmenter.init();
      final crops = await segmenter.segment(imageBytes).timeout(AppConstants.analysisTimeout);
      debugPrint('Segmentation: ${crops.length} grains, ${sw.elapsedMilliseconds} ms');
      if (crops.isEmpty) {
        throw const AnalysisFailure(
          kind: FailureKind.noGrains,
          title: 'No grains found',
          message: 'No grains were found. Use a plain background, even light, and spread the grains apart.',
          hint: 'Retake the photo with grains separated.',
        );
      }

      // 2. Classify every crop (Stage 1, then Stage 2 for mold only)
      tflite = TFLiteService();
      await tflite.loadStageModels();

      final counts = <String, int>{
        AppConstants.classHealthy: 0,
        AppConstants.classEarlyRisk: 0,
        AppConstants.classSpoiled: 0,
      };
      var failedClassifications = 0;
      for (var i = 0; i < crops.length; i++) {
        if (_cancelRequested || !mounted) return;
        _setStage('Checking grain ${i + 1} of ${crops.length}...');
        final r = await tflite.classifyGrain(crops[i].pngBytes);
        if (r.finalLabel.startsWith('error')) {
          debugPrint('Grain $i skipped: ${r.finalLabel}');
          failedClassifications++;
          continue;
        }
        counts[r.finalLabel] = counts[r.finalLabel]! + 1;
        debugPrint('Grain $i -> ${r.finalLabel}  s1=${r.stage1Probs}  s2=${r.stage2Probs}');
      }
      final total = counts.values.fold<int>(0, (a, b) => a + b);
      if (total == 0) {
        throw const AnalysisFailure(
          kind: FailureKind.model,
          title: 'Models unavailable',
          message: 'The analysis models could not be loaded. Restart the app.',
          hint: 'Restart the app and try again.',
        );
      }
      final report = segmenter.lastReport;
      final warnings = <String>[];
      if (longSide < AppConstants.minImageLongSide) warnings.add('Low-resolution photo. Results may be less reliable.');
      if (report != null && report.sharpness < AppConstants.blurTileVarianceMin) warnings.add('The photo looks blurry. Retake it with the phone held steady.');
      if (report?.grainCapReached == true) warnings.add('Only the first 150 grains were analysed.');
      if (failedClassifications > 0) warnings.add('$failedClassifications grains could not be checked.');

      // 3. Highest count wins; on a tie the more severe class wins
      const severityOrder = [
        AppConstants.classSpoiled,
        AppConstants.classEarlyRisk,
        AppConstants.classHealthy,
      ];
      var finalLabel = severityOrder.first;
      for (final c in severityOrder) {
        if (counts[c]! > counts[finalLabel]!) finalLabel = c;
      }
      final confidence = counts[finalLabel]! / total;
      debugPrint('Counts: $counts  total=$total  FINAL=$finalLabel  '
          '(${sw.elapsedMilliseconds} ms)');

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ResultsScreen(),
          settings: RouteSettings(
            arguments: {
              'imagePath': imagePath,
              'imageBytes': imageBytes,
              'label': finalLabel,
              'confidence': confidence,
              'counts': counts,
              'totalGrains': total,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
              'scanId': DateTime.now().millisecondsSinceEpoch.toString(),
              'batchId': widget.batchId,
              'warnings': warnings,
            },
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('=== Pile analysis error ===\n$e\n$stackTrace');
      if (!mounted) return;
      _resetAnalysis();
      await _showFailure(AnalysisFailure.from(e), onRetry: () => _captureImage(), onChooseAnotherPhoto: _pickImageFromGallery);
    } finally {
      segmenter?.dispose();
      tflite?.dispose();
    }

  }

  Future<void> _showFailure(
    AnalysisFailure failure, {
    VoidCallback? onRetry,
    VoidCallback? onChooseAnotherPhoto,
  }) => showFailureDialog(context, failure, onRetry: onRetry, onChooseAnotherPhoto: onChooseAnotherPhoto);

  Future<void> _handleBack() async {
    if (!_isAnalyzing) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final cancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel analysis?'),
        content: const Text('The current analysis will be stopped.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep analysing')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cancel')),
        ],
      ),
    );
    if (cancel == true && mounted) {
      _cancelRequested = true;
      Navigator.of(context).pop();
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Image Source',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            
            // Camera option
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text(
                'Camera',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Take a new photo',
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _captureImage();
              },
            ),
            
            const Divider(color: Colors.grey),
            
            // Gallery option
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text(
                'Gallery',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Choose from existing photos',
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _pickImageFromGallery();
              },
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            _buildBody(),

            // The picked / captured photo, shown while it is analysed
            if (_pickedBytes != null) _buildAnalysisOverlay(),

            // Top bar
            _buildTopBar(),

            // Bottom controls
            if (!_isAnalyzing) _buildBottomControls(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAnalysisOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black,
        child: Stack(
          children: [
            Center(
              child: Image.memory(
                _pickedBytes!,
                fit: BoxFit.contain,
                cacheWidth: 1280,
                gaplessPlayback: true,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _analysisStage,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.6),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: _handleBack,
            ),
            const Text(
              'Scan Grains',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_isInitialized)
              IconButton(
                icon: Icon(
                  _showGuides ? Icons.grid_off : Icons.grid_on,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _showGuides = !_showGuides;
                  });
                },
              )
            else
              const SizedBox(width: 48), // Placeholder for layout
          ],
        ),
      ),
    );
  }
  
  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 80,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _permissionPermanentlyDenied
                      ? PermissionHandlerUtil.openAppSettings
                      : _checkPermissions,
                  child: Text(_permissionPermanentlyDenied
                      ? 'Open settings'
                      : 'Allow camera'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _pickImageFromGallery,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Use Gallery'),
                ),
              ],
            ),
          ],
        ),
      );
    }
    
    if (!_isInitialized || _cameraController == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 24),
            const Text(
              'Initializing camera...',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _pickImageFromGallery,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
              child: const Text('Or select from gallery'),
            ),
          ],
        ),
      );
    }
    
    return Stack(
      children: [
        // Camera preview
        Center(
          child: AspectRatio(
            aspectRatio: _cameraController!.value.aspectRatio,
            child: CameraPreview(_cameraController!),
          ),
        ),
        
        // Overlay guides
        if (_showGuides)
          CameraOverlay(
            showGuides: _showGuides,
          ),
        
        // Quality indicator
        
        // Distance indicator (placeholder)
        const Positioned(
          right: 24,
          top: 200,
          child: DistanceIndicator(distance: 28.0), // Mock distance
        ),
      ],
    );
  }
  
  Widget _buildBottomControls() {
    const isReady = true;
    
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          children: [
            const Text(
              'Place the grains on a plain, evenly lit surface',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            
            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Gallery button
                GestureDetector(
                  onTap: _pickImageFromGallery,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.photo_library,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                
                // Capture button (main)
                GestureDetector(
                  onTap: _isInitialized ? _showImageSourceDialog : _pickImageFromGallery,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isInitialized && isReady ? AppColors.healthy : Colors.white,
                        width: 4,
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _isInitialized && isReady ? AppColors.healthy : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: _isInitialized && isReady
                          ? const Icon(Icons.check, color: Colors.white, size: 32)
                          : const Icon(Icons.camera_alt, color: Colors.grey, size: 32),
                    ),
                  ),
                ),
                
                // Placeholder for symmetry
                const SizedBox(width: 60, height: 60),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
}