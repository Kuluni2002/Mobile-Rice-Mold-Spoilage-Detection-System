/*import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/routes/app_routes.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // Request camera permission
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission required')),
        );
        Navigator.of(context).pop();
      }
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        _controller = CameraController(
          _cameras!.first,
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _controller!.initialize();
        
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final image = await _controller!.takePicture();
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.results,
          arguments: {
            'imagePath': image.path,
            'scanId': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        );
      }
    } catch (e) {
      debugPrint('Error capturing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Capture Rice Sample',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _isInitialized
          ? Stack(
              children: [
                // Camera preview
                Positioned.fill(
                  child: CameraPreview(_controller!),
                ),
                
                // Overlay with guidelines
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                    ),
                    child: Center(
                      child: Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Text(
                            'Position rice sample\nwithin the frame',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Capture button
                Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _captureImage,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 4,
                          ),
                        ),
                        child: _isCapturing
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.grey,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt,
                                size: 40,
                                color: Colors.grey,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
    );
  }
}*/
/*
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../../core/constants/app_colors.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> 
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }
  
  @override
  void dispose() {
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
      _initializeCamera();
    }
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
      );
      
      await _cameraController!.initialize();
      
      if (!mounted) return;
      
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize camera: $e';
      });
    }
  }
  
  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    
    try {
      // Show loading
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Capturing image...')),
      );
      
      final image = await _cameraController!.takePicture();
      
      if (!mounted) return;
      
      // TODO: Navigate to processing screen with image
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image saved: ${image.path}')),
      );
      
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to capture image: $e'),
          backgroundColor: AppColors.spoiled,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Capture Grains'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
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
            ElevatedButton(
              onPressed: _initializeCamera,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (!_isInitialized || _cameraController == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }
    
    return Stack(
      children: [
        // Camera preview
        Center(
          child: CameraPreview(_cameraController!),
        ),
        
        // Overlay guides (basic for now)
        CustomPaint(
          painter: GridOverlayPainter(),
          child: Container(),
        ),
        
        // Bottom controls
        Positioned(
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
                  Colors.black.withOpacity(0.8),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              children: [
                // Instruction text
                const Text(
                  'Spread 50-100 grains evenly',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Capture button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _captureImage,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Grid overlay painter (basic)
class GridOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1;
    
    // Draw center rectangle guide
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.8,
      height: size.height * 0.6,
    );
    
    canvas.drawRect(rect, paint);
    
    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 0.5;
    
    // Vertical lines
    for (int i = 1; i < 3; i++) {
      final x = rect.left + (rect.width * i / 3);
      canvas.drawLine(
        Offset(x, rect.top),
        Offset(x, rect.bottom),
        gridPaint,
      );
    }
    
    // Horizontal lines
    for (int i = 1; i < 3; i++) {
      final y = rect.top + (rect.height * i / 3);
      canvas.drawLine(
        Offset(rect.left, y),
        Offset(rect.right, y),
        gridPaint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}*/

