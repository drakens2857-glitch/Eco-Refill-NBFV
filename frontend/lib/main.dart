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

// 🔹 Ya NO necesitamos importar FaceRecognition aquí
// import 'screens/facerecognition.dart';

// Web
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui_web' as ui_web;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await dotenv.load(fileName: "assets/.env");

  if (kIsWeb) {
    ui_web.platformViewRegistry.registerViewFactory(
      'camera-view',
      (int viewId) {
        final video = html.VideoElement()
          ..autoplay = true
          ..muted = true
          ..style.width = '100%'
          ..style.height = '100%';

        video.setAttribute('playsinline', 'true');

        html.window.navigator.mediaDevices
            ?.getUserMedia({'video': true}).then((stream) {
          video.srcObject = stream;
          video.play();
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
      ),

      initialRoute: "/home",

      routes: {

        "/home": (_) => const HomeScreen(),

        "/login": (_) => const LoginScreen(),

        "/register": (_) => const RegisterScreen(),

        "/dashboard": (_) => const DashboardScreen(),

        "/materiales": (_) => const MaterialesScreen(),

        "/tareas": (_) => const TareasScreen(),

        "/perfil": (_) => const PerfilScreen(),

        "/usuarios": (_) => const UsuariosScreen(),

        "/ingreso": (_) => const IngresoScreen(),

        "/procesos": (_) => const ProcesosScreen(),

        "/feed_publico": (_) => const FeedPublicoScreen(
              desdeLogin: false,
            ),

        "/reportes": (_) => const ReportesScreen(),

        "/pantallabienvenida": (_) => const PantallaBienvenida(),

        // ❌ ELIMINAR ESTA RUTA
        // "/facerecognition": (_) => const FaceRecognitionScreen(),

      },
    );
  }
}