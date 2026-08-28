import 'dart:math' as math;
import 'package:flutter/material.dart';

class ProcesoFilamentoAnimation extends StatefulWidget {
  const ProcesoFilamentoAnimation({super.key});

  @override
  State<ProcesoFilamentoAnimation> createState() =>
      _ProcesoFilamentoAnimationState();
}

class _ProcesoFilamentoAnimationState
    extends State<ProcesoFilamentoAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );

    // Avanza una sola vez y se detiene al llegar a la última etapa
    // (Filamento 3D), sin volver a repetir (sin loop).
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.stop();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Pantallas angostas (celular dentro del modal) usan textos y
        // espaciados más compactos para que nada se corte ni se monte.
        final bool compact = constraints.maxWidth < 380;

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF9C4DFF).withOpacity(0.45),
                ),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF13091D),
                    Color(0xFF090510),
                    Color(0xFF160820),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9C4DFF).withOpacity(0.12),
                    blurRadius: 35,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(compact ? 16 : 28),
                child: Column(
                  children: [
                    Text(
                      'ASÍ CONVERTIMOS EL PLÁSTICO EN FILAMENTO 3D',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 15 : 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Del residuo a la innovación',
                      style: TextStyle(
                        color: const Color(0xFFB86CFF).withOpacity(0.9),
                        fontSize: compact ? 12 : 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    SizedBox(height: compact ? 16 : 28),

                    Expanded(
                      child: CustomPaint(
                        painter: _ProcesoPainter(
                          progress: _controller.value,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),

                    SizedBox(height: compact ? 12 : 20),

                    _buildBottomInfo(compact: compact),

                    const SizedBox(height: 10),

                    Text(
                      'Dando nueva vida al plástico, creando un mejor futuro. ♻',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: compact ? 11 : 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomInfo({required bool compact}) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: compact ? 18 : 35,
      runSpacing: 8,
      children: [
        _infoItem(
          Icons.recycling,
          'Reciclar',
          compact: compact,
        ),
        _infoItem(
          Icons.settings,
          'Transformar',
          compact: compact,
        ),
        _infoItem(
          Icons.print,
          'Crear',
          compact: compact,
        ),
      ],
    );
  }

  Widget _infoItem(IconData icon, String text, {required bool compact}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: const Color(0xFFA855F7),
          size: compact ? 16 : 20,
        ),
        const SizedBox(width: 7),
        Text(
          text,
          style: TextStyle(
            color: Colors.white70,
            fontSize: compact ? 11.5 : 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// PAINTER PRINCIPAL
// ============================================================

class _ProcesoPainter extends CustomPainter {
  final double progress;

  _ProcesoPainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final double centerY = h * 0.52;

    // 🔹 Antes cada etapa (círculo, máquina, engranajes) y su título se
    // dibujaban con tamaños absolutos en píxeles, pensados para el ancho
    // de escritorio (~540px). En celular el ancho real del lienzo baja a
    // ~250-300px, pero los tamaños seguían siendo los mismos, así que los
    // 5 íconos y sus títulos quedaban unos encima de otros. Ahora todo se
    // escala según el ancho disponible: `baseScale` reduce el tamaño de
    // las máquinas/íconos, y `textScale` (con un piso más alto para que
    // siga siendo legible) reduce los títulos.
    final double baseScale = (w / 540).clamp(0.42, 1.0);
    final double textScale = (w / 540).clamp(0.62, 1.0);

    final List<double> positions = [
      w * 0.10,
      w * 0.30,
      w * 0.50,
      w * 0.70,
      w * 0.90,
    ];

    // Fondo con partículas
    _drawBackgroundParticles(canvas, size);

    // Línea principal
    _drawConnectionLine(
      canvas,
      positions,
      centerY,
      baseScale,
    );

    // Progreso animado sobre la línea
    _drawProgressLine(
      canvas,
      positions,
      centerY,
      baseScale,
    );

    // Etapas: cada una se agranda y se ilumina más mientras la línea de
    // progreso pasa por ella (efecto de "foco" viajero).
    _drawStageScaled(
      canvas,
      Offset(positions[0], centerY),
      _stageActivation(0, positions.length),
      baseScale,
      (c, center, activation) => _drawPlasticStage(c, center, activation),
    );

    _drawStageScaled(
      canvas,
      Offset(positions[1], centerY),
      _stageActivation(1, positions.length),
      baseScale,
      (c, center, activation) => _drawShredderStage(c, center, activation),
    );

    _drawStageScaled(
      canvas,
      Offset(positions[2], centerY),
      _stageActivation(2, positions.length),
      baseScale,
      (c, center, activation) => _drawExtruderStage(c, center, activation),
    );

    _drawStageScaled(
      canvas,
      Offset(positions[3], centerY),
      _stageActivation(3, positions.length),
      baseScale,
      (c, center, activation) => _drawCoolingStage(c, center, activation),
    );

    _drawStageScaled(
      canvas,
      Offset(positions[4], centerY),
      _stageActivation(4, positions.length),
      baseScale,
      (c, center, activation) => _drawSpoolStage(c, center, activation),
    );

    // Partículas que viajan por el proceso
    _drawMovingParticles(
      canvas,
      positions,
      centerY,
    );

    // Títulos
    _drawStageTitle(
      canvas,
      '1',
      'PLÁSTICO',
      Offset(positions[0], 20),
      textScale,
    );

    _drawStageTitle(
      canvas,
      '2',
      'TRITURACIÓN',
      Offset(positions[1], 20),
      textScale,
    );

    _drawStageTitle(
      canvas,
      '3',
      'EXTRUSIÓN',
      Offset(positions[2], 20),
      textScale,
    );

    _drawStageTitle(
      canvas,
      '4',
      'ENFRIAMIENTO',
      Offset(positions[3], 20),
      textScale,
    );

    _drawStageTitle(
      canvas,
      '5',
      'FILAMENTO 3D',
      Offset(positions[4], 20),
      textScale,
    );
  }

  // ============================================================
  // ACTIVACIÓN DE ETAPA (agrandar + iluminar al pasar por ella)
  // ============================================================

  // Devuelve un valor 0..1: qué tan "activa" está la etapa [index] según
  // dónde va la línea de progreso. Llega a 1 cuando la línea está justo
  // sobre esa etapa y decae suavemente hacia los lados.
  double _stageActivation(int index, int totalStages) {
    final double stageT = index / (totalStages - 1);
    const double window = 0.16;
    final double distance = (progress - stageT).abs();
    final double closeness = (1 - (distance / window)).clamp(0.0, 1.0);
    // Suavizado tipo "ease" para que el crecimiento no se sienta lineal.
    return closeness * closeness * (3 - 2 * closeness);
  }

  // Envuelve el dibujo de una etapa aplicando una escala centrada en su
  // posición: 1.0 en reposo, hasta 1.28 cuando está totalmente activa.
  void _drawStageScaled(
    Canvas canvas,
    Offset center,
    double activation,
    double baseScale,
    void Function(Canvas canvas, Offset center, double activation) draw,
  ) {
    final double scale = baseScale * (1.0 + activation * 0.28);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    canvas.translate(-center.dx, -center.dy);

    draw(canvas, center, activation);

    canvas.restore();
  }

  // ============================================================
  // FONDO
  // ============================================================

  void _drawBackgroundParticles(Canvas canvas, Size size) {
    final paint = Paint();

    for (int i = 0; i < 35; i++) {
      final double x =
          ((i * 73) % size.width) + math.sin(progress * math.pi * 2 + i) * 4;

      final double y =
          ((i * 41) % size.height) +
              math.cos(progress * math.pi * 2 + i) * 3;

      paint.color = const Color(0xFFA855F7).withOpacity(0.08);

      canvas.drawCircle(
        Offset(x, y),
        1.5,
        paint,
      );
    }
  }

  // ============================================================
  // LÍNEA DE CONEXIÓN
  // ============================================================

  void _drawConnectionLine(
    Canvas canvas,
    List<double> positions,
    double y,
    double baseScale,
  ) {
    final paint = Paint()
      ..color = const Color(0xFF4C1D70).withOpacity(0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final double gap = 35 * baseScale;

    for (int i = 0; i < positions.length - 1; i++) {
      canvas.drawLine(
        Offset(positions[i] + gap, y),
        Offset(positions[i + 1] - gap, y),
        paint,
      );
    }
  }

  void _drawProgressLine(
    Canvas canvas,
    List<double> positions,
    double y,
    double baseScale,
  ) {
    final paint = Paint()
      ..color = const Color(0xFFA855F7)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        5,
      );

    final double gap = 35 * baseScale;
    final double totalStart = positions.first + gap;
    final double totalEnd = positions.last - gap;
    final double currentX =
        totalStart + (totalEnd - totalStart) * progress;

    canvas.drawLine(
      Offset(totalStart, y),
      Offset(currentX, y),
      paint,
    );
  }

  // ============================================================
  // PLÁSTICO
  // ============================================================

  void _drawPlasticStage(
    Canvas canvas,
    Offset center,
    double activation,
  ) {
    _drawStageCircle(canvas, center, activation);

    final paint = Paint()
      ..color = const Color(0xFF5B21B6)
      ..style = PaintingStyle.fill;

    // Botella 1
    final bottle1 = Path();

    bottle1.moveTo(
      center.dx - 20,
      center.dy - 27,
    );

    bottle1.lineTo(
      center.dx - 10,
      center.dy - 27,
    );

    bottle1.lineTo(
      center.dx - 10,
      center.dy - 21,
    );

    bottle1.lineTo(
      center.dx - 6,
      center.dy - 18,
    );

    bottle1.lineTo(
      center.dx - 6,
      center.dy + 21,
    );

    bottle1.quadraticBezierTo(
      center.dx - 15,
      center.dy + 28,
      center.dx - 24,
      center.dy + 21,
    );

    bottle1.lineTo(
      center.dx - 24,
      center.dy - 18,
    );

    bottle1.lineTo(
      center.dx - 20,
      center.dy - 21,
    );

    bottle1.close();

    canvas.drawPath(bottle1, paint);

    // Botella 2
    final paint2 = Paint()
      ..color = const Color(0xFF9333EA)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(
            center.dx + 12,
            center.dy + 7,
          ),
          width: 24,
          height: 44,
        ),
        const Radius.circular(6),
      ),
      paint2,
    );

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(
          center.dx + 12,
          center.dy - 19,
        ),
        width: 10,
        height: 8,
      ),
      paint2,
    );
  }

  // ============================================================
  // TRITURADORA
  // ============================================================

  void _drawShredderStage(
    Canvas canvas,
    Offset center,
    double activation,
  ) {
    _drawStageCircle(canvas, center, activation);

    final machinePaint = Paint()
      ..color = const Color(0xFF7E22CE)
      ..style = PaintingStyle.fill;

    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(
          center.dx,
          center.dy + 8,
        ),
        width: 58,
        height: 48,
      ),
      const Radius.circular(8),
    );

    canvas.drawRRect(body, machinePaint);

    // Tolva
    final hopper = Path();

    hopper.moveTo(
      center.dx - 25,
      center.dy - 27,
    );

    hopper.lineTo(
      center.dx + 25,
      center.dy - 27,
    );

    hopper.lineTo(
      center.dx + 14,
      center.dy - 5,
    );

    hopper.lineTo(
      center.dx - 14,
      center.dy - 5,
    );

    hopper.close();

    canvas.drawPath(hopper, machinePaint);

    // Engranajes
    _drawGear(
      canvas,
      Offset(
        center.dx - 12,
        center.dy + 11,
      ),
      12,
      progress * math.pi * 4,
    );

    _drawGear(
      canvas,
      Offset(
        center.dx + 13,
        center.dy + 11,
      ),
      12,
      -progress * math.pi * 4,
    );

    // Partículas trituradas
    final particlePaint = Paint()
      ..color = const Color(0xFFD8B4FE);

    for (int i = 0; i < 5; i++) {
      final double x =
          center.dx - 20 + ((progress * 30 + i * 12) % 40);

      final double y =
          center.dy + 30 + (i % 3) * 5;

      canvas.drawCircle(
        Offset(x, y),
        2.5,
        particlePaint,
      );
    }
  }

  // ============================================================
  // EXTRUSORA
  // ============================================================

  void _drawExtruderStage(
    Canvas canvas,
    Offset center,
    double activation,
  ) {
    _drawStageCircle(canvas, center, activation);

    final bodyPaint = Paint()
      ..color = const Color(0xFF6D28D9)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(
            center.dx,
            center.dy + 4,
          ),
          width: 62,
          height: 43,
        ),
        const Radius.circular(7),
      ),
      bodyPaint,
    );

    // Tolva
    final hopper = Path();

    hopper.moveTo(
      center.dx - 19,
      center.dy - 28,
    );

    hopper.lineTo(
      center.dx + 19,
      center.dy - 28,
    );

    hopper.lineTo(
      center.dx + 12,
      center.dy - 7,
    );

    hopper.lineTo(
      center.dx - 12,
      center.dy - 7,
    );

    hopper.close();

    canvas.drawPath(
      hopper,
      Paint()
        ..color = const Color(0xFFA855F7)
        ..style = PaintingStyle.fill,
    );

    // Parte caliente
    final heatPaint = Paint()
      ..color = Color.lerp(
        const Color(0xFF7E22CE),
        const Color(0xFFFF9D00),
        (math.sin(progress * math.pi * 4) + 1) / 2,
      )!
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(
        center.dx + 29,
        center.dy + 4,
      ),
      8,
      heatPaint,
    );

    // Filamento saliendo
    final filamentPaint = Paint()
      ..color = const Color(0xFFE9D5FF)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final filamentPath = Path();

    filamentPath.moveTo(
      center.dx + 36,
      center.dy + 4,
    );

    filamentPath.cubicTo(
      center.dx + 48,
      center.dy + 4,
      center.dx + 50,
      center.dy + 18,
      center.dx + 62,
      center.dy + 18,
    );

    canvas.drawPath(
      filamentPath,
      filamentPaint,
    );

    // Brillo (más intenso mientras la etapa está activa)
    final glowPaint = Paint()
      ..color = const Color(0xFFFFA500).withOpacity(0.3 + activation * 0.4)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        12 + activation * 6,
      );

    canvas.drawCircle(
      Offset(
        center.dx + 29,
        center.dy + 4,
      ),
      12,
      glowPaint,
    );
  }

  // ============================================================
  // ENFRIAMIENTO
  // ============================================================

  void _drawCoolingStage(
    Canvas canvas,
    Offset center,
    double activation,
  ) {
    _drawStageCircle(canvas, center, activation);

    final machinePaint = Paint()
      ..color = const Color(0xFF6D28D9)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(
            center.dx,
            center.dy + 18,
          ),
          width: 70,
          height: 28,
        ),
        const Radius.circular(7),
      ),
      machinePaint,
    );

    // Ventiladores
    for (int i = -1; i <= 1; i++) {
      final fanCenter = Offset(
        center.dx + i * 22,
        center.dy - 10,
      );

      _drawFan(
        canvas,
        fanCenter,
        13,
        progress * math.pi * 4,
      );
    }

    // Agua / partículas
    final waterPaint = Paint()
      ..color = const Color(0xFF60A5FA).withOpacity(0.8);

    for (int i = 0; i < 7; i++) {
      final double x =
          center.dx - 28 + ((i * 13) % 56);

      final double y =
          center.dy + 10 + ((progress * 35 + i * 7) % 20);

      canvas.drawCircle(
        Offset(x, y),
        1.7,
        waterPaint,
      );
    }
  }

  // ============================================================
  // BOBINA
  // ============================================================

  void _drawSpoolStage(
    Canvas canvas,
    Offset center,
    double activation,
  ) {
    _drawStageCircle(canvas, center, activation);

    canvas.save();

    canvas.translate(
      center.dx,
      center.dy,
    );

    canvas.rotate(
      progress * math.pi * 2,
    );

    final spoolPaint = Paint()
      ..color = const Color(0xFFA855F7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: 62,
        height: 70,
      ),
      spoolPaint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: 28,
        height: 34,
      ),
      Paint()
        ..color = const Color(0xFFE9D5FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );

    // Líneas de filamento
    final filamentPaint = Paint()
      ..color = const Color(0xFF7E22CE)
      ..strokeWidth = 2;

    for (int i = -2; i <= 2; i++) {
      canvas.drawLine(
        Offset(
          -25,
          i * 9,
        ),
        Offset(
          25,
          i * 9,
        ),
        filamentPaint,
      );
    }

    canvas.restore();

    // Brillo (más intenso mientras la etapa está activa; se queda
    // encendido al terminar, ya que es la última etapa del proceso)
    final glowPaint = Paint()
      ..color = const Color(0xFFA855F7).withOpacity(0.25 + activation * 0.45)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        18 + activation * 10,
      );

    canvas.drawCircle(
      center,
      40,
      glowPaint,
    );
  }

  // ============================================================
  // CÍRCULOS DE ETAPA
  // ============================================================

  void _drawStageCircle(
    Canvas canvas,
    Offset center,
    double activation,
  ) {
    // Halo exterior: crece y se vuelve más intenso mientras la línea de
    // progreso pasa por esta etapa.
    final glowPaint = Paint()
      ..color = const Color(0xFFA855F7).withOpacity(0.18 + activation * 0.42)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        18 + activation * 14,
      );

    canvas.drawCircle(
      center,
      43 + activation * 10,
      glowPaint,
    );

    final circlePaint = Paint()
      ..color = const Color(0xFF12071B)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      center,
      39,
      circlePaint,
    );

    final borderPaint = Paint()
      ..color = Color.lerp(
        const Color(0xFFA855F7).withOpacity(0.8),
        const Color(0xFFE9D5FF),
        activation,
      )!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 + activation * 1.5;

    canvas.drawCircle(
      center,
      39,
      borderPaint,
    );
  }

  // ============================================================
  // ENGRANAJE
  // ============================================================

  void _drawGear(
    Canvas canvas,
    Offset center,
    double radius,
    double rotation,
  ) {
    canvas.save();

    canvas.translate(
      center.dx,
      center.dy,
    );

    canvas.rotate(rotation);

    final paint = Paint()
      ..color = const Color(0xFFE9D5FF)
      ..style = PaintingStyle.fill;

    final path = Path();

    const int teeth = 10;

    for (int i = 0; i < teeth * 2; i++) {
      final double angle =
          i * math.pi / teeth;

      final double r =
          i.isEven ? radius : radius * 0.75;

      final point = Offset(
        math.cos(angle) * r,
        math.sin(angle) * r,
      );

      if (i == 0) {
        path.moveTo(
          point.dx,
          point.dy,
        );
      } else {
        path.lineTo(
          point.dx,
          point.dy,
        );
      }
    }

    path.close();

    canvas.drawPath(
      path,
      paint,
    );

    canvas.drawCircle(
      Offset.zero,
      radius * 0.28,
      Paint()
        ..color = const Color(0xFF7E22CE),
    );

    canvas.restore();
  }

  // ============================================================
  // VENTILADOR
  // ============================================================

  void _drawFan(
    Canvas canvas,
    Offset center,
    double radius,
    double rotation,
  ) {
    canvas.save();

    canvas.translate(
      center.dx,
      center.dy,
    );

    canvas.rotate(rotation);

    final bladePaint = Paint()
      ..color = const Color(0xFFD8B4FE)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 3; i++) {
      canvas.save();

      canvas.rotate(
        i * (math.pi * 2 / 3),
      );

      final blade = Path();

      blade.moveTo(0, 0);

      blade.quadraticBezierTo(
        radius * 0.3,
        -radius * 0.8,
        radius,
        -radius * 0.3,
      );

      blade.quadraticBezierTo(
        radius * 0.45,
        -radius * 0.1,
        0,
        0,
      );

      canvas.drawPath(
        blade,
        bladePaint,
      );

      canvas.restore();
    }

    canvas.drawCircle(
      Offset.zero,
      4,
      Paint()
        ..color = const Color(0xFFA855F7),
    );

    canvas.restore();
  }

  // ============================================================
  // PARTÍCULAS EN MOVIMIENTO
  // ============================================================

  void _drawMovingParticles(
    Canvas canvas,
    List<double> positions,
    double y,
  ) {
    final paint = Paint()
      ..color = const Color(0xFFE9D5FF);

    final double start = positions.first + 40;
    final double end = positions.last - 40;

    for (int i = 0; i < 10; i++) {
      final double particleProgress =
          (progress + i * 0.1) % 1;

      final double x =
          start + (end - start) * particleProgress;

      final double wave =
          math.sin(
                particleProgress * math.pi * 8,
              ) *
              5;

      canvas.drawCircle(
        Offset(
          x,
          y + wave,
        ),
        2.5,
        paint,
      );
    }
  }

  // ============================================================
  // TÍTULOS
  // ============================================================

  void _drawStageTitle(
    Canvas canvas,
    String number,
    String title,
    Offset position,
    double textScale,
  ) {
    final double numberFontSize = 12 * textScale;
    final double titleFontSize = 11 * textScale;
    final double numberCircleRadius = 13 * textScale;

    final textPainter = TextPainter(
      text: TextSpan(
        text: number,
        style: TextStyle(
          color: const Color(0xFFB86CFF),
          fontSize: numberFontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    canvas.drawCircle(
      Offset(
        position.dx,
        position.dy + 8 * textScale,
      ),
      numberCircleRadius,
      Paint()
        ..color = const Color(0xFF7E22CE),
    );

    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy + 2 * textScale,
      ),
    );

    final titlePainter = TextPainter(
      text: TextSpan(
        text: title,
        style: TextStyle(
          color: Colors.white,
          fontSize: titleFontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // 🔹 El ancho máximo del título se reduce junto con el resto de la
    // escala de texto, para que no invada el título de la etapa vecina
    // en pantallas angostas.
    titlePainter.layout(
      maxWidth: 100 * textScale,
    );

    titlePainter.paint(
      canvas,
      Offset(
        position.dx - titlePainter.width / 2,
        position.dy + 27 * textScale,
      ),
    );
  }

  @override
  bool shouldRepaint(
    covariant _ProcesoPainter oldDelegate,
  ) {
    return oldDelegate.progress != progress;
  }
}
