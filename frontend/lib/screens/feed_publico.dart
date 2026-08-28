import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kIsWeb;
import 'dart:convert' show base64Decode;
import 'dart:typed_data'; // 🔹 para manejar bytes
import 'package:convert/convert.dart'; // 🔹 para convertir hex a bytes
import '../services/api_service.dart';

class FeedPublicoScreen extends StatefulWidget {
  final bool desdeLogin;

  const FeedPublicoScreen({super.key, required this.desdeLogin});

  @override
  State<FeedPublicoScreen> createState() => _FeedPublicoScreenState();
}

class _FeedPublicoScreenState extends State<FeedPublicoScreen> {
  final api = ApiService();
  List posts = [];
  bool loading = true;
  String? _error;

  // 🎨 Paleta inspirada en el dashboard de referencia.
  static const Color _bg = Color(0xFF05070C);
  static const Color _cardColor = Color(0xFF0D1220);
  static const Color _cardBorder = Color(0xFF1C2536);
  static const Color _purple = Color(0xFFA855F7);
  static const Color _cyan = Colors.cyanAccent;
  static const Color _greyText = Color(0xFF8B96A8);

  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";
  String _selectedCategory = "Todas las publicaciones";
  String _sortOption = "Más recientes";
  int _currentPage = 0;
  final int _itemsPerPage = 6;

