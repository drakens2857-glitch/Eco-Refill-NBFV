import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  static const Color backgroundColor = Color(0xFF0B0B16);
  static const Color sidebarBg = Color(0xFF0D0D1A);
  static const Color sidebarBorder = Color(0xFF252238);
  static const Color panelColor = Color(0xFF121225);
  static const Color secondaryPanelColor = Color(0xFF17172C);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color lightPurple = Color(0xFFC084FC);
  static const Color cyan = Color(0xFF34D7FF);

  String _searchText = "";
  String _selectedState = "Todos";
  int _currentPage = 0;

  final int _itemsPerPage = 6;

  final List<String> _roles = ["jefe", "inventario", "ingreso", "proceso"];

  final List<String> _states = ["Todos", "Activo", "Inactivo"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSidebar(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: _buildMainContent(context),
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
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height,
      ),
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
                    border: Border.all(color: purple),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.view_in_ar_rounded,
                    color: lightPurple,
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
          _sidebarItem(Icons.groups_outlined, "Usuarios", true, null),
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
          const SizedBox(height: 70),
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
    String title,
    bool selected,
    VoidCallback? onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? purple.withOpacity(0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? purple.withOpacity(0.45) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? lightPurple : Colors.white70,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLogout() {
    Navigator.pushReplacementNamed(context, '/pantallabienvenida');
  }

  Widget _buildMainContent(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("users").snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              "Error al cargar los usuarios",
              style: TextStyle(color: Colors.redAccent),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: lightPurple),
            ),
          );
        }

        final documents = snapshot.data?.docs ?? [];

        final filteredUsers = documents.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          final name = _value(data["name"]).toLowerCase();
          final email = _value(data["email"]).toLowerCase();
          final phone = _value(data["phone"]).toLowerCase();
          final cargo = _value(data["cargo"]).toLowerCase();

          final estado = _value(data["estado"], fallback: "Activo");

          final matchesSearch =
              name.contains(_searchText) ||
              email.contains(_searchText) ||
              phone.contains(_searchText) ||
              cargo.contains(_searchText);

          final matchesState =
              _selectedState == "Todos" || estado == _selectedState;

          return matchesSearch && matchesState;
        }).toList();

        final activeUsers = documents.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          return _value(data["estado"], fallback: "Activo") == "Activo";
        }).length;

        final totalPages = filteredUsers.isEmpty
            ? 1
            : (filteredUsers.length / _itemsPerPage).ceil();

        if (_currentPage >= totalPages) {
          _currentPage = 0;
        }

        final startIndex = _currentPage * _itemsPerPage;
        final safeStartIndex = startIndex.clamp(0, filteredUsers.length);
        final safeEndIndex = (startIndex + _itemsPerPage).clamp(
          0,
          filteredUsers.length,
        );

        final pageUsers = filteredUsers.sublist(safeStartIndex, safeEndIndex);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 18),
            _buildStatistics(
              totalUsers: documents.length,
              activeUsers: activeUsers,
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 1050;

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildUsersPanel(
                        context,
                        filteredUsers,
                        pageUsers,
                        totalPages,
                      ),
                      const SizedBox(height: 18),
                      _buildRightPanel(
                        context,
                        totalUsers: documents.length,
                        activeUsers: activeUsers,
                      ),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 11,
                      child: _buildUsersPanel(
                        context,
                        filteredUsers,
                        pageUsers,
                        totalPages,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      flex: 8,
                      child: _buildRightPanel(
                        context,
                        totalUsers: documents.length,
                        activeUsers: activeUsers,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Usuarios y Reportes",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Gestiona usuarios del sistema y genera reportes",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics({required int totalUsers, required int activeUsers}) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            title: "Usuarios activos",
            value: "$activeUsers",
            icon: Icons.groups_outlined,
            color: lightPurple,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _statCard(
            title: "Usuarios registrados",
            value: "$totalUsers",
            icon: Icons.badge_outlined,
            color: cyan,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersPanel(
    BuildContext context,
    List<QueryDocumentSnapshot> filteredUsers,
    List<QueryDocumentSnapshot> pageUsers,
    int totalPages,
  ) {
    return Container(
      constraints: const BoxConstraints(minHeight: 620),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Usuarios Registrados",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Lista de todos los usuarios del sistema",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                icon: const Icon(Icons.add),
                label: const Text("Nuevo usuario"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: purple.withOpacity(0.18),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 17,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: purple.withOpacity(0.45)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 620) {
                return Column(
                  children: [
                    _searchField(),
                    const SizedBox(height: 12),
                    _stateDropdown(),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: _searchField()),
                  const SizedBox(width: 14),
                  SizedBox(width: 200, child: _stateDropdown()),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            "Total de usuarios: ${filteredUsers.length}",
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 14),
          if (pageUsers.isEmpty)
            const SizedBox(
              height: 180,
              child: Center(
                child: Text(
                  "No hay usuarios para mostrar",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pageUsers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final document = pageUsers[index];
                final data = document.data() as Map<String, dynamic>;

                return _buildUserCard(context, document.id, data);
              },
            ),
          const SizedBox(height: 18),
          _buildPagination(totalPages),
        ],
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      onChanged: (value) {
        setState(() {
          _searchText = value.trim().toLowerCase();
          _currentPage = 0;
        });
      },
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: "Buscar usuario...",
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.search, color: lightPurple),
        filled: true,
        fillColor: secondaryPanelColor,
        border: _inputBorder(),
        enabledBorder: _inputBorder(),
        focusedBorder: _inputBorder(color: purple),
      ),
    );
  }

  Widget _stateDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedState,
      dropdownColor: secondaryPanelColor,
      style: const TextStyle(color: Colors.white),
      iconEnabledColor: lightPurple,
      decoration: InputDecoration(
        labelText: "Filtrar por estado",
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: secondaryPanelColor,
        border: _inputBorder(),
        enabledBorder: _inputBorder(),
        focusedBorder: _inputBorder(color: purple),
      ),
      items: _states.map((state) {
        return DropdownMenuItem(
          value: state,
          child: Text(state, style: const TextStyle(color: Colors.white)),
        );
      }).toList(),
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          _selectedState = value;
          _currentPage = 0;
        });
      },
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    String documentId,
    Map<String, dynamic> data,
  ) {
    final name = _value(data["name"], fallback: "Usuario");
    final email = _value(data["email"]);
    final phone = _value(data["phone"]);
    final cargo = _value(data["cargo"], fallback: "proceso");
    final estado = _value(data["estado"], fallback: "Activo");

    final isActive = estado.toLowerCase() == "activo";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: secondaryPanelColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 650) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _avatar(name),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _statusBadge(estado, isActive),
                  ],
                ),
                const SizedBox(height: 14),
                _userInfoLine(Icons.email_outlined, email),
                const SizedBox(height: 5),
                _userInfoLine(Icons.phone_outlined, phone),
                const SizedBox(height: 5),
                _userInfoLine(Icons.work_outline, cargo),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _actionButton(
                      icon: Icons.edit_outlined,
                      title: "Editar",
                      color: cyan,
                      onTap: () {
                        _showEditDialog(context, documentId, data);
                      },
                    ),
                    const SizedBox(width: 8),
                    _actionButton(
                      icon: Icons.delete_outline,
                      title: "Eliminar",
                      color: Colors.redAccent,
                      onTap: () {
                        _deleteUser(context, documentId);
                      },
                    ),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              _avatar(name),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _statusBadge(estado, isActive),
                      ],
                    ),
                    const SizedBox(height: 9),
                    _userInfoLine(Icons.email_outlined, email),
                    const SizedBox(height: 5),
                    _userInfoLine(Icons.phone_outlined, phone),
                    const SizedBox(height: 5),
                    _userInfoLine(Icons.work_outline, cargo),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "ID",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    documentId.length > 7
                        ? "${documentId.substring(0, 7)}..."
                        : documentId,
                    style: const TextStyle(
                      color: cyan,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _actionButton(
                        icon: Icons.edit_outlined,
                        title: "Editar",
                        color: cyan,
                        onTap: () {
                          _showEditDialog(context, documentId, data);
                        },
                      ),
                      const SizedBox(width: 8),
                      _actionButton(
                        icon: Icons.delete_outline,
                        title: "Eliminar",
                        color: Colors.redAccent,
                        onTap: () {
                          _deleteUser(context, documentId);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _avatar(String name) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: purple.withOpacity(0.16),
        border: Border.all(color: purple.withOpacity(0.45)),
      ),
      child: Center(
        child: Text(
          _getInitials(name),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String estado, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.greenAccent.withOpacity(0.12)
            : Colors.redAccent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? Colors.greenAccent.withOpacity(0.3)
              : Colors.redAccent.withOpacity(0.3),
        ),
      ),
      child: Text(
        estado,
        style: TextStyle(
          color: isActive ? Colors.greenAccent : Colors.redAccent,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _userInfoLine(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 15),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: color.withOpacity(0.11),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: color.withOpacity(0.28)),
        ),
        child: Icon(icon, color: color, size: 17),
      ),
    );
  }

  Widget _buildRightPanel(
    BuildContext context, {
    required int totalUsers,
    required int activeUsers,
  }) {
    final inactiveUsers = totalUsers - activeUsers;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Resumen",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Información del módulo",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/reportes');
                },
                child: const Text(
                  "Ver reportes",
                  style: TextStyle(color: cyan),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: secondaryPanelColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Estado de usuarios",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                _summaryRow("Usuarios totales", "$totalUsers", lightPurple),
                const SizedBox(height: 12),
                _summaryRow(
                  "Usuarios activos",
                  "$activeUsers",
                  Colors.greenAccent,
                ),
                const SizedBox(height: 12),
                _summaryRow(
                  "Usuarios inactivos",
                  "$inactiveUsers",
                  Colors.orangeAccent,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: secondaryPanelColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Acciones rápidas",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _quickAction(
                  icon: Icons.bar_chart_outlined,
                  title: "Reportes",
                  subtitle: "Consultar reportes",
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/reportes');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: purple.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: purple.withOpacity(0.25)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: lightPurple, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Puedes utilizar los accesos rápidos para navegar por los módulos principales del sistema.",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.4,
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

  Widget _summaryRow(String title, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title, style: const TextStyle(color: Colors.white70)),
        ),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: purple.withOpacity(0.15),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: lightPurple),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination(int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _paginationButton(
          icon: Icons.chevron_left,
          enabled: _currentPage > 0,
          onTap: () {
            if (_currentPage > 0) {
              setState(() {
                _currentPage--;
              });
            }
          },
        ),
        const SizedBox(width: 10),
        for (int index = 0; index < totalPages; index++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () {
                setState(() {
                  _currentPage = index;
                });
              },
              borderRadius: BorderRadius.circular(11),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _currentPage == index ? purple : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: _currentPage == index
                        ? purple
                        : Colors.white.withOpacity(0.12),
                  ),
                ),
                child: Center(
                  child: Text(
                    "${index + 1}",
                    style: TextStyle(
                      color: _currentPage == index
                          ? Colors.white
                          : Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(width: 10),
        _paginationButton(
          icon: Icons.chevron_right,
          enabled: _currentPage < totalPages - 1,
          onTap: () {
            if (_currentPage < totalPages - 1) {
              setState(() {
                _currentPage++;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _paginationButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(enabled ? 0.04 : 0.02),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white70 : Colors.white24,
          size: 20,
        ),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    String documentId,
    Map<String, dynamic> data,
  ) {
    final nameController = TextEditingController(
      text: _value(data["name"], fallback: ""),
    );
    final emailController = TextEditingController(
      text: _value(data["email"], fallback: ""),
    );
    final phoneController = TextEditingController(
      text: _value(data["phone"], fallback: ""),
    );

    String selectedRole = _roles.contains(data["cargo"])
        ? data["cargo"]
        : "proceso";

    String selectedState = _value(data["estado"], fallback: "Activo");

    if (selectedState != "Activo" && selectedState != "Inactivo") {
      selectedState = "Activo";
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: panelColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Editar usuario",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogTextField(
                  controller: nameController,
                  label: "Nombre",
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 12),
                _dialogTextField(
                  controller: emailController,
                  label: "Correo",
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 12),
                _dialogTextField(
                  controller: phoneController,
                  label: "Teléfono",
                  icon: Icons.phone_outlined,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  dropdownColor: secondaryPanelColor,
                  style: const TextStyle(color: Colors.white),
                  decoration: _dialogInputDecoration(
                    "Cargo",
                    Icons.work_outline,
                  ),
                  items: _roles.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(
                        role,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      selectedRole = value;
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedState,
                  dropdownColor: secondaryPanelColor,
                  style: const TextStyle(color: Colors.white),
                  decoration: _dialogInputDecoration(
                    "Estado",
                    Icons.toggle_on_outlined,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: "Activo",
                      child: Text(
                        "Activo",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    DropdownMenuItem(
                      value: "Inactivo",
                      child: Text(
                        "Inactivo",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      selectedState = value;
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                "Cancelar",
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection("users")
                      .doc(documentId)
                      .update({
                        "name": nameController.text.trim(),
                        "email": emailController.text.trim(),
                        "phone": phoneController.text.trim(),
                        "cargo": selectedRole,
                        "estado": selectedState,
                      });

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Usuario actualizado correctamente"),
                      ),
                    );
                  }
                } catch (error) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "No se pudo actualizar el usuario: $error",
                        ),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  Widget _dialogTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: _dialogInputDecoration(label, icon),
    );
  }

  InputDecoration _dialogInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: lightPurple),
      filled: true,
      fillColor: secondaryPanelColor,
      border: _inputBorder(),
      enabledBorder: _inputBorder(),
      focusedBorder: _inputBorder(color: purple),
    );
  }

  Future<void> _deleteUser(BuildContext context, String documentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: panelColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            "Eliminar usuario",
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            "¿Estás seguro de que deseas eliminar este usuario?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                "Cancelar",
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text("Eliminar"),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(documentId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Usuario eliminado correctamente")),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No se pudo eliminar el usuario: $error")),
        );
      }
    }
  }

  OutlineInputBorder _inputBorder({Color color = Colors.transparent}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: color == Colors.transparent
            ? Colors.white.withOpacity(0.09)
            : color,
      ),
    );
  }

  String _value(dynamic value, {String fallback = "-"}) {
    final text = (value ?? "").toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String _getInitials(String name) {
    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      return "U";
    }

    final parts = cleanName.split(RegExp(r"\s+"));

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return "${parts.first.substring(0, 1)}${parts[1].substring(0, 1)}"
        .toUpperCase();
  }
}
