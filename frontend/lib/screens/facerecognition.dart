import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import 'web_camera_view.dart';

class FaceRecognitionScreen extends StatefulWidget {
  final String uid;

  const FaceRecognitionScreen({
    super.key,
    required this.uid,
  });

  @override
  State<FaceRecognitionScreen> createState() =>
      _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  Uint8List? _capturedImage;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // 🔹 Registra el elemento <video> HTML antes de que se construya
    // el HtmlElementView. Sin esto la cámara no aparece.
    registerCameraView();
  }

  Future<void> _captureAndSend() async {
    if (_sending) return;

    final videoElement =
        html.document.querySelector('video') as html.VideoElement?;

    if (videoElement == null || videoElement.videoWidth == 0) {
      _showAlert("La cámara aún no está lista. Espera un momento y vuelve a intentar.");
      return;
    }

    setState(() => _sending = true);

    try {
      final canvas = html.CanvasElement(
        width: videoElement.videoWidth,
        height: videoElement.videoHeight,
      );

      final ctx = canvas.context2D;
      ctx.drawImage(videoElement, 0, 0);

      final blob = await canvas.toBlob('image/jpeg');

      final reader = html.FileReader();
      reader.readAsArrayBuffer(blob);
      await reader.onLoad.first;

      final bytes = reader.result as Uint8List;

      setState(() {
        _capturedImage = bytes;
      });

      final request = http.MultipartRequest(
        "POST",
        Uri.parse("http://127.0.0.1:8000/api/auth/login_with_face"),
      );

      request.fields["uid"] = widget.uid;

      request.files.add(
        http.MultipartFile.fromBytes(
          "file",
          bytes,
          filename: "captura.jpg",
        ),
      );

      final response = await request.send();
      final body = await response.stream.bytesToString();

      Map<String, dynamic> data;
      try {
        data = jsonDecode(body) as Map<String, dynamic>;
      } catch (_) {
        _showAlert("El servidor respondió de forma inesperada. Revisa que el backend esté corriendo.");
        return;
      }

      if (response.statusCode == 200 && data["success"] == true) {
        if (!mounted) return;

        final token = data["token"];
        if (token != null) {
          try {
            await FirebaseAuth.instance.signInWithCustomToken(token);
          } catch (e) {
            _showAlert("Rostro reconocido, pero no se pudo iniciar sesión: $e");
            return;
          }
        }

        if (!mounted) return;

        Navigator.pushReplacementNamed(
          context,
          "/pantallabienvenida",
        );
      } else {
        final detail = data["detail"];
        String message;
        if (detail is Map && detail["message"] != null) {
          message = detail["message"].toString();
        } else {
          message = data["message"]?.toString() ??
              detail?.toString() ??
              "Rostro no reconocido";
        }

        final bool sinRostroRegistrado =
            message.toLowerCase().contains("sin rostro registrado");

        // 🔹 Solo se ofrece registrar el rostro si el usuario ya demostró
        // ser dueño de esta cuenta (inició sesión con contraseña antes de
        // llegar aquí). Así nadie puede registrar un rostro ajeno solo
        // sabiendo el correo.
        final bool yaAutenticadoComoEsteUsuario =
            FirebaseAuth.instance.currentUser?.uid == widget.uid;

        if (sinRostroRegistrado &&
            yaAutenticadoComoEsteUsuario &&
            _capturedImage != null) {
          _offerRegisterFace();
        } else {
          _showAlert(message);
        }
      }
    } catch (e) {
      _showAlert("No se pudo conectar con el servidor: $e");
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _offerRegisterFace() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Rostro no registrado"),
        content: const Text(
          "Esta cuenta todavía no tiene un rostro guardado. "
          "Ya iniciaste sesión con tu contraseña, así que puedes "
          "registrar tu rostro ahora usando la última foto capturada.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _registerFaceNow();
            },
            child: const Text("Registrar mi rostro"),
          ),
        ],
      ),
    );
  }

  Future<void> _registerFaceNow() async {
    if (_capturedImage == null) return;

    setState(() => _sending = true);

    try {
      final request = http.MultipartRequest(
        "POST",
        Uri.parse("http://127.0.0.1:8000/api/auth/add_face"),
      );

      request.fields["uid"] = widget.uid;

      request.files.add(
        http.MultipartFile.fromBytes(
          "file",
          _capturedImage!,
          filename: "registro.jpg",
        ),
      );

      final response = await request.send();
      final body = await response.stream.bytesToString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data["success"] == true) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, "/pantallabienvenida");
      } else {
        _showAlert(data["detail"]?.toString() ?? "No se pudo registrar el rostro.");
      }
    } catch (e) {
      _showAlert("No se pudo conectar con el servidor: $e");
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showAlert(String mensaje) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reconocimiento Facial"),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Aceptar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reconocimiento Facial"),
        backgroundColor: Colors.cyanAccent,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          const Expanded(
            child: HtmlElementView(
              viewType: "camera-view",
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: _sending ? null : _captureAndSend,
            child: _sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text("Capturar rostro"),
          ),
          const SizedBox(height: 15),
          if (_capturedImage != null)
            Expanded(
              child: Image.memory(_capturedImage!),
            ),
        ],
      ),
    );
  }
}