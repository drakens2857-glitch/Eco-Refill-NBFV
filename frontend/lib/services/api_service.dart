import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

class ApiService {
  final String baseUrl = "http://127.0.0.1:8000/api";

  /// 🔹 Registrar usuario
  Future<void> crearUsuario(String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("Usuario creado: ${response.body}");
    } else {
      print("Error: ${response.body}");
    }
  }

  /// 🔹 Obtener publicaciones (feed)
  Future<List<dynamic>> getPosts({int skip = 0, int limit = 10}) async {
    final response = await http.get(
      Uri.parse("$baseUrl/posts?skip=$skip&limit=$limit"),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al obtener publicaciones: ${response.body}");
    }
  }

  /// 🔹 Crear nueva publicación con imagen (via backend)
  Future<void> createPost(String author, String description, Uint8List imageBytes) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse("$baseUrl/posts/create_post"),
    );
    request.fields['author'] = author;
    request.fields['description'] = description;
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      imageBytes,
      filename: "post.png",
    ));

    var response = await request.send();
    if (response.statusCode == 200) {
      print("Publicación creada con éxito");
    } else {
      print("Error al crear publicación: ${response.statusCode}");
    }
  }
}
