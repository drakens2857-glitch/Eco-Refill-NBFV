import 'package:flutter/material.dart';

class PantallaBienvenida extends StatelessWidget {
  const PantallaBienvenida({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, '/pantallabienvenida');
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F2027),
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text(
            "Eco-Refill Futurista",
            style: TextStyle(color: Colors.cyanAccent),
          ),
          centerTitle: true,
        ),
        drawer: Drawer(
          backgroundColor: Colors.black,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Colors.cyanAccent),
                child: Text(
                  "Menú Eco-Refill",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _menuItem(context, Icons.person, "Perfil", '/perfil'),
              _menuItem(context, Icons.dashboard, "Dashboard", '/dashboard'),
              _menuItem(context, Icons.add_box, "Ingreso Plásticos", '/ingreso'),
              _menuItem(context, Icons.recycling, "Materiales", '/materiales'),
              _menuItem(context, Icons.settings, "Procesos", '/procesos'),
              _menuItem(context, Icons.app_registration, "Registrar Usuario", '/register'),
              _menuItem(context, Icons.task, "Tareas", '/tareas'),
              _menuItem(context, Icons.people, "Usuarios", '/usuarios'),
            ],
          ),
        ),
        body: const Center(
          child: Text(
            "Bienvenido al panel principal",
            style: TextStyle(color: Colors.cyanAccent, fontSize: 20),
          ),
        ),
      ),
    );
  }

  ListTile _menuItem(BuildContext context, IconData icon, String text, String route) {
    return ListTile(
      leading: Icon(icon, color: Colors.cyanAccent),
      title: Text(text, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pushReplacementNamed(context, route);
      },
    );
  }
}
