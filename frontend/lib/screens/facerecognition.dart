import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';

class FaceRecognitionScreen extends StatefulWidget {
  const FaceRecognitionScreen({super.key});

  @override
  State<FaceRecognitionScreen> createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  Uint8List? _capturedImage;
  final AuthService _authService = AuthService();

  Future<void> _captureAndSend() async {
    final videoElement = html.document.querySelector('video') as html.VideoElement?;

    if (videoElement == null || videoElement.videoWidth == 0) {
      print("No se encontró el video o aún no está listo.");
      return;
    }

    final canvas = html.CanvasElement(
      width: videoElement.videoWidth,
      height: videoElement.videoHeight,
    );
    final ctx = canvas.context2D;
    ctx.drawImage(videoElement, 0, 0);

    final blob = await canvas.toBlob('image/jpeg');

    if (blob != null) {
      final reader = html.FileReader();
      reader.readAsArrayBuffer(blob);
      await reader.onLoad.first;

      final bytes = reader.result as Uint8List;

      // 🔹 Mostrar la captura en pantalla
      setState(() {
        _capturedImage = bytes;
      });

      // 🔹 Enviar al backend (login facial)
      final request = http.MultipartRequest(
        'POST',
        Uri.parse("http://localhost:8000/api/procesar/"), // 🔹 con barra al final
      );

      request.files.add(http.MultipartFile.fromBytes('file', bytes,
          filename: "captura.jpg"));

      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      final data = json.decode(respStr);

      if (data["status"] == "success") {
        final userUid = data["user"]; // 🔹 ahora es UID
        final success = await _authService.loginWithFace(userUid);
        if (success) {
          // Opcional: obtener correo desde UID
          final email = await _authService.getEmailFromUid(userUid);
          Navigator.pushReplacementNamed(context, '/pantallabienvenida');
          if (email != null) {
            _showAlert("Bienvenido $email");
          }
        } else {
          _showAlert("No se pudo iniciar sesión con UID $userUid");
        }
      } else {
        _showAlert("Rostro no reconocido");
      }
    } else {
      print("No se pudo crear el blob de la imagen.");
    }
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Mensaje"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Activar Reconocimiento Facial"),
        backgroundColor: Colors.cyanAccent,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          const Expanded(child: HtmlElementView(viewType: 'camera-view')),
          ElevatedButton(
            onPressed: _captureAndSend,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Capturar y procesar"),
          ),
          if (_capturedImage != null)
            Expanded(
              child: Image.memory(_capturedImage!),
            ),
        ],
      ),
    );
  }
}
