import 'package:ecommerce_app/providers/cart_provider.dart';
import 'package:ecommerce_app/screens/order_success_screen.dart'; // ADDED (Module 10)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 1. Change to StatefulWidget to manage loading state (Module 10)
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // 2. State variable to track if an order is being placed (Module 10)
  bool _isLoading = false;

  // 3. The function to handle the entire checkout process (Module 10)
  Future<void> _placeOrder() async {
    // 4. Get the provider instance (listen: false) (Module 10)
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // Guard clause: ensure cart is not empty before proceeding
    if (cartProvider.items.isEmpty) {
      return;
    }

    // 5. Start loading and rebuild UI (Module 10)
    setState(() {
      _isLoading = true;
    });

    try {
      // 6. Call the persistent placeOrder logic (Module 10)
      await cartProvider.placeOrder();

      // 7. On success, navigate to the OrderSuccessScreen (Module 10)
      if (mounted) {
        // Use pushAndRemoveUntil to clear the navigation history
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const OrderSuccessScreen(),
          ),
              (Route<dynamic> route) => false, // Remove all previous routes
        );
      }
    } catch (error) {
      // 8. On failure, show an error message (Module 10)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // 9. Stop loading and rebuild UI, regardless of success or failure (Module 10)
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Get the cart. This time, we *want* to listen (default)
    //    so this screen rebuilds when we remove an item.
    final cart = Provider.of<CartProvider>(context);

    // Determine if the button should be disabled (Module 10)
    final isDisabled = _isLoading || cart.items.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
      ),
      body: Column(
        children: [
          // 2. The list of items
          Expanded(
            // 3. If cart is empty, show a message
            child: cart.items.isEmpty
                ? const Center(child: Text('Your cart is empty.'))
                : ListView.builder(
              itemCount: cart.items.length,
              itemBuilder: (context, index) {
                final cartItem = cart.items[index];
                // 4. A ListTile to show item details
                return ListTile(
                  leading: CircleAvatar(
                    // Show a mini-image (or first letter)
                    child: Text(cartItem.name[0]),
                  ),
                  title: Text(cartItem.name),
                  subtitle: Text('Qty: ${cartItem.quantity}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 5. Total for this item
                      Text(
                          '₱${(cartItem.price * cartItem.quantity).toStringAsFixed(2)}'),
                      // 6. Remove button
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          // 7. Call the removeItem function
                          cart.removeItem(cartItem.id);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 8. The Total Price Summary
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '₱${cart.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // 10. The Checkout Button (Module 10)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50), // Full width button
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              // 11. Disable if loading OR if cart is empty (Module 10)
              onPressed: isDisabled ? null : _placeOrder,
              child: _isLoading
                  ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
                  : const Text(
                'Place Order',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}