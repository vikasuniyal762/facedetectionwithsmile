import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

import '../main.dart';

class CameraView extends StatefulWidget {
  CameraView({
    Key? key,
    required this.title,
    required this.customPaint,
    required this.onImage,
    this.initialDirection = CameraLensDirection.back,
  }) : super(key: key);

  final String title;
  final CustomPaint? customPaint;
  final Function(InputImage inputImage) onImage;
  final CameraLensDirection initialDirection;


  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  final ValueNotifier<Duration> _durationNotifier = ValueNotifier(Duration.zero);
  CameraController? _controller;
  int _cameraIndex = -1;
  double zoomLevel = 0.0, minZoomLevel = 0.0, maxZoomLevel = 0.0;
  bool _changingCameraLens = false;
  Timer? _timer;
  bool _isRecording = false;
  int _timerSeconds = 0;



  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopLiveFeed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions:[
          ElevatedButton(
          onPressed: () async {
    if (_isRecording) {
    // Stop recording.
    await _controller?.stopVideoRecording();
    _timer?.cancel();
    setState(() {
    _isRecording = false;
    _timerSeconds = 0;
    });
    } else {
    // Start recording.
    try {
    await _controller?.startVideoRecording();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
    setState(() {
    _timerSeconds++;
    });
    if (_timerSeconds >= 10) {
    _timer?.cancel();
    _controller?.stopVideoRecording();
    setState(() {
    _isRecording = false;
    _timerSeconds = 0;
    });
    }
    });
    setState(() {
    _isRecording = true;
    });
    } on CameraException catch (e) {
    // Handle the camera exception.
    print(e);
    }
    }
    }, child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('$_timerSeconds seconds'),
        TextButton(
          onPressed: null,
          child: _isRecording ? Text('Stop Recording') : Text('Start Recording'),
        )
  ]
      ),
    )
        ],
      ),
      body: _body(),
    );
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


  Future<void> _initializeCamera() async {
    final camera = cameras.firstWhere(
          (element) =>
      element.lensDirection == widget.initialDirection &&
          element.sensorOrientation == 90,
      orElse: () => cameras.firstWhere(
            (element) => element.lensDirection == widget.initialDirection,
        orElse: () => cameras.first,
      ),
    );

    _cameraIndex = cameras.indexOf(camera);
    await _startLiveFeed();
  }

  Future<void> _startLiveFeed() async {
    final camera = cameras[_cameraIndex];
    _controller = CameraController(
      camera,
      ResolutionPreset.max,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await _controller!.initialize();
    zoomLevel = await _controller!.getMinZoomLevel();
    minZoomLevel = zoomLevel;
    maxZoomLevel = await _controller!.getMaxZoomLevel();

    _controller!.startImageStream(_processCameraImage);
    setState(() {});
  }

  Future<void> _stopLiveFeed() async {
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }

  Future<void> _switchLiveCamera() async {
    setState(() => _changingCameraLens = true);
    _cameraIndex = (_cameraIndex + 1) % cameras.length;

    await _stopLiveFeed();
    await _startLiveFeed();
    setState(() => _changingCameraLens = false);
  }


  ///count the frames .....
  int count = 0;
  void _processCameraImage(CameraImage image) {
    if (count % 2 != 0) {
      count++;
      return;
    }
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) return;
    widget.onImage(inputImage);
    print('The frame is: $count');
    count++;
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = cameras[_cameraIndex];
    final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) return null;

    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }
}