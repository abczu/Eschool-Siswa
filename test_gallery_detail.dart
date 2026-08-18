import 'dart:io';

void main() async {
  final client = HttpClient();
  
  final urls = [
    "http://devsekolah.eschool.ac.id/storage/87/gallery/compressed/6a3b4e00acdbf7.086042491782271488.png",
    "https://devsekolah.eschool.ac.id/storage/87/gallery/compressed/6a3b4e00acdbf7.086042491782271488.png",
    "http://devsekolah.eschool.ac.id/storage/87/gallery/compressed/6a792ceeb9fd54.330970661786326254.jpg",
    "https://devsekolah.eschool.ac.id/storage/87/gallery/compressed/6a792ceeb9fd54.330970661786326254.jpg",
  ];
  
  client.badCertificateCallback = (cert, host, port) => true;

  for (var urlStr in urls) {
    try {
      final uri = Uri.parse(urlStr);
      final request = await client.getUrl(uri);
      final response = await request.close();
      print("URL: $urlStr -> Status: ${response.statusCode}");
      await response.drain();
    } catch (e) {
      print("URL: $urlStr -> Failed: $e");
    }
  }
  
  client.close();
}
