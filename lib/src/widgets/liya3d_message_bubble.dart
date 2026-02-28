import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/liya3d_message.dart';
import '../models/liya3d_enums.dart';
import '../models/liya3d_media_item.dart';
import '../utils/liya3d_colors.dart';
import '../utils/liya3d_glass_decoration.dart';
import '../utils/liya3d_media_extractor.dart';

/// Chat message bubble with Liquid Glass styling
class Liya3dMessageBubble extends StatefulWidget {
  /// The message to display
  final Liya3dMessage message;

  /// Callback when a suggestion is tapped
  final ValueChanged<String>? onSuggestionTap;

  /// Callback when media is tapped (for preview)
  final ValueChanged<Liya3dMediaItem>? onMediaTap;

  /// Maximum width ratio (0.0 - 1.0)
  final double maxWidthRatio;

  const Liya3dMessageBubble({
    super.key,
    required this.message,
    this.onSuggestionTap,
    this.onMediaTap,
    this.maxWidthRatio = 0.8,
  });

  @override
  State<Liya3dMessageBubble> createState() => _Liya3dMessageBubbleState();
}

class _Liya3dMessageBubbleState extends State<Liya3dMessageBubble> {
  bool _copySuccess = false;
  late Liya3dMediaExtractResult _mediaResult;

  bool get isUser => widget.message.role == Liya3dMessageRole.user;

  @override
  void initState() {
    super.initState();
    _extractMedia();
  }

