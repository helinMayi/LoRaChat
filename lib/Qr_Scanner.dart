import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lora_chat/Chats.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_scanner_overlay/qr_scanner_overlay.dart';
import 'package:lora_chat/Contacts.dart';
import 'package:lora_chat/shared_pref.dart';

class QrScanner extends StatefulWidget {
  const QrScanner({super.key});
  static bool isScanned = true;
  static List<Contact> contacts = [];
  static List<Chat> chats = [];
  @override
  State<QrScanner> createState() => _QrScannerState();
}

class _QrScannerState extends State<QrScanner> {
  MobileScannerController camController = MobileScannerController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool isFlashOn = false;
  bool pop = false;
  Future<void> updateContactList()async {
    json_contacts = jsonEncode(QrScanner.contacts.map((c) => c.toMap()).toList());
    await sharedPref.setString("contacts", json_contacts);
    print("contacted mapped encoded");
    print(json_contacts);
  }
  Future<void> updateChatList() async {
    json_chats = jsonEncode(QrScanner.chats.map((c) => c.toJson()).toList());
    await sharedPref.setString("chats", json_chats);
    print("mapped encoded");
    print(json_chats);
  }
  String CreateID(Contact newContact){
    List phones = [newContact.phone, jsonDecode(sharedPref.getString("userAdded").toString())[0]];
    phones.sort();
    String chatID = phones.fold("", (init,acc) => "$init$acc");
    print("chatID");
    print(chatID);
    return chatID;
  }
  Future<void> CreateChat(Contact newContact) async {
    print("create chat");
    String chatID = CreateID(newContact);
    Chat newChat = Chat(id: chatID,
        participants: [newContact, Contact(name: jsonDecode(sharedPref.getString("userAdded").toString())[1],
            phone: jsonDecode(sharedPref.getString("userAdded").toString())[0],
            email: jsonDecode(sharedPref.getString("userAdded").toString())[2])
          ],
        messages: []);
    setState(() {
        QrScanner.chats.add(newChat);
    });
  }
  @override
  void initState() {
    super.initState();
    QrScanner.isScanned = true;
  }
  @override
  Future AddContact(String value){
    print("value");
    QrScanner.isScanned = false;
    List<String> values = value.split('|');
    TextEditingController name = TextEditingController();
    name.text = values[0];
    bool isDuplicate = QrScanner.contacts.any((contact) => contact.phone == values[1]);
    return showDialog(context: context,
        builder: (BuildContext context){
      return AlertDialog(
          title: Text("Add contact",
              style: Theme.of(context).textTheme.headlineMedium),
          content: Container(
              width: 500,
              height: 500,
              padding: const EdgeInsets.symmetric(horizontal: 23,vertical: 40),
              child: Form(
          key: formKey,
          child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextFormField(
                      controller: name,
                      keyboardType: TextInputType.name,
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'\n|\t'))
                      ],
                      decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius:BorderRadius.circular(30)),
                          enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(width: 3, color: Colors.blueAccent),
                              borderRadius: BorderRadius.circular(30)
                          ),
                          labelText: "name",
                          hintText: ""
                      ),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value){
                        if(value == null || value.isEmpty){
                          return "";
                        }
                      }
                  ),
                  TextFormField(
                    readOnly: true,
                    initialValue: values[1],
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius:BorderRadius.circular(30)),
                        enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(width: 3, color: Colors.blueAccent),
                            borderRadius: BorderRadius.circular(30)
                        ),
                        labelText: "Phone",
                        hintText: ""
                    ),
                  ),
                  TextFormField(
                    readOnly: true,
                    initialValue: values[2],
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius:BorderRadius.circular(30)),
                        enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(width: 3, color: Colors.blueAccent),
                            borderRadius: BorderRadius.circular(30)
                        ),
                        labelText: "Email",
                        hintText: ""
                    ),
                  ),
                  if (isDuplicate)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        "Contact already exists",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ElevatedButton(
                    onPressed: isDuplicate ? null : () async {
                      if(formKey.currentState!.validate()) {
                        //Add contact to contact list
                        Contact newContact = Contact(name: name.text, phone: values[1], email: values[2]);
                        //Create chat instance
                        setState((){
                          QrScanner.contacts.add(newContact);
                        });
                        await CreateChat(newContact);
                        await updateContactList();
                        await updateChatList();
                        setState(() {
                          pop = true;
                        });
                        Navigator.pop(context,true);
                      }
                    },
                    child: Text("Save",
                        style: Theme.of(context).textTheme.bodySmall))
                ],
              )
              )
          )
      );
        });
  }
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Add contact",
          style: Theme.of(context).textTheme.headlineMedium),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(1.0),
            child: Container(
              color: Colors.black12, // Color of the divider
              height: 1.0, // Thickness of the divider
            ),
          ),
        ),
        body: Container(
          width: double.maxFinite,
          padding: EdgeInsets.symmetric(horizontal: 23,vertical: 40),
          alignment: Alignment.center,
          child: SizedBox(
                  child: Stack(
                      children: [
                        MobileScanner (
                            controller: camController,
                            onDetect: (capture) async {
                              if(QrScanner.isScanned){
                                final List<Barcode> barcodes = capture
                                    .barcodes;
                                for (final barcode in barcodes) {
                                  debugPrint('Barcode found! ${barcode.rawValue}');
                                  //add new contact
                                  await AddContact(barcode.rawValue.toString());
                                  print("pop");
                                  print(pop);
                                  if(pop){
                                    Navigator.pop(context,true);
                                  }
                                }
                              }
                            }
                        ),
                        QRScannerOverlay(
                            overlayColor: Colors.white12.withOpacity(0.5)),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              isFlashOn = !isFlashOn;
                            });
                            camController.toggleTorch();
                          },
                          icon: Icon(Icons.flash_on,
                              color: isFlashOn ? Colors.blueAccent : Colors
                                  .black38,
                              size: 40),
                        ),
                      ]
                  )
              )
          )
    );
  }
}