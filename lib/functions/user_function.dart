import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://presensi-fa.test/api/',
);

Future<Map<String, dynamic>> registerUser(
  Map<String, String> fields, {
  Map<String, String>? files,
}) async {
  var uri = Uri.parse('${apiUrl}user');
  var request = http.MultipartRequest('POST', uri);

  // Tambahkan fields
  fields.forEach((key, value) {
    request.fields[key] = value;
  });

  // Tambahkan files (opsional)
  if (files != null) {
    for (var entry in files.entries) {
      request.files.add(
        await http.MultipartFile.fromPath(entry.key, entry.value),
      );
    }
  }

  try {
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw json.decode(response.body);
    }
  } catch (e) {
    throw {'message': 'Gagal Membuat Akun', 'errors': e.toString()};
  }
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

      print(data);
      print(imageFile);
      var streamedResponse = await request.send();
      response = await http.Response.fromStream(streamedResponse);
      print('Multipart POST sent: $uri');
    } else {
      response = await http.patch(
        uri,
        headers: {...headers, 'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      print('PATCH sent: $uri');
    }

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    final Map<String, dynamic> responseJson = json.decode(response.body);

    if (response.statusCode == 200) {
      final userData = responseJson['user'] ?? responseJson;
      print(userData);
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