/*import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/image_quality_checker.dart';
import '../../../core/utils/permission_handler.dart';
import '../../widgets/camera/camera_overlay.dart';
import '../../widgets/camera/quality_indicator.dart';
import '../../widgets/camera/distance_indicator.dart';
import '../../../services/tflite_service.dart';
import '../../../models/classification_result.dart';
import '../../../core/routes/app_routes.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> 
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  String? _error;
  
  // Real-time quality feedback
  ImageQualityResult? _qualityResult;
  Timer? _qualityCheckTimer;
  bool _isChecking = false;
  bool _showGuides = true;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }
  
  @override
  void dispose() {
    _qualityCheckTimer?.cancel();
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
      _qualityCheckTimer?.cancel();
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }
  
  Future<void> _checkPermissions() async {
    final hasPermission = await PermissionHandlerUtil.checkCameraPermission();
    
    if (!hasPermission) {
      final granted = await PermissionHandlerUtil.requestCameraPermission();
      
      if (!granted) {
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
        imageFormatGroup: ImageFormatGroup.yuv420, // Better for processing
      );
      
      await _cameraController!.initialize();
      
      if (!mounted) return;
      
      setState(() {
        _isInitialized = true;
      });
      
      // Start real-time quality checks
      _startQualityChecks();
      
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize camera: $e';
      });
    }
  }
  
  void _startQualityChecks() {
    // Check quality every 2 seconds
    _qualityCheckTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _performQualityCheck(),
    );
  }
  
  Future<void> _performQualityCheck() async {
    if (_isChecking || 
        _cameraController == null || 
        !_cameraController!.value.isInitialized) {
      return;
    }
    
    _isChecking = true;
    
    try {
      final image = await _cameraController!.takePicture();
      final imageBytes = await image.readAsBytes();
      
      // Quick check for real-time feedback
      final result = ImageQualityChecker.quickCheck(imageBytes);
      
      if (mounted) {
        setState(() {
          _qualityResult = result;
        });
      }
    } catch (e) {
      // Silently fail for periodic checks
    } finally {
      _isChecking = false;
    }
  }
  
  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    
    try {
      // Stop quality checks during capture
      _qualityCheckTimer?.cancel();
      
      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
      
      final image = await _cameraController!.takePicture();
      final imageBytes = await image.readAsBytes();
      
      // Perform comprehensive quality check
      final qualityResult = await ImageQualityChecker.checkQuality(imageBytes);
      
      if (!mounted) return;
      Navigator.of(context).pop(); // Dismiss loading
      
      if (qualityResult.status == ImageQualityStatus.error) {
        // Show error and don't proceed
        _showQualityError(qualityResult.message ?? 'Image quality is poor');
        
        // Restart quality checks
        _startQualityChecks();
        return;
      }
      
      if (qualityResult.status == ImageQualityStatus.warning) {
        // Show warning but allow to proceed
        final proceed = await _showQualityWarning(
          qualityResult.message ?? 'Image quality could be better',
        );
        
        if (!proceed) {
          // Restart quality checks
          _startQualityChecks();
          return;
        }
      }
      
         // Show classification loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              'Analyzing rice quality...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
    
    // Import TFLite service at the top of file
    final tfliteService = TFLiteService();
    await tfliteService.initialize();
    
    // Classify the image
    final classificationResult = await tfliteService.classifyImage(imageBytes);
    
    // Clean up
    tfliteService.dispose();
    
    if (!mounted) return;
    Navigator.of(context).pop(); // Dismiss classification loading
    
    // Navigate to results with classification data
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.results,
      arguments: {
        'imagePath': image.path,
        'imageBytes': imageBytes,
        'classification': classificationResult,
        'scanId': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
    
  } catch (e) {
    if (!mounted) return;
    
    Navigator.of(context).pop(); // Dismiss any loading dialog
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to process image: $e'),
        backgroundColor: AppColors.spoiled,
      ),
    );
    
    _startQualityChecks();
  }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image captured: ${image.path}'),
          backgroundColor: AppColors.healthy,
        ),
      );
      
      // Restart quality checks
      _startQualityChecks();
      
    } catch (e) {
      if (!mounted) return;
      
      Navigator.of(context).pop(); // Dismiss loading if shown
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to capture image: $e'),
          backgroundColor: AppColors.spoiled,
        ),
      );
      
      // Restart quality checks
      _startQualityChecks();
    }
  }
  
  void _showQualityError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Poor Image Quality'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  Future<bool> _showQualityWarning(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Image Quality Warning'),
        content: Text('$message\n\nDo you want to proceed anyway?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Retake'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            _buildBody(),
            
            // Top bar
            _buildTopBar(),
            
            // Bottom controls
            if (_isInitialized) _buildBottomControls(),
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
              Colors.black.withOpacity(0.6),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const Text(
              'Capture Grains',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
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
            ),
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
            ElevatedButton(
              onPressed: _checkPermissions,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (!_isInitialized || _cameraController == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
            message: _qualityResult?.message,
            messageColor: _getMessageColor(_qualityResult?.status),
          ),
        
        // Quality indicator
        if (_qualityResult != null)
          Positioned(
            top: 100,
            right: 24,
            child: QualityIndicator(result: _qualityResult!),
          ),
        
        // Distance indicator (placeholder)
        const Positioned(
          right: 24,
          top: 200,
          child: DistanceIndicator(distance: 28.0), // Mock distance
        ),
      ],
    );
  }
  
  Color _getMessageColor(ImageQualityStatus? status) {
    switch (status) {
      case ImageQualityStatus.good:
        return AppColors.healthy;
      case ImageQualityStatus.warning:
        return AppColors.earlyRisk;
      case ImageQualityStatus.error:
        return AppColors.spoiled;
      default:
        return AppColors.primary;
    }
  }
  
  Widget _buildBottomControls() {
    final isReady = _qualityResult?.status == ImageQualityStatus.good;
    
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
              Colors.black.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          children: [
            // Instruction text
            const Text(
              'Spread 50-100 grains evenly on white surface',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Tips
            if (!isReady && _qualityResult != null)
              Text(
                'Tip: ${_getQualityTip(_qualityResult!)}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            
            const SizedBox(height: 24),
            
            // Capture button
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _captureImage,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isReady ? AppColors.healthy : Colors.white,
                        width: 4,
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isReady ? AppColors.healthy : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: isReady
                          ? const Icon(Icons.check, color: Colors.white, size: 32)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _getQualityTip(ImageQualityResult result) {
    if (result.isBlurry) {
      return 'Hold your phone steady and ensure good focus';
    } else if (result.isTooDark) {
      return 'Move to a brighter area or turn on more lights';
    } else if (result.isTooBright) {
      return 'Reduce direct light or move to avoid glare';
    }
    return 'Maintain distance of 25-30cm above grains';
  }
}*/

