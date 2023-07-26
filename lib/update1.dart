import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:widgetstry/xFile.dart';
import 'coordinates_translator.dart';


class FaceDetectorPainter extends CustomPainter with ChangeNotifier {
  FaceDetectorPainter(this.faces, this.absoluteImageSize, this.rotation, this.pathForImage);

  final List<Face> faces;
  final Size absoluteImageSize;
  final InputImageRotation rotation;
  String pathForImage=videoXFile!.path;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.green;

    for (final Face face in faces) {
      canvas.drawRect(
        Rect.fromLTRB(
          translateX(face.boundingBox.left, rotation, size, absoluteImageSize),
          translateY(face.boundingBox.top, rotation, size, absoluteImageSize),
          translateX(face.boundingBox.right, rotation, size, absoluteImageSize),
          translateY(face.boundingBox.bottom, rotation, size, absoluteImageSize),
        ),
        paint,
      );
    }

    // Crop the image to the bounding box of the detected face
    cropTheImage();
  }

  Future<void> cropTheImage() async {
    if (pathForImage == null || cropImage == false) {
      return;
    }
    final File videoFile = File(pathForImage);
    cropImage = true;
    var cropped = await ImageCropper.platform.cropImage(

      sourcePath: videoFile.path, // Enter your imageFile Path here
      uiSettings: [
        AndroidUiSettings(lockAspectRatio: false),

      ],
    );
    if (cropped != null) {
      croppedFile = File(cropped.path);
      // notifyListeners(); // Notify the widget tree that a redraw is needed
    }
  }

  late final File croppedFile;
  bool cropImage = false;

  @override
  bool shouldRepaint(FaceDetectorPainter oldDelegate) {
    return oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.faces != faces ||
        oldDelegate.cropImage != cropImage;
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: FaceDetectorPainter(faces, absoluteImageSize, rotation,pathForImage),
    );
  }

}
