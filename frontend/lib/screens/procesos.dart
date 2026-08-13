import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class ProcesosScreen extends StatefulWidget {
  const ProcesosScreen({super.key});

  @override
  State<ProcesosScreen> createState() => _ProcesosScreenState();
}

class _ProcesosScreenState extends State<ProcesosScreen> {
  static const Color darkBg = Color(0xFF0F0716);
  static const Color sidebarBg = Color(0xFF070216);
  static const Color sidebarBorder = Color(0xFF1E1035);
  static const Color cardBg = Color(0xFF170C28);
  static const Color neonPurple = Color(0xFFA855F7);
  static const Color statBlue = Color(0xFF3B82F6);
  static const Color statGreen = Color(0xFF22C55E);
  static const Color statOrange = Color(0xFFF59E0B);

  final AuthService _authService = AuthService();
  String? userRole;
  bool _activosColapsado = false;
  String? _filtroTipoHistorial;

  final fases = const [
    "Limpieza",
    "Preparación",
    "Corte en tiras",
    "Termoformado",
    "Moldeado",
    "Enfriamiento",
    "Enrollado",
    "Almacenamiento",
    "Proceso finalizado",
  ];

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
    final texto = tipo.toLowerCase();
    if (texto.contains("prueba")) return Icons.science_outlined;
    if (texto.contains("limpieza")) return Icons.local_drink_outlined;
    if (texto.contains("preparaci")) return Icons.settings_outlined;
    if (texto.contains("carga")) return Icons.inventory_2_outlined;
    if (texto.contains("revisi") || texto.contains("calidad")) {
      return Icons.fact_check_outlined;
    }
    if (texto.contains("clasific")) return Icons.category_outlined;
    if (texto.contains("tritura")) return Icons.blender_outlined;
    if (texto.contains("molde")) return Icons.category_outlined;
    if (texto.contains("enfriam")) return Icons.ac_unit_outlined;
    if (texto.contains("enroll") || texto.contains("almacen")) {
      return Icons.inventory_outlined;
    }
    return Icons.recycling_outlined;
  }

  ({String label, Color color}) _estadoInfo(int progreso) {
    if (progreso <= 0) {
      return (label: "En espera", color: statOrange);
    } else if (progreso >= 100) {
      return (label: "Completado", color: statGreen);
    }
    return (label: "En ejecución", color: statBlue);
  }

  String _twoDigits(int v) => v.toString().padLeft(2, '0');

  String _formatFecha(DateTime d) =>
      "${_twoDigits(d.day)}/${_twoDigits(d.month)}/${d.year} "
      "${_twoDigits(d.hour)}:${_twoDigits(d.minute)}";

  String _formatFechaTexto(String? raw) {
    if (raw == null) return "-";
    final parsed = DateTime.tryParse(raw);
    return parsed != null ? _formatFecha(parsed) : raw;
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

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> options,
    required void Function(String?) onChanged,
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
            child: DropdownButton<String>(
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
                        option,
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

  void _mostrarFormularioProceso() {
    final descController = TextEditingController();
    final tipoController = TextEditingController();
    final cantidadController = TextEditingController();
    String faseSeleccionada = fases.first;
    double progresoInicial = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: neonPurple.withOpacity(0.3)),
          ),
          title: const Text(
            "Nuevo Proceso",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDecoration(
                    "Descripción",
                    icon: Icons.description_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tipoController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDecoration(
                    "Tipo (ej: Limpieza, Prueba, Carga)",
                    icon: Icons.label_outline,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDropdownField(
                  label: "Fase",
                  icon: Icons.timeline_outlined,
                  value: faseSeleccionada,
                  options: fases,
                  onChanged: (nuevo) {
                    setDialogState(() => faseSeleccionada = nuevo!);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cantidadController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDecoration(
                    "Cantidad a procesar",
                    icon: Icons.tag,
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Progreso inicial: ${progresoInicial.round()}%",
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
                Slider(
                  value: progresoInicial,
                  min: 0,
                  max: 100,
                  divisions: 20,
                  activeColor: neonPurple,
                  inactiveColor: neonPurple.withOpacity(0.2),
                  onChanged: (valor) {
                    setDialogState(() => progresoInicial = valor);
                  },
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
                await FirebaseFirestore.instance.collection("procesos").add({
                  "usuario":
                      FirebaseAuth.instance.currentUser?.email ??
                      "Usuario actual",
                  "descripcion": descController.text,
                  "tipo": tipoController.text.isEmpty
                      ? "General"
                      : tipoController.text,
                  "fase": faseSeleccionada,
                  "progreso": progresoInicial.round(),
                  "cantidad": int.tryParse(cantidadController.text) ?? 0,
                  "fecha": DateTime.now().toString(),
                });
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Proceso creado correctamente")),
                );
              },
              label: const Text("Guardar"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _actualizarProgreso(String id, Map<String, dynamic> data) async {
    double progreso = (data["progreso"] ?? 0).toDouble();

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
            "Actualizar progreso",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${progreso.round()}%",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Slider(
                value: progreso,
                min: 0,
                max: 100,
                divisions: 20,
                activeColor: neonPurple,
                inactiveColor: neonPurple.withOpacity(0.2),
                onChanged: (valor) {
                  setDialogState(() => progreso = valor);
                },
              ),
            ],
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
                backgroundColor: neonPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection("procesos")
                    .doc(id)
                    .update({"progreso": progreso.round()});
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: const Text("Guardar"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cambiarFase(String id, Map<String, dynamic> data) async {
    String faseSeleccionada = fases.contains(data["fase"])
        ? data["fase"]
        : fases.first;

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
            "Cambiar fase",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: _buildDropdownField(
            label: "Fase",
            icon: Icons.timeline_outlined,
            value: faseSeleccionada,
            options: fases,
            onChanged: (nuevo) {
              setDialogState(() => faseSeleccionada = nuevo!);
            },
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
                backgroundColor: neonPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                if (faseSeleccionada == "Proceso finalizado") {
                  await FirebaseFirestore.instance.collection("historial").add({
                    ...data,
                    "fase": faseSeleccionada,
                    "fechaFinalizado": DateTime.now().toString(),
                  });
                  await FirebaseFirestore.instance
                      .collection("procesos")
                      .doc(id)
                      .delete();
                } else {
                  await FirebaseFirestore.instance
                      .collection("procesos")
                      .doc(id)
                      .update({"fase": faseSeleccionada});
                }
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: const Text("Guardar"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _eliminarProceso(String id) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: neonPurple.withOpacity(0.3)),
        ),
        title: const Text(
          "Eliminar Proceso",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "¿Seguro de eliminar este proceso?",
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
                  .collection("procesos")
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

  void _verDetalleHistorial(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: neonPurple.withOpacity(0.3)),
        ),
        title: const Text(
          "Detalle del Proceso",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Descripción: ${data["descripcion"] ?? "-"}",
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              "Tipo: ${data["tipo"] ?? "-"}",
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              "Cantidad procesada: ${data["cantidad"] ?? 0} unid",
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              "Inicio: ${_formatFechaTexto(data["fecha"]?.toString())}",
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              "Finalizado: ${_formatFechaTexto(data["fechaFinalizado"]?.toString())}",
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cerrar",
              style: TextStyle(color: Colors.redAccent),
            ),
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
                      "Procesos",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (userRole == "proceso" || userRole == "jefe")
                      ElevatedButton.icon(
                        onPressed: _mostrarFormularioProceso,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text("Crear Proceso"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: neonPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: BorderSide(
                              color: neonPurple.withOpacity(0.6),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 28),
                    _buildPanelesRow(),
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
          _sidebarItem(Icons.settings_outlined, "Procesos", true, null),
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

  Widget _buildPanelesRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;

        if (!isWide) {
          return Column(
            children: [
              _buildPanelActivos(),
              const SizedBox(height: 24),
              _buildPanelHistorial(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: _activosColapsado ? 1 : 4,
              child: _activosColapsado
                  ? _buildPanelActivosColapsado()
                  : _buildPanelActivos(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 220),
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () =>
                        setState(() => _activosColapsado = !_activosColapsado),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cardBg,
                        border: Border.all(color: neonPurple.withOpacity(0.5)),
                      ),
                      child: Icon(
                        _activosColapsado
                            ? Icons.keyboard_double_arrow_left
                            : Icons.keyboard_double_arrow_right,
                        color: neonPurple,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(flex: 6, child: _buildPanelHistorial()),
          ],
        );
      },
    );
  }

  Widget _buildPanelActivosColapsado() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: neonPurple.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Icon(Icons.play_circle_outline, color: neonPurple.withOpacity(0.8)),
          const SizedBox(height: 8),
          const Text(
            "Activos",
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelActivos() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: neonPurple.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statBlue.withOpacity(0.15),
                ),
                child: const Icon(
                  Icons.play_circle_outline,
                  color: statBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Procesos Activos",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Gestiona los procesos en ejecución",
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("procesos")
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: neonPurple),
                  ),
                );
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    "No hay procesos activos",
                    style: TextStyle(color: Colors.white54),
                  ),
                );
              }

              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildProcesoActivoCard(doc.id, data);
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildInfoBanner(
            icon: Icons.auto_awesome_outlined,
            text:
                "Los procesos en ejecución se mostrarán aquí.\nPuedes crear, pausar o finalizar procesos desde las opciones.",
          ),
        ],
      ),
    );
  }

  Widget _buildProcesoActivoCard(String id, Map<String, dynamic> data) {
    final tipo = (data["tipo"] ?? "General").toString();
    final progreso = (data["progreso"] ?? 0) as int;
    final estado = _estadoInfo(progreso);
    final fechaTexto = _formatFechaTexto(data["fecha"]?.toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: neonPurple.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  neonPurple.withOpacity(0.4),
                  neonPurple.withOpacity(0.08),
                ],
              ),
            ),
            child: Icon(_iconForTipo(tipo), color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        (data["descripcion"] ?? "").toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      color: cardBg,
                      icon: const Icon(
                        Icons.more_vert,
                        color: Colors.white54,
                        size: 18,
                      ),
                      onSelected: (value) {
                        if (value == "progreso") {
                          _actualizarProgreso(id, data);
                        } else if (value == "fase") {
                          _cambiarFase(id, data);
                        } else if (value == "eliminar") {
                          _eliminarProceso(id);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: "progreso",
                          child: Text("Actualizar progreso"),
                        ),
                        PopupMenuItem(
                          value: "fase",
                          child: Text("Cambiar fase"),
                        ),
                        PopupMenuItem(
                          value: "eliminar",
                          child: Text("Eliminar"),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: estado.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: estado.color, size: 8),
                      const SizedBox(width: 6),
                      Text(
                        estado.label,
                        style: TextStyle(color: estado.color, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Colors.white38,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  progreso <= 0 ? "Inicio estimado" : "Inicio",
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  fechaTexto,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.category_outlined,
                            color: Colors.white38,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Tipo",
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                tipo,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Progreso $progreso%",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progreso / 100,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.08),
                    valueColor: AlwaysStoppedAnimation(
                      progreso <= 0 ? Colors.white24 : neonPurple,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelHistorial() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: neonPurple.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: neonPurple.withOpacity(0.15),
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: neonPurple.withOpacity(0.9),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Historial",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Procesos finalizados",
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String?>(
                color: cardBg,
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: darkBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: neonPurple.withOpacity(0.3)),
                  ),
                  child: const Icon(
                    Icons.filter_alt_outlined,
                    color: Colors.white70,
                    size: 18,
                  ),
                ),
                onSelected: (valor) => setState(() {
                  _filtroTipoHistorial = valor;
                }),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: null, child: Text("Todos los tipos")),
                  PopupMenuItem(value: "Limpieza", child: Text("Limpieza")),
                  PopupMenuItem(value: "Prueba", child: Text("Prueba")),
                  PopupMenuItem(value: "Carga", child: Text("Carga")),
                  PopupMenuItem(value: "Revisión", child: Text("Revisión")),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("historial")
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: neonPurple),
                  ),
                );
              }

              var docs = snapshot.data!.docs;

              if (_filtroTipoHistorial != null) {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return (data["tipo"] ?? "") == _filtroTipoHistorial;
                }).toList();
              }

              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    "No hay procesos finalizados",
                    style: TextStyle(color: Colors.white54),
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final columnas = constraints.maxWidth > 600 ? 2 : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columnas,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.9,
                    ),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      return _buildHistorialCard(data);
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
          _buildInfoBanner(
            icon: Icons.folder_open_outlined,
            text:
                "Aquí se muestran los procesos finalizados.\nPuedes revisar los detalles de cada registro.",
          ),
        ],
      ),
    );
  }

  Widget _buildHistorialCard(Map<String, dynamic> data) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _verDetalleHistorial(data),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: darkBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statGreen.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    (data["descripcion"] ?? "").toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(Icons.check_circle, color: statGreen, size: 18),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Finalizado",
                style: TextStyle(color: statGreen, fontSize: 11),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Tipo",
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                      Text(
                        (data["tipo"] ?? "-").toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Finalizado",
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                      Text(
                        _formatFechaTexto(data["fechaFinalizado"]?.toString()),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Cantidad procesada",
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
                Text(
                  "${data["cantidad"] ?? 0} unid",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner({required IconData icon, required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: neonPurple.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: neonPurple.withOpacity(0.7), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
