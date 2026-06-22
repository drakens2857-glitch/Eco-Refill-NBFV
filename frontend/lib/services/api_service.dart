import 'package:http/http.dart' as http;
import 'dart:convert';

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

  /// 🔹 Crear nueva publicación
  Future<void> createPost(String author, String description, String imageUrl) async {
    final response = await http.post(
      Uri.parse("$baseUrl/posts/"), // ✅ barra final
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "author": author,
        "description": description,
        "imageUrl": imageUrl,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("Publicación creada: ${response.body}");
    } else {
      print("Error al crear publicación: ${response.body}");
    }
  }
}
