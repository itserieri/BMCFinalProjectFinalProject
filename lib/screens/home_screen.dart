// Part 1: Imports
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 1. ADD THIS IMPORT
import 'package:ecommerce_app/screens/admin_panel_screen.dart'; // 2. ADD THIS
import 'package:ecommerce_app/widgets/product_card.dart'; // 1. ADD THIS IMPORT
import 'package:ecommerce_app/screens/product_detail_screen.dart'; // 1. ADD THIS IMPORT
import 'package:ecommerce_app/providers/cart_provider.dart'; // 1. ADD THIS
import 'package:ecommerce_app/screens/cart_screen.dart'; // 2. ADD THIS
import 'package:provider/provider.dart'; // 3. ADD THIS
import 'package:ecommerce_app/screens/order_history_screen.dart'; // 1. ADD
import 'package:ecommerce_app/screens/profile_screen.dart'; // 1. ADD THIS
import 'package:ecommerce_app/widgets/notification_icon.dart'; // 1. ADD THIS
import 'package:ecommerce_app/screens/chat_screen.dart';

// Part 2: Widget Definition
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  // 4. Create the State class
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 1. A state variable to hold the user's role. Default to 'user'.
  String _userRole = 'user';

  // 2. Get the current user from Firebase Auth
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 3. This function runs ONCE when the screen is first created
  @override
  void initState() {
    super.initState();
    // 4. Call our function to get the role as soon as the screen loads
    _fetchUserRole();
  }

  // 5. This is our new function to get data from Firestore
  Future<void> _fetchUserRole() async {
    // 6. If no one is logged in, do nothing
    if (_currentUser == null) return;
    try {
      // 7. Go to the 'users' collection, find the document
      //    matching the current user's ID
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      // 8. If the document exists...
      if (doc.exists && doc.data() != null) {
        // 9. ...call setState() to save the role to our variable
        setState(() {
          _userRole = doc.data()!['role'];
        });
      }
    } catch (e) {
      print("Error fetching user role: $e");
      // If there's an error, they'll just keep the 'user' role
    }
  }

  // 10. Move the _signOut function inside this class
  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 1. --- THIS IS THE CHANGE ---
        //    DELETE your old title:
        /*
        title: Text(_currentUser != null ? 'Welcome!' : 'Home'),
        */

        // 2. ADD this new title:
        title: Image.asset(
          'assets/images/app_logo.png', // 3. The path to your logo
          height: 40, // 4. Set a fixed height
        ),

        // 5. 'centerTitle' is now handled by our global AppBarTheme

        // --- END OF CHANGE ---
        actions: [
          // 1. --- ADD THIS NEW WIDGET ---
          // This is a special, efficient way to use Provider
          Consumer<CartProvider>(
            // 2. The "builder" function rebuilds *only* the icon
            builder: (context, cart, child) {
              // 3. The "Badge" widget adds a small label
              return Badge(
                // 4. Get the count from the provider
                label: Text(cart.itemCount.toString()),
                // 5. Only show the badge if the count is > 0
                isLabelVisible: cart.itemCount > 0,
                // 6. This is the child (our icon button)
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () {
                    // 7. Navigate to the CartScreen
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

          // 2. --- ADD OUR NEW WIDGET ---
          const NotificationIcon(),
          // --- END OF NEW WIDGET ---

          // 2. --- ADD THIS NEW BUTTON ---
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

          // 2. --- THIS IS THE MAGIC ---
          //    This is a "collection-if". The IconButton will only
          //    be built IF _userRole is equal to 'admin'.
          if (_userRole == 'admin')
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Admin Panel',
              onPressed: () {
                // 3. This is why we imported admin_panel_screen.dart
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminPanelScreen(),
                  ),
                );
              },
            ),

          // 4. The logout button (always visible)
          // 6. ADD this new "Profile" IconButton
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      // 1. REPLACE THE OLD "body: Center(...)" WITH THIS:
      body: StreamBuilder<QuerySnapshot>(
        // 2. This is our query to Firestore
        stream: FirebaseFirestore.instance
            .collection('products')
            .orderBy('createdAt', descending: true) // 3. Show newest first
            .snapshots(),

        // 4. The builder runs every time new data arrives from the stream
        builder: (context, snapshot) {
          // 5. STATE 1: While data is loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 6. STATE 2: If an error occurs
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // 7. STATE 3: If there's no data (or no products)
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No products found. Add some in the Admin Panel!'),
            );
          }

          // 8. STATE 4: We have data!
          // Get the list of product documents from the snapshot
          final products = snapshot.data!.docs;

          // 9. Use GridView.builder for a 2-column grid
          return GridView.builder(
            padding: const EdgeInsets.all(10.0),

            // 10. This configures the grid
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 columns
              crossAxisSpacing: 10, // Horizontal space between cards
              mainAxisSpacing: 10, // Vertical space between cards
              childAspectRatio: 3 / 4, // Makes cards taller than wide
            ),

            itemCount: products.length,
            itemBuilder: (context, index) {
              // 11. Get the data for one product
              final productDoc = products[index];
              final productData = productDoc.data() as Map<String, dynamic>;

              // 12. Return our custom ProductCard widget!
              return ProductCard(
                productName: productData['name'],
                price: productData['price'],
                imageUrl: productData['imageUrl'],
                // 4. --- THIS IS THE NEW PART ---
                //    Add the onTap property
                onTap: () {
                  // 5. Navigate to the new screen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreen(
                        // 6. Pass the data to the new screen
                        productData: productData,
                        productId: productDoc.id, // 7. Pass the unique ID!
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      // 1. --- REPLACE YOUR 'floatingActionButton:' ---
      floatingActionButton: _userRole == 'user'
          ? StreamBuilder<DocumentSnapshot>(
              // 2. A new StreamBuilder
              // 3. Listen to *this user's* chat document
              stream: _firestore
                  .collection('chats')
                  .doc(_currentUser!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                int unreadCount = 0;
                // 4. Check if the doc exists and has our count field
                if (snapshot.hasData && snapshot.data!.exists) {
                  // Ensure data is not null before casting
                  final data = snapshot.data!.data();
                  if (data != null) {
                    unreadCount =
                        (data as Map<String, dynamic>)['unreadByUserCount'] ??
                        0;
                  }
                }

                // 5. --- THE FIX for "trailing not defined" ---
                //    We wrap the FAB in the Badge widget
                return Badge(
                  // 6. Show the count in the badge
                  label: Text('$unreadCount'),
                  // 7. Only show the badge if the count is > 0
                  isLabelVisible: unreadCount > 0,
                  // 8. The FAB is now the *child* of the Badge
                  child: FloatingActionButton.extended(
                    icon: const Icon(Icons.support_agent),
                    label: const Text('Contact Admin'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              ChatScreen(chatRoomId: _currentUser!.uid),
                        ),
                      );
                    },
                  ),
                );
                // --- END OF FIX ---
              },
            )
          : null, // 9. If admin, don't show the FAB
    );
  }
}
