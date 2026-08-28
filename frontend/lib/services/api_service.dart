import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'api_config.dart';

class ApiService {
  final String baseUrl = ApiConfig.apiBaseUrl;

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

  /// 🔹 Editar publicación existente (título, descripción, autor, categoría)
  Future<void> updatePost(
    String postId, {
    String? title,
    String? description,
    String? author,
    String? category,
  }) async {
    final Map<String, dynamic> body = {};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (author != null) body['author'] = author;
    if (category != null) body['category'] = category;

    final response = await http.put(
      Uri.parse("$baseUrl/posts/$postId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      String detail = response.body;
      try {
        detail = (jsonDecode(response.body)["detail"] ?? detail).toString();
      } catch (_) {}
      throw Exception(detail);
    }
  }

  /// 🔹 Eliminar publicación
  Future<void> deletePost(String postId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/posts/$postId"),
    );

    if (response.statusCode != 200) {
      String detail = response.body;
      try {
        detail = (jsonDecode(response.body)["detail"] ?? detail).toString();
      } catch (_) {}
      throw Exception(detail);
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
