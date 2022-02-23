import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

import '../main.dart';
import 'dart:async';
import 'dart:math' as math;

enum ScreenMode { liveFeed }

class CameraView extends StatefulWidget {
  CameraView(
      {Key? key,
      required this.title,
      // required this.customPaint,
      required this.face,
      required this.onImage,
      this.initialDirection = CameraLensDirection.back})
      : super(key: key);

  final String title;
  // final CustomPaint? customPaint;
  final Face? face;
  final Function(InputImage inputImage) onImage;
  final CameraLensDirection initialDirection;
  String? emotion = '';
  String? eyes = '';
  String? head = '';
  String? noface = '';
  Rect? boundingbox;

  int? eyesopencnt = 0;
  int? eyesclosecnt = 0;
  int? headstcnt = 0;
  int? headleftcnt = 0;
  int? headrightcnt = 0;
  int? smilecnt = 0;
  int? notsmilecnt = 0;
  int? neutralcnt = 0;
  int? brightcnt = 0;
  int? nofacecnt = 0;
  int? framenum = 0;
  static Map? metrics;

  // Whether or not the rectangle is displayed
  bool? isRectangleVisible = false;

  // Holds the position information of the rectangle
  Map<String, double> position = {
    'x': 250,
    'y': 200,
    'w': 400,
    'h': 400,
  };

  // Some logic to get the rectangle values
  void updateRectanglePosition() {
    // setState(() {
    // assign new position
    Rect? bb = boundingbox;
    position = {
      'x': bb?.left as double,
      'y': (bb?.top)! * 3 / 4,
      'w': (bb?.width)! * 3 / 4.5,
      'h': (bb?.height)! * 3 / 3.5,
    };
    isRectangleVisible = true;
    //});
  }

  @override
  _CameraViewState createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  CameraController? _controller;
  int _cameraIndex = 0;
  double zoomLevel = 0.0, minZoomLevel = 0.0, maxZoomLevel = 0.0;

  @override
  void initState() {
    super.initState();

    for (var i = 0; i < cameras.length; i++) {
      if (cameras[i].lensDirection == widget.initialDirection) {
        _cameraIndex = i;
      }
    }
    _startLiveFeed();
  }

