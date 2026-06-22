import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final api = ApiService();
  final AuthService _authService = AuthService();

  List posts = [];
  bool loading = true;

  final _descController = TextEditingController();
  final _imgController = TextEditingController();

  String? userRole;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _loadUserRole();
  }

  Future<void> _loadPosts() async {
    final data = await api.getPosts();
    setState(() {
      posts = data;
      loading = false;
    });
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

  Future<void> _createPost() async {
    await api.createPost(
      "Frankyn",
      _descController.text,
      _imgController.text,
    );
    _descController.clear();
    _imgController.clear();
    _loadPosts();
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
            // 🔹 Siempre vuelve a la pantalla de bienvenida
            Navigator.pushReplacementNamed(context, '/pantallabienvenida');
          },
        ),
      ),

      body: Column(
        children: [
          // 🔹 Solo el jefe ve el formulario
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
                  TextField(
                    controller: _imgController,
                    decoration: const InputDecoration(
                      labelText: "URL de imagen",
                      border: OutlineInputBorder(),
                    ),
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

          // 🔹 Feed estilo Facebook (visible para todos)
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      return Card(
                        color: Colors.black.withOpacity(0.8),
                        margin: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (post["imageUrl"] != null &&
                                post["imageUrl"].isNotEmpty)
                              Image.network(post["imageUrl"], fit: BoxFit.cover),
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
