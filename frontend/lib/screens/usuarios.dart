import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  String _searchText = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Usuarios Registrados",
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
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (value) => setState(() => _searchText = value.toLowerCase()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Buscar usuario por nombre, correo o teléfono...",
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.cyanAccent),
                filled: true,
                fillColor: Colors.black.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection("users").snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data["name"] ?? "").toString().toLowerCase();
                  final email = (data["email"] ?? "").toString().toLowerCase();
                  final phone = (data["phone"] ?? "").toString().toLowerCase();
                  return name.contains(_searchText) ||
                         email.contains(_searchText) ||
                         phone.contains(_searchText);
                }).toList();

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        "Total de usuarios: ${users.length}",
                        style: const TextStyle(color: Colors.cyanAccent),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final data = users[index].data() as Map<String, dynamic>;
                          return Card(
                            color: Colors.black.withOpacity(0.8),
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data["name"] ?? "",
                                      style: const TextStyle(
                                          color: Colors.cyanAccent,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  Text("Correo: ${data["email"]}",
                                      style: const TextStyle(color: Colors.white70)),
                                  Text("Teléfono: ${data["phone"]}",
                                      style: const TextStyle(color: Colors.white70)),
                                  Text("Cargo: ${data["cargo"]}",
                                      style: const TextStyle(color: Colors.white70)),
                                  Text("Estado: Activo",
                                      style: const TextStyle(color: Colors.greenAccent)),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          final nombreController = TextEditingController(text: data["name"]);
                                          final correoController = TextEditingController(text: data["email"]);
                                          final telefonoController = TextEditingController(text: data["phone"]);
                                          String cargoSeleccionado = data["cargo"] ?? "proceso";

                                          showDialog(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              backgroundColor: Colors.black,
                                              title: const Text("Editar Usuario",
                                                  style: TextStyle(color: Colors.cyanAccent)),
                                              content: SingleChildScrollView(
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    TextField(controller: nombreController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Nombre", labelStyle: TextStyle(color: Colors.cyanAccent))),
                                                    TextField(controller: correoController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Correo", labelStyle: TextStyle(color: Colors.cyanAccent))),
                                                    TextField(controller: telefonoController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Teléfono", labelStyle: TextStyle(color: Colors.cyanAccent))),
                                                    const SizedBox(height: 12),
                                                    DropdownButtonFormField<String>(
                                                      dropdownColor: Colors.black,
                                                      value: cargoSeleccionado,
                                                      items: ["jefe", "inventario", "ingreso", "proceso"]
                                                          .map((cargo) => DropdownMenuItem(
                                                                value: cargo,
                                                                child: Text(cargo, style: const TextStyle(color: Colors.white)),
                                                              ))
                                                          .toList(),
                                                      onChanged: (nuevoCargo) {
                                                        cargoSeleccionado = nuevoCargo!;
                                                      },
                                                      decoration: const InputDecoration(
                                                        labelText: "Cargo",
                                                        labelStyle: TextStyle(color: Colors.cyanAccent),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: Colors.redAccent))),
                                                ElevatedButton(
                                                  onPressed: () async {
                                                    await FirebaseFirestore.instance
                                                        .collection("users")
                                                        .doc(users[index].id)
                                                        .update({
                                                      "name": nombreController.text,
                                                      "email": correoController.text,
                                                      "phone": telefonoController.text,
                                                      "cargo": cargoSeleccionado,
                                                    });
                                                    Navigator.pop(context);
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text("Usuario actualizado")),
                                                    );
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.cyanAccent,
                                                    foregroundColor: Colors.black,
                                                  ),
                                                  child: const Text("Guardar"),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.cyanAccent,
                                          foregroundColor: Colors.black,
                                        ),
                                        child: const Text("Editar"),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () async {
                                          await FirebaseFirestore.instance
                                              .collection("users")
                                              .doc(users[index].id)
                                              .delete();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.redAccent,
                                          foregroundColor: Colors.black,
                                        ),
                                        child: const Text("Eliminar"),
                                      ),
                                    ],
                                  )
                                ],
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.cyanAccent,
        foregroundColor: Colors.black,
        onPressed: () {
          Navigator.pushNamed(context, '/register');
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.cyanAccent,
        unselectedItemColor: Colors.white70,
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/reportes');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Reportes"),
        ],
      ),
    );
  }
}
