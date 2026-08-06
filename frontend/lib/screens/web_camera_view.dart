// lib/screens/web_camera_view.dart
//
// Registra el viewType "camera-view" que usa HtmlElementView en
// facerecognition.dart. Sin este registro, la cámara nunca aparece
// porque Flutter no sabe qué elemento HTML dibujar ahí.

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

bool _cameraViewRegistered = false;

void registerCameraView() {
  // registerViewFactory solo se puede llamar una vez por nombre de vista,
  // así que protegemos con este flag por si el widget se reconstruye.
  if (_cameraViewRegistered) return;
  _cameraViewRegistered = true;

  // ignore: undefined_prefixed_name
  ui_web.platformViewRegistry.registerViewFactory('camera-view', (int viewId) {
    final video = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover';

    html.window.navigator.mediaDevices
        ?.getUserMedia({'video': true, 'audio': false})
        .then((stream) {
      video.srcObject = stream;
    }).catchError((error) {
      // Esto se ve en la consola del navegador (F12) si el usuario
      // niega el permiso de cámara o no hay ninguna disponible.
      // ignore: avoid_print
      print('Error accediendo a la cámara: $error');
    });

    return video;
  });
}
