import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

import '../config/cloudinary_config.dart';
import 'login.dart';
import '../services/auth_service.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final AuthService _authService = AuthService();
  String? userRole;

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

  Future<void> _uploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final url = Uri.parse(
          "https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload");

      var request = http.MultipartRequest("POST", url)
        ..fields['upload_preset'] = CloudinaryConfig.uploadPreset;

      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: pickedFile.name,
        ));
      } else {
        final file = File(pickedFile.path);
        request.files.add(await http.MultipartFile.fromPath('file', file.path));
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        final res = await http.Response.fromStream(response);

        final imageUrl = (res.body.contains("secure_url"))
            ? RegExp(r'"secure_url":"([^"]+)"')
                .firstMatch(res.body)!
                .group(1)
                ?.replaceAll(r'\/', '/')
            : null;

        if (imageUrl != null) {
          await FirebaseFirestore.instance
              .collection("users")
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .update({"photoUrl": imageUrl});

          setState(() {}); // refrescar pantalla
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      Future.microtask(() {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Perfil de Usuario",
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
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection("users")
            .doc(currentUser.uid)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.data() as Map<String, dynamic>;

          return Column(
            children: [
              const SizedBox(height: 30),
              CircleAvatar(
                radius: 60,
                backgroundImage: (data["photoUrl"] != null &&
                        data["photoUrl"].isNotEmpty)
                    ? NetworkImage(data["photoUrl"])
                    : const AssetImage("assets/images/default_avatar.png")
                        as ImageProvider,
                child: (data["photoUrl"] == null || data["photoUrl"].isEmpty)
                    ? const Icon(Icons.person, size: 60, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: _uploadImage,
                icon: const Icon(Icons.camera_alt, color: Colors.black),
                label: const Text("Cambiar Foto"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Hola, ${data["name"] ?? "Usuario"}",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent,
                ),
              ),
              const SizedBox(height: 10),
              Text("Correo: ${data["email"]}",
                  style: const TextStyle(color: Colors.white70)),
              Text("Teléfono: ${data["phone"]}",
                  style: const TextStyle(color: Colors.white70)),
              Text("Cargo: ${data["cargo"]}",
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 30),

              Expanded(
                child: Center(
                  child: Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: _buildRoleButtons(context),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _authService.logout();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                      (Route<dynamic> route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout, color: Colors.black),
                  label: const Text("Cerrar Sesión"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildRoleButtons(BuildContext context) {
    switch (userRole) {
      case "jefe":
        return [
          _bigButton(Icons.task, "Tareas", () => Navigator.pushNamed(context, '/tareas')),
          _bigButton(Icons.people, "Usuarios", () => Navigator.pushNamed(context, '/usuarios')),
          _bigButton(Icons.recycling, "Inventario", () => Navigator.pushNamed(context, '/materiales')),
          _bigButton(Icons.add_box, "Ingreso Plásticos", () => Navigator.pushNamed(context, '/ingreso')),
          _bigButton(Icons.settings, "Procesos", () => Navigator.pushNamed(context, '/procesos')),
        ];
      case "inventario":
        return [
          _bigButton(Icons.recycling, "Inventario", () => Navigator.pushNamed(context, '/materiales')),
          _bigButton(Icons.task, "Tareas", () => Navigator.pushNamed(context, '/tareas')),
        ];
      case "ingreso":
        return [
          _bigButton(Icons.task, "Tareas", () => Navigator.pushNamed(context, '/tareas')),
          _bigButton(Icons.add_box, "Ingreso Plásticos", () => Navigator.pushNamed(context, '/ingreso')),
        ];
      case "proceso":
        return [
          _bigButton(Icons.task, "Tareas", () => Navigator.pushNamed(context, '/tareas')),
          _bigButton(Icons.settings, "Procesos", () => Navigator.pushNamed(context, '/procesos')),
        ];
      default:
        return [];
    }
  }

  Widget _bigButton(IconData icon, String text, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.black),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.cyanAccent,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