/*import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/image_quality_checker.dart';
import '../../../core/utils/permission_handler.dart';
import '../../../core/routes/app_routes.dart';
import '../../widgets/camera/camera_overlay.dart';
import '../../widgets/camera/quality_indicator.dart';
import '../../widgets/camera/distance_indicator.dart';
import '../../../services/tflite_service.dart';
import '../../../models/classification_result.dart';
import '../results/results_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> 
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  String? _error;
  
  // Image picker
  final ImagePicker _imagePicker = ImagePicker();
  
  // Real-time quality feedback
  ImageQualityResult? _qualityResult;
  Timer? _qualityCheckTimer;
  bool _isChecking = false;
  bool _showGuides = true;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }
  
  @override
  void dispose() {
    _qualityCheckTimer?.cancel();
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
      _qualityCheckTimer?.cancel();
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }
  
  Future<void> _checkPermissions() async {
    final hasPermission = await PermissionHandlerUtil.checkCameraPermission();
    
    if (!hasPermission) {
      final granted = await PermissionHandlerUtil.requestCameraPermission();
      
      if (!granted) {
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
      
      setState(() {
        _isInitialized = true;
      });
      
      // Start real-time quality checks
      _startQualityChecks();
      
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize camera: $e';
      });
    }
  }
  
  void _startQualityChecks() {
    // Check quality every 3 seconds (increased interval)
    _qualityCheckTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _performQualityCheck(),
    );
  }
  
  Future<void> _performQualityCheck() async {
    if (_isChecking || 
        _cameraController == null || 
        !_cameraController!.value.isInitialized) {
      return;
    }
    
    _isChecking = true;
    
    try {
      final image = await _cameraController!.takePicture();
      final imageBytes = await image.readAsBytes();
      
      // Quick check for real-time feedback (skip TFLite for periodic checks)
      final result = ImageQualityChecker.quickCheck(imageBytes);
      
      if (mounted) {
        setState(() {
          _qualityResult = result;
        });
      }
      
      // Clean up the temporary file
      await File(image.path).delete().catchError((_) {});
      
    } catch (e) {
      // Silently fail for periodic checks
      debugPrint('Quality check failed: $e');
    } finally {
      _isChecking = false;
    }
  }
  
  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    
    try {
      _qualityCheckTimer?.cancel();
      
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                'Capturing image...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
      
      final image = await _cameraController!.takePicture();
      final imageBytes = await image.readAsBytes();
      
      if (!mounted) return;
      
      await _processImage(image.path, imageBytes);
      
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error capturing image: $e'),
          backgroundColor: AppColors.spoiled,
        ),
      );
      
      _startQualityChecks();
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // Reduced from 100 to avoid memory issues
        maxWidth: 1024,   // Limit image size
        maxHeight: 1024,
      );
      
      if (pickedFile == null) return;
      
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                'Processing selected image...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
      
      // Read image bytes
      final File imageFile = File(pickedFile.path);
      final Uint8List imageBytes = await imageFile.readAsBytes();
      
      if (!mounted) return;
      
      await _processImage(pickedFile.path, imageBytes);
      
    } catch (e) {
      if (!mounted) return;
      
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: AppColors.spoiled,
        ),
      );
    }
  }

 // Update the _processImage method with better debugging:

Future<void> _processImage(String imagePath, Uint8List imageBytes) async {
  TFLiteService? tfliteService;
  
  try {
    // Update loading message
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              'Analyzing rice quality...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
    
    // Initialize two-stage TFLite service
    tfliteService = TFLiteService();
    
    debugPrint('=== Starting Two-Stage TFLite Analysis ===');
    debugPrint('Image size: ${imageBytes.length} bytes');
    
    await tfliteService.loadStageModels();
    debugPrint('Stage models loaded');
    
    final grainClassification = await tfliteService.classifyGrain(imageBytes);
    debugPrint('Stage 1 probs: ${grainClassification.stage1Probs}');
    debugPrint('Stage 2 probs: ${grainClassification.stage2Probs}');
    debugPrint('Final label: ${grainClassification.finalLabel}');
    
        if (grainClassification.finalLabel.startsWith('error')) {
      throw Exception(grainClassification.finalLabel);
    }
    // Derive a single confidence value to pass to ResultsScreen.
    // Use the winning probability from whichever stage produced the final label.
    double confidence;
    final s2 = grainClassification.stage2Probs;
    if (s2 != null) {
      // Stage 2 ran: confidence = max(stage2Probs)
      confidence = s2[0] >= s2[1] ? s2[0] : s2[1];
    } else {
      // Healthy (or stage2 missing): confidence = stage1Probs[0] (healthy prob)
      final s1 = grainClassification.stage1Probs;
      confidence = s1.isNotEmpty ? (s1[0] >= s1[1] ? s1[0] : s1[1]) : 0.0;
    }
    
    if (!mounted) return;
    Navigator.of(context).pop(); // Dismiss loading
    
    debugPrint('=== About to navigate ===');
    debugPrint('Label: ${grainClassification.finalLabel}');
    debugPrint('Confidence: $confidence');
    
    // Use direct navigation — same args as before so ResultsScreen works unchanged
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ResultsScreen(),
        settings: RouteSettings(
          arguments: {
            'imagePath': imagePath,
            'imageBytes': imageBytes,
            'label': grainClassification.finalLabel,
            'confidence': confidence,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'scanId': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        ),
      ),
    );
    
    debugPrint('=== Navigation called ===');
    
  } catch (e, stackTrace) {
    debugPrint('=== TFLite Error ===');
    debugPrint('Error: $e');
    debugPrint('Stack trace: $stackTrace');
    
    if (!mounted) return;
    
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    
    // Show specific error information
    String errorTitle = 'Processing Error';
    String errorMessage = e.toString();
    
    if (errorMessage.contains('Model file not found')) {
      errorTitle = 'Model Not Found';
      errorMessage = 'The AI model file could not be loaded. Please check if the model file exists in assets/models/';
    } else if (errorMessage.contains('Failed to initialize')) {
      errorTitle = 'Model Loading Failed';
      errorMessage = 'The AI model could not be initialized. This might be due to model compatibility issues.';
    } else if (errorMessage.contains('tensor')) {
      errorTitle = 'Model Input Error';
      errorMessage = 'There was an issue with the model input format. The image might not be compatible.';
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(errorTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(errorMessage),
            const SizedBox(height: 16),
            const Text(
              'Debug Information:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Image size: ${imageBytes.length} bytes',
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
            Text(
              'Error: ${e.runtimeType}',
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (_isInitialized) {
                _startQualityChecks();
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
    
  } finally {
    // Clean up
    try {
      tfliteService?.dispose();
    } catch (e) {
      debugPrint('Error disposing TFLite service: $e');
    }
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
  
  void _showQualityError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Poor Image Quality'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  Future<bool> _showQualityWarning(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Image Quality Warning'),
        content: Text('$message\n\nDo you want to proceed anyway?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Retake'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            _buildBody(),
            
            // Top bar
            _buildTopBar(),
            
            // Bottom controls
            _buildBottomControls(),
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
              onPressed: () => Navigator.of(context).pop(),
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
                  onPressed: _checkPermissions,
                  child: const Text('Retry Camera'),
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
            message: _qualityResult?.message,
            messageColor: _getMessageColor(_qualityResult?.status),
          ),
        
        // Quality indicator
        if (_qualityResult != null)
          Positioned(
            top: 100,
            right: 24,
            child: QualityIndicator(result: _qualityResult!),
          ),
        
        // Distance indicator (placeholder)
        const Positioned(
          right: 24,
          top: 200,
          child: DistanceIndicator(distance: 28.0), // Mock distance
        ),
      ],
    );
  }
  
  Color _getMessageColor(ImageQualityStatus? status) {
    switch (status) {
      case ImageQualityStatus.good:
        return AppColors.healthy;
      case ImageQualityStatus.warning:
        return AppColors.earlyRisk;
      case ImageQualityStatus.error:
        return AppColors.spoiled;
      default:
        return AppColors.primary;
    }
  }
  
  Widget _buildBottomControls() {
    final isReady = _qualityResult?.status == ImageQualityStatus.good;
    
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
            // Instruction text
            const Text(
              'Spread 5-20 grains evenly on dark surface',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Tips
            if (_isInitialized && !isReady && _qualityResult != null)
              Text(
                'Tip: ${_getQualityTip(_qualityResult!)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
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
  
  String _getQualityTip(ImageQualityResult result) {
    if (result.isBlurry) {
      return 'Hold your phone steady and ensure good focus';
    } else if (result.isTooDark) {
      return 'Move to a brighter area or turn on more lights';
    } else if (result.isTooBright) {
      return 'Reduce direct light or move to avoid glare';
    }
    return 'Maintain distance of 25-30cm above grains';
  }
}*/


