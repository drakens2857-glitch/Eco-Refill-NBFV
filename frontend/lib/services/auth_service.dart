import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🔹 Variables privadas para guardar credenciales del jefe
  String? _adminEmail;
  String? _adminPassword;

  /// 🔹 Iniciar sesión y guardar credenciales del jefe
  Future<User?> login(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Guardamos credenciales del jefe
      _adminEmail = email;
      _adminPassword = password;
      return credential.user;
    } on FirebaseAuthException catch (e) {
      print("Error en login: ${e.code} - ${e.message}");
      return null;
    }
  }

  /// 🔹 Registrar usuario con datos adicionales
  Future<bool> register(String name, String email, String password, String phone, String cargo) async {
    try {
      // Crear usuario en Firebase Auth
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? newUser = credential.user;

      if (newUser != null) {
        // Guardar datos adicionales en Firestore
        await _db.collection("users").doc(newUser.uid).set({
          "name": name,
          "email": email,
          "phone": phone,
          "cargo": cargo,
          "createdAt": DateTime.now(),
        });

        // 🔹 Cerrar sesión del usuario recién creado
        await _auth.signOut();

        // 🔹 Volver a iniciar sesión con el jefe automáticamente
        if (_adminEmail != null && _adminPassword != null) {
          await _auth.signInWithEmailAndPassword(
            email: _adminEmail!,
            password: _adminPassword!,
          );
        }

        return true;
      }

      return false;
    } on FirebaseAuthException catch (e) {
      print("Error en registro: ${e.code} - ${e.message}");
      return false;
    } catch (e) {
      print("Error inesperado en registro: $e");
      return false;
    }
  }

  /// 🔹 Cerrar sesión
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// 🔹 Usuario actual
  User? get currentUser => _auth.currentUser;

  /// 🔹 Obtener cargo/rol del usuario actual desde Firestore
  Future<String?> getUserRole(String uid) async {
    final doc = await _db.collection("users").doc(uid).get();
    if (doc.exists) {
      return doc.data()?["cargo"];
    }
    return null;
  }
}
