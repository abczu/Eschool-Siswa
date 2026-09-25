import 'dart:convert';
import 'dart:io';

void main() async {
  final routes = [
    'change-password',
    'parent/change-password',
    'parent/password',
    'parent/update-password',
    'parent/reset-password',
    'guardian/change-password',
    'guardian/password',
    'parent/profile',
    'parent/change-password-all',
  ];

  for (var r in routes) {
    final url = Uri.parse('https://devapisekolah.eschool.ac.id/api/$r');
    final request = await HttpClient().postUrl(url);
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Accept', 'application/json');
    request.write(jsonEncode({}));
    final response = await request.close();
    print('$r -> Status: ${response.statusCode}');
  }
}
