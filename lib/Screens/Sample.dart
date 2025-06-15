import 'dart:io';
import 'dart:nativewrappers/_internal/vm/lib/typed_data_patch.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img; // مكتبة لتحويل وتغيير حجم الصورة

class ImageClassificationPage extends StatefulWidget {
  @override
  _ImageClassificationPageState createState() => _ImageClassificationPageState();
}

class _ImageClassificationPageState extends State<ImageClassificationPage> {
  File? _image;
  List<dynamic>? _results;
  bool _isLoading = false;
  late Interpreter _interpreter;

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/Model/cnn_model.tflite');
      print("Model loaded successfully!");
    } catch (e) {
      print("Error loading model: $e");
    }
  }

  Future<void> _selectImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _isLoading = true;
        _image = File(pickedImage.path);
      });

      classifyImage(_image!);
    }
  }

  // دالة لتغيير حجم الصورة
  img.Image resizeImage(img.Image inputImage, int width, int height) {
    return img.copyResize(inputImage, width: width, height: height);
  }

  // دالة لتصنيف الصورة
  Future<void> classifyImage(File image) async {
    // تحويل الصورة باستخدام مكتبة image
    img.Image inputImage = img.decodeImage(image.readAsBytesSync())!;
    img.Image resizedImage = resizeImage(inputImage, 224, 224); // تغيير الحجم إلى 224x224

    // تحويل الصورة إلى Uint8List
    Uint8List imageBytes = Uint8List.fromList(resizedImage.getBytes());

    // استخدم الدالة المناسبة لتشغيل النموذج
    var output = List.filled(1 * 1001, 0).reshape([1, 1001]); // افتراض أن الخرج هو 1001
    _interpreter.run(imageBytes as Object, output);

    setState(() {
      _isLoading = false;
      _results = output;
    });
  }

  @override
  void dispose() {
    _interpreter.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Classification Demo'),
      ),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : (_image == null
            ? Text('No image selected.')
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.file(_image!),
            SizedBox(height: 20),
            _results != null
                ? Text(
              'Result: ${_results![0]}',
              style: TextStyle(fontSize: 20),
            )
                : Text('No classification result.'),
          ],
        )),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _selectImage,
        tooltip: 'Select Image',
        child: Icon(Icons.image),
      ),
    );
  }
}
