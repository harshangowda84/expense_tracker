import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/update_service.dart';

class UpdateBanner extends StatefulWidget {
  final UpdateInfo updateInfo;
  final VoidCallback? onDismiss;

  const UpdateBanner({
    super.key,
    required this.updateInfo,
    this.onDismiss,
  });

  @override
  State<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends State<UpdateBanner> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _downloadStatus = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showUpdateDialog(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.system_update,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Update Available!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'v${widget.updateInfo.currentVersion} → v${widget.updateInfo.latestVersion}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.8),
                  size: 16,
                ),
                if (widget.onDismiss != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: widget.onDismiss,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        color: Colors.white.withOpacity(0.8),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: !_isDownloading, // Prevent dismissal during download
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.system_update, color: Color(0xFF6366F1)),
                SizedBox(width: 8),
                Text('Update Available'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.updateInfo.releaseName.isNotEmpty 
                    ? widget.updateInfo.releaseName 
                    : 'Version ${widget.updateInfo.latestVersion}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Current: v${widget.updateInfo.currentVersion}\nLatest: v${widget.updateInfo.latestVersion}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                if (widget.updateInfo.releaseNotes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'What\'s New:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    child: SingleChildScrollView(
                      child: Text(
                        widget.updateInfo.releaseNotes,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
                // Download progress indicator
                if (_isDownloading) ...[
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      LinearProgressIndicator(
                        value: _downloadProgress,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _downloadStatus,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(_downloadProgress * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Color(0xFF6366F1),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            actions: _isDownloading ? [
              // Only show a cancel button during download
              TextButton(
                onPressed: () {
                  setState(() {
                    _isDownloading = false;
                    _downloadProgress = 0.0;
                    _downloadStatus = '';
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
            ] : [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Later'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Download & Install'),
                onPressed: () => _downloadAndInstall(setDialogState),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  void _downloadAndInstall([StateSetter? setDialogState]) async {
    // Update both widget state and dialog state
    void updateState(VoidCallback fn) {
      if (mounted) setState(fn);
      if (setDialogState != null) setDialogState(fn);
    }
    
    // First, immediately show downloading state in the dialog
    updateState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _downloadStatus = 'Initializing download...';
    });
    
    // Small delay to ensure UI updates
    await Future.delayed(const Duration(milliseconds: 200));
    
    try {
      final updateService = UpdateService();
      final fileName = 'spendly_v${widget.updateInfo.latestVersion}.apk';
      
      updateState(() {
        _downloadStatus = 'Starting download...';
      });
      
      print('🚀 Starting download for $fileName');
      
      // Download the APK with real-time progress updates
      final downloadResult = await updateService.downloadApk(
        widget.updateInfo.downloadUrl,
        fileName,
        (progress) {
          print('📊 Progress callback: ${(progress * 100).toStringAsFixed(1)}%');
          updateState(() {
            _downloadProgress = progress;
            _downloadStatus = progress < 1.0 
                ? 'Downloading... ${(progress * 100).toStringAsFixed(1)}%'
                : 'Download complete! Preparing installation...';
          });
          print('🔄 UI Updated: ${_downloadStatus}');
        },
      );
      
      if (downloadResult.success && downloadResult.filePath != null) {
        updateState(() {
          _downloadStatus = 'Download complete! Opening installer...';
        });
        
        // Small delay to show the completion status
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Try to install the APK
        final installSuccess = await updateService.installApk(downloadResult.filePath!);
        
        if (context.mounted) {
          Navigator.of(context).pop();
          
          if (installSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text('Installer opened! Follow the prompts to complete installation.'),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 6),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info, color: Colors.white),
                        SizedBox(width: 12),
                        Text('APK downloaded successfully!'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Location: Downloads/${fileName}\n'
                      'Please enable "Install unknown apps" permission and install manually.',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 10),
              ),
            );
          }
        }
      } else {
        // Download failed, show browser fallback
        if (context.mounted) {
          updateState(() {
            _isDownloading = false;
          });
          _showBrowserFallback(downloadResult.message);
        }
      }
    } catch (e) {
      if (context.mounted) {
        updateState(() {
          _isDownloading = false;
        });
        _showBrowserFallback('Download error: $e');
      }
    }
  }
  
  void _showBrowserFallback(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Download Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              errorMessage,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Alternative options:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Download link:',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    widget.updateInfo.downloadUrl,
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copy Link', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: widget.updateInfo.downloadUrl));
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Download link copied to clipboard!'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[600],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.open_in_browser, size: 16),
                          label: const Text('Open Browser', style: TextStyle(fontSize: 12)),
                          onPressed: () async {
                            final success = await UpdateService().downloadUpdate(widget.updateInfo.downloadUrl);
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Browser opened! Look for the APK download.'),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Could not open browser. Please copy the link and open manually.'),
                                    backgroundColor: Colors.orange,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}