import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'api_config.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? _adminEmail;
  String? _adminPassword;

  /// 🔹 Login con email y contraseña
  Future<User?> login(String email, String password) async {
    UserCredential credential;
    try {
      credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      print("Error en login: ${e.code} - ${e.message}");
      return null;
    }

    final User? user = credential.user;

    if (user != null) {
      final doc = await _db.collection("users").doc(user.uid).get();

      // 🔹 Si el perfil ya no existe en Firestore (usuario eliminado desde
      // el panel), no dejamos entrar aunque la cuenta de Firebase Auth
      // todavía exista.
      if (!doc.exists) {
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Esta cuenta ya no existe.',
        );
      }

      // 🔹 Verifica que la cuenta no haya sido inactivada por un admin.
      final estado = (doc.data()?["estado"] ?? "Activo").toString();

      if (estado.toLowerCase() == "inactivo") {
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'user-disabled',
          message:
              'Esta cuenta ha sido inactivada. Contacta a un administrador.',
        );
      }
    }

    _adminEmail = email;
    _adminPassword = password;
    return user;
  }

  /// 🔹 Registro normal
  Future<bool> register(
      String name, String email, String password, String phone, String cargo) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? newUser = credential.user;

      if (newUser != null) {
        await _db.collection("users").doc(newUser.uid).set({
          "name": name,
          "email": email,
          "phone": phone,
          "cargo": cargo,
          "createdAt": DateTime.now(),
        });

        await _auth.signOut();

        if (_adminEmail != null && _adminPassword != null) {
          await _auth.signInWithEmailAndPassword(
            email: _adminEmail!,
            password: _adminPassword!,
          );
        }
        return true;
      }
      return false;
    } catch (e) {
      print("Error en registro: $e");
      return false;
    }
  }

  /// 🔹 Registro con rostro
  Future<bool> registerWithFace(
      String name,
      String email,
      String password,
      String phone,
      String cargo,
      Uint8List faceBytes) async {
    try {
      var uri = Uri.parse("${ApiConfig.apiBaseUrl}/auth/register_with_face");
      var request = http.MultipartRequest("POST", uri);

      request.fields["name"] = name;
      request.fields["email"] = email;
      request.fields["password"] = password;
      request.fields["phone"] = phone;
      request.fields["cargo"] = cargo;

      request.files.add(http.MultipartFile.fromBytes("file", faceBytes, filename: "face.jpg"));

      var response = await request.send();
      var respStr = await response.stream.bytesToString();
      var data = json.decode(respStr);

      if (response.statusCode == 200 && data["uid"] != null) {
        return true;
      }

      // 🔹 Antes esto solo devolvía "false" y se perdía el motivo real
      // (por ejemplo: "No se detectó ningún rostro.", "Debe existir
      // solamente un rostro." o que el correo ya está registrado).
      // Ahora lo lanzamos como excepción para que la pantalla de
      // registro pueda mostrar el mensaje exacto del servidor.
      final detalle = data["detail"] ?? data["message"] ?? respStr;
      throw Exception(detalle);
    } catch (e) {
      print("Error en registro con rostro: $e");
      rethrow;
    }
  }

  /// 🔹 Login con rostro reconocido (usando UID)
  Future<bool> loginWithFace(String uid) async {
    try {
      final email = await getEmailFromUid(uid);
      if (email == null) {
        return false;
      }

      // Aquí podrías implementar lógica adicional si necesitas autenticar con Firebase
      // pero recuerda que Firebase no permite login solo con email sin contraseña.
      return true;
    } catch (e) {
      print("Error login facial: $e");
      return false;
    }
  }

  /// 🔹 Obtener correo desde UID
  Future<String?> getEmailFromUid(String uid) async {
    try {
      final doc = await _db.collection("users").doc(uid).get();
      if (doc.exists) {
        return doc.data()?["email"];
      }
      return null;
    } catch (e) {
      print("Error obteniendo correo desde UID: $e");
      return null;
    }
  }

  /// 🔹 Obtener UID desde el email
  /// 🔹 Obtener UID desde el email (vía backend, evita permisos de Firestore)
  Future<String?> getUidByEmail(String email) async {
    try {
      final uri = Uri.parse(
        "${ApiConfig.apiBaseUrl}/auth/uid_by_email?email=$email",
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data["uid"];
      }

      return null;
    } catch (e) {
      print("Error obteniendo UID desde email: $e");
      return null;
    }
  }

  /// 🔹 Cerrar sesión
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// 🔹 Usuario actual
  User? get currentUser => _auth.currentUser;

  /// 🔹 Obtener rol del usuario
  Future<String?> getUserRole(String uid) async {
    final doc = await _db.collection("users").doc(uid).get();
    if (doc.exists) {
      return doc.data()?["cargo"];
    }
    return null;
  }
}
