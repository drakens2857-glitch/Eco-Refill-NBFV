import 'dart:html' as html; // 🔹 Para usar cámara en Flutter Web
import 'dart:typed_data';
import 'login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/permisos.dart';
import 'web_camera_view.dart';

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
  String? userRole;

  Uint8List? _capturedFace; // 🔹 foto del rostro

  @override
  void initState() {
    super.initState();
    // 🔹 Registra el elemento <video> HTML antes de que se construya
    // el HtmlElementView. Sin esto la cámara no aparece.
    registerCameraView();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final role = await _authService.getUserRole(uid);
      if (mounted) {
        setState(() {
          userRole = role;
        });
      }
    }
  }

  // Paleta de colores del diseño Neón / Cyberpunk
  static const Color neonPurple = Color(0xFFA855F7);
  static const Color darkBg = Color(0xFF0F0716);
  static const Color sidebarBg = Color(0xFF070216);
  static const Color sidebarBorder = Color(0xFF1E1035);
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

        // No navegamos a otra pantalla: esto evita "cerrar" la sesión
        // actual del administrador que está registrando al usuario.
        // Solo limpiamos el formulario para dejarlo listo para un
        // nuevo registro.
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _phoneController.clear();
        setState(() {
          _selectedCargo = null;
          _capturedFace = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: neonPurple,
            content: Text("Usuario $name registrado correctamente"),
          ),
        );
      } else {
        _showAlert("No se pudo registrar el usuario. Intenta nuevamente.");
      }
    } on FirebaseAuthException catch (e) {
      _showAlert("Error: ${e.message}");
    } catch (e) {
      _showAlert(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    if (isMobile) {
      return Scaffold(
        backgroundColor: darkBg,
        appBar: _buildMobileAppBar(),
        drawer: Drawer(
          backgroundColor: sidebarBg,
          child: SafeArea(child: _buildSidebarContent(context)),
        ),
        body: SafeArea(child: _buildMainPanel(context, isMobile: true)),
      );
    }

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
              color: sidebarBg,
              border: Border(
                right: BorderSide(color: sidebarBorder, width: 1),
              ),
            ),
            child: _buildSidebarContent(context),
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
            child: _buildMainPanel(context, isMobile: false),
          ),
        ],
      ),
    );
  }

  // Barra superior para vista móvil (con botón de menú para el Drawer)
  PreferredSizeWidget _buildMobileAppBar() {
    return AppBar(
      backgroundColor: sidebarBg,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      title: Row(
        mainAxisSize: MainAxisSize.min,
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
              size: 18,
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
    );
  }

  // Contenido de la barra lateral, reutilizado tanto en el layout de
  // escritorio (columna fija) como en el Drawer de la vista móvil.
  Widget _buildSidebarContent(BuildContext context) {
    return Column(
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
                      if (Permisos.puedeVer(userRole, 'inicio'))
                        _buildSidebarItem(
                          Icons.home_outlined,
                          "Inicio",
                          false,
                          () => Navigator.pushReplacementNamed(
                            context,
                            '/pantallabienvenida',
                          ),
                        ),

                      if (Permisos.puedeVer(userRole, 'perfil'))
                        _buildSidebarItem(
                          Icons.person_outline_rounded,
                          "Mi Perfil",
                          false,
                          () => Navigator.pushReplacementNamed(
                              context, '/perfil'),
                        ),

                      if (Permisos.puedeVer(userRole, 'dashboard'))
                        _buildSidebarItem(
                          Icons.dashboard_outlined,
                          "Crear Publicaciones",
                          false,
                          () => Navigator.pushReplacementNamed(
                            context,
                            '/dashboard',
                          ),
                        ),

                      if (Permisos.puedeVer(userRole, 'ingreso'))
                        _buildSidebarItem(
                          Icons.add_box_outlined,
                          "Ingreso Plásticos",
                          false,
                          () => Navigator.pushReplacementNamed(
                              context, '/ingreso'),
                        ),

                      if (Permisos.puedeVer(userRole, 'materiales'))
                        _buildSidebarItem(
                          Icons.recycling_rounded,
                          "Materiales",
                          false,
                          () => Navigator.pushReplacementNamed(
                            context,
                            '/materiales',
                          ),
                        ),

                      if (Permisos.puedeVer(userRole, 'procesos'))
                        _buildSidebarItem(
                          Icons.settings_outlined,
                          "Procesos",
                          false,
                          () => Navigator.pushReplacementNamed(
                            context,
                            '/procesos',
                          ),
                        ),

                      if (Permisos.puedeVer(userRole, 'usuarios'))
                        _buildSidebarItem(
                          Icons.groups_outlined,
                          "Usuarios",
                          false,
                          () => Navigator.pushReplacementNamed(
                            context,
                            '/usuarios',
                          ),
                        ),

                      if (Permisos.puedeVer(userRole, 'register'))
                        _buildSidebarItem(
                          Icons.person_add_alt_1_outlined,
                          "Registrar Usuario",
                          true,
                          null,
                        ),

                      if (Permisos.puedeVer(userRole, 'tareas'))
                        _buildSidebarItem(
                          Icons.task_alt_outlined,
                          "Tareas",
                          false,
                          () => Navigator.pushReplacementNamed(
                              context, '/tareas'),
                        ),

                      if (Permisos.puedeVer(userRole, 'reportes'))
                        _buildSidebarItem(
                          Icons.summarize_outlined,
                          "Reportes",
                          false,
                          () => Navigator.pushReplacementNamed(
                              context, '/reportes'),
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
            );
  }

  // Panel principal (formulario + cámara). En móvil ocupa todo el ancho
  // y usa paddings más pequeños; en escritorio conserva su diseño original.
  Widget _buildMainPanel(BuildContext context, {required bool isMobile}) {
    return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [darkBg, Color(0xFF230B36)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 12 : 24),
                  child: Container(
                    padding: EdgeInsets.all(isMobile ? 20 : 32),
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
                        Builder(
                          builder: (context) {
                            final buttonCapturar = Container(
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
                            );

                            final buttonRegistrar = Container(
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
                            );

                            if (isMobile) {
                              return Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: buttonCapturar,
                                  ),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: double.infinity,
                                    child: buttonRegistrar,
                                  ),
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: buttonCapturar),
                                const SizedBox(width: 20),
                                Expanded(child: buttonRegistrar),
                              ],
                            );
                          },
                        )
                      ],
                    ),
                  ),
                ),
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
    final Color background = isSelected ? neonPurple : Colors.transparent;
    final Color foreground = isSelected ? Colors.white : Colors.white70;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: foreground, size: 20),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: foreground,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
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