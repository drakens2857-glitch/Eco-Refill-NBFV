/// Helper centralizado de permisos por rol.
/// Colocar en: lib/services/permisos.dart
///
/// Roles existentes: jefe, inventario, ingreso, proceso.
/// "jefe" tiene acceso a todas las pantallas.
/// Los demás roles solo ven lo definido en el mapa de abajo.
class Permisos {
  static const Map<String, List<String>> _accesos = {
    'jefe': [
      'inicio',
      'perfil',
      'dashboard',
      'ingreso',
      'materiales',
      'procesos',
      'usuarios',
      'register',
      'tareas',
      'reportes',
    ],
    'inventario': [
      'inicio',
      'perfil',
      'ingreso',
      'tareas',
      'reportes',
    ],
    'ingreso': [
      'inicio',
      'perfil',
      'materiales',
      'tareas',
      'reportes',
    ],
    'proceso': [
      'inicio',
      'perfil',
      'procesos',
      'tareas',
      'reportes',
    ],
  };

  /// Devuelve true si el [rol] puede ver la pantalla identificada por [clave].
  /// Claves válidas: inicio, perfil, dashboard, ingreso, materiales,
  /// procesos, usuarios, register, tareas, reportes.
  static bool puedeVer(String? rol, String clave) {
    if (rol == null) return false;
    final rolNormalizado = rol.trim().toLowerCase();
    return _accesos[rolNormalizado]?.contains(clave) ?? false;
  }

  /// Devuelve true si el rol es "jefe" (acceso total, único que puede crear
  /// reportes; el resto solo puede verlos).
  static bool esJefe(String? rol) {
    if (rol == null) return false;
    return rol.trim().toLowerCase() == 'jefe';
  }
}
