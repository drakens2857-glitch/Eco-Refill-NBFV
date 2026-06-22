import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MaterialesScreen extends StatelessWidget {
  const MaterialesScreen({super.key});

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
              await FirebaseFirestore.instance.collection("materiales").add({
                "nombre": nombreController.text,
                "grosor": grosorController.text,
                "color": colorController.text,
                "flexibilidad": flexibilidadController.text,
                "resistencia": resistenciaController.text,
                "familia": familiaController.text,
                "createdAt": Timestamp.now(),
              });
              Navigator.pop(context);
            },
            child: const Text("Crear"),
          ),
        ],
      ),
    );
  }

  Future<void> _editarMaterial(BuildContext context, String id, Map<String, dynamic> data) async {
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
                    "Familia: ${data["familia"] ?? "-"}",
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
