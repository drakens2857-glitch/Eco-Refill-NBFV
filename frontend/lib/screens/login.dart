import 'dart:ui';

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pantallabienvenida.dart';
import 'facerecognition.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  late AnimationController _pulseController;
  late Animation<double> _glowAnimation;
  late Animation<Color?> _backgroundAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 8, end: 26).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _backgroundAnimation = ColorTween(
      begin: const Color(0xFFF5FBFF),
      end: const Color(0xFFEAF6FF),
    ).animate(_pulseController);
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF5EFE6),
        title: const Text(
          "Error",
          style: TextStyle(
            color: Color(0xFF9C4A2F),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Color(0xFF4A4A4A)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "OK",
              style: TextStyle(
                color: Color(0xFF2C5E3B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showAlert("Por favor ingresa correo y contraseña.");
      return;
    }

    try {
      final user = await _authService.login(email, password);

      if (user != null) {
        if (!mounted) return;

        Navigator.pushReplacementNamed(context, '/pantallabienvenida');
      } else {
        _showAlert("Error al iniciar sesión. Verifica tus datos.");
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _showAlert("No existe un usuario con ese correo.");
      } else if (e.code == 'wrong-password') {
        _showAlert("La contraseña es incorrecta.");
      } else if (e.code == 'invalid-email') {
        _showAlert("El formato del correo no es válido.");
      } else {
        _showAlert("Error: ${e.message}");
      }
    } catch (e) {
      _showAlert("Error inesperado: $e");
    }
  }

  Future<void> _startFaceLogin() async {
    final emailController = TextEditingController();

    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF5EFE6),
        title: const Text(
          "Reconocimiento Facial",
          style: TextStyle(
            color: Color(0xFF9C4A2F),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: emailController,
          autofocus: true,
          style: const TextStyle(color: Color(0xFF2C2C2C), fontSize: 15),
          decoration: InputDecoration(
            hintText: "Ingresa tu correo",
            hintStyle: TextStyle(color: Colors.grey.shade500),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF9C4A2F)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF2C5E3B), width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, emailController.text.trim()),
            child: const Text("Continuar"),
          ),
        ],
      ),
    );

    if (email == null || email.isEmpty) return;

    final uid = await _authService.getUidByEmail(email);

    if (uid == null) {
      _showAlert("No se encontró ningún usuario con ese correo.");
      return;
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FaceRecognitionScreen(uid: uid)),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/Fondo1.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      constraints: const BoxConstraints(
                        maxWidth: 760,
                        maxHeight: 620,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12), // efecto vidrio
                        borderRadius: BorderRadius.circular(18),

                        border: Border.all(
                          color: const Color.fromARGB(255, 117, 33, 196),
                          width: 1,
                        ),

                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(255, 200, 155, 255),
                            blurRadius: _glowAnimation.value,
                            spreadRadius: _glowAnimation.value / 40,
                          ),

                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: child,
                    ),
                  ),
                );
              },

              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 4,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xff120B22),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(15),
                          bottomLeft: Radius.circular(15),
                        ),
                      ),
                      padding: const EdgeInsets.all(25),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  color: Color.fromARGB(255, 179, 100, 252),
                                  size: 35,
                                ),
                                SizedBox(width: 15),
                                Text(
                                  "ECO - REFILL",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 25),

                            Text(
                              "Gestión del ciclo del filamento 3D",
                              style: TextStyle(
                                color: Colors.white.withOpacity(.55),
                                fontSize: 14,
                              ),
                            ),

                            const SizedBox(height: 35),

                            SizedBox(
                              height: 230,
                              child: Center(
                                child: AnimatedBuilder(
                                  animation: _pulseController,
                                  builder: (context, child) {
                                    return Transform.translate(
                                      offset: Offset(
                                        0,
                                        8 * (_glowAnimation.value / 26),
                                      ),
                                      child: child,
                                    );
                                  },
                                  child: Image.asset(
                                    "assets/images/Filamento3D.png",
                                    width: 250,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 60),

                            RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: "De residuos,       ",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),

                                  TextSpan(
                                    text: "Creamos futuro.",
                                    style: TextStyle(
                                      color: Color(0xffA855F7),
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 50),

                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      color: Color(0xffA855F7),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "Inventario",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),

                                Column(
                                  children: [
                                    Icon(
                                      Icons.eco_outlined,
                                      color: Color(0xffA855F7),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "Producción",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),

                                Column(
                                  children: [
                                    Icon(
                                      Icons.security,
                                      color: Color(0xffA855F7),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "Seguridad",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    flex: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 42,
                        vertical: 28,
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xff6F36D8),
                            Color(0xff261642),
                            Color(0xff131020),
                          ],
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 62,
                              height: 62,
                              child: Image.asset(
                                "assets/images/Icon1.png",
                                fit: BoxFit.contain,
                              ),
                            ),

                            const SizedBox(height: 22),

                            const Text(
                              "Iniciar Sesión",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 6),

                            const Text(
                              " ¡Bienvenido de nuevo!",
                              style: TextStyle(
                                color: Color(0xffD68CFF),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),

                            const SizedBox(height: 18),

                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Correo Electrónico",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(.95),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            SizedBox(
                              height: 46,
                              child: HoverTextField(
                                controller: _emailController,
                                hint: "Ingresa tu correo",
                              ),
                            ),

                            const SizedBox(height: 20),

                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Contraseña",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(.95),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            SizedBox(
                              height: 46,
                              child: HoverTextField(
                                controller: _passwordController,
                                hint: "Ingresa tu contraseña",
                                obscure: true,
                              ),
                            ),

                            const SizedBox(height: 30),

                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: _HoverButton(
                                text: "Iniciar Sesión",
                                onPressed: _login,
                              ),
                            ),

                            const SizedBox(height: 10),

                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors.white.withOpacity(.15),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    "o",
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Colors.white.withOpacity(.15),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: _startFaceLogin,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(.04),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xff7A2BFF),
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.face_retouching_natural,
                                      color: Colors.white,
                                      size: 30,
                                    ),

                                    SizedBox(width: 18),

                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Reconocimiento Facial",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),

                                        SizedBox(height: 2),

                                        Text(
                                          "Acceso rápido y seguro",
                                          style: TextStyle(
                                            color: Colors.white60,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 22),

                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.verified_user_outlined,
                                  size: 16,
                                  color: Colors.white38,
                                ),

                                SizedBox(width: 8),

                                Text(
                                  "Acceso seguro y protegido",
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HoverButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;

  const _HoverButton({required this.text, required this.onPressed});

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,

          alignment: Alignment.center,

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),

            color: hover
                ? const Color.fromARGB(255, 55, 26, 106)
                : const Color(0xff150D26),

            border: Border.all(
              color: hover ? const Color(0xffB46CFF) : const Color(0xff7A2BFF),
              width: 2,
            ),

            boxShadow: [
              BoxShadow(
                color: const Color(0xff8F45FF).withOpacity(hover ? .75 : .35),
                blurRadius: hover ? 28 : 12,
                spreadRadius: hover ? 2 : 0,
              ),

              BoxShadow(
                color: const Color.fromARGB(255, 49, 48, 48).withOpacity(.35),
                offset: const Offset(0, 6),
                blurRadius: 12,
              ),
            ],
          ),

          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),

            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              letterSpacing: 1.4,

              shadows: hover
                  ? [Shadow(color: Color(0xffD7A9FF), blurRadius: 12)]
                  : [],
            ),

            child: Text(widget.text),
          ),
        ),
      ),
    );
  }
}

class HoverTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;

  const HoverTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.obscure = false,
  });

  @override
  State<HoverTextField> createState() => _HoverTextFieldState();
}

class _HoverTextFieldState extends State<HoverTextField> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.text,
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),

        clipBehavior: Clip.none,

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),

          boxShadow: hover
              ? [
                  BoxShadow(
                    color: const Color(0xff8F45FF).withOpacity(.30),
                    blurRadius: 14,
                    spreadRadius: 0,
                  ),
                ]
              : [],
        ),

        child: TextField(
          controller: widget.controller,
          obscureText: widget.obscure,

          style: const TextStyle(color: Colors.white, fontSize: 14),

          decoration: InputDecoration(
            filled: true,

            fillColor: const Color(0xff2A1F4B).withOpacity(.35),

            hintText: widget.hint,

            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 12,
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(.15)),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xffA855F7),
                width: 1.8,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
