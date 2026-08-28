import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/permisos.dart';

/// Pantalla de notificaciones. Muestra, para el usuario que inició sesión,
/// únicamente las tareas asignadas a él y los reportes creados a su nombre.
/// Se accede desde la campana ubicada en la esquina superior derecha de
/// PantallaBienvenida.
class PantallaNotificaciones extends StatefulWidget {
  const PantallaNotificaciones({super.key});

  @override
  State<PantallaNotificaciones> createState() =>
      _PantallaNotificacionesState();
}

class _PantallaNotificacionesState extends State<PantallaNotificaciones> {
  static const Color darkBg = Color(0xFF0F0716);
  static const Color sidebarBg = Color(0xFF070216);
  static const Color sidebarBorder = Color(0xFF1E1035);
  static const Color cardBg = Color(0xFF170C28);
  static const Color neonPurple = Color(0xFFA855F7);
  static const Color lightPurple = Color(0xFFC084FC);
  static const Color accentGreen = Color(0xFF34D399);
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color accentBlue = Color(0xFF60A5FA);

  final AuthService _authService = AuthService();
  String? userRole;
  String _filtro = "Todas"; // Todas | Tareas | Reportes

  @override
  void initState() {
    super.initState();
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

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  Future<void> _marcarComoLeido(String coleccion, String id) async {
    try {
      await FirebaseFirestore.instance
          .collection(coleccion)
          .doc(id)
          .update({"leido": true});
    } catch (_) {
      // Si falla, no interrumpe la experiencia del usuario.
    }
  }

  DateTime _fechaDe(dynamic valor) {
    if (valor is Timestamp) return valor.toDate();
    if (valor is DateTime) return valor;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final hh = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return "$dd/$mm/${date.year} · $hh:$min";
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    final mainContent = SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 14 : 24),
        child: _buildMainContent(context),
      ),
    );

    if (isMobile) {
      return Scaffold(
        backgroundColor: darkBg,
        appBar: _buildMobileAppBar(),
        drawer: Drawer(
          backgroundColor: sidebarBg,
          child: SafeArea(child: _buildSidebar(context, isDrawer: true)),
        ),
        body: SafeArea(child: mainContent),
      );
    }

    return Scaffold(
      backgroundColor: darkBg,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSidebar(context),
            Expanded(child: mainContent),
          ],
        ),
      ),
    );
  }

  // Barra superior para la vista móvil, con el botón para abrir el Drawer.
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

  // ================= SIDEBAR (idéntico al resto de pantallas) =================
  Widget _buildSidebar(BuildContext context, {bool isDrawer = false}) {
    return Container(
      width: isDrawer ? null : 220,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: isDrawer
            ? null
            : const Border(right: BorderSide(color: sidebarBorder, width: 1)),
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

  // ================= CONTENIDO PRINCIPAL =================
  Widget _buildMainContent(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Text(
          "No se encontró el usuario actual.",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("tareas")
          .where("usuarioId", isEqualTo: uid)
          .snapshots(),
      builder: (context, tareasSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("reportes")
              .where("userId", isEqualTo: uid)
              .snapshots(),
          builder: (context, reportesSnapshot) {
            final cargando = tareasSnapshot.connectionState ==
                    ConnectionState.waiting ||
                reportesSnapshot.connectionState == ConnectionState.waiting;

            if (cargando) {
              return const Padding(
                padding: EdgeInsets.all(60),
                child: Center(
                  child: CircularProgressIndicator(color: neonPurple),
                ),
              );
            }

            final tareasDocs = tareasSnapshot.data?.docs ?? [];
            final reportesDocs = reportesSnapshot.data?.docs ?? [];

            final notificaciones = <Map<String, dynamic>>[];

            for (final doc in tareasDocs) {
              final data = doc.data() as Map<String, dynamic>;
              notificaciones.add({
                "coleccion": "tareas",
                "id": doc.id,
                "tipo": "tarea",
                "titulo": (data["nombre"] ?? "Tarea sin nombre").toString(),
                "detalle":
                    "Importancia: ${data["importancia"] ?? "-"}  ·  Estado: ${data["estado"] ?? "Pendiente"}",
                "estado": data["estado"] ?? "Pendiente",
                "leido": data["leido"] == true,
                "fecha": _fechaDe(data["createdAt"]),
              });
            }

            for (final doc in reportesDocs) {
              final data = doc.data() as Map<String, dynamic>;
              notificaciones.add({
                "coleccion": "reportes",
                "id": doc.id,
                "tipo": "reporte",
                "titulo": "Nuevo reporte",
                "detalle": (data["texto"] ?? "").toString(),
                "leido": data["leido"] == true,
                "fecha": _fechaDe(data["createdAt"]),
              });
            }

            notificaciones.sort(
              (a, b) => (b["fecha"] as DateTime).compareTo(
                a["fecha"] as DateTime,
              ),
            );

            final filtradas = notificaciones.where((n) {
              if (_filtro == "Tareas") return n["tipo"] == "tarea";
              if (_filtro == "Reportes") return n["tipo"] == "reporte";
              return true;
            }).toList();

            final noLeidas =
                notificaciones.where((n) => n["leido"] == false).length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(noLeidas),
                const SizedBox(height: 18),
                _buildFiltros(),
                const SizedBox(height: 18),
                if (filtradas.isEmpty)
                  _buildEmptyState()
                else
                  ...filtradas.map((n) => _buildNotificacionCard(n)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(int noLeidas) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: neonPurple.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: lightPurple,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Notificaciones",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Tareas y reportes asignados a tu usuario",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          if (noLeidas > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: accentOrange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accentOrange.withOpacity(0.4)),
              ),
              child: Text(
                "$noLeidas sin leer",
                style: const TextStyle(
                  color: accentOrange,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    final opciones = ["Todas", "Tareas", "Reportes"];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: opciones.map((opcion) {
        final activo = _filtro == opcion;
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _filtro = opcion),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: activo ? neonPurple : cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: activo ? neonPurple : Colors.white.withOpacity(0.08),
              ),
            ),
            child: Text(
              opcion,
              style: TextStyle(
                color: activo ? Colors.white : Colors.white70,
                fontWeight: activo ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: const Column(
        children: [
          Icon(Icons.notifications_off_outlined,
              color: Colors.white38, size: 36),
          SizedBox(height: 12),
          Text(
            "No tienes notificaciones por ahora",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificacionCard(Map<String, dynamic> n) {
    final esTarea = n["tipo"] == "tarea";
    final leido = n["leido"] == true;
    final fecha = n["fecha"] as DateTime;
    final Color colorTipo = esTarea ? accentBlue : lightPurple;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: leido
              ? null
              : () => _marcarComoLeido(
                    n["coleccion"] as String,
                    n["id"] as String,
                  ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: leido
                    ? Colors.white.withOpacity(0.08)
                    : neonPurple.withOpacity(0.5),
                width: leido ? 1 : 1.4,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorTipo.withOpacity(0.15),
                  ),
                  child: Icon(
                    esTarea
                        ? Icons.task_alt_outlined
                        : Icons.summarize_outlined,
                    color: colorTipo,
                    size: 20,
                  ),
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
                              n["titulo"] as String,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: leido
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!leido)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 8, top: 4),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: neonPurple,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        n["detalle"] as String,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(fecha),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
