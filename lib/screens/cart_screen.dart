import 'package:ecommerce_app/providers/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_app/screens/order_success_screen.dart'; // 1. ADD THIS
import 'package:ecommerce_app/screens/payment_screen.dart'; // 1. Import PaymentScreen

// 2. Change this to a StatefulWidget
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  // 3. Create the State
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // 5. Add our loading state variable
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // 1. Get the cart. This time, we *want* to listen (default)
    //    so this screen rebuilds when we remove an item.
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
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
                              '₱${(cartItem.price * cartItem.quantity).toStringAsFixed(2)}',
                            ),
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

          // 3. --- THIS IS THE NEW PRICE BREAKDOWN CARD ---
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                // 4. Use a Column for multiple rows
                children: [
                  // 5. ROW 1: Subtotal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:', style: TextStyle(fontSize: 16)),
                      Text(
                        '₱${cart.subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // 6. ROW 2: VAT
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('VAT (12%):', style: TextStyle(fontSize: 16)),
                      Text(
                        '₱${cart.vat.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),

                  const Divider(height: 20, thickness: 1),

                  // 7. ROW 3: Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₱${cart.totalPriceWithVat.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // --- END OF NEW CARD ---

          // We'll add a "Checkout" button here in a future module
          const SizedBox(height: 20),
          // 6. --- THIS IS THE MODIFIED BUTTON ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              // 7. Disable if cart is empty, otherwise navigate
              onPressed: cart.items.isEmpty
                  ? null
                  : () {
                      // 8. Navigate to our new PaymentScreen
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PaymentScreen(
                            // 9. Pass the final VAT-inclusive total
                            totalAmount: cart.totalPriceWithVat,
                          ),
                        ),
                      );
                    },
              // 10. No more spinner!
              child: const Text('Proceed to Payment'),
            ),
          ),
        ],
      ),
    );
  }
}
