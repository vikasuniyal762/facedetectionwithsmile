import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'face_detector_painter.dart';
import 'camera_view.dart';

class FaceDetectorView extends StatefulWidget {  //FaceDetectorView responsible for managing the state of the face detection view
  @override
  State<FaceDetectorView> createState() => _FaceDetectorViewState();
}
class _FaceDetectorViewState extends State<FaceDetectorView> {
  final FaceDetector _faceDetector = FaceDetector(   //FaceDetectorView object or instance is created
    options: FaceDetectorOptions(
      enableContours: true,
     enableClassification: true,
    ),
  );
  bool _canProcess = true; //use to control the processing flow prevent multiple simultaneous image processing.
  bool _isBusy = false; //use to control the processing flow prevent multiple simultaneous image processing.
  CustomPaint? _customPaint; //used to draw the contours of detected faces on the UI.
 // String? _text;

  @override
  void dispose() {  //method is overridden to clean up resources when the widget is disposed.
    _canProcess = false;
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CameraView(
        customPaint: _customPaint,
       // text: _text,
        onImage: processImage,
        initialDirection: CameraLensDirection.back,
        title: 'Camera',
      ),
    );
  }
/*It is called by the onImage callback of the CameraView widget
//processImage method is defined to perform face detection on the captured input image */
  Future<void> processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    final faces = await _faceDetector.processImage(inputImage);
    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null) {
      final painter = FaceDetectorPainter(
          faces, inputImage.metadata!.size, inputImage.metadata!.rotation);
      _customPaint = CustomPaint(painter: painter);


      /// to count the smiling face in camera
      final int numSmilingFaces = faces.fold(0, (count, face) {
        if (face.smilingProbability != null && face.smilingProbability! > 0.5) {
          return count + 1;
        }
        return count;
      });
      print('Number of smiling faces: $numSmilingFaces');
     /// Additional code for detecting the state of the right and left eyes
      for (Face face in faces) {
        String rightEyeState = 'Closed';
        if (face.rightEyeOpenProbability != null &&
            face.rightEyeOpenProbability! > 0.5) {
          rightEyeState = 'Open';
        }
        String leftEyeState = 'Closed';
        if (face.leftEyeOpenProbability != null &&
            face.leftEyeOpenProbability! > 0.5) {
          leftEyeState = 'Open';
        }
        print('Right eye state: $rightEyeState');
        print('Left eye state: $leftEyeState');
      }

    } else {
      String text = 'Faces found: ${faces.length}\n\n';
      for (final face in faces) {
        text += 'face: ${face.boundingBox}\n\n';
      }
      ///OPERATIONS ON FACES.LENGTH

      _customPaint = null;
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }
}