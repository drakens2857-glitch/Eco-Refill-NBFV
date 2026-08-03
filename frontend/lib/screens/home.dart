import 'package:flutter/material.dart';
import 'feed_publico.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color neonPurple = Color(0xFFA855F7);
  static const Color darkBg = Color(0xFF0F0716);
  static const Color cardBg = Color(0xFF170C28);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF8B5CF6)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.view_in_ar_rounded,
                color: Color(0xFFC084FC),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'ECO-REFILL',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            icon: const Icon(Icons.login_rounded, color: neonPurple, size: 18),
            label: const Text(
              "Iniciar Sesión",
              style: TextStyle(color: neonPurple, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const FeedPublicoScreen(desdeLogin: false),
                ),
              );
            },
            icon: const Icon(
              Icons.public_rounded,
              color: Colors.white70,
              size: 18,
            ),
            label: const Text(
              "Usuarios no registrados",
              style: TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(width: 32),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [darkBg, Color(0xFF1B0B2E), Color(0xFF280B3A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "¿QUIÉNES SOMOS?",
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2.5,
                  shadows: [
                    Shadow(color: neonPurple, blurRadius: 18),
                    Shadow(color: neonPurple, blurRadius: 36),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Innovación, sostenibilidad y tecnología avanzada en la gestión de reciclaje de plásticos.",
                style: TextStyle(
                  color: Color(0xFFC084FC),
                  fontSize: 18,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 60),
              LayoutBuilder(
                builder: (context, constraints) {
                  bool isWide = constraints.maxWidth > 850;
                  return isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildMissionCard()),
                            const SizedBox(width: 40),
                            Expanded(child: _buildVisionCard()),
                          ],
                        )
                      : Column(
                          children: [
                            _buildMissionCard(),
                            const SizedBox(height: 40),
                            _buildVisionCard(),
                          ],
                        );
                },
              ),
              const SizedBox(height: 50),
              _buildGeneralObjectiveCard(),
              const SizedBox(height: 50),
              LayoutBuilder(
                builder: (context, constraints) {
                  bool isWide = constraints.maxWidth > 950;
                  return isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildSpecificObjectivesCard(),
                            ),
                            const SizedBox(width: 40),
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  _buildValueCard(
                                    icon: Icons.verified_outlined,
                                    title: "Garantía de Calidad",
                                    description:
                                        "Procesos estandarizados bajo métricas estrictas para asegurar la máxima pureza y consistencia del material reutilizado.",
                                  ),
                                  const SizedBox(height: 32),
                                  _buildValueCard(
                                    icon: Icons.shield_outlined,
                                    title: "Confianza & Seguridad",
                                    description:
                                        "Protección de datos industriales y transparencia operativa con control biométrico para todos los roles del sistema.",
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _buildSpecificObjectivesCard(),
                            const SizedBox(height: 40),
                            _buildValueCard(
                              icon: Icons.verified_outlined,
                              title: "Garantía de Calidad",
                              description:
                                  "Procesos estandarizados bajo métricas estrictas para asegurar la máxima pureza y consistencia del material reutilizado.",
                            ),
                            const SizedBox(height: 32),
                            _buildValueCard(
                              icon: Icons.shield_outlined,
                              title: "Confianza & Seguridad",
                              description:
                                  "Protección de datos industriales y transparencia operativa con control biométrico para todos los roles del sistema.",
                            ),
                          ],
                        );
                },
              ),
              const SizedBox(height: 50),
              LayoutBuilder(
                builder: (context, constraints) {
                  bool isWide = constraints.maxWidth > 850;
                  return isWide
                      ? Row(
                          children: [
                            Expanded(
                              child: _buildSectionCard(
                                icon: Icons.psychology_outlined,
                                title: "Innovación & Tecnología",
                                text:
                                    "Aplicamos algoritmos avanzados y trazabilidad inteligente en tiempo real para optimizar los ciclos de transformación plástica.",
                              ),
                            ),
                            const SizedBox(width: 40),
                            Expanded(
                              child: _buildSectionCard(
                                icon: Icons.eco_outlined,
                                title: "Sustentabilidad Activa",
                                text:
                                    "Impulsamos la economía circular reduciendo significativamente la huella de carbono y el desperdicio industrial en planta.",
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _buildSectionCard(
                              icon: Icons.psychology_outlined,
                              title: "Innovación & Tecnología",
                              text:
                                  "Aplicamos algoritmos avanzados y trazabilidad inteligente en tiempo real para optimizar los ciclos de transformación plástica.",
                            ),
                            const SizedBox(height: 40),
                            _buildSectionCard(
                              icon: Icons.eco_outlined,
                              title: "Sustentabilidad Activa",
                              text:
                                  "Impulsamos la economía circular reduciendo significativamente la huella de carbono y el desperdicio industrial en planta.",
                            ),
                          ],
                        );
                },
              ),
              const SizedBox(height: 50),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 30,
                ),
                decoration: BoxDecoration(
                  color: neonPurple.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: neonPurple.withOpacity(0.35)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.precision_manufacturing_outlined,
                      color: neonPurple,
                      size: 24,
                    ),
                    SizedBox(width: 20),
                    Text(
                      "ECO-REFILL  •  TECNOLOGÍA Y RECICLAJE INTELIGENTE EN FLUIDOS 3D",
                      style: TextStyle(
                        color: neonPurple,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMissionCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardBg.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: neonPurple.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: neonPurple.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rocket_launch_outlined, color: neonPurple, size: 32),
              SizedBox(width: 20),
              Text(
                "Misión",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Text(
            "Liderar la transformación tecnológica del sector de reciclaje, automatizando el control de procesos e inventarios con trazabilidad precisa y autenticación biométrica de máxima seguridad.",
            style: TextStyle(
              color: Color(0xFFE2D4F0),
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisionCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardBg.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: neonPurple.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: neonPurple.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.remove_red_eye_outlined, color: neonPurple, size: 32),
              SizedBox(width: 14),
              Text(
                "Visión",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Text(
            "Ser el estándar global de software industrial para la economía circular, reconocidos por impulsar plantas de tratamiento inteligente sostenibles y eficientes para el año 2030.",
            style: TextStyle(
              color: Color(0xFFE2D4F0),
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralObjectiveCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardBg.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: neonPurple.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(color: neonPurple.withOpacity(0.2), blurRadius: 20),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.track_changes_outlined, color: neonPurple, size: 30),
              SizedBox(width: 12),
              Text(
                "OBJETIVO GENERAL",
                style: TextStyle(
                  color: neonPurple,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 18),
          Text(
            "Proporcionar una plataforma digital centralizada e intuitiva que gestione el flujo completo de reciclaje de plásticos, garantizando un control riguroso del personal, optimización de tiempos y reducción de desperdicios en planta.",
            style: TextStyle(
              color: Color(0xFFE2D4F0),
              fontSize: 16,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecificObjectivesCard() {
    final objectives = [
      "Implementar módulos de registro y autenticación biométrica mediante reconocimiento facial.",
      "Digitalizar el inventario de insumos, clasificación de plásticos y materiales procesados.",
      "Ofrecer un dashboard en tiempo real con analítica detallada para la toma de decisiones estratégicas.",
      "Optimizar los tiempos de respuesta ante fallos en líneas de extrusión y procesamiento.",
    ];

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardBg.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: neonPurple.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.fact_check_outlined, color: neonPurple, size: 28),
              SizedBox(width: 12),
              Text(
                "Objetivos Específicos",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...objectives.map(
            (obj) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: neonPurple,
                    size: 20,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      obj,
                      style: const TextStyle(
                        color: Color(0xFFE2D4F0),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF200E36),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: neonPurple.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: neonPurple, size: 26),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFC084FC),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFFE2D4F0),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cardBg.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: neonPurple.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: neonPurple, size: 28),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFFE2D4F0),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