import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/image_quality_checker.dart';
import '../../../core/utils/permission_handler.dart';
import '../../widgets/camera/camera_overlay.dart';
import '../../widgets/camera/quality_indicator.dart';
import '../../widgets/camera/distance_indicator.dart';
import '../../../services/tflite_service.dart';
import '../../../services/grain_segmenter.dart';
import '../results/results_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> 
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  String? _error;
  
  // Image picker
  final ImagePicker _imagePicker = ImagePicker();
  
  // Real-time quality feedback
  ImageQualityResult? _qualityResult;
  Timer? _qualityCheckTimer;
  bool _isChecking = false;
  bool _showGuides = true;

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

  void _restartQualityChecks() {
    _qualityCheckTimer?.cancel();
    if (_isInitialized) _startQualityChecks();
  }
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }
  
  @override
  void dispose() {
    _qualityCheckTimer?.cancel();
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
      _qualityCheckTimer?.cancel();
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }
  
  Future<void> _checkPermissions() async {
    final hasPermission = await PermissionHandlerUtil.checkCameraPermission();
    
    if (!hasPermission) {
      final granted = await PermissionHandlerUtil.requestCameraPermission();
      
      if (!granted) {
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
      
      setState(() {
        _isInitialized = true;
      });
      
      // Start real-time quality checks
      _startQualityChecks();
      
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize camera: $e';
      });
    }
  }
  
  void _startQualityChecks() {
    // Check quality every 3 seconds (increased interval)
    _qualityCheckTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _performQualityCheck(),
    );
  }
  
  Future<void> _performQualityCheck() async {
    if (_isChecking || 
        _cameraController == null || 
        !_cameraController!.value.isInitialized) {
      return;
    }
    
    _isChecking = true;
    
    try {
      final image = await _cameraController!.takePicture();
      final imageBytes = await image.readAsBytes();
      
      // Quick check for real-time feedback (skip TFLite for periodic checks)
      final result = ImageQualityChecker.quickCheck(imageBytes);
      
      if (mounted) {
        setState(() {
          _qualityResult = result;
        });
      }
      
      // Clean up the temporary file
      await File(image.path).delete().catchError((_) {});
      
    } catch (e) {
      // Silently fail for periodic checks
      debugPrint('Quality check failed: $e');
    } finally {
      _isChecking = false;
    }
  }
  
  Future<void> _captureImage() async {
    if (_isAnalyzing ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      _qualityCheckTimer?.cancel();

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
      _restartQualityChecks();
    }
  }

  Future<void> _pickImageFromGallery() async {
    if (_isAnalyzing) return;

    try {
      // No size limits: the segmenter needs the original full-resolution photo.
      final XFile? pickedFile =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      final Uint8List imageBytes = await File(pickedFile.path).readAsBytes();
      if (!mounted) return;

      _qualityCheckTimer?.cancel();
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
      _restartQualityChecks();
    }
  }

  // Full pile pipeline: MobileSAM segmentation -> Stage 1 / Stage 2 per grain
  // -> counts -> highest count wins (tie: the more severe class wins).
  Future<void> _processImage(String imagePath, Uint8List imageBytes) async {
    GrainSegmenter? segmenter;
    TFLiteService? tflite;
    final sw = Stopwatch()..start();

    try {
      debugPrint('=== Pile analysis start: ${imageBytes.length} bytes ===');

      // 1. Segment grains (MobileSAM ONNX, runs in an isolate)
      _setStage('Finding grains... this can take up to a minute');
      segmenter = GrainSegmenter();
      await segmenter.init();
      final crops = await segmenter.segment(imageBytes);
      debugPrint('Segmentation: ${crops.length} grains, ${sw.elapsedMilliseconds} ms');
      if (crops.isEmpty) throw Exception('No grains detected');

      // 2. Classify every crop (Stage 1, then Stage 2 for mold only)
      tflite = TFLiteService();
      await tflite.loadStageModels();

      final counts = <String, int>{
        AppConstants.classHealthy: 0,
        AppConstants.classEarlyRisk: 0,
        AppConstants.classSpoiled: 0,
      };
      for (var i = 0; i < crops.length; i++) {
        _setStage('Checking grain ${i + 1} of ${crops.length}...');
        final r = await tflite.classifyGrain(crops[i].pngBytes);
        if (r.finalLabel.startsWith('error')) {
          debugPrint('Grain $i skipped: ${r.finalLabel}');
          continue;
        }
        counts[r.finalLabel] = counts[r.finalLabel]! + 1;
        debugPrint('Grain $i -> ${r.finalLabel}  s1=${r.stage1Probs}  s2=${r.stage2Probs}');
      }
      final total = counts.values.fold<int>(0, (a, b) => a + b);
      if (total == 0) throw Exception('Could not classify any grain');

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
            },
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('=== Pile analysis error ===\n$e\n$stackTrace');
      if (!mounted) return;
      _resetAnalysis();
      _restartQualityChecks();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Analysis failed'),
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      segmenter?.dispose();
      tflite?.dispose();
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
  
  void _showQualityError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Poor Image Quality'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  Future<bool> _showQualityWarning(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Image Quality Warning'),
        content: Text('$message\n\nDo you want to proceed anyway?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Retake'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
    
    return result ?? false;
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
              onPressed: () => Navigator.of(context).pop(),
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
                  onPressed: _checkPermissions,
                  child: const Text('Retry Camera'),
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
            message: _qualityResult?.message,
            messageColor: _getMessageColor(_qualityResult?.status),
          ),
        
        // Quality indicator
        if (_qualityResult != null)
          Positioned(
            top: 100,
            right: 24,
            child: QualityIndicator(result: _qualityResult!),
          ),
        
        // Distance indicator (placeholder)
        const Positioned(
          right: 24,
          top: 200,
          child: DistanceIndicator(distance: 28.0), // Mock distance
        ),
      ],
    );
  }
  
  Color _getMessageColor(ImageQualityStatus? status) {
    switch (status) {
      case ImageQualityStatus.good:
        return AppColors.healthy;
      case ImageQualityStatus.warning:
        return AppColors.earlyRisk;
      case ImageQualityStatus.error:
        return AppColors.spoiled;
      default:
        return AppColors.primary;
    }
  }
  
  Widget _buildBottomControls() {
    final isReady = _qualityResult?.status == ImageQualityStatus.good;
    
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
            // Instruction text
            const Text(
              'Spread 5-20 grains evenly on dark surface',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Tips
            if (_isInitialized && !isReady && _qualityResult != null)
              Text(
                'Tip: ${_getQualityTip(_qualityResult!)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
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
  
  String _getQualityTip(ImageQualityResult result) {
    if (result.isBlurry) {
      return 'Hold your phone steady and ensure good focus';
    } else if (result.isTooDark) {
      return 'Move to a brighter area or turn on more lights';
    } else if (result.isTooBright) {
      return 'Reduce direct light or move to avoid glare';
    }
    return 'Maintain distance of 25-30cm above grains';
  }
}