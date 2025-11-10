import 'package:flutter/material.dart';
import 'package:ecommerce_app/providers/cart_provider.dart'; // 1. ADD THIS
import 'package:provider/provider.dart'; // 2. ADD THIS

// 1. This is a new StatelessWidget
class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> productData;
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productData,
    required this.productId,
  });

  @override
  // 2. Create the State class
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

// 3. Rename the main class to _ProductDetailScreenState and extend State
class _ProductDetailScreenState extends State<ProductDetailScreen> {
  // 4. ADD OUR NEW STATE VARIABLE FOR QUANTITY
  int _quantity = 1;

  // 1. ADD THIS FUNCTION
  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  // 2. ADD THIS FUNCTION
  void _decrementQuantity() {
    // We don't want to go below 1
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Extract data from the map for easier use
    final String name = widget.productData['name'];
    final String description = widget.productData['description'];
    final String imageUrl = widget.productData['imageUrl'];
    final double price = widget.productData['price'];

    // 1. ADD THIS LINE: Get the CartProvider
    // We set listen: false because we are not rebuilding, just calling a function
    final cart = Provider.of<CartProvider>(context, listen: false);

    // 2. The main screen widget
    return Scaffold(
      appBar: AppBar(
        // 3. Show the product name in the top bar
        title: Text(name),
      ),
      // 4. This allows scrolling if the description is very long
      body: SingleChildScrollView(
        child: Column(
          // 5. Make children fill the width
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 6. The large product image
            Image.network(
              imageUrl,
              height: 300, // Give it a fixed height
              fit: BoxFit.cover, // Make it fill the space
              // 7. Add the same loading/error builders as the card
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const SizedBox(
                  height: 300,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox(
                  height: 300,
                  child: Center(child: Icon(Icons.broken_image, size: 100)),
                );
              },
            ),

            // 8. A Padding widget to contain all the text
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 9. Product Name (large font)
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 10. Price (large font, different color)
                  Text(
                    '₱${price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 11. A horizontal dividing line
                  const Divider(thickness: 1),
                  const SizedBox(height: 16),

                  // 12. The full description
                  Text(
                    'About this item',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5, // Adds line spacing for readability
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 4. --- ADD THIS NEW SECTION ---
                  //    (before the "Add to Cart" button)
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 5. DECREMENT BUTTON
                      IconButton.filledTonal(
                        icon: const Icon(Icons.remove),
                        onPressed: _decrementQuantity,
                      ),

                      // 6. QUANTITY DISPLAY
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          '$_quantity', // 7. Display our state variable
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // 8. INCREMENT BUTTON
                      IconButton.filled(
                        icon: const Icon(Icons.add),
                        onPressed: _incrementQuantity,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // --- END OF NEW SECTION ---

                  // 9. Find your "Add to Cart" button
                  ElevatedButton.icon(
                    onPressed: () {
                      // 10. --- THIS IS THE UPDATED LOGIC ---
                      //    We now pass the _quantity from our state
                      cart.addItem(
                        widget.productId,
                        name,
                        price,
                        _quantity, // 11. Pass the selected quantity
                      );

                      // 12. Update the SnackBar message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added $_quantity x $name to cart!'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: const Text('Add to Cart'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
