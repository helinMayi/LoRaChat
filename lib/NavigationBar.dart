import 'package:flutter/material.dart';
import 'package:lora_chat/ProfilePage.dart';
import 'package:lora_chat/ContactPage.dart';
import 'package:lora_chat/ChatPage.dart';

class Navigation extends StatefulWidget {
  const Navigation({super.key});
  @override
  State<Navigation> createState() => NavigationState();
}

class NavigationState extends State<Navigation> {
  int currentIndex = 2;
  late final List<Widget> frames;
  void initState(){
    frames = [
    ChatFrame(),
    ContactFrame(),
    ProfileFrame(),
    ];
  }
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: frames[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.chat),
                label: "Chat"),
            BottomNavigationBarItem(
                icon: Icon(Icons.account_circle),
                label: "Contacts"),
            BottomNavigationBarItem(
                icon: Icon(Icons.contacts),
                label: "Profile"),
          ],
      ),
    );
  }
}