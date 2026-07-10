import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MaterialesScreen extends StatefulWidget {
  const MaterialesScreen({super.key});

  @override
  State<MaterialesScreen> createState() => _MaterialesScreenState();
}

class _MaterialesScreenState extends State<MaterialesScreen> {
  DocumentSnapshot? ingresoSeleccionado;
  int cantidadUsada = 0;

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
        backgroundColor: Colors.black.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Nuevo Material", style: TextStyle(color: Colors.cyanAccent)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔹 Campos del material
              TextField(controller: nombreController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Nombre", labelStyle: TextStyle(color: Colors.cyanAccent))),
              TextField(controller: grosorController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Grosor", labelStyle: TextStyle(color: Colors.cyanAccent))),
              TextField(controller: colorController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Color", labelStyle: TextStyle(color: Colors.cyanAccent))),
              TextField(controller: flexibilidadController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Flexibilidad", labelStyle: TextStyle(color: Colors.cyanAccent))),
              TextField(controller: resistenciaController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Resistencia", labelStyle: TextStyle(color: Colors.cyanAccent))),
              TextField(controller: familiaController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Familia (Composición Química)", labelStyle: TextStyle(color: Colors.cyanAccent))),

              const SizedBox(height: 12),

              // 🔹 Dropdown de ingresos
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('ingresos').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Text(
                      "No hay ingresos disponibles",
                      style: TextStyle(color: Colors.white),
                    );
                  }

                  return DropdownButton<DocumentSnapshot>(
                    value: ingresoSeleccionado,
                    hint: const Text(
                      "Selecciona ingreso",
                      style: TextStyle(color: Colors.cyanAccent),
                    ),
                    dropdownColor: Colors.black,   // 🔹 Fondo oscuro
                    isExpanded: true,              // 🔹 Ocupa todo el ancho
                    items: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: doc,
                        child: Text(
                          "${data['categoria']} - ${data['color']} (Disponible: ${data['cantidad']})",
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (nuevo) {
                      setState(() {
                        ingresoSeleccionado = nuevo;
                      });
                    },
                  );
                },
              ),

              const SizedBox(height: 12),

              // 🔹 Cantidad usada
              TextField(
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Cantidad a usar",
                  labelStyle: TextStyle(color: Colors.cyanAccent),
                ),
                onChanged: (val) {
                  cantidadUsada = int.tryParse(val) ?? 0;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: Colors.redAccent))),
          ElevatedButton(
            onPressed: () async {
              if (ingresoSeleccionado != null && cantidadUsada > 0) {
                final data = ingresoSeleccionado!.data() as Map<String, dynamic>;
                final disponible = data['cantidad'] as int;

                if (cantidadUsada <= disponible) {
                  // Guardar material
                  await FirebaseFirestore.instance.collection("materiales").add({
                    "nombre": nombreController.text,
                    "grosor": grosorController.text,
                    "color": colorController.text,
                    "flexibilidad": flexibilidadController.text,
                    "resistencia": resistenciaController.text,
                    "familia": familiaController.text,
                    "ingresoId": ingresoSeleccionado!.id,
                    "cantidadUsada": cantidadUsada,
                    "createdAt": Timestamp.now(),
                  });

                  // Actualizar ingreso
                  await FirebaseFirestore.instance
                      .collection("ingresos")
                      .doc(ingresoSeleccionado!.id)
                      .update({"cantidad": disponible - cantidadUsada});

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Material creado y ingreso actualizado")),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Cantidad usada mayor a disponible")),
                  );
                }
              }
            },
            child: const Text("Crear"),
          ),
        ],
      ),
    );
  }

  Future<void> _editarMaterial(BuildContext context, String id, Map<String, dynamic> data) async {
    // 🔹 Mantengo tu lógica de edición igual
    final nombreController = TextEditingController(text: data["nombre"]);
    final grosorController = TextEditingController(text: data["grosor"]);
    final colorController = TextEditingController(text: data["color"]);
    final flexibilidadController = TextEditingController(text: data["flexibilidad"]);
    final resistenciaController = TextEditingController(text: data["resistencia"]);
    final familiaController = TextEditingController(text: data["familia"]);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Editar Material", style: TextStyle(color: Colors.cyanAccent)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nombreController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Nombre", labelStyle: TextStyle(color: Colors.cyanAccent))),
              TextField(controller: grosorController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Grosor", labelStyle: TextStyle(color: Colors.cyanAccent))),
              TextField(controller: colorController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Color", labelStyle: TextStyle(color: Colors.cyanAccent))),
              TextField(controller: flexibilidadController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Flexibilidad", labelStyle: TextStyle(color: Colors.cyanAccent))),
              TextField(controller: resistenciaController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Resistencia", labelStyle: TextStyle(color: Colors.cyanAccent))),
              TextField(controller: familiaController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Familia (Composición Química)", labelStyle: TextStyle(color: Colors.cyanAccent))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: Colors.redAccent))),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection("materiales").doc(id).update({
                "nombre": nombreController.text,
                "grosor": grosorController.text,
                "color": colorController.text,
                "flexibilidad": flexibilidadController.text,
                "resistencia": resistenciaController.text,
                "familia": familiaController.text,
              });
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
        backgroundColor: Colors.black.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Eliminar Material", style: TextStyle(color: Colors.cyanAccent)),
        content: const Text("¿Seguro de eliminar este material?", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: Colors.redAccent))),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection("materiales").doc(id).delete();
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
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Materiales", style: TextStyle(color: Colors.cyanAccent)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.cyanAccent),
          onPressed: () {
            // 🔹 Siempre vuelve a la pantalla de bienvenida
            Navigator.pushReplacementNamed(context, '/pantallabienvenida');
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("materiales").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final id = docs[index].id;

              return Card(
                color: Colors.black.withOpacity(0.8),
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text(data["nombre"], style: const TextStyle(color: Colors.cyanAccent)),
                  subtitle: Text(
                    "Grosor: ${data["grosor"] ?? "-"} | Color: ${data["color"] ?? "-"}\n"
                    "Flexibilidad: ${data["flexibilidad"] ?? "-"} | Resistencia: ${data["resistencia"] ?? "-"}\n"
                    "Familia: ${data["familia"] ?? "-"} | Cantidad usada: ${data["cantidadUsada"] ?? "-"}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.cyanAccent), onPressed: () => _editarMaterial(context, id, data)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _confirmarEliminar(context, id)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.cyanAccent,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
        onPressed: () => _crearMaterial(context),
      ),
    );
  }
}

