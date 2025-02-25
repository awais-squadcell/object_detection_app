import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

late List<CameraDescription> cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Object Detection and Recognition")),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(image: AssetImage("assets/4.png"), fit: BoxFit.cover)),
        child: Center(
          child: IconButton(
            icon: const Icon(Icons.camera_alt, size: 80, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CameraScreen()),
              );
            },
          ),
        ),
      ),
    );
  }
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  bool _isDetecting = false;
  String _detectionResults = "Initializing...";
  List<Rect> _boundingBoxes = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _initializeCamera() {
    _controller = CameraController(cameras[0], ResolutionPreset.medium);
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});

      // Start live detection
      _startLiveDetection();
    });
  }

  void _startLiveDetection() async {
    while (mounted) {
      if (_isDetecting) continue;

      _isDetecting = true;
      try {
        final XFile image = await _controller.takePicture();
        final File imageFile = File(image.path);
        final inputImage = InputImage.fromFile(imageFile);

        await _runAllDetections(inputImage);
      } catch (e) {
        print("Error capturing image: $e");
      }
      _isDetecting = false;
      await Future.delayed(const Duration(milliseconds: 500)); // Add delay to reduce processing load
    }
  }

  Future<void> _runAllDetections(InputImage inputImage) async {
    List<String> results = [];
    List<Rect> boundingBoxes = [];

    // 🟢 Object Detection
    final objectDetector = ObjectDetector(options: ObjectDetectorOptions(
      mode: DetectionMode.single,
      classifyObjects: true,
      multipleObjects: true,
    ));
    final objects = await objectDetector.processImage(inputImage);
    if (objects.isNotEmpty) {
      boundingBoxes.addAll(objects.map((obj) => obj.boundingBox));
      results.add("🔹 Object Detection:");
      for (var obj in objects) {
        for (var label in obj.labels) {
          results.add("${label.text} (Confidence: ${(label.confidence * 100).toStringAsFixed(2)}%)");
        }
      }
    }
    objectDetector.close();

    // 🟡 Image Labeling
    final imageLabeler = ImageLabeler(options: ImageLabelerOptions());
    final labels = await imageLabeler.processImage(inputImage);
    if (labels.isNotEmpty) {
      results.add("\n🔹 Image Labeling:");
      results.addAll(labels.map((label) => "${label.label} (${(label.confidence * 100).toStringAsFixed(2)}%)"));
    }
    imageLabeler.close();

    // 🔵 Text Recognition
    final textRecognizer = TextRecognizer();
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    if (recognizedText.text.isNotEmpty) {
      results.add("\n🔹 Text Recognition:\n${recognizedText.text}");
    }
    textRecognizer.close();

    // 🔴 Face Detection
    final faceDetector = FaceDetector(options: FaceDetectorOptions());
    final faces = await faceDetector.processImage(inputImage);
    if (faces.isNotEmpty) {
      boundingBoxes.addAll(faces.map((face) => face.boundingBox));
      results.add("\n🔹 Face Detection: Detected ${faces.length} face(s)");
    }
    faceDetector.close();

    // 🟠 Barcode Scanning
    final barcodeScanner = BarcodeScanner();
    final barcodes = await barcodeScanner.processImage(inputImage);
    if (barcodes.isNotEmpty) {
      results.add("\n🔹 Barcode Scanning:");
      results.addAll(barcodes.map((barcode) => barcode.rawValue ?? "Unknown"));
    }
    barcodeScanner.close();

    if (mounted) {
      setState(() {
        _detectionResults = results.isNotEmpty ? results.join("\n") : "No features detected.";
        _boundingBoxes = boundingBoxes;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Stack(
        children: [
          // Live Camera Preview
          Positioned.fill(
            child: CameraPreview(_controller),
          ),

          // Bounding Box Overlay
          Positioned.fill(
            child: CustomPaint(
              painter: BoundingBoxPainter(_boundingBoxes),
            ),
          ),

          // Detection Results (Scrollable Overlay)
          Positioned(
            bottom: 10,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _detectionResults,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ),

          // Back Button
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, size: 30, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter to draw bounding boxes
class BoundingBoxPainter extends CustomPainter {
  final List<Rect> boundingBoxes;

  BoundingBoxPainter(this.boundingBoxes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (final rect in boundingBoxes) {
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(BoundingBoxPainter oldDelegate) {
    return oldDelegate.boundingBoxes != boundingBoxes;
  }
}
