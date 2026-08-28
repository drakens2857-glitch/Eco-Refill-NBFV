import 'package:flutter/material.dart';
import '../services/informes_service.dart';
import '../services/pdf_informe_service.dart';

/// Panel de chat con la IA de informes. Se usa como un panel lateral
/// (Positioned a la derecha) desde PantallaBienvenida u otras pantallas.
class PanelChatIA extends StatefulWidget {
  final VoidCallback onCerrar;

  const PanelChatIA({super.key, required this.onCerrar});

  @override
  State<PanelChatIA> createState() => _PanelChatIAState();
}

class _PanelChatIAState extends State<PanelChatIA> {
  static const Color panelBg = Color(0xFF0F0716);
  static const Color cardBg = Color(0xFF170C28);
  static const Color neonPurple = Color(0xFFA855F7);

  final InformesService _informesService = InformesService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<MensajeChatIA> _mensajes = [];
  bool _cargando = false;

  Future<void> _enviarMensaje([String? textoSugerido]) async {
    final texto = (textoSugerido ?? _inputController.text).trim();
    if (texto.isEmpty || _cargando) return;

    setState(() {
      _mensajes.add(MensajeChatIA(texto: texto, esUsuario: true));
      _cargando = true;
      _inputController.clear();
    });
    _desplazarAbajo();

    final respuesta = await _informesService.generarInforme(texto);

    if (!mounted) return;
    setState(() {
      _mensajes.add(respuesta);
      _cargando = false;
    });
    _desplazarAbajo();
  }

  void _desplazarAbajo() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 160,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final anchoPantalla = MediaQuery.of(context).size.width;
    final anchoPanel = anchoPantalla < 420 ? anchoPantalla : 380.0;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: anchoPanel,
        decoration: BoxDecoration(
          color: panelBg,
          border: Border(left: BorderSide(color: neonPurple.withOpacity(0.3))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 24,
              offset: const Offset(-6, 0),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _mensajes.isEmpty
                    ? _buildEstadoVacio()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _mensajes.length,
                        itemBuilder: (context, index) =>
                            _buildBurbuja(_mensajes[index]),
                      ),
              ),
              if (_cargando)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: neonPurple,
                    ),
                  ),
                ),
              _buildInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: neonPurple.withOpacity(0.3))),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: neonPurple, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              "Asistente de Informes",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          IconButton(
            onPressed: widget.onCerrar,
            icon: const Icon(Icons.close, color: Colors.white54, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoVacio() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined,
              color: neonPurple.withOpacity(0.5), size: 40),
          const SizedBox(height: 12),
          const Text(
            "Pídeme un informe, por ejemplo:",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 10),
          _buildSugerencia("Genera un informe de ingresos"),
          _buildSugerencia("Genera un informe de materiales"),
          _buildSugerencia("Genera un informe de procesos"),
        ],
      ),
    );
  }

  Widget _buildSugerencia(String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _enviarMensaje(texto),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: neonPurple.withOpacity(0.2)),
          ),
          child: Text(
            texto,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildBurbuja(MensajeChatIA mensaje) {
    final alineacion =
        mensaje.esUsuario ? Alignment.centerRight : Alignment.centerLeft;
    final color = mensaje.esUsuario ? neonPurple : cardBg;

    return Align(
      alignment: alineacion,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mensaje.texto,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
            if (mensaje.esInforme) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: () => PdfInformeService.descargarInforme(
                  titulo: "Informe ECO-REFILL",
                  contenidoMarkdown: mensaje.texto,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.download_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      "Descargar PDF",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              onSubmitted: (_) => _enviarMensaje(),
              decoration: InputDecoration(
                hintText: "Ej: genera un informe de ingresos",
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                filled: true,
                fillColor: cardBg,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: neonPurple.withOpacity(0.25)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: neonPurple),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: neonPurple,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _enviarMensaje(),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.send_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
