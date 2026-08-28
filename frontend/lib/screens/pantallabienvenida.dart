import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/permisos.dart';
import '../widgets/panel_chat_ia.dart';
import '../widgets/proceso_filamento_animation.dart';

class PantallaBienvenida extends StatefulWidget {
  const PantallaBienvenida({super.key});

  @override
  State<PantallaBienvenida> createState() => _PantallaBienvenidaState();
}

class _PantallaBienvenidaState extends State<PantallaBienvenida> {
  static const Color darkBg = Color(0xFF0F0716);
  static const Color sidebarBg = Color(0xFF070216);
  static const Color sidebarBorder = Color(0xFF1E1035);
  static const Color neonPurple = Color(0xFFA855F7);
  static const Color cardBg = Color(0xFF130A24);
  static const Color cardBorder = Color(0xFF241238);
  static const Color textGray = Color(0xFF9CA3AF);
  static const Color accentGreen = Color(0xFF34D399);

  // Debajo de este ancho, el sidebar pasa a ser un Drawer deslizable y el
  // resto del contenido se reacomoda en columnas simples (celular).
  static const double _mobileBreakpoint = 800;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthService _authService = AuthService();
  String? userRole;
  bool _mostrarChatIA = false;

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

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < _mobileBreakpoint;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: darkBg,
      // En celular el sidebar se convierte en un Drawer que se abre con el
      // botón de menú del header, en vez de ocupar una columna fija.
      drawer: isMobile
          ? Drawer(
              backgroundColor: sidebarBg,
              child: SafeArea(child: _buildSidebar(context, isMobile: true)),
            )
          : null,
      body: SafeArea(
        child: Stack(
          children: [
            if (isMobile)
              Column(
                children: [
                  _buildHeader(isMobile: true),
                  Expanded(child: _buildInicioContent(context, isMobile: true)),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSidebar(context, isMobile: false),
                  Expanded(
                    child: Column(
                      children: [
                        _buildHeader(isMobile: false),
                        Expanded(
                          child: _buildInicioContent(context, isMobile: false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            // Campana de notificaciones, anclada a la esquina superior
            // derecha. Al tocarla navega a la pantalla de notificaciones
            // del usuario que inició sesión.
            Positioned(
              top: 16,
              right: isMobile ? 12 : 24,
              child: _buildNotificacionesBell(context),
            ),
            // Botón para abrir el chat de informes con IA, anclado a la
            // derecha. Se oculta mientras el panel está abierto.
            // Se usa Visibility (en vez de "if") para que el widget nunca
            // se elimine del árbol a mitad de un gesto de toque; eso es lo
            // que provoca el error "Cannot hit test a render box that has
            // never been laid out".
            Positioned(
              right: isMobile ? 12 : 24,
              bottom: isMobile ? 12 : 24,
              child: Visibility(
                visible: !_mostrarChatIA,
                maintainState: true,
                maintainAnimation: true,
                maintainSize: false,
                // En celular el botón se reduce a solo ícono para no
                // ocupar tanto espacio sobre el contenido.
                child: isMobile
                    ? FloatingActionButton(
                        backgroundColor: neonPurple,
                        foregroundColor: Colors.white,
                        onPressed: () => setState(() => _mostrarChatIA = true),
                        child: const Icon(Icons.auto_awesome),
                      )
                    : FloatingActionButton.extended(
                        backgroundColor: neonPurple,
                        foregroundColor: Colors.white,
                        onPressed: () => setState(() => _mostrarChatIA = true),
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text("Informes IA"),
                      ),
              ),
            ),
            // Panel de chat deslizado desde la derecha. Se limita su ancho
            // para que en celular no se corte contra el borde de la
            // pantalla y en escritorio no ocupe más de lo necesario.
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Visibility(
                visible: _mostrarChatIA,
                maintainState: true,
                maintainAnimation: true,
                maintainSize: false,
                child: SizedBox(
                  width: isMobile ? screenWidth : 400,
                  child: PanelChatIA(
                    onCerrar: () => setState(() => _mostrarChatIA = false),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificacionesBell(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return _bellButton(context, 0);
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
            final tareasSinLeer = (tareasSnapshot.data?.docs ?? [])
                .where((doc) =>
                    (doc.data() as Map<String, dynamic>)["leido"] != true)
                .length;
            final reportesSinLeer = (reportesSnapshot.data?.docs ?? [])
                .where((doc) =>
                    (doc.data() as Map<String, dynamic>)["leido"] != true)
                .length;

            return _bellButton(context, tareasSinLeer + reportesSinLeer);
          },
        );
      },
    );
  }

  Widget _bellButton(BuildContext context, int noLeidas) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: () => Navigator.pushNamed(context, '/pantallanotificaciones'),
          icon: const Icon(
            Icons.notifications_outlined,
            color: Colors.white70,
            size: 26,
          ),
          tooltip: "Notificaciones",
        ),
        if (noLeidas > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: darkBg, width: 1.5),
              ),
              child: Text(
                noLeidas > 9 ? "9+" : "$noLeidas",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

   Widget _buildSidebar(BuildContext context, {required bool isMobile}) {
    return Container(
      width: isMobile ? double.infinity : 220,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: isMobile
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
                // En el Drawer de celular se agrega un botón para cerrarlo
                // manualmente, además del gesto de tocar fuera.
                if (isMobile) ...[
                  const Spacer(),
                  IconButton(
                    onPressed: () => _scaffoldKey.currentState?.closeDrawer(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    splashRadius: 20,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 40),
          if (Permisos.puedeVer(userRole, 'inicio'))
            _sidebarItem(
              Icons.home_outlined,
              "Inicio",
              true,
              null,
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

  Widget _buildHeader({required bool isMobile}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 16 : 28,
        horizontal: isMobile ? 8 : 0,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: neonPurple.withOpacity(0.4), width: 1.5),
        ),
      ),
      child: Row(
        children: [
          if (isMobile)
            IconButton(
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              icon: const Icon(Icons.menu_rounded, color: Colors.white70),
            ),
          Expanded(
            child: Text(
              "Bienvenido al panel principal",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFFC084FC),
                fontSize: isMobile ? 18 : 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Espaciador invisible del mismo ancho que el botón de menú,
          // para que el título quede realmente centrado en celular.
          if (isMobile) const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Contenido de la pantalla de Inicio: hero + proceso + tarjetas + stats
  // ---------------------------------------------------------------------

  final List<Map<String, dynamic>> _pasosProceso = const [
    {
      "imagen": "assets/images/proceso/paso1_plastico.png",
      "titulo": "Plástico",
      "desc": "Recolectamos y seleccionamos el plástico.",
    },
    {
      "imagen": "assets/images/proceso/paso2_trituracion.png",
      "titulo": "Trituración",
      "desc": "El plástico se tritura en pequeñas partículas.",
    },
    {
      "imagen": "assets/images/proceso/paso3_extrusion.png",
      "titulo": "Extrusión",
      "desc": "Las partículas se funden y se extruyen en forma de hilo.",
    },
    {
      "imagen": "assets/images/proceso/paso4_enfriamiento.png",
      "titulo": "Enfriamiento",
      "desc": "El filamento pasa por un sistema de enfriamiento.",
    },
    {
      "imagen": "assets/images/proceso/paso5_filamento.png",
      "titulo": "Filamento 3D",
      "desc": "El filamento se enrolla y queda listo para imprimir.",
    },
  ];

  Widget _buildInicioContent(BuildContext context, {required bool isMobile}) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 14 : 24,
        24,
        isMobile ? 14 : 24,
        32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroSection(context, isMobile: isMobile),
          const SizedBox(height: 20),
          _buildFeatureCards(context, isMobile: isMobile),
          const SizedBox(height: 20),
          _buildStatsSection(context, isMobile: isMobile),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, {required bool isMobile}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 28),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: isMobile ? 24 : 30,
                fontWeight: FontWeight.bold,
                height: 1.15,
              ),
              children: const [
                TextSpan(
                  text: "De ",
                  style: TextStyle(color: Colors.white),
                ),
                TextSpan(
                  text: "residuos\n",
                  style: TextStyle(color: Color(0xFFC084FC)),
                ),
                TextSpan(
                  text: "a ",
                  style: TextStyle(color: Colors.white),
                ),
                TextSpan(
                  text: "innovación",
                  style: TextStyle(color: Color(0xFFC084FC)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: textGray,
                height: 1.4,
              ),
              children: [
                TextSpan(text: "Transformamos plástico reciclado en filamento para "),
                TextSpan(
                  text: "impresión 3D",
                  style: TextStyle(color: neonPurple, fontWeight: FontWeight.w600),
                ),
                TextSpan(text: "."),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: neonPurple,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            "En Eco-Refill convertimos desechos plásticos en recursos de "
            "alto valor, impulsando una economía circular y sostenible.",
            style: TextStyle(fontSize: 13, color: textGray, height: 1.5),
          ),
          const SizedBox(height: 22),
          Center(
            child: Container(
              // Halo que rodea el botón siguiendo su misma forma
              // (rectángulo redondeado), en vez de un círculo de luz detrás.
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: neonPurple.withOpacity(0.55),
                    blurRadius: 28,
                    spreadRadius: 4,
                  ),
                  BoxShadow(
                    color: neonPurple.withOpacity(0.30),
                    blurRadius: 55,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: OutlinedButton.icon(
                onPressed: () => _mostrarModalVideo(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: sidebarBg,
                  side: const BorderSide(color: neonPurple, width: 1.2),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 14 : 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.play_circle_fill_rounded, color: neonPurple),
                label: const Text(
                  "Ver el proceso completo",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            "Así convertimos el plástico en filamento 3D",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          _CarruselProceso(pasos: _pasosProceso, isMobile: isMobile),
          const SizedBox(height: 22),
          _buildLineaProgreso(),
          const SizedBox(height: 14),
          const Center(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "Dando nueva vida al plástico, creando un mejor futuro. ",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  TextSpan(text: "♻️", style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineaProgreso() {
    return Row(
      children: List.generate(9, (i) {
        final bool esPunto = i.isEven;
        if (esPunto) {
          return Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: neonPurple,
              shape: BoxShape.circle,
            ),
          );
        }
        return Expanded(
          child: Container(height: 1.5, color: neonPurple.withOpacity(0.4)),
        );
      }),
    );
  }

  Widget _buildFeatureCards(BuildContext context, {required bool isMobile}) {
    final tarjetas = [
      {
        "icon": Icons.recycling_rounded,
        "color": neonPurple,
        "titulo": "Reciclaje",
        "desc": "Damos una segunda vida a los plásticos que contaminan nuestro planeta.",
      },
      {
        "icon": Icons.donut_large_rounded,
        "color": neonPurple,
        "titulo": "Filamento 3D",
        "desc": "Producimos filamento de alta calidad para impresión 3D sostenible.",
      },
      {
        "icon": Icons.eco_rounded,
        "color": accentGreen,
        "titulo": "Impacto Positivo",
        "desc": "Reducimos residuos, ahorramos recursos y construimos un futuro más limpio.",
      },
    ];

    final List<Widget> tarjetasWidgets = [
      for (final t in tarjetas)
        _buildFeatureCard(
          t["icon"] as IconData,
          t["color"] as Color,
          t["titulo"] as String,
          t["desc"] as String,
        ),
    ];

    // En celular se apilan en una sola columna a todo el ancho; en
    // escritorio/tablet se acomodan en un Wrap de tarjetas de 340px.
    if (isMobile) {
      return Column(
        children: [
          for (int i = 0; i < tarjetasWidgets.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            tarjetasWidgets[i],
          ],
        ],
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        for (final w in tarjetasWidgets) SizedBox(width: 340, child: w),
      ],
    );
  }

  Widget _buildFeatureCard(IconData icon, Color color, String titulo, String desc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Color(0xFFC084FC),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: const TextStyle(color: textGray, fontSize: 12.5, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, {required bool isMobile}) {
    // TODO: reemplazar estos valores estáticos por datos reales,
    // por ejemplo con un StreamBuilder a una colección de Firestore
    // (p. ej. "estadisticas" o agregando los documentos de "materiales").
    final stats = [
      {
        "icon": Icons.local_drink_outlined,
        "valor": "1,250 kg",
        "label": "Plástico reciclado",
      },
      {
        "icon": Icons.settings_outlined,
        "valor": "320 kg",
        "label": "Filamento producido",
      },
      {
        "icon": Icons.donut_large_rounded,
        "valor": "45",
        "label": "Rollos generados",
      },
      {
        "icon": Icons.eco_rounded,
        "valor": "875 kg",
        "label": "CO₂ evitado",
      },
    ];

    final List<Widget> statsWidgets = [
      for (final s in stats)
        _buildStatItem(
          s["icon"] as IconData,
          s["valor"] as String,
          s["label"] as String,
        ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Impacto actual",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 18),
          // En celular, una estadística por fila a todo el ancho (un
          // Wrap con ancho infinito rompería el layout, ya que Wrap no
          // acota el ancho de sus hijos); en escritorio se mantiene el
          // Wrap original con tarjetas de 190px una junto a otra.
          if (isMobile)
            Column(
              children: [
                for (int i = 0; i < statsWidgets.length; i++) ...[
                  if (i > 0) const SizedBox(height: 16),
                  statsWidgets[i],
                ],
              ],
            )
          else
            Wrap(
              spacing: 32,
              runSpacing: 20,
              children: [
                for (final w in statsWidgets) SizedBox(width: 190, child: w),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String valor, String label) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: neonPurple.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFFC084FC), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                valor,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: Color(0xFFC084FC), fontSize: 12),
              ),
              const Text(
                "Este mes",
                style: TextStyle(color: textGray, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Modal con el video del proceso completo
  // ---------------------------------------------------------------------

  void _mostrarModalVideo(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < _mobileBreakpoint;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 24,
            vertical: isMobile ? 24 : 40,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 640),
            child: Container(
              padding: EdgeInsets.all(isMobile ? 14 : 24),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                  // Animación del proceso completo (plástico -> filamento 3D).
                  // Cada etapa se agranda y se ilumina más al pasar por
                  // ella; al llegar a la última (Filamento 3D) se detiene,
                  // no vuelve a repetir. Envuelta en SizedBox + scroll para
                  // que no desborde en pantallas pequeñas, y con una altura
                  // reducida en celular para que quepa junto al teclado o
                  // barra de estado sin necesidad de hacer scroll.
                  Flexible(
                    child: SingleChildScrollView(
                      child: SizedBox(
                        height: isMobile ? 420 : 480,
                        child: const ProcesoFilamentoAnimation(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ===========================================================================
// CARRUSEL DE PASOS DEL PROCESO
// ---------------------------------------------------------------------------
// Muestra los pasos en un PageView horizontal: la tarjeta centrada se agranda
// y muestra una luz de fondo (glow), las tarjetas laterales se ven más
// pequeñas y opacas. Avanza solo, sin flechas, cada 5 segundos.
// ===========================================================================

class _CarruselProceso extends StatefulWidget {
  final List<Map<String, dynamic>> pasos;
  final bool isMobile;

  const _CarruselProceso({required this.pasos, required this.isMobile});

  @override
  State<_CarruselProceso> createState() => _CarruselProcesoState();
}

class _CarruselProcesoState extends State<_CarruselProceso> {
  static const Color _neonPurple = Color(0xFFA855F7);
  static const Color _sidebarBg = Color(0xFF070216);
  static const Color _textGray = Color(0xFF9CA3AF);

  late final PageController _controller;
  double _pagina = 0;
  Timer? _timer;

  // Ancho de cada tarjeta y proporción visible del viewport: en celular
  // se muestra prácticamente una sola tarjeta a la vez y más angosta;
  // en escritorio/tablet se ven varias tarjetas vecinas de refilón.
  late final double _itemWidth = widget.isMobile ? 220 : 280;
  late final double _viewportFraction = widget.isMobile ? 0.72 : 0.38;
  late final double _altoCarrusel = widget.isMobile ? 360 : 430;

  // Punto de partida alto para poder desplazarse hacia la izquierda desde
  // el primer paso también (efecto de carrusel infinito en ambas direcciones).
  static const int _offsetInicial = 10000;

  @override
  void initState() {
    super.initState();
    final int paginaInicial = _offsetInicial * widget.pasos.length;
    _controller = PageController(
      viewportFraction: _viewportFraction,
      initialPage: paginaInicial,
    );
    _pagina = paginaInicial.toDouble();
    _controller.addListener(_onScroll);
    _iniciarAutoAvance();
  }

  // Avanza automáticamente un paso cada 5 segundos, sin detenerse (el
  // carrusel es infinito en ambas direcciones, así que no hay última
  // etapa en la que frenar).
  void _iniciarAutoAvance() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _moverA(_pagina.round() + 1);
    });
  }

  void _onScroll() {
    setState(() {
      _pagina = _controller.page ?? _pagina;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _moverA(int indice) {
    _controller.animateToPage(
      indice,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _altoCarrusel,
      child: PageView.builder(
        controller: _controller,
        clipBehavior: Clip.none,
        // itemCount null = scroll infinito en ambas direcciones.
        itemCount: null,
        itemBuilder: (context, index) {
          final int indiceReal = index % widget.pasos.length;
          final double distancia = (index - _pagina).abs().clamp(0.0, 1.0);
          final double escala = 1 - (distancia * 0.30);
          final double cercania = (1 - distancia).clamp(0.0, 1.0);

          return Center(
            child: Transform.scale(
              scale: escala,
              child: _tarjetaPaso(
                widget.pasos[indiceReal],
                indiceReal + 1,
                cercania,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _tarjetaPaso(
    Map<String, dynamic> paso,
    int numero,
    double cercania,
  ) {
    // La imagen crece dentro de un rango proporcional al ancho de la
    // tarjeta (más chico en celular, más grande en escritorio).
    final double imagenBase = widget.isMobile ? 100 : 130;
    final double imagenMax = widget.isMobile ? 38 : 50;
    final double tamanoImagen = imagenBase + (cercania * imagenMax);
    final double boxImagen = widget.isMobile ? 200 : 260;
    final double glowExterior = widget.isMobile ? 90 : 140;
    final double glowInterior = widget.isMobile ? 45 : 70;

    return SizedBox(
      width: _itemWidth,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        // 🔹 Antes el texto nunca bajaba de 45-55% de opacidad, así que
        // se seguía leyendo (y "sangrando" hacia los lados) aunque la
        // tarjeta no estuviera centrada. Ahora toda la tarjeta usa
        // "cercania" (0 = lejos del centro, 1 = centrada) como opacidad,
        // así queda invisible hasta que llega a la mitad.
        opacity: cercania,
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _neonPurple,
              shape: BoxShape.circle,
              boxShadow: cercania > 0.5
                  ? [
                      BoxShadow(
                        color: _neonPurple.withOpacity(0.6 * cercania),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              "$numero",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            paso["titulo"] as String,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14 + (cercania * 2),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            paso["desc"] as String,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textGray,
              fontSize: 11.5,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: boxImagen,
            height: boxImagen,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Capa 1: resplandor exterior amplio y suave (le da el
                // efecto de "mucha luz" alrededor de la tarjeta centrada).
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: cercania,
                  child: Container(
                    width: tamanoImagen + glowExterior,
                    height: tamanoImagen + glowExterior,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _neonPurple.withOpacity(0.55),
                          _neonPurple.withOpacity(0.22),
                          _neonPurple.withOpacity(0.0),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
                // Capa 2: resplandor interior más concentrado y brillante,
                // justo alrededor de la imagen.
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: cercania,
                  child: Container(
                    width: tamanoImagen + glowInterior,
                    height: tamanoImagen + glowInterior,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _neonPurple.withOpacity(0.75),
                          _neonPurple.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: tamanoImagen,
                  height: tamanoImagen,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: _sidebarBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _neonPurple.withOpacity(0.25 + 0.75 * cercania),
                      width: 1.5,
                    ),
                    boxShadow: cercania > 0.25
                        ? [
                            BoxShadow(
                              color: _neonPurple.withOpacity(0.65 * cercania),
                              blurRadius: 50,
                              spreadRadius: 8,
                            ),
                            BoxShadow(
                              color: _neonPurple.withOpacity(0.45 * cercania),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Image.asset(
                    paso["imagen"] as String,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.image_not_supported_outlined,
                      color: _textGray,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}
