import 'package:permission_handler/permission_handler.dart' as ph;

class PermissionHandlerUtil {
  /// Request camera permission
  static Future<bool> requestCameraPermission() async {
    final status = await ph.Permission.camera.request();
    return status.isGranted;
  }
  
  /// Check if camera permission is granted
  static Future<bool> checkCameraPermission() async {
    final status = await ph.Permission.camera.status;
    return status.isGranted;
  }
  
  /// Check if camera permission is permanently denied
  static Future<bool> isCameraPermissionPermanentlyDenied() async {
    final status = await ph.Permission.camera.status;
    return status.isPermanentlyDenied;
  }
  
  /// Open app settings
  static Future<void> openAppSettings() async {
    await ph.openAppSettings();
  }
  
  /// Request storage permission (for saving images)
  static Future<bool> requestStoragePermission() async {
    final status = await ph.Permission.storage.request();
    return status.isGranted;
  }
  
  /// Check storage permission
  static Future<bool> checkStoragePermission() async {
    final status = await ph.Permission.storage.status;
    return status.isGranted;
  }
}