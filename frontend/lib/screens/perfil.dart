import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

import '../config/cloudinary_config.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final user = FirebaseAuth.instance.currentUser;

  Future<void> _uploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final url = Uri.parse(
          "https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload");

      var request = http.MultipartRequest("POST", url)
        ..fields['upload_preset'] = CloudinaryConfig.uploadPreset;

      if (kIsWeb) {
        // 🌐 Flutter Web → usar bytes
        final bytes = await pickedFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: pickedFile.name,
        ));
      } else {
        // 📱 Android/iOS/Desktop → usar File
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
              .doc(user!.uid)
              .update({"photoUrl": imageUrl});

          setState(() {}); // refrescar pantalla
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Perfil de Usuario",
            style: TextStyle(color: Colors.cyanAccent)),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection("users").doc(user!.uid).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!.data() as Map<String, dynamic>;

          return Center(
            child: Card(
              color: Colors.black.withOpacity(0.8),
              margin: const EdgeInsets.all(24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 12,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                        radius: 50,
                        backgroundImage: (data["photoUrl"] != null && data["photoUrl"].isNotEmpty)
                            ? NetworkImage(data["photoUrl"])
                            : const AssetImage("assets/images/default_avatar.png") as ImageProvider,
                        child: (data["photoUrl"] == null || data["photoUrl"].isEmpty)
                            ? const Icon(Icons.person, size: 50, color: Colors.white)
                            : null,
                      ),


                    const SizedBox(height: 20),

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
                      data["name"] ?? "Sin nombre",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.cyanAccent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text("Correo: ${data["email"]}", style: const TextStyle(color: Colors.white70)),
                    Text("Teléfono: ${data["phone"]}", style: const TextStyle(color: Colors.white70)),

                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      icon: const Icon(Icons.logout, color: Colors.black),
                      label: const Text("Cerrar Sesión"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
