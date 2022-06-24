import 'dart:async';
import 'dart:typed_data';

import 'package:barcode/barcode.dart';
import 'package:barcode_image/barcode_image.dart';
import 'package:bluetooth_thermal_printer/bluetooth_thermal_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart' hide Barcode;
import 'package:flutter/material.dart' hide Image;
import 'package:image/image.dart';
import 'package:qr_flutter/qr_flutter.dart';

class BlueToothThermalScreen extends StatefulWidget {
  @override
  _BlueToothThermalScreenState createState() => _BlueToothThermalScreenState();
}

class _BlueToothThermalScreenState extends State<BlueToothThermalScreen> {
  @override
  void initState() {
    super.initState();
  }

  bool connected = false;
  List? availableBluetoothDevices = [];

  Future<void> getBluetooth() async {
    final List? bluetooths = await BluetoothThermalPrinter.getBluetooths;
    debugPrint("Print $bluetooths");
    setState(() {
      availableBluetoothDevices = bluetooths;
    });
  }

  Future<void> setConnect(String mac) async {
    debugPrint("try to connect");
    final String? result = await BluetoothThermalPrinter.connect(mac);
    debugPrint("state conneected $result");
    if (result == "true") {
      setState(() {
        connected = true;
      });
    }
  }

  Future<void> printTicket() async {
    String? isConnected = await BluetoothThermalPrinter.connectionStatus;
    if (isConnected == "true") {
      List<int> bytes = await printSampleText();
      final result = await BluetoothThermalPrinter.writeBytes(bytes);
      debugPrint("Print $result");
    } else {
      //Hadnle Not Connected Senario
    }
  }

  Future<void> printGraphics() async {
    String? isConnected = await BluetoothThermalPrinter.connectionStatus;
    if (isConnected == "true") {
      List<int> bytes = await printQrCode();
      final result = await BluetoothThermalPrinter.writeBytes(bytes);
      debugPrint("Print $result");
    } else {
      //Hadnle Not Connected Senario
    }
  }

  Future<List<int>> printQrCode() async {
    List<int> bytes = [];

    CapabilityProfile profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);

    // Create an image
    final image = Image(300, 300);

    // Fill it with a solid color (white)
    fill(image, getColor(255, 255, 255));

    // Draw the barcode
    drawBarcode(image, Barcode.qrCode(), "Yellow mellow", font: arial_24);
    bytes += generator.image(image);

    bytes += generator.text("Home");
    Uint8List data = Uint8List.fromList(image.data);
    QrCode.fromUint8List(data: data, errorCorrectLevel: QrErrorCorrectLevel.L);
    bytes += generator.hr();

    // Print Barcode using native function
    final List<int> barData = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 4];
    // bytes += generator.barcode(Barcode.upcA());

    bytes += generator.cut();

    return bytes;
  }

  Future<List<int>> printSampleText() async {
    List<int> bytes = [];
    CapabilityProfile profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);

    bytes += generator.text("Sample text",
        styles: const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
        linesAfter: 1);

    bytes += generator.text("Type you centered text here",
        styles: const PosStyles(align: PosAlign.center));

    // Hr lines ---------
    bytes += generator.hr();

    // Row
    bytes += generator.row([
      /* column width should add up to 12 */
      PosColumn(
          text: "Title sample: ",
          width: 6,
          styles: const PosStyles(
            align: PosAlign.left,
          )),
      PosColumn(
          text: "Price sample",
          width: 6,
          styles: const PosStyles(
            align: PosAlign.center,
          )),
    ]);

    // Hr lines =======
    bytes += generator.hr(ch: '=', linesAfter: 1);

    // ticket.feed(2);
    bytes += generator.text('Have fun!',
        styles: const PosStyles(align: PosAlign.center, bold: true));

    bytes += generator.cut();
    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Bluetooth Thermal Printer Demo'),
        ),
        body: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Search Paired Bluetooth"),
              TextButton(
                onPressed: () {
                  getBluetooth();
                },
                child: const Text("Search"),
              ),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: (availableBluetoothDevices?.length ?? 0) > 0
                      ? availableBluetoothDevices?.length
                      : 0,
                  itemBuilder: (context, index) {
                    return ListTile(
                      onTap: () {
                        String select = availableBluetoothDevices?[index];
                        List list = select.split("#");
                        // String name = list[0];
                        String mac = list[1];
                        setConnect(mac);
                      },
                      title: Text('${availableBluetoothDevices?[index]}'),
                      subtitle: const Text("Click to connect"),
                    );
                  },
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              TextButton(
                onPressed: connected ? printGraphics : null,
                child: const Text("Print"),
              ),
              TextButton(
                onPressed: connected ? printTicket : null,
                child: const Text("Print Ticket"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
