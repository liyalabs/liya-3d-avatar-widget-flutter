/// TTS (Text-to-Speech) text cleaning utilities.
/// Strips markdown, URLs, emojis for clean speech output.
class Liya3dTtsUtils {
  Liya3dTtsUtils._();

  /// Strip markdown links: [text](url) → text
  static String _stripMarkdownLinks(String text) {
    return text.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\([^)]+\)'),
      (m) => m.group(1) ?? '',
    );
  }

  /// Strip bare URLs (http/https)
  static String _stripBareUrls(String text) {
    return text.replaceAll(RegExp(r'https?://[^\s)>\]]+'), '');
  }

  /// Strip markdown formatting (bold, italic, heading, list markers)
  static String _stripMarkdownFormatting(String text) {
    var result = text;
    result = result.replaceAll(RegExp(r'#{1,6}\s*'), '');
    result = result.replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (m) => m.group(1) ?? '');
    result = result.replaceAllMapped(RegExp(r'\*([^*]+)\*'), (m) => m.group(1) ?? '');
    result = result.replaceAllMapped(RegExp(r'__([^_]+)__'), (m) => m.group(1) ?? '');
    result = result.replaceAllMapped(RegExp(r'_([^_]+)_'), (m) => m.group(1) ?? '');
    result = result.replaceAllMapped(RegExp(r'~~([^~]+)~~'), (m) => m.group(1) ?? '');
    result = result.replaceAllMapped(RegExp(r'`([^`]+)`'), (m) => m.group(1) ?? '');
    result = result.replaceAll(RegExp(r'^[-*+]\s+', multiLine: true), '');
    result = result.replaceAll(RegExp(r'^\d+\.\s+', multiLine: true), '');
    return result;
  }

  /// Strip emojis
  static String _stripEmojis(String text) {
    return text.replaceAll(
      RegExp(
        r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}'
        r'\u{1F1E0}-\u{1F1FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}'
        r'\u{FE00}-\u{FE0F}\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}'
        r'\u{1FA70}-\u{1FAFF}\u{200D}\u{20E3}\u{FE0F}]',
        unicode: true,
      ),
      '',
    );
  }

  /// Normalize whitespace
  static String _normalizeWhitespace(String text) {
    return text
        .replaceAll(RegExp(r'\n{2,}'), '. ')
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }

  /// Full TTS text cleaning pipeline.
  /// Strips markdown links (keeps label), bare URLs, formatting, emojis.
  static String stripForTTS(String text) {
    if (text.isEmpty) return '';
    var clean = text;
    clean = _stripMarkdownLinks(clean);
    clean = _stripBareUrls(clean);
    clean = _stripMarkdownFormatting(clean);
    clean = _stripEmojis(clean);
    clean = _normalizeWhitespace(clean);
    return clean;
  }
}
