import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:lora_chat/SignUp.dart';
import 'package:lora_chat/bluetoothConnect.dart';
import 'package:lora_chat/shared_pref.dart';
void main(){
  runApp(const MainPage());
}
class MainPage extends StatelessWidget {
  const MainPage({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: const ManageBLE(),
          theme: ThemeData(
            scaffoldBackgroundColor: const Color.fromRGBO(41, 41, 41,0.5),
            useMaterial3: true,
            colorSchemeSeed: const Color.fromRGBO(41,41,41,0.5),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ButtonStyle(
                  padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
                  textStyle: WidgetStateProperty.all(TextStyle(fontSize: 16)),
                  shape: WidgetStateProperty.all(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
              )
            )
          )
        ),
            textTheme: const TextTheme(
              headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color.fromRGBO(23, 195, 255,0.5)),
              headlineMedium: TextStyle(fontSize: 22, color: Color.fromRGBO(23, 195, 255,0.5)),
              bodyMedium: TextStyle(fontSize: 16, color: Color.fromRGBO(23, 195, 255,0.5)),
              bodySmall: TextStyle(fontSize: 12, color: Color.fromRGBO(23, 195, 255,0.5)),
              bodyLarge: TextStyle(fontSize: 20, color: Color.fromRGBO(23, 195, 255,0.5))
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              titleTextStyle: TextStyle(fontSize: 36, color: Color.fromRGBO(158, 195, 253,0.5)),
            )
    )
    )
    );
  }
}
class ManageBLE extends StatefulWidget {
  const ManageBLE({super.key});

  @override
  State<ManageBLE> createState() => _ManageBLEState();
}

class _ManageBLEState extends State<ManageBLE> {
  ShowDialog(BuildContext context) {
    return AlertDialog(
        //backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.grey[200],
        contentPadding: const EdgeInsets.all(20),
        title: const Text("Warning!"),
        content: const Text("Please turn the bluetooth on",
        style: TextStyle(
            color: Colors.black)
    ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BluetoothState>(
      stream: FlutterBlue.instance.state,
      initialData: BluetoothState.unknown,
      builder: (c, snapshot) {
        final state = snapshot.data;
        if (state == BluetoothState.on) {
          return const LandingPage();
        } else {
          return Center(
            child: ShowDialog(context)
          );
        }
      });
  }
}

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("LoRa",
              style: Theme.of(context).textTheme.headlineMedium),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color.fromRGBO(41,41,41, 0.5), // Color of the divider
            height: 1.0, // Thickness of the divider
          ),
        ),
        ),
      body: Container(
        width: double.maxFinite,
        padding: const EdgeInsets.symmetric(horizontal: 23,vertical: 40),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                      fit: BoxFit.fitWidth,
                      image: ExactAssetImage('assets/images/bluetooth1.png')
                  ),
                ),
                height: 400,
                width: 280,
              ),
              SizedBox(
                  height: 70,
                  width: 250,
                  child: ElevatedButton(// this is the button
                    onPressed: () async {
                      //navigate to the sign up or home page if user already signed in
                      sharedPref = await sharedP;
                      isSignedIn = sharedPref.getBool('signed') ?? false;
                      if(isSignedIn){
                        print("signed in");
                        Navigator.push(context, MaterialPageRoute(
                            builder:(context) => const ChooseDevice()));
                      } else {
                        Navigator.push(context, MaterialPageRoute(
                            builder:(context) => const Signup()));
                      }
                    },
                    child: Text("Start",
                      style: Theme.of(context).textTheme.bodyLarge,),
                  )),
            ],
          ),
        )
      ),
    );
  }
}