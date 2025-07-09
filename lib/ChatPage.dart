import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lora_chat/Chats.dart';
import 'package:lora_chat/Contacts.dart';
import 'dart:convert';
import 'package:lora_chat/Qr_Scanner.dart';
import 'package:lora_chat/bluetoothConnect.dart';
import 'package:lora_chat/shared_pref.dart';
import 'package:lora_chat/ChatScreen.dart';

class ChatFrame extends StatefulWidget {
  const ChatFrame({super.key});

  @override
  State<ChatFrame> createState() => _ChatFrameState();
}

class _ChatFrameState extends State<ChatFrame> {
  StreamSubscription<List<int>>? _streamSubscription;
  late Chat chat;
  String myID = jsonDecode(sharedPref.getString("userAdded").toString())[0];
  RetrieveChatList()async {
    List<dynamic> decodedChats = jsonDecode(sharedPref.getString("chats").toString());
    setState(() {
      QrScanner.chats = decodedChats.map<Chat>((item) => Chat.fromJson(item)).toList();
      print("retrieve chat list");
      print(QrScanner.chats.length);
    });
  }
  //Request for key
  Future<void> WriteRequest(String otherUserID, int code) async {
    print("other user");
    print(otherUserID);
    print("my id");
    print(myID);
    List<int> dataPacket = [];
    //first element == sender ID (750 895 6832) => 10 bytes
    for (int i = 0; i < myID.length; ++i) {
      dataPacket.insert(i, utf8.encode(myID)[i]);
    }
    // second element == receiver ID (*** *** ****) => 10 bytes
    for (int i = 0; i < otherUserID.length; ++i) {
      dataPacket.insert(i + myID.length, utf8.encode(otherUserID)[i]);
    }
    // third element == code => 1 byte
    dataPacket.insert(myID.length + otherUserID.length, code);
    if (code == "k".codeUnitAt(0)) {
      print("request key");
      DateTime time = DateTime.now();
      print("unix time");
      String timestamp = time.microsecondsSinceEpoch.toString();
      print(timestamp);
      for (int i = 0; i < timestamp.length; ++i) {
        dataPacket.insert(myID.length + otherUserID.length + 1 + i,
            utf8.encode(timestamp)[i]);
      }
    } else if(code == "a".codeUnitAt(0)){
        print("approve key");
        DateTime time = DateTime.now();
        print("unix time");
        String timestamp = time.microsecondsSinceEpoch.toString();
        print(timestamp);
        for (int i = 0; i < timestamp.length; ++i) {
          dataPacket.insert(myID.length + otherUserID.length + 1 + i,
              utf8.encode(timestamp)[i]);
        }
    } // else if x is the code a denial will be sent
    print("data packet");
    print(dataPacket.length);
    for (int i = 0; i < dataPacket.length; ++i) {
      print(dataPacket[i]);
    }
    await ChooseDevice.targetCharacteristic_receive!.write(dataPacket);
  }
  //Approve or disaprove the request
  Future<void> ReadRequest() async {
    print("chat page read");
    await ChooseDevice.targetDevice!.requestMtu(256).catchError((error){
      print("MTU request failed: $error");
    });
    ChooseDevice.targetCharacteristic_send?.setNotifyValue(true);
    await Future.delayed(const Duration(seconds: 1));
    _streamSubscription?.onError((error) {
      print("Error in Bluetooth stream: $error");
    });
    _streamSubscription = ChooseDevice.targetCharacteristic_send!.value.listen((
        Receivedvalue) async {
      print("received data");
      print(Receivedvalue);
      if (Receivedvalue.length > 3) {
        String senderID = utf8.decode(Receivedvalue.sublist(0, 10));
        String receiverID = utf8.decode(Receivedvalue.sublist(10, 20));
        String code = utf8.decode(Receivedvalue.sublist(20, 21));
        //List<Contact> contacts =
        List<Contact> otherUserIDs = jsonDecode(sharedPref.getString("contacts").toString())
            .map<Contact>((item) =>  Contact.fromMap(item)).toList();
        String otherUserID = otherUserIDs.firstWhere(
                (contact) => contact.phone == senderID,
            orElse: () => Contact(name: "", phone: "", email: "")).phone;
        print(otherUserID);
            // QrScanner.contacts.firstWhere(
            //   (contact) => contact.phone == senderID, orElse: () => Contact(name: "", phone: "", email: "")).phone;
        if (receiverID == myID && senderID == otherUserID) {
          print("Addresses approved");
          if (code == "k") {
            print("request key");
            ShowDialog(context, senderID,receiverID);
          } else if (code == "a") {
            chat = QrScanner.chats.firstWhere(
                    (c) => c.participants![0].phone == senderID);
            print("go to chat");
            await _streamSubscription?.cancel();
              await Navigator.push(context,
                  MaterialPageRoute(
                      builder: (context) => ChatBox(userChat: chat)));
          } else if (code == "x"){
            ShowAlert(context);
          }
        } else {
          print("Addresses invalid");
          WriteRequest(otherUserID, "x".codeUnitAt(0));
        }
      }
    });
  }
  //char denial
  ShowAlert(BuildContext context) {
    return AlertDialog(
      //backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      backgroundColor: Colors.grey[200],
      contentPadding: const EdgeInsets.all(20),
      title: const Text("Warning"),
      content: const Text("Access Denied",
          style: TextStyle(
              color: Colors.black)
      ),
    );
  }
  //  chat request
  Future ShowDialog(BuildContext context, String senderID, String receiverID) async{
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        //backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.all(20),
        title: const Text("Chat request"),
        content:  Text("$senderID wants to chat with you",
            style: const TextStyle(
                color: Colors.black
            )),
        actions: [
          ElevatedButton(onPressed: () async {
            print("accept");
            WriteRequest(senderID,"a".codeUnitAt(0));
            Navigator.pop(context);
            chat = QrScanner.chats.firstWhere(
                    (c) => c.participants![0].phone == senderID);
            print("go to chat");
            await _streamSubscription?.cancel();
            await Navigator.push(context,
                MaterialPageRoute(
                    builder: (context) => ChatBox(userChat: chat)));
          },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black
            ),
            child: const Text("Accept"),
          ),
          ElevatedButton(onPressed: (){
            print("deny");
            WriteRequest(senderID,"x".codeUnitAt(0));
            Navigator.pop(context);
          },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black
            ),
            child: const Text("Deny"),
          )
        ],
      ),
    );
  }
  Future<void> initialize() async {
    await ReadRequest();
    await RetrieveChatList();
  }
  @override
  void initState() {
    super.initState();
    initialize();
  }
  @override
  void dispose() {
    // Dispose of stream subscription here
    _streamSubscription?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title:  Text("Chats",
          style: Theme.of(context).textTheme.headlineMedium,),
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
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: ListView.separated(
              itemCount: QrScanner.chats.length,
              itemBuilder: (BuildContext context, int index) {
                final chat = QrScanner.chats[index];
                return ListTile(
                  onTap: (){
                    //request key
                    WriteRequest(chat.participants![0].phone,"k".codeUnitAt(0));
                  },
                    title: Text(chat.participants![0].name, style: Theme.of(context).textTheme.bodyMedium),
                    subtitle: Text("say Hi! to ${chat.participants![0].name}",
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                        fontSize: 11,
                        letterSpacing: -0.2,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9899A5),
                        )),
                    leading: const CircleAvatar(
                      backgroundColor: Colors.grey,
                      backgroundImage: AssetImage('assets/profile.png'),
                    ),
                );
              },
              separatorBuilder: (BuildContext context, int index) => const Divider(
                color: Colors.white,
              )),
        )
    );
  }
}
