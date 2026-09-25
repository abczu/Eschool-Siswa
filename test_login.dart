import 'dart:convert';
import 'dart:io';

void main() async {
  final url = Uri.parse('https://devapisekolah.eschool.ac.id/api/parent/login');
  final request = await HttpClient().postUrl(url);
  request.headers.set('Content-Type', 'application/json');
  request.write(jsonEncode({
    'email': '081234567900',
    'password': '081234567900'
  }));
  final response = await request.close();
  final responseBody = await response.transform(utf8.decoder).join();
  print(responseBody);
}
