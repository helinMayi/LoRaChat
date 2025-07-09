import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lora_chat/shared_pref.dart';
import 'package:path_provider/path_provider.dart';

class ProfileFrame extends StatefulWidget {
  const ProfileFrame({super.key});
  @override
  State<ProfileFrame> createState() => _ProfileFrameState();
}
class _ProfileFrameState extends State<ProfileFrame> {
  List<dynamic> user = jsonDecode(sharedPref.getString("userAdded").toString());
  late File QrCodeImage;
  //Retrieve the user's qr code from the file
  Future<void> RetrieveQrCode () async {
    final directory = await getApplicationDocumentsDirectory();
    print(directory);
    final filePath = '${directory.path}/qr_code.png';
    setState(() {
      QrCodeImage = File(filePath);
    });
  }
  @override
  void initState() {
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text("Profile",
            style: Theme.of(context).textTheme.headlineMedium),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(1.0),
            child: Container(
              color: Colors.black12, // Color of the divider
              // height: 1.0, // Thickness of the divider
    ),
    ),
    ),
    body: Container(
    width: double.maxFinite,
    padding: EdgeInsets.symmetric(horizontal: 23,vertical: 40),
    child: Column(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(
            height: 50,
            width: 50,
            child: CircleAvatar(
              backgroundColor: Colors.grey,
              backgroundImage: AssetImage('assets/profile.png'),
            ),
          ),
          Text("Hello ${user[1].split(' ')[0]}",
              style: Theme.of(context).textTheme.headlineMedium),
          GestureDetector(
            child: const Icon(Icons.qr_code_2, size: 50,
            color: Color.fromRGBO(23, 195, 255,0.5)),
            onTap: () async {
              try {
                await RetrieveQrCode();
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("My QR Code"),
                      content: Container(
                        height: 250,
                        width: 250,
                        child: Image.file(QrCodeImage),
                      ),
                    );
                  },
                );
              } catch (error) {
                // Handle errors during QR code retrieval (optional)
                print('Error retrieving QR code: $error');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: Could not find QR code',
                    style: Theme.of(context).textTheme.headlineMedium),
                  ),
                );
              }
            },
          ),
        ],
      ),
      SizedBox(height: 70),
      Padding(
          padding: EdgeInsets.only(left: 5),
          child: Text("Phone number:  ${user[0]}",
              style: Theme.of(context).textTheme.headlineMedium)),
      SizedBox(height: 20),
      Padding(
          padding: EdgeInsets.only(left: 5),
          child: Text("Full name:  ${user[1]}",
              style: Theme.of(context).textTheme.headlineMedium)),
    SizedBox(height: 20),
      Padding(
          padding: EdgeInsets.only(left: 5),
          child: Text("Email:  ${user[2]}",
              style: Theme.of(context).textTheme.headlineMedium)),
      SizedBox(height: 20),
      Padding(
          padding: EdgeInsets.only(left: 5),
          child: Text("Gender:  ${user[3]}",
              style: Theme.of(context).textTheme.headlineMedium)),
      SizedBox(height: 20),
      Padding(
          padding: EdgeInsets.only(left: 5),
          child: Text("Birth date:  ${user[4]}",
              style: Theme.of(context).textTheme.headlineMedium)),
      SizedBox(height: 20),
      Padding(
          padding: EdgeInsets.only(left: 5),
          child: Text("Country: ${user[5]}",
              style: Theme.of(context).textTheme.headlineMedium)),
      SizedBox(height: 20),
      Padding(
          padding: EdgeInsets.only(left: 5),
          child: Text("City:  ${user[6]}",
              style: Theme.of(context).textTheme.headlineMedium)),
    ]
    ),
    ),
    );
  }
}