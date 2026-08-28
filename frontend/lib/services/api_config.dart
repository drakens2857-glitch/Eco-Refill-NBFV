/// 🔧 Configuración central de la URL del backend.
///
/// Backend desplegado en Google Cloud Run.
class ApiConfig {
  static const String baseUrl = "https://eco-refill-backend-992396324099.us-central1.run.app";

  /// URL base con el prefijo /api ya incluido, para usar directo en ApiService.
  static String get apiBaseUrl => "$baseUrl/api";
}