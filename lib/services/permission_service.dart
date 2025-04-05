import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  // Check and request all required permissions
  static Future<bool> checkAndRequestAllPermissions(BuildContext context) async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.camera,
      Permission.microphone,
    ].request();

    bool allGranted = true;
    statuses.forEach((permission, status) {
      if (!status.isGranted) {
        allGranted = false;
      }
    });

    if (!allGranted) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permissions Required'),
            content: const Text(
              'This app requires location, camera, and microphone permissions to function properly. Please grant these permissions in your device settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => openAppSettings(),
                child: const Text('Open Settings'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      }
    }

    return allGranted;
  }

  // Check if all permissions are granted
  static Future<bool> checkPermissions() async {
    bool cameraStatus = await Permission.camera.isGranted;
    bool locationStatus = await Permission.location.isGranted;
    bool locationAlwaysStatus = await Permission.locationAlways.isGranted;
    bool locationWhenInUseStatus = await Permission.locationWhenInUse.isGranted;

    return cameraStatus && 
           locationStatus && 
           (locationAlwaysStatus || locationWhenInUseStatus);
  }

  // Request camera permission
  static Future<bool> requestCameraPermission() async {
    PermissionStatus status = await Permission.camera.request();
    return status.isGranted;
  }

  // Request location permission
  static Future<bool> requestLocationPermission() async {
    PermissionStatus status = await Permission.location.request();
    return status.isGranted;
  }

  // Request background location permission
  static Future<bool> requestBackgroundLocationPermission() async {
    PermissionStatus status = await Permission.locationAlways.request();
    return status.isGranted;
  }

  // Toggle flashlight
  static Future<bool> toggleFlashlight() async {
    if (await Permission.camera.isGranted) {
      try {
        // Note: You'll need to implement the actual torch control using the camera plugin
        return true;
      } catch (e) {
        debugPrint('Error toggling flashlight: $e');
      }
    }
    return false;
  }

  // Helper method to get permission name
  static String _getPermissionName(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return 'Camera';
      case Permission.location:
        return 'Location';
      case Permission.locationAlways:
        return 'Background Location';
      case Permission.locationWhenInUse:
        return 'Location When In Use';
      default:
        return permission.toString();
    }
  }
} 