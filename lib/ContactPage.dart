import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:lora_chat/Qr_Scanner.dart';
import 'package:lora_chat/Contacts.dart';
import 'package:lora_chat/shared_pref.dart';

class ContactFrame extends StatefulWidget {
  const ContactFrame({super.key});
  @override
  State<ContactFrame> createState() => _ContactFrameState();
}

class _ContactFrameState extends State<ContactFrame> {
  RetrieveContactList() async {
    List<dynamic> decodedContacts = jsonDecode(sharedPref.getString("contacts").toString());
     setState((){
       QrScanner.contacts = decodedContacts.map<Contact>((item) => Contact.fromMap(item)).toList();
      print("retrieve contact list");
      print(QrScanner.contacts.length);
    });
  }
  @override
  void initState() {
    super.initState();
    RetrieveContactList();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
        title: Text("Contacts",
            style: Theme.of(context).textTheme.headlineMedium),
    bottom: PreferredSize(
    preferredSize: Size.fromHeight(1.0),
    child: Container(
    color: Colors.black12, // Color of the divider
    height: 1.0, // Thickness of the divider
    ),
    ),
    ),
    floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(
              builder: (context) => QrScanner()));
          RetrieveContactList();
        },
        label: const Text("Add Contact"),
    icon: Icon(IconlyBroken.add_user),),
    body: Container(
    width: double.maxFinite,
    padding: EdgeInsets.symmetric(vertical: 20),
      child: QrScanner.contacts.isEmpty ? Center(child: Text("No contacts available"))
      : ListView.separated(
        itemCount: QrScanner.contacts.length,
          itemBuilder: (BuildContext context, int index) {
          final contact = QrScanner.contacts[index];
          return ListTile(
            horizontalTitleGap: 10,
            title: Text(contact.name, style: Theme.of(context).textTheme.bodyMedium),
            subtitle: Text("${contact.phone}     ${contact.email}",
            style: Theme.of(context).textTheme.bodySmall),
            leading: CircleAvatar(
              backgroundColor: Colors.grey,
              backgroundImage: AssetImage('assets/profile.png'),

            ),
            trailing:  Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(onPressed: (){
                  setState(() {
                    QrScanner.contacts.removeAt(index);
                    QrScanner.chats.removeAt(index);
                  });
                  json_contacts = jsonEncode(QrScanner.contacts.map((c) => c.toMap()).toList());
                  json_chats = jsonEncode(QrScanner.chats.map((c) => c.toJson()).toList());
                  sharedPref.setString("chats", json_chats);
                  sharedPref.setString("contacts", json_contacts);
                  print("contact");
                  print(jsonEncode(QrScanner.contacts.map((c) => c.toMap()).toList()));
                  print("chat");
                  print(jsonEncode(QrScanner.chats.map((c) => c.toJson()).toList()));
                },
                icon: Icon(IconlyBroken.delete),
                ),
                IconButton(onPressed: (){
                  // Navigator.push(context,
                  //     MaterialPageRoute(
                  //         builder: (context) => ChatBox(userChat: contact)));
                },
                icon: Icon(IconlyBroken.chat),
                )
              ],
          )
          );
          },
          separatorBuilder: (BuildContext context, int index) => const Divider(
            color: Colors.white,
          )),
    )
    );
  }
}