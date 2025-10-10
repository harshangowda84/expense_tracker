import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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