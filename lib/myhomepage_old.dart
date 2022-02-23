import 'dart:io';
import 'dart:developer';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? imageFile;
  final fileName = DateTime.now().millisecondsSinceEpoch.toString();
  var vidPath;
  void _fileInit() async {
    Directory dir = await getApplicationDocumentsDirectory();
    vidPath = dir.path;
    log('data: $vidPath');
  }

  void _getFromCamera() async {
    XFile? pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxHeight: 1080,
      maxWidth: 1080,
    );
    setState(() {
      imageFile = File(pickedFile!.path);
    });
    File savedImage = await imageFile!.copy('$vidPath/$fileName.jpg');
  }

  @override
  Widget build(BuildContext context) {
    _fileInit();
    return Scaffold(
        body: ListView(
      children: [
        SizedBox(
          height: 50,
        ),
        imageFile != null
            ? Container(
                child: Image.file(imageFile!),
              )
            : Container(
                child: Icon(
                  Icons.camera_enhance_rounded,
                  color: Colors.green,
                  size: MediaQuery.of(context).size.width * .6,
                ),
              ),
        Padding(
          padding: const EdgeInsets.all(30.0),
          child: ElevatedButton(
            child: Text('Capture Image With Camera'),
            onPressed: () {
              _getFromCamera();
            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.purple),
              padding: MaterialStateProperty.all(const EdgeInsets.all(12)),
              textStyle:
                  MaterialStateProperty.all(const TextStyle(fontSize: 12)),
            ),
          ),
        ),
      ],
    ));
  }
}
