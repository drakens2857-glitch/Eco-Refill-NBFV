import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final filamentos = [
    {
      "imagen": "assets/images/filamento1.png",
      "mensaje": "El primer filamento reciclado se creó en 2010 con plásticos PET."
    },
    {
      "imagen": "assets/images/filamento2.png",
      "mensaje": "En 2015 se popularizó el uso de filamentos ecológicos en impresoras 3D."
    },
    {
      "imagen": "assets/images/filamento3.png",
      "mensaje": "Hoy en día los filamentos 3D permiten reducir residuos plásticos."
    },
    {
      "imagen": "assets/images/filamento4.png",
      "mensaje": "Los filamentos de bioplástico PLA son biodegradables y muy usados."
    },
  ];

  List<bool> expanded = [];

  @override
  void initState() {
    super.initState();
    expanded = List.generate(filamentos.length, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Eco-Refill Futurista",
          style: TextStyle(color: Colors.cyanAccent),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            child: const Text(
              "Iniciar Sesión",
              style: TextStyle(color: Colors.cyanAccent),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/feed_publico'),
            child: const Text(
              "Usuarios no registrados",
              style: TextStyle(color: Colors.cyanAccent),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            "Descubre la historia del filamento 3D",
            style: TextStyle(
              fontSize: 20,
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,       // dos imágenes por fila
                childAspectRatio: 0.9,   // proporción similar a la que tenías
                crossAxisSpacing: 40,    // separación horizontal (~1 cm)
                mainAxisSpacing: 40,     // separación vertical (~1 cm)
              ),
              itemCount: filamentos.length,
              itemBuilder: (context, index) {
                final item = filamentos[index];
                return Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          expanded[index] = !expanded[index];
                        });
                      },
                      child: Image.asset(item["imagen"]!, height: 100),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Filamento 3D",
                      style: TextStyle(color: Colors.cyanAccent),
                    ),
                    if (expanded[index]) ...[
                      const SizedBox(height: 10),
                      Text(
                        item["mensaje"]!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ]
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