  @override
  void didUpdateWidget(covariant Liya3dMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.content != widget.message.content ||
        oldWidget.message.media != widget.message.media) {
      _extractMedia();
    }
  }

  void _extractMedia() {
    _mediaResult = Liya3dMediaExtractor.extract(
      widget.message.content,
      backendMedia: widget.message.media,
    );
  }

  Future<void> _handleCopy() async {
    await Clipboard.setData(ClipboardData(text: widget.message.content));
    if (!mounted) return;
    setState(() => _copySuccess = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copySuccess = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth * widget.maxWidthRatio;

    // Typing indicator
    if (widget.message.isTyping) {
      return _buildTypingIndicator();
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        margin: EdgeInsets.only(
          left: isUser ? 48 : 8,
          right: isUser ? 8 : 48,
          top: 4,
          bottom: 4,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Message bubble
            ClipRRect(
              borderRadius: _getBorderRadius(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: Liya3dGlassDecoration.messageBubble(isUser: isUser),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Message content — render markdown for assistant (without media markdown)
                      if (!isUser && _mediaResult.cleanText.isNotEmpty)
                        _MarkdownBody(text: _mediaResult.cleanText)
                      else if (isUser)
                        Text(
                          widget.message.content,
                          style: TextStyle(
                            color: Liya3dColors.textLight,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      // Media thumbnails (images/videos)
                      if (_mediaResult.media.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _mediaResult.media.map((media) {
                              return _buildMediaThumbnail(media);
                            }).toList(),
                          ),
                        ),
                      // Response time (for assistant messages)
                      if (!isUser && widget.message.responseTime != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${widget.message.responseTime!.toStringAsFixed(1)}s',
                            style: TextStyle(
                              color: Liya3dColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // Copy button (assistant messages only)
            if (!isUser && widget.message.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: GestureDetector(
                  onTap: _handleCopy,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.transparent,
                    ),
                    child: Icon(
                      _copySuccess ? Icons.check : Icons.copy_outlined,
                      size: 14,
                      color: _copySuccess
                          ? const Color(0xFF22C55E)
                          : Liya3dColors.textMuted,
                    ),
                  ),
                ),
              ),
            // Suggestions (for assistant messages)
            if (!isUser &&
                widget.message.suggestions != null &&
                widget.message.suggestions!.isNotEmpty)
              _buildSuggestions(),
          ],
        ),
      ),
    );
  }

  BorderRadius _getBorderRadius() {
    if (isUser) {
      return const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
        bottomLeft: Radius.circular(16),
        bottomRight: Radius.circular(4),
      );
    } else {
      return const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
        bottomLeft: Radius.circular(4),
        bottomRight: Radius.circular(16),
      );
    }
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: Liya3dGlassDecoration.messageBubble(isUser: false),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            const SizedBox(width: 4),
            _buildDot(1),
            const SizedBox(width: 4),
            _buildDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Liya3dColors.textMuted.withValues(alpha: 0.5 + (value * 0.5)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildSuggestions() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: widget.message.suggestions!.map((suggestion) {
          return GestureDetector(
            onTap: () => widget.onSuggestionTap?.call(suggestion),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: Liya3dGlassDecoration.suggestionChip(),
              child: Text(
                suggestion,
                style: TextStyle(
                  color: Liya3dColors.suggestionText,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMediaThumbnail(Liya3dMediaItem media) {
    return GestureDetector(
      onTap: () => widget.onMediaTap?.call(media),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 200,
          maxHeight: 150,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Image thumbnail
            if (media.isImage)
              Image.network(
                media.url,
                fit: BoxFit.cover,
                width: 200,
                height: 150,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 200,
                    height: 150,
                    color: Colors.white.withValues(alpha: 0.05),
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 200,
                    height: 150,
                    color: Colors.white.withValues(alpha: 0.05),
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Liya3dColors.textMuted,
                        size: 32,
                      ),
                    ),
                  );
                },
              ),
            // Video thumbnail (placeholder with play icon)
            if (media.isVideo)
              Container(
                width: 200,
                height: 150,
                color: Colors.black,
                child: Stack(
                  children: [
                    // Video thumbnail could be loaded from thumbnailUrl if available
                    if (media.thumbnailUrl != null)
                      Image.network(
                        media.thumbnailUrl!,
                        fit: BoxFit.cover,
                        width: 200,
                        height: 150,
                      ),
                    // Play button overlay
                    Center(
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Hint text at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Text(
                  media.isImage ? '🖼 Tıkla — büyüt' : '🎬 Tıkla — izle',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lightweight markdown renderer for chat messages.
/// Supports: bold, italic, links, inline code, headings, lists.
class _MarkdownBody extends StatelessWidget {
  final String text;
  const _MarkdownBody({required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Text.rich(
      _parseMarkdown(text),
      style: TextStyle(
        color: Liya3dColors.textLight,
        fontSize: 14,
        height: 1.4,
      ),
    );
  }

  TextSpan _parseMarkdown(String input) {
    final spans = <InlineSpan>[];
    // Split into lines for heading/list detection
    final lines = input.split('\n');

    for (int i = 0; i < lines.length; i++) {
      if (i > 0) spans.add(const TextSpan(text: '\n'));
      var line = lines[i];

      // Headings (# ## ###)
      final headingMatch = RegExp(r'^#{1,3}\s+(.+)$').firstMatch(line);
      if (headingMatch != null) {
        spans.addAll(_parseInline(headingMatch.group(1)!, bold: true));
        continue;
      }

      // List items (- or *)
      final listMatch = RegExp(r'^[-*]\s+(.+)$').firstMatch(line);
      if (listMatch != null) {
        spans.add(const TextSpan(text: '• '));
        spans.addAll(_parseInline(listMatch.group(1)!));
        continue;
      }

      // Numbered list
      final numMatch = RegExp(r'^\d+\.\s+(.+)$').firstMatch(line);
      if (numMatch != null) {
        final num = RegExp(r'^(\d+\.)').firstMatch(line)!.group(1)!;
        spans.add(TextSpan(text: '$num '));
        spans.addAll(_parseInline(numMatch.group(1)!));
        continue;
      }

      spans.addAll(_parseInline(line));
    }

    return TextSpan(children: spans);
  }

  /// Parse inline markdown: bold, italic, links, inline code
  List<InlineSpan> _parseInline(String text, {bool bold = false}) {
    final spans = <InlineSpan>[];
    // Pattern matches: [text](url), **bold**, *italic*, `code`
    final regex = RegExp(
      r'\[([^\]]+)\]\((https?://[^)]+)\)'  // markdown link
      r'|\*\*([^*]+)\*\*'                   // bold
      r'|\*([^*]+)\*'                        // italic
      r'|`([^`]+)`'                          // inline code
    );

    int lastEnd = 0;
    for (final match in regex.allMatches(text)) {
      // Plain text before match
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null,
        ));
      }

      if (match.group(1) != null && match.group(2) != null) {
        // Markdown link: [text](url)
        final linkText = match.group(1)!;
        final url = match.group(2)!;
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: GestureDetector(
            onTap: () => _openUrl(url),
            child: Text(
              linkText,
              style: TextStyle(
                color: const Color(0xFFA5B4FC),
                decoration: TextDecoration.underline,
                decorationColor: const Color(0xFFA5B4FC).withValues(alpha: 0.5),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ));
      } else if (match.group(3) != null) {
        // Bold
        spans.add(TextSpan(
          text: match.group(3),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ));
      } else if (match.group(4) != null) {
        // Italic
        spans.add(TextSpan(
          text: match.group(4),
          style: const TextStyle(fontStyle: FontStyle.italic),
        ));
      } else if (match.group(5) != null) {
        // Inline code
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              match.group(5)!,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Liya3dColors.textLight,
              ),
            ),
          ),
        ));
      }

      lastEnd = match.end;
    }

    // Remaining text after last match
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null,
      ));
    }

    // If no matches at all, return the whole text
    if (spans.isEmpty) {
      spans.add(TextSpan(
        text: text,
        style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null,
      ));
    }

    return spans;
  }

  void _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
