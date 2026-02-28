import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../models/liya3d_media_item.dart';
import '../utils/liya3d_colors.dart';

/// Full-screen media preview dialog for images and videos
class Liya3dMediaPreviewDialog extends StatefulWidget {
  /// The media item to preview
  final Liya3dMediaItem media;

  const Liya3dMediaPreviewDialog({
    super.key,
    required this.media,
  });

  /// Show the dialog
  static Future<void> show(BuildContext context, Liya3dMediaItem media) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) => Liya3dMediaPreviewDialog(media: media),
    );
  }

  @override
  State<Liya3dMediaPreviewDialog> createState() => _Liya3dMediaPreviewDialogState();
}

class _Liya3dMediaPreviewDialogState extends State<Liya3dMediaPreviewDialog> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isVideoError = false;

  @override
  void initState() {
    super.initState();
    if (widget.media.isVideo) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.media.url),
      );
      await _videoController!.initialize();
      await _videoController!.play();
      if (mounted) {
        setState(() => _isVideoInitialized = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isVideoError = true);
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _handleDownload() async {
    final uri = Uri.tryParse(widget.media.url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          // Content
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Media content
                      Flexible(
                        child: _buildMediaContent(),
                      ),
                      // Actions
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Download button
                            ElevatedButton.icon(
                              onPressed: _handleDownload,
                              icon: const Icon(Icons.download, size: 18),
                              label: const Text('İndir'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Close button
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaContent() {
    if (widget.media.isImage) {
      return InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Image.network(
          widget.media.url,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 300,
              height: 300,
              alignment: Alignment.center,
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: const Color(0xFF6366F1),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 300,
              height: 200,
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.broken_image_outlined,
                    color: Liya3dColors.textMuted,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Görsel yüklenemedi',
                    style: TextStyle(
                      color: Liya3dColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    // Video
    if (_isVideoError) {
      return Container(
        width: 300,
        height: 200,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Liya3dColors.textMuted,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              'Video yüklenemedi',
              style: TextStyle(
                color: Liya3dColors.textMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (!_isVideoInitialized) {
      return Container(
        width: 300,
        height: 200,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(
          color: Color(0xFF6366F1),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: _videoController!.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_videoController!),
          // Play/Pause overlay
          GestureDetector(
            onTap: () {
              setState(() {
                if (_videoController!.value.isPlaying) {
                  _videoController!.pause();
                } else {
                  _videoController!.play();
                }
              });
            },
            child: AnimatedOpacity(
              opacity: _videoController!.value.isPlaying ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
