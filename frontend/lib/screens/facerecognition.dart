import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen>
    with SingleTickerProviderStateMixin {
  Uint8List? _capturedImage;
  bool _sending = false;

  late final AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    // 🔹 Registra el elemento <video> HTML antes de que se construya
    // el HtmlElementView. Sin esto la cámara no aparece.
    registerCameraView();

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
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
        Uri.parse("https://eco-refill-backend-992396324099.us-central1.run.app/api/auth/login_with_face"),
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

        // 🔹 Verificar el estado del usuario en Firestore antes de dejarlo
        // entrar. El campo "estado" no vive en Firebase Auth, así que un
        // rostro reconocido no basta si la cuenta está inactiva.
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid)
            .get();

        final estado = (userDoc.data()?['estado'] ?? 'Activo').toString();

        if (estado.toLowerCase() == 'inactivo') {
          await FirebaseAuth.instance.signOut();
          _logAccess(widget.uid, "denied");
          if (!mounted) return;
          _showAlert(
            "Esta cuenta se encuentra inactiva. Contacta a un administrador.",
          );
          return;
        }

        // 🔹 Registra el acceso autorizado para las estadísticas del
        // dashboard (usuarios registrados, accesos hoy, etc). No bloquea
        // la navegación si falla.
        _logAccess(widget.uid, "authorized");

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
          // 🔹 Solo contamos como "intento fallido" un rostro que sí se
          // comparó y no coincidió; no un usuario que aún no tiene rostro
          // registrado.
          if (!sinRostroRegistrado) {
            _logAccess(widget.uid, "denied");
          }
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
        Uri.parse("https://eco-refill-backend-992396324099.us-central1.run.app/api/auth/add_face"),
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

  /// Guarda cada intento de reconocimiento (autorizado o denegado) en
  /// Firestore, para alimentar las estadísticas del dashboard. No guarda
  /// la foto capturada: solo uid, resultado y fecha/hora.
  Future<void> _logAccess(String uid, String status) async {
    try {
      await FirebaseFirestore.instance.collection("access_logs").add({
        "uid": uid,
        "status": status, // "authorized" | "denied"
        "timestamp": FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Si falla el registro de estadísticas no interrumpimos el login.
    }
  }

  void _retomarFoto() {
    if (_sending) return;
    setState(() => _capturedImage = null);
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

  // 🎨 Paleta inspirada en el dashboard de referencia.
  static const _bgColor = Color(0xFF060A13);
  static const _cardColor = Color(0xFF0E1420);
  static const _cardBorder = Color(0xFF1C2536);
  static const _cyan = Colors.cyanAccent;
  static const _green = Color(0xFF34D399);
  static const _greyText = Color(0xFF8B96A8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(context),
              const SizedBox(height: 20),
              _buildCameraCard(),
              const SizedBox(height: 16),
              _buildStatusTipCard(),
              const SizedBox(height: 16),
              _buildStatsRow(),
              const SizedBox(height: 16),
              _buildLastRecognitionCard(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Encabezado: botón de volver + título + estado del sistema
  // ---------------------------------------------------------------------
  Widget _buildTopBar(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        InkWell(
          onTap: () => Navigator.maybePop(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _cardBorder),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Reconocimiento Facial",
                style: TextStyle(
                  color: _cyan,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Sistema de identificación y control de acceso",
                style: TextStyle(color: _greyText, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _buildSystemPill(),
      ],
    );
  }

  Widget _buildSystemPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: _green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            "Sistema activo",
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Tarjeta con la cámara / foto capturada
  // ---------------------------------------------------------------------
  Widget _buildCameraCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _cyan.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.videocam, color: _cyan, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Cámara en vivo",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: _green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _sending
                            ? "Analizando rostro..."
                            : (_capturedImage == null
                                ? "Detectando rostro..."
                                : "Foto capturada"),
                        style: const TextStyle(
                            color: _green, fontSize: 11.5),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // La cámara en vivo se mantiene siempre montada (para no
                    // perder el <video> del navegador), pero queda cubierta
                    // por la foto capturada en cuanto existe una.
                    Container(color: Colors.black),
                    const HtmlElementView(viewType: "camera-view"),
                    if (_capturedImage == null) _buildFaceFrame(),
                    if (_capturedImage != null)
                      Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(_capturedImage!, fit: BoxFit.cover),
                          if (_sending) _buildScanOverlay(),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_capturedImage != null && !_sending)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Center(
                child: TextButton.icon(
                  onPressed: _retomarFoto,
                  icon: const Icon(Icons.refresh, color: _greyText),
                  label: const Text(
                    "Tomar otra foto",
                    style: TextStyle(color: _greyText),
                  ),
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _sending ? null : _captureAndSend,
              style: OutlinedButton.styleFrom(
                foregroundColor: _cyan,
                side: BorderSide(
                    color: _cyan.withOpacity(_sending ? 0.3 : 0.8)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _cyan,
                      ),
                    )
                  : const Icon(Icons.center_focus_strong, size: 20),
              label: Text(
                _sending ? "Procesando..." : "Capturar rostro",
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Marco de esquinas estilo "escáner facial" que se muestra sobre la
  /// cámara en vivo mientras aún no se ha capturado una foto.
  Widget _buildFaceFrame() {
    const bracket = _cyan;
    Widget corner({required Alignment align, required bool top, required bool left}) {
      return Align(
        alignment: align,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CustomPaint(
              painter: _CornerPainter(color: bracket, top: top, left: left),
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        corner(align: Alignment.topLeft, top: true, left: true),
        corner(align: Alignment.topRight, top: true, left: false),
        corner(align: Alignment.bottomLeft, top: false, left: true),
        corner(align: Alignment.bottomRight, top: false, left: false),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Tarjeta de estado actual + consejo
  // ---------------------------------------------------------------------
  Widget _buildStatusTipCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _green.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _sending ? Icons.hourglass_top : Icons.check,
                    color: _green,
                  ),
                ),
                const SizedBox(height: 8),
                const Text("Estado actual",
                    style: TextStyle(color: _greyText, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  _sending ? "Enviando" : "Listo",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _sending ? "verificando..." : "para identificar",
                  style: const TextStyle(color: _greyText, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 90, color: _cardBorder),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.lightbulb_outline, color: _cyan, size: 18),
                    SizedBox(width: 6),
                    Text("Consejo",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "Asegúrate de estar en un lugar bien iluminado y mirar "
                  "directamente a la cámara.",
                  style: TextStyle(
                      color: _greyText, fontSize: 12.5, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Fila de estadísticas: usuarios registrados (colección "users") +
  // accesos/intentos de hoy (colección "access_logs" que este mismo
  // formulario alimenta en _logAccess).
  // ---------------------------------------------------------------------
  Widget _buildStatsRow() {
    final startOfToday = DateTime.now();
    final todayStart = DateTime(
        startOfToday.year, startOfToday.month, startOfToday.day);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("users").snapshots(),
      builder: (context, usersSnap) {
        final totalUsuarios = usersSnap.data?.docs.length;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("access_logs")
              .where("timestamp",
                  isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
              .snapshots(),
          builder: (context, logsSnap) {
            int autorizados = 0;
            int fallidos = 0;

            if (logsSnap.hasData) {
              for (final doc in logsSnap.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                if (data["status"] == "authorized") {
                  autorizados++;
                } else if (data["status"] == "denied") {
                  fallidos++;
                }
              }
            }

            final totalIntentos = autorizados + fallidos;
            final String precision = totalIntentos == 0
                ? "—"
                : "${(autorizados / totalIntentos * 100).toStringAsFixed(1)}%";

            return Row(
              children: [
                Expanded(
                  child: _statCard(
                    icon: Icons.groups_outlined,
                    iconColor: _cyan,
                    value: totalUsuarios?.toString() ?? "…",
                    label: "Usuarios\nregistrados",
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                    icon: Icons.verified_user_outlined,
                    iconColor: _green,
                    value: autorizados.toString(),
                    label: "Accesos\nautorizados hoy",
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                    icon: Icons.schedule,
                    iconColor: const Color(0xFFF59E0B),
                    value: fallidos.toString(),
                    label: "Intentos\nfallidos hoy",
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                    icon: Icons.graphic_eq,
                    iconColor: const Color(0xFFA78BFA),
                    value: precision,
                    label: "Precisión\ndel sistema",
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
                color: _greyText, fontSize: 10.5, height: 1.2),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Último reconocimiento: toma el registro más reciente de
  // "access_logs" y busca el nombre del usuario en "users".
  // ---------------------------------------------------------------------
  Widget _buildLastRecognitionCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("access_logs")
          .orderBy("timestamp", descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        final cardDecoration = BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _cardBorder),
        );

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: cardDecoration,
            child: const Row(
              children: [
                Icon(Icons.history, color: _greyText),
                SizedBox(width: 12),
                Text(
                  "Todavía no hay reconocimientos registrados.",
                  style: TextStyle(color: _greyText, fontSize: 12.5),
                ),
              ],
            ),
          );
        }

        final doc = snapshot.data!.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        final String uid = data["uid"]?.toString() ?? "";
        final String status = data["status"]?.toString() ?? "denied";
        final Timestamp? ts = data["timestamp"] as Timestamp?;
        final DateTime? dt = ts?.toDate();

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: cardDecoration,
          child: FutureBuilder<DocumentSnapshot>(
            future: uid.isEmpty
                ? null
                : FirebaseFirestore.instance
                    .collection("users")
                    .doc(uid)
                    .get(),
            builder: (context, userSnap) {
              String nombre = "Usuario";
              if (userSnap.hasData && userSnap.data!.exists) {
                final userData =
                    userSnap.data!.data() as Map<String, dynamic>;
                final n = (userData["name"] ?? "").toString().trim();
                if (n.isNotEmpty) nombre = n;
              }

              return Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: _cyan.withOpacity(0.15),
                    child: Text(
                      _getInitials(nombre),
                      style: const TextStyle(
                        color: _cyan,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Último reconocimiento",
                          style: TextStyle(color: _greyText, fontSize: 11.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          nombre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: (status == "authorized"
                                    ? _green
                                    : Colors.redAccent)
                                .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status == "authorized"
                                ? "Acceso autorizado"
                                : "Acceso denegado",
                            style: TextStyle(
                              color: status == "authorized"
                                  ? _green
                                  : Colors.redAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (dt != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            "${_formatDate(dt)}   ${_formatTime(dt)}",
                            style: const TextStyle(
                                color: _greyText, fontSize: 11.5),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.fingerprint,
                      color: _cyan.withOpacity(0.7), size: 34),
                ],
              );
            },
          ),
        );
      },
    );
  }

  String _getInitials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return "U";
    final parts = clean.split(RegExp(r"\s+"));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return "${parts.first.substring(0, 1)}${parts[1].substring(0, 1)}"
        .toUpperCase();
  }

  String _formatDate(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}/"
        "${dt.month.toString().padLeft(2, '0')}/${dt.year}";
  }

  String _formatTime(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, '0')}:"
        "${dt.minute.toString().padLeft(2, '0')}:"
        "${dt.second.toString().padLeft(2, '0')}";
  }

  /// Animación de "rostro siendo escaneado": una línea que recorre la
  /// foto de arriba a abajo sobre un marco resaltado, mientras se envía
  /// la imagen al backend.
  Widget _buildScanOverlay() {
    return AnimatedBuilder(
      animation: _scanController,
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Oscurece un poco la foto para que resalte la línea de escaneo.
            Container(color: Colors.black.withOpacity(0.25)),
            // Marco tipo "escáner facial".
            Center(
              child: Container(
                width: 220,
                height: 260,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.cyanAccent.withOpacity(0.8),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            // Línea de escaneo que se mueve de arriba hacia abajo.
            // (El Positioned debe ser hijo directo de un Stack; el
            // LayoutBuilder va adentro solo para leer las constraints).
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final top =
                      constraints.maxHeight * _scanController.value;
                  return Stack(
                    children: [
                      Positioned(
                        top: top,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.cyanAccent.withOpacity(0),
                                Colors.cyanAccent,
                                Colors.cyanAccent.withOpacity(0),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyanAccent.withOpacity(0.8),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Escaneando rostro...",
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Dibuja una "L" (esquina) usada para armar el marco tipo escáner facial
/// sobre la vista de la cámara en vivo.
class _CornerPainter extends CustomPainter {
  final Color color;
  final bool top;
  final bool left;

  _CornerPainter({required this.color, required this.top, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final double y = top ? 0 : size.height;
    final double x = left ? 0 : size.width;
    final double vDir = top ? 1 : -1;
    final double hDir = left ? 1 : -1;

    path.moveTo(x, y + vDir * size.height * 0.7);
    path.lineTo(x, y);
    path.lineTo(x + hDir * size.width * 0.7, y);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.top != top ||
      oldDelegate.left != left;
}