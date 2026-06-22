import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  String? _selectedUserId;
  final _reporteController = TextEditingController();

  Future<void> _subirReporte() async {
    final texto = _reporteController.text.trim();
    if (_selectedUserId == null || texto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona un usuario y escribe un reporte")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection("reportes").add({
      "userId": _selectedUserId,
      "texto": texto,
      "createdAt": DateTime.now(),
    });

    _reporteController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Reporte subido correctamente")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Reportes", style: TextStyle(color: Colors.cyanAccent)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.cyanAccent),
          onPressed: () {
            // 🔹 Ahora sí vuelve a la pantalla principal
            Navigator.pushReplacementNamed(context, '/pantallabienvenida');
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔹 Dropdown con usuarios reales
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection("users").snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                final users = snapshot.data!.docs;
                return DropdownButtonFormField<String>(
                  value: _selectedUserId,
                  items: users.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(data["name"] ?? "Sin nombre"),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedUserId = value),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.people, color: Colors.cyanAccent),
                    labelText: "Selecciona usuario",
                    labelStyle: const TextStyle(color: Colors.cyanAccent),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.cyanAccent),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  dropdownColor: Colors.black,
                  style: const TextStyle(color: Colors.white),
                );
              },
            ),
            const SizedBox(height: 20),

            // 🔹 Cuadro de texto grande
            Expanded(
              child: TextField(
                controller: _reporteController,
                maxLines: null,
                expands: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Escribe tu reporte aquí...",
                  hintStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 🔹 Botón subir reporte
            ElevatedButton.icon(
              onPressed: _subirReporte,
              icon: const Icon(Icons.upload, color: Colors.black),
              label: const Text("Subir Reporte"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
