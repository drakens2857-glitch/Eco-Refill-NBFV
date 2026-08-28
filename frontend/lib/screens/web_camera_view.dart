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
      // Crítico en iOS/Safari: sin este atributo, el navegador abre la
      // cámara en pantalla completa en vez de mostrarla dentro de la app.
      ..setAttribute('playsinline', 'true')
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover';

    _iniciarCamara(video);

    return video;
  });
}

// Pide la cámara frontal (selfie) primero, ya que es la esperada para
// reconocimiento facial y la que muchos celulares Android NO usan por
// defecto si solo se pide {'video': true}. Si el dispositivo no tiene
// cámara frontal (o el navegador no soporta 'facingMode'), cae de
// vuelta a pedir cualquier cámara disponible.
void _iniciarCamara(html.VideoElement video) {
  html.window.navigator.mediaDevices
      ?.getUserMedia({
        'video': {'facingMode': 'user'},
        'audio': false,
      })
      .then((stream) => _asignarStream(video, stream))
      .catchError((error) {
    // ignore: avoid_print
    print('No se pudo abrir la cámara frontal, probando genérica: $error');
    html.window.navigator.mediaDevices
        ?.getUserMedia({'video': true, 'audio': false})
        .then((stream) => _asignarStream(video, stream))
        .catchError((error) {
      // Esto se ve en la consola del navegador (F12) si el usuario
      // niega el permiso de cámara o no hay ninguna disponible.
      // ignore: avoid_print
      print('Error accediendo a la cámara: $error');
    });
  });
}

void _asignarStream(html.VideoElement video, html.MediaStream stream) {
  video.srcObject = stream;
  // En varios navegadores móviles el autoplay no basta; se llama play()
  // explícitamente una vez asignado el stream.
  video.play();
}
