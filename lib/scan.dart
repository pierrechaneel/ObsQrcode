import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ScanPage extends StatefulWidget {
  @override
  _ScanPageState createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  Color primaryColor = const Color(0xff000000);
  Color secondaryColor = const Color(0xff000000);
  Color logoGreen = const Color(0xFFf97300);
  String qrCodeResult = "Not Yet Scanned";
  ScanResult? scanResult;
  String? apiResponse;
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController jobController = TextEditingController();
  final _flashOnController = TextEditingController(text: 'Flash on');
  final _flashOffController = TextEditingController(text: 'Flash off');
  final _cancelController = TextEditingController(text: 'Cancel');

  var _aspectTolerance = 0.00;
  var _numberOfCameras = 0;
  var _selectedCamera = -1;
  var _useAutoFocus = true;
  var _autoEnableFlash = false;

  static final _possibleFormats = BarcodeFormat.values.toList()
    ..removeWhere((e) => e == BarcodeFormat.unknown);

  List<BarcodeFormat> selectedFormats = [..._possibleFormats];

  @override
  Widget build(BuildContext context) {
    final scanResult = this.scanResult;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: Color(0xff000000),
        title: Text("Scan QR"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(height: 20),
              _buildApiResponseWidget(),
              if (scanResult != null || apiResponse != null)
                Card(
                  child: Column(
                    children: <Widget>[
                      ListTile(
                        title: Center(
                          child: Text(
                            "Informations sur l'invité",
                            style: TextStyle(fontSize: 20.0, color: Color(0xFFf97300), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      ..._buildKeyValueList(scanResult?.rawContent ?? ""),
                    ],
                  ),
                ),
              const SizedBox(
                height: 20.0,
              ),
              ElevatedButton(
                onPressed: () {
                  _scan();
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(const Color(0xFFf97300)),
                ),
                child: const Text(
                  "Open Scanner",
                  style: TextStyle(color: Color(0xffffffff),fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _scan() async {
    setState(() {
      scanResult = null;
      apiResponse = null;
    });

    try {
      final result = await BarcodeScanner.scan(
        options: ScanOptions(
          strings: {
            'cancel': _cancelController.text,
            'flash_on': _flashOnController.text,
            'flash_off': _flashOffController.text,
          },
          restrictFormat: selectedFormats,
          useCamera: _selectedCamera,
          autoEnableFlash: _autoEnableFlash,
          android: AndroidOptions(
            aspectTolerance: _aspectTolerance,
            useAutoFocus: _useAutoFocus,
          ),
        ),
      );
      setState(() => scanResult = result);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Données envoyées, Veuillez patienter !'),
        duration: Duration(seconds: 3),
      ));

      await sendDataToAPI(context, result.rawContent);
    } on PlatformException catch (e) {
      setState(() {
        scanResult = ScanResult(
          type: ResultType.Error,
          rawContent: e.code == BarcodeScanner.cameraAccessDenied
              ? 'The user did not grant the camera permission!'
              : 'Unknown error: $e',
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur lors de l\'envoi des données : $e'),
        duration: Duration(seconds: 15),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Fermer',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ));
    }
  }

  Future<void> sendDataToAPI(BuildContext context, String scannedData) async {
    try {
      String apiUrl = "http://10.25.2.121:9996/api/controls";
      Map<String, dynamic> qrData = jsonDecode(scannedData);

      Map<String, dynamic> jsonData = {
        'name': qrData['name'],
        'email': qrData['email'],
        'tel': qrData['tel'],
        'date': qrData['date'],
        'heure': qrData['heure'],
        'eventId': qrData['eventId'],
        'id': qrData['id'],
      };

      String jsonDataString = jsonEncode(jsonData);

      http.Response response = await http.post(
        Uri.parse(apiUrl),
        body: jsonDataString,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Données envoyées, Veuillez patienter !'),
          duration: Duration(seconds: 20),
          action: SnackBarAction(
            label: 'Fermer',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
          behavior: SnackBarBehavior.floating,
        ));
      } else {
        Map<String, dynamic> responseData = json.decode(response.body);
        String message = responseData['message'];
        setState(() {
          apiResponse = message;
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$message'),
          duration: Duration(seconds: 20),
          action: SnackBarAction(
            label: 'Fermer',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur lors de l\'envoi des données : $e'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  List<Widget> _buildKeyValueList(String rawData) {
    if (rawData.isEmpty) {
      return [];
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(rawData);
    } catch (e) {
      return [Text("Données scannées non valides")];
    }

    List<String> excludedKeys = ['id', 'eventId', 'date'];
    List<Widget> widgets = [];

    data.forEach((key, value) {
      if (!excludedKeys.contains(key)) {
        widgets.add(
          ListTile(
            title: Text(key),
            subtitle: Text(value.toString()),
          ),
        );
      }
    });

    return widgets;
  }


  Widget _buildApiResponseWidget() {
    if (apiResponse != null) {
      return Card(
        child: Column(
          children: <Widget>[
            ListTile(
              title: Text('Réponse'),
              subtitle: Text(apiResponse!),
            ),
          ],
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }
}
