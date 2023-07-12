import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import 'face_detector_view.dart';

List<CameraDescription> cameras = [];
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  cameras = await availableCameras();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Flutter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.switch_camera_rounded),
            onPressed: () {
              // Handle camera switch icon press
            },
          ),
          IconButton(
            icon: Icon(Icons.help),
            onPressed: () {
              // Handle help icon press
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepOrange,Colors.white, Colors.green],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FaceDetectorView()),
              );
            },
            child: const Icon(Icons.camera,size: 50,color:Colors.black),
          ),
        ),
      ),
    );
  }
}
