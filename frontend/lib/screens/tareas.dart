import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/permisos.dart';

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
  static const List<String> _unidadesTiempo = [
    "Horas",
    "Minutos",
    "Horas y minutos",
  ];
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

  // Convierte la unidad seleccionada + los controladores de horas/minutos
  // en el texto que se guarda en Firestore (ej: "2 H", "45 min", "1:20").
  String _tiempoATexto(
    String unidad,
    TextEditingController horasController,
    TextEditingController minutosController,
  ) {
    switch (unidad) {
      case "Minutos":
        final m = minutosController.text.trim();
        return m.isEmpty ? "" : "$m min";
      case "Horas y minutos":
        final h = horasController.text.trim().isEmpty
            ? "0"
            : horasController.text.trim();
        final m = minutosController.text.trim().isEmpty
            ? "00"
            : minutosController.text.trim().padLeft(2, '0');
        return "$h:$m";
      case "Horas":
      default:
        final h = horasController.text.trim();
        return h.isEmpty ? "" : "$h H";
    }
  }

  // Interpreta un texto de tiempo ya guardado (formatos antiguos incluidos)
  // para precargar la unidad y los valores al editar una tarea.
  Map<String, String> _parseTiempoTexto(String? tiempo) {
    final texto = (tiempo ?? "").trim();
    if (texto.contains(":")) {
      final partes = texto.split(":");
      return {
        "unidad": "Horas y minutos",
        "horas": partes[0].replaceAll(RegExp(r'[^0-9]'), ''),
        "minutos": partes.length > 1
            ? partes[1].replaceAll(RegExp(r'[^0-9]'), '')
            : "",
      };
    }
    if (texto.toLowerCase().contains("min")) {
      return {
        "unidad": "Minutos",
        "horas": "",
        "minutos": texto.replaceAll(RegExp(r'[^0-9]'), ''),
      };
    }
    return {
      "unidad": "Horas",
      "horas": texto.replaceAll(RegExp(r'[^0-9]'), ''),
      "minutos": "",
    };
  }

  // Campo de "Tiempo estimado": permite elegir entre Horas, Minutos u
  // Horas y minutos (ej. 1:20) y muestra solo los campos necesarios.
  Widget _buildTiempoEstimadoField({
    required String unidad,
    required TextEditingController horasController,
    required TextEditingController minutosController,
    required void Function(String) onUnidadChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdownField<String>(
          label: "Tiempo estimado",
          icon: Icons.access_time_outlined,
          value: unidad,
          options: _unidadesTiempo,
          onChanged: (valor) => onUnidadChanged(valor!),
        ),
        const SizedBox(height: 10),
        if (unidad == "Horas")
          TextField(
            controller: horasController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: Colors.white),
            decoration: _fieldDecoration("Horas", icon: Icons.schedule),
          )
        else if (unidad == "Minutos")
          TextField(
            controller: minutosController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: Colors.white),
            decoration: _fieldDecoration("Minutos", icon: Icons.schedule),
          )
        else
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: horasController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDecoration("Horas", icon: Icons.schedule),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  ":",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: minutosController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDecoration(
                    "Minutos",
                    icon: Icons.schedule,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  // Cuenta palabras para el límite de Observaciones.
  int _contarPalabras(String texto) {
    final limpio = texto.trim();
    if (limpio.isEmpty) return 0;
    return limpio.split(RegExp(r'\s+')).length;
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
    String Function(T)? displayText,
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
                        displayText != null
                            ? displayText(option)
                            : option.toString(),
                        overflow: TextOverflow.ellipsis,
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

  void _mostrarExito(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: statGreen.withOpacity(0.5)),
        ),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: statGreen),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _mostrarEliminado(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
        ),
        content: Row(
          children: [
            const Icon(Icons.delete_forever, color: Colors.redAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.redAccent.withOpacity(0.6)),
        ),
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  Future<void> _crearTarea(BuildContext context) async {
    final nombreController = TextEditingController();
    final cantidadController = TextEditingController();
    final horasController = TextEditingController();
    final minutosController = TextEditingController();
    final observacionesController = TextEditingController();
    String tipoSeleccionado = _tipos.first;
    String importanciaSeleccionada = _importancias.last;
    String unidadTiempoSeleccionada = _unidadesTiempo.first;

    // Trae los procesos ya finalizados para poder vincular la tarea a uno
    final historialSnapshot = await FirebaseFirestore.instance
        .collection("historial")
        .get();
    final procesosDisponibles = historialSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        "id": doc.id,
        "descripcion": (data["descripcion"] ?? "Proceso sin nombre")
            .toString(),
      };
    }).toList();

    Map<String, dynamic>? procesoSeleccionado = procesosDisponibles.isNotEmpty
        ? procesosDisponibles.first
        : null;

    // Trae los usuarios registrados para poder asignarles la tarea
    final usersSnapshot = await FirebaseFirestore.instance
        .collection("users")
        .get();
    final usuariosDisponibles = usersSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        "id": doc.id,
        "nombre": (data["name"] ?? "Sin nombre").toString(),
      };
    }).toList();

    Map<String, dynamic>? usuarioSeleccionado = usuariosDisponibles.isNotEmpty
        ? usuariosDisponibles.first
        : null;

    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: neonPurple.withOpacity(0.3)),
          ),
          title: const Text(
            "Nueva Tarea",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: MediaQuery.of(dialogContext).size.width < 460
                ? MediaQuery.of(dialogContext).size.width - 64
                : 400,
            child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  minLines: 1,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDecoration(
                    "Nombre",
                    icon: Icons.drive_file_rename_outline,
                  ),
                ),
                const SizedBox(height: 12),
                if (usuariosDisponibles.isNotEmpty)
                  _buildDropdownField<Map<String, dynamic>>(
                    label: "Asignar a",
                    icon: Icons.person_outline,
                    value: usuarioSeleccionado!,
                    options: usuariosDisponibles,
                    displayText: (opcion) => opcion["nombre"] as String,
                    onChanged: (valor) {
                      setDialogState(() => usuarioSeleccionado = valor);
                    },
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: darkBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Text(
                      "Aún no hay usuarios registrados para asignar",
                      style: TextStyle(color: Colors.white54, fontSize: 12),
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
                if (procesosDisponibles.isNotEmpty)
                  _buildDropdownField<Map<String, dynamic>>(
                    label: "Proceso de origen",
                    icon: Icons.link_outlined,
                    value: procesoSeleccionado!,
                    options: procesosDisponibles,
                    displayText: (opcion) => opcion["descripcion"] as String,
                    onChanged: (valor) {
                      setDialogState(() => procesoSeleccionado = valor);
                    },
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: darkBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white24,
                      ),
                    ),
                    child: const Text(
                      "Aún no hay procesos finalizados para vincular",
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: cantidadController,
                  minLines: 1,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDecoration("Cantidad", icon: Icons.tag),
                ),
                const SizedBox(height: 12),
                _buildTiempoEstimadoField(
                  unidad: unidadTiempoSeleccionada,
                  horasController: horasController,
                  minutosController: minutosController,
                  onUnidadChanged: (valor) {
                    setDialogState(() => unidadTiempoSeleccionada = valor);
                  },
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
                  minLines: 3,
                  maxLines: 5,
                  inputFormatters: const [_WordLimitFormatter(300)],
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDecoration(
                    "Observaciones",
                    icon: Icons.notes_outlined,
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      "${_contarPalabras(observacionesController.text)}/300 palabras",
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
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
                if (nombreController.text.trim().isEmpty) {
                  _mostrarError("Ponle un nombre a la tarea antes de guardar.");
                  return;
                }
                if (usuarioSeleccionado == null) {
                  _mostrarError(
                    "No hay usuarios registrados para asignar la tarea.",
                  );
                  return;
                }
                try {
                  await FirebaseFirestore.instance
                      .collection("tareas")
                      .add({
                        "nombre": nombreController.text,
                        "tipo": tipoSeleccionado,
                        "cantidad": cantidadController.text,
                        "tiempo": _tiempoATexto(
                          unidadTiempoSeleccionada,
                          horasController,
                          minutosController,
                        ),
                        "observaciones": observacionesController.text,
                        "importancia": importanciaSeleccionada,
                        "estado": "Pendiente",
                        "procesoId": procesoSeleccionado?["id"],
                        "procesoNombre":
                            procesoSeleccionado?["descripcion"] ??
                            "Sin proceso asociado",
                        "usuarioId": usuarioSeleccionado?["id"],
                        "usuarioNombre": usuarioSeleccionado?["nombre"],
                        "leido": false,
                        "createdAt": Timestamp.now(),
                      });
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  _mostrarExito("Tarea creada con éxito");
                } catch (error) {
                  _mostrarError("No se pudo guardar la tarea: $error");
                }
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
    final cantidadController = TextEditingController(text: data["cantidad"]);
    final tiempoInicial = _parseTiempoTexto(data["tiempo"] as String?);
    final horasController = TextEditingController(
      text: tiempoInicial["horas"],
    );
    final minutosController = TextEditingController(
      text: tiempoInicial["minutos"],
    );
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
    String unidadTiempoSeleccionada = _unidadesTiempo.contains(
      tiempoInicial["unidad"],
    )
        ? tiempoInicial["unidad"]!
        : _unidadesTiempo.first;

    // Trae los procesos ya finalizados para poder reasignar/mostrar el vínculo
    final historialSnapshot = await FirebaseFirestore.instance
        .collection("historial")
        .get();
    final procesosDisponibles = historialSnapshot.docs.map((doc) {
      final docData = doc.data();
      return {
        "id": doc.id,
        "descripcion": (docData["descripcion"] ?? "Proceso sin nombre")
            .toString(),
      };
    }).toList();

    Map<String, dynamic>? procesoSeleccionado;
    if (procesosDisponibles.isNotEmpty) {
      procesoSeleccionado = procesosDisponibles.firstWhere(
        (p) => p["id"] == data["procesoId"],
        orElse: () => procesosDisponibles.first,
      );
    }

    // Trae los usuarios registrados para poder reasignar la tarea
    final usersSnapshot = await FirebaseFirestore.instance
        .collection("users")
        .get();
    final usuariosDisponibles = usersSnapshot.docs.map((doc) {
      final docData = doc.data();
      return {
        "id": doc.id,
        "nombre": (docData["name"] ?? "Sin nombre").toString(),
      };
    }).toList();

    Map<String, dynamic>? usuarioSeleccionado;
    if (usuariosDisponibles.isNotEmpty) {
      usuarioSeleccionado = usuariosDisponibles.firstWhere(
        (u) => u["id"] == data["usuarioId"],
        orElse: () => usuariosDisponibles.first,
      );
    }

    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: neonPurple.withOpacity(0.3)),
          ),
          title: const Text(
            "Editar Tarea",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: MediaQuery.of(dialogContext).size.width < 460
                ? MediaQuery.of(dialogContext).size.width - 64
                : 400,
            child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  minLines: 1,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDecoration(
                    "Nombre",
                    icon: Icons.drive_file_rename_outline,
                  ),
                ),
                const SizedBox(height: 12),
                if (usuariosDisponibles.isNotEmpty)
                  _buildDropdownField<Map<String, dynamic>>(
                    label: "Asignar a",
                    icon: Icons.person_outline,
                    value: usuarioSeleccionado!,
                    options: usuariosDisponibles,
                    displayText: (opcion) => opcion["nombre"] as String,
                    onChanged: (valor) {
                      setDialogState(() => usuarioSeleccionado = valor);
                    },
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: darkBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Text(
                      "Aún no hay usuarios registrados para asignar",
                      style: TextStyle(color: Colors.white54, fontSize: 12),
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
                if (procesosDisponibles.isNotEmpty)
                  _buildDropdownField<Map<String, dynamic>>(
                    label: "Proceso de origen",
                    icon: Icons.link_outlined,
                    value: procesoSeleccionado!,
                    options: procesosDisponibles,
                    displayText: (opcion) => opcion["descripcion"] as String,
                    onChanged: (valor) {
                      setDialogState(() => procesoSeleccionado = valor);
                    },
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: darkBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Text(
                      "Aún no hay procesos finalizados para vincular",
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: cantidadController,
                  minLines: 1,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDecoration("Cantidad", icon: Icons.tag),
                ),
                const SizedBox(height: 12),
                _buildTiempoEstimadoField(
                  unidad: unidadTiempoSeleccionada,
                  horasController: horasController,
                  minutosController: minutosController,
                  onUnidadChanged: (valor) {
                    setDialogState(() => unidadTiempoSeleccionada = valor);
                  },
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
                  minLines: 3,
                  maxLines: 5,
                  inputFormatters: const [_WordLimitFormatter(300)],
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDecoration(
                    "Observaciones",
                    icon: Icons.notes_outlined,
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      "${_contarPalabras(observacionesController.text)}/300 palabras",
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
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
                try {
                  await FirebaseFirestore.instance
                      .collection("tareas")
                      .doc(id)
                      .update({
                        "nombre": nombreController.text,
                        "tipo": tipoSeleccionado,
                        "cantidad": cantidadController.text,
                        "tiempo": _tiempoATexto(
                          unidadTiempoSeleccionada,
                          horasController,
                          minutosController,
                        ),
                        "observaciones": observacionesController.text,
                        "importancia": importanciaSeleccionada,
                        "estado": estadoSeleccionado,
                        "procesoId": procesoSeleccionado?["id"],
                        "procesoNombre":
                            procesoSeleccionado?["descripcion"] ??
                            "Sin proceso asociado",
                        "usuarioId": usuarioSeleccionado?["id"],
                        "usuarioNombre": usuarioSeleccionado?["nombre"],
                      });
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  _mostrarExito("Tarea editada con éxito");
                } catch (error) {
                  _mostrarError("No se pudo editar la tarea: $error");
                }
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
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
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
              try {
                await FirebaseFirestore.instance
                    .collection("tareas")
                    .doc(id)
                    .delete();
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                _mostrarEliminado("Tarea eliminada con éxito");
              } catch (error) {
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                _mostrarError("No se pudo eliminar la tarea: $error");
              }
            },
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esMovil = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: darkBg,
      drawer: esMovil
          ? Drawer(
              width: 260,
              backgroundColor: sidebarBg,
              child: _buildSidebar(context),
            )
          : null,
      appBar: esMovil
          ? AppBar(
              backgroundColor: sidebarBg,
              iconTheme: const IconThemeData(color: Colors.white),
              title: const Text(
                "Tareas",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!esMovil) SizedBox(width: 220, child: _buildSidebar(context)),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(esMovil ? 16 : 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (!esMovil)
                      const Text(
                        "Tareas",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (!esMovil) const SizedBox(height: 24),
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
              true,
              null,
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
            "procesoNombre": data["procesoNombre"] ?? "Sin proceso asociado",
            "usuarioNombre": data["usuarioNombre"],
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
    final tarjetas = [
      _buildStatCard(
        icon: Icons.assignment_outlined,
        color: neonPurple,
        value: "$total",
        label: "Total tareas",
        sublabel: "en el sistema",
      ),
      _buildStatCard(
        icon: Icons.autorenew,
        color: statBlue,
        value: "$enProgreso",
        label: "En progreso",
        sublabel: "tareas activas",
      ),
      _buildStatCard(
        icon: Icons.check_circle_outline,
        color: statGreen,
        value: "$completadas",
        label: "Completadas",
        sublabel: "tareas finalizadas",
      ),
      _buildStatCard(
        icon: Icons.schedule_outlined,
        color: statOrange,
        value: "$pendientes",
        label: "Pendientes",
        sublabel: "por iniciar",
      ),
      _buildStatCard(
        icon: Icons.trending_up,
        color: statPink,
        value: "$importanciaAlta",
        label: "Importancia alta",
        sublabel: "requieren atención",
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // En pantallas angostas mostramos 2 tarjetas por fila (1 en celulares
        // muy pequeños); en escritorio, las 5 en una sola fila.
        final esMovil = constraints.maxWidth < 700;
        final columnas = constraints.maxWidth < 420
            ? 1
            : (esMovil ? 2 : tarjetas.length);
        final espacio = 14.0;
        final anchoTarjeta =
            (constraints.maxWidth - espacio * (columnas - 1)) / columnas;

        return Wrap(
          spacing: espacio,
          runSpacing: espacio,
          children: [
            for (final tarjeta in tarjetas)
              SizedBox(width: anchoTarjeta, child: tarjeta),
          ],
        );
      },
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final esMovil = constraints.maxWidth < 700;

          final buscador = TextField(
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
          );

          final dropdownEstado = _buildDropdownField<String>(
            label: "Estado",
            icon: Icons.flag_outlined,
            value: _estadoFiltro,
            options: _estadosFiltro,
            onChanged: (valor) => setState(() {
              _estadoFiltro = valor!;
              _currentPage = 1;
            }),
          );

          final dropdownImportancia = _buildDropdownField<String>(
            label: "Importancia",
            icon: Icons.priority_high,
            value: _importanciaFiltro,
            options: _importanciasFiltro,
            onChanged: (valor) => setState(() {
              _importanciaFiltro = valor!;
              _currentPage = 1;
            }),
          );

          final dropdownOrden = _buildDropdownField<String>(
            label: "Ordenar por",
            icon: Icons.sort,
            value: _ordenarPor,
            options: _ordenOpciones,
            onChanged: (valor) => setState(() => _ordenarPor = valor!),
          );

          if (!esMovil) {
            return Row(
              children: [
                Expanded(flex: 3, child: buscador),
                const SizedBox(width: 12),
                Expanded(child: dropdownEstado),
                const SizedBox(width: 12),
                Expanded(child: dropdownImportancia),
                const SizedBox(width: 12),
                Expanded(child: dropdownOrden),
              ],
            );
          }

          // En celular, cada campo ocupa su propia fila para que no se
          // aprieten ni se corten.
          return Column(
            children: [
              buscador,
              const SizedBox(height: 12),
              dropdownEstado,
              const SizedBox(height: 12),
              dropdownImportancia,
              const SizedBox(height: 12),
              dropdownOrden,
            ],
          );
        },
      ),
    );
  }

  Widget _buildTareaCard(Map<String, dynamic> registro) {
    final tipo = registro["tipo"] as String;
    final importancia = registro["importancia"] as String;
    final estado = registro["estado"] as String? ?? "Pendiente";
    final esCompletada = estado == "Completada";
    final createdAt = registro["createdAt"];
    final fechaTexto = createdAt is Timestamp
        ? _formatDate(createdAt.toDate())
        : "-";

    final avatar = Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: esCompletada
              ? [
                  statGreen.withOpacity(0.55),
                  statGreen.withOpacity(0.12),
                ]
              : [
                  _colorForTipo(tipo).withOpacity(0.4),
                  _colorForTipo(tipo).withOpacity(0.08),
                ],
        ),
      ),
      child: Icon(
        esCompletada ? Icons.check_circle_rounded : _iconForTipo(tipo),
        color: Colors.white,
        size: 24,
      ),
    );

    final infoPrincipal = Column(
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
          "Cantidad: ${registro["cantidad"]}",
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.link_outlined,
              color: neonPurple.withOpacity(0.7),
              size: 13,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                "Proceso: ${registro["procesoNombre"]}",
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: neonPurple.withOpacity(0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        if (registro["usuarioNombre"] != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                color: Colors.white54,
                size: 13,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  "Asignado a: ${registro["usuarioNombre"]}",
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
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
                style: TextStyle(
                  color: _colorForTipo(tipo),
                  fontSize: 11,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: esCompletada
                    ? statGreen.withOpacity(0.22)
                    : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (esCompletada)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: statGreen,
                        size: 12,
                      ),
                    ),
                  Text(
                    estado,
                    style: TextStyle(
                      color: esCompletada ? statGreen : Colors.white60,
                      fontSize: 11,
                      fontWeight:
                          esCompletada ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );

    final tiempoWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.access_time, color: Colors.white54, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              registro["tiempo"].toString(),
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
            const Text(
              "Tiempo estimado",
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ],
    );

    final importanciaWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "Importancia",
          style: TextStyle(color: Colors.white38, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
    );

    final fechaWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.calendar_today_outlined,
          color: Colors.white54,
          size: 16,
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
    );

    final acciones = userRole == "jefe"
        ? Row(
            mainAxisSize: MainAxisSize.min,
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
          )
        : null;

    final decoracion = BoxDecoration(
      color: esCompletada ? statGreen.withOpacity(0.16) : cardBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: esCompletada
            ? statGreen.withOpacity(0.8)
            : neonPurple.withOpacity(0.15),
        width: esCompletada ? 1.6 : 1,
      ),
      boxShadow: esCompletada
          ? [
              BoxShadow(
                color: statGreen.withOpacity(0.25),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ]
          : null,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool esAngosto = constraints.maxWidth < 640;

        if (esAngosto) {
          // 🔹 En pantallas angostas apilamos todo en vertical: evita que
          // "Tiempo estimado"/"Importancia" queden en columnas de pocos
          // píxeles y el texto se parta letra por letra.
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: decoracion,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    avatar,
                    const SizedBox(width: 16),
                    Expanded(child: infoPrincipal),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 20,
                  runSpacing: 10,
                  children: [
                    tiempoWidget,
                    importanciaWidget,
                    fechaWidget,
                  ],
                ),
                if (acciones != null) ...[
                  const SizedBox(height: 4),
                  Align(alignment: Alignment.centerRight, child: acciones),
                ],
              ],
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: decoracion,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              avatar,
              const SizedBox(width: 16),
              Expanded(flex: 3, child: infoPrincipal),
              Expanded(flex: 2, child: tiempoWidget),
              Expanded(flex: 2, child: importanciaWidget),
              Expanded(flex: 2, child: fechaWidget),
              if (acciones != null) acciones,
            ],
          ),
        );
      },
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
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        Text(
          total == 0
              ? "Mostrando 0 de 0 tareas"
              : "Mostrando ${inicio + 1} a $fin de $total tareas",
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
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
          ],
        ),
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

/// Limita el texto ingresado a un número máximo de palabras.
/// Si el usuario intenta superar el límite, se rechaza el cambio
/// y el texto se queda como estaba.
class _WordLimitFormatter extends TextInputFormatter {
  final int maxWords;
  const _WordLimitFormatter(this.maxWords);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final trimmed = newValue.text.trim();
    final palabras = trimmed.isEmpty ? <String>[] : trimmed.split(RegExp(r'\s+'));
    if (palabras.length <= maxWords) {
      return newValue;
    }
    return oldValue;
  }
}
