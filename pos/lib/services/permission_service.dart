import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
// Import the package with a prefix to resolve the name conflict
import 'package:permission_handler/permission_handler.dart' as ph;

class PermissionService {
  // ==================== OPEN APP SETTINGS ====================
  
  /// Open the app settings page so user can manually enable permissions
  static Future<void> openAppSettings() async {
    await Permission.camera.request(); 
    // ✅ FIX: Call the package's function using the 'ph' prefix
    // This stops the infinite recursion crash!
    await ph.openAppSettings();
  }
  
  /// Check if a specific permission is granted
  static Future<bool> isPermissionGranted(Permission permission) async {
    final status = await permission.status;
    return status.isGranted;
  }

  // ==================== CAMERA PERMISSION ====================
  
  // Request camera permission
  static Future<bool> requestCameraPermission() async {
    PermissionStatus status = await Permission.camera.request();
    
    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      // Permission denied, but can be requested again
      return false;
    } else if (status.isPermanentlyDenied) {
      // Permission permanently denied, show dialog to open settings
      return false;
    }
    return false;
  }

  // Check if camera permission is granted
  static Future<bool> isCameraPermissionGranted() async {
    PermissionStatus status = await Permission.camera.status;
    return status.isGranted;
  }

  // ==================== MICROPHONE PERMISSION ====================
  
  // Request microphone permission
  static Future<bool> requestMicrophonePermission() async {
    PermissionStatus status = await Permission.microphone.request();
    
    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      return false;
    } else if (status.isPermanentlyDenied) {
      return false;
    }
    return false;
  }

  // Check if microphone permission is granted
  static Future<bool> isMicrophonePermissionGranted() async {
    PermissionStatus status = await Permission.microphone.status;
    return status.isGranted;
  }

  // ==================== LOCATION PERMISSIONS ====================
  
  // Request location permission (fine location)
  static Future<bool> requestLocationPermission() async {
    PermissionStatus status = await Permission.location.request();
    
    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      return false;
    } else if (status.isPermanentlyDenied) {
      return false;
    }
    return false;
  }
  
  // Request location permission (always/background)
  static Future<bool> requestLocationAlwaysPermission() async {
    PermissionStatus status = await Permission.locationAlways.request();
    
    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      return false;
    } else if (status.isPermanentlyDenied) {
      return false;
    }
    return false;
  }
  
  // Request location permission (when in use)
  static Future<bool> requestLocationWhenInUsePermission() async {
    PermissionStatus status = await Permission.locationWhenInUse.request();
    
    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      return false;
    } else if (status.isPermanentlyDenied) {
      return false;
    }
    return false;
  }

  // Check location permission status
  static Future<PermissionStatus> checkLocationPermission() async {
    return await Permission.location.status;
  }
  
  // Check if location permission is granted
  static Future<bool> isLocationPermissionGranted() async {
    PermissionStatus status = await Permission.location.status;
    return status.isGranted;
  }

  // ==================== STORAGE PERMISSIONS (Optional) ====================
  
  // Request storage permission (for Android)
  static Future<bool> requestStoragePermission() async {
    PermissionStatus status = await Permission.storage.request();
    
    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      return false;
    } else if (status.isPermanentlyDenied) {
      return false;
    }
    return false;
  }

  // Check if storage permission is granted
  static Future<bool> isStoragePermissionGranted() async {
    PermissionStatus status = await Permission.storage.status;
    return status.isGranted;
  }

  // ==================== NOTIFICATION PERMISSION (Android 13+) ====================
  
  // Request notification permission
  static Future<bool> requestNotificationPermission() async {
    PermissionStatus status = await Permission.notification.request();
    
    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      return false;
    } else if (status.isPermanentlyDenied) {
      return false;
    }
    return false;
  }

  // Check if notification permission is granted
  static Future<bool> isNotificationPermissionGranted() async {
    PermissionStatus status = await Permission.notification.status;
    return status.isGranted;
  }

  // ==================== COMBINED PERMISSIONS ====================
  
  // Request all permissions (camera, microphone, location)
  static Future<Map<Permission, bool>> requestAllPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
      Permission.location,  // Add location permission
    ].request();
    
    bool cameraGranted = statuses[Permission.camera]?.isGranted ?? false;
    bool micGranted = statuses[Permission.microphone]?.isGranted ?? false;
    bool locationGranted = statuses[Permission.location]?.isGranted ?? false;
    
    return {
      Permission.camera: cameraGranted,
      Permission.microphone: micGranted,
      Permission.location: locationGranted,
    };
  }

  // Request all permissions with storage and notifications
  static Future<Map<Permission, bool>> requestAllPermissionsExtended() async {
    List<Permission> permissions = [
      Permission.camera,
      Permission.microphone,
      Permission.location,
    ];
    
    // Add storage for Android
    if (await _isAndroid()) {
      permissions.add(Permission.storage);
    }
    
    // Add notification for Android 13+
    if (await _isAndroid13Plus()) {
      permissions.add(Permission.notification);
    }
    
    Map<Permission, PermissionStatus> statuses = await permissions.request();
    
    Map<Permission, bool> result = {};
    for (var permission in permissions) {
      result[permission] = statuses[permission]?.isGranted ?? false;
    }
    
    return result;
  }

  // ==================== PERMISSION DIALOGS ====================
  
  // Show permission denied dialog
  static Future<void> showPermissionDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings(); // Safe because we fixed the internal loop
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
  
  // Show location permission denied dialog
  static Future<void> showLocationPermissionDialog(
    BuildContext context,
  ) async {
    return showPermissionDialog(
      context,
      'Location Permission Required',
      'This app needs location access to detect your country automatically.\n\n'
      'Please grant location permission to automatically set your country code.\n'
      'You can also manually select your country from the dropdown.',
    );
  }
  
  // Show location permission permanently denied dialog
  static Future<void> showLocationPermanentlyDeniedDialog(
    BuildContext context,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Permanently Denied'),
        content: const Text(
          'Location permission has been permanently denied.\n\n'
          'You can still manually select your country from the dropdown.\n'
          'If you want to enable location detection, please go to settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // Show camera permission denied dialog
  static Future<void> showCameraPermissionDialog(
    BuildContext context,
  ) async {
    return showPermissionDialog(
      context,
      'Camera Permission Required',
      'This app needs camera access to scan QR codes and barcodes.\n\n'
      'Please grant camera permission to use the scanner features.',
    );
  }

  // Show microphone permission denied dialog
  static Future<void> showMicrophonePermissionDialog(
    BuildContext context,
  ) async {
    return showPermissionDialog(
      context,
      'Microphone Permission Required',
      'This app needs microphone access for voice input.\n\n'
      'Please grant microphone permission to use voice search.',
    );
  }

  // ==================== UTILITY METHODS ====================
  
  // Request location permission with fallback
  static Future<bool> requestLocationWithFallback() async {
    PermissionStatus status = await Permission.location.request();
    
    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      // Permission denied - user can try again
      return false;
    } else if (status.isPermanentlyDenied) {
      // Permission permanently denied - user must go to settings
      return false;
    } else if (status.isRestricted) {
      // Permission restricted (parental controls, etc.)
      return false;
    }
    return false;
  }
  
  // Request multiple location permissions (fine + coarse)
  static Future<bool> requestLocationFineAndCoarse() async {
    // Request fine location (which includes coarse location)
    PermissionStatus status = await Permission.location.request();
    
    if (status.isGranted) {
      return true;
    }
    
    // Try coarse location if fine is not granted
    if (!status.isGranted) {
      PermissionStatus coarseStatus = await Permission.locationWhenInUse.request();
      return coarseStatus.isGranted;
    }
    
    return false;
  }

  // ✅ FIX: Check if device is Android without requiring BuildContext
  static Future<bool> _isAndroid() async {
    try {
      return Platform.isAndroid;
    } catch (e) {
      return false; // Safely return false if running on Web
    }
  }

  // Check if device is Android 13+
  static Future<bool> _isAndroid13Plus() async {
    // Simplified check - return false by default
    // You can use device_info_plus for accurate version checking
    return false;
  }

  // ==================== BATCH PERMISSION CHECKS ====================
  
  /// Check multiple permissions at once
  static Future<Map<Permission, bool>> checkPermissions(
    List<Permission> permissions,
  ) async {
    Map<Permission, bool> results = {};
    for (var permission in permissions) {
      results[permission] = await isPermissionGranted(permission);
    }
    return results;
  }

  /// Check if all required permissions are granted
  static Future<bool> areAllPermissionsGranted(
    List<Permission> permissions,
  ) async {
    for (var permission in permissions) {
      if (!(await isPermissionGranted(permission))) {
        return false;
      }
    }
    return true;
  }

  /// Request permissions and return results
  static Future<Map<Permission, bool>> requestPermissions(
    List<Permission> permissions,
  ) async {
    Map<Permission, PermissionStatus> statuses = await permissions.request();
    
    Map<Permission, bool> results = {};
    for (var permission in permissions) {
      results[permission] = statuses[permission]?.isGranted ?? false;
    }
    return results;
  }
}