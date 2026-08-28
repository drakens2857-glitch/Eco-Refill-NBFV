import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'gemini_config.dart';

/// Un mensaje dentro del chat de informes: puede ser del usuario o de la IA.
/// Cuando [esInforme] es true, el mensaje trae un informe en Markdown listo
/// para descargarse como PDF.
class MensajeChatIA {
  final String texto;
  final bool esUsuario;
  final bool esInforme;

  MensajeChatIA({
    required this.texto,
    required this.esUsuario,
    this.esInforme = false,
  });
}

/// Genera informes 100% desde el cliente Flutter, sin backend:
/// 1. Lee y agrega los datos de Firestore (ingresos, materiales, procesos).
/// 2. Arma un prompt en español con esos datos ya resumidos.
/// 3. Llama a la API gratuita de Gemini (Google AI Studio) para redactar
///    el informe en Markdown.
///
/// No requiere Cloud Functions ni el plan Blaze de Firebase: solo usa el
/// SDK normal de Firestore (funciona en el plan gratuito Spark).
class InformesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _detectarTipo(String mensaje) {
    final texto = mensaje.toLowerCase();
    if (texto.contains('ingreso')) return 'ingresos';
    if (texto.contains('material')) return 'materiales';
    if (texto.contains('proceso') || texto.contains('historial')) {
      return 'procesos';
    }
    return 'general';
  }

  Future<Map<String, dynamic>> _resumenIngresos() async {
    final snap = await _db.collection('ingresos').get();
    final porCategoria = <String, dynamic>{};
    int total = 0;
    final registros = <Map<String, dynamic>>[];

    for (final doc in snap.docs) {
      final d = doc.data();
      final categoria = (d['categoria'] ?? 'Sin categoría').toString();
      final color = (d['color'] ?? 'Sin color').toString();
      final cantidad = _aEntero(d['cantidad']);
      total += cantidad;

      porCategoria.putIfAbsent(
        categoria,
        () => {'total': 0, 'colores': <String, int>{}},
      );
      porCategoria[categoria]['total'] =
          (porCategoria[categoria]['total'] as int) + cantidad;
      final colores = porCategoria[categoria]['colores'] as Map<String, int>;
      colores[color] = (colores[color] ?? 0) + cantidad;

      registros.add({
        'categoria': categoria,
        'color': color,
        'cantidad': cantidad,
        'fecha': d['fecha'],
        'registradoPor': d['registradoPor'],
      });
    }

    registros.sort((a, b) {
      final fa = DateTime.tryParse(a['fecha']?.toString() ?? '') ?? DateTime(2000);
      final fb = DateTime.tryParse(b['fecha']?.toString() ?? '') ?? DateTime(2000);
      return fb.compareTo(fa);
    });

    return {
      'totalGeneralUnidades': total,
      'totalRegistros': snap.docs.length,
      'porCategoria': porCategoria,
      'ultimosRegistros': registros.take(20).toList(),
    };
  }

  Future<Map<String, dynamic>> _resumenMateriales() async {
    final snap = await _db.collection('materiales').get();
    final materiales = snap.docs.map((doc) {
      final d = doc.data();
      return {
        'nombre': d['nombre'],
        'color': d['color'],
        'grosor': d['grosor'],
        'flexibilidad': d['flexibilidad'],
        'resistencia': d['resistencia'],
        'familia': d['familia'],
        'cantidadUsada': d['cantidadUsada'],
      };
    }).toList();

    return {'totalMateriales': snap.docs.length, 'materiales': materiales};
  }

  Future<Map<String, dynamic>> _resumenProcesos() async {
    final activosSnap = await _db.collection('procesos').get();
    final historialSnap = await _db.collection('historial').get();

    final activos = <Map<String, dynamic>>[];
    final porFase = <String, int>{};
    for (final doc in activosSnap.docs) {
      final d = doc.data();
      final fase = (d['fase'] ?? 'Sin fase').toString();
      activos.add({
        'descripcion': d['descripcion'],
        'tipo': d['tipo'],
        'fase': d['fase'],
        'progreso': d['progreso'],
        'cantidad': d['cantidad'],
        'usuario': d['usuario'],
        'fecha': d['fecha'],
      });
      porFase[fase] = (porFase[fase] ?? 0) + 1;
    }

    final finalizados = <Map<String, dynamic>>[];
    int cantidadFinalizada = 0;
    for (final doc in historialSnap.docs) {
      final d = doc.data();
      cantidadFinalizada += _aEntero(d['cantidad']);
      finalizados.add({
        'descripcion': d['descripcion'],
        'tipo': d['tipo'],
        'cantidad': d['cantidad'],
        'fechaFinalizado': d['fechaFinalizado'],
      });
    }

    return {
      'totalProcesosActivos': activosSnap.docs.length,
      'porFase': porFase,
      'procesosActivos': activos,
      'totalProcesosFinalizados': historialSnap.docs.length,
      'cantidadTotalFinalizada': cantidadFinalizada,
      'ultimosFinalizados': finalizados.length > 20
          ? finalizados.sublist(finalizados.length - 20)
          : finalizados,
    };
  }

  int _aEntero(dynamic valor) {
    if (valor is num) return valor.toInt();
    return int.tryParse('$valor') ?? 0;
  }

  String _construirPrompt(
    String mensaje,
    String tipo,
    Map<String, dynamic> datos,
  ) {
    final datosJson = const JsonEncoder.withIndent('  ').convert(datos);
    return '''
Eres un asistente que genera informes profesionales en español para ECO-REFILL, una planta de reciclaje de plásticos.
Recibes datos ya agregados en JSON (totales, agrupaciones, últimos registros).
Redacta un informe en formato Markdown con: un título con '#', un resumen ejecutivo breve,
secciones con '##' que muestren los totales y agrupaciones relevantes (usa listas con '-'),
y una sección final de observaciones o recomendaciones cortas.
Usa EXCLUSIVAMENTE los datos que se te entregan, no inventes cifras ni registros.
Si algún dato relevante no está disponible, dilo explícitamente.

Solicitud del usuario: "$mensaje"

Tipo de informe detectado: $tipo

Datos disponibles (JSON):
$datosJson
''';
  }

  Future<String> _llamarGemini(String prompt) async {
    if (geminiApiKey.isEmpty || geminiApiKey == 'TU_API_KEY_AQUI') {
      throw Exception(
        'Falta configurar tu API key gratuita de Gemini en gemini_config.dart',
      );
    }

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=$geminiApiKey',
    );

    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
      }),
    );

    if (resp.statusCode != 200) {
      throw Exception('Error de la IA (${resp.statusCode}): ${resp.body}');
    }

    final data = jsonDecode(utf8.decode(resp.bodyBytes));
    final texto = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
    if (texto == null || texto.toString().trim().isEmpty) {
      throw Exception('La IA no devolvió contenido para este informe.');
    }
    return texto.toString();
  }

  Future<MensajeChatIA> generarInforme(String mensaje) async {
    try {
      final tipo = _detectarTipo(mensaje);
      Map<String, dynamic> datos;

      if (tipo == 'ingresos') {
        datos = {'ingresos': await _resumenIngresos()};
      } else if (tipo == 'materiales') {
        datos = {'materiales': await _resumenMateriales()};
      } else if (tipo == 'procesos') {
        datos = {'procesos': await _resumenProcesos()};
      } else {
        final resultados = await Future.wait([
          _resumenIngresos(),
          _resumenMateriales(),
          _resumenProcesos(),
        ]);
        datos = {
          'ingresos': resultados[0],
          'materiales': resultados[1],
          'procesos': resultados[2],
        };
      }

      final prompt = _construirPrompt(mensaje, tipo, datos);
      final informe = await _llamarGemini(prompt);

      return MensajeChatIA(texto: informe, esUsuario: false, esInforme: true);
    } catch (e) {
      return MensajeChatIA(
        texto: 'No se pudo generar el informe: $e',
        esUsuario: false,
      );
    }
  }
}
