import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/grid_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(SmartParkingApp());
}

class SmartParkingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Parking',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: GridScreen(),
    );
  }
}
