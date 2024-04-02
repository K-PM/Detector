import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';

class Home extends StatefulWidget {
  const Home({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late CameraController _cameraController;
  String _result = '';
  bool _isCameraInitialized = false;
  bool _isModelReady = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadModel();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    // Buscar la cámara frontal
    CameraDescription? frontCamera;
    for (var camera in cameras) {
      if (camera.lensDirection == CameraLensDirection.front) {
        frontCamera = camera;
        break;
      }
    }

    if (frontCamera == null) {
      print('No se encontró la cámara frontal.');
      return;
    }

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      imageFormatGroup: ImageFormatGroup.yuv420
    );

    try {
      await _cameraController.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
      _cameraController.startImageStream((CameraImage image) {
        if (!_isModelReady) return;
        _classifyImage(image);
      });
    } catch (e) {
      print('Error al inicializar la cámara: $e');
    }
  }

  Future<void> _loadModel() async {
    try {
      await Tflite.loadModel(
        model: "assets/modelo.tflite",
        labels: "assets/etiquetas.txt",
      );
      setState(() {
        _isModelReady = true;
      });
    } catch (e) {
      print('Error al cargar el modelo: $e');
    }
  }

  @override
  void dispose() {
    _cameraController.stopImageStream();
    _cameraController.dispose();
    Tflite.close();
    super.dispose();
  }

  void _classifyImage(CameraImage image) async {
    if (_isModelReady) {
      try {
        List<dynamic>? recognitions = await Tflite.runModelOnFrame(
          bytesList: image.planes.map((plane) {
            return plane.bytes;
          }).toList(),
          imageHeight: image.height,
          imageWidth: image.width,
          imageMean: 127.5,
          imageStd: 127.5,
          rotation: 90,
          numResults: 2,
          threshold: 0.1,
        );
        if (recognitions != null && recognitions.isNotEmpty) {
          setState(() {
            _result = recognitions[0]['label'];
          });
        }
      } catch (e) {
        print('Error al clasificar la imagen: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: _cameraController.value.aspectRatio,
                  child: CameraPreview(_cameraController),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: EdgeInsets.all(8),
              color: Colors.black.withOpacity(0.5),
              child: Text(
                'Clase predicha: $_result',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    title: 'TFLite Example',
    home: Home(title: 'TFLite Example'),
  ));
}
