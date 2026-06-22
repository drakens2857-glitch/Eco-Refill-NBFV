import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedCargo;
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

  void _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final phone = _phoneController.text.trim();
    final cargo = _selectedCargo ?? "";

    if (name.isEmpty || email.isEmpty || password.isEmpty || phone.isEmpty || cargo.isEmpty) {
      _showAlert("Por favor completa todos los campos.");
      return;
    }

    try {
      final success = await _authService.register(name, email, password, phone, cargo);

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Usuario $name registrado correctamente")),
        );
      } else {
        _showAlert("Error al registrar usuario. Intenta nuevamente.");
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _showAlert("El correo ya está registrado.");
      } else if (e.code == 'invalid-email') {
        _showAlert("El formato del correo no es válido.");
      } else if (e.code == 'weak-password') {
        _showAlert("La contraseña es demasiado débil.");
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
      appBar: AppBar(
        title: const Text("Registrar Usuario"),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.cyanAccent),
          onPressed: () {
            // 🔹 Siempre vuelve a la pantalla de bienvenida
            Navigator.pushReplacementNamed(context, '/pantallabienvenida');
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF141E30), Color(0xFF243B55)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              elevation: 16,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: Colors.black.withOpacity(0.75),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Registrar Usuario",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.cyanAccent,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(_nameController, "Nombre", Icons.person),
                    const SizedBox(height: 16),
                    _buildTextField(_emailController, "Correo", Icons.email),
                    const SizedBox(height: 16),
                    _buildTextField(_passwordController, "Contraseña", Icons.lock, obscure: true),
                    const SizedBox(height: 16),
                    _buildTextField(_phoneController, "Teléfono", Icons.phone),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCargo,
                      items: const [
                        DropdownMenuItem(value: "jefe", child: Text("Jefe")),
                        DropdownMenuItem(value: "inventario", child: Text("Inventario")),
                        DropdownMenuItem(value: "ingreso", child: Text("Ingreso")),
                        DropdownMenuItem(value: "proceso", child: Text("Proceso")),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCargo = value;
                        });
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.work, color: Colors.cyanAccent),
                        labelText: "Cargo",
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
                      dropdownColor: Colors.black,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Registrar",
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
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.cyanAccent),
        labelText: label,
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
    );
  }
}
