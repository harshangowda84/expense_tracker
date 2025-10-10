import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';

class UpdateService {
  static const String _githubApiUrl = 'https://api.github.com/repos/harshangowda84/expense_tracker/releases/latest';
  final Dio _dio = Dio();

  /// Check if an update is available
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      print('🔍 Current app version: $currentVersion');
      
      // Fetch latest release from GitHub
      final response = await _dio.get(_githubApiUrl);
      
      if (response.statusCode == 200) {
        final releaseData = response.data;
        final latestVersion = releaseData['tag_name']?.replaceFirst('v', '') ?? '';
        final releaseName = releaseData['name'] ?? '';
        final releaseNotes = releaseData['body'] ?? '';
        
        print('🌐 Latest GitHub version: $latestVersion');
        
        // Find APK download URL
        String? downloadUrl;
        final assets = releaseData['assets'] as List<dynamic>? ?? [];
        
        for (final asset in assets) {
          final fileName = asset['name'] as String? ?? '';
          if (fileName.toLowerCase().endsWith('.apk')) {
            downloadUrl = asset['browser_download_url'] as String?;
            break;
          }
        }
        
        // Compare versions
        if (_isNewerVersion(currentVersion, latestVersion) && downloadUrl != null) {
          print('✅ Update available: $currentVersion → $latestVersion');
          return UpdateInfo(
            currentVersion: currentVersion,
            latestVersion: latestVersion,
            releaseName: releaseName,
            releaseNotes: releaseNotes,
            downloadUrl: downloadUrl,
          );
        } else {
          print('✅ App is up to date');
          return null;
        }
      }
    } catch (e) {
      print('❌ Error checking for updates: $e');
    }
    return null;
  }
  
  /// Compare two version strings (e.g., "1.0.0" vs "1.0.1")
  bool _isNewerVersion(String current, String latest) {
    final currentParts = current.split('.').map(int.tryParse).where((e) => e != null).cast<int>().toList();
    final latestParts = latest.split('.').map(int.tryParse).where((e) => e != null).cast<int>().toList();
    
    // Ensure both have at least 3 parts (major.minor.patch)
    while (currentParts.length < 3) currentParts.add(0);
    while (latestParts.length < 3) latestParts.add(0);
    
    for (int i = 0; i < 3; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }
  
  /// Request storage permission for Android
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Request install packages permission for APK installation
      var installPermission = await Permission.requestInstallPackages.status;
      if (installPermission.isDenied) {
        installPermission = await Permission.requestInstallPackages.request();
      }
      
      // For Android 13+ (API 33+), we don't need WRITE_EXTERNAL_STORAGE
      // The app can write to its own directory and Downloads folder
      return installPermission.isGranted || installPermission.isLimited;
    }
    return true;
  }
  
  /// Download APK file to device storage
  Future<DownloadResult> downloadApk(String downloadUrl, String fileName, Function(double) onProgress) async {
    try {
      // Request storage permission
      if (!await _requestStoragePermission()) {
        return DownloadResult(
          success: false,
          message: 'Storage permission denied',
        );
      }
      
      // Get downloads directory
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        // Try to get public Downloads directory
        try {
          downloadsDir = Directory('/storage/emulated/0/Download');
          if (!await downloadsDir.exists()) {
            // Fallback to app's external storage
            downloadsDir = await getExternalStorageDirectory();
          }
        } catch (e) {
          // Fallback to app's external storage
          downloadsDir = await getExternalStorageDirectory();
        }
      } else {
        downloadsDir = await getDownloadsDirectory();
      }
      
      if (downloadsDir == null) {
        return DownloadResult(
          success: false,
          message: 'Could not access downloads folder',
        );
      }
      
      final filePath = '${downloadsDir.path}/$fileName';
      print('📥 Downloading APK to: $filePath');
      
      // Download the file
      await _dio.download(
        downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            onProgress(progress);
            print('📥 Download progress: ${(progress * 100).toStringAsFixed(1)}%');
          }
        },
      );
      
      // Verify file was downloaded
      final file = File(filePath);
      if (await file.exists()) {
        final fileSize = await file.length();
        print('✅ APK downloaded successfully: ${fileSize} bytes');
        return DownloadResult(
          success: true,
          filePath: filePath,
          message: 'Download completed',
        );
      } else {
        return DownloadResult(
          success: false,
          message: 'Download failed - file not found',
        );
      }
      
    } catch (e) {
      print('❌ Download error: $e');
      return DownloadResult(
        success: false,
        message: 'Download failed: $e',
      );
    }
  }
  
  /// Install APK file (Android only)
  Future<bool> installApk(String filePath) async {
    try {
      if (!Platform.isAndroid) {
        print('❌ APK installation only supported on Android');
        return false;
      }
      
      final file = File(filePath);
      if (!await file.exists()) {
        print('❌ APK file not found: $filePath');
        return false;
      }
      
      // Check if we have install permission
      var installPermission = await Permission.requestInstallPackages.status;
      if (installPermission.isDenied) {
        print('📋 Requesting install packages permission...');
        installPermission = await Permission.requestInstallPackages.request();
      }
      
      if (installPermission.isDenied || installPermission.isPermanentlyDenied) {
        print('❌ Install packages permission denied');
        return false;
      }
      
      print('📱 Opening APK for installation: $filePath');
      
      // Open the APK file with the system installer
      final result = await OpenFile.open(filePath);
      
      if (result.type == ResultType.done) {
        print('✅ APK installer opened successfully');
        return true;
      } else {
        print('❌ Failed to open APK installer: ${result.message}');
        return false;
      }
      
    } catch (e) {
      print('❌ Installation error: $e');
      return false;
    }
  }
  
  /// Open download URL in browser with improved launch strategy
  Future<bool> downloadUpdate(String downloadUrl) async {
    try {
      print('🔗 Opening download URL: $downloadUrl');
      final uri = Uri.parse(downloadUrl);
      
      // Try multiple launch modes to ensure browser opens
      bool launched = false;
      
      // First try: External application (preferred)
      if (await canLaunchUrl(uri)) {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (launched) {
          print('✅ Opened with external application');
          return true;
        }
      }
      
      // Second try: Platform default
      if (!launched && await canLaunchUrl(uri)) {
        launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
        if (launched) {
          print('✅ Opened with platform default');
          return true;
        }
      }
      
      // Third try: External non-browser application
      if (!launched && await canLaunchUrl(uri)) {
        launched = await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);
        if (launched) {
          print('✅ Opened with external non-browser application');
          return true;
        }
      }
      
      print('❌ All launch methods failed');
      return false;
      
    } catch (e) {
      print('❌ Error opening download URL: $e');
      return false;
    }
  }
}

class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String releaseName;
  final String releaseNotes;
  final String downloadUrl;
  
  UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseName,
    required this.releaseNotes,
    required this.downloadUrl,
  });
  
  @override
  String toString() {
    return 'UpdateInfo(current: $currentVersion, latest: $latestVersion, name: $releaseName)';
  }
}

class DownloadResult {
  final bool success;
  final String? filePath;
  final String message;
  
  DownloadResult({
    required this.success,
    this.filePath,
    required this.message,
  });
  
  @override
  String toString() {
    return 'DownloadResult(success: $success, path: $filePath, message: $message)';
  }
}