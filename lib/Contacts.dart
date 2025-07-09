import 'dart:convert';

class Contact{
  late String name, phone, email;
  Contact({
    required this.name,
    required this.phone,
    required this.email
  });
  // convert a contact to a map (before encoding to JSON)
Map<String, dynamic> toMap(){
  return {
    'name' : name,
    'phone' : phone,
    'email' : email
  };
}
//Convert contact to JSON
String toJson() => json.encode(toMap());

//convert a map into a contact (after decoding from json)
factory Contact.fromMap(Map<String,dynamic> map) {
  return Contact(
    name: map['name'],
    phone: map['phone'],
    email: map['email'],
  );
}
  // Convert JSON to a contact
  factory Contact.fromJson(String source) => Contact.fromMap(json.decode(source));
}