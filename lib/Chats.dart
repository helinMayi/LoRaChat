import 'package:lora_chat/Contacts.dart';
import 'package:lora_chat/Messages.dart';

class Chat {
  String? id;
  List<Contact>? participants;
  List<Message>? messages;

  Chat({
    required this.id,
    required this.participants,
    required this.messages,
  });

  Chat.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    participants = List.from(json['participants']).map((m) => Contact.fromJson(m)).toList();
    messages =
        List.from(json['messages']).map((m) => Message.fromJson(m)).toList();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['participants'] = participants?.map((m) => m.toJson()).toList() ?? [];
    data['messages'] = messages?.map((m) => m.toJson()).toList() ?? [];
    return data;
  }
}