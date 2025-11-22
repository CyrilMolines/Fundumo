import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service for handling app permissions
class PermissionService {
  /// Request camera permission
  Future<PermissionStatus> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status;
  }

  /// Check camera permission status
  Future<PermissionStatus> checkCameraPermission() async {
    return await Permission.camera.status;
  }

  /// Request storage permission (Android) or photos permission (iOS)
  Future<Map<Permission, PermissionStatus>> requestStoragePermission() async {
    if (await Permission.photos.isRestricted) {
      return {Permission.photos: PermissionStatus.restricted};
    }
    
    final statuses = await [
      Permission.photos,
      Permission.storage,
    ].request();
    
    return statuses;
  }

  /// Check storage permission status
  Future<bool> checkStoragePermission() async {
    final photosStatus = await Permission.photos.status;
    final storageStatus = await Permission.storage.status;
    return photosStatus.isGranted || storageStatus.isGranted;
  }

  /// Request notification permission
  Future<PermissionStatus> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status;
  }

  /// Check notification permission status
  Future<PermissionStatus> checkNotificationPermission() async {
    return await Permission.notification.status;
  }

  /// Open app settings
  Future<bool> openAppSettings() async {
    return await Permission.camera.request().then((_) => openAppSettings());
  }

  /// Check if permission is permanently denied
  bool isPermanentlyDenied(PermissionStatus status) {
    return status.isPermanentlyDenied;
  }

  /// Get permission rationale message
  String getPermissionRationale(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return 'Camera access is needed to scan receipts and capture warranty documents.';
      case Permission.photos:
      case Permission.storage:
        return 'Storage access is needed to save receipt images and export data.';
      case Permission.notification:
        return 'Notifications are needed to remind you about subscription renewals and warranty expirations.';
      default:
        return 'This permission is required for the app to function properly.';
    }
  }
}

final permissionServiceProvider = Provider<PermissionService>(
  (ref) => PermissionService(),
);

