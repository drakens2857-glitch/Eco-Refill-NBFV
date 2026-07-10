import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class ProcesosScreen extends StatefulWidget {
  const ProcesosScreen({super.key});

  @override
  State<ProcesosScreen> createState() => _ProcesosScreenState();
}

class _ProcesosScreenState extends State<ProcesosScreen> {
  final AuthService _authService = AuthService();
  String? userRole;

  final fases = [
    "Limpieza",
    "Preparación",
    "Corte en tiras",
    "Termoformado",
    "Moldeado",
    "Enfriamiento",
    "Enrollado",
    "Almacenamiento",
    "Proceso finalizado",
  ];

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

  void _mostrarFormularioProceso() {
    final descController = TextEditingController();
    String faseSeleccionada = "Limpieza";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text("Nuevo Proceso",
            style: TextStyle(color: Colors.cyanAccent)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Descripción",
                labelStyle: TextStyle(color: Colors.cyanAccent),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButton<String>(
              dropdownColor: Colors.black,
              value: faseSeleccionada,
              items: fases.map((e) => DropdownMenuItem(
                value: e,
                child: Text(e, style: const TextStyle(color: Colors.white)),
              )).toList(),
              onChanged: (nuevo) {
                faseSeleccionada = nuevo!;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar",
                style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection("procesos").add({
                "usuario": "Usuario actual",
                "descripcion": descController.text,
                "fecha": DateTime.now().toString(),
                "fase": faseSeleccionada,
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Proceso creado correctamente")),
              );
            },
            child: const Text("Guardar"),
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
        title: const Text("Procesos",
            style: TextStyle(color: Colors.cyanAccent)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.cyanAccent),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/pantallabienvenida');
          },
        ),
      ),
      body: Column(
        children: [
          if (userRole == "proceso" || userRole == "jefe")
            Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton.icon(
                onPressed: _mostrarFormularioProceso,
                icon: const Icon(Icons.add, color: Colors.black),
                label: const Text("Crear Proceso"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                ),
              ),
            ),

          // 🔹 Procesos activos
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection("procesos").snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final id = docs[index].id;

                    return Card(
                      color: Colors.black.withOpacity(0.8),
                      margin: const EdgeInsets.all(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Usuario: ${data["usuario"]}",
                                style: const TextStyle(
                                    color: Colors.cyanAccent,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text("Descripción: ${data["descripcion"]}",
                                style: const TextStyle(color: Colors.white)),
                            const SizedBox(height: 6),
                            Text("Fecha: ${data["fecha"]}",
                                style: const TextStyle(color: Colors.white70)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Text("Fase: ",
                                    style: TextStyle(color: Colors.cyanAccent)),
                                DropdownButton<String>(
                                  dropdownColor: Colors.black,
                                  value: data["fase"],
                                  items: fases.map((fase) {
                                    return DropdownMenuItem(
                                      value: fase,
                                      child: Text(fase,
                                          style: const TextStyle(color: Colors.white)),
                                    );
                                  }).toList(),
                                  onChanged: (nuevoFase) async {
                                    if (nuevoFase == "Proceso finalizado") {
                                      // 🔹 Mover a historial
                                      await FirebaseFirestore.instance.collection("historial").add(data);
                                      await FirebaseFirestore.instance.collection("procesos").doc(id).delete();
                                    } else {
                                      await FirebaseFirestore.instance.collection("procesos").doc(id).update({
                                        "fase": nuevoFase,
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 🔹 Historial
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection("historial").snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final docs = snapshot.data!.docs;

                if (docs.isEmpty) return const SizedBox();

                return Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text("Historial",
                          style: TextStyle(color: Colors.cyanAccent, fontSize: 18)),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          return Card(
                            color: Colors.black.withOpacity(0.8),
                            margin: const EdgeInsets.all(12),
                            child: ListTile(
                              title: Text(data["descripcion"],
                                  style: const TextStyle(color: Colors.cyanAccent)),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_red_eye,
                                    color: Colors.cyanAccent),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: Colors.black,
                                      title: const Text("Detalle del Proceso",
                                          style: TextStyle(color: Colors.cyanAccent)),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("Descripción: ${data["descripcion"]}",
                                              style: const TextStyle(color: Colors.white)),
                                          Text("Fecha: ${data["fecha"]}",
                                              style: const TextStyle(color: Colors.white70)),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text("Cerrar",
                                              style: TextStyle(color: Colors.redAccent)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
