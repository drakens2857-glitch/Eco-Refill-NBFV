import 'package:flutter/material.dart';
import 'dart:typed_data'; // 🔹 para manejar bytes
import 'package:convert/convert.dart'; // 🔹 para convertir hex a bytes
import '../services/api_service.dart';

class FeedPublicoScreen extends StatefulWidget {
  final bool desdeLogin;

  const FeedPublicoScreen({super.key, required this.desdeLogin});

  @override
  State<FeedPublicoScreen> createState() => _FeedPublicoScreenState();
}

class _FeedPublicoScreenState extends State<FeedPublicoScreen> {
  final api = ApiService();
  List posts = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    final data = await api.getPosts();
    setState(() {
      posts = data;
      loading = false;
    });
  }

  // 🔹 Función para convertir hex a bytes
  Uint8List? _decodeImage(String? hexString) {
    if (hexString == null || hexString.isEmpty) return null;
    try {
      return Uint8List.fromList(hex.decode(hexString));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Publicaciones",
          style: TextStyle(color: Colors.cyanAccent),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.cyanAccent),
          onPressed: () {
            if (widget.desdeLogin) {
              Navigator.pushReplacementNamed(context, '/pantallabienvenida');
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                final imageBytes = _decodeImage(post["imageBytes"]);

                return Card(
                  color: Colors.black.withOpacity(0.8),
                  margin: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔹 Mostrar imagen guardada en Firestore como hex
                      if (imageBytes != null)
                        Image.memory(
                          imageBytes,
                          fit: BoxFit.cover,
                        ),

                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          post["description"] ?? "",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Autor: ${post["author"] ?? "Desconocido"}",
                          style: const TextStyle(color: Colors.cyanAccent),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
