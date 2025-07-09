import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:lora_chat/bluetoothConnect.dart';
import 'package:lora_chat/shared_pref.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});
  @override
  State<Signup> createState() => SignupState();
}

class SignupState extends State<Signup> {
  TextEditingController phoneCont = TextEditingController();
  TextEditingController nameCont = TextEditingController();
  TextEditingController emailCont = TextEditingController();
  String? genderCont;
  TextEditingController birthCont = TextEditingController();
  TextEditingController countryCont = TextEditingController();
  TextEditingController cityCont = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  //Add account to database
  Future addUser (String json_user) async {
    isSignedIn = true;
    await sharedPref.setBool("signed",isSignedIn);
    await sharedPref.setString("userAdded",json_user);
  }
  @override
  @override
  void initState() {
    isSignedIn = false;
    super.initState();
  }
  @override
  void dispose() {
    phoneCont.dispose();
    nameCont.dispose();
    emailCont.dispose();
    birthCont.dispose();
    countryCont.dispose();
    cityCont.dispose();
    super.dispose();
  }
  Future<void> saveQrImage(QrPainter qrcode) async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    qrcode.paint(canvas, Size(200, 200));
    final picture = recorder.endRecording();
    final image = await picture.toImage(200, 200);
    // Convert image to ByteData and then to Uint8List
    final ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
    if (byteData != null) {
      final Uint8List pngBytes = byteData.buffer.asUint8List();
      // Get the application's document directory
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/qr_code.png';
      // Write the image data to the file
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);
      print("QR Code saved at: $filePath");
    } else {
      print("Failed to convert image to ByteData.");
    }
  }
  Future ShowDialog(BuildContext context) async{
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
            backgroundColor: Colors.white.withOpacity(0.8),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
            content:  const Text("User created",
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87 ))
        )
      //useSafeArea: true
    );
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
    body: Container(
    alignment: Alignment.center,
    child: ListView(
    children: [
    SizedBox(
    height: 50,
    child: Text("Welcome",
    style: Theme.of(context).textTheme.headlineLarge)),
    SizedBox(
        height: 50,
        child: Text("Create account",
            style: Theme.of(context).textTheme.headlineMedium)),
      Form(
          key: formKey,
          child:SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                      height: 70,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("+964"),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: phoneCont,
                              decoration: InputDecoration(
                                labelText: "Phone number",
                                border: OutlineInputBorder(borderRadius:BorderRadius.circular(30)),
                                enabledBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(width: 3, color: Colors.blueAccent),
                                    borderRadius: BorderRadius.circular(30)
                                ),
                              ),
                              autovalidateMode: AutovalidateMode.onUserInteraction, // Enable autovalidation
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly, // Allow only digits
                                LengthLimitingTextInputFormatter(10), // Limit to 10 digits
                              ],
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Phone number cannot be empty";
                                } else if (value.length != 10) {
                                  return "Phone number must be exactly 10 digits";
                                }
                              },
                            ),
                          ),
                        ],
                      ),
              ),
                  SizedBox(
                      height: 70,
                      child: TextFormField(
                          keyboardType: TextInputType.name,
                          controller: nameCont,
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'\n|\t'))
                          ],
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius:BorderRadius.circular(30)),
                              enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(width: 3, color: Colors.blueAccent),
                                  borderRadius: BorderRadius.circular(30)
                              ),
                              labelText: "Name",
                              hintText: "First name Last name"
                          ),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (value){
                            if(value == null || value.isEmpty){
                              return "";
                            }
                          }
                      ) ),
                  SizedBox(
                      height: 70,
                      child: TextFormField(
                          keyboardType: TextInputType.emailAddress,
                          controller: emailCont,
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'\n|\t'))
                          ],
                          decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius:BorderRadius.circular(30)),
                              enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(width: 3, color: Colors.blueAccent),
                                  borderRadius: BorderRadius.circular(30)
                              ),
                              labelText: "Email",
                              hintText: "@smth.com"
                          ),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (value){
                            if(value == null || value.isEmpty){
                              return "";
                            }
                          }
                      )),
                  SizedBox(
                      height:70,
                      child: DropdownButtonFormField(
                        value: genderCont,
                        decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius:BorderRadius.circular(30)),
                            enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(width: 3, color: Colors.blueAccent),
                                borderRadius: BorderRadius.circular(30)
                            ),
                            labelText: "Gender",
                            hintText: ""
                        ),
                        onChanged: (value){
                          setState(() {
                            genderCont = value;
                          });
                        },
                        items: ['Male','Female','Other']
                            .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c,
                            style: const TextStyle(
                              color: Color.fromRGBO(23, 195, 255,0.5)
                            ),))).toList(),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (value){
                            if(value == null || value.isEmpty){
                              return "";
                            }
                          }
                      )),
                  SizedBox(
                      height: 70,
                      child:TextFormField(
                          controller: birthCont,
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'\n|\t'))
                          ],
                          decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius:BorderRadius.circular(30)),
                              enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(width: 3, color: Colors.blueAccent),
                                  borderRadius: BorderRadius.circular(30)
                              ),
                              labelText: "Birth Date",
                              hintText: "mm/dd/yyyy"
                          ),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (value){
                            if(value == null || value.isEmpty){
                              return "";
                            }
                          }

                      )),
                  SizedBox(
                      height: 70,
                      child: TextFormField(
                          controller: countryCont,
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'\n|\t'))
                          ],
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius:BorderRadius.circular(30)),
                              enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(width: 3, color: Colors.blueAccent),
                                  borderRadius: BorderRadius.circular(30)
                              ),
                              labelText: "Country",
                              hintText: ""
                          ),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (value){
                            if(value == null || value.isEmpty){
                              return "";
                            }
                          }
                      )),
                  SizedBox(
                      height: 70,
                      child: TextFormField(
                          controller: cityCont,
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'\n|\t'))
                          ],
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius:BorderRadius.circular(30)),
                              enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(width: 3, color: Colors.blueAccent),
                                  borderRadius: BorderRadius.circular(30)
                              ),
                              labelText: "City",
                              hintText: ""
                          ),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (value){
                            if(value == null || value.isEmpty){
                              return "";
                            }
                          }
                      )),
                  SizedBox(
                      height: 45,
                      child: ElevatedButton(
                        onPressed: () async {
                          if(formKey.currentState!.validate()){
                            List<String> userForm = [phoneCont.text,
                              nameCont.text, emailCont.text,genderCont!,
                              birthCont.text, countryCont.text,cityCont.text];
                            json_user = jsonEncode(userForm);
                            addUser(json_user);
                            ShowDialog(context);
                            QrPainter QrImage = QrPainter(
                              data: "${nameCont.text}|${phoneCont.text}|${emailCont.text}",
                              version: QrVersions.auto,
                              errorCorrectionLevel: QrErrorCorrectLevel.Q,
                            );
                            saveQrImage(QrImage);
                            Future.delayed(const Duration(seconds: 2),(){
                              Navigator.pushAndRemoveUntil
                                (context, MaterialPageRoute(
                                  builder: (context) => ChooseDevice()),(route) => false);
                            } );
                          } else{
                            // form is not submitted till all cells are filled
                          }
                        },
                        child: const Text("Sign up",
                          style: TextStyle(
                              fontSize: 18,
                            color: Color.fromRGBO(23, 129, 215, 0.5)
                          ),),
                      ))
                ],
              )
          )
      )
    ]
    ),
    )
    )
    );
  }
}