import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class MaterialesScreen extends StatefulWidget {
  const MaterialesScreen({super.key});

  @override
  State<MaterialesScreen> createState() => _MaterialesScreenState();
}

class _MaterialesScreenState extends State<MaterialesScreen> {
  static const Color darkBg = Color(0xFF0F0716);
  static const Color sidebarBg = Color(0xFF070216);
  static const Color sidebarBorder = Color(0xFF1E1035);
  static const Color cardBg = Color(0xFF170C28);
  static const Color neonPurple = Color(0xFFA855F7);

  final AuthService _authService = AuthService();

  String? ingresoSeleccionadoId;
  int cantidadUsada = 0;
  String _searchQuery = "";

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
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

  Future<void> _crearMaterial(BuildContext context) async {
    final nombreController = TextEditingController();
    final grosorController = TextEditingController();
    final colorController = TextEditingController();
    final flexibilidadController = TextEditingController();
    final resistenciaController = TextEditingController();
    final familiaController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: neonPurple.withOpacity(0.3)),
        ),
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    neonPurple.withOpacity(0.6),
                    neonPurple.withOpacity(0.15),
                  ],
                ),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Nuevo Material",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Completa la información del nuevo material",
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              TextField(
                controller: nombreController,
                style: const TextStyle(color: Colors.white),
                decoration: _fieldDecoration(
                  "Nombre",
                  icon: Icons.category_outlined,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: grosorController,
                style: const TextStyle(color: Colors.white),
                decoration: _fieldDecoration(
                  "Grosor",
                  icon: Icons.layers_outlined,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: colorController,
                style: const TextStyle(color: Colors.white),
                decoration: _fieldDecoration(
                  "Color",
                  icon: Icons.water_drop_outlined,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: flexibilidadController,
                style: const TextStyle(color: Colors.white),
                decoration: _fieldDecoration(
                  "Flexibilidad",
                  icon: Icons.waves_outlined,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: resistenciaController,
                style: const TextStyle(color: Colors.white),
                decoration: _fieldDecoration(
                  "Resistencia",
                  icon: Icons.shield_outlined,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: familiaController,
                style: const TextStyle(color: Colors.white),
                decoration: _fieldDecoration(
                  "Familia (Composición Química)",
                  icon: Icons.science_outlined,
                ),
              ),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('ingresos')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CircularProgressIndicator(color: neonPurple),
                    );
                  }

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Text(
                      "No hay ingresos disponibles",
                      style: TextStyle(color: Colors.white54),
                    );
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: darkBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: neonPurple.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.move_to_inbox_outlined,
                          color: neonPurple.withOpacity(0.8),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButton<String>(
                            value: ingresoSeleccionadoId,
                            hint: const Text(
                              "Selecciona ingreso",
                              style: TextStyle(color: Colors.white54),
                            ),
                            dropdownColor: cardBg,
                            isExpanded: true,
                            underline: const SizedBox(),
                            items: docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return DropdownMenuItem(
                                value: doc.id,
                                child: Text(
                                  "${data['categoria']} - ${data['color']} (Disponible: ${data['cantidad']})",
                                  style: const TextStyle(color: Colors.white),
                                ),
                              );
                            }).toList(),
                            onChanged: (nuevo) {
                              setState(() {
                                ingresoSeleccionadoId = nuevo;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              TextField(
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: _fieldDecoration(
                  "Cantidad a usar",
                  icon: Icons.tag,
                ),
                onChanged: (val) {
                  cantidadUsada = int.tryParse(val) ?? 0;
                },
              ),
              const SizedBox(height: 16),
              Divider(color: Colors.white.withOpacity(0.08)),
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
              if (ingresoSeleccionadoId != null && cantidadUsada > 0) {
                final ingresoRef = FirebaseFirestore.instance
                    .collection("ingresos")
                    .doc(ingresoSeleccionadoId);
                final ingresoSnap = await ingresoRef.get();

                if (!ingresoSnap.exists) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("El ingreso seleccionado ya no existe"),
                    ),
                  );
                  return;
                }

                final data = ingresoSnap.data() as Map<String, dynamic>;
                final disponible = data['cantidad'] as int;

                if (cantidadUsada <= disponible) {
                  await FirebaseFirestore.instance
                      .collection("materiales")
                      .add({
                        "nombre": nombreController.text,
                        "grosor": grosorController.text,
                        "color": colorController.text,
                        "flexibilidad": flexibilidadController.text,
                        "resistencia": resistenciaController.text,
                        "familia": familiaController.text,
                        "ingresoId": ingresoSeleccionadoId,
                        "cantidadUsada": cantidadUsada,
                        "createdAt": Timestamp.now(),
                      });

                  await ingresoRef.update({
                    "cantidad": disponible - cantidadUsada,
                  });

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Material creado y ingreso actualizado"),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Cantidad usada mayor a disponible"),
                    ),
                  );
                }
              }
            },
            label: const Text("Crear"),
          ),
        ],
      ),
    );
  }

  Future<void> _editarMaterial(
    BuildContext context,
    String id,
    Map<String, dynamic> data,
  ) async {
    final nombreController = TextEditingController(text: data["nombre"]);
    final grosorController = TextEditingController(text: data["grosor"]);
    final colorController = TextEditingController(text: data["color"]);
    final flexibilidadController = TextEditingController(
      text: data["flexibilidad"],
    );
    final resistenciaController = TextEditingController(
      text: data["resistencia"],
    );
    final familiaController = TextEditingController(text: data["familia"]);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: neonPurple.withOpacity(0.3)),
        ),
        title: const Text(
          "Editar Material",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                style: const TextStyle(color: Colors.white),
                decoration: _fieldDecoration("Nombre"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: grosorController,
                style: const TextStyle(color: Colors.white),
                decoration: _fieldDecoration("Grosor"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: colorController,
                style: const TextStyle(color: Colors.white),
                decoration: _fieldDecoration("Color"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: flexibilidadController,
                style: const TextStyle(color: Colors.white),
                decoration: _fieldDecoration("Flexibilidad"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: resistenciaController,
                style: const TextStyle(color: Colors.white),
                decoration: _fieldDecoration("Resistencia"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: familiaController,
                style: const TextStyle(color: Colors.white),
                decoration: _fieldDecoration("Familia (Composición Química)"),
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
                  .collection("materiales")
                  .doc(id)
                  .update({
                    "nombre": nombreController.text,
                    "grosor": grosorController.text,
                    "color": colorController.text,
                    "flexibilidad": flexibilidadController.text,
                    "resistencia": resistenciaController.text,
                    "familia": familiaController.text,
                  });
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Guardar"),
          ),
        ],
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
          "Eliminar Material",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "¿Seguro de eliminar este material?",
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
                  .collection("materiales")
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
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    Expanded(child: _buildMaterialsGrid()),
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
          _sidebarItem(Icons.recycling_rounded, "Materiales", true, null),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Materiales",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "Catálogo de filamentos y materiales registrados",
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 260,
          child: TextField(
            style: const TextStyle(color: Colors.white),
            onChanged: (value) =>
                setState(() => _searchQuery = value.toLowerCase()),
            decoration: InputDecoration(
              hintText: "Buscar material...",
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Colors.white38),
              filled: true,
              fillColor: cardBg,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: neonPurple.withOpacity(0.25)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: neonPurple),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () => _crearMaterial(context),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("Nuevo Material"),
          style: ElevatedButton.styleFrom(
            backgroundColor: neonPurple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("materiales").snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: neonPurple),
          );
        }

        var docs = snapshot.data!.docs;

        if (_searchQuery.isNotEmpty) {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final nombre = (data["nombre"] ?? "").toString().toLowerCase();
            return nombre.contains(_searchQuery);
          }).toList();
        }

        if (docs.isEmpty) {
          return _buildEmptyState();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 1100
                ? 3
                : constraints.maxWidth > 700
                ? 2
                : 1;

            return GridView.builder(
              itemCount: docs.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.4,
              ),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                return _buildMaterialCard(doc.id, data);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMaterialCard(String id, Map<String, dynamic> data) {
    final nombre = data["nombre"] ?? "Sin nombre";
    final grosor = data["grosor"] ?? "-";
    final color = data["color"] ?? "-";
    final familia = data["familia"] ?? "-";
    final cantidadUsada = data["cantidadUsada"] ?? "-";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: neonPurple.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  neonPurple.withOpacity(0.5),
                  neonPurple.withOpacity(0.08),
                ],
              ),
            ),
            child: Icon(
              Icons.album_rounded,
              color: Colors.white.withOpacity(0.9),
              size: 34,
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
                        nombre.toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
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
                        if (value == "editar") {
                          _editarMaterial(context, id, data);
                        } else if (value == "eliminar") {
                          _confirmarEliminar(context, id);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: "editar", child: Text("Editar")),
                        PopupMenuItem(
                          value: "eliminar",
                          child: Text("Eliminar"),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  "Color: $color  •  Grosor: $grosor",
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildChip("Familia: $familia"),
                    _buildChip("Usado: $cantidadUsada"),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: neonPurple.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(color: neonPurple, fontSize: 11),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            color: neonPurple.withOpacity(0.5),
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            "No hay materiales registrados",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Crea uno con el botón \"Nuevo Material\"",
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
