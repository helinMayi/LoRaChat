class Message{
  String? senderID;
  String? content;
  DateTime? sentAt;

  Message({
    required this.senderID,
    required this.content,
    required this.sentAt,
  });

  Message.fromJson(Map<String, dynamic> json) {
    senderID = json['senderID'];
    content = json['content'];
    sentAt = DateTime.parse(json['sentAt']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['senderID'] = senderID;
    data['content'] = content;
    data['sentAt'] = sentAt!.toIso8601String();
    return data;
  }
}