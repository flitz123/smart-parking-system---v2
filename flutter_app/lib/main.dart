import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/grid_screen.dart';

Future<void> _initializeFirebaseIfAvailable() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    print('Firebase: initialized via native config');
    return;
  } catch (e) {
    print('Firebase native init failed: $e');
  }

  final apiKey =
      const String.fromEnvironment('FIREBASE_API_KEY', defaultValue: '');
  final appId =
      const String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '');
  final messagingSenderId = const String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
      defaultValue: '');
  final projectId =
      const String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: '');
  final authDomain =
      const String.fromEnvironment('FIREBASE_AUTH_DOMAIN', defaultValue: '');
  final databaseUrl =
      const String.fromEnvironment('FIREBASE_DATABASE_URL', defaultValue: '');
  final storageBucket =
      const String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: '');

  if (apiKey.isNotEmpty &&
      appId.isNotEmpty &&
      messagingSenderId.isNotEmpty &&
      projectId.isNotEmpty) {
    try {
      final options = FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        authDomain: authDomain.isNotEmpty ? authDomain : null,
        databaseURL: databaseUrl.isNotEmpty ? databaseUrl : null,
        storageBucket: storageBucket.isNotEmpty ? storageBucket : null,
      );
      await Firebase.initializeApp(options: options);
      print('Firebase: initialized programmatically from dart-define');
      return;
    } catch (e) {
      print('Firebase programmatic init failed: $e');
    }
  }

  print(
      'Firebase not initialized; continuing without Firebase (backend API fallback active)');
}

void main() async {
  await _initializeFirebaseIfAvailable();

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.white,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          color: Colors.red.shade50,
          child: SingleChildScrollView(
            child: Text(
              'Uncaught error:\n' + details.exceptionAsString(),
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
        ),
      ),
    );
  };

  runZonedGuarded(() {
    runApp(SmartParkingApp());
  }, (error, stack) {
    print('Uncaught zone error: $error');
    print(stack);
  });
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
