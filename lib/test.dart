import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:widgetstry/xFile.dart';
import 'coordinates_translator.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class FaceDetectorPainter extends CustomPainter {
  FaceDetectorPainter(this.faces, this.absoluteImageSize, this.rotation);
  String pathForImage=videoFile!.path;
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

      // Generate a thumbnail image from the video
      // Directory? dir = await getTemporaryDirectory();
      // String finalPath = "${dir.path}/video.mp4";
      await VideoThumbnailGenerator.generateThumbnail(pathForImage);

      // Bounding box of the detected face
      final rect=ui.Rect.fromLTRB(
        face.boundingBox.left,
        face.boundingBox.top,
        face.boundingBox.right,
        face.boundingBox.bottom,
      );

      // Crop the image to the bounding box of the detected face
      final croppedFile = await ImageCropper.cropImage(
        imagePath: pathForImage,
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

      // Save the cropped image to a file
      if (croppedFile != null) {
        final File croppedImageFile=File('${Directory.systemTemp.path}/image.jpg');
        await croppedImageFile.writeAsBytes(await File(pathForImage).readAsBytes());
      }
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
  static Future<File?> cropImage({
    String? imagePath,
    required List<CropAspectRatioPreset> aspectRatioPresets,
    required AndroidUiSettings androidUiSettings,
    required IOSUiSettings iosUiSettings,
  }) async {
    try {
      // Call the cropImage function from the image_cropper package
      final croppedFile = await ImageCropper.cropImage(
        imagePath: imagePath,
        aspectRatioPresets: aspectRatioPresets,
        androidUiSettings: androidUiSettings,
        iosUiSettings: iosUiSettings,
      );
      print(
          "1###################################################################### $croppedFile");

      // Return the cropped image file
      return croppedFile;
    } catch (e) {
      print("Error occurred while cropping the image: $e");
      // Handle the error here, such as displaying an error message to the user.
      return null;
    }
  }
}