import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String apiUrl = String.fromEnvironment(
  'API_URL',
  // defaultValue: 'http://presensi-fa.test/api/',
  defaultValue: 'https://presensi-fa-api.vercel.app/api/api/',
);

Future<http.StreamedResponse> registerUser({
  required Map<String, String> fields,
  File? imageFile, // mobile
  Uint8List? webImageBytes, // web
  required bool isWeb,
}) async {
  final uri = Uri.parse('${apiUrl}user');
  final request = http.MultipartRequest('POST', uri)
    ..headers.addAll({
      'Accept': 'application/json',
    });

  // Tambahkan field form
  fields.forEach((key, value) {
    request.fields[key] = value;
  });

  // Tambahkan gambar
  if (isWeb && webImageBytes != null) {
    request.files.add(
      http.MultipartFile.fromBytes(
        'image', // nama field yang digunakan di backend
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


Future<Map<String, dynamic>> updateUser(
  Map<String, String> data,
  String id, {
  bool isFormData = false,
  dynamic imageFile,
  bool isWeb = false,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  try {
    late http.Response response;
    var uri = Uri.parse('${apiUrl}user/$id');

    if (isFormData) {
      var request = http.MultipartRequest('POST', uri);
      request.headers.addAll(headers);

      // Tambahkan field teks/form
      data.forEach((key, value) {
        request.fields[key] = value;
      });

      // Tambahkan file gambar jika ada
      if (imageFile != null) {
        if (isWeb && imageFile is Uint8List) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'image',
              imageFile,
              filename: 'image.jpg',
            ),
          );
        } else if (imageFile is File) {
          request.files.add(
            await http.MultipartFile.fromPath('image', imageFile.path),
          );
        }
      }
      var streamedResponse = await request.send();
      response = await http.Response.fromStream(streamedResponse);
    } else {
      response = await http.patch(
        uri,
        headers: {...headers, 'Content-Type': 'application/json'},
        body: json.encode(data),
      );
    }

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    final Map<String, dynamic> responseJson = json.decode(response.body);

    if (response.statusCode == 200) {
      final userData = responseJson['user'] ?? responseJson;
      await prefs.setString('user', jsonEncode(userData));
      return responseJson;
    } else {
      throw responseJson;
    }
  } catch (e, stack) {
    print('Catch error: $e');
    print('Stack trace: $stack');
    throw {'message': 'Gagal mengupdate akun', 'errors': e.toString()};
  }
}

Future<Map<String, dynamic>> getMembersData() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final headers = {'Authorization': 'Bearer $token'};

  try {
    final response = await http.get(
      Uri.parse('${apiUrl}users'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw json.decode(response.body);
    }
  } catch (e) {
    throw {'message': 'Gagal Mengambil Data Anggota', 'errors': e.toString()};
  }
}
