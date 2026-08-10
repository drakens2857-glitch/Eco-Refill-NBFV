import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class TareasScreen extends StatefulWidget {
  const TareasScreen({super.key});

  @override
  State<TareasScreen> createState() => _TareasScreenState();
}

class _TareasScreenState extends State<TareasScreen> {
  static const Color darkBg = Color(0xFF0F0716);
  static const Color sidebarBg = Color(0xFF070216);
  static const Color sidebarBorder = Color(0xFF1E1035);
  static const Color cardBg = Color(0xFF170C28);
  static const Color neonPurple = Color(0xFFA855F7);
  static const Color statBlue = Color(0xFF3B82F6);
  static const Color statGreen = Color(0xFF22C55E);
  static const Color statOrange = Color(0xFFF59E0B);
  static const Color statPink = Color(0xFFEC4899);

  static const List<String> _tipos = [
    "Carga",
    "Monitoreo",
    "Inspección",
    "Mantenimiento",
    "Otro",
  ];
  static const List<String> _importancias = ["Alta", "Media", "Baja"];
  static const List<String> _estados = [
    "Pendiente",
    "En progreso",
    "Completada",
  ];

  static const List<String> _estadosFiltro = [
    "Todos",
    "Pendiente",
    "En progreso",
    "Completada",
  ];
  static const List<String> _importanciasFiltro = [
    "Todas",
    "Alta",
    "Media",
    "Baja",
  ];
  static const List<String> _ordenOpciones = ["Más recientes", "Más antiguas"];

  final AuthService _authService = AuthService();
  String? userRole;

  String _searchQuery = "";
  String _estadoFiltro = "Todos";
  String _importanciaFiltro = "Todas";
  String _ordenarPor = "Más recientes";
  int _currentPage = 1;
  static const int _pageSize = 4;

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

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  IconData _iconForTipo(String tipo) {
    switch (tipo) {
      case "Carga":
        return Icons.inventory_2_outlined;
      case "Monitoreo":
        return Icons.thermostat_outlined;
      case "Inspección":
        return Icons.fact_check_outlined;
      case "Mantenimiento":
        return Icons.settings_outlined;
      default:
        return Icons.task_alt_outlined;
    }
  }

  Color _colorForTipo(String tipo) {
    switch (tipo) {
      case "Carga":
        return neonPurple;
      case "Monitoreo":
        return statBlue;
      case "Inspección":
        return statGreen;
      case "Mantenimiento":
        return statBlue;
      default:
        return Colors.white54;
    }
  }

  Color _colorForImportancia(String importancia) {
    switch (importancia) {
      case "Alta":
        return statPink;
      case "Media":
        return statOrange;
      case "Baja":
        return statGreen;
      default:
        return Colors.white54;
    }
  }

