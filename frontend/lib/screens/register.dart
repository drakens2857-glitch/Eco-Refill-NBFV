import 'dart:html' as html; // 🔹 Para usar cámara en Flutter Web
import 'dart:typed_data';
import 'login.dart';
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

  Uint8List? _capturedFace; // 🔹 foto del rostro

  // Paleta de colores del diseño Neón / Cyberpunk
  static const Color neonPurple = Color(0xFFA855F7);
  static const Color darkBg = Color(0xFF0F0716);
  static const Color sidebarBg = Color(0xFF13091F);
  static const Color cardBg = Color(0xFF170C28);
  static const Color inputBg = Color(0xFF22113A);

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBg,
        title: const Text("Atención", style: TextStyle(color: neonPurple)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: neonPurple)),
          ),
        ],
      ),
    );
  }

  Future<void> _captureFace() async {
    final videoElement =
        html.document.querySelector('video') as html.VideoElement?;

    if (videoElement == null || videoElement.videoWidth == 0) {
      _showAlert("La cámara aún no está lista.");
      return;
    }

    final canvas = html.CanvasElement(
      width: videoElement.videoWidth,
      height: videoElement.videoHeight,
    );
    final ctx = canvas.context2D;
    ctx.drawImage(videoElement, 0, 0);

    final blob = await canvas.toBlob('image/jpeg');

    final reader = html.FileReader();
    reader.readAsArrayBuffer(blob);
    await reader.onLoad.first;

    if (!mounted) return;

    setState(() {
      _capturedFace = reader.result as Uint8List;
    });
  }

  void _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final phone = _phoneController.text.trim();
    final cargo = _selectedCargo ?? "";

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        phone.isEmpty ||
        cargo.isEmpty ||
        _capturedFace == null) {
      _showAlert("Por favor completa todos los campos y captura tu rostro.");
      return;
    }

    try {
      final success = await _authService.registerWithFace(
        name,
        email,
        password,
        phone,
        cargo,
        _capturedFace!,
      );

      if (success) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: neonPurple,
            content: Text("Usuario $name registrado correctamente"),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showAlert("Error: ${e.message}");
    } catch (e) {
      _showAlert("Error inesperado: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      body: Row(
        children: [
          // -----------------------------------------------------------------
          // 1. BARRA LATERAL IZQUIERDA (Sidebar)
          // -----------------------------------------------------------------
          Container(
            width: 220,
            decoration: const BoxDecoration(
              color: Color(0xFF070216),
              border: Border(
                right: BorderSide(color: Color(0xFF1E1035), width: 1),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 30),
                // Logo o Título de App
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF8B5CF6)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.view_in_ar_rounded,
                          color: Color(0xFFC084FC),
                          size: 20,
                        ),
                      ),

                      const SizedBox(width: 10),

                      const Text(
                        "ECO-REFILL",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Lista de opciones del Menú Lateral
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _buildSidebarItem(
                        Icons.home_outlined,
                        "Inicio",
                        false,
                        () => Navigator.pushReplacementNamed(
                          context,
                          '/pantallabienvenida',
                        ),
                      ),

                     _buildSidebarItem(
                        Icons.person_outline_rounded,
                        "Mi Perfil",
                        false,
                        () =>
                            Navigator.pushReplacementNamed(context, '/perfil'),
                      ),

                     _buildSidebarItem(
                        Icons.dashboard_outlined,
                        "Dashboard",
                        false,
                        () => Navigator.pushReplacementNamed(
                          context,
                          '/dashboard',
                        ),
                      ),

                      _buildSidebarItem(
                        Icons.add_box_outlined,
                        "Ingreso Plásticos",
                        false,
                        () =>
                            Navigator.pushReplacementNamed(context, '/ingreso'),
                      ),

                      _buildSidebarItem(
                        Icons.recycling_outlined,
                        "Materiales",
                        false,
                        () => Navigator.pushReplacementNamed(
                          context,
                          '/materiales',
                        ),
                      ),

                      _buildSidebarItem(
                        Icons.settings_outlined,
                        "Procesos",
                        false,
                        () => Navigator.pushReplacementNamed(
                          context,
                          '/procesos',
                        ),
                      ),

                      _buildSidebarItem(
                        Icons.groups_outlined,
                        "Usuarios",
                        false,
                        () => Navigator.pushReplacementNamed(
                          context,
                          '/usuarios',
                        ),
                      ),

                      _buildSidebarItem(
                        Icons.person_add_alt_1_outlined,
                        "Registrar Usuario",
                        true,
                        null,
                      ),

                      _buildSidebarItem(
                        Icons.task_alt_outlined,
                        "Tareas",
                        false,
                        () =>
                            Navigator.pushReplacementNamed(context, '/tareas'),
                      ),
                    ],
                  ),
                ),

                // Botón Cerrar Sesión en la parte inferior
                _buildSidebarItem(
                  Icons.logout_rounded,
                  "Cerrar Sesión",
                  false,
                  () async {
                    await _authService.logout();

                    if (!mounted) return;

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),

          Container(
            width: 220,
            margin: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 25,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF05060A),
                  Color.fromARGB(255, 49, 3, 91),
                  Color.fromARGB(255, 126, 15, 206),
                ],
              ),
              border: Border.all(
                color: Color.fromARGB(255, 137, 5, 231),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(255, 128, 60, 205).withOpacity(.15),
                  blurRadius: 25,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),

          // -----------------------------------------------------------------
          // 2. PANEL PRINCIPAL DERECHO (Formulario y Cámara)
          // -----------------------------------------------------------------
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [darkBg, Color(0xFF230B36)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: cardBg.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: neonPurple.withOpacity(0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: neonPurple.withOpacity(0.2),
                          blurRadius: 25,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Título neón con resplandor
                        const Text(
                          "Registrar Usuario",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(color: neonPurple, blurRadius: 12),
                              Shadow(color: neonPurple, blurRadius: 24),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Formulario Grid de 2 columnas (Nombre/Correo, Contraseña/Cargo, etc.)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            bool isWide = constraints.maxWidth > 500;
                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        _nameController,
                                        "Nombre",
                                        Icons.person_outline,
                                      ),
                                    ),
                                    if (isWide) const SizedBox(width: 16),
                                    if (isWide)
                                      Expanded(
                                        child: _buildTextField(
                                          _emailController,
                                          "Correo",
                                          Icons.email_outlined,
                                        ),
                                      ),
                                  ],
                                ),
                                if (!isWide) const SizedBox(height: 16),
                                if (!isWide)
                                  _buildTextField(
                                    _emailController,
                                    "Correo",
                                    Icons.email_outlined,
                                  ),
                                const SizedBox(height: 18),

                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        _passwordController,
                                        "Contraseña",
                                        Icons.lock_outline,
                                        obscure: true,
                                      ),
                                    ),
                                    if (isWide) const SizedBox(width: 16),
                                    if (isWide)
                                      Expanded(child: _buildDropdownCargo()),
                                  ],
                                ),
                                if (!isWide) const SizedBox(height: 16),
                                if (!isWide) _buildDropdownCargo(),
                                const SizedBox(height: 18),

                                _buildTextField(
                                  _phoneController,
                                  "Teléfono",
                                  Icons.phone_outlined,
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 18),

                        // Vista de la cámara
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 180,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              border: Border.all(
                                color: neonPurple.withOpacity(0.5),
                              ),
                            ),
                            child: const HtmlElementView(
                              viewType: 'camera-view',
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Previsualización si ya capturó foto
                        if (_capturedFace != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(_capturedFace!, height: 100),
                          ),
                          const SizedBox(height: 18),
                        ],

                        // Botón de acción principal
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: neonPurple.withOpacity(0.40),
                                      blurRadius: 15,
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: _captureFace,
                                  icon: const Icon(Icons.camera_alt_outlined),
                                  label: const Text("Capturar Rostro"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: neonPurple,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 20),

                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: neonPurple.withOpacity(0.40),
                                      blurRadius: 15,
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: _register,
                                  icon: const Icon(Icons.person_add_alt_1),
                                  label: const Text("Registrar Usuario"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: neonPurple,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES DE ESTILO ---

  // Elementos de la lista del menú lateral
  Widget _buildSidebarItem(
    IconData icon,
    String title,
    bool isSelected,
    VoidCallback? onTap,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF4C1D95) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        onTap: onTap,
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white54,
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // Estilo de los campos de entrada de texto
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        filled: true,
        fillColor: inputBg,
        prefixIcon: Icon(icon, color: neonPurple, size: 20),
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.6),
          fontSize: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: neonPurple.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: neonPurple, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

@override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  // Estilo para el Dropdown de Selección de Cargo
  Widget _buildDropdownCargo() {
    return DropdownButtonFormField<String>(
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
      dropdownColor: cardBg,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      icon: const Icon(Icons.arrow_drop_down, color: neonPurple),
      decoration: InputDecoration(
        filled: true,
        fillColor: inputBg,
        prefixIcon: const Icon(Icons.work_outline, color: neonPurple, size: 20),
        labelText: "Cargo",
        labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.6),
          fontSize: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: neonPurple.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: neonPurple, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
