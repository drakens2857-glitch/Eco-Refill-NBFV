import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/permisos.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IngresoScreen extends StatefulWidget {
  const IngresoScreen({super.key});

  @override
  State<IngresoScreen> createState() => _IngresoScreenState();
}

class _IngresoScreenState extends State<IngresoScreen>
    with SingleTickerProviderStateMixin {
  static const Color darkBg = Color(0xFF0F0716);
  static const Color sidebarBg = Color(0xFF070216);
  static const Color sidebarBorder = Color(0xFF1E1035);
  static const Color cardBg = Color(0xFF170C28);
  static const Color neonPurple = Color(0xFFA855F7);
  static const Color statPink = Color(0xFFEC4899);
  static const Color statCyan = Color(0xFF22D3EE);

  final List<String> categorias = const [
    "Botellas",
    "Botellones",
    "Canecas",
    "Canastas",
  ];

  late TabController _tabController;
  final AuthService _authService = AuthService();
  String? userRole;

  final Map<String, TextEditingController> _cantidadControllers = {};
  final Map<String, TextEditingController> _notasControllers = {};
  final Map<String, TextEditingController> _tamanoControllers = {};
  final Map<String, TextEditingController> _composicionControllers = {};
  final Map<String, String?> _colorSeleccionado = {};
  final Map<String, DateTime> _fechaSeleccionada = {};
  final Map<String, bool> _verTodos = {};
  // Controla qué grupos (categoría-color) están expandidos en la lista de registros
  final Map<String, bool> _grupoExpandido = {};

  static const List<String> _coloresDisponibles = [
    "Rojo",
    "Azul",
    "Verde",
    "Amarillo",
    "Negro",
    "Blanco",
    "Naranja",
    "Transparente",
    "Morado",
    "Gris",
  ];

  // Unidades disponibles para el tamaño
  static const List<String> _unidadesTamano = ["cm", "ml"];

  // Composiciones químicas disponibles para creación de filamento 3D
  static const List<String> _composicionesQuimicas = [
    "PLA",
    "ABS",
    "PETG",
    "PET",
    "TPU",
    "HDPE",
    "PP",
    "PVC",
    "Nylon (PA)",
    "ASA",
    "PC",
    "HIPS",
  ];

  final Map<String, String> _unidadTamanoSeleccionada = {};
  final Map<String, String?> _composicionSeleccionada = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categorias.length, vsync: this);
    _tabController.addListener(() => setState(() {}));

    for (final categoria in categorias) {
      _cantidadControllers[categoria] = TextEditingController();
      _notasControllers[categoria] = TextEditingController();
      _tamanoControllers[categoria] = TextEditingController();
      _composicionControllers[categoria] = TextEditingController();
      _colorSeleccionado[categoria] = null;
      _fechaSeleccionada[categoria] = DateTime.now();
      _verTodos[categoria] = false;
      _unidadTamanoSeleccionada[categoria] = _unidadesTamano.first;
      _composicionSeleccionada[categoria] = null;
    }

    _loadUserRole();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final controller in _cantidadControllers.values) {
      controller.dispose();
    }
    for (final controller in _notasControllers.values) {
      controller.dispose();
    }
    for (final controller in _tamanoControllers.values) {
      controller.dispose();
    }
    for (final controller in _composicionControllers.values) {
      controller.dispose();
    }
    super.dispose();
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

  IconData _iconForCategoria(String categoria) {
    switch (categoria) {
      case "Botellas":
        return Icons.local_drink_outlined;
      case "Botellones":
        return Icons.oil_barrel_outlined;
      case "Canecas":
        return Icons.delete_outline;
      case "Canastas":
        return Icons.inventory_2_outlined;
      default:
        return Icons.recycling_outlined;
    }
  }

  Color _colorFromName(String? name) {
    switch ((name ?? "").toLowerCase()) {
      case "rojo":
        return Colors.redAccent;
      case "azul":
        return Colors.blueAccent;
      case "verde":
        return Colors.greenAccent;
      case "amarillo":
        return Colors.amber;
      case "negro":
        return Colors.white70;
      case "blanco":
        return Colors.white;
      case "naranja":
        return Colors.orangeAccent;
      case "transparente":
        return Colors.white38;
      case "morado":
        return neonPurple;
      case "gris":
        return Colors.grey;
      default:
        return neonPurple;
    }
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  String _formatDate(DateTime d) =>
      "${_twoDigits(d.day)}/${_twoDigits(d.month)}/${d.year}";

  String _formatTime(DateTime d) =>
      "${_twoDigits(d.hour)}:${_twoDigits(d.minute)}:${_twoDigits(d.second)}";

  Future<void> _pickFechaHora(String categoria) async {
    final actual = _fechaSeleccionada[categoria] ?? DateTime.now();

    final fecha = await showDatePicker(
      context: context,
      initialDate: actual,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (fecha == null) return;

    if (!mounted) return;
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(actual),
    );
    if (hora == null) return;

    setState(() {
      _fechaSeleccionada[categoria] = DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        hora.hour,
        hora.minute,
      );
    });
  }

  Future<void> _guardarIngreso(String categoria) async {
    final color = _colorSeleccionado[categoria];
    final cantidad = int.tryParse(_cantidadControllers[categoria]!.text) ?? 0;

    if (color == null || color.isEmpty || cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Selecciona un color e ingresa una cantidad válida"),
        ),
      );
      return;
    }

    final fecha = _fechaSeleccionada[categoria] ?? DateTime.now();
    final registradoPor =
        FirebaseAuth.instance.currentUser?.email ?? "Desconocido";

    final valorTamano = _tamanoControllers[categoria]!.text.trim();
    final unidadTamano = _unidadTamanoSeleccionada[categoria] ?? "cm";
    final tamanoFinal = valorTamano.isNotEmpty
        ? "$valorTamano $unidadTamano"
        : "";
    final composicionFinal = _composicionSeleccionada[categoria] ?? "";

    await FirebaseFirestore.instance.collection('ingresos').add({
      "categoria": categoria,
      "color": color,
      "cantidad": cantidad,
      "fecha": fecha.toString(),
      "registradoPor": registradoPor,
      "notas": _notasControllers[categoria]!.text,
      "tamano": tamanoFinal,
      "composicionQuimica": composicionFinal,
    });

    _cantidadControllers[categoria]!.clear();
    _notasControllers[categoria]!.clear();
    _tamanoControllers[categoria]!.clear();
    _composicionControllers[categoria]!.clear();

    if (!mounted) return;
    setState(() {
      _colorSeleccionado[categoria] = null;
      _fechaSeleccionada[categoria] = DateTime.now();
      _unidadTamanoSeleccionada[categoria] = _unidadesTamano.first;
      _composicionSeleccionada[categoria] = null;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Ingreso registrado en $categoria")));
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 28),
                    _buildTabsRow(),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: isMobile ? 900 : 720,
                      child: TabBarView(
                        controller: _tabController,
                        children: categorias
                            .map(
                              (categoria) => _buildCategoryContent(categoria),
                            )
                            .toList(),
                      ),
                    ),
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

  // En celular este contenido se muestra dentro de un Drawer; en pantallas
  // grandes queda siempre visible como barra lateral fija.
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
              Icons.dashboard_outlined,
              "Crear Publicaciones",
              false,
              () => Navigator.pushReplacementNamed(context, '/dashboard'),
            ),
          if (Permisos.puedeVer(userRole, 'ingreso'))
            _sidebarItem(
              Icons.add_box_outlined,
              "Ingreso Plásticos",
              true,
              null,
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
    return const Column(
      children: [
        Text(
          "Ingreso de Plásticos",
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 6),
        Text(
          "Registra y gestiona los plásticos que ingresan al sistema",
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildTabsRow() {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: List.generate(categorias.length, (index) {
        final categoria = categorias[index];
        final active = _tabController.index == index;

        return InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () => _tabController.animateTo(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            decoration: BoxDecoration(
              color: active ? neonPurple.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: active ? neonPurple : Colors.white24,
                width: 1.4,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: neonPurple.withOpacity(0.35),
                        blurRadius: 18,
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _iconForCategoria(categoria),
                  color: active ? neonPurple : Colors.white54,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  categoria,
                  style: TextStyle(
                    color: active ? Colors.white : Colors.white54,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCategoryContent(String categoria) {
    final puedeRegistrar = userRole == "ingreso" || userRole == "jefe";

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ingresos')
          .where('categoria', isEqualTo: categoria)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        final registros = docs.map((doc) {
          return {"id": doc.id, "data": doc.data() as Map<String, dynamic>};
        }).toList();

        registros.sort((a, b) {
          final fechaA =
              DateTime.tryParse(
                (a["data"] as Map<String, dynamic>)["fecha"]?.toString() ?? "",
              ) ??
              DateTime(2000);
          final fechaB =
              DateTime.tryParse(
                (b["data"] as Map<String, dynamic>)["fecha"]?.toString() ?? "",
              ) ??
              DateTime(2000);
          return fechaB.compareTo(fechaA);
        });

        int totalEsteMes = 0;
        int totalMesAnterior = 0;
        int totalHistorico = 0;
        final ahora = DateTime.now();
        final mesAnterior = DateTime(ahora.year, ahora.month - 1);

        for (final registro in registros) {
          final data = registro["data"] as Map<String, dynamic>;
          final cantidad = (data["cantidad"] ?? 0) as int;
          totalHistorico += cantidad;

          final fecha = DateTime.tryParse(data["fecha"]?.toString() ?? "");
          if (fecha != null) {
            if (fecha.year == ahora.year && fecha.month == ahora.month) {
              totalEsteMes += cantidad;
            } else if (fecha.year == mesAnterior.year &&
                fecha.month == mesAnterior.month) {
              totalMesAnterior += cantidad;
            }
          }
        }

        double crecimiento;
        if (totalMesAnterior > 0) {
          crecimiento =
              ((totalEsteMes - totalMesAnterior) / totalMesAnterior) * 100;
        } else {
          crecimiento = totalEsteMes > 0 ? 100 : 0;
        }

        // Agrupar los registros por color: si hoy se registran botellas azules
        // y mañana se registran más botellas azules, aparecen en el mismo grupo.
        final Map<String, List<Map<String, dynamic>>> gruposPorColorMap = {};
        for (final registro in registros) {
          final data = registro["data"] as Map<String, dynamic>;
          final colorRegistro = (data["color"] ?? "Sin color").toString();
          gruposPorColorMap.putIfAbsent(colorRegistro, () => []).add(registro);
        }

        final grupos = gruposPorColorMap.entries.map((entry) {
          final registrosDelGrupo = entry.value;
          final totalCantidad = registrosDelGrupo.fold<int>(
            0,
            (sum, r) =>
                sum +
                (((r["data"] as Map<String, dynamic>)["cantidad"] ?? 0) as int),
          );
          final fechaMasReciente = registrosDelGrupo
              .map(
                (r) =>
                    DateTime.tryParse(
                      (r["data"] as Map<String, dynamic>)["fecha"]
                              ?.toString() ??
                          "",
                    ) ??
                    DateTime(2000),
              )
              .reduce((a, b) => a.isAfter(b) ? a : b);
          return {
            "color": entry.key,
            "total": totalCantidad,
            "registros": registrosDelGrupo,
            "fechaReciente": fechaMasReciente,
          };
        }).toList();

        grupos.sort(
          (a, b) => (b["fechaReciente"] as DateTime).compareTo(
            a["fechaReciente"] as DateTime,
          ),
        );

        final verTodos = _verTodos[categoria] ?? false;
        final gruposVisibles = verTodos ? grupos : grupos.take(4).toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;

            final columnaDerecha = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsRow(
                  categoria,
                  totalEsteMes,
                  crecimiento,
                  totalHistorico,
                ),
                const SizedBox(height: 24),
                _buildRegistrosCard(
                  categoria,
                  gruposVisibles,
                  grupos.length,
                  verTodos,
                ),
              ],
            );

            if (!puedeRegistrar) {
              return SingleChildScrollView(child: columnaDerecha);
            }

            return isWide
                ? SingleChildScrollView(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 4, child: _buildFormCard(categoria)),
                        const SizedBox(width: 24),
                        Expanded(flex: 5, child: columnaDerecha),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildFormCard(categoria),
                        const SizedBox(height: 24),
                        columnaDerecha,
                      ],
                    ),
                  );
          },
        );
      },
    );
  }

  Widget _buildFormCard(String categoria) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: neonPurple.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: neonPurple.withOpacity(0.08), blurRadius: 24),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      neonPurple.withOpacity(0.5),
                      neonPurple.withOpacity(0.1),
                    ],
                  ),
                ),
                child: Icon(
                  _iconForCategoria(categoria),
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Registrar ingreso de ${categoria.toLowerCase()}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Completa la información para registrar\nun nuevo ingreso de ${categoria.toLowerCase()}.",
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: darkBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: neonPurple.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.palette_outlined,
                  color: neonPurple.withOpacity(0.8),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButton<String>(
                    value: _colorSeleccionado[categoria],
                    hint: const Text(
                      "Color",
                      style: TextStyle(color: Colors.white54),
                    ),
                    dropdownColor: cardBg,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: _coloresDisponibles
                        .map(
                          (color) => DropdownMenuItem(
                            value: color,
                            child: Text(
                              color,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (valor) {
                      setState(() {
                        _colorSeleccionado[categoria] = valor;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _cantidadControllers[categoria],
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Cantidad",
              hintText: "Ej: 3",
              hintStyle: const TextStyle(color: Colors.white38),
              labelStyle: const TextStyle(color: Colors.white54),
              prefixIcon: Icon(Icons.tag, color: neonPurple.withOpacity(0.8)),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _tamanoControllers[categoria],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Tamaño",
                    hintText: "Ej: 500, 2, 20",
                    hintStyle: const TextStyle(color: Colors.white38),
                    labelStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: Icon(
                      Icons.straighten_outlined,
                      color: neonPurple.withOpacity(0.8),
                    ),
                    filled: true,
                    fillColor: darkBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: neonPurple.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: neonPurple),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: darkBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: neonPurple.withOpacity(0.3)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _unidadTamanoSeleccionada[categoria],
                      dropdownColor: cardBg,
                      isExpanded: true,
                      style: const TextStyle(color: Colors.white),
                      items: _unidadesTamano
                          .map(
                            (unidad) => DropdownMenuItem(
                              value: unidad,
                              child: Text(
                                unidad,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (valor) {
                        setState(() {
                          _unidadTamanoSeleccionada[categoria] =
                              valor ?? _unidadesTamano.first;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: darkBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: neonPurple.withOpacity(0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _composicionSeleccionada[categoria],
                isExpanded: true,
                dropdownColor: cardBg,
                hint: Row(
                  children: [
                    Icon(
                      Icons.science_outlined,
                      color: neonPurple.withOpacity(0.8),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Composición química",
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
                selectedItemBuilder: (context) {
                  return _composicionesQuimicas.map((composicion) {
                    return Row(
                      children: [
                        Icon(
                          Icons.science_outlined,
                          color: neonPurple.withOpacity(0.8),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          composicion,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    );
                  }).toList();
                },
                items: _composicionesQuimicas
                    .map(
                      (composicion) => DropdownMenuItem(
                        value: composicion,
                        child: Text(
                          composicion,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (valor) {
                  setState(() {
                    _composicionSeleccionada[categoria] = valor;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _pickFechaHora(categoria),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: darkBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: neonPurple.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    color: neonPurple.withOpacity(0.8),
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Fecha y hora",
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  const Spacer(),
                  Text(
                    "${_formatDate(_fechaSeleccionada[categoria]!)} "
                    "${_formatTime(_fechaSeleccionada[categoria]!)}",
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.edit_calendar_outlined,
                    color: neonPurple.withOpacity(0.8),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: darkBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: neonPurple.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: neonPurple.withOpacity(0.8),
                  size: 18,
                ),
                const SizedBox(width: 12),
                const Text(
                  "Registrado por",
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const Spacer(),
                Text(
                  FirebaseAuth.instance.currentUser?.email ?? "Usuario actual",
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _notasControllers[categoria],
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Notas (opcional)",
              hintText: "Añadir detalles adicionales...",
              hintStyle: const TextStyle(color: Colors.white38),
              labelStyle: const TextStyle(color: Colors.white54),
              alignLabelWithHint: true,
              prefixIcon: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Icon(
                  Icons.notes_outlined,
                  color: neonPurple.withOpacity(0.8),
                ),
              ),
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
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _guardarIngreso(categoria),
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              label: const Text("Registrar ingreso"),
              style: ElevatedButton.styleFrom(
                backgroundColor: neonPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(
    String categoria,
    int totalEsteMes,
    double crecimiento,
    int totalHistorico,
  ) {
    final crecimientoTexto =
        "${crecimiento >= 0 ? '+' : ''}${crecimiento.toStringAsFixed(0)}%";

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: _iconForCategoria(categoria),
            iconColor: neonPurple,
            value: "$totalEsteMes",
            label: categoria,
            sublabel: "Este mes",
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            icon: Icons.trending_up,
            iconColor: statPink,
            value: crecimientoTexto,
            label: "Vs. mes anterior",
            sublabel: "Crecimiento",
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            icon: Icons.layers_outlined,
            iconColor: statCyan,
            value: "$totalHistorico",
            label: "Total histórico",
            sublabel: "Todas las fechas",
          ),
        ),
      ],
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: iconColor.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withOpacity(0.15),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            sublabel,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrosCard(
    String categoria,
    List<Map<String, dynamic>> gruposVisibles,
    int totalGrupos,
    bool verTodos,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: neonPurple.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                color: neonPurple.withOpacity(0.9),
                size: 20,
              ),
              const SizedBox(width: 10),
              const Text(
                "Registros recientes",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (totalGrupos > 4)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _verTodos[categoria] = !verTodos;
                    });
                  },
                  icon: Icon(
                    verTodos ? Icons.expand_less : Icons.arrow_forward,
                    color: neonPurple,
                    size: 16,
                  ),
                  label: Text(
                    verTodos ? "Ver menos" : "Ver todos",
                    style: const TextStyle(color: neonPurple, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (gruposVisibles.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  "No hay ingresos registrados en $categoria",
                  style: const TextStyle(color: Colors.white54),
                ),
              ),
            )
          else
            Column(
              children: gruposVisibles
                  .map((grupo) => _buildGrupoItem(categoria, grupo))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildGrupoItem(String categoria, Map<String, dynamic> grupo) {
    final color = grupo["color"] as String;
    final total = grupo["total"] as int;
    final registrosDelGrupo =
        grupo["registros"] as List<Map<String, dynamic>>;
    final circleColor = _colorFromName(color);
    final claveGrupo = "$categoria-$color";
    final expandido = _grupoExpandido[claveGrupo] ?? false;

    // Ordenar los registros del grupo del más reciente al más antiguo
    final registrosOrdenados = List<Map<String, dynamic>>.from(
      registrosDelGrupo,
    )..sort((a, b) {
      final fechaA =
          DateTime.tryParse(
            (a["data"] as Map<String, dynamic>)["fecha"]?.toString() ?? "",
          ) ??
          DateTime(2000);
      final fechaB =
          DateTime.tryParse(
            (b["data"] as Map<String, dynamic>)["fecha"]?.toString() ?? "",
          ) ??
          DateTime(2000);
      return fechaB.compareTo(fechaA);
    });

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: darkBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              setState(() {
                _grupoExpandido[claveGrupo] = !expandido;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: circleColor.withOpacity(0.18),
                    ),
                    child: Icon(
                      Icons.local_drink_outlined,
                      color: circleColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Color: $color",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${registrosOrdenados.length} "
                          "${registrosOrdenados.length == 1 ? 'registro' : 'registros'}",
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "Total",
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                      Text(
                        "$total",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    expandido ? Icons.expand_less : Icons.expand_more,
                    color: neonPurple.withOpacity(0.8),
                  ),
                ],
              ),
            ),
          ),
          if (expandido)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: registrosOrdenados.map((registro) {
                  final data = registro["data"] as Map<String, dynamic>;
                  return _buildRegistroItem(data);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRegistroItem(Map<String, dynamic> data) {
    final cantidad = data["cantidad"]?.toString() ?? "0";
    final registradoPor = data["registradoPor"]?.toString() ?? "Desconocido";
    final fecha = DateTime.tryParse(data["fecha"]?.toString() ?? "");
    final circleColor = _colorFromName(data["color"]?.toString());
    final tamano = data["tamano"]?.toString() ?? "";
    final composicion = data["composicionQuimica"]?.toString() ?? "";
    final detalles = [
      if (tamano.isNotEmpty) "Tamaño: $tamano",
      if (composicion.isNotEmpty) "Composición: $composicion",
    ].join(" · ");

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 40,
            decoration: BoxDecoration(
              color: circleColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Registrado por: $registradoPor",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (detalles.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    detalles,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                "Cantidad",
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
              Text(
                cantidad,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fecha != null ? _formatDate(fecha) : "-",
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                fecha != null ? _formatTime(fecha) : "-",
                style: const TextStyle(color: neonPurple, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