  InputDecoration _fieldDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: icon != null
          ? Icon(icon, color: neonPurple.withOpacity(0.8), size: 20)
          : null,
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
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required IconData icon,
    required T value,
    required List<T> options,
    required void Function(T?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: darkBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: neonPurple.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: neonPurple.withOpacity(0.8), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              underline: const SizedBox(),
              dropdownColor: cardBg,
              hint: Text(label, style: const TextStyle(color: Colors.white54)),
              items: options
                  .map(
                    (option) => DropdownMenuItem(
                      value: option,
                      child: Text(
                        option.toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _crearTarea(BuildContext context) async {
    final nombreController = TextEditingController();
    final procedimientoController = TextEditingController();
    final cantidadController = TextEditingController();
    final tiempoController = TextEditingController();
    final observacionesController = TextEditingController();
    String tipoSeleccionado = _tipos.first;
    String importanciaSeleccionada = _importancias.last;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: neonPurple.withOpacity(0.3)),
          ),
          title: const Text(
            "Nueva Tarea",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDecoration(
                    "Nombre",
                    icon: Icons.drive_file_rename_outline,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDropdownField<String>(
                  label: "Tipo",
                  icon: Icons.category_outlined,
                  value: tipoSeleccionado,
                  options: _tipos,
                  onChanged: (valor) {
                    setDialogState(() => tipoSeleccionado = valor!);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: procedimientoController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDecoration(
                    "Procedimiento",
                    icon: Icons.list_alt_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cantidadController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDecoration("Cantidad", icon: Icons.tag),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tiempoController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDecoration(
                    "Tiempo estimado",
                    icon: Icons.access_time_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDropdownField<String>(
                  label: "Importancia",
                  icon: Icons.priority_high,
                  value: importanciaSeleccionada,
                  options: _importancias,
                  onChanged: (valor) {
                    setDialogState(() => importanciaSeleccionada = valor!);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: observacionesController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDecoration(
                    "Observaciones",
                    icon: Icons.notes_outlined,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancelar",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: neonPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.save_outlined, size: 18),
              onPressed: () async {
                await FirebaseFirestore.instance.collection("tareas").add({
                  "nombre": nombreController.text,
                  "tipo": tipoSeleccionado,
                  "procedimiento": procedimientoController.text,
                  "cantidad": cantidadController.text,
                  "tiempo": tiempoController.text,
                  "observaciones": observacionesController.text,
                  "importancia": importanciaSeleccionada,
                  "estado": "Pendiente",
                  "createdAt": Timestamp.now(),
                });
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              label: const Text("Crear"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editarTarea(
    BuildContext context,
    String id,
    Map<String, dynamic> data,
  ) async {
    final nombreController = TextEditingController(text: data["nombre"]);
    final procedimientoController = TextEditingController(
      text: data["procedimiento"],
    );
    final cantidadController = TextEditingController(text: data["cantidad"]);
    final tiempoController = TextEditingController(text: data["tiempo"]);
    final observacionesController = TextEditingController(
      text: data["observaciones"],
    );
    String tipoSeleccionado = _tipos.contains(data["tipo"])
        ? data["tipo"]
        : _tipos.first;
    String importanciaSeleccionada = _importancias.contains(data["importancia"])
        ? data["importancia"]
        : _importancias.last;
    String estadoSeleccionado = _estados.contains(data["estado"])
        ? data["estado"]
        : _estados.first;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: neonPurple.withOpacity(0.3)),
          ),
          title: const Text(
            "Editar Tarea",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDecoration(
                    "Nombre",
                    icon: Icons.drive_file_rename_outline,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDropdownField<String>(
                  label: "Tipo",
                  icon: Icons.category_outlined,
                  value: tipoSeleccionado,
                  options: _tipos,
                  onChanged: (valor) {
                    setDialogState(() => tipoSeleccionado = valor!);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: procedimientoController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDecoration(
                    "Procedimiento",
                    icon: Icons.list_alt_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cantidadController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDecoration("Cantidad", icon: Icons.tag),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tiempoController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDecoration(
                    "Tiempo estimado",
                    icon: Icons.access_time_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDropdownField<String>(
                  label: "Importancia",
                  icon: Icons.priority_high,
                  value: importanciaSeleccionada,
                  options: _importancias,
                  onChanged: (valor) {
                    setDialogState(() => importanciaSeleccionada = valor!);
                  },
                ),
                const SizedBox(height: 12),
                _buildDropdownField<String>(
                  label: "Estado",
                  icon: Icons.flag_outlined,
                  value: estadoSeleccionado,
                  options: _estados,
                  onChanged: (valor) {
                    setDialogState(() => estadoSeleccionado = valor!);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: observacionesController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDecoration(
                    "Observaciones",
                    icon: Icons.notes_outlined,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancelar",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: neonPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.save_outlined, size: 18),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection("tareas")
                    .doc(id)
                    .update({
                      "nombre": nombreController.text,
                      "tipo": tipoSeleccionado,
                      "procedimiento": procedimientoController.text,
                      "cantidad": cantidadController.text,
                      "tiempo": tiempoController.text,
                      "observaciones": observacionesController.text,
                      "importancia": importanciaSeleccionada,
                      "estado": estadoSeleccionado,
                    });
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              label: const Text("Guardar"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarEliminar(BuildContext context, String id) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: neonPurple.withOpacity(0.3)),
        ),
        title: const Text(
          "Eliminar Tarea",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "¿Seguro de eliminar esta tarea?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancelar",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection("tareas")
                  .doc(id)
                  .delete();
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Tareas",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildTareasContent(),
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
          _sidebarItem(
            Icons.dashboard_outlined,
            "Dashboard",
            false,
            () => Navigator.pushReplacementNamed(context, '/dashboard'),
          ),
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
          _sidebarItem(Icons.task_alt_outlined, "Tareas", true, null),
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

  Widget _buildTareasContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("tareas").snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 80),
            child: CircularProgressIndicator(color: neonPurple),
          );
        }

        final docs = snapshot.data!.docs;

        var registros = docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            "id": doc.id,
            "nombre": data["nombre"] ?? "",
            "tipo": data["tipo"] ?? "Otro",
            "procedimiento": data["procedimiento"] ?? "-",
            "cantidad": data["cantidad"] ?? "-",
            "tiempo": data["tiempo"] ?? "-",
            "observaciones": data["observaciones"] ?? "-",
            "importancia": data["importancia"] ?? "Media",
            "estado": data["estado"] ?? "Pendiente",
            "createdAt": data["createdAt"],
            "raw": data,
          };
        }).toList();

        final totalTareas = registros.length;
        final enProgreso = registros
            .where((r) => r["estado"] == "En progreso")
            .length;
        final completadas = registros
            .where((r) => r["estado"] == "Completada")
            .length;
        final pendientes = registros
            .where((r) => r["estado"] == "Pendiente")
            .length;
        final importanciaAlta = registros
            .where((r) => r["importancia"] == "Alta")
            .length;

        if (_searchQuery.isNotEmpty) {
          registros = registros
              .where(
                (r) =>
                    r["nombre"].toString().toLowerCase().contains(_searchQuery),
              )
              .toList();
        }
        if (_estadoFiltro != "Todos") {
          registros = registros
              .where((r) => r["estado"] == _estadoFiltro)
              .toList();
        }
        if (_importanciaFiltro != "Todas") {
          registros = registros
              .where((r) => r["importancia"] == _importanciaFiltro)
              .toList();
        }

        registros.sort((a, b) {
          final tsA = a["createdAt"];
          final tsB = b["createdAt"];
          if (tsA == null || tsB == null) return 0;
          final cmp = (tsA as Timestamp).compareTo(tsB as Timestamp);
          return _ordenarPor == "Más recientes" ? -cmp : cmp;
        });

        final totalPaginas = (registros.length / _pageSize).ceil().clamp(
          1,
          9999,
        );
        final paginaActual = _currentPage.clamp(1, totalPaginas);
        final inicio = (paginaActual - 1) * _pageSize;
        final fin = (inicio + _pageSize).clamp(0, registros.length);
        final visibles = inicio < registros.length
            ? registros.sublist(inicio, fin)
            : [];

        return Column(
          children: [
            _buildStatsRow(
              totalTareas,
              enProgreso,
              completadas,
              pendientes,
              importanciaAlta,
            ),
            const SizedBox(height: 24),
            _buildFiltersRow(),
            const SizedBox(height: 16),
            if (visibles.isEmpty)
              _buildEmptyState()
            else
              Column(
                children: visibles.map((r) => _buildTareaCard(r)).toList(),
              ),
            const SizedBox(height: 16),
            _buildPaginationRow(
              registros.length,
              inicio,
              fin,
              paginaActual,
              totalPaginas,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsRow(
    int total,
    int enProgreso,
    int completadas,
    int pendientes,
    int importanciaAlta,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.assignment_outlined,
            color: neonPurple,
            value: "$total",
            label: "Total tareas",
            sublabel: "en el sistema",
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildStatCard(
            icon: Icons.autorenew,
            color: statBlue,
            value: "$enProgreso",
            label: "En progreso",
            sublabel: "tareas activas",
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle_outline,
            color: statGreen,
            value: "$completadas",
            label: "Completadas",
            sublabel: "tareas finalizadas",
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildStatCard(
            icon: Icons.schedule_outlined,
            color: statOrange,
            value: "$pendientes",
            label: "Pendientes",
            sublabel: "por iniciar",
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildStatCard(
            icon: Icons.trending_up,
            color: statPink,
            value: "$importanciaAlta",
            label: "Importancia alta",
            sublabel: "requieren atención",
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
    required String sublabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  sublabel,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: neonPurple.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (value) => setState(() {
                _searchQuery = value.toLowerCase();
                _currentPage = 1;
              }),
              decoration: InputDecoration(
                hintText: "Buscar tarea...",
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                filled: true,
                fillColor: darkBg,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: neonPurple.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: neonPurple),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildDropdownField<String>(
              label: "Estado",
              icon: Icons.flag_outlined,
              value: _estadoFiltro,
              options: _estadosFiltro,
              onChanged: (valor) => setState(() {
                _estadoFiltro = valor!;
                _currentPage = 1;
              }),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildDropdownField<String>(
              label: "Importancia",
              icon: Icons.priority_high,
              value: _importanciaFiltro,
              options: _importanciasFiltro,
              onChanged: (valor) => setState(() {
                _importanciaFiltro = valor!;
                _currentPage = 1;
              }),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildDropdownField<String>(
              label: "Ordenar por",
              icon: Icons.sort,
              value: _ordenarPor,
              options: _ordenOpciones,
              onChanged: (valor) => setState(() => _ordenarPor = valor!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTareaCard(Map<String, dynamic> registro) {
    final tipo = registro["tipo"] as String;
    final importancia = registro["importancia"] as String;
    final createdAt = registro["createdAt"];
    final fechaTexto = createdAt is Timestamp
        ? _formatDate(createdAt.toDate())
        : "-";

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: neonPurple.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _colorForTipo(tipo).withOpacity(0.4),
                  _colorForTipo(tipo).withOpacity(0.08),
                ],
              ),
            ),
            child: Icon(_iconForTipo(tipo), color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  registro["nombre"].toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Procedimiento: ${registro["procedimiento"]}  |  Cantidad: ${registro["cantidad"]}",
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _colorForTipo(tipo).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tipo,
                    style: TextStyle(color: _colorForTipo(tipo), fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                const Icon(Icons.access_time, color: Colors.white54, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        registro["tiempo"].toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      const Text(
                        "Tiempo estimado",
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Importancia",
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _colorForImportancia(importancia).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    importancia,
                    style: TextStyle(
                      color: _colorForImportancia(importancia),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: Colors.white54,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Creada",
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                    Text(
                      fechaTexto,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (userRole == "jefe")
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    color: neonPurple.withOpacity(0.9),
                  ),
                  onPressed: () => _editarTarea(
                    context,
                    registro["id"] as String,
                    registro["raw"] as Map<String, dynamic>,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: () =>
                      _confirmarEliminar(context, registro["id"] as String),
                ),
              ],
            ),
        ],
      ),
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
            Icons.task_alt_outlined,
            color: neonPurple.withOpacity(0.5),
            size: 42,
          ),
          const SizedBox(height: 16),
          const Text(
            "No hay tareas que coincidan",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Ajusta los filtros o crea una nueva tarea",
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationRow(
    int total,
    int inicio,
    int fin,
    int paginaActual,
    int totalPaginas,
  ) {
    return Row(
      children: [
        Text(
          total == 0
              ? "Mostrando 0 de 0 tareas"
              : "Mostrando ${inicio + 1} a $fin de $total tareas",
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white70),
          onPressed: paginaActual > 1
              ? () => setState(() => _currentPage = paginaActual - 1)
              : null,
        ),
        for (final entry in _buildPageEntries(totalPaginas, paginaActual))
          entry == -1
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    "...",
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => setState(() => _currentPage = entry),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: entry == paginaActual ? neonPurple : cardBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: neonPurple.withOpacity(0.3)),
                      ),
                      child: Text(
                        "$entry",
                        style: TextStyle(
                          color: entry == paginaActual
                              ? Colors.white
                              : Colors.white70,
                          fontWeight: entry == paginaActual
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: Colors.white70),
          onPressed: paginaActual < totalPaginas
              ? () => setState(() => _currentPage = paginaActual + 1)
              : null,
        ),
        const SizedBox(width: 12),
        if (userRole == "jefe")
          ElevatedButton.icon(
            onPressed: () => _crearTarea(context),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("Nueva tarea"),
            style: ElevatedButton.styleFrom(
              backgroundColor: neonPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
      ],
    );
  }

  List<int> _buildPageEntries(int totalPaginas, int paginaActual) {
    final paginas = List.generate(totalPaginas, (i) => i + 1)
        .where(
          (p) => p == 1 || p == totalPaginas || (p - paginaActual).abs() <= 1,
        )
        .toList();

    final entries = <int>[];
    for (var i = 0; i < paginas.length; i++) {
      if (i > 0 && paginas[i] - paginas[i - 1] > 1) {
        entries.add(-1);
      }
      entries.add(paginas[i]);
    }
    return entries;
  }

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return "$dd/$mm/${date.year}";
  }
}
