import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:image_picker/image_picker.dart';

import '../main.dart';

class CameraView extends StatefulWidget {
  CameraView(
      {Key? key,
        required this.title,
        required this.customPaint,
        required this.onImage,
        this.initialDirection = CameraLensDirection.back})
      : super(key: key);

  final String title;
  final CustomPaint? customPaint;
  final Function(InputImage inputImage) onImage;
  final CameraLensDirection initialDirection;

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {

  CameraController? _controller;
  int _cameraIndex = -1;
  double zoomLevel = 0.0, minZoomLevel = 0.0, maxZoomLevel = 0.0;
  bool _changingCameraLens = false;

  @override
  void initState() {
    super.initState();
    if (cameras.any(
          (element) =>
      element.lensDirection == widget.initialDirection &&
          element.sensorOrientation == 90,
    )) {
      _cameraIndex = cameras.indexOf(
        cameras.firstWhere((element) =>
        element.lensDirection == widget.initialDirection &&
            element.sensorOrientation == 90),
      );
    } else {
      for (var i = 0; i < cameras.length; i++) {
        if (cameras[i].lensDirection == widget.initialDirection) {
          _cameraIndex = i;
          break;
        }
      }
    }

    if (_cameraIndex != -1) {
      _startLiveFeed();
    } else {
    }
  }
  @override
  void dispose() {
    _stopLiveFeed();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
          actions: [
            IconButton(
              icon: Icon(Icons.switch_camera_rounded),
              onPressed: _floatingActionButton,
            ),
          ]
      ),
      body: _body(),
    );
  }

  Widget? _floatingActionButton() {
    if (cameras.length == 1) return null;
    return SizedBox(
        height: 60.0,
        width: 60.0,
        child: FloatingActionButton(
          onPressed: _switchLiveCamera,
          child: Icon(
            Platform.isIOS
                ? Icons.flip_camera_ios_outlined
                : Icons.flip_camera_ios_sharp,
            size: 40,
          ),
        ));
  }

  Widget _body() {
    return _liveFeedBody();
  }

  Widget _liveFeedBody() {
    if (_controller?.value.isInitialized == false) {
      return Container();
    }
    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * _controller!.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Transform.scale(
            scale: scale,
            child: Center(
              child: _changingCameraLens
                  ? Center(
                child: const Text('Changing camera lens'),
              )
                  : CameraPreview(_controller!),
            ),
          ),
          if (widget.customPaint != null) widget.customPaint!,
        ],
      ),
    );
  }
  Future _startLiveFeed() async {
    final camera = cameras[_cameraIndex];
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    _controller?.initialize().then((_) {
      if (!mounted) {
        return;
      }
      _controller?.getMinZoomLevel().then((value) {
        zoomLevel = value;
        minZoomLevel = value;
      });
      _controller?.getMaxZoomLevel().then((value) {
        maxZoomLevel = value;
      });
      _controller?.startImageStream(_processCameraImage);
      setState(() {});
    });
  }

  Future _stopLiveFeed() async {
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }

  Future _switchLiveCamera() async {
    setState(() => _changingCameraLens = true);
    _cameraIndex = (_cameraIndex + 1) % cameras.length;

    await _stopLiveFeed();
    await _startLiveFeed();
    setState(() => _changingCameraLens = false);
  }

///FRAME FUNCTIONALITY UNDER THIS CODE
//   int count=0;
//   void _processCameraImage(CameraImage image) {
//     if (count == 2) {
//       count = 0;
//       return;
//     }
//
//     final inputImage = _inputImageFromCameraImage(image);
//     if (inputImage == null) return;
//
//     widget.onImage(inputImage);
//     print('the frame is : ........................................................hiiiiiiiiiiii $count');
//
//     count++;
//   }

  int count = 0;

  void _processCameraImage(CameraImage image) {
    count++;
    if (count % 2 != 0) {
      return;
    }

    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage! == null) {
      return;
    }

    widget.onImage(inputImage);
    print('the frame is : ........................................................hiiiiiiiiiiii $count');
  }




  InputImage? _inputImageFromCameraImage(CameraImage image) {
    // get camera rotation
    final camera = cameras[_cameraIndex];
    final rotation =
    InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (rotation == null) return null;

    // get image format
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) return null;
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    // compose InputImage using bytes
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation, // used only in Android
        format: format, // used only in iOS
        bytesPerRow: plane.bytesPerRow, // used only in iOS
      ),
    );
  }
}
