import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'camera_view.dart';
import 'painters/face_detector_painter.dart';
import 'package:tflite/tflite.dart';
import 'dart:async';

class FaceDetectorView extends StatefulWidget {
  const FaceDetectorView({Key? key}) : super(key: key);
  @override
  State<FaceDetectorView> createState() => _FaceDetectorViewState();
}

class _FaceDetectorViewState extends State<FaceDetectorView> {
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;
  var _cameraLensDirection = CameraLensDirection.front;

  String _result = '';
  bool _isModelReady = false;
  

  @override
  void initState() {
    super.initState();
    _loadModel();
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
      print('SE CARGO EL MODELOOOOOOO');
      print(_isModelReady);
    } catch (e) {
      print('Error al cargar el modelo: $e');
    }
  }

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
    ),
  );

  @override
  void dispose() {
    _faceDetector.close();
    Tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CameraView(
      resulClassi: _result,
      customPaint: _customPaint,
      onImage: _processImage,
      initialCameraLensDirection: _cameraLensDirection,
      onCameraLensDirectionChanged: (value) => _cameraLensDirection = value,
    );
  }

  Future<void> _processImage(InputImage inputImage, CameraImage image) async {
    if (_isBusy) return;
    _isBusy = true;
    setState(() {
      _text = '';
    });

    _classifyImage(image);

    final faces = await _faceDetector.processImage(inputImage);
    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null) {
      _customPaint = CustomPaint(
          painter: FaceDetectorPainter(faces, inputImage.metadata!.size,
              inputImage.metadata!.rotation, _cameraLensDirection));
    } else {
      String text = 'Faces found: ${faces.length}\n\n';
      for (final face in faces) {
        text += 'face: ${face.boundingBox}\n\n';
      }
      _text = text;
      _customPaint = null;
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
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
            _result = "valor: ${recognitions[0]['label']}";
          });
        }
      } catch (e) {
        print('Error al clasificar la imagen: $e');
      }
    }
  }
}
