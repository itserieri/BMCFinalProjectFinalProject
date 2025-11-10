import 'package:ecommerce_app/screens/auth_wrapper.dart'; // 1. Import AuthWrapper
// 1. Import the native splash package
import 'package:flutter_native_splash/flutter_native_splash.dart';
// This imports all the standard Material Design widgets
import 'package:flutter/material.dart';

// 1. Import the Firebase core package
import 'package:firebase_core/firebase_core.dart';
// 2. Import the auto-generated Firebase options file
import 'firebase_options.dart';
import 'package:ecommerce_app/providers/cart_provider.dart'; // 1. ADD THIS
import 'package:provider/provider.dart'; // 2. ADD THIS
// FIX: ADDED MISSING FIREBASE AUTH IMPORT
import 'package:firebase_auth/firebase_auth.dart';


void main() async {
// 1. Preserve the splash screen
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
// 2. Initialize Firebase (from Module 1)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

// FIX: ADDED FIREBASE PERSISTENCE
  await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);

// FIX: MANUAL CARTPROVIDER CREATION
  final cartProvider = CartProvider();
// FIX: CALL THE NEW INITIALIZER METHOD
  cartProvider.initializeAuthListener();

// 3. `Run` the app (from Module 1)
  // This is the line we're changing
  runApp(
    // 2. We wrap our app in the provider
    ChangeNotifierProvider.value( // FIX: Changed to .value to pass existing instance
      // 3. This "creates" one instance of our cart
      value: cartProvider, // FIX: Use the existing instance
      // 4. The child is our normal app
      child: const MyApp(),
    ),
  );

// 4. Remove the splash screen after app is ready
  FlutterNativeSplash.remove();
}
// ... The MyApp widget remains exactly the same ...

class MyApp extends StatelessWidget {
  const MyApp({super.key});
// ... (const MyApp)
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'eCommerce App',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
// 1. Change this line
      home: const AuthWrapper(),
    );
  }
}