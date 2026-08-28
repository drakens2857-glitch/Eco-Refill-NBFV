import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';
import '../services/permisos.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const Color darkBg = Color(0xFF0F0716);
  static const Color sidebarBg = Color(0xFF070216);
  static const Color sidebarBorder = Color(0xFF1E1035);
  static const Color cardBg = Color(0xFF170C28);
  static const Color neonPurple = Color(0xFFA855F7);
  static const Color statTeal = Color(0xFF22D3EE);
  // 🔹 Backend desplegado en Google Cloud Run (antes apuntaba a
  // http://localhost:8000, lo que solo funcionaba en tu propia máquina).
  static const String baseUrl =
      "https://eco-refill-backend-992396324099.us-central1.run.app";

  final AuthService _authService = AuthService();

  List posts = [];
  bool loading = true;
  String? _loadError;

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  Uint8List? _selectedImage;

  String? userRole;

  bool _sortDescending = true;
  bool _onlyWithImages = false;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _loadUserRole();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() {
      loading = true;
      _loadError = null;
    });

    try {
      final response = await http
          .get(Uri.parse("$baseUrl/api/posts"))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          posts = decoded is List ? decoded : [];
          loading = false;
        });
      } else {
        // 🔹 Se registra siempre (no solo en debug) para poder ver el
        // motivo real abriendo la consola del navegador (F12) en la app
        // ya desplegada, sin depender de correr en modo debug.
        debugPrint(
          "⚠️ _loadPosts: status=${response.statusCode} body=${response.body}",
        );
        setState(() {
          loading = false;
          _loadError =
              "El servidor respondió con un error (${response.statusCode}).";
        });
      }
    } catch (e) {
      // 🔹 Antes cualquier fallo de red (timeout, CORS, backend dormido en
      // Cloud Run, sin conexión, etc.) quedaba sin capturar: "loading" se
      // quedaba en true para siempre y la pantalla giraba en el spinner
      // sin mostrar nunca las publicaciones, ni viejas ni nuevas.
      // 🔹 Se imprime siempre el detalle real del error en la consola del
      // navegador para poder diagnosticar (CORS, timeout, DNS, etc.) aunque
      // la app esté corriendo en modo producción/release.
      debugPrint("❌ _loadPosts error: $e");
      setState(() {
        loading = false;
        _loadError =
            "No se pudieron cargar las publicaciones. Revisa tu conexión e intenta de nuevo.";
      });
    }
  }

  Future<void> _loadUserRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final role = await _authService.getUserRole(uid);
      if (kDebugMode) {
        // 🔹 Ayuda de depuración: confirma en la consola qué rol llegó y
        // con qué email quedó la sesión, para diagnosticar por qué no
        // aparecen "Editar"/"Eliminar" en una publicación.
        debugPrint(
          "🔎 userRole=\"$role\" currentEmail=\"${FirebaseAuth.instance.currentUser?.email}\"",
        );
      }
      setState(() {
        userRole = role;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _selectedImage = bytes;
      });
    }
  }

  Future<void> _createPost() async {
    if (_selectedImage == null ||
        _titleController.text.isEmpty ||
        _descController.text.isEmpty) {
      return;
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse("$baseUrl/api/posts/create_post"),
    );
    request.fields['title'] = _titleController.text;
    request.fields['description'] = _descController.text;
    request.fields['author'] =
        FirebaseAuth.instance.currentUser?.email ?? "Desconocido";
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        _selectedImage!,
        filename: "post.png",
      ),
    );

    try {
      final response = await request.send().timeout(
            const Duration(seconds: 30),
          );
      if (response.statusCode == 200) {
        _titleController.clear();
        _descController.clear();
        setState(() {
          _selectedImage = null;
        });
        _loadPosts();
      } else {
        if (kDebugMode) {
          debugPrint("⚠️ _createPost: status=${response.statusCode}");
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No se pudo crear la publicación"),
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("❌ _createPost error: $e");
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al crear la publicación: $e")),
        );
      }
    }
  }

  Future<void> _updatePost(
    dynamic postId, {
    required String title,
    required String description,
  }) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/api/posts/$postId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"title": title, "description": description}),
      );

      if (response.statusCode == 200) {
        _loadPosts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Publicación actualizada")),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No se pudo actualizar la publicación"),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al actualizar: $e")),
        );
      }
    }
  }

  Future<void> _deletePost(dynamic postId) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/api/posts/$postId"),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        _loadPosts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Publicación eliminada")),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No se pudo eliminar la publicación"),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al eliminar: $e")),
        );
      }
    }
  }

  bool _canManagePost(dynamic post) {
    // 🔹 Comparación tolerante a mayúsculas/espacios: un correo guardado
    // como "Nombre@Gmail.com " vs "nombre@gmail.com" antes hacía fallar
    // la comparación exacta y ocultaba "Editar"/"Eliminar" sin motivo.
    final author = post["author"]?.toString().trim().toLowerCase();
    final currentEmail =
        FirebaseAuth.instance.currentUser?.email?.trim().toLowerCase();
    final role = userRole?.trim().toLowerCase();
    final isOwner = author != null &&
        author.isNotEmpty &&
        currentEmail != null &&
        author == currentEmail;
    return role == "jefe" || isOwner;
  }

  Future<void> _showEditPostDialog(dynamic post) async {
    final editTitleController = TextEditingController(
      text: (post["title"] ?? "").toString(),
    );
    final editDescController = TextEditingController(
      text: (post["description"] ?? "").toString(),
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Editar publicación",
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: editTitleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Título",
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: darkBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: neonPurple.withOpacity(0.3)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: editDescController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Descripción",
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: darkBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: neonPurple.withOpacity(0.3)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                "Cancelar",
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: neonPurple),
              child: const Text(
                "Guardar",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final newTitle = editTitleController.text.trim();
      final newDesc = editDescController.text.trim();
      if (newTitle.isEmpty || newDesc.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Título y descripción no pueden estar vacíos"),
            ),
          );
        }
        return;
      }
      await _updatePost(
        post["id"],
        title: newTitle,
        description: newDesc,
      );
    }

    editTitleController.dispose();
    editDescController.dispose();
  }

  Future<void> _confirmDeletePost(dynamic post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Eliminar publicación",
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            "¿Seguro que quieres eliminar esta publicación? Esta acción no se puede deshacer.",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                "Cancelar",
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text(
                "Eliminar",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deletePost(post["id"]);
    }
  }

  List _visiblePosts() {
    var list = List.from(posts);
    if (_onlyWithImages) {
      list = list.where((p) {
        final img = p["imageUrl"];
        return img != null && img.toString().isNotEmpty;
      }).toList();
    }
    if (_sortDescending) {
      list = list.reversed.toList();
    }
    return list;
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    String str = raw.toString();
    if (str.isEmpty) return null;

    // Si el backend envía la fecha sin indicar zona horaria (ej: "2025-08-14T10:23:45"),
    // Dart la interpreta como si ya fuera hora LOCAL, lo cual está mal si en realidad
    // el backend guarda la fecha en UTC. Por eso, si no trae 'Z' ni un offset (+hh:mm/-hh:mm),
    // asumimos que es UTC y lo marcamos explícitamente antes de parsear.
    final hasTimezone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(str);
    if (!hasTimezone) {
      str = "${str}Z";
    }

    final parsed = DateTime.tryParse(str);
    // Convertimos siempre a la hora local del dispositivo para mostrarla al usuario.
    return parsed?.toLocal();
  }

  String _formatDate(DateTime date) {
    const months = [
      "ene",
      "feb",
      "mar",
      "abr",
      "may",
      "jun",
      "jul",
      "ago",
      "sep",
      "oct",
      "nov",
      "dic",
    ];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  String _formatTime(DateTime date) {
    final hour24 = date.hour;
    final period = hour24 >= 12 ? "PM" : "AM";
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    return "$hour12:$minute $period";
  }

  int get _totalPosts => posts.length;

  int get _uniqueAuthors =>
      posts.map((p) => p["author"] ?? "Desconocido").toSet().length;

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: darkBg,
      drawer: isMobile
          ? Drawer(
              backgroundColor: sidebarBg,
              child: SafeArea(child: _buildSidebar(context)),
            )
          : null,
      appBar: isMobile ? _buildMobileAppBar(context) : null,
      body: SafeArea(
        top: !isMobile,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isMobile) _buildSidebar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 900;
                        final showCreateCard = userRole == "jefe";
                        if (!showCreateCard) {
                          return _buildStatsGrid();
                        }
                        return isWide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: _buildCreatePostCard(),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(flex: 2, child: _buildStatsGrid()),
                                ],
                              )
                            : Column(
                                children: [
                                  _buildCreatePostCard(),
                                  const SizedBox(height: 24),
                                  _buildStatsGrid(),
                                ],
                              );
                      },
                    ),
                    const SizedBox(height: 40),
                    _buildPostsSection(),
                    const SizedBox(height: 32),
                    _buildBottomBanner(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: sidebarBg,
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
          const SizedBox(width: 8),
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

  // En celular, este mismo contenido se muestra dentro de un Drawer
  // (accesible con el ícono de menú de la AppBar). En pantallas grandes
  // se muestra siempre visible como barra lateral fija.
  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: sidebarBg,
        border: Border(right: BorderSide(color: sidebarBorder, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
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
              false,
              () => Navigator.pushReplacementNamed(context, '/perfil'),
            ),
          if (Permisos.puedeVer(userRole, 'dashboard'))
            _sidebarItem(
                Icons.dashboard_outlined, "Crear Publicaciones", true, null),
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
          _sidebarItem(
            Icons.logout_rounded,
            "Cerrar Sesión",
            false,
            _handleLogout,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _sidebarItem(
    IconData icon,
    String label,
    bool active,
    VoidCallback? onTap,
  ) {
    final Color background = active ? neonPurple : Colors.transparent;
    final Color foreground = active ? Colors.white : Colors.white70;

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
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
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

  Widget _buildHeader() {
    return const Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Publicaciones",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "Comparte novedades con tu equipo",
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreatePostCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: neonPurple.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.edit_note_outlined, color: neonPurple, size: 22),
              SizedBox(width: 10),
              Text(
                "Crear publicación",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.only(left: 32),
            child: Text(
              "Comparte información importante con tu equipo",
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Título",
              labelStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: darkBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: neonPurple.withOpacity(0.3)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: neonPurple),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _descController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Descripción",
              labelStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: darkBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: neonPurple.withOpacity(0.3)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: neonPurple),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // 🔹 Antes este bloque era un solo Row con Icono + texto + Spacer()
          // + "JPG, PNG hasta 10MB" al final. En pantallas de celular angostas
          // esos elementos no cabían en una sola fila y Flutter los desbordaba
          // (las franjas amarillas/negras de "RenderFlex overflowed"). Ahora
          // el título va en su propia fila y el texto de ayuda va debajo,
          // así nunca compiten por el mismo espacio horizontal.
          InkWell(
            onTap: _pickImage,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: neonPurple.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _selectedImage != null
                            ? Icons.check_circle
                            : Icons.image_outlined,
                        color: _selectedImage != null ? statTeal : neonPurple,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedImage != null
                              ? "Imagen seleccionada"
                              : "Seleccionar imagen",
                          style: const TextStyle(color: Colors.white70),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Padding(
                    padding: EdgeInsets.only(left: 36),
                    child: Text(
                      "JPG, PNG hasta 10MB",
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _createPost,
              icon: const Icon(Icons.send_outlined, color: Colors.white),
              label: const Text("Publicar"),
              style: ElevatedButton.styleFrom(
                backgroundColor: neonPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: neonPurple.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.insert_chart_outlined, color: neonPurple, size: 22),
              SizedBox(width: 10),
              Text(
                "Resumen general",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.only(left: 32),
            child: Text(
              "Información rápida",
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.description_outlined,
                  iconColor: neonPurple,
                  value: "$_totalPosts",
                  label: "Publicaciones",
                  sublabel: "Totales",
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.groups_outlined,
                  iconColor: statTeal,
                  value: "$_uniqueAuthors",
                  label: "Autores",
                  sublabel: "Únicos",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required String sublabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          Text(
            sublabel,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsSection() {
    final visible = _visiblePosts();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.list_alt_outlined, color: neonPurple, size: 22),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Últimas publicaciones",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Mantente al día con las novedades",
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
            PopupMenuButton<bool>(
              color: cardBg,
              initialValue: _sortDescending,
              onSelected: (value) => setState(() => _sortDescending = value),
              itemBuilder: (context) => const [
                PopupMenuItem(value: true, child: Text("Más recientes")),
                PopupMenuItem(value: false, child: Text("Más antiguas")),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: neonPurple.withOpacity(0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _sortDescending ? "Más recientes" : "Más antiguas",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: () => setState(() => _onlyWithImages = !_onlyWithImages),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _onlyWithImages ? neonPurple.withOpacity(0.2) : cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: neonPurple.withOpacity(0.25)),
                ),
                child: Icon(
                  Icons.filter_list,
                  color: _onlyWithImages ? neonPurple : Colors.white70,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(child: CircularProgressIndicator(color: neonPurple)),
          )
        else if (_loadError != null)
          _buildErrorState()
        else if (visible.isEmpty)
          _buildEmptyState()
        else
          Column(
            children: visible
                .map<Widget>((post) => _buildPostCard(post))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: neonPurple.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            color: neonPurple.withOpacity(0.6),
            size: 42,
          ),
          const SizedBox(height: 16),
          const Text(
            "Aún no hay publicaciones",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Cuando crees una publicación, aparecerá aquí",
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: Colors.redAccent,
            size: 42,
          ),
          const SizedBox(height: 16),
          Text(
            _loadError ?? "No se pudieron cargar las publicaciones.",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadPosts,
            style: ElevatedButton.styleFrom(backgroundColor: neonPurple),
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text(
              "Reintentar",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(dynamic post) {
    final imageUrl = post["imageUrl"];
    final hasImage = imageUrl != null && imageUrl.toString().isNotEmpty;
    // 🔹 Las imágenes nuevas vienen como URL completa de Firebase Storage
    // (https://...). Las publicaciones antiguas (creadas antes de migrar a
    // Storage) podían traer una ruta relativa tipo "/uploads/archivo.png";
    // esas rutas ya no existen en el servidor, pero se dejan sin romper la
    // app si aparecieran.
    final resolvedImageUrl = hasImage
        ? (imageUrl.toString().startsWith("http")
            ? imageUrl.toString()
            : "$baseUrl$imageUrl")
        : "";
    final title = post["title"] ?? "";
    final description = post["description"] ?? "";
    final author = post["author"] ?? "Desconocido";
    final initial = author.toString().isNotEmpty
        ? author.toString()[0].toUpperCase()
        : "?";
    final postDate = _parseDate(post["created_at"]);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: neonPurple.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: hasImage
                ? Image.network(
                    resolvedImageUrl,
                    width: 110,
                    height: 110,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 110,
                      height: 110,
                      color: darkBg,
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: neonPurple.withOpacity(0.4),
                      ),
                    ),
                  )
                : Container(
                    width: 110,
                    height: 110,
                    color: darkBg,
                    child: Icon(
                      Icons.image_outlined,
                      color: neonPurple.withOpacity(0.4),
                    ),
                  ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.toString().isNotEmpty)
                  Text(
                    title.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (title.toString().isNotEmpty) const SizedBox(height: 6),
                Text(
                  description.toString(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: neonPurple.withOpacity(0.25),
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: neonPurple,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      author.toString(),
                      style: const TextStyle(
                        color: neonPurple,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PopupMenuButton<String>(
                color: cardBg,
                icon: const Icon(Icons.more_vert, color: Colors.white54),
                onSelected: (value) {
                  if (value == "copy") {
                    Clipboard.setData(
                      ClipboardData(text: "$title\n$description"),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Publicación copiada")),
                    );
                  } else if (value == "edit") {
                    _showEditPostDialog(post);
                  } else if (value == "delete") {
                    _confirmDeletePost(post);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: "copy",
                    child: Text("Copiar publicación"),
                  ),
                  if (_canManagePost(post)) ...[
                    const PopupMenuItem(
                      value: "edit",
                      child: Text("Editar publicación"),
                    ),
                    const PopupMenuItem(
                      value: "delete",
                      child: Text(
                        "Eliminar publicación",
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ],
              ),
              if (postDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      color: Colors.white54,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(postDate),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_outlined,
                      color: Colors.white54,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatTime(postDate),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [neonPurple.withOpacity(0.25), neonPurple.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_outlined, color: Colors.white, size: 26),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Comunicación clara, equipo más fuerte",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Comparte, informa y construye un mejor entorno de trabajo.",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
