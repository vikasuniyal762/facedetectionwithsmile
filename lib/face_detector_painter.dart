import 'dart:ui' as ui;
import 'dart:io'; // Import dart:io for File class
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_cropper/image_cropper.dart'; // Import image_cropper package

class FaceDetectorPainter extends CustomPainter with ChangeNotifier {
  FaceDetectorPainter(this.faces, this.absoluteImageSize, this.rotation, this.pathForImage);

  final List<Face> faces;
  final Size absoluteImageSize;
  final InputImageRotation rotation;
  String pathForImage;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.green;

    for (final Face face in faces) {
      canvas.drawRect(
        Rect.fromLTRB(
          face.boundingBox.left,
          face.boundingBox.top,
          face.boundingBox.right,
          face.boundingBox.bottom,
        ),
        paint,
      );

      if (pathForImage != null && File(pathForImage).existsSync()) {
        _cropAndDrawFace(canvas, face);
      }
    }
  }

  void _cropAndDrawFace(Canvas canvas, Face face) async {
    final ui.Image image = await loadImage(pathForImage);
    final double imageWidth = absoluteImageSize.width;
    final double imageHeight = absoluteImageSize.height;
    final double scaleX = size.width / imageWidth;
    final double scaleY = size.height / imageHeight;

    final Rect boundingBoxRect = Rect.fromLTRB(
      face.boundingBox.left * scaleX,
      face.boundingBox.top * scaleY,
      face.boundingBox.right * scaleX,
      face.boundingBox.bottom * scaleY,
    );

    final Rect canvasRect = Rect.fromLTWH(0, 0, size.width, size.height);

    final ui.Rect cropRect = Rect.fromLTRB(
      boundingBoxRect.left.clamp(0.0, size.width),
      boundingBoxRect.top.clamp(0.0, size.height),
      boundingBoxRect.right.clamp(0.0, size.width),
      boundingBoxRect.bottom.clamp(0.0, size.height),
    );

    // Crop the image to the bounding box of the detected face
    canvas.drawImageRect(image, cropRect, canvasRect, Paint());
  }

  Future<ui.Image> loadImage(String path) async {
    final File imageFile = File(path);
    final Uint8List imageBytes = await imageFile.readAsBytes();
    return decodeImageFromList(imageBytes);
  }

  @override
  bool shouldRepaint(FaceDetectorPainter oldDelegate) {
    return oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.faces != faces;
  }
}

// https://stackoverflow.com/questions/74937208/i-want-to-crop-the-camera-while-previewing-how-do-i-do-that