import 'dart:io';
import 'dart:ui' as ui;
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'coordinates_translator.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class FaceDetectorPainter extends CustomPainter {
  FaceDetectorPainter(this.faces, this.absoluteImageSize, this.rotation);

  final List<Face> faces;
  final Size absoluteImageSize;
  final InputImageRotation rotation;

  @override
  Future<void> paint(Canvas canvas, Size size) async {
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
          translateY(
              face.boundingBox.bottom, rotation, size, absoluteImageSize),
        ),
        paint,
      );
      final thumbnail = await VideoThumbnailGenerator.generateThumbnail('path/to/video');
      final rect = ui.Rect.fromLTRB(
        face.boundingBox.left,
        face.boundingBox.top,
        face.boundingBox.right,
        face.boundingBox.bottom,
      );
      final croppedImage = await ImageCropper.cropImage(
        imagePath: 'path/to/image',
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9
        ],
        androidUiSettings: AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        iosUiSettings: IOSUiSettings(
          title: 'Crop Image',
        ),
      );

      // void paintContour(FaceContourType type) {
      //   final faceContour = face.contours[type];
      //   if (faceContour?.points != null) {
      //     for (final Point point in faceContour!.points) {
      //       canvas.drawCircle(
      //           Offset(
      //             translateX(
      //                 point.x.toDouble(), rotation, size, absoluteImageSize),
      //             translateY(
      //                 point.y.toDouble(), rotation, size, absoluteImageSize),
      //           ),
      //           1,
      //           paint);
      //     }
      //   }
      // }

      // paintContour(FaceContourType.face);
      // paintContour(FaceContourType.leftEyebrowTop);
      // paintContour(FaceContourType.leftEyebrowBottom);
      // paintContour(FaceContourType.rightEyebrowTop);
      // paintContour(FaceContourType.rightEyebrowBottom);
      // paintContour(FaceContourType.leftEye);
      // paintContour(FaceContourType.rightEye);
      // paintContour(FaceContourType.upperLipTop);
      // paintContour(FaceContourType.upperLipBottom);
      // paintContour(FaceContourType.lowerLipTop);
      // paintContour(FaceContourType.lowerLipBottom);
      // paintContour(FaceContourType.noseBridge);
      // paintContour(FaceContourType.noseBottom);
      // paintContour(FaceContourType.leftCheek);
      // paintContour(FaceContourType.rightCheek);
    }
  }

  @override
  bool shouldRepaint(FaceDetectorPainter oldDelegate) {
    return oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.faces != faces;
  }
}

class VideoThumbnailGenerator {
  static Future<ui.Image> generateThumbnail(String videoPath) async {
    final uint8list = await VideoThumbnail.thumbnailData(
      video: videoPath,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 128,
      quality: 25,
    );
    final codec = await ui.instantiateImageCodec(uint8list!);
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}

class ImageCropper {
  static Future<String?> cropImage(
      {String? imagePath,
      required List<CropAspectRatioPreset> aspectRatioPresets,
      required AndroidUiSettings androidUiSettings,
      required IOSUiSettings iosUiSettings}
      ) async {
    final cropper = ImageCropper();
    final croppedFile = await cropper._cropImage(
        imagePath: imagePath,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9
        ],
        androidUiSettings: AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        iosUiSettings:
            IOSUiSettings(title: 'Crop Image', aspectRatioLockEnabled: false));
    print("1###################################################################### $croppedFile");
    return croppedFile;
  }

  Future<String?> _cropImage({
    String? imagePath,
    required List<CropAspectRatioPreset> aspectRatioPresets,
    required AndroidUiSettings androidUiSettings,
    required IOSUiSettings iosUiSettings,
  }) async {
    final croppedFile = await ImageCropper.cropImage(
      imagePath: imagePath,
      aspectRatioPresets: aspectRatioPresets,
      androidUiSettings: androidUiSettings,
      iosUiSettings: iosUiSettings,
    );
    print("2###################################################################### $croppedFile");
    return croppedFile;
  }
}
