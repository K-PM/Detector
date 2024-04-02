// main.dart
import 'package:flutter/material.dart';
import 'package:proyect_face_ia/vision_detector_views/google.dart'; // Importa el archivo iniciate.dart

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face',
      theme: ThemeData(
        colorScheme: ColorScheme.dark(),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: FaceDetectorView(), // Cambia FaceDetectorView() a Iniciate()
    );
  }
}


