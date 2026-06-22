import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';

// Importa tus pantallas
import 'screens/login.dart';
import 'screens/register.dart';
import 'screens/dashboard.dart';
import 'screens/materiales.dart';
import 'screens/tareas.dart';
import 'screens/perfil.dart';
import 'screens/usuarios.dart';   
import 'screens/ingreso.dart';    
import 'screens/procesos.dart';   
import 'screens/feed_publico.dart';
import 'screens/home.dart';
import 'screens/reportes.dart';
import 'screens/pantallabienvenida.dart'; // 🔹 Importa tu nueva pantalla

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Carga variables de entorno (Cloudinary)
  await dotenv.load(fileName: "assets/.env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Eco-Refill Futurista',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F2027),
        primaryColor: Colors.cyanAccent,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyanAccent,
            foregroundColor: Colors.black,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      initialRoute: '/home',
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/materiales': (context) => const MaterialesScreen(),
        '/tareas': (context) => const TareasScreen(),
        '/perfil': (context) => const PerfilScreen(),
        '/usuarios': (context) => const UsuariosScreen(),
        '/ingreso': (context) => const IngresoScreen(),
        '/procesos': (context) => const ProcesosScreen(),
        '/feed_publico': (context) => const FeedPublicoScreen(),
        '/reportes': (context) => const ReportesScreen(),
        '/pantallabienvenida': (context) => const PantallaBienvenida(),

      },
    );
  }
}
