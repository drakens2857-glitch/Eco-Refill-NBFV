import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? _adminEmail;
  String? _adminPassword;

  Future<User?> login(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _adminEmail = email;
      _adminPassword = password;
      return credential.user;
    } on FirebaseAuthException catch (e) {
      print("Error en login: ${e.code} - ${e.message}");
      return null;
    }
  }

  Future<bool> register(String name, String email, String password, String phone, String cargo) async {
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

  Future<bool> registerWithFace(
      String name,
      String email,
      String password,
      String phone,
      String cargo,
      Uint8List faceBytes) async {
    try {
      var uri = Uri.parse("http://localhost:8000/api/auth/register_with_face"); // 🔹 corregido
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
      return false;
    } catch (e) {
      print("Error en registro con rostro: $e");
      return false;
    }
  }

  /// 🔹 Login con rostro reconocido (usando UID)
  Future<bool> loginWithFace(String uid) async {
    try {
      final doc = await _db.collection("users").doc(uid).get();
      if (doc.exists) {
        return true; // Usuario existe en Firestore
      }
      return false;
    } catch (e) {
      print("Error en login facial: $e");
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

  Future<void> logout() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;

  Future<String?> getUserRole(String uid) async {
    final doc = await _db.collection("users").doc(uid).get();
    if (doc.exists) {
      return doc.data()?["cargo"];
    }
    return null;
  }
}
