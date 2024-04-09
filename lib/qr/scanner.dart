import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:scan/scan.dart';
import 'package:hlvm_mobileapp/prepare/prepare_data.dart';

class QRCodeScannerFromFileForm extends StatefulWidget {
  @override
  _QRCodeScannerFromFileFormState createState() =>
      _QRCodeScannerFromFileFormState();
}

class _QRCodeScannerFromFileFormState extends State<QRCodeScannerFromFileForm> {
  String _scanResult = 'No QR code scanned';
  String? _filePath;

  Future<void> _selectFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'], // разрешенные расширения файлов
    );

    if (result != null) {
      setState(() {
        _filePath = result.files.single.path!;
      });
    }
  }

  Future<void> _parseQRCodeFromFile() async {
    if (_filePath != null) {
      String? qrCode = await Scan.parse(_filePath!);
      if (qrCode != null) {
        setState(() {
          _scanResult = qrCode;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PrepareDataQRCode(data: _scanResult),
            ),
          );
        });
      } else {
        setState(() {
          _scanResult = 'Failed to parse QR code from the selected image';
        });
      }
    } else {
      setState(() {
        _scanResult = 'No file selected';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: _selectFile,
            child: Text('Select Image'),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _parseQRCodeFromFile,
            child: Text('Parse QR Code'),
          ),
          SizedBox(height: 20),
          Center(
            child: Text(
              'Scanned Result: \n$_scanResult',
              style: TextStyle(fontSize: 18, color: Colors.blueGrey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
