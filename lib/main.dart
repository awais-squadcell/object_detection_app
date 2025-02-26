import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/camera_screen.dart';

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
          child: Column(
            children: [
              Spacer(),
              IconButton(
                icon: const Icon(Icons.camera_alt, size: 80, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CameraScreen()),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text('Click to Detect ...',
                    style: TextStyle(fontSize: 16, color: Colors.white)),
              )
            ],
          ),
        ),
      ),
    );
  }
}


