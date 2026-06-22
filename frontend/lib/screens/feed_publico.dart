import 'package:flutter/material.dart';
import '../services/api_service.dart';

class FeedPublicoScreen extends StatefulWidget {
  const FeedPublicoScreen({super.key});

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
      body: loading
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
    );
  }
}
