import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';

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
  static const String baseUrl = "http://localhost:8000";

  final AuthService _authService = AuthService();

  List posts = [];
  bool loading = true;

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
    final response = await http.get(
      Uri.parse("http://localhost:8000/api/posts/"),
    );
    if (response.statusCode == 200) {
      setState(() {
        posts = jsonDecode(response.body);
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });
    }
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
      Uri.parse("http://localhost:8000/api/posts/create_post"),
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

    final response = await request.send();
    if (response.statusCode == 200) {
      _titleController.clear();
      _descController.clear();
      setState(() {
        _selectedImage = null;
      });
      _loadPosts();
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
    return DateTime.tryParse(raw.toString());
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
    return Scaffold(
      backgroundColor: darkBg,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSidebar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
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
          _sidebarItem(
            Icons.home_outlined,
            "Inicio",
            false,
            () =>
                Navigator.pushReplacementNamed(context, '/pantallabienvenida'),
          ),
          _sidebarItem(
            Icons.person_outline_rounded,
            "Mi Perfil",
            false,
            () => Navigator.pushReplacementNamed(context, '/perfil'),
          ),
          _sidebarItem(Icons.dashboard_outlined, "Dashboard", true, null),
          _sidebarItem(
            Icons.add_box_outlined,
            "Ingreso Plásticos",
            false,
            () => Navigator.pushReplacementNamed(context, '/ingreso'),
          ),
          _sidebarItem(
            Icons.recycling_rounded,
            "Materiales",
            false,
            () => Navigator.pushReplacementNamed(context, '/materiales'),
          ),
          _sidebarItem(
            Icons.settings_outlined,
            "Procesos",
            false,
            () => Navigator.pushReplacementNamed(context, '/procesos'),
          ),
          _sidebarItem(
            Icons.groups_outlined,
            "Usuarios",
            false,
            () => Navigator.pushReplacementNamed(context, '/usuarios'),
          ),
          _sidebarItem(
            Icons.person_add_alt_1_outlined,
            "Registrar Usuario",
            false,
            () => Navigator.pushReplacementNamed(context, '/register'),
          ),
          _sidebarItem(
            Icons.task_alt_outlined,
            "Tareas",
            false,
            () => Navigator.pushReplacementNamed(context, '/tareas'),
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
    final Color background = active
        ? neonPurple.withOpacity(0.15)
        : Colors.transparent;
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
              child: Row(
                children: [
                  Icon(
                    _selectedImage != null
                        ? Icons.check_circle
                        : Icons.image_outlined,
                    color: _selectedImage != null ? statTeal : neonPurple,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _selectedImage != null
                        ? "Imagen seleccionada"
                        : "Seleccionar imagen",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const Spacer(),
                  const Text(
                    "JPG, PNG hasta 10MB",
                    style: TextStyle(color: Colors.white38, fontSize: 12),
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

  Widget _buildPostCard(dynamic post) {
    final imageUrl = post["imageUrl"];
    final hasImage = imageUrl != null && imageUrl.toString().isNotEmpty;
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
                    "$baseUrl$imageUrl",
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
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: "copy",
                    child: Text("Copiar publicación"),
                  ),
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
