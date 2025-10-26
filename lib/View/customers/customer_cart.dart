import 'package:flutter/material.dart';
import 'customer_checkout.dart';
import 'package:chikankan/Model/cart_model.dart';
import 'package:chikankan/locator.dart';
import 'package:chikankan/Controller/cart_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerCart extends StatefulWidget {
  const CustomerCart({super.key});

  @override
  State<CustomerCart> createState() => _CustomerCartState();
}

class _CustomerCartState extends State<CustomerCart> {
  final CartService _cartService = locator<CartService>();
  
  final ValueNotifier<String?> _selectedItemIdNotifier = ValueNotifier<String?>(null);

  // --- Helper to get the SINGLE selected CartItem object ---
  CartItem? _getSelectedCartItem(List<CartItem> allItems, String? selectedItemIdValue) {
    if (selectedItemIdValue == null) {
      return null;
    }
    try {
      return allItems.firstWhere((item) => item.id == selectedItemIdValue);
    } catch (e) {
      print("Selected item not found in current list: $e");
      // Reset selection via notifier if item disappears
      WidgetsBinding.instance.addPostFrameCallback((_) {
        
        if (mounted && _selectedItemIdNotifier.value == selectedItemIdValue) {
           _selectedItemIdNotifier.value = null; // Reset selection safely
        }
      });
      return null;
    }
  }

  // --- Helper to calculate total price of the SINGLE selected item ---
  double _getSelectedTotalPrice(CartItem? selectedItem) {
    if (selectedItem == null) {
      return 0.0;
    }
    return selectedItem.price * selectedItem.quantity;
  }
  @override
  void dispose() {
    _selectedItemIdNotifier.dispose(); // Clean up the notifier
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use AnimatedBuilder to listen for changes in CartService
    final Stream<QuerySnapshot>? cartStream = _cartService.getCartStream();
  
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 254, 246),
      appBar: AppBar(
        title: const Text('Cart', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      // --- Use StreamBuilder ---
      body: StreamBuilder<QuerySnapshot>(
        stream: cartStream,
        builder: (context, snapshot) {
          // --- Handle Loading/Error States ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("Cart Stream Error: ${snapshot.error}");
            return const Center(child: Text("Error loading cart."));
          }
          // Handle case where user isn't logged in (stream is null)
          if (!snapshot.hasData && cartStream == null) {
             return const Center(child: Text("Please log in to view your cart."));
          }
          // Handle empty cart
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Your cart is empty.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }
          final List<DocumentSnapshot> cartDocs = snapshot.data!.docs;
          final List<CartItem> cartItems = cartDocs
              .map((doc) => CartItem.fromFirestore(doc))
              .toList();
          
          return ValueListenableBuilder<String?>(
            valueListenable: _selectedItemIdNotifier, // Listen to the notifier
            builder: (context, selectedItemIdValue, child) {
              // --- Calculate selected item/price based on the NOTIFIER's current value ---
              final CartItem? selectedCartItem = _getSelectedCartItem(cartItems, selectedItemIdValue);
              final double selectedTotalPrice = _getSelectedTotalPrice(selectedCartItem);

              // --- Build UI based on fetched data ---
              return Column(
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
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return CartItemCard(
                      item: item,
                      isSelected: selectedItemIdValue == item.id, // Correct: Use value from builder
                      onChanged: (String? selectedId) {
                       _selectedItemIdNotifier.value = (_selectedItemIdNotifier.value == selectedId)
                      ? null // If yes, deselect
                      : selectedId; // If no, select the tapped one
                      
                     },
                    );
                  },
                ),
              ),
              // --- Show Checkout Button ONLY if an item is selected ---
              if (selectedItemIdValue != null && selectedCartItem != null)
                _buildCheckoutButton(context, selectedCartItem, selectedTotalPrice)
              else
                const SizedBox(height: 90), // Keep space
                ],
              );
            }, 
          ); 
        }, 
      ), 
    ); // End Scaffold
  } // End build

  // --- Modify Checkout Button to take a single item ---
  Widget _buildCheckoutButton(BuildContext context, CartItem selectedItem, double total) {
     return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0).copyWith(bottom: 32.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            // --- Navigate with only the SINGLE selected item ---
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CheckoutPage(
                  items: [selectedItem], // Pass a list containing only the selected item
                  total: total, // Pass the total for the selected item
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
          // --- Update button text ---
          child: Text(
            'Checkout Selected (RM${total.toStringAsFixed(2)})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
      ),
    );
  }
}

class CartItemCard extends StatelessWidget {
  final CartItem item;
  final bool isSelected;
  final Function(String?)? onChanged; // Callback signature is fine

  const CartItemCard({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final CartService cartService = locator<CartService>();

    return Card(
      color: const Color.fromARGB(255, 252, 248, 221),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 2,
      child: InkWell( // Make the whole card tappable for selection
        onTap: () {
           if (onChanged != null) {
              onChanged!(isSelected ? null : item.id);
           }
        },
        borderRadius: BorderRadius.circular(12.0),
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
                    Text('Qty: ${item.quantity}', style: TextStyle(fontSize: 15, color: Colors.grey[800])),
                  ],
                ),
              ),
              Radio<String>(
                value: item.id,
                groupValue: isSelected ? item.id : null, // Set groupValue based on isSelected
                onChanged: (String? value) {
                  // Call the callback when the radio itself is tapped
                  if (onChanged != null) {
                    onChanged!(item.id);
                  }
                },
                activeColor: const Color.fromARGB(255, 255, 166, 0),
              ),
              IconButton(
                icon: Icon(Icons.remove_circle_outline, color: Colors.red.shade700),
                tooltip: 'Remove Item',
                onPressed: () {
                  cartService.removeItem(item.id);
                }
              ),
            ],
          ),
        ),
      ),
    );
  }
}
