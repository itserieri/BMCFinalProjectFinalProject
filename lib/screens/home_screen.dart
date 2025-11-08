// Part 1: Imports
import 'package:ecommerce_app/widgets/product_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/screens/admin_panel_screen.dart';
import 'package:ecommerce_app/screens/product_detail_screen.dart';

import 'package:ecommerce_app/providers/cart_provider.dart';
import 'package:ecommerce_app/screens/cart_screen.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_app/screens/order_history_screen.dart'; // Import is correct now

// Change StatelessWidget to StatefulWidget
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  // Create the State class
  State<HomeScreen> createState() => _HomeScreenState();
}
// Rename the main class to _HomeScreenState and extend State
class _HomeScreenState extends State<HomeScreen> {

  // A state variable to hold the user's role. Default to 'user'.
  String _userRole = 'user';
  // Get the current user from Firebase Auth
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  // This function runs ONCE when the screen is first created

  @override
  void initState() {
    super.initState();
    // Call our function to get the role as soon as the screen loads
    _fetchUserRole();
  }

  // This is our new function to get data from Firestore
  Future<void> _fetchUserRole() async {
    // If no one is logged in, do nothing
    if (_currentUser == null) return;
    try {
      // Go to the 'users' collection, find the document
      // matching the current user's ID
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid)
          .get();

      // If the document exists...
      if (doc.exists && doc.data() != null) {
        // ...call setState() to save the role to our variable
        setState(() {
          _userRole = doc.data()!['role'];
        });
      }
    } catch (e) {
      print("Error fetching user role: $e");
      // If there's an error, they'll just keep the 'user' role
    }
  }
  // Move the _signOut function inside this class
  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }
  // The build method is next...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Use the _currentUser variable we defined
        title: Text(_currentUser != null ? 'Welcome, ${_currentUser.email}' : 'Home'),
        actions: [

          // Admin Panel Button
          if (_userRole == 'admin')
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Admin Panel',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminPanelScreen(),
                  ),
                );
              },
            ),

          // Cart Icon (Consumer wraps the widget that needs to rebuild)
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              return Badge(
                label: Text(cart.itemCount.toString()),
                isLabelVisible: cart.itemCount > 0,
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () {
                    // Navigate to the CartScreen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CartScreen(),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          // Order History Button
          IconButton(
            icon: const Icon(Icons.receipt_long), // A "receipt" icon
            tooltip: 'My Orders',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const OrderHistoryScreen(),
                ),
              );
            },
          ),

          // The logout button (always visible)
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _signOut, // Call our _signOut function
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(

        // This is our query to Firestore
        stream: FirebaseFirestore.instance
            .collection('products')
            .orderBy('createdAt', descending: true) // Show newest first
            .snapshots(),

        // The builder runs every time new data arrives from the stream
        builder: (context, snapshot) {

          // STATE 1: While data is loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // STATE 2: If an error occurs
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // STATE 3: If there's no data (or no products)
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No products found. Add some in the Admin Panel!'),
            );
          }

          // STATE 4: We have data!
          // Get the list of product documents from the snapshot
          final products = snapshot.data!.docs;

          // Use GridView.builder for a 2-column grid
          return GridView.builder(
            padding: const EdgeInsets.all(10.0),
            // This configures the grid
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 columns
              crossAxisSpacing: 10, // Horizontal space between cards
              mainAxisSpacing: 10, // Vertical space between cards
              childAspectRatio: 3 / 4, // Makes cards taller than wide
            ),

            itemCount: products.length,
            itemBuilder: (context, index) {
              // Get the data for one product
              final productDoc = products[index];

              // ** --- START OF CRITICAL FIX --- **
              // 1. Get the raw data first, which can be null
              final productDataMap = productDoc.data();

              // 2. CHECK FOR NULL: If the document's data is null, skip this item.
              if (productDataMap == null) {
                return const SizedBox.shrink();
              }

              // 3. Cast the non-null data to the expected Map type
              final productData = productDataMap as Map<String, dynamic>;
              // ** --- END OF CRITICAL FIX --- **

              // Return the ProductCard
              return ProductCard(
                // Ensure the fields are safely cast and exist in the map
                productName: productData['name'] as String,

                // FIX FOR PRICE: Safely cast price from 'num' (Firestore number) to double.
                price: (productData['price'] as num).toDouble(),

                // CRITICAL FIX: Changed 'imageUrl' to the correct 'imageUrl'
                // Used the null-coalescing operator (??) for the fallback image
                imageUrl: productData['imageUrl'] as String? ?? 'https://placehold.co/600x400',

                // Add the onTap property to navigate to the detail screen
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreen(
                        productData: productData,
                        productId: productDoc.id, // Pass the unique ID!
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}