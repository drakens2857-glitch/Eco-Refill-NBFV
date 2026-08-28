import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/permisos.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  static const Color darkBg = Color(0xFF0F0716);
  static const Color sidebarBg = Color(0xFF070216);
  static const Color sidebarBorder = Color(0xFF1E1035);
  static const Color cardBg = Color(0xFF170C28);
  static const Color neonPurple = Color(0xFFA855F7);
  static const Color lightPurple = Color(0xFFC084FC);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color accentTeal = Color(0xFF2DD4BF);
  static const Color accentGreen = Color(0xFF34D399);
  static const Color accentOrange = Color(0xFFF59E0B);

  static const Map<String, Color> _categoriaColor = {
    "Usuarios": neonPurple,
    "Accesos": accentGreen,
    "Actividad": accentBlue,
    "Seguridad": accentOrange,
  };
  static const Map<String, IconData> _categoriaIcon = {
    "Usuarios": Icons.people_alt_outlined,
    "Accesos": Icons.shield_outlined,
    "Actividad": Icons.show_chart_rounded,
    "Seguridad": Icons.gpp_maybe_outlined,
  };

  // paleta que se asigna en orden a cada valor distinto de "cargo"
  static const List<Color> _cargoPalette = [
    accentBlue,
    accentTeal,
    neonPurple,
    accentOrange,
    Color(0xFFF472B6),
    Color(0xFF38BDF8),
    Color(0xFFFBBF24),
  ];

  String _capitalize(String s) =>
      s.isEmpty ? s : "${s[0].toUpperCase()}${s.substring(1)}";

  final AuthService _authService = AuthService();
  String? userRole;

  String? _selectedUserId;
  final _reporteController = TextEditingController();

  // ---- estado del panel "Generar reporte" ----
  int _selectedTabIndex = 0; // 0 Resumen, 1 Usuarios, 2 Accesos
  String _tipoReporte = "Usuarios";
  DateTimeRange? _rangoFechas;
  String _filtroRol = "Todos los roles";

  static const List<String> _meses = [
    "Ene", "Feb", "Mar", "Abr", "May", "Jun",
    "Jul", "Ago", "Sep", "Oct", "Nov", "Dic",
  ];

  String _fmtDate(DateTime d) => "${d.day} ${_meses[d.month - 1]} ${d.year}";

  // Hoy, sin hora (límite inferior: no se puede elegir hacia atrás).
  DateTime _hoySinHora() {
    final ahora = DateTime.now();
    return DateTime(ahora.year, ahora.month, ahora.day);
  }

  // Límite superior: máximo 1 mes hacia adelante desde hoy.
  DateTime _fechaMaxima() {
    final hoy = _hoySinHora();
    return DateTime(hoy.year, hoy.month + 1, hoy.day);
  }

  DateTimeRange _rangoFechasPorDefecto() {
    final hoy = _hoySinHora();
    return DateTimeRange(start: hoy, end: hoy.add(const Duration(days: 7)));
  }

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _rangoFechas = _rangoFechasPorDefecto();
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

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  Future<void> _subirReporte() async {
    final texto = _reporteController.text.trim();
    if (_selectedUserId == null || texto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Selecciona un usuario y escribe un reporte")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection("reportes").add({
      "userId": _selectedUserId,
      "texto": texto,
      "leido": false,
      "createdAt": DateTime.now(),
    });

    _reporteController.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Reporte subido correctamente")),
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
                "Reportes",
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
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.all(esMovil ? 16 : 24),
                  child: _buildMainContent(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= SIDEBAR =================
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
              false,
              () => Navigator.pushReplacementNamed(context, '/tareas'),
            ),
          if (Permisos.puedeVer(userRole, 'reportes'))
            _sidebarItem(
              Icons.summarize_outlined,
              "Reportes",
              true,
              null,
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

  // ================= CONTENIDO PRINCIPAL =================
  Widget _buildMainContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderRow(),
        const SizedBox(height: 24),
        _buildStatsRow(),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final esMovil = constraints.maxWidth < 900;

            final contenidoTabs = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.white.withOpacity(0.08)),
                    ),
                  ),
                  child: _buildTabsRow(),
                ),
                const SizedBox(height: 20),
                if (_selectedTabIndex == 0) ...[
                  _buildDonutCard(expandir: false),
                  const SizedBox(height: 20),
                  _buildReportesRecientesCard(expandir: false),
                ] else if (_selectedTabIndex == 1)
                  _buildUsuariosReportesCard()
                else
                  _buildAccessLogsCard(),
              ],
            );

            if (esMovil) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFiltersPanel(),
                  const SizedBox(height: 20),
                  contenidoTabs,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFiltersPanel(),
                const SizedBox(width: 24),
                Expanded(child: contenidoTabs),
              ],
            );
          },
        ),
      ],
    );
  }

  // ---------- encabezado ----------
  Widget _buildHeaderRow() {
    final backButton = IconButton(
      onPressed: () => Navigator.maybePop(context),
      icon: const Icon(Icons.arrow_back, color: Colors.white70),
    );

    final titulo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [neonPurple, Color(0xFF6D28D9)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bar_chart_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              "Reportes",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          "Genera, consulta y exporta reportes de usuarios y actividad del sistema",
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool esAngosto = constraints.maxWidth < 640;

        if (esAngosto) {
          // 🔹 En pantallas angostas el chip de fecha ya no compite por
          // espacio con el título: baja debajo, ocupando todo el ancho.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  backButton,
                  const SizedBox(width: 4),
                  Expanded(child: titulo),
                ],
              ),
              const SizedBox(height: 12),
              _dateRangeChip(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            backButton,
            const SizedBox(width: 4),
            Expanded(child: titulo),
            _dateRangeChip(),
          ],
        );
      },
    );
  }

  Widget _dateRangeChip() {
    final text = _rangoFechas == null
        ? "Seleccionar fechas"
        : "${_fmtDate(_rangoFechas!.start)} - ${_fmtDate(_rangoFechas!.end)}";
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: _hoySinHora(),
          lastDate: _fechaMaxima(),
          initialDateRange: _rangoFechas,
        );
        if (picked != null) setState(() => _rangoFechas = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 16, color: lightPurple),
            const SizedBox(width: 8),
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down,
                size: 18, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  // ---------- tarjetas de estadísticas ----------
  Widget _buildStatsRow() {
    final tarjetas = [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection("users").snapshots(),
          builder: (context, snapshot) {
            final count =
                snapshot.hasData ? snapshot.data!.docs.length.toString() : "--";
            return _statCard(
              icon: Icons.people_alt_outlined,
              iconColor: accentBlue,
              title: "Usuarios registrados",
              value: count,
              deltaIcon: Icons.trending_up_rounded,
              deltaColor: accentGreen,
              deltaText: "+2 esta semana",
            );
          },
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection("users").snapshots(),
          builder: (context, usersSnap) {
            final totalUsuarios =
                usersSnap.hasData ? usersSnap.data!.docs.length : 0;
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("access_logs")
                  .where("status", isEqualTo: "authorized")
                  .snapshots(),
              builder: (context, logsSnap) {
                String value = "--";
                String delta = "Con acceso autorizado";
                if (usersSnap.hasData && logsSnap.hasData) {
                  final uids = <String>{};
                  for (final doc in logsSnap.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final uid = data["uid"] as String?;
                    if (uid != null) uids.add(uid);
                  }
                  value = uids.length.toString();
                  if (totalUsuarios > 0) {
                    final pct = (uids.length / totalUsuarios * 100)
                        .toStringAsFixed(1);
                    delta = "$pct% del total";
                  }
                }
                return _statCard(
                  icon: Icons.verified_user_outlined,
                  iconColor: accentGreen,
                  title: "Usuarios activos",
                  value: value,
                  deltaIcon: Icons.circle,
                  deltaColor: accentGreen,
                  deltaText: delta,
                );
              },
            );
          },
        ),
        StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance.collection("reportes").snapshots(),
          builder: (context, snapshot) {
            final count =
                snapshot.hasData ? snapshot.data!.docs.length.toString() : "--";
            return _statCard(
              icon: Icons.description_outlined,
              iconColor: lightPurple,
              title: "Reportes generados",
              value: count,
              deltaIcon: Icons.trending_up_rounded,
              deltaColor: accentGreen,
              deltaText: "+5 vs semana anterior",
            );
          },
        ),
        _statCard(
          icon: Icons.remove_red_eye_outlined,
          iconColor: accentOrange,
          title: "Visualizaciones",
          value: "1.248",
          deltaIcon: Icons.trending_up_rounded,
          deltaColor: accentGreen,
          deltaText: "+18% esta semana",
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final esMovil = constraints.maxWidth < 700;
        final columnas = constraints.maxWidth < 420
            ? 1
            : (esMovil ? 2 : tarjetas.length);
        final espacio = 20.0;
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

  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required IconData deltaIcon,
    required Color deltaColor,
    required String deltaText,
  }) {
    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -6,
              top: -6,
              child: Icon(icon, size: 58, color: iconColor.withOpacity(0.08)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(height: 14),
                Text(title,
                    style: const TextStyle(color: Colors.white60, fontSize: 13)),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(deltaIcon, size: 14, color: deltaColor),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        deltaText,
                        style: TextStyle(color: deltaColor, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
    );
  }

  // ---------- panel "Generar reporte" ----------
  Widget _buildFiltersPanel() {
    final esJefe = Permisos.esJefe(userRole);
    return Container(
      width: MediaQuery.of(context).size.width < 900 ? double.infinity : 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Generar reporte",
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            "Selecciona el tipo de reporte y los filtros que deseas aplicar.",
            style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 24),
          _filterLabel("Tipo de reporte"),
          _dropdownField(
            icon: Icons.people_alt_outlined,
            value: _tipoReporte,
            items: const ["Usuarios", "Actividad", "Accesos"],
            onChanged: (v) => setState(() => _tipoReporte = v!),
          ),
          const SizedBox(height: 18),
          _filterLabel("Rango de fechas"),
          _dateRangeField(),
          const SizedBox(height: 18),
          _filterLabel("Filtros adicionales"),
          const SizedBox(height: 8),
          _dropdownField(
            icon: Icons.person_outline,
            value: _filtroRol,
            items: const [
              "Todos los roles",
              "Jefe",
              "Inventario",
              "Ingreso",
              "Proceso",
            ],
            onChanged: (v) => setState(() => _filtroRol = v!),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: esJefe
                  ? _abrirDialogoGenerarReporte
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text("No tienes permisos para generar reportes")),
                      );
                    },
              icon: const Icon(Icons.description_outlined,
                  color: Colors.white, size: 18),
              label: const Text("Generar reporte"),
              style: ElevatedButton.styleFrom(
                backgroundColor: neonPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _tipoReporte = "Usuarios";
                  _filtroRol = "Todos los roles";
                  _rangoFechas = _rangoFechasPorDefecto();
                });
              },
              icon: const Icon(Icons.refresh_rounded,
                  color: Colors.white70, size: 18),
              label:
                  const Text("Limpiar filtros", style: TextStyle(color: Colors.white70)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withOpacity(0.15)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
              color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );

  Widget _dropdownField({
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: darkBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: sidebarBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
          dropdownColor: cardBg,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          items: items
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Row(
                      children: [
                        Icon(icon, size: 16, color: lightPurple),
                        const SizedBox(width: 10),
                        Text(e),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _dateRangeField() {
    final text = _rangoFechas == null
        ? "Seleccionar fechas"
        : "${_fmtDate(_rangoFechas!.start)} - ${_fmtDate(_rangoFechas!.end)}";
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: _hoySinHora(),
          lastDate: _fechaMaxima(),
          initialDateRange: _rangoFechas,
        );
        if (picked != null) setState(() => _rangoFechas = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: darkBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sidebarBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 16, color: lightPurple),
            const SizedBox(width: 10),
            Expanded(
                child: Text(text,
                    style: const TextStyle(color: Colors.white, fontSize: 13))),
            const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  void _abrirDialogoGenerarReporte() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: MediaQuery.of(context).size.width < 460
                ? MediaQuery.of(context).size.width - 40
                : 420,
            child: Stack(
              children: [
                _buildFormularioReporte(),
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------- pestañas ----------
  Widget _buildTabsRow() {
    final tabs = ["Resumen", "Usuarios", "Accesos"];
    return Row(
      children: List.generate(tabs.length, (i) {
        final active = _selectedTabIndex == i;
        return Padding(
          padding: const EdgeInsets.only(right: 28),
          child: InkWell(
            onTap: () => setState(() => _selectedTabIndex = i),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tabs[i],
                  style: TextStyle(
                    color: active ? Colors.white : Colors.white54,
                    fontWeight:
                        active ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 2,
                  width: 28,
                  color: active ? neonPurple : Colors.transparent,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ---------- pestaña "Usuarios": nombre + cantidad de reportes ----------
  Widget _buildUsuariosReportesCard() {
    return _card(
      expandir: false,
      title: "Usuarios",
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("users").snapshots(),
        builder: (context, usersSnapshot) {
          if (!usersSnapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(color: neonPurple)),
            );
          }

          final userDocs = usersSnapshot.data!.docs;
          if (userDocs.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text("Todavía no hay usuarios registrados.",
                  style: TextStyle(color: Colors.white54)),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection("reportes").snapshots(),
            builder: (context, reportesSnapshot) {
              // Cuenta cuántos reportes tiene cada usuario (por su userId).
              final Map<String, int> conteoReportes = {};
              if (reportesSnapshot.hasData) {
                for (final doc in reportesSnapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final uid = (data["userId"] as String?) ?? "";
                  if (uid.isEmpty) continue;
                  conteoReportes[uid] = (conteoReportes[uid] ?? 0) + 1;
                }
              }

              // Ordena de mayor a menor cantidad de reportes.
              final ordenados = userDocs.toList()
                ..sort((a, b) {
                  final ca = conteoReportes[a.id] ?? 0;
                  final cb = conteoReportes[b.id] ?? 0;
                  return cb.compareTo(ca);
                });

              return Column(
                children: ordenados.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final nombre = (data["name"] as String?)?.trim();
                  final cantidad = conteoReportes[doc.id] ?? 0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: neonPurple.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.person_outline,
                              color: lightPurple, size: 18),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            (nombre == null || nombre.isEmpty)
                                ? "Sin nombre"
                                : nombre,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: neonPurple.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "$cantidad ${cantidad == 1 ? 'reporte' : 'reportes'}",
                            style: const TextStyle(
                              color: neonPurple,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }

  // ---------- tarjeta genérica ----------
  Widget _card({
    required String title,
    required Widget child,
    Widget? trailing,
    bool expandir = true,
  }) {
    final tarjeta = Container(
      width: expandir ? null : double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      );
    return expandir ? Expanded(child: tarjeta) : tarjeta;
  }

  // ---------- "Usuarios por cargo" (dona, datos reales de Firestore) ----------
  Widget _buildDonutCard({bool expandir = true}) {
    return _card(
      expandir: expandir,
      title: "Usuarios por cargo",
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("users").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(color: neonPurple)),
            );
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text("Todavía no hay usuarios registrados.",
                  style: TextStyle(color: Colors.white54)),
            );
          }

          // agrupar por el campo real "cargo"
          final Map<String, int> conteo = {};
          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final cargo = (data["cargo"] as String?)?.trim();
            final key = (cargo == null || cargo.isEmpty) ? "Sin cargo" : cargo;
            conteo[key] = (conteo[key] ?? 0) + 1;
          }

          final entries = conteo.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          final data = <Map<String, Object>>[
            for (int i = 0; i < entries.length; i++)
              {
                "label": _capitalize(entries[i].key),
                "value": entries[i].value.toDouble(),
                "color": _cargoPalette[i % _cargoPalette.length],
              },
          ];
          final total = docs.length.toDouble();

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(150, 150),
                      painter: _DonutPainter(data: data, total: total),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          total.toInt().toString(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold),
                        ),
                        const Text("Total",
                            style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: data.map((e) {
                    final value = e["value"] as double;
                    final pct = (value / total * 100).toStringAsFixed(1);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                                color: e["color"] as Color,
                                shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              e["label"] as String,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ),
                          Text(
                            "${value.toInt()} ($pct%)",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------- pestaña "Accesos" (datos reales de access_logs) ----------
  Widget _buildAccessLogsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Accesos recientes",
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("access_logs")
                .orderBy("timestamp", descending: true)
                .limit(15)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child:
                      Center(child: CircularProgressIndicator(color: neonPurple)),
                );
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text("Todavía no hay registros de acceso.",
                      style: TextStyle(color: Colors.white54)),
                );
              }
              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final uid = (data["uid"] as String?) ?? "uid desconocido";
                  final status = (data["status"] as String?) ?? "desconocido";
                  final autorizado = status == "authorized";
                  final color = autorizado ? accentGreen : accentOrange;
                  String fechaHora = "";
                  final ts = data["timestamp"];
                  if (ts is Timestamp) {
                    final d = ts.toDate();
                    fechaHora =
                        "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
                  }
                  final uidCorto =
                      uid.length > 14 ? "${uid.substring(0, 14)}…" : uid;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            autorizado
                                ? Icons.lock_open_rounded
                                : Icons.lock_outline_rounded,
                            color: color,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(uidCorto,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(fechaHora,
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 11)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(status,
                              style: TextStyle(color: color, fontSize: 11)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------- "Reportes recientes" (datos reales de Firestore) ----------
  Widget _buildReportesRecientesCard({bool expandir = true}) {
    return _card(
      expandir: expandir,
      title: "Reportes recientes",
      trailing: TextButton(
        onPressed: _abrirHistorialCompleto,
        child: const Text("Ver todos", style: TextStyle(color: lightPurple, fontSize: 13)),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("reportes")
            .orderBy("createdAt", descending: true)
            .limit(4)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(color: neonPurple)),
            );
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text("Todavía no hay reportes.",
                  style: TextStyle(color: Colors.white54)),
            );
          }
          return Column(
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final texto = (data["texto"] ?? "") as String;
              final categoria = (data["categoria"] as String?) ?? "Usuarios";
              final color = _categoriaColor[categoria] ?? neonPurple;
              final icon = _categoriaIcon[categoria] ?? Icons.description_outlined;
              final titulo = texto.isEmpty
                  ? "Reporte"
                  : (texto.length > 42 ? "${texto.substring(0, 42)}..." : texto);
              String fechaHora = "";
              final createdAt = data["createdAt"];
              if (createdAt is Timestamp) {
                final d = createdAt.toDate();
                fechaHora =
                    "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(titulo,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(fechaHora,
                              style:
                                  const TextStyle(color: Colors.white38, fontSize: 11)),
                        ],
                      ),
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(categoria,
                          style: TextStyle(color: color, fontSize: 11)),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.download_outlined,
                          color: Colors.white54, size: 18),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Descarga no disponible todavía")),
                        );
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _abrirHistorialCompleto() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: MediaQuery.of(context).size.width < 520
                ? MediaQuery.of(context).size.width - 40
                : 480,
            height: 560,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Historial de reportes",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(child: SingleChildScrollView(child: _buildListaReportes())),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= FORMULARIO (solo jefe, dentro del diálogo) =================
  Widget _buildFormularioReporte() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Nuevo reporte",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection("users").snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(color: neonPurple),
                  ),
                );
              }
              final users = snapshot.data!.docs;
              return DropdownButtonFormField<String>(
                value: _selectedUserId,
                items: users.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return DropdownMenuItem(
                    value: doc.id,
                    child: Text(data["name"] ?? "Sin nombre"),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedUserId = value),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.people, color: lightPurple),
                  labelText: "Selecciona usuario",
                  labelStyle: const TextStyle(color: lightPurple),
                  filled: true,
                  fillColor: darkBg,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: sidebarBorder),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: neonPurple),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                dropdownColor: cardBg,
                style: const TextStyle(color: Colors.white),
              );
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reporteController,
            maxLines: 5,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Escribe tu reporte aquí...",
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: darkBg,
              border: OutlineInputBorder(
                borderSide: BorderSide(color: sidebarBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: sidebarBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: neonPurple),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _subirReporte,
              icon: const Icon(Icons.upload, color: Colors.white),
              label: const Text("Subir Reporte"),
              style: ElevatedButton.styleFrom(
                backgroundColor: neonPurple,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
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

  // ================= LISTA COMPLETA DE REPORTES =================
  Widget _buildListaReportes() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("reportes")
          .orderBy("createdAt", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(color: neonPurple),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: const Text(
              "Todavía no hay reportes.",
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final texto = data["texto"] ?? "";
            final leido = data["leido"] == true;
            final createdAt = data["createdAt"];
            String fecha = "";
            if (createdAt is Timestamp) {
              final d = createdAt.toDate();
              fecha = "${d.day}/${d.month}/${d.year}";
            } else if (createdAt is DateTime) {
              fecha = "${createdAt.day}/${createdAt.month}/${createdAt.year}";
            }

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.description_outlined,
                          color: lightPurple, size: 18),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: (leido ? accentGreen : accentOrange)
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              leido ? "Visto" : "No visto",
                              style: TextStyle(
                                color: leido ? accentGreen : accentOrange,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (fecha.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              fecha,
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    texto,
                    style: const TextStyle(color: Colors.white, height: 1.4),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ================= PINTORES PERSONALIZADOS =================
class _DonutPainter extends CustomPainter {
  final List<Map<String, Object>> data;
  final double total;
  const _DonutPainter({required this.data, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.22;
    final radius = (size.width - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    double startAngle = -math.pi / 2;

    for (final e in data) {
      final value = e["value"] as double;
      final sweep = (value / total) * 2 * math.pi;
      final gap = total > 0 ? 0.04 : 0.0;
      final paint = Paint()
        ..color = e["color"] as Color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        math.max(sweep - gap, 0.001),
        false,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.total != total;
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final double chartHeight;
  const _LineChartPainter({
    required this.values,
    required this.labels,
    required this.chartHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const maxValue = 100.0;
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1;
    const textStyle = TextStyle(color: Colors.white38, fontSize: 10);

    for (int i = 0; i <= 4; i++) {
      final y = chartHeight - (chartHeight / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      final tp = TextPainter(
        text: TextSpan(text: (i * 25).toString(), style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(-2, y - 6));
    }

    final stepX = size.width / (values.length - 1);
    final points = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final x = stepX * i;
      final y = chartHeight - (values[i] / maxValue * chartHeight);
      points.add(Offset(x, y));
    }

    final areaPath = Path()..moveTo(points.first.dx, chartHeight);
    for (final p in points) {
      areaPath.lineTo(p.dx, p.dy);
    }
    areaPath.lineTo(points.last.dx, chartHeight);
    areaPath.close();

    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFA855F7).withOpacity(0.35),
          const Color(0xFFA855F7).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight));
    canvas.drawPath(areaPath, areaPaint);

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }
    final linePaint = Paint()
      ..color = const Color(0xFFA855F7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    for (final p in points) {
      canvas.drawCircle(p, 3.5, Paint()..color = const Color(0xFF170C28));
      canvas.drawCircle(
        p,
        3.5,
        Paint()
          ..color = const Color(0xFFA855F7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    for (int i = 0; i < labels.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(stepX * i - tp.width / 2, chartHeight + 10));
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) => false;
}
