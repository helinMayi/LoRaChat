import 'dart:core';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:device_info/device_info.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lora_chat/NavigationBar.dart';


class ChooseDevice extends StatefulWidget {
  const ChooseDevice({super.key});
  static BluetoothCharacteristic? targetCharacteristic_send;
  static BluetoothCharacteristic? targetCharacteristic_receive;
  static BluetoothDevice? targetDevice;
  @override
  State<ChooseDevice> createState() => _ChooseDeviceState();
}

class _ChooseDeviceState extends State<ChooseDevice> {
  bool isON = false;
  String connectionText = "";
  FlutterBlue blueObj = FlutterBlue.instance;
  StreamSubscription <ScanResult>? scanResult;
  StreamSubscription<BluetoothDeviceState>? state_check;
  late List<BluetoothService> service;
  List<ScanResult> discoveredDevices = [];
  bool isScanning = false;
  //incoming data from/to LoRa
  String? readDataStr;
  late String SessionAlertDialog;

  @override
  void initState() {
    super.initState();
  }
  // Determine whether the current [context] has been granted the relevant [Permission].
  Future<bool> hasPermission(BuildContext context, Permission permission) async {
    var status = await permission.request().isGranted;
    return status;
  }
  // Determine whether the current [context] has been granted the relevant permissions to perform
  // Bluetooth operations depending on the mobile device's Android version.
  Future<bool> hasRequiredBLEPermissions(BuildContext context) async{
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if(Platform.isAndroid && int.parse(androidInfo.version.release) >= 12){
      return await hasPermission(context, Permission.bluetoothScan) && await hasPermission(context, Permission.bluetoothConnect);
    } else {
      return await hasPermission(context, Permission.locationWhenInUse);
    }
  }
  enableScan() async {
    await hasRequiredBLEPermissions(context);
    isScanning = true;
    setState(() {
      connectionText = "Start Scanning...";
    });
    if (await Permission.bluetoothConnect.request().isGranted && await Permission.location.request().isGranted) {
      scanResult = blueObj.scan().listen((scanResult) async {
        if (!discoveredDevices.contains(scanResult.device)) {
          discoveredDevices.add(scanResult);
          setState(() {
            if (kDebugMode) {
              print(scanResult);
            }
          });
        }
      }
      );
    } else {
      setState(() {
        connectionText = "access denied";
      });
    }
  }
  //Pair
  pairWithDevice() async {
    if (ChooseDevice.targetDevice == null){
      if (kDebugMode) {
        print("target device null");
        return;
      }
    }
    await ChooseDevice.targetDevice?.connect();
    setState(() {
      if (kDebugMode) {
        print("connected");
      }
    });
    if(ChooseDevice.targetDevice != null){
      if (kDebugMode) {
        print("target device not null");
      }
      isScanning = false;
      blueObj.stopScan();
      //navigate to the home page
       Navigator.push(context, MaterialPageRoute(
           builder: (context) => Navigation()));
    }
    state_check = ChooseDevice.targetDevice?.state.listen((BluetoothDeviceState state) async {
      if (state == BluetoothDeviceState.disconnected) {
        ShowDialog(context);
      }
    });
    discoverService();
  }
  // define services and characteristics
  discoverService() async {
    service = await ChooseDevice.targetDevice!.discoverServices();
    service.forEach((service) {
      print('Service UUID: ${service.uuid}');
        service.characteristics.forEach((characteristic) async {
          if (kDebugMode) {
            print('Characteristic UUID: ${characteristic.uuid}');
            print('Properties: ${characteristic.properties}');
          }
          // check properties
          if(characteristic.properties.write){
            print("write");
            setState(() {
              ChooseDevice.targetCharacteristic_receive = characteristic;
            });
          } else if(characteristic.properties.read){
            print("read");
            setState(() {
              ChooseDevice.targetCharacteristic_send = characteristic;
            });
          }
        });
    });
  }
  //Bluetooth connection loss dialog
  Future ShowDialog(BuildContext context) async{
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        //backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.all(20),
        title: const Text("Warning!"),
        content: const Text("Lost Connection, please completely close and reopen the app.",
        style: TextStyle(
          color: Colors.black
        )),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("LoRa",
          style: Theme.of(context).textTheme.headlineMedium,),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(
              color: const Color.fromRGBO(41, 41, 41, 0.5), // Color of the divider
              height: 1.0, // Thickness of the divider
            ),
          ),
        ),
      body: Container(
    width: double.maxFinite,
    padding: const EdgeInsets.symmetric(horizontal: 23,vertical: 40),
    child: Column(
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      const SizedBox(height: 30),
        Expanded(
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'On',
                style: TextStyle(
                  fontSize: 20,
                  color:  Color.fromRGBO(23, 129, 215,0.5),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Switch(
                value: isScanning,
                onChanged: (value) {
                  // Start or stop scanning based on switch value
                  if (value) {
                    enableScan();
                  } else {
                    blueObj.stopScan();
                    setState(() {
                      isScanning = false;
                    });
                  }
                },
              ),
            ],
          ),
          if (isScanning || discoveredDevices.isNotEmpty)
      Expanded(
        child: ListView.builder(
          itemCount: discoveredDevices.length,
          itemBuilder: (context, index){
            final device = discoveredDevices[index].device;
            return  ListTile(
            leading: const Icon(Icons.bluetooth),
            title: Text(device.name.isNotEmpty ? device.name : 'Unknown Device'),
            subtitle: Text(device.id.toString()),
            onTap: () {
              if (kDebugMode) {
                print('Selected device: ${device.name}');
              }
              setState(() {
                ChooseDevice.targetDevice = discoveredDevices[index].device;
              });
              pairWithDevice(); // Connect to the selected device
    },
            );
    },
    ),
      ),
    ],
    ),
    ),
    ),
    ],
    ),
    ),
    ),
    );
  }
}