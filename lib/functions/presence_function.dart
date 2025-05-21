import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'dart:io';

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

Future<http.StreamedResponse> addPresence({
  required String lab,
  String? note,
  File? imageFile, // untuk mobile
  Uint8List? webImageBytes, // untuk web
  required bool isWeb,
}) async {
  final token = await _getToken();

  var uri = Uri.parse('${apiUrl}presence');
  var request =
      http.MultipartRequest('POST', uri)
        ..headers.addAll({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        })
        ..fields['lab'] = lab;

  if (note != null) {
    request.fields['note'] = note;
  }

  if (isWeb && webImageBytes != null) {
    request.files.add(
      http.MultipartFile.fromBytes(
        'image', // nama field di backend
        webImageBytes,
        filename: 'web_upload.jpg',
      ),
    );
  } else if (!isWeb && imageFile != null) {
    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
      ),
    );
  }

  return await request.send();
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
