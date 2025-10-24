import 'package:flutter/material.dart';
import 'customer_checkout.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final int quantity;
  // bool isSelected; //multiple item

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.quantity,
    // this.isSelected = false,
  });
}

class CustomerCart extends StatefulWidget {
  const CustomerCart({super.key});

  @override
  State<CustomerCart> createState() => _CustomerCartState();
}

class _CustomerCartState extends State<CustomerCart> {
  // Mock data
  final List<CartItem> _cartItems = [
    CartItem(
      id: '1',
      name: 'Red Bean Bun',
      price: 4.50,
      imageUrl: 'placeholder',
      quantity: 2,
    ),
    CartItem(
      id: '2',
      name: 'Chocolate Bun',
      price: 5.00,
      imageUrl: 'placeholder',
      quantity: 1,
    ),
    CartItem(
      id: '3',
      name: 'Kaya Puff',
      price: 3.20,
      imageUrl: 'placeholder',
      quantity: 3,
    ),
    CartItem(
      id: '4',
      name: 'Red Bean Bun',
      price: 4.50,
      imageUrl: 'placeholder',
      quantity: 1,
    ),
    CartItem(
      id: '5',
      name: 'Chocolate Bun',
      price: 5.00,
      imageUrl: 'placeholder',
      quantity: 1,
    ),
    CartItem(
      id: '6',
      name: 'Kaya Puff',
      price: 3.20,
      imageUrl: 'placeholder',
      quantity: 1,
    ),
  ];

  String? _selectedItemId;

  // --- Calculate total price of the SINGLE selected item ---
  double get _totalPrice {
    if (_selectedItemId == null) {
      return 0.0;
    }
    CartItem selectedItem;
    try {
      // Find the selected item using firstWhere
      selectedItem = _cartItems.firstWhere(
        (item) => item.id == _selectedItemId,
      );

      // Explicitly check if quantity is somehow null AFTER finding the item
      // Although 'quantity' is required, this adds extra safety
      final int quantity = selectedItem.quantity ?? 0;
      return selectedItem.price * quantity;
    } catch (e) {
      // This catch block handles the case where firstWhere finds NO item
      // (which shouldn't happen if _selectedItemId comes from the list, but it's safe)
      print("Error finding selected item in _totalPrice: $e");
      return 0.0; // Return 0 if item not found or error occurs
    }
  }

  // --- Get the SINGLE selected CartItem object ---
  CartItem? get _selectedCartItem {
    if (_selectedItemId == null) {
      return null;
    }
    try {
      return _cartItems.firstWhere((item) => item.id == _selectedItemId);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 254, 246),
      appBar: AppBar(
        title: const Text(
          'Cart',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0),
            child: Text(
              '(Select one item to checkout at a time)',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              itemCount: _cartItems.length,
              itemBuilder: (context, index) {
                final item = _cartItems[index];
                return CartItemCard(
                  item: item,
                  isSelected: _selectedItemId == item.id,
                  onChanged: (String? selectedId) {
                    setState(() {
                      _selectedItemId = selectedId;
                    });
                  },
                );
              },
            ),
          ),
          // Conditionally show Checkout Button if an item is selected
          if (_selectedItemId != null) // Check if an item ID is selected
            _buildCheckoutButton(context)
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildCheckoutButton(BuildContext context) {
    final selectedItem = _selectedCartItem;
    if (selectedItem == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 24.0,
        vertical: 16.0,
      ).copyWith(bottom: 32.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            // Navigate with the SINGLE selected item (which now includes quantity)
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CheckoutPage(
                  items: [selectedItem], // Pass list with one item
                  total:
                      _totalPrice, // Pass the calculated total (price * quantity)
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 255, 153, 0),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
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

class CartItemCard extends StatelessWidget {
  final CartItem item;
  final bool isSelected;
  final Function(String?)? onChanged;

  const CartItemCard({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color.fromARGB(255, 252, 248, 221),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(
                Icons.image_outlined,
                color: Colors.grey[400],
                size: 32,
              ),
            ),
            const SizedBox(width: 16.0),

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
                    style: TextStyle(fontSize: 15, color: Colors.grey[800]),
                  ),

                  const SizedBox(height: 4),

                  // Text(
                  //   'Qty: ${item.quantity}',
                  //   style: TextStyle(fontSize: 15, color: Colors.grey[800]),
                  // ),
                ],
              ),
            ),
            const SizedBox(width: 20.0),

            Text(
                    'Qty: ${item.quantity}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                  ),

            const SizedBox(width: 16.0),

            Radio<String>(
              value: item.id,
              groupValue: isSelected ? item.id : null,
              onChanged: (String? value) {
                // Call the callback with the item's ID when tapped
                if (onChanged != null) {
                  onChanged!(item.id);
                }
              },
              activeColor: const Color.fromARGB(255, 255, 166, 0),
            ),
          ],
        ),
      ),
    );
  }
}
