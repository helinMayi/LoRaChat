import 'dart:async';
import 'dart:convert';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:lora_chat/Chats.dart';
import 'package:lora_chat/Messages.dart';
import 'package:lora_chat/Qr_Scanner.dart';
import 'package:lora_chat/bluetoothConnect.dart';
import 'package:lora_chat/shared_pref.dart';

class ChatBox extends StatefulWidget {
  final Chat userChat;
   ChatBox({super.key, required this.userChat});
  @override
  State<ChatBox> createState() => ChatBoxState();
}

class ChatBoxState extends State<ChatBox> {
  ChatUser? me, otherUser;
  StreamController<Chat> chatStreamController = StreamController<Chat>();
  StreamSubscription<List<int>>? _streamSubscription;
  @override
  void dispose() {
    // Dispose of stream subscription here
    _streamSubscription?.cancel();
    chatStreamController.close();
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    // id = phone number
    me = ChatUser(id: widget.userChat.participants![1].phone,
        firstName: widget.userChat.participants![1].name);
    otherUser = ChatUser(id: widget.userChat.participants![0].phone,
        firstName: widget.userChat.participants![0].name);
    print("user chat");
    print(otherUser?.id);
    // start streaming the messages
    initialize();
  }
  Future<void> initialize() async {
    await streamChatmessages();
    await readData();
  }
  // for displaying
  Stream<Chat> retrieveChatmessages(){
    print("retrieveChatmessages");
    return chatStreamController.stream;
  }
  //Listens to new messages from the shared prefs with the chatId we want
  Future<void> streamChatmessages() async {
    print("streamChatmessages");
    getChatmessagesFromSharedPrefs(widget.userChat.id).listen((chat) {
      chatStreamController.add(chat);
    });
  }
  //gets chat meassages from shared prefs with the specified chatID
  Stream<Chat> getChatmessagesFromSharedPrefs(String? chatID) async*{
    print("getChatmessagesFromSharedPrefs");
    final chats = sharedPref.getString("chats");
    List<dynamic> decodedChats = jsonDecode(chats!);
    final Chat? myChat = decodedChats.map<Chat>((item) => Chat.fromJson(item)).toList().
    firstWhere((c) => c.id == widget.userChat.id, orElse: () => Chat(id: "", participants: [], messages: []));
    if (myChat != null) {
      yield myChat;
    } else {
  yield Chat(id: widget.userChat.id, participants: [], messages: []);
  }
  }
  // save messages to shared preferences
  Future<void> saveChatMessage(Message message)async {
    widget.userChat.messages!.add(message);
    json_chats = jsonEncode(QrScanner.chats.map((c) => c.toJson()).toList());
    await sharedPref.setString("chats", json_chats);
    await streamChatmessages();
    print("chats");
    print(sharedPref.getString("chats"));
  }
  Future<void> onWriteData(ChatMessage chatMessage) async {
    writeData(chatMessage,"d".codeUnitAt(0));
  }
  // send data (write data)
  Future<void> writeData(ChatMessage chatMessage,int code) async {
    print("send data");
    List<int> dataPacket = [];
    //first element == sender ID (750 895 6832) => 10 bytes
    for (int i = 0; i < me!.id.length; ++i) {
      dataPacket.insert(i, utf8.encode(me!.id)[i]);
    }
    // second element == receiver ID (*** *** ****) => 10 bytes
    for (int i = 0; i < otherUser!.id.length; ++i) {
      dataPacket.insert(i + me!.id.length, utf8.encode(otherUser!.id)[i]);
    }
    // third element == code => 1 byte
    dataPacket.insert(me!.id.length + otherUser!.id.length, code);
    print("incoming data");
    Message message = Message(senderID: me!.id,
        content: chatMessage.text,
        sentAt: DateTime.now());
    await saveChatMessage(message);
    for (int i = 0; i < chatMessage.text.length; ++i) {
      dataPacket.insert(me!.id.length + otherUser!.id.length + 1 + i,
          utf8.encode(chatMessage.text)[i]);
    }
    print("data packet");
    for (int i = 0; i < dataPacket.length; ++i) {
      print(dataPacket[i]);
    }
    await ChooseDevice.targetCharacteristic_receive!.write(dataPacket);
  }

  //read data
  Future<void> readData() async {
    print("chat screen read");
    String senderID, receiverID, code;
    await ChooseDevice.targetCharacteristic_send!.setNotifyValue(true);
    await Future.delayed(Duration(seconds: 1));
    _streamSubscription = ChooseDevice.targetCharacteristic_send!.value.listen((
        Receivedvalue) async {
      print("received data");
      print(Receivedvalue);
      if (Receivedvalue.length > 3) {
        senderID = utf8.decode(Receivedvalue.sublist(0, 10));
        receiverID = utf8.decode(Receivedvalue.sublist(10, 20));
        code = utf8.decode(Receivedvalue.sublist(20, 21));
        if (receiverID == me!.id && senderID == otherUser!.id) {
          if (code == "d") {
            //print data in the UI
            String receivedMessage = utf8.decode(
                Receivedvalue.sublist(21));
            Message message = Message(senderID: senderID,
                content: receivedMessage,
                sentAt: DateTime.now());
            saveChatMessage(message);
          }
        }
      }
    });
  }
  // convert chat messages to Dash_Chat ChatMessage type
  List<ChatMessage> generateChatMessageList(List<Message> messages){
    List<ChatMessage> chatMessages = messages.map((m) {
      return ChatMessage(user: m.senderID == me!.id ? me! : otherUser!,
          createdAt: m.sentAt!,
      text: m.content!);
    }).toList();
    chatMessages.sort((a,b){return b.createdAt.compareTo(a.createdAt);});
    return chatMessages;
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey,
                      backgroundImage: AssetImage('assets/profile.png'),
                    ),
                  ),
                  Text(
                    otherUser!.firstName!,
                    style: Theme.of(context).textTheme.headlineMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Spacer(), // Creates space to center the content
                ],
              ),
              centerTitle: false,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1.0),
                child: Container(
                  color: Colors.black12, // Color of the divider
                  height: 1.0, // Thickness of the divider
                ),
              ),
            ),
            body: PopScope(
              onPopInvokedWithResult: (bool didPop, Object? result) {
                _streamSubscription?.cancel();
                },
              child:StreamBuilder<Chat>(
                stream: retrieveChatmessages(),
                builder: (context, snapshot){
                  Chat? chat = snapshot.data;
                  List<ChatMessage> messages = [];
                  if (chat != null && chat.messages != null) {
                    messages = generateChatMessageList(chat.messages!);
                  }
                  return DashChat(currentUser: me!,
                      onSend: onWriteData,
                      messages: messages,
                      messageOptions: const MessageOptions(
                        showCurrentUserAvatar: true,
                        showTime: true,
                      ),
                      inputOptions: const InputOptions(
                          alwaysShowSend: true,
                          maxInputLength: 234,
                          inputTextStyle: TextStyle(
                              color: Colors.black
                          )
                      )
                  );
                },
              )
            )
        )
    );
  }
}
