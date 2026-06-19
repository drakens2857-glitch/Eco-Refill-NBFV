import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  final String baseUrl = "http://127.0.0.1:8000/api";

  Future<void> crearUsuario(String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    if (response.statusCode == 200) {
      print("Usuario creado: ${response.body}");
    } else {
      print("Error: ${response.body}");
    }
  }
}
