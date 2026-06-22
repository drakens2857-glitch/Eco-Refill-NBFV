import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class ProcesosScreen extends StatefulWidget {
  const ProcesosScreen({super.key});

  @override
  State<ProcesosScreen> createState() => _ProcesosScreenState();
}

class _ProcesosScreenState extends State<ProcesosScreen> {
  final AuthService _authService = AuthService();
  String? userRole;

  List<Map<String, dynamic>> procesos = [
    {
      "usuario": "Carlos",
      "descripcion": "Clasificación de botellas plásticas",
      "fecha": "2026-06-21 15:30",
      "estado": "En proceso"
    },
    {
      "usuario": "Ana",
      "descripcion": "Revisión de canecas recicladas",
      "fecha": "2026-06-21 14:10",
      "estado": "No completado"
    },
  ];

  final estados = ["Completado", "En proceso", "No completado"];

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
    String estadoSeleccionado = "En proceso";

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
              value: estadoSeleccionado,
              items: estados.map((e) => DropdownMenuItem(
                value: e,
                child: Text(e, style: const TextStyle(color: Colors.white)),
              )).toList(),
              onChanged: (nuevo) {
                estadoSeleccionado = nuevo!;
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
            onPressed: () {
              setState(() {
                procesos.add({
                  "usuario": "Usuario actual",
                  "descripcion": descController.text,
                  "fecha": DateTime.now().toString(),
                  "estado": estadoSeleccionado,
                });
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
            // 🔹 Siempre vuelve a la pantalla de bienvenida
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
          Expanded(
            child: ListView.builder(
              itemCount: procesos.length,
              itemBuilder: (context, index) {
                final proceso = procesos[index];
                return Card(
                  color: Colors.black.withOpacity(0.8),
                  margin: const EdgeInsets.all(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Usuario: ${proceso["usuario"]}",
                            style: const TextStyle(
                                color: Colors.cyanAccent,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text("Descripción: ${proceso["descripcion"]}",
                            style: const TextStyle(color: Colors.white)),
                        const SizedBox(height: 6),
                        Text("Fecha: ${proceso["fecha"]}",
                            style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text("Estado: ",
                                style: TextStyle(color: Colors.cyanAccent)),
                            DropdownButton<String>(
                              dropdownColor: Colors.black,
                              value: proceso["estado"],
                              items: estados.map((estado) {
                                return DropdownMenuItem(
                                  value: estado,
                                  child: Text(estado,
                                      style: const TextStyle(color: Colors.white)),
                                );
                              }).toList(),
                              onChanged: (nuevoEstado) {
                                setState(() {
                                  proceso["estado"] = nuevoEstado!;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
