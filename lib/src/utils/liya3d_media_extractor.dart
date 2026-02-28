import '../models/liya3d_media_item.dart';

/// Result of media extraction from content
class Liya3dMediaExtractResult {
  /// Clean text content without media markdown
  final String cleanText;

  /// Extracted media items
  final List<Liya3dMediaItem> media;

  const Liya3dMediaExtractResult({
    required this.cleanText,
    required this.media,
  });
}

/// Utility class to extract media (images/videos) from message content
class Liya3dMediaExtractor {
  /// Regex for markdown images: ![alt](url)
  static final RegExp _imageRegex = RegExp(r'!\[([^\]]*)\]\(([^)]+)\)');

  /// Regex for video links: [text](url.mp4|webm|mov)
  static final RegExp _videoRegex = RegExp(
    r'\[([^\]]*)\]\((https?://[^)]+\.(?:mp4|webm|mov))\)',
    caseSensitive: false,
  );

  /// Extract media from content
  /// 
  /// If [backendMedia] is provided and not empty, uses that instead of parsing markdown.
  /// This ensures backward compatibility while preferring backend-provided media.
  static Liya3dMediaExtractResult extract(
    String content, {
    List<Liya3dMediaItem>? backendMedia,
  }) {
    // If backend media is provided, use it
    if (backendMedia != null && backendMedia.isNotEmpty) {
      final cleanText = content
          .replaceAll(_imageRegex, '')
          .replaceAll(_videoRegex, '')
          .trim();
      return Liya3dMediaExtractResult(
        cleanText: cleanText,
        media: backendMedia,
      );
    }

    // Fallback: Parse markdown
    final List<Liya3dMediaItem> media = [];

    // Extract images
    for (final match in _imageRegex.allMatches(content)) {
      final alt = match.group(1) ?? 'Görsel';
      final url = match.group(2);
      if (url != null && url.isNotEmpty) {
        media.add(Liya3dMediaItem(
          type: 'image',
          url: url,
          alt: alt,
        ));
      }
    }

    // Extract videos
    for (final match in _videoRegex.allMatches(content)) {
      final alt = match.group(1) ?? 'Video';
      final url = match.group(2);
      if (url != null && url.isNotEmpty) {
        media.add(Liya3dMediaItem(
          type: 'video',
          url: url,
          alt: alt,
        ));
      }
    }

    // Clean text
    final cleanText = content
        .replaceAll(_imageRegex, '')
        .replaceAll(_videoRegex, '')
        .trim();

    return Liya3dMediaExtractResult(
      cleanText: cleanText,
      media: media,
    );
  }

  /// Check if content contains any media
  static bool hasMedia(String content) {
    return _imageRegex.hasMatch(content) || _videoRegex.hasMatch(content);
  }
}
