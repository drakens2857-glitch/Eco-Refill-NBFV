import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 🔹 Registrar usuario con datos adicionales
  Future<User?> register(String name, String email, String password, String phone) async {
    try {
      // Crear usuario en Firebase Auth
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = credential.user;

      if (user != null) {
        // Guardar datos adicionales en Firestore
        await _db.collection("users").doc(user.uid).set({
          "name": name,
          "email": email,
          "phone": phone,
          "createdAt": DateTime.now(),
        });
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print("Error en registro: ${e.code} - ${e.message}");
      return null;
    } catch (e) {
      print("Error inesperado en registro: $e");
      return null;
    }
  }

  /// 🔹 Iniciar sesión
  Future<User?> login(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      print("Error en login: ${e.code} - ${e.message}");
      return null;
    } catch (e) {
      print("Error inesperado en login: $e");
      return null;
    }
  }

  /// 🔹 Cerrar sesión
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// 🔹 Usuario actual
  User? get currentUser => _auth.currentUser;
}
