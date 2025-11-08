import 'package:flutter/material.dart';
import 'dart:async'; // For StreamSubscription
import 'package:firebase_auth/firebase_auth.dart'; // For Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore
import 'package:flutter/foundation.dart';

// 1. A simple class to hold the data for an item in the cart
class CartItem {
  final String id; // The unique product ID
  final String name;
  final double price;
  int quantity; // Quantity can change, so it's not final

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1, // Default to 1 when added
  });

  // A method to convert our CartItem object into a Map (for Firestore)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }

  // A factory constructor to create a CartItem from a Map (from Firestore)
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: (json['quantity'] as num).toInt(),
    );
  }
}

// 1. The CartProvider class "mixes in" ChangeNotifier
class CartProvider with ChangeNotifier {

  // 2. This is the private list of items.
  List<CartItem> _items = [];

  // Properties for Firebase
  String? _userId;
  StreamSubscription? _authSubscription;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Constructor for Auth Listener
  CartProvider() {
    // 1. Listen for changes in the user's authentication state
    _authSubscription = _auth.authStateChanges().listen((user) {
      if (user != null) {
        // User is logged in: set ID and fetch their cart
        _userId = user.uid;
        _fetchCart();
      } else {
        // User is logged out: clear the local cart state
        _userId = null;
        _items = [];
        notifyListeners(); // Update UI
      }
    });
  }

  // 3. A public "getter" to let widgets *read* the list of items
  List<CartItem> get items => [..._items];

  // 4. A public "getter" to calculate the total number of items
  int get itemCount {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  // 5. A public "getter" to calculate the total price
  double get totalPrice {
    return _items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  // Fetches the cart data from Firestore for the current user
  Future<void> _fetchCart() async {
    if (_userId == null) return;

    try {
      final cartDoc = await _firestore.collection('carts').doc(_userId).get();

      if (cartDoc.exists && cartDoc.data()!.containsKey('items')) {
        final List<dynamic> fetchedItems = cartDoc.data()!['items'];

        _items = fetchedItems
            .map((itemMap) => CartItem.fromJson(itemMap as Map<String, dynamic>))
            .toList();

        notifyListeners(); // Update the UI with the loaded cart data
      } else {
        _items = [];
        notifyListeners();
      }
    } catch (error) {
      print('Error fetching cart: $error');
    }
  }

  // Saves the current local cart data to Firestore
  Future<void> _saveCart() async {
    if (_userId == null) return;

    try {
      final List<Map<String, dynamic>> itemsAsJson = _items.map((item) => item.toJson()).toList();

      await _firestore.collection('carts').doc(_userId).set({
        'items': itemsAsJson,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      print('Error saving cart: $error');
    }
  }

  // The main logic: "Add Item to Cart" (Updated for persistence)
  void addItem(String id, String name, double price) {
    final existingItemIndex = _items.indexWhere((item) => item.id == id);

    if (existingItemIndex >= 0) {
      _items[existingItemIndex].quantity += 1;
    } else {
      _items.add(CartItem(id: id, name: name, price: price));
    }

    _saveCart(); // Save the updated cart to Firestore
    notifyListeners();
  }

  // The "Remove Item from Cart" logic (Updated for persistence and decrementing)
  void removeItem(String productId) {
    final existingItemIndex = _items.indexWhere((item) => item.id == productId);

    if (existingItemIndex >= 0) {
      if (_items[existingItemIndex].quantity > 1) {
        _items[existingItemIndex].quantity -= 1;
      } else {
        _items.removeAt(existingItemIndex);
      }
    }

    _saveCart(); // Save the updated cart to Firestore
    notifyListeners();
  }

  // Clears the local cart list
  void clearCart() {
    _items = [];
    notifyListeners();
  }

  // Creates a new Order document in Firestore and clears the cart.
  Future<void> placeOrder() async {
    if (_userId == null || _items.isEmpty) {
      throw Exception("Cannot place order: User not logged in or cart is empty.");
    }

    try {
      final List<Map<String, dynamic>> itemsAsJson = _items.map((item) => item.toJson()).toList();

      // Create the new Order document in the 'orders' collection
      await _firestore.collection('orders').add({
        'userId': _userId,
        'totalPrice': totalPrice,
        'items': itemsAsJson,
        'status': 'Pending',
        'orderDate': FieldValue.serverTimestamp(),
      });

      // Clear the cart data locally and save the empty cart to Firestore
      clearCart();
      await _saveCart();

    } catch (error) {
      print('Error placing order: $error');
      throw Exception("Failed to place order. Please check your connection or try again.");
    }
  }

  // Cleans up the StreamSubscription when the provider is disposed
  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}