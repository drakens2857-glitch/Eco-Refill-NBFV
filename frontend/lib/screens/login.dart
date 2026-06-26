import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pantallabienvenida.dart'; // 🔹 Importa tu nueva pantalla

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showAlert("Por favor ingresa correo y contraseña.");
      return;
    }

    try {
      final user = await _authService.login(email, password);

      if (user != null) {
        // 🔹 Usuario autenticado → PantallaBienvenida
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const PantallaBienvenida()),
          (Route<dynamic> route) => false,
        );
      } else {
        _showAlert("Error al iniciar sesión. Verifica tus datos.");
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _showAlert("No existe un usuario con ese correo.");
      } else if (e.code == 'wrong-password') {
        _showAlert("La contraseña es incorrecta.");
      } else if (e.code == 'invalid-email') {
        _showAlert("El formato del correo no es válido.");
      } else {
        _showAlert("Error: ${e.message}");
      }
    } catch (e) {
      _showAlert("Error inesperado: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Card(
            elevation: 12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: Colors.black.withOpacity(0.7),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Eco-Refill",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🔹 Campo de correo
                  TextField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Correo",
                      labelStyle: const TextStyle(color: Colors.cyanAccent),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.cyanAccent),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 🔹 Campo de contraseña
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Contraseña",
                      labelStyle: const TextStyle(color: Colors.cyanAccent),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.cyanAccent),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🔹 Botón iniciar sesión
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Iniciar Sesión",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
