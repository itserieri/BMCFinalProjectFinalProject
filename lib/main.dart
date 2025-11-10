import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// 1. Import the native splash package
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'screens/auth_wrapper.dart'; // 1. Import AuthWrapper
import 'package:ecommerce_app/providers/cart_provider.dart'; // 1. ADD THIS
import 'package:provider/provider.dart'; // 2. ADD THIS
import 'package:google_fonts/google_fonts.dart'; // 1. ADD THIS IMPORT

// 2. --- ADD OUR NEW APP COLOR PALETTE ---
const Color kRichBlack = Color(0xFF0F0F14); // Tokyonight Day Ink Black
const Color kBrown = Color(0xFF2D79C7); // Tokyonight Day Country Blue
const Color kLightBrown = Color(0xFF73DACA); // Tokyonight Day Light Green
const Color kOffWhite = Color(0xFFD5D6DB); // Tokyonight Day Almost White
// --- END OF COLOR PALETTE ---

void main() async {
  // 1. Preserve the splash screen
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // 2. Initialize Firebase (from Module 1)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 1. This is the line we're changing

  runApp(
    // 2. We wrap our app in the provider
    ChangeNotifierProvider(
      // 3. This "creates" one instance of our cart
      create: (context) => CartProvider(),
      // 4. The child is our normal app
      child: const MyApp(),
    ),
  );

  // 4. Remove the splash screen after app is ready
  FlutterNativeSplash.remove();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'eCommerce App',

      // 1. --- THIS IS THE NEW, COMPLETE THEME ---
      theme: ThemeData(
        // 2. Set the main color scheme
        colorScheme: ColorScheme.fromSeed(
          seedColor: kBrown,
          // Our new primary color
          brightness: Brightness.light,
          primary: kBrown,
          onPrimary: Colors.white,
          secondary: kLightBrown,
          background: kOffWhite, // Our new app background
        ),
        useMaterial3: true,

        // 3. Set the background color for all screens
        scaffoldBackgroundColor: kOffWhite,

        // 4. --- (FIX) APPLY THE GOOGLE FONT ---
        // This applies "Lato" to all text in the app
        textTheme: GoogleFonts.latoTextTheme(Theme.of(context).textTheme),

        // 5. --- (FIX) GLOBAL BUTTON STYLE ---
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kBrown, // Use our new brown
            foregroundColor: Colors.white, // Text color
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Rounded corners
            ),
          ),
        ),

        // 6. --- (FIX) GLOBAL TEXT FIELD STYLE ---
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          labelStyle: TextStyle(color: kBrown.withOpacity(0.8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kBrown, width: 2.0),
          ),
        ),

        // 7. --- (FIX) GLOBAL CARD STYLE ---
        cardTheme: CardThemeData(
          elevation: 1, // A softer shadow
          color: Colors.white, // Pure white cards on the off-white bg
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          // 8. This ensures the images inside the card are rounded
          clipBehavior: Clip.antiAlias,
        ),

        // 9. --- (NEW) GLOBAL APPBAR STYLE ---
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white, // Clean white AppBar
          foregroundColor: kRichBlack, // Black icons and text
          elevation: 0, // No shadow, modern look
          centerTitle: true,
        ),
      ),

      // --- END OF NEW THEME ---
      home: const AuthWrapper(),
    );
  }
}
