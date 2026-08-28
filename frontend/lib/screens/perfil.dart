import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

import '../config/cloudinary_config.dart';
import 'login.dart';
import '../services/auth_service.dart';
import '../services/permisos.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final AuthService _authService = AuthService();
  String? userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final role = await _authService.getUserRole(uid);
      setState(() {
        userRole = role;
      });
    }
  }

  Future<void> _uploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload",
      );

      var request = http.MultipartRequest("POST", url)
        ..fields['upload_preset'] = CloudinaryConfig.uploadPreset;

      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: pickedFile.name,
          ),
        );
      } else {
        final file = File(pickedFile.path);
        request.files.add(await http.MultipartFile.fromPath('file', file.path));
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        final res = await http.Response.fromStream(response);

        final imageUrl = (res.body.contains("secure_url"))
            ? RegExp(
                r'"secure_url":"([^"]+)"',
              ).firstMatch(res.body)!.group(1)?.replaceAll(r'\/', '/')
            : null;

        if (imageUrl != null) {
          await FirebaseFirestore.instance
              .collection("users")
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .update({"photoUrl": imageUrl});

          setState(() {}); // refrescar pantalla
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      Future.microtask(() {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      });
      return const SizedBox.shrink();
    }

    final isMobile = MediaQuery.of(context).size.width < 700;

    final content = FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser.uid)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF6D28D9)),
          );
        }
        final data = snapshot.data!.data() as Map<String, dynamic>;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            isMobile ? 14 : 24,
            16,
            isMobile ? 14 : 24,
            10,
          ),
          child: Column(
            children: [
              // ================= BANNER DE PERFIL =================
              _buildProfileBanner(data, isMobile: isMobile),

              const SizedBox(height: 17),
              // ================= TARJETAS DE ESTADÍSTICAS =================
              LayoutBuilder(
                builder: (context, constraints) {
                  final tarjetas = [
                    _statCard(Icons.view_in_ar_rounded, "24", "Productos"),
                    _statCard(
                      Icons.recycling_rounded,
                      "128 kg",
                      "Plástico reciclado",
                    ),
                    _statCard(
                      Icons.blur_circular_rounded,
                      "18 kg",
                      "Filamento producido",
                    ),
                    _statCard(
                      Icons.eco_outlined,
                      "12",
                      "Tareas completadas",
                    ),
                  ];

                  if (constraints.maxWidth < 560) {
                    return GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1.3,
                      children: tarjetas,
                    );
                  }

                  return Row(
                    children: [
                      for (int i = 0; i < tarjetas.length; i++) ...[
                        if (i != 0) const SizedBox(width: 21),
                        Expanded(child: tarjetas[i]),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 17),

              // ================= SECCIÓN DE INFORMACIÓN =================
              _buildInfoSection(data),
            ],
          ),
        );
      },
    );

    if (isMobile) {
      return Scaffold(
        backgroundColor: const Color(0xFF03000E),
        appBar: _buildMobileAppBar(),
        drawer: Drawer(
          backgroundColor: const Color(0xFF070216),
          child: SafeArea(child: _buildSidebar(context, isDrawer: true)),
        ),
        body: SafeArea(child: content),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF03000E),
      body: Row(
        children: [
          // ================= BARRA LATERAL (NAVBAR) =================
          _buildSidebar(context),

          // ================= CONTENIDO PRINCIPAL =================
          Expanded(child: content),
        ],
      ),
    );
  }

  // Barra superior para la vista móvil, con el botón para abrir el Drawer.
  PreferredSizeWidget _buildMobileAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF070216),
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

  // --- WIDGET: BARRA LATERAL ---
  Widget _buildSidebar(BuildContext context, {bool isDrawer = false}) {
    return Container(
      width: isDrawer ? null : 220,
      decoration: BoxDecoration(
        color: const Color(0xFF070216),
        border: isDrawer
            ? null
            : const Border(
                right: BorderSide(color: Color(0xFF1E1035), width: 1),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          // Logo
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

          // ================= MENÚ =================
          if (Permisos.puedeVer(userRole, 'inicio'))
            _sidebarItem(
              Icons.home_outlined,
              "Inicio",
              false,
              () => Navigator.pushReplacementNamed(
                  context, '/pantallabienvenida'),
            ),

          if (Permisos.puedeVer(userRole, 'perfil'))
            _sidebarItem(
              Icons.person_outline_rounded,
              "Mi Perfil",
              true,
              null, // Ya estás en esta pantalla
            ),

          if (Permisos.puedeVer(userRole, 'dashboard'))
            _sidebarItem(
              Icons.dashboard_outlined,
              "Crear Publicaciones",
              false,
              () => Navigator.pushReplacementNamed(context, '/dashboard'),
            ),

          if (Permisos.puedeVer(userRole, 'ingreso'))
            _sidebarItem(
              Icons.add_box_outlined,
              "Ingreso Plásticos",
              false,
              () => Navigator.pushReplacementNamed(context, '/ingreso'),
            ),

          if (Permisos.puedeVer(userRole, 'materiales'))
            _sidebarItem(
              Icons.recycling_rounded,
              "Materiales",
              false,
              () => Navigator.pushReplacementNamed(context, '/materiales'),
            ),

          if (Permisos.puedeVer(userRole, 'procesos'))
            _sidebarItem(
              Icons.settings_outlined,
              "Procesos",
              false,
              () => Navigator.pushReplacementNamed(context, '/procesos'),
            ),

          if (Permisos.puedeVer(userRole, 'usuarios'))
            _sidebarItem(
              Icons.groups_outlined,
              "Usuarios",
              false,
              () => Navigator.pushReplacementNamed(context, '/usuarios'),
            ),

          if (Permisos.puedeVer(userRole, 'register'))
            _sidebarItem(
              Icons.person_add_alt_1_outlined,
              "Registrar Usuario",
              false,
              () => Navigator.pushReplacementNamed(context, '/register'),
            ),

          if (Permisos.puedeVer(userRole, 'tareas'))
            _sidebarItem(
              Icons.task_alt_outlined,
              "Tareas",
              false,
              () => Navigator.pushReplacementNamed(context, '/tareas'),
            ),

          if (Permisos.puedeVer(userRole, 'reportes'))
            _sidebarItem(
              Icons.summarize_outlined,
              "Reportes",
              false,
              () => Navigator.pushReplacementNamed(context, '/reportes'),
            ),

          const Spacer(),

          _sidebarItem(Icons.logout_rounded, "Cerrar Sesión", false, () async {
            await _authService.logout();

            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            }
          }),
        ],
      ),
    );
  }

  static const Color neonPurple = Color(0xFFA855F7);

  Widget _sidebarItem(
    IconData icon,
    String label,
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
                    label,
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

  // --- WIDGET: BANNER PRINCIPAL ---
  Widget _buildProfileBanner(Map<String, dynamic> data, {bool isMobile = false}) {
    final avatar = Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFA855F7), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFA855F7).withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: isMobile ? 50 : 74,
            backgroundImage:
                (data["photoUrl"] != null && data["photoUrl"].isNotEmpty)
                ? NetworkImage(data["photoUrl"])
                : const AssetImage("assets/images/default_avatar.png")
                      as ImageProvider,
          ),
        ),
        Positioned(
          bottom: 10,
          right: 10,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.greenAccent,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF0F0728),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );

    final nombreYBadge = Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Text(
          data["name"] ?? "Nicolás Bello",
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 22 : 30,
            fontWeight: FontWeight.w600,
            letterSpacing: .3,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF3B0764),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF6B21A8)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                color: Color(0xFFC084FC),
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                userRole ?? "Administrador",
                style: const TextStyle(
                  color: Color(0xFFE9D5FF),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final cuadroDescriptivo = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.eco_outlined, color: Colors.greenAccent, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Apasionado por la tecnología y la sostenibilidad, Transformando residuos en nuevas oportunidades.",
              style: TextStyle(
                color: Color.fromARGB(255, 255, 255, 255),
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );

    final botonEditar = ElevatedButton.icon(
      onPressed: _uploadImage,
      icon: const Icon(Icons.edit_outlined, size: 16),
      label: const Text("Editar Perfil"),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2E1065).withOpacity(0.6),
        foregroundColor: Colors.white,
        elevation: 0,
        side: const BorderSide(color: Color(0xFF6B21A8)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    final datosUsuario = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        nombreYBadge,
        const SizedBox(height: 20),
        Text(
          "${data["cargo"] ?? 'Tecnólogo en ADSO'}  |  Desarrollador",
          style: const TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            fontSize: 17,
            fontWeight: FontWeight.w500,
            height: 1.4,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 22),
        cuadroDescriptivo,
      ],
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 26,
        vertical: isMobile ? 20 : 28,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF3B1B74), width: 1.3),
        image: DecorationImage(
          image: const AssetImage("assets/images/FondoA.png"),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.45),
            BlendMode.darken,
          ),
        ),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                avatar,
                const SizedBox(height: 18),
                datosUsuario,
                const SizedBox(height: 18),
                SizedBox(width: double.infinity, child: botonEditar),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                avatar,
                const SizedBox(width: 26),
                Expanded(child: datosUsuario),
                const SizedBox(width: 16),
                botonEditar,
              ],
            ),
    );
  }

  // --- WIDGET: TARJETAS DE ESTADÍSTICAS ---
  Widget _statCard(IconData icon, String valor, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF09041A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E1035)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFFA855F7), size: 28),
              const SizedBox(width: 12),
              Text(
                valor,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // --- WIDGET: SECCIÓN DE INFORMACIÓN Y PESTAÑAS ---
  Widget _buildInfoSection(Map<String, dynamic> data) {
    return Container(
      constraints: const BoxConstraints(minHeight: 300),
      decoration: BoxDecoration(
        color: const Color(0xFF09041A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E1035)),
      ),
      child: Column(
        children: [
          // Pestañas (Tabs)
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF1E1035), width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4C1D95),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "Información",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenido de la pestaña
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 480;
              return Padding(
                padding: EdgeInsets.all(isNarrow ? 18 : 32),
                child: Column(
                  children: [
                    isNarrow
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _infoItem(
                                Icons.mail_outline_rounded,
                                "Correo:",
                                data["email"] ?? "nicolas@example.com",
                              ),
                              const SizedBox(height: 20),
                              _infoItem(
                                Icons.school_outlined,
                                "Programa:",
                                "ADSO - SENA",
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: _infoItem(
                                  Icons.mail_outline_rounded,
                                  "Correo:",
                                  data["email"] ?? "nicolas@example.com",
                                ),
                              ),
                              Expanded(
                                child: _infoItem(
                                  Icons.school_outlined,
                                  "Programa:",
                                  "ADSO - SENA",
                                ),
                              ),
                            ],
                          ),
                    const SizedBox(height: 30),
                    isNarrow
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _infoItem(
                                Icons.workspace_premium_outlined,
                                "Rol:",
                                userRole ?? "Administrador",
                              ),
                              const SizedBox(height: 20),
                              _infoItem(
                                Icons.location_on_outlined,
                                "Ubicación:",
                                "Mosquera, Colombia",
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: _infoItem(
                                  Icons.workspace_premium_outlined,
                                  "Rol:",
                                  userRole ?? "Administrador",
                                ),
                              ),
                              Expanded(
                                child: _infoItem(
                                  Icons.location_on_outlined,
                                  "Ubicación:",
                                  "Mosquera, Colombia",
                                ),
                              ),
                            ],
                          ),
                    const SizedBox(height: 40),

                    // Cita Inferior
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.eco_rounded,
                            color: Colors.greenAccent,
                            size: 20,
                          ),
                          SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              '"La tecnología también puede cuidar el planeta."',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontStyle: FontStyle.italic,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white54, size: 22),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  // Métodos auxiliares conservados intactos
  List<Widget> _buildRoleButtons(BuildContext context) {
    switch (userRole) {
      case "jefe":
        return [
          _bigButton(
            Icons.task,
            "Tareas",
            () => Navigator.pushNamed(context, '/tareas'),
          ),
          _bigButton(
            Icons.people,
            "Usuarios",
            () => Navigator.pushNamed(context, '/usuarios'),
          ),
          _bigButton(
            Icons.recycling,
            "Inventario",
            () => Navigator.pushNamed(context, '/materiales'),
          ),
          _bigButton(
            Icons.add_box,
            "Ingreso Plásticos",
            () => Navigator.pushNamed(context, '/ingreso'),
          ),
          _bigButton(
            Icons.settings,
            "Procesos",
            () => Navigator.pushNamed(context, '/procesos'),
          ),
        ];
      case "inventario":
        return [
          _bigButton(
            Icons.recycling,
            "Inventario",
            () => Navigator.pushNamed(context, '/materiales'),
          ),
          _bigButton(
            Icons.task,
            "Tareas",
            () => Navigator.pushNamed(context, '/tareas'),
          ),
        ];
      case "ingreso":
        return [
          _bigButton(
            Icons.task,
            "Tareas",
            () => Navigator.pushNamed(context, '/tareas'),
          ),
          _bigButton(
            Icons.add_box,
            "Ingreso Plásticos",
            () => Navigator.pushNamed(context, '/ingreso'),
          ),
        ];
      case "proceso":
        return [
          _bigButton(
            Icons.task,
            "Tareas",
            () => Navigator.pushNamed(context, '/tareas'),
          ),
          _bigButton(
            Icons.settings,
            "Procesos",
            () => Navigator.pushNamed(context, '/procesos'),
          ),
        ];
      default:
        return [];
    }
  }

  Widget _bigButton(IconData icon, String text, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.black),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.cyanAccent,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
