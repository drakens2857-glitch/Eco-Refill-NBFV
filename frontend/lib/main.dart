 import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';

// Pantallas
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
import 'screens/pantallabienvenida.dart';
import 'screens/facerecognition.dart';

// 🔹 Import específico para Web
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui_web' as ui_web;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await dotenv.load(fileName: "assets/.env");

  // Registrar cámara solo si es Web
  if (kIsWeb) {
    ui_web.platformViewRegistry.registerViewFactory(
      'camera-view',
      (int viewId) {
        final video = html.VideoElement()
          ..autoplay = true
          ..muted = true // 🔹 necesario para autoplay en Chrome
          ..style.width = '100%'
          ..style.height = '100%';

        // 🔹 playsinline evita que Safari/iOS abra pantalla completa
        video.setAttribute('playsinline', 'true');

        // Conectar la cámara
        html.window.navigator.mediaDevices
            ?.getUserMedia({'video': true}).then((stream) {
          video.srcObject = stream;
          video.play().catchError((e) {
            print("Error al reproducir el video: $e");
          });
        }).catchError((e) {
          print("Error al acceder a la cámara: $e");
        });

        return video;
      },
    );
  }

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
        '/feed_publico': (context) => const FeedPublicoScreen(desdeLogin: false),
        '/reportes': (context) => const ReportesScreen(),
        '/pantallabienvenida': (context) => const PantallaBienvenida(),
        '/facerecognition': (context) => const FaceRecognitionScreen(),
      },
    );
  }
}
