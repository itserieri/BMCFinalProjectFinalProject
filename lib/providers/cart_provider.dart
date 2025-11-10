import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: (json['quantity'] as num).toInt(),
    );
  }
}

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  String? _userId;
  StreamSubscription? _authSubscription;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CartProvider() {
    // Moved to initializeAuthListener to avoid issues in widget tree
  }

  void initializeAuthListener() {
    _authSubscription = _auth.authStateChanges().listen((user) {
      if (user != null) {
        _userId = user.uid;
        _fetchCart();
      } else {
        _userId = null;
        _items = [];
        notifyListeners();
      }
    });
  }

  List<CartItem> get items => [..._items];

  int get itemCount {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  double get subtotal {
    return _items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  double get vat {
    return subtotal * 0.12;
  }

  double get totalPriceWithVat {
    return subtotal + vat;
  }

  Future<void> _fetchCart() async {
    if (_userId == null) return;
    try {
      final cartDoc = await _firestore.collection('carts').doc(_userId).get();
      if (cartDoc.exists && cartDoc.data()!.containsKey('items')) {
        final List<dynamic> fetchedItems = cartDoc.data()!['items'];
        _items = fetchedItems
            .map((itemMap) => CartItem.fromJson(itemMap as Map<String, dynamic>))
            .toList();
      } else {
        _items = [];
      }
      notifyListeners();
    } catch (error) {
      print('Error fetching cart: $error');
    }
  }

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

  void addItem(String id, String name, double price, int quantity) {
    var index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index].quantity += quantity;
    } else {
      _items.add(CartItem(id: id, name: name, price: price, quantity: quantity));
    }
    _saveCart();
    notifyListeners();
  }

  void removeItem(String productId) {
    final existingItemIndex = _items.indexWhere((item) => item.id == productId);
    if (existingItemIndex >= 0) {
      if (_items[existingItemIndex].quantity > 1) {
        _items[existingItemIndex].quantity -= 1;
      } else {
        _items.removeAt(existingItemIndex);
      }
      _saveCart();
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    _items = [];
    await _saveCart();
    notifyListeners();
  }

  Future<void> placeOrder() async {
    if (_userId == null || _items.isEmpty) {
      throw Exception('Cannot place order: User not logged in or cart is empty.');
    }

    try {
      final orderData = {
        'userId': _userId,
        'items': _items.map((item) => item.toJson()).toList(),
        'subtotal': subtotal,
        'vat': vat,
        'totalPrice': totalPriceWithVat,
        'itemCount': itemCount,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('orders').add(orderData);

      await clearCart();
    } catch (error) {
      print('Error placing order: $error');
      throw Exception('Failed to place order. Please check your connection and try again.');
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
