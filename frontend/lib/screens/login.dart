import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'facerecognition.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  late final AnimationController _pulseController;
  late final Animation<double> _glowAnimation;

  bool _isLoading = false;

  static const Color _purple = Color(0xffA855F7);
  static const Color _darkPurple = Color(0xff150D26);
  static const Color _cream = Color(0xFFF5EFE6);
  static const Color _brown = Color(0xFF9C4A2F);
  static const Color _green = Color(0xFF2C5E3B);

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
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _goToHome() {
    if (!mounted) return;

    Navigator.pushReplacementNamed(context, '/home');
  }

  void _showAlert(String message) {
    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _cream,
          title: const Text(
            'Aviso',
            style: TextStyle(color: _brown, fontWeight: FontWeight.bold),
          ),
          content: Text(
            message,
            style: const TextStyle(color: Color(0xFF4A4A4A)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'OK',
                style: TextStyle(color: _green, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _login() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showAlert('Por favor ingresa correo y contraseña.');
      return;
    }

    if (!email.contains('@')) {
      _showAlert('Ingresa un correo electrónico válido.');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final User? user = await _authService.login(email, password);

      if (!mounted) return;

      if (user != null) {
        Navigator.pushReplacementNamed(context, '/pantallabienvenida');
      } else {
        _showAlert('No se pudo iniciar sesión. Verifica tus datos.');
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      _showAlert(_getFirebaseErrorMessage(error));
    } catch (_) {
      if (!mounted) return;
      _showAlert('Ocurrió un error inesperado. Intenta nuevamente.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getFirebaseErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-credential':
      case 'invalid-login-credentials':
      case 'wrong-password':
      case 'user-not-found':
        return 'El correo o la contraseña no son correctos.';

      case 'invalid-email':
        return 'El formato del correo electrónico no es válido.';

      case 'user-disabled':
        return 'Esta cuenta se encuentra deshabilitada.';

      case 'too-many-requests':
        return 'Demasiados intentos. Espera unos minutos e inténtalo nuevamente.';

      case 'network-request-failed':
        return 'No hay conexión con Internet. Revisa tu red.';

      case 'operation-not-allowed':
        return 'El inicio de sesión con correo y contraseña no está habilitado.';

      default:
        return 'No se pudo iniciar sesión. Intenta nuevamente.';
    }
  }

  Future<void> _startFaceLogin() async {
    final emailController = TextEditingController();

    final String? email = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _cream,
          title: const Text(
            'Reconocimiento Facial',
            style: TextStyle(color: _brown, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: emailController,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Color(0xFF2C2C2C), fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Ingresa tu correo',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: _brown),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: _green, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar', style: TextStyle(color: _brown)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, emailController.text.trim());
              },
              child: const Text('Continuar', style: TextStyle(color: _green)),
            ),
          ],
        );
      },
    );

    emailController.dispose();

    if (email == null || email.isEmpty) return;

    try {
      final String? uid = await _authService.getUidByEmail(email);

      if (!mounted) return;

      if (uid == null) {
        _showAlert('No se encontró ningún usuario con ese correo.');
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => FaceRecognitionScreen(uid: uid)),
      );
    } catch (_) {
      if (!mounted) return;

      _showAlert('No se pudo iniciar el reconocimiento facial.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,

      // Botón visible en la esquina superior izquierda.
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(left: 14, top: 14),
        child: FloatingActionButton.extended(
          heroTag: 'loginHomeButton',
          onPressed: _goToHome,
          tooltip: 'Ir al inicio',
          backgroundColor: _darkPurple,
          foregroundColor: Colors.white,
          elevation: 10,
          icon: const Icon(Icons.home_rounded, size: 22),
          label: const Text(
            'Inicio',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),

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
                        color: Colors.white.withOpacity(0.12),
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
              child: _buildLoginContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmallScreen = constraints.maxWidth < 650;

        if (isSmallScreen) {
          return Column(
            children: [_buildPresentationPanel(), _buildFormPanel()],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 4, child: _buildPresentationPanel()),
            Expanded(flex: 6, child: _buildFormPanel()),
          ],
        );
      },
    );
  }

  Widget _buildPresentationPanel() {
    return Container(
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
                  'ECO - REFILL',
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
              'Gestión del ciclo del filamento 3D',
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
                      offset: Offset(0, 8 * (_glowAnimation.value / 26)),
                      child: child,
                    );
                  },
                  child: Image.asset(
                    'assets/images/Filamento3D.png',
                    width: 250,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 60),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'De residuos,       ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: 'Creamos futuro.',
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
                _FeatureItem(
                  icon: Icons.inventory_2_outlined,
                  label: 'Inventario',
                ),
                _FeatureItem(icon: Icons.eco_outlined, label: 'Producción'),
                _FeatureItem(icon: Icons.security, label: 'Seguridad'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xff6F36D8), Color(0xff261642), Color(0xff131020)],
        ),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(15),
          bottomRight: Radius.circular(15),
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
                'assets/images/Icon1.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Iniciar Sesión',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '¡Bienvenido de nuevo!',
              style: TextStyle(
                color: Color(0xffD68CFF),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 18),
            _fieldLabel('Correo Electrónico'),
            const SizedBox(height: 8),
            SizedBox(
              height: 46,
              child: HoverTextField(
                controller: _emailController,
                hint: 'Ingresa tu correo',
              ),
            ),
            const SizedBox(height: 20),
            _fieldLabel('Contraseña'),
            const SizedBox(height: 8),
            SizedBox(
              height: 46,
              child: HoverTextField(
                controller: _passwordController,
                hint: 'Ingresa tu contraseña',
                obscure: true,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: _isLoading
                  ? _buildLoadingButton()
                  : _HoverButton(text: 'Iniciar Sesión', onPressed: _login),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: Divider(color: Colors.white.withOpacity(.15))),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('o', style: TextStyle(color: Colors.white54)),
                ),
                Expanded(child: Divider(color: Colors.white.withOpacity(.15))),
              ],
            ),
            const SizedBox(height: 10),
            _buildFaceLoginButton(),
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
                  'Acceso seguro y protegido',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingButton() {
    return Container(
      decoration: BoxDecoration(
        color: _darkPurple,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xff7A2BFF), width: 2),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildFaceLoginButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: _isLoading ? null : _startFaceLogin,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xff7A2BFF)),
        ),
        child: const Row(
          children: [
            Icon(Icons.face_retouching_natural, color: Colors.white, size: 30),
            SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reconocimiento Facial',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Acceso rápido y seguro',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(.95),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xffA855F7)),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
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
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (mounted) {
          setState(() => _hover = true);
        }
      },
      onExit: (_) {
        if (mounted) {
          setState(() => _hover = false);
        }
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: _hover
                ? const Color.fromARGB(255, 55, 26, 106)
                : const Color.fromARGB(255, 38, 15, 75),
            border: Border.all(
              color: _hover ? const Color(0xffB46CFF) : const Color(0xff7A2BFF),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff8F45FF).withOpacity(_hover ? .75 : .35),
                blurRadius: _hover ? 28 : 12,
                spreadRadius: _hover ? 2 : 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(.35),
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
              shadows: _hover
                  ? const [Shadow(color: Color(0xffD7A9FF), blurRadius: 12)]
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
  bool _hover = false;
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscure;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.text,
      onEnter: (_) {
        if (mounted) {
          setState(() => _hover = true);
        }
      },
      onExit: (_) {
        if (mounted) {
          setState(() => _hover = false);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: _hover
              ? [
                  BoxShadow(
                    color: const Color(0xff8F45FF).withOpacity(.30),
                    blurRadius: 14,
                  ),
                ]
              : [],
        ),
        child: TextField(
          controller: widget.controller,
          obscureText: _obscureText,
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
            suffixIcon: widget.obscure
                ? IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                    icon: Icon(
                      _obscureText
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.white60,
                    ),
                  )
                : null,
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
