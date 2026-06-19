import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyCPOOf4qGCqlrnVQzkuC0Qrwdtd4b6b-dc",
    appId: "1:992396324099:web:aa1ad54618ca2f6fb30d36",
    messagingSenderId: "992396324099",
    projectId: "eco-refill-31771",
    authDomain: "eco-refill-31771.firebaseapp.com",
    storageBucket: "eco-refill-31771.firebasestorage.app",
  );

  static FirebaseOptions get currentPlatform => web;
}
