import 'package:flutter/material.dart';
import 'feed_publico.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const Color neonPurple = Color(0xFFA855F7);
  static const Color darkBg = Color(0xFF0F0716);
  static const Color cardBg = Color(0xFF170C28);
  static const Color panelBg = Color(0xFF120A20);
  static const Color panelBorder = Color(0xFF241534);
  static const Color green = Color(0xFF34D399);
  static const Color cyan = Color(0xFF22D3EE);
  static const Color greyText = Color(0xFFB6AFC4);

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _porQueKey = GlobalKey();

  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: 0, end: 14).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToPorQue() {
    final ctx = _porQueKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _irAProductos() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FeedPublicoScreen(desdeLogin: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // 🔹 Home es la pantalla principal: nunca debe mostrar una flecha
        // de "atrás" automática, sin importar cómo se haya llegado a ella.
        automaticallyImplyLeading: false,
        titleSpacing: 12,
        title: LayoutBuilder(
          builder: (context, constraints) {
            final bool isNarrow = MediaQuery.of(context).size.width < 480;
            return Row(
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
                Text(
                  'ECO-REFILL',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    fontSize: isNarrow ? 17 : 24,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          Builder(
            builder: (context) {
              final bool isNarrow = MediaQuery.of(context).size.width < 480;
              if (isNarrow) {
                return IconButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  icon: const Icon(Icons.login_rounded, color: neonPurple),
                  tooltip: "Iniciar Sesión",
                );
              }
              return TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                icon: const Icon(Icons.login_rounded, color: neonPurple, size: 18),
                label: const Text(
                  "Iniciar Sesión",
                  style: TextStyle(color: neonPurple, fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [darkBg, Color(0xFF150826), Color(0xFF1B0B2E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width < 700 ? 18 : 48,
            vertical: 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHero(context),
              const SizedBox(height: 48),
              _buildCalidadYProcesoRow(context),
              const SizedBox(height: 36),
              _buildPorQuePanel(context, key: _porQueKey),
            ],
          ),
        ),
      ),
    );
  }

  // ================= CALIDAD + PROCESO =================
  Widget _buildCalidadYProcesoRow(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth > 1000;

        final calidad = _buildCalidadPanel(isWide: isWide);
        final proceso = _buildProcesoPanel(isWide: isWide);

        if (isWide) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 4, child: calidad),
                const SizedBox(width: 24),
                Expanded(flex: 6, child: proceso),
              ],
            ),
          );
        }

        return Column(
          children: [
            calidad,
            const SizedBox(height: 24),
            proceso,
          ],
        );
      },
    );
  }

  Widget _buildCalidadPanel({required bool isWide}) {
    final bullets = [
      _CalidadBullet(
        title: "Diámetro preciso",
        subtitle: "1.75mm ± 0.02mm",
      ),
      _CalidadBullet(
        title: "Acabado uniforme",
        subtitle: "Sin burbujas ni impurezas",
      ),
      _CalidadBullet(
        title: "Alta compatibilidad",
        subtitle: "Funciona con la mayoría de impresoras 3D",
      ),
      _CalidadBullet(
        title: "Colores inspirados en la naturaleza",
        subtitle: null,
      ),
    ];

    final colorDots = [green, neonPurple, cyan, Color(0xFFF472B6), Color(0xFFFBBF24)];

    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: panelBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                    children: [
                      const TextSpan(text: "Calidad que ", style: TextStyle(color: Colors.white)),
                      TextSpan(text: "se imprime", style: TextStyle(color: green)),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                for (int i = 0; i < bullets.length; i++) ...[
                  _buildCalidadBulletRow(bullets[i]),
                  if (i != bullets.length - 1) const SizedBox(height: 18),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: colorDots
                      .map((c) => Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: c.withOpacity(0.6), blurRadius: 6),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: green.withOpacity(0.35), blurRadius: 60, spreadRadius: 4),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/Filamento3D_verde.png',
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1F16).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: green.withOpacity(0.4)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.recycling_rounded, color: green, size: 18),
                        const SizedBox(height: 2),
                        Text(
                          "100%",
                          style: TextStyle(color: green, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        const Text(
                          "Reciclado",
                          style: TextStyle(color: greyText, fontSize: 9.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalidadBulletRow(_CalidadBullet bullet) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.diamond_outlined, color: neonPurple, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bullet.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
              if (bullet.subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  bullet.subtitle!,
                  style: const TextStyle(color: greyText, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProcesoPanel({required bool isWide}) {
    final steps = [
      _ProcesoStep(
        numero: "1",
        icon: Icons.delete_outline_rounded,
        titulo: "Recolectamos",
        descripcion: "Residuos plásticos seleccionados.",
        color: greyText,
      ),
      _ProcesoStep(
        numero: "2",
        icon: Icons.precision_manufacturing_outlined,
        titulo: "Procesamos",
        descripcion: "Limpieza, trituración y clasificación.",
        color: cyan,
      ),
      _ProcesoStep(
        numero: "3",
        icon: Icons.settings_input_component_outlined,
        titulo: "Transformamos",
        descripcion: "Extrusión de precisión y enfriamiento.",
        color: neonPurple,
      ),
      _ProcesoStep(
        numero: "4",
        icon: Icons.album_outlined,
        titulo: "Creamos",
        descripcion: "Filamento 3D listo para dar vida a tus ideas.",
        color: green,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              children: [
                const TextSpan(text: "De residuo a filamento: ", style: TextStyle(color: Colors.white)),
                TextSpan(text: "nuestro proceso", style: TextStyle(color: neonPurple)),
              ],
            ),
          ),
          const SizedBox(height: 26),
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < steps.length; i++) ...[
                  Expanded(child: _buildProcesoStepWidget(steps[i])),
                  if (i != steps.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 26),
                      child: Icon(Icons.chevron_right_rounded, color: Colors.white24),
                    ),
                ],
              ],
            )
          else
            Column(
              children: [
                for (int i = 0; i < steps.length; i++) ...[
                  _buildProcesoStepWidget(steps[i]),
                  if (i != steps.length - 1) const SizedBox(height: 20),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildProcesoStepWidget(_ProcesoStep step) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1028),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: step.color.withOpacity(0.4)),
          ),
          child: Icon(step.icon, color: step.color, size: 26),
        ),
        const SizedBox(height: 12),
        Text(
          "${step.numero}. ${step.titulo}",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          step.descripcion,
          style: const TextStyle(color: greyText, fontSize: 12, height: 1.4),
        ),
      ],
    );
  }

  // ================= HERO =================
  Widget _buildHero(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth > 950;

        final textColumn = _buildHeroText(isWide: isWide);
        final visual = _buildHeroVisual(isWide: isWide);

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 5, child: textColumn),
              const SizedBox(width: 40),
              Expanded(flex: 6, child: visual),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            textColumn,
            const SizedBox(height: 40),
            visual,
          ],
        );
      },
    );
  }

  Widget _buildHeroText({required bool isWide}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge: Sostenible • Innovador • Responsable
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: green.withOpacity(0.08),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: green.withOpacity(0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.eco_rounded, color: green, size: 15),
              const SizedBox(width: 8),
              Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                  children: [
                    TextSpan(text: "Sostenible", style: TextStyle(color: green)),
                    TextSpan(text: "  •  ", style: TextStyle(color: greyText)),
                    TextSpan(text: "Innovador", style: TextStyle(color: Colors.white70)),
                    TextSpan(text: "  •  ", style: TextStyle(color: greyText)),
                    TextSpan(text: "Responsable", style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // Título grande
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: "Del residuo\nal ",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              TextSpan(
                text: "futuro.",
                style: TextStyle(
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: [green, cyan, neonPurple],
                    ).createShader(const Rect.fromLTWH(0, 0, 260, 70)),
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
            ],
          ),
          style: TextStyle(fontSize: isWide ? 54 : 40),
        ),
        const SizedBox(height: 20),

        // Subtítulo
        Text.rich(
          TextSpan(
            style: const TextStyle(
              color: greyText,
              fontSize: 16.5,
              height: 1.5,
            ),
            children: const [
              TextSpan(
                text:
                    "Transformamos plásticos reciclados en materia prima de alta calidad para impulsar una ",
              ),
              TextSpan(
                text: "producción sostenible.",
                style: TextStyle(
                  color: neonPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),

        // Botones
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            _PrimaryButton(
              icon: Icons.inventory_2_outlined,
              label: "Explorar publicaciones",
              onTap: _irAProductos,
            ),
            _OutlinedButton(
              icon: Icons.eco_outlined,
              label: "Conoce nuestro impacto",
              onTap: _scrollToPorQue,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroVisual({required bool isWide}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // En pantallas angostas el círculo se ajusta al ancho disponible
        // para no desbordar en celulares pequeños.
        final double maxDiameter = isWide ? 460 : 320;
        final double diameter = constraints.maxWidth.isFinite
            ? maxDiameter.clamp(0, constraints.maxWidth)
            : maxDiameter;
        final double imageWidth = diameter * (isWide ? 420 / 460 : 280 / 320);

        final image = AnimatedBuilder(
          animation: _floatController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -_floatAnimation.value / 2 + 7),
              child: child,
            );
          },
          child: Container(
            width: diameter,
            height: diameter,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: neonPurple.withOpacity(0.45),
                  blurRadius: 120,
                  spreadRadius: 14,
                ),
                BoxShadow(
                  color: cyan.withOpacity(0.25),
                  blurRadius: 90,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/Filamento3D.png',
              width: imageWidth,
            ),
          ),
        );

        return _buildHeroVisualLayout(isWide: isWide, image: image);
      },
    );
  }

  Widget _buildHeroVisualLayout({required bool isWide, required Widget image}) {

    final badges = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoBadge(
          icon: Icons.recycling_rounded,
          iconColor: green,
          title: "Plástico reciclado",
          value: "100%",
        ),
        const SizedBox(height: 14),
        _InfoBadge(
          icon: Icons.workspace_premium_outlined,
          iconColor: neonPurple,
          title: "Calidad premium",
          value: "Garantizada",
        ),
        const SizedBox(height: 14),
        _InfoBadge(
          icon: Icons.eco_rounded,
          iconColor: green,
          title: "Impacto positivo",
          value: "Real",
        ),
      ],
    );

    if (isWide) {
      return SizedBox(
        height: 480,
        child: Stack(
          alignment: Alignment.center,
          children: [
            image,
            Positioned(
              right: 0,
              child: SizedBox(width: 190, child: badges),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Center(child: image),
        const SizedBox(height: 24),
        badges,
      ],
    );
  }

  // ================= ¿POR QUÉ ELEGIR? =================
  Widget _buildPorQuePanel(BuildContext context, {Key? key}) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: panelBorder),
      ),
      child: Column(
        children: [
          Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              children: [
                const TextSpan(text: "¿Por qué elegir ", style: TextStyle(color: Colors.white)),
                TextSpan(text: "ECO-REFILL", style: TextStyle(color: neonPurple)),
                const TextSpan(text: "?", style: TextStyle(color: Colors.white)),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth > 900;

              final items = [
                _buildFeatureItem(
                  icon: Icons.recycling_rounded,
                  iconColor: green,
                  title: "Sostenible",
                  text:
                      "Damos una segunda vida al plástico y reducimos la contaminación ambiental.",
                ),
                _buildFeatureItem(
                  icon: Icons.verified_outlined,
                  iconColor: neonPurple,
                  title: "Alta calidad",
                  text:
                      "Material resistente y con excelente consistencia para cada proceso.",
                ),
                _buildFeatureItem(
                  icon: Icons.devices_other_outlined,
                  iconColor: cyan,
                  title: "Compatibilidad",
                  text:
                      "Se adapta a la mayoría de procesos y equipos de producción.",
                ),
                _buildFeatureItem(
                  icon: Icons.eco_outlined,
                  iconColor: green,
                  title: "Impacto real",
                  text:
                      "Cada proceso apoya un modelo de economía circular.",
                ),
              ];

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: items[0]),
                    const SizedBox(width: 24),
                    Expanded(child: items[1]),
                    const SizedBox(width: 24),
                    Expanded(child: items[2]),
                    const SizedBox(width: 24),
                    Expanded(child: items[3]),
                  ],
                );
              }

              return Column(
                children: [
                  items[0],
                  const SizedBox(height: 26),
                  items[1],
                  const SizedBox(height: 26),
                  items[2],
                  const SizedBox(height: 26),
                  items[3],
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          Container(height: 1, color: panelBorder),
          const SizedBox(height: 28),
          _buildStatsRow(),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(color: iconColor.withOpacity(0.4)),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                text,
                style: const TextStyle(
                  color: greyText,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================= ESTADÍSTICAS (sin "productos disponibles") =================
  Widget _buildStatsRow() {
    final stats = [
      _StatItem(value: "12.5 Ton", label: "Plástico reciclado", color: cyan),
      _StatItem(value: "1.248", label: "Clientes satisfechos", color: neonPurple),
      _StatItem(value: "342", label: "Impresiones creadas", color: Colors.white),
      _StatItem(value: "98%", label: "Reducción de CO₂", color: green),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth > 700;

        if (isWide) {
          return Row(
            children: stats
                .map((s) => Expanded(child: _buildStatWidget(s)))
                .toList(),
          );
        }

        return Wrap(
          spacing: 24,
          runSpacing: 24,
          alignment: WrapAlignment.center,
          children: stats
              .map((s) => SizedBox(width: 150, child: _buildStatWidget(s)))
              .toList(),
        );
      },
    );
  }

  Widget _buildStatWidget(_StatItem s) {
    return Column(
      children: [
        Text(
          s.value,
          style: TextStyle(
            color: s.color,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          s.label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: greyText, fontSize: 12.5),
        ),
      ],
    );
  }
}

class _CalidadBullet {
  final String title;
  final String? subtitle;

  const _CalidadBullet({required this.title, this.subtitle});
}

class _ProcesoStep {
  final String numero;
  final IconData icon;
  final String titulo;
  final String descripcion;
  final Color color;

  const _ProcesoStep({
    required this.numero,
    required this.icon,
    required this.titulo,
    required this.descripcion,
    required this.color,
  });
}

class _StatItem {
  final String value;
  final String label;
  final Color color;

  const _StatItem({required this.value, required this.label, required this.color});
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  const _InfoBadge({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF150B26).withOpacity(0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: iconColor.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Color(0xFFB6AFC4), fontSize: 11),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: iconColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFA855F7).withOpacity(_hover ? 0.55 : 0.3),
                blurRadius: _hover ? 24 : 12,
                spreadRadius: _hover ? 1 : 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: Colors.white, size: 19),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlinedButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OutlinedButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_OutlinedButton> createState() => _OutlinedButtonState();
}

class _OutlinedButtonState extends State<_OutlinedButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          decoration: BoxDecoration(
            color: _hover ? Colors.white.withOpacity(0.06) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: Colors.white, size: 19),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


