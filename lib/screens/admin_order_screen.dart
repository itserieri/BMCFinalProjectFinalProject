import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Part B: The Screen Layout
class AdminOrderScreen extends StatefulWidget {
  const AdminOrderScreen({super.key});

  @override
  State<AdminOrderScreen> createState() => _AdminOrderScreenState();
}

class _AdminOrderScreenState extends State<AdminOrderScreen> {
  // A simple list of available statuses for the dialog
  final List<String> statuses = ['Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled'];

  // 1. Helper function to determine the status chip color
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Processing':
        return Colors.blue;
      case 'Shipped':
        return Colors.deepPurple;
      case 'Delivered':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // 2. Function to update the order status in Firestore (Part C)
  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': newStatus});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order $orderId status updated to $newStatus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  // 3. Function to show the status selection dialog
  void _showStatusDialog(String orderId, String currentStatus) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Order Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: statuses.map((status) {
              return ListTile(
                title: Text(status),
                // Show a checkmark for the current status
                trailing: status == currentStatus ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () {
                  Navigator.of(context).pop(); // Close the dialog
                  _updateOrderStatus(orderId, status); // Update status
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Orders'),
      ),
      // Part B: Fetching all orders
      body: StreamBuilder<QuerySnapshot>(
        // 4. Query: Get ALL orders, sorted by newest first
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('orderDate', descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No orders found.'),
            );}

          final orders = snapshot.data!.docs;

          return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
          final orderDoc = orders[index];
          final orderId = orderDoc.id;
          final orderData = orderDoc.data() as Map<String, dynamic>;

          // Data extraction with safe fallbacks
          final currentStatus = orderData['status'] as String? ?? 'Pending';
          final total = (orderData['totalPrice'] as num? ?? 0.0).toDouble();
          final userId = orderData['userId'] as String? ?? 'N/A';

          return Card(
          elevation: 1,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          // 5. onTap: Call the dialog function
          child: ListTile(
          onTap: () => _showStatusDialog(orderId, currentStatus),

          // Display key details
          title: Text('Order ID: $orderId', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('User ID: $userId\nTotal: ₱${total.toStringAsFixed(2)}'),
          isThreeLine: true,

          // Display the colored status chip
          trailing: Chip(
          label: Text(
          currentStatus,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: _getStatusColor(currentStatus),
          ),
          ),
          );
          },
          );
        },
      ),
    );
  }
}