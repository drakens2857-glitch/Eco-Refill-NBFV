import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert'; // 🔹 para decodificar JSON y hex
import '../services/auth_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();

  List posts = [];
  bool loading = true;

  final _descController = TextEditingController();
  Uint8List? _selectedImage;

  String? userRole;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _loadUserRole();
  }

  Future<void> _loadPosts() async {
    final response = await http.get(Uri.parse("http://localhost:8000/api/posts/"));
    if (response.statusCode == 200) {
      setState(() {
        posts = jsonDecode(response.body); // 🔹 ahora sí parseamos JSON
        loading = false;
      });
    } else {
      print("Error al cargar posts: ${response.statusCode}");
    }
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _selectedImage = bytes;
      });
    }
  }

  Future<void> _createPost() async {
    if (_selectedImage == null || _descController.text.isEmpty) return;

    final request = http.MultipartRequest(
      'POST',
      Uri.parse("http://localhost:8000/api/posts/create_post"), // 🔹 corregido
    );
    request.fields['description'] = _descController.text;
    request.fields['author'] =
        FirebaseAuth.instance.currentUser?.email ?? "Desconocido";
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      _selectedImage!,
      filename: "post.png",
    ));

    final response = await request.send();
    if (response.statusCode == 200) {
      _descController.clear();
      setState(() {
        _selectedImage = null;
      });
      _loadPosts();
    } else {
      print("Error al crear post: ${response.statusCode}");
    }
  }

  // 🔹 Función para decodificar hex a bytes
  Uint8List? _decodeHex(String? hexString) {
    if (hexString == null || hexString.isEmpty) return null;
    final result = <int>[];
    for (var i = 0; i < hexString.length; i += 2) {
      result.add(int.parse(hexString.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(result);
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
            Navigator.pushReplacementNamed(context, '/pantallabienvenida');
          },
        ),
      ),
      body: Column(
        children: [
          if (userRole == "jefe")
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      labelText: "Descripción",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image, color: Colors.black),
                        label: const Text("Seleccionar imagen"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (_selectedImage != null)
                        const Icon(Icons.check_circle, color: Colors.green),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _createPost,
                    icon: const Icon(Icons.send, color: Colors.black),
                    label: const Text("Guardar publicación"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(color: Colors.cyanAccent),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      final imageBytes = _decodeHex(post["imageBytes"]);

                      return Card(
                        color: Colors.black.withOpacity(0.8),
                        margin: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (imageBytes != null)
                              Image.memory(imageBytes, fit: BoxFit.cover),
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
          ),
        ],
      ),
    );
  }
}
