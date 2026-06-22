import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class TareasScreen extends StatefulWidget {
  const TareasScreen({super.key});

  @override
  State<TareasScreen> createState() => _TareasScreenState();
}

class _TareasScreenState extends State<TareasScreen> {
  String? userRole;
  final AuthService _authService = AuthService();

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

  Future<void> _crearTarea(BuildContext context) async {
    final nombreController = TextEditingController();
    final procedimientoController = TextEditingController();
    final cantidadController = TextEditingController();
    final tiempoController = TextEditingController();
    final observacionesController = TextEditingController();
    final importanciaController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Nueva Tarea", style: TextStyle(color: Colors.cyanAccent)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nombreController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Nombre", labelStyle: TextStyle(color: Colors.cyanAccent))),
              TextField(controller: procedimientoController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Procedimiento", labelStyle: TextStyle(color: Colors.cyanAccent))),
              TextField(controller: cantidadController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Cantidad", labelStyle: TextStyle(color: Colors.cyanAccent))),
              TextField(controller: tiempoController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Tiempo", labelStyle: TextStyle(color: Colors.cyanAccent))),
              TextField(controller: observacionesController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Observaciones", labelStyle: TextStyle(color: Colors.cyanAccent))),
              TextField(controller: importanciaController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Importancia", labelStyle: TextStyle(color: Colors.cyanAccent))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: Colors.redAccent))),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection("tareas").add({
                "nombre": nombreController.text,
                "procedimiento": procedimientoController.text,
                "cantidad": cantidadController.text,
                "tiempo": tiempoController.text,
                "observaciones": observacionesController.text,
                "importancia": importanciaController.text,
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

  Future<void> _editarTarea(BuildContext context, String id, Map<String, dynamic> data) async {
    final nombreController = TextEditingController(text: data["nombre"]);
    final procedimientoController = TextEditingController(text: data["procedimiento"]);
    final cantidadController = TextEditingController(text: data["cantidad"]);
    final tiempoController = TextEditingController(text: data["tiempo"]);
    final observacionesController = TextEditingController(text: data["observaciones"]);
    final importanciaController = TextEditingController(text: data["importancia"]);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Editar Tarea", style: TextStyle(color: Colors.cyanAccent)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nombreController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Nombre", labelStyle: TextStyle(color: Colors.cyanAccent))),
              TextField(controller: procedimientoController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Procedimiento", labelStyle: TextStyle(color: Colors.cyanAccent))),
              TextField(controller: cantidadController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Cantidad", labelStyle: TextStyle(color: Colors.cyanAccent))),
              TextField(controller: tiempoController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Tiempo", labelStyle: TextStyle(color: Colors.cyanAccent))),
              TextField(controller: observacionesController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Observaciones", labelStyle: TextStyle(color: Colors.cyanAccent))),
              TextField(controller: importanciaController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Importancia", labelStyle: TextStyle(color: Colors.cyanAccent))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: Colors.redAccent))),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection("tareas").doc(id).update({
                "nombre": nombreController.text,
                "procedimiento": procedimientoController.text,
                "cantidad": cantidadController.text,
                "tiempo": tiempoController.text,
                "observaciones": observacionesController.text,
                "importancia": importanciaController.text,
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
        title: const Text("Eliminar Tarea", style: TextStyle(color: Colors.cyanAccent)),
        content: const Text("¿Seguro de eliminar esta tarea?", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: Colors.redAccent))),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection("tareas").doc(id).delete();
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
        title: const Text("Tareas", style: TextStyle(color: Colors.cyanAccent)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.cyanAccent),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/pantallabienvenida');
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("tareas").snapshots(),
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
                    "Procedimiento: ${data["procedimiento"] ?? "-"} | Cantidad: ${data["cantidad"] ?? "-"}\n"
                    "Tiempo: ${data["tiempo"] ?? "-"} | Observaciones: ${data["observaciones"] ?? "-"}\n"
                    "Importancia: ${data["importancia"] ?? "-"}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: userRole == "jefe"
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.cyanAccent),
                              onPressed: () => _editarTarea(context, id, data),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () => _confirmarEliminar(context, id),
                            ),
                          ],
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: userRole == "jefe"
          ? FloatingActionButton(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black,
              child: const Icon(Icons.add),
              onPressed: () => _crearTarea(context),
            )
          : null,
    );
  }
}

