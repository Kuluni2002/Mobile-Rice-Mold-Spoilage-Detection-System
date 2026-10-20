import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class CameraOverlay extends StatelessWidget {
  final bool showGuides;
  final String? message;
  final Color? messageColor;
  
  const CameraOverlay({
    super.key,
    this.showGuides = true,
    this.message,
    this.messageColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dimmed overlay
        if (showGuides)
          CustomPaint(
            painter: OverlayPainter(),
            child: Container(),
          ),
        
        // Guide rectangle
        if (showGuides)
          CustomPaint(
            painter: GuideRectanglePainter(),
            child: Container(),
          ),
        
        // Corner markers
        if (showGuides)
          CustomPaint(
            painter: CornerMarkersPainter(),
            child: Container(),
          ),
        
        // Message overlay
        if (message != null)
          Positioned(
            top: 100,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (messageColor ?? AppColors.primary).withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class OverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5);
    
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final rectWidth = size.width * 0.85;
    final rectHeight = size.height * 0.65;
    
    final rect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: rectWidth,
      height: rectHeight,
    );
    
    // Draw dimmed area around the rectangle
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(rect)
      ..fillType = PathFillType.evenOdd;
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GuideRectanglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final rectWidth = size.width * 0.85;
    final rectHeight = size.height * 0.65;
    
    final rect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: rectWidth,
      height: rectHeight,
    );
    
    canvas.drawRect(rect, paint);
    
    // Draw grid lines (3x3)
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1;
    
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
}

class CornerMarkersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.healthy
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final rectWidth = size.width * 0.85;
    final rectHeight = size.height * 0.65;
    
    final rect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: rectWidth,
      height: rectHeight,
    );
    
    const markerLength = 30.0;
    
    // Top-left corner
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left + markerLength, rect.top),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left, rect.top + markerLength),
      paint,
    );
    
    // Top-right corner
    canvas.drawLine(
      Offset(rect.right, rect.top),
      Offset(rect.right - markerLength, rect.top),
      paint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.top + markerLength),
      paint,
    );
    
    // Bottom-left corner
    canvas.drawLine(
      Offset(rect.left, rect.bottom),
      Offset(rect.left + markerLength, rect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.bottom),
      Offset(rect.left, rect.bottom - markerLength),
      paint,
    );
    
    // Bottom-right corner
    canvas.drawLine(
      Offset(rect.right, rect.bottom),
      Offset(rect.right - markerLength, rect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.bottom),
      Offset(rect.right, rect.bottom - markerLength),
      paint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}