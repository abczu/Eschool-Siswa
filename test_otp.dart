import 'dart:convert';
import 'dart:io';

void main() async {
  final url = Uri.parse('https://devapisekolah.eschool.ac.id/api/auth/otp/verify');
  final request = await HttpClient().postUrl(url);
  request.headers.set('Content-Type', 'application/json');
  request.write(jsonEncode({
    'identifier': '081234567900',
    'otp_code': '123456',
    'otp': '123456',
    'code': '123456',
    'otpCode': '123456',
    'fcm_id': ''
  }));
  final response = await request.close();
  final responseBody = await response.transform(utf8.decoder).join();
  print(responseBody);
}
