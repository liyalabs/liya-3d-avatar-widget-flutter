/// Media item model for images and videos in chat messages
class Liya3dMediaItem {
  /// Media type: 'image' or 'video'
  final String type;

  /// Media URL
  final String url;

  /// Alt text / description
  final String? alt;

  /// Thumbnail URL (optional)
  final String? thumbnailUrl;

  /// Width in pixels (optional)
  final int? width;

  /// Height in pixels (optional)
  final int? height;

  /// Duration in seconds (for videos)
  final int? durationSeconds;

  const Liya3dMediaItem({
    required this.type,
    required this.url,
    this.alt,
    this.thumbnailUrl,
    this.width,
    this.height,
    this.durationSeconds,
  });

  /// Check if this is an image
  bool get isImage => type == 'image';

  /// Check if this is a video
  bool get isVideo => type == 'video';

  factory Liya3dMediaItem.fromJson(Map<String, dynamic> json) {
    return Liya3dMediaItem(
      type: json['type'] as String? ?? 'image',
      url: json['url'] as String,
      alt: json['alt'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      width: json['width'] as int?,
      height: json['height'] as int?,
      durationSeconds: json['duration_seconds'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'url': url,
      if (alt != null) 'alt': alt,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
    };
  }

  Liya3dMediaItem copyWith({
    String? type,
    String? url,
    String? alt,
    String? thumbnailUrl,
    int? width,
    int? height,
    int? durationSeconds,
  }) {
    return Liya3dMediaItem(
      type: type ?? this.type,
      url: url ?? this.url,
      alt: alt ?? this.alt,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      width: width ?? this.width,
      height: height ?? this.height,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }

  @override
  String toString() {
    return 'Liya3dMediaItem(type: $type, url: $url, alt: $alt)';
  }
}
