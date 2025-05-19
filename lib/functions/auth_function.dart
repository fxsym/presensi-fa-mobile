// File: lib/auth_function.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String API_AUTH_URL = 'http://presensi-fa.test/api/auth/';

Future<http.Response> loginRequest(
  String userInput,
  String password,
  String deviceName,
) async {
  final url = Uri.parse('${API_AUTH_URL}login');
  final body = {
    "user_input": userInput,
    "password": password,
    "device_name": deviceName,
  };

  print(body);

  final response = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(body),
  );

  print(response);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['token'] != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
    }
  } else {
    throw Exception(jsonDecode(response.body)['message'] ?? 'Login gagal');
  }

  return response;
}

Future<void> logoutRequest() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final response = await http.post(
    Uri.parse('${API_AUTH_URL}logout'),
    headers: {"Authorization": "Bearer $token"},
  );

  if (response.statusCode != 200) {
    throw Exception(jsonDecode(response.body)['message'] ?? 'Logout gagal');
  }

  await prefs.remove('token');
}
