import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://presensi-fa.test/api/',
);

Future<String?> _getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('token');
}

Future<List<dynamic>> getPresences() async {
  final token = await _getToken();
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  final response = await http.get(
    Uri.parse('${apiUrl}presence'),
    headers: headers,
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    print(data);

    // Ambil hanya bagian presences
    final presences = data['presences'];

    // Simpan ke SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('presences', jsonEncode(presences));

    return presences;
  } else {
    throw Exception('Gagal mengambil data presensi');
  }
}


Future<http.Response> addPresence(Map<String, dynamic> data) async {
  final token = await _getToken();
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  final response = await http.post(
    Uri.parse('${apiUrl}presence'),
    headers: headers,
    body: jsonEncode(data),
  );

  if (response.statusCode == 200 || response.statusCode == 201) {
    return response;
  } else {
    throw Exception('Gagal membuat data presensi');
  }
}

Future<http.Response> deletePresence(String id) async {
  final token = await _getToken();
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  final response = await http.delete(
    Uri.parse('${apiUrl}presence/$id'),
    headers: headers,
  );

  if (response.statusCode == 200) {
    return response;
  } else {
    throw Exception('Gagal menghapus data presensi');
  }
}

Future<http.Response> updatePresenceStatus(String id, String status) async {
  final token = await _getToken();
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  final data = {'status': status};

  final response = await http.post(
    Uri.parse('${apiUrl}update-presence-status/$id'),
    headers: headers,
    body: jsonEncode(data),
  );

  if (response.statusCode == 200) {
    return response;
  } else {
    throw Exception('Gagal memperbarui status presensi');
  }
}