  // 🔹 Antes _decodeImageFromPost/_imageUrlFromPost (que decodifican
  // base64/hex, un trabajo pesado) se llamaban desde cero en CADA build:
  // una vez en _buildStatsRow (para contar "con imagen") y otra vez más
  // por cada card en _buildPostCard. Como el build se dispara con cada
  // tecla del buscador, cada cambio de orden/página, etc., esto
  // redecodificaba TODAS las imágenes de TODAS las publicaciones una y
  // otra vez, congelando la UI. Ahora se calcula una sola vez por
  // publicación y se cachea.
  final Map<int, Uint8List?> _imageBytesCache = {};
  final Map<int, String?> _imageUrlCache = {};

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.trim();
        _currentPage = 0;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() {
      loading = true;
      _error = null;
    });

    try {
      final data = await api
          .getPosts()
          .timeout(const Duration(seconds: 20));

      // 🔹 Ayuda de depuración: imprime en consola las claves reales que
      // trae cada publicación, para confirmar cómo se llama el campo de la
      // imagen en tu backend (puede no ser "imageBytes").
      if (kDebugMode && data.isNotEmpty) {
        final first = data.first;
        if (first is Map) {
          debugPrint("🔎 Campos de una publicación: ${first.keys.toList()}");
        }
      }

      setState(() {
        posts = data;
        loading = false;
        // Los datos son nuevos: invalidamos la caché de imágenes para no
        // arrastrar resultados de publicaciones que ya no existen.
        _imageBytesCache.clear();
        _imageUrlCache.clear();
      });
    } catch (e) {
      // 🔹 Antes, si esto fallaba (CORS, timeout, backend caído/arrancando),
      // "loading" se quedaba en true para siempre y la pantalla mostraba
      // el spinner sin fin, sin ninguna pista de qué estaba pasando.
      debugPrint("❌ Error cargando publicaciones: $e");
      setState(() {
        _error = e.toString();
        loading = false;
      });
    }
  }

  // 🔹 Busca la imagen de una publicación probando varios nombres de
  // campo comunes y varios formatos (hex, base64). Si tu backend guarda
  // la imagen bajo otro nombre, agrégalo a `_imageFieldCandidates`.
  static const List<String> _imageFieldCandidates = [
    "imageBytes",
    "image_bytes",
    "image",
    "img",
    "photo",
    "picture",
  ];

  static const List<String> _imageUrlFieldCandidates = [
    "imageUrl",
    "image_url",
    "photoUrl",
    "photo_url",
    "fileUrl",
    "file_url",
    "url",
  ];

  Uint8List? _decodeImageFromPost(Map post) {
    for (final key in _imageFieldCandidates) {
      final raw = post[key];
      if (raw == null) continue;
      final asString = raw.toString().trim();
      if (asString.isEmpty) continue;

      // Intenta hex (par de dígitos hexadecimales).
      if (asString.length % 2 == 0 &&
          RegExp(r'^[0-9a-fA-F]+$').hasMatch(asString)) {
        try {
          return Uint8List.fromList(hex.decode(asString));
        } catch (_) {
          // sigue intentando con otros formatos/campos
        }
      }

      // Intenta base64.
      try {
        final cleaned = asString.contains(',')
            ? asString.substring(asString.indexOf(',') + 1)
            : asString;
        return base64Decode(cleaned);
      } catch (_) {
        // no era base64 válido; prueba el siguiente campo
      }
    }
    return null;
  }

  // 🔹 Mismo servidor que usa ApiService (sin el sufijo /api), para poder
  // completar rutas relativas como "/uploads/foto.png" que devuelve el
  // backend en el campo imageUrl.
  static const String _mediaBaseUrl = "https://eco-refill-backend-992396324099.us-central1.run.app";

  /// Si la imagen no viene embebida sino como URL (por ejemplo, si el
  /// backend la sirve desde disco o un bucket), la usamos con Image.network.
  /// Si la URL es relativa (empieza con "/", como la guarda tu backend),
  /// le anteponemos la dirección del servidor.
  String? _imageUrlFromPost(Map post) {
    for (final key in _imageUrlFieldCandidates) {
      final raw = post[key];
      final asString = raw?.toString().trim() ?? "";
      if (asString.isEmpty) continue;

      if (asString.startsWith("http://") || asString.startsWith("https://")) {
        // 🔹 En la versión web, si la página se sirve por https y la
        // imagen viene en http, el navegador bloquea la carga como
        // "contenido mixto" y la imagen simplemente no aparece, sin
        // ningún error visible. Como el backend sí soporta https,
        // subimos el esquema en vez de dejar que el navegador la
        // descarte en silencio.
        if (kIsWeb && asString.startsWith("http://")) {
          return asString.replaceFirst("http://", "https://");
        }
        return asString;
      }
      final path = asString.startsWith("/") ? asString : "/$asString";
      return "$_mediaBaseUrl$path";
    }
    return null;
  }

  // 🔹 Punto único de acceso a las imágenes de una publicación: calcula
  // bytes/URL la primera vez y reutiliza el resultado en los siguientes
  // builds, en vez de re-decodificar en cada render.
  Uint8List? _imageBytesFor(Map post) {
    final key = identityHashCode(post);
    if (_imageBytesCache.containsKey(key)) return _imageBytesCache[key];
    final bytes = _decodeImageFromPost(post);
    _imageBytesCache[key] = bytes;
    return bytes;
  }

  String? _imageUrlFor(Map post) {
    final key = identityHashCode(post);
    if (_imageUrlCache.containsKey(key)) return _imageUrlCache[key];
    final url = _imageBytesFor(post) == null ? _imageUrlFromPost(post) : null;
    _imageUrlCache[key] = url;
    return url;
  }

  String _getInitials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return "?";
    final parts = clean.split(RegExp(r"\s+"));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return "${parts.first.substring(0, 1)}${parts[1].substring(0, 1)}"
        .toUpperCase();
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  /// Busca la fecha de una publicación probando los nombres de campo más
  /// comunes ("created_at" es el que usa tu backend actual).
  DateTime? _postDate(Map post) {
    return _parseDate(post["created_at"]) ??
        _parseDate(post["date"]) ??
        _parseDate(post["createdAt"]);
  }

  num _numField(Map post, String key) {
    final v = post[key];
    if (v is num) return v;
    return num.tryParse(v?.toString() ?? "") ?? 0;
  }

  List<String> get _availableCategories {
    final set = <String>{};
    for (final p in posts) {
      final c = (p["category"] ?? "").toString().trim();
      if (c.isNotEmpty) set.add(c);
    }
    return set.toList()..sort();
  }

  List get _filteredPosts {
    var list = posts.where((p) {
      final desc = (p["description"] ?? "").toString().toLowerCase();
      final author = (p["author"] ?? "").toString().toLowerCase();
      final q = _searchText.toLowerCase();
      final matchesQuery =
          q.isEmpty || desc.contains(q) || author.contains(q);

      final category = (p["category"] ?? "").toString();
      final matchesCategory = _selectedCategory == "Todas las publicaciones" ||
          category == _selectedCategory;

      return matchesQuery && matchesCategory;
    }).toList();

    switch (_sortOption) {
      case "Más recientes":
        list.sort((a, b) {
          final da = _postDate(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
          final db = _postDate(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
          return db.compareTo(da);
        });
        break;
      case "Más antiguas":
        list.sort((a, b) {
          final da = _postDate(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
          final db = _postDate(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
          return da.compareTo(db);
        });
        break;
      case "Más vistas":
        list.sort((a, b) => _numField(b, "views").compareTo(_numField(a, "views")));
        break;
      case "Más gustadas":
        list.sort((a, b) => _numField(b, "likes").compareTo(_numField(a, "likes")));
        break;
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPosts;
    final totalPages = (filtered.length / _itemsPerPage).ceil().clamp(1, 999);
    final page = _currentPage.clamp(0, totalPages - 1);
    final pageItems = filtered
        .skip(page * _itemsPerPage)
        .take(_itemsPerPage)
        .toList();

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: loading
            ? const Center(
                child: CircularProgressIndicator(color: _cyan),
              )
            : _error != null
                ? _buildErrorState()
                : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 24),
                    _buildStatsRow(),
                    const SizedBox(height: 24),
                    _buildFiltersBar(),
                    const SizedBox(height: 20),
                    if (pageItems.isEmpty)
                      _buildEmptyState()
                    else
                      _buildPostsGrid(pageItems),
                    const SizedBox(height: 24),
                    if (filtered.isNotEmpty)
                      _buildPagination(totalPages, page),
                  ],
                ),
              ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Estado de error (antes se quedaba en spinner infinito sin avisar)
  // ---------------------------------------------------------------------
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, color: _greyText, size: 48),
            const SizedBox(height: 16),
            const Text(
              "No se pudieron cargar las publicaciones",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? "",
              textAlign: TextAlign.center,
              style: const TextStyle(color: _greyText, fontSize: 12.5),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadPosts,
              icon: const Icon(Icons.refresh),
              label: const Text("Reintentar"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Encabezado
  // ---------------------------------------------------------------------
  Widget _buildHeader(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: InkWell(
            onTap: () {
              // 🔹 Antes esto siempre hacía pushReplacementNamed, lo que
              // apilaba una SEGUNDA instancia de Home encima de la
              // original (a la que se llegó con Navigator.push). Al
              // quedar algo debajo en la pila, el AppBar de Home mostraba
              // su flecha de "atrás" automática junto al logo. Si se
              // puede volver simplemente con pop(), usamos eso.
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else if (widget.desdeLogin) {
                Navigator.pushReplacementNamed(context, '/pantallabienvenida');
              } else {
                Navigator.pushReplacementNamed(context, '/home');
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _cardBorder),
              ),
              child: const Icon(Icons.arrow_back, color: _cyan, size: 20),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 54),
          child: Column(
            children: [
              Text(
                "Publicaciones",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                "Explora todas las publicaciones creadas en el sistema",
                style: TextStyle(color: _greyText, fontSize: 13),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Estadísticas (calculadas a partir de las publicaciones ya cargadas)
  // ---------------------------------------------------------------------
  Widget _buildStatsRow() {
    final total = posts.length;
    final autores = posts
        .map((p) => (p["author"] ?? "").toString().trim())
        .where((a) => a.isNotEmpty)
        .toSet()
        .length;
    final conImagen = posts
        .where((p) => _imageBytesFor(p) != null || _imageUrlFor(p) != null)
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 560;
        final cards = [
          _statCard(
            icon: Icons.description_outlined,
            iconColor: _purple,
            value: total.toString(),
            label: "Total publicaciones",
            sublabel: "en el sistema",
          ),
          _statCard(
            icon: Icons.person_outline,
            iconColor: _cyan,
            value: autores.toString(),
            label: "Autores",
            sublabel: "han publicado",
          ),
          _statCard(
            icon: Icons.image_outlined,
            iconColor: const Color(0xFFF59E0B),
            value: conImagen.toString(),
            label: "Con imagen",
            sublabel: "adjunta",
          ),
        ];

        if (isNarrow) {
          return Column(
            children: [
              for (final c in cards) ...[
                c,
                const SizedBox(height: 10),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i != cards.length - 1) const SizedBox(width: 14),
            ],
          ],
        );
      },
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required String sublabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.14),
              shape: BoxShape.circle,
              border: Border.all(color: iconColor.withOpacity(0.4)),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: _greyText, fontSize: 12.5)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(sublabel,
                  style: const TextStyle(color: _greyText, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Barra de búsqueda + filtros
  // ---------------------------------------------------------------------
  Widget _buildFiltersBar() {
    final categories = ["Todas las publicaciones", ..._availableCategories];
    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = "Todas las publicaciones";
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;

        final search = _filterField(
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white, fontSize: 13.5),
            decoration: const InputDecoration(
              isDense: true,
              isCollapsed: true,
              border: InputBorder.none,
              hintText: "Buscar publicación, autor...",
              hintStyle: TextStyle(color: _greyText, fontSize: 13.5),
              prefixIcon: Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.search, color: _greyText, size: 20),
              ),
              // 🔹 Sin esto, el prefixIcon reserva por defecto una caja de
              // 48x48, más alta que el contenedor de 46px del buscador, y
              // eso empujaba el texto fuera del centro vertical.
              prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
            ),
          ),
        );

        final categoryDropdown = _filterField(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              dropdownColor: _cardColor,
              icon: const Icon(Icons.keyboard_arrow_down, color: _greyText),
              style: const TextStyle(color: Colors.white, fontSize: 13.5),
              items: categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _selectedCategory = v;
                  _currentPage = 0;
                });
              },
            ),
          ),
        );

        final sortDropdown = _filterField(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _sortOption,
              isExpanded: true,
              dropdownColor: _cardColor,
              icon: const Icon(Icons.keyboard_arrow_down, color: _greyText),
              style: const TextStyle(color: Colors.white, fontSize: 13.5),
              items: const [
                DropdownMenuItem(
                    value: "Más recientes", child: Text("Más recientes")),
                DropdownMenuItem(
                    value: "Más antiguas", child: Text("Más antiguas")),
                DropdownMenuItem(
                    value: "Más vistas", child: Text("Más vistas")),
                DropdownMenuItem(
                    value: "Más gustadas", child: Text("Más gustadas")),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _sortOption = v;
                  _currentPage = 0;
                });
              },
            ),
          ),
        );

        if (isNarrow) {
          return Column(
            children: [
              search,
              const SizedBox(height: 10),
              categoryDropdown,
              const SizedBox(height: 10),
              sortDropdown,
            ],
          );
        }

        return Row(
          children: [
            Expanded(flex: 2, child: search),
            const SizedBox(width: 12),
            Expanded(child: categoryDropdown),
            const SizedBox(width: 12),
            Expanded(child: sortDropdown),
          ],
        );
      },
    );
  }

  Widget _filterField({required Widget child}) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
      ),
      child: Align(alignment: Alignment.centerLeft, child: child),
    );
  }

  // ---------------------------------------------------------------------
  // Estado vacío
  // ---------------------------------------------------------------------
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: const Column(
        children: [
          Icon(Icons.inbox_outlined, color: _greyText, size: 36),
          SizedBox(height: 10),
          Text(
            "No se encontraron publicaciones.",
            style: TextStyle(color: _greyText, fontSize: 13.5),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Grid de publicaciones
  // ---------------------------------------------------------------------
  Widget _buildPostsGrid(List pageItems) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 1;
        if (constraints.maxWidth > 1100) {
          columns = 3;
        } else if (constraints.maxWidth > 720) {
          columns = 2;
        }

        const spacing = 16.0;
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final post in pageItems)
              SizedBox(width: cardWidth, child: _buildPostCard(post)),
          ],
        );
      },
    );
  }

  Widget _buildPostCard(Map post) {
    final imageBytes = _imageBytesFor(post);
    final imageUrl = imageBytes == null ? _imageUrlFor(post) : null;
    final author = (post["author"] ?? "Desconocido").toString();
    final title = (post["title"] ?? "").toString().trim();
    final description = (post["description"] ?? "").toString();
    final category = (post["category"] ?? "").toString().trim();
    final date = _postDate(post);

    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: _cyan.withOpacity(0.15),
                  child: Text(
                    _getInitials(author),
                    style: const TextStyle(
                      color: _cyan,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (date != null)
                        Text(
                          "${date.day.toString().padLeft(2, '0')}/"
                          "${date.month.toString().padLeft(2, '0')}/"
                          "${date.year} • "
                          "${date.hour.toString().padLeft(2, '0')}:"
                          "${date.minute.toString().padLeft(2, '0')}",
                          style: const TextStyle(
                              color: _greyText, fontSize: 11),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (imageBytes != null)
            AspectRatio(
              aspectRatio: 16 / 11,
              child: Image.memory(
                imageBytes,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.black26,
                  child: const Icon(Icons.image_not_supported_outlined,
                      color: _greyText, size: 28),
                ),
              ),
            )
          else if (imageUrl != null)
            AspectRatio(
              aspectRatio: 16 / 11,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.black26,
                  child: const Icon(Icons.image_not_supported_outlined,
                      color: _greyText, size: 28),
                ),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: Colors.black26,
                    child: const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _cyan),
                      ),
                    ),
                  );
                },
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 140,
              color: Colors.black26,
              child: const Icon(Icons.image_not_supported_outlined,
                  color: _greyText, size: 28),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty) ...[
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  description.isEmpty ? "Sin descripción." : description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Color(0xFFE2D4F0), fontSize: 13.5, height: 1.4),
                ),
                if (category.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _purple.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        color: _purple,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Paginación
  // ---------------------------------------------------------------------
  Widget _buildPagination(int totalPages, int page) {
    List<Object> pageTokens() {
      if (totalPages <= 7) {
        return List.generate(totalPages, (i) => i);
      }
      final tokens = <Object>{0, totalPages - 1};
      for (int i = page - 1; i <= page + 1; i++) {
        if (i >= 0 && i < totalPages) tokens.add(i);
      }
      final sorted = tokens.toList()..sort((a, b) => (a as int).compareTo(b as int));
      final result = <Object>[];
      for (int i = 0; i < sorted.length; i++) {
        if (i > 0 && (sorted[i] as int) - (sorted[i - 1] as int) > 1) {
          result.add("...");
        }
        result.add(sorted[i]);
      }
      return result;
    }

    Widget navButton(IconData icon, VoidCallback? onTap) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _cardBorder),
          ),
          child: Icon(icon,
              color: onTap == null ? _greyText.withOpacity(0.4) : Colors.white,
              size: 18),
        ),
      );
    }

    return Center(
      child: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          navButton(
            Icons.chevron_left,
            page > 0 ? () => setState(() => _currentPage = page - 1) : null,
          ),
          for (final token in pageTokens())
            if (token == "...")
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text("...", style: TextStyle(color: _greyText)),
              )
            else
              InkWell(
                onTap: () => setState(() => _currentPage = token as int),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: token == page ? _purple : _cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: token == page ? _purple : _cardBorder,
                    ),
                  ),
                  child: Text(
                    "${(token as int) + 1}",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight:
                          token == page ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
          navButton(
            Icons.chevron_right,
            page < totalPages - 1
                ? () => setState(() => _currentPage = page + 1)
                : null,
          ),
        ],
      ),
    );
  }
}
