import 'package:shared_preferences/shared_preferences.dart';

//shared preferences {key,value} ---> key == phone number, value == list of user inputs
final Future<SharedPreferences> sharedP = SharedPreferences.getInstance();
late final SharedPreferences sharedPref;
late String json_user;
late String json_contacts;
late String json_chats;
late bool isSignedIn;