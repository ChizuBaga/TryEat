import 'package:flutter/material.dart';
import 'customer_checkout.dart'; // Import the new checkout page

// ---
// STEP 1: Create a class to model your cart item data
// ---
class CartItem {
  final String id;
  final String name;
  final double price;
  final String imageUrl; // Placeholder for your image
  bool isSelected;       // This will be controlled by the checkbox

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.isSelected = false, // Items are not selected by default
  });
}

// ---
// STEP 2: Stateful Widget
// ---
class CustomerCart extends StatefulWidget {
  const CustomerCart({super.key});

  @override
  State<CustomerCart> createState() => _CustomerCartState();
}

class _CustomerCartState extends State<CustomerCart> {
  // ---
  // STEP 3: Create mock data for your cart
  // You will replace this with a call to Firebase
  // ---
  final List<CartItem> _cartItems = [
    CartItem(id: '1', name: 'Red Bean Bun', price: 4.50, imageUrl: 'placeholder'),
    CartItem(id: '2', name: 'Chocolate Bun', price: 5.00, imageUrl: 'placeholder'),
    CartItem(id: '3', name: 'Kaya Puff', price: 3.20, imageUrl: 'placeholder'),
    CartItem(id: '4', name: 'Red Bean Bun', price: 4.50, imageUrl: 'placeholder'),
    CartItem(id: '5', name: 'Chocolate Bun', price: 5.00, imageUrl: 'placeholder'),
    CartItem(id: '6', name: 'Kaya Puff', price: 3.20, imageUrl: 'placeholder'),
    CartItem(id: '7', name: 'Kaya Puff', price: 3.20, imageUrl: 'placeholder'),
    CartItem(id: '8', name: 'Kaya Puff', price: 3.20, imageUrl: 'placeholder'),
    CartItem(id: '9', name: 'Kaya Puff', price: 3.20, imageUrl: 'placeholder'),
    CartItem(id: '10', name: 'Kaya Puff', price: 3.20, imageUrl: 'placeholder'),
  ];

  // ---
  // Calculate the total price of selected items
  // ---
  double get _totalPrice {
    double total = 0.0;
    for (var item in _cartItems) {
      if (item.isSelected) {
        total += item.price;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 248, 221),
      appBar: AppBar(
        title: const Text('Cart', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      // ---
      // STEP 4: Use a Column to hold the List and the Checkout Bar
      // ---
      body: Column(
        children: [
          // The list of items should take up all available space
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              itemCount: _cartItems.length,
              itemBuilder: (context, index) {
                final item = _cartItems[index];
                return CartItemCard(
                  item: item,
                  //update the state of the checkbox
                  onChanged: (bool? newValue) {
                    setState(() {
                      _cartItems[index].isSelected = newValue ?? false;
                    });
                  },
                );
              },
            ),
          ),
          // ---
          // STEP 6: Conditionally show the Checkout Button based on price
          // ---
          if (_totalPrice > 0)
            _buildCheckoutButton(context)
          else
            const SizedBox.shrink(), // Show nothing if no items are selected
        ],
      ),
    );
  }

  // ---
  // A widget for the bottom checkout button
  // ---
  Widget _buildCheckoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0)
          .copyWith(bottom: 32.0), // Extra padding for the home bar
      child: SizedBox(
        width: double.infinity, // Make the button full-width
        child: ElevatedButton(
          onPressed: () {
            // Get all selected items
            final selectedItems =
                _cartItems.where((item) => item.isSelected).toList();

            // Navigate to the new CheckoutPage
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    CheckoutPage(items: selectedItems, total: _totalPrice),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 255, 153, 0), // Black button
            foregroundColor: Colors.white, // White text
            padding:
                const EdgeInsets.symmetric(vertical: 16.0), // Button height
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            elevation: 5,
          ),
          child: const Text(
            'Checkout',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
      ),
    );
  }
}

// ---
// STEP 5: Create a dedicated widget for the Cart Item Card
// ---
class CartItemCard extends StatelessWidget {
  final CartItem item;
  final Function(bool?)? onChanged;

  const CartItemCard({
    super.key,
    required this.item,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color.fromARGB(255, 255, 229, 143),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Image Placeholder
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child:
                  Icon(Icons.image_outlined, color: Colors.grey[400], size: 32),
            ),
            const SizedBox(width: 16.0),

            // Item Name and Price
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'RM${item.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16.0),
            
            Checkbox(
              value: item.isSelected,
              onChanged: onChanged,
              activeColor: const Color.fromARGB(255, 255, 166, 0), 
              checkColor: Colors.white,
              shape: const CircleBorder(),
              side: BorderSide(color: Colors.grey[400]!, width: 2),
            ),
          ],
        ),
      ),
    );
  }
}

