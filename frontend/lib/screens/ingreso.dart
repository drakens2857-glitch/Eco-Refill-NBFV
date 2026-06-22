import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class IngresoScreen extends StatefulWidget {
  const IngresoScreen({super.key});

  @override
  State<IngresoScreen> createState() => _IngresoScreenState();
}

class _IngresoScreenState extends State<IngresoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  String? userRole;

  final ingresos = {
    "Botellas": [
      {"color": "Verde", "cantidad": 20, "fecha": "2026-06-21 15:30"},
      {"color": "Transparente", "cantidad": 15, "fecha": "2026-06-21 14:10"},
    ],
    "Botellones": [
      {"color": "Azul", "cantidad": 5, "fecha": "2026-06-21 13:00"},
    ],
    "Canecas": [
      {"color": "Negro", "cantidad": 2, "fecha": "2026-06-21 12:45"},
    ],
    "Canastas": [
      {"color": "Rojo", "cantidad": 8, "fecha": "2026-06-21 11:20"},
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildIngresoList(String categoria) {
    final lista = ingresos[categoria] ?? [];
    if (lista.isEmpty) {
      return const Center(
        child: Text("No hay ingresos registrados",
            style: TextStyle(color: Colors.white)),
      );
    }
    return ListView.builder(
      itemCount: lista.length,
      itemBuilder: (context, index) {
        final item = lista[index];
        return Card(
          color: Colors.black.withOpacity(0.8),
          margin: const EdgeInsets.all(12),
          child: ListTile(
            leading: const Icon(Icons.recycling, color: Colors.cyanAccent),
            title: Text(
              "Color: ${item["color"]}, Cantidad: ${item["cantidad"]}",
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              "Fecha: ${item["fecha"]}",
              style: const TextStyle(color: Colors.cyanAccent),
            ),
          ),
        );
      },
    );
  }

  void _mostrarFormularioIngreso(String categoria) {
    final colorController = TextEditingController();
    final cantidadController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text("Nuevo ingreso en $categoria",
            style: const TextStyle(color: Colors.cyanAccent)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: colorController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Color",
                labelStyle: TextStyle(color: Colors.cyanAccent),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: cantidadController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Cantidad",
                labelStyle: TextStyle(color: Colors.cyanAccent),
              ),
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
                ingresos[categoria]!.add({
                  "color": colorController.text,
                  "cantidad": int.tryParse(cantidadController.text) ?? 0,
                  "fecha": DateTime.now().toString(),
                });
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Ingreso agregado en $categoria")),
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
        title: const Text("Ingreso de Plásticos",
            style: TextStyle(color: Colors.cyanAccent)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.cyanAccent),
          onPressed: () {
            // 🔹 Siempre vuelve a la pantalla de bienvenida
            Navigator.pushReplacementNamed(context, '/pantallabienvenida');
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.cyanAccent,
          tabs: const [
            Tab(text: "Botellas"),
            Tab(text: "Botellones"),
            Tab(text: "Canecas"),
            Tab(text: "Canastas"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildIngresoList("Botellas"),
          _buildIngresoList("Botellones"),
          _buildIngresoList("Canecas"),
          _buildIngresoList("Canastas"),
        ],
      ),
      floatingActionButton: (userRole == "ingreso" || userRole == "jefe")
          ? FloatingActionButton(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black,
              onPressed: () {
                final categoria =
                    _tabController.index == 0 ? "Botellas" :
                    _tabController.index == 1 ? "Botellones" :
                    _tabController.index == 2 ? "Canecas" : "Canastas";
                _mostrarFormularioIngreso(categoria);
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
