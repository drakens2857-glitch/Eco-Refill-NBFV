import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Convierte el texto (Markdown simple: #, ##, -, **) que devuelve la IA
/// en un PDF y abre el diálogo de compartir/descargar del sistema.
class PdfInformeService {
  static Future<void> descargarInforme({
    required String titulo,
    required String contenidoMarkdown,
  }) async {
    final doc = pw.Document();
    final lineas = contenidoMarkdown.split('\n');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          final widgets = <pw.Widget>[
            pw.Text(
              titulo,
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Generado el ${_formatearFecha(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 8),
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 8),
          ];

          for (final lineaOriginal in lineas) {
            final linea = lineaOriginal.trim();

            if (linea.isEmpty) {
              widgets.add(pw.SizedBox(height: 6));
            } else if (linea.startsWith('### ')) {
              widgets.add(pw.Padding(
                padding: const pw.EdgeInsets.only(top: 6, bottom: 2),
                child: pw.Text(
                  _quitarNegritas(linea.replaceFirst('### ', '')),
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
              ));
            } else if (linea.startsWith('## ')) {
              widgets.add(pw.Padding(
                padding: const pw.EdgeInsets.only(top: 10, bottom: 4),
                child: pw.Text(
                  _quitarNegritas(linea.replaceFirst('## ', '')),
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.purple700,
                  ),
                ),
              ));
            } else if (linea.startsWith('# ')) {
              widgets.add(pw.Padding(
                padding: const pw.EdgeInsets.only(top: 4, bottom: 6),
                child: pw.Text(
                  _quitarNegritas(linea.replaceFirst('# ', '')),
                  style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold),
                ),
              ));
            } else if (linea.startsWith('- ') || linea.startsWith('* ')) {
              widgets.add(pw.Bullet(
                text: _quitarNegritas(linea.substring(2)),
                style: const pw.TextStyle(fontSize: 10.5),
              ));
            } else {
              widgets.add(pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Text(
                  _quitarNegritas(linea),
                  style: const pw.TextStyle(fontSize: 10.5),
                ),
              ));
            }
          }

          return widgets;
        },
      ),
    );

    final bytes = await doc.save();
    final nombreArchivo =
        'informe_eco_refill_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await Printing.sharePdf(bytes: bytes, filename: nombreArchivo);
  }

  static String _quitarNegritas(String texto) => texto.replaceAll('**', '');

  static String _formatearFecha(DateTime d) {
    String dos(int v) => v.toString().padLeft(2, '0');
    return '${dos(d.day)}/${dos(d.month)}/${d.year} ${dos(d.hour)}:${dos(d.minute)}';
  }
}
