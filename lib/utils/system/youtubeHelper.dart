/// Helper YouTube tanpa package player tambahan.
///
/// Video YouTube dibuka di aplikasi YouTube (eksternal) sehingga seluruh
/// fitur murni milik YouTube — tanpa kontrol custom dan tanpa package
/// player di dalam aplikasi.
class YoutubeHelper {
  static final List<RegExp> _idPatterns = [
    // https://www.youtube.com/watch?v=VIDEO_ID / youtu.be/watch?v=...
    RegExp(r'[?&]v=([A-Za-z0-9_-]{11})'),
    // https://youtu.be/VIDEO_ID
    RegExp(r'youtu\.be/([A-Za-z0-9_-]{11})'),
    // https://www.youtube.com/embed/VIDEO_ID, /shorts/, /live/, /v/
    RegExp(r'youtube(?:-nocookie)?\.com/(?:embed|shorts|live|v)/([A-Za-z0-9_-]{11})'),
  ];

  static final RegExp _plainId = RegExp(r'^[A-Za-z0-9_-]{11}$');

  /// Mengambil ID video YouTube (11 karakter) dari berbagai format URL.
  /// Mengembalikan null jika bukan URL YouTube yang valid.
  static String? extractYoutubeId(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final input = url.trim();
    for (final pattern in _idPatterns) {
      final match = pattern.firstMatch(input);
      if (match != null) return match.group(1);
    }
    if (_plainId.hasMatch(input)) return input;
    return null;
  }

  /// URL thumbnail YouTube tanpa package.
  static String thumbnailUrlForId(String videoId) =>
      'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

  /// Thumbnail dari URL, atau null jika ID tidak bisa diambil.
  static String? thumbnailUrl(String? url) {
    final id = extractYoutubeId(url);
    if (id == null) return null;
    return thumbnailUrlForId(id);
  }

}