  @override
  void dispose() {
    _stopLiveFeed();
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 20.0),
          ),
        ],
      ),
      body: _body(),
      floatingActionButton: _floatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  bool _hasBeenPressed = false;

  Widget? _floatingActionButton() {
    // if (_hasBeenPressed) {
    //   startVideoRecording();
    // }
    return Container(
      margin: EdgeInsets.all(5),
      child: ElevatedButton(
        // style: TextButton.styleFrom(
        //   primary: Colors.blue,
        //   onSurface: Colors.red,
        // ),
        // onPressed: () {
        //   startVideoRecording();
        // },
        // child: Text('start Recording'),
        onPressed: () {
          setState(() {
            _hasBeenPressed = !_hasBeenPressed;
          });
        },
        child: Text(_hasBeenPressed ? 'Stop Recording' : 'Start Recording'),
        style: ElevatedButton.styleFrom(
          primary: _hasBeenPressed ? Colors.red : Colors.orange,
        ),
      ),
    );
  }

  late Timer timer;
  int _start = 5;

  void startTimer() {
    const oneSec = const Duration(seconds: 1);
    timer = new Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_start == 0) {
          setState(() {
            timer.cancel();
          });
        } else {
          setState(() {
            _start--;
          });
        }
      },
    );
  }

  Widget _metrics() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Container(
        //       margin: const EdgeInsets.only(left: 10.0, right: 10.0),
        //     ),
        Padding(
          padding: EdgeInsets.fromLTRB(10, 560, 20,
              20), //apply padding to LTRB, L:Left, T:Top, R:Right, B:Bottom
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Eyes: Straight'),
            Text('Head Position: Tilted to the side'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Emotion: Smiling'),
            Text('Brightness: Good'),
          ],
        ),
      ],
    );
  }

  Widget _body() {
    Widget body;
    body = _liveFeedBody();
    return body;
  }

  // Widget _liveFeedBody() {
  //   // _metrics();
  //   if (_controller?.value.isInitialized == false) {
  //     return Container();
  //   }
  //   return Container(
  //     color: Colors.black,
  //     child: Stack(
  //       fit: StackFit.expand,
  //       children: <Widget>[
  //         CameraPreview(_controller!),
  //         // if (widget.customPaint != null) widget.customPaint!,
  //       ],
  //     ),
  //   );
  // }

  Widget _liveFeedBody() {
    // _metrics();
    if (_controller?.value.isInitialized == false) {
      return Container();
    }
    return Container(
        child: Column(
      children: [
        Stack(children: [
          Container(
            alignment: Alignment.center,
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.75,
            child: Transform(
                alignment: Alignment.center,
                child: CameraPreview(_controller!),
                transform: Matrix4.rotationY(math.pi)),
          ),
          // Visibility(
          //   visible: _recShown,
          //   child: Container(
          //     margin: EdgeInsets.only(top: 28, left: 300),
          //     child: Text('REC',
          //         style:
          //             TextStyle(color: Colors.red, fontSize: 20)),
          //   ),
          // ),
          // Visibility(
          //   visible: _recShown,
          //   child: Container(
          //     margin: EdgeInsets.only(top: 30, left: 340),
          //     child: CustomPaint(
          //       painter: OpenPainter(),
          //     ),
          //   ),
          // ),
          // Visibility(
          //   visible: _timerShown,
          //   child: Container(
          //     alignment: Alignment.center,
          //     margin: EdgeInsets.only(top: 250),
          //     child: Text("$_start",
          //         textAlign: TextAlign.center,
          //         style: TextStyle(
          //             color: Colors.white,
          //             fontWeight: FontWeight.bold,
          //             fontSize: 100)),
          //   ),
          // ),
          Container(
            height: 80,
            width: double.infinity,
            color: Colors.black.withOpacity(0.5),
            margin: EdgeInsets.only(top: 500),
            padding: EdgeInsets.all(200),
          ),
          // Visibility(
          //   visible: _nofaceShown,
          //   child: Container(
          //     margin: EdgeInsets.only(top: 470),
          //     alignment: Alignment.center,
          //     child: Text('${_.noface}',
          //         style: TextStyle(
          //           fontSize: 20,
          //           color: Colors.red,
          //         )),
          //   ),
          // ),
          if (widget.face != null &&
              widget.face?.smilingProbability != null &&
              widget.face?.rightEyeOpenProbability != null &&
              widget.face?.leftEyeOpenProbability != null)
            Positioned(
              bottom: 36,
              left: 0,
              child: Column(
                children: <Widget>[
                  if (detectEyes(widget.face?.rightEyeOpenProbability!,
                          widget.face?.leftEyeOpenProbability!) ==
                      'Eyes opened')
                    Text('Eyes: Opened',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.greenAccent[400],
                        )),
                  if (detectEyes(widget.face?.rightEyeOpenProbability!,
                          widget.face?.leftEyeOpenProbability!) ==
                      'Eyes closed')
                    Text('Eyes: Closed',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.redAccent[400],
                        )),
                  if (detectSmile(widget.face?.smilingProbability!) ==
                      'Smiling')
                    Text('Emotion: Smiling',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.greenAccent[400],
                        )),
                  if (detectSmile(widget.face?.smilingProbability!) ==
                      'Neutral')
                    Text('Emotion: Neutral',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.orange,
                        )),
                  if (detectSmile(widget.face?.smilingProbability!) ==
                      'Not Smiling')
                    Text('Emotion: Not Smiling',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.redAccent[400],
                        )),
                ],
              ),
            ),
          if (widget.face != null &&
              widget.face?.headEulerAngleY != null &&
              widget.face?.rightEyeOpenProbability != null &&
              widget.face?.leftEyeOpenProbability != null)
            Positioned(
              bottom: 36,
              right: 0,
              child: Column(
                children: <Widget>[
                  if (detectHead(widget.face?.headEulerAngleY!) == 'Left')
                    Text('Head Position: Left',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.redAccent[400],
                        )),
                  if (detectHead(widget.face?.headEulerAngleY!) == 'Right')
                    Text('Head Position: Right',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.redAccent[400],
                        )),
                  if (detectHead(widget.face?.headEulerAngleY!) == 'Straight')
                    Text('Head Position: Straight',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.greenAccent[400],
                        )),
                  if (detectEyes(widget.face?.rightEyeOpenProbability!,
                          widget.face?.leftEyeOpenProbability!) ==
                      'Eyes opened')
                    Text('Brightness: Good',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.greenAccent[400],
                        )),
                  if (detectEyes(widget.face?.rightEyeOpenProbability!,
                          widget.face?.leftEyeOpenProbability!) ==
                      'Eyes closed')
                    Text('Brightness: Bad',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.redAccent[400],
                        )),
                ],
              ),
            ),
          if (widget.isRectangleVisible!)
            Positioned(
              left: widget.position['x'],
              top: widget.position['y'],
              child: InkWell(
                child: Container(
                  width: widget.position['w'],
                  height: widget.position['h'],
                  decoration: BoxDecoration(
                    border: Border.all(
                      width: 2,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ),
            ),
        ])
      ],
    ));
  }

  String detectSmile(smileProb) {
    if (smileProb > 0.7) {
      return 'Smiling';
    } else if (smileProb! > 0.2) {
      return 'Neutral';
    } else {
      return 'Not Smiling';
    }
  }

  String detectEyes(right, left) {
    if (right! > 0.1 && left! > 0.1) {
      return 'Eyes opened';
    } else {
      return 'Eyes closed';
    }
  }

  String detectHead(headposeProb) {
    if (headposeProb! > 10) {
      return 'Left';
    } else if (headposeProb! < -10) {
      return 'Right';
    } else {
      return 'Straight';
    }
  }

  Future _startLiveFeed() async {
    final camera = cameras[_cameraIndex];
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: true,
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

  Future _processCameraImage(CameraImage image) async {
    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize =
        Size(image.width.toDouble(), image.height.toDouble());

    final camera = cameras[_cameraIndex];
    final imageRotation =
        InputImageRotationMethods.fromRawValue(camera.sensorOrientation) ??
            InputImageRotation.Rotation_0deg;

    final inputImageFormat =
        InputImageFormatMethods.fromRawValue(image.format.raw) ??
            InputImageFormat.NV21;

    final planeData = image.planes.map(
      (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList();

    final inputImageData = InputImageData(
      size: imageSize,
      imageRotation: imageRotation,
      inputImageFormat: inputImageFormat,
      planeData: planeData,
    );

    final inputImage =
        InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);

    widget.onImage(inputImage);
  }
}
