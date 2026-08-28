import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/permisos.dart';

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
  String? userRole;

  String _searchQuery = "";

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

  static const List<String> _categoriasDisponibles = [
    "Botellas",
    "Botellones",
    "Canecas",
    "Canastas",
  ];

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

  // Opciones de grosor de filamento
  static const List<String> _gruesosDisponibles = [
    "1.75 mm",
    "2.85 mm",
    "3.00 mm",
  ];

  // Opciones de flexibilidad del material
  static const List<String> _flexibilidadesDisponibles = [
    "Rígido",
    "Semi-flexible",
    "Flexible",
    "Muy flexible",
  ];

  // Opciones de resistencia del material
  static const List<String> _resistenciasDisponibles = [
    "Baja",
    "Media",
    "Alta",
    "Muy alta",
  ];

  // Composiciones químicas disponibles para filamento 3D
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

  // Devuelve el valor solo si existe entre las opciones válidas; si no,
  // null para que el Dropdown no falle con un valor desconocido.
  String? _valorSiValido(String? valor, List<String> opciones) {
    if (valor != null && opciones.contains(valor)) return valor;
    return null;
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
    final familiaController = TextEditingController();
    final cantidadController = TextEditingController();

    String? colorSeleccionado;
    String? categoriaSeleccionada;
    String? grosorSeleccionado;
    String? flexibilidadSeleccionada;
    String? resistenciaSeleccionada;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
          content: SizedBox(
            width: MediaQuery.of(context).size.width < 520
                ? MediaQuery.of(context).size.width * 0.8
                : 460,
            child: SingleChildScrollView(
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
                  DropdownButtonFormField<String>(
                    value: grosorSeleccionado,
                    decoration: _fieldDecoration(
                      "Grosor",
                      icon: Icons.layers_outlined,
                    ),
                    dropdownColor: cardBg,
                    style: const TextStyle(color: Colors.white),
                    items: _gruesosDisponibles
                        .map(
                          (g) => DropdownMenuItem(
                            value: g,
                            child: Text(
                              g,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (valor) {
                      setDialogState(() {
                        grosorSeleccionado = valor;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: flexibilidadSeleccionada,
                    decoration: _fieldDecoration(
                      "Flexibilidad",
                      icon: Icons.waves_outlined,
                    ),
                    dropdownColor: cardBg,
                    style: const TextStyle(color: Colors.white),
                    items: _flexibilidadesDisponibles
                        .map(
                          (f) => DropdownMenuItem(
                            value: f,
                            child: Text(
                              f,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (valor) {
                      setDialogState(() {
                        flexibilidadSeleccionada = valor;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: resistenciaSeleccionada,
                    decoration: _fieldDecoration(
                      "Resistencia",
                      icon: Icons.shield_outlined,
                    ),
                    dropdownColor: cardBg,
                    style: const TextStyle(color: Colors.white),
                    items: _resistenciasDisponibles
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(
                              r,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (valor) {
                      setDialogState(() {
                        resistenciaSeleccionada = valor;
                      });
                    },
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
                  Divider(color: Colors.white.withOpacity(0.08)),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Selecciona el color del inventario",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
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
                            value: colorSeleccionado,
                            hint: const Text(
                              "Selecciona color",
                              style: TextStyle(color: Colors.white54),
                            ),
                            dropdownColor: cardBg,
                            isExpanded: true,
                            underline: const SizedBox(),
                            items: _coloresDisponibles
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _colorFromName(c),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          c,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (nuevo) {
                              setDialogState(() {
                                colorSeleccionado = nuevo;
                                categoriaSeleccionada = null;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (colorSeleccionado != null) ...[
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Disponible en color $colorSeleccionado",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('ingresos')
                          .where('color', isEqualTo: colorSeleccionado)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: CircularProgressIndicator(
                              color: neonPurple,
                            ),
                          );
                        }

                        final docs = snapshot.data!.docs;

                        // Agrupamos por categoría (Botellas, Botellones, etc.)
                        // igual que en la pantalla de Ingreso.
                        final Map<String, int> totalPorCategoria = {};
                        final Map<String, int> registrosPorCategoria = {};
                        for (final doc in docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final categoria =
                              (data['categoria'] ?? '').toString();
                          final cantidad = (data['cantidad'] ?? 0) as int;
                          if (cantidad <= 0) continue;
                          totalPorCategoria[categoria] =
                              (totalPorCategoria[categoria] ?? 0) + cantidad;
                          registrosPorCategoria[categoria] =
                              (registrosPorCategoria[categoria] ?? 0) + 1;
                        }

                        final categoriasConStock = _categoriasDisponibles
                            .where(
                              (cat) => (totalPorCategoria[cat] ?? 0) > 0,
                            )
                            .toList();

                        if (categoriasConStock.isEmpty) {
                          return Text(
                            "No hay ingresos disponibles en color "
                            "$colorSeleccionado",
                            style: const TextStyle(color: Colors.white54),
                          );
                        }

                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: categoriasConStock.map((categoria) {
                            final activa = categoriaSeleccionada == categoria;
                            final total = totalPorCategoria[categoria] ?? 0;
                            final registros =
                                registrosPorCategoria[categoria] ?? 0;

                            return InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                setDialogState(() {
                                  categoriaSeleccionada = categoria;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: activa
                                      ? neonPurple.withOpacity(0.18)
                                      : darkBg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: activa
                                        ? neonPurple
                                        : neonPurple.withOpacity(0.25),
                                    width: activa ? 1.4 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _iconForCategoria(categoria),
                                      color: activa
                                          ? neonPurple
                                          : Colors.white54,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          categoria,
                                          style: TextStyle(
                                            color: activa
                                                ? Colors.white
                                                : Colors.white70,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          "Disponible: $total "
                                          "($registros ${registros == 1 ? 'registro' : 'registros'})",
                                          style: const TextStyle(
                                            color: Colors.white38,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 14),
                  TextField(
                    controller: cantidadController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: _fieldDecoration(
                      "Cantidad a usar",
                      icon: Icons.tag,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Text(
                        "Si un solo registro no alcanza, se completará "
                        "usando otros registros del mismo color y categoría.",
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Divider(color: Colors.white.withOpacity(0.08)),
                ],
              ),
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
                final cantidadUsada =
                    int.tryParse(cantidadController.text) ?? 0;

                if (colorSeleccionado == null ||
                    categoriaSeleccionada == null ||
                    cantidadUsada <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Selecciona color, categoría y una cantidad válida",
                      ),
                    ),
                  );
                  return;
                }

                try {
                  // Buscamos todos los ingresos de ese color y categoría,
                  // ordenados del más antiguo al más reciente (FIFO), para
                  // poder ir tomando cantidad de varios registros si uno
                  // solo no alcanza.
                  final ingresosSnap = await FirebaseFirestore.instance
                      .collection('ingresos')
                      .where('categoria', isEqualTo: categoriaSeleccionada)
                      .where('color', isEqualTo: colorSeleccionado)
                      .get();

                  final docsOrdenados = ingresosSnap.docs.toList()
                    ..sort((a, b) {
                      final fechaA =
                          DateTime.tryParse(
                            (a.data()['fecha'] ?? '').toString(),
                          ) ??
                          DateTime(2000);
                      final fechaB =
                          DateTime.tryParse(
                            (b.data()['fecha'] ?? '').toString(),
                          ) ??
                          DateTime(2000);
                      return fechaA.compareTo(fechaB);
                    });

                  final totalDisponible = docsOrdenados.fold<int>(
                    0,
                    (sum, doc) => sum + ((doc.data()['cantidad'] ?? 0) as int),
                  );

                  if (totalDisponible < cantidadUsada) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "No hay suficiente cantidad disponible. "
                          "Disponible: $totalDisponible, solicitado: $cantidadUsada",
                        ),
                      ),
                    );
                    return;
                  }

                  final materialRef = FirebaseFirestore.instance
                      .collection('materiales')
                      .doc();

                  await FirebaseFirestore.instance.runTransaction((
                    transaction,
                  ) async {
                    int restante = cantidadUsada;
                    final consumoDetalle = <Map<String, dynamic>>[];

                    // Primero leemos (dentro de la transacción) todos los
                    // documentos que vamos a necesitar, antes de escribir.
                    final snapsFrescos = <DocumentSnapshot>[];
                    for (final doc in docsOrdenados) {
                      if (restante <= 0) break;
                      final snapFresco = await transaction.get(doc.reference);
                      snapsFrescos.add(snapFresco);
                    }

                    for (final snapFresco in snapsFrescos) {
                      if (restante <= 0) break;
                      if (!snapFresco.exists) continue;

                      final data = snapFresco.data() as Map<String, dynamic>;
                      final disponible = (data['cantidad'] ?? 0) as int;
                      if (disponible <= 0) continue;

                      final tomar = restante < disponible
                          ? restante
                          : disponible;

                      transaction.update(snapFresco.reference, {
                        "cantidad": disponible - tomar,
                      });

                      consumoDetalle.add({
                        "ingresoId": snapFresco.reference.id,
                        "cantidadTomada": tomar,
                      });

                      restante -= tomar;
                    }

                    if (restante > 0) {
                      // Alguien más consumió stock justo antes que nosotros:
                      // abortamos para no dejar datos inconsistentes.
                      throw Exception(
                        "El stock disponible cambió y ya no alcanza. "
                        "Intenta de nuevo.",
                      );
                    }

                    transaction.set(materialRef, {
                      "nombre": nombreController.text,
                      "grosor": grosorSeleccionado ?? "",
                      "color": colorSeleccionado,
                      "categoria": categoriaSeleccionada,
                      "flexibilidad": flexibilidadSeleccionada ?? "",
                      "resistencia": resistenciaSeleccionada ?? "",
                      "familia": familiaController.text,
                      "cantidadUsada": cantidadUsada,
                      "ingresosUtilizados": consumoDetalle,
                      "createdAt": Timestamp.now(),
                    });
                  });

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Material creado y ingresos actualizados"),
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error al crear el material: $e")),
                  );
                }
              },
              label: const Text("Crear"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editarMaterial(
    BuildContext context,
    String id,
    Map<String, dynamic> data,
  ) async {
    final nombreController = TextEditingController(text: data["nombre"]);

    String? colorSeleccionado = _valorSiValido(
      data["color"]?.toString(),
      _coloresDisponibles,
    );
    String? grosorSeleccionado = _valorSiValido(
      data["grosor"]?.toString(),
      _gruesosDisponibles,
    );
    String? flexibilidadSeleccionada = _valorSiValido(
      data["flexibilidad"]?.toString(),
      _flexibilidadesDisponibles,
    );
    String? resistenciaSeleccionada = _valorSiValido(
      data["resistencia"]?.toString(),
      _resistenciasDisponibles,
    );
    String? composicionSeleccionada = _valorSiValido(
      data["familia"]?.toString(),
      _composicionesQuimicas,
    );

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
            "Editar Material",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
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
                DropdownButtonFormField<String>(
                  value: grosorSeleccionado,
                  decoration: _fieldDecoration(
                    "Grosor",
                    icon: Icons.layers_outlined,
                  ),
                  dropdownColor: cardBg,
                  style: const TextStyle(color: Colors.white),
                  items: _gruesosDisponibles
                      .map(
                        (g) => DropdownMenuItem(
                          value: g,
                          child: Text(
                            g,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (valor) {
                    setDialogState(() {
                      grosorSeleccionado = valor;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: colorSeleccionado,
                  decoration: _fieldDecoration(
                    "Color",
                    icon: Icons.palette_outlined,
                  ),
                  dropdownColor: cardBg,
                  style: const TextStyle(color: Colors.white),
                  items: _coloresDisponibles
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(
                            c,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (valor) {
                    setDialogState(() {
                      colorSeleccionado = valor;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: flexibilidadSeleccionada,
                  decoration: _fieldDecoration(
                    "Flexibilidad",
                    icon: Icons.waves_outlined,
                  ),
                  dropdownColor: cardBg,
                  style: const TextStyle(color: Colors.white),
                  items: _flexibilidadesDisponibles
                      .map(
                        (f) => DropdownMenuItem(
                          value: f,
                          child: Text(
                            f,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (valor) {
                    setDialogState(() {
                      flexibilidadSeleccionada = valor;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: resistenciaSeleccionada,
                  decoration: _fieldDecoration(
                    "Resistencia",
                    icon: Icons.shield_outlined,
                  ),
                  dropdownColor: cardBg,
                  style: const TextStyle(color: Colors.white),
                  items: _resistenciasDisponibles
                      .map(
                        (r) => DropdownMenuItem(
                          value: r,
                          child: Text(
                            r,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (valor) {
                    setDialogState(() {
                      resistenciaSeleccionada = valor;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: composicionSeleccionada,
                  decoration: _fieldDecoration(
                    "Familia (Composición Química)",
                    icon: Icons.science_outlined,
                  ),
                  dropdownColor: cardBg,
                  style: const TextStyle(color: Colors.white),
                  items: _composicionesQuimicas
                      .map(
                        (comp) => DropdownMenuItem(
                          value: comp,
                          child: Text(
                            comp,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (valor) {
                    setDialogState(() {
                      composicionSeleccionada = valor;
                    });
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
                      "grosor": grosorSeleccionado ?? "",
                      "color": colorSeleccionado ?? "",
                      "flexibilidad": flexibilidadSeleccionada ?? "",
                      "resistencia": resistenciaSeleccionada ?? "",
                      "familia": composicionSeleccionada ?? "",
                    });
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
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 16 : 32),
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
              false,
              () => Navigator.pushReplacementNamed(context, '/ingreso'),
            ),
          if (Permisos.puedeVer(userRole, 'materiales'))
            _sidebarItem(
              Icons.recycling_rounded,
              "Materiales",
              true,
              null,
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
    final searchField = TextField(
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
    );

    final newButton = ElevatedButton.icon(
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
    );

    const titleColumn = Column(
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
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isNarrow = constraints.maxWidth < 700;

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleColumn,
              const SizedBox(height: 16),
              searchField,
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: newButton),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: titleColumn),
            SizedBox(width: 260, child: searchField),
            const SizedBox(width: 16),
            newButton,
          ],
        );
      },
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
