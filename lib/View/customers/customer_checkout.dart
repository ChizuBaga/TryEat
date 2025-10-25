import 'package:flutter/material.dart';
import 'customer_cart.dart';

class CheckoutPage extends StatefulWidget {
  final List<CartItem> items;
  final double total;

  const CheckoutPage({super.key, required this.items, required this.total});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String _address = "Enter your address";
  double _deliveryFee = 0.0;
  String? _selectedPayment;
  final List<String> _paymentMethods = [
    'Touch N Go',
    'Credit/Debit Card',
    'Online Transfer',
  ];
  final _addressController = TextEditingController();

  bool _isAddressRequired(String? deliverMethod) {
    if (deliverMethod == null) return false;
    // Check if the method (case-insensitive) requires an address
    final methodLower = deliverMethod.toLowerCase();
    return methodLower.contains('delivery') ||
        methodLower.contains('3rd party');
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  // Function to show the address input modal
  void _showAddressModal() {
    if (_address != "Enter your address") {
      _addressController.text = _address;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 24.0,
            left: 24.0,
            right: 24.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter Your Address',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _addressController,
                autofocus: true,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'e.g., 123, Jalan Emas...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  onPressed: () {
                    if (_addressController.text.isNotEmpty) {
                      setState(() {
                        _address = _addressController.text;
                      });
                    }
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Confirm Address'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // Function to show success message and navigate home
  void _placeOrder() {
    // Show the SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.all(10),
          height: 70,
          child: const Center(
            child: Text(
              '✅ Order placed successfully!\nYou can view the order status in the Orders tab.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 8,
        duration: const Duration(seconds: 3),
      ),
    );

    // Navigate after the SnackBar duration + a small buffer
    Future.delayed(const Duration(seconds: 3, milliseconds: 200), () {
      if (mounted) {
        // Assuming '/customer_tab' is the route name for your main page with tabs
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/customer_tab',
          (Route<dynamic> route) => false,
        );
      }
    });
  }

  // Function to show an error message
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Function to validate all fields before placing order
  void _validateAndPlaceOrder() {
    final String? deliverMethod = widget.items.isNotEmpty
        ? widget.items.first.deliverMethod
        : null;

    if (_isAddressRequired(deliverMethod) && _address == "Enter your address") {
      _showErrorSnackbar('Please enter your address for delivery.');
      return;
    }

    // Check payment method
    if (_selectedPayment == null) {
      _showErrorSnackbar('Please select a payment method.');
      return;
    }

    // If all checks pass:
    _placeOrder();
  }

  @override
  Widget build(BuildContext context) {
    final CartItem? singleItem = widget.items.isNotEmpty
        ? widget.items.first
        : null;
    final String itemDeliverMethod =
        singleItem?.deliverMethod ?? 'N/A'; 

    _deliveryFee = _isAddressRequired(itemDeliverMethod)
        ? 5.00
        : 0.0; 

    double subtotal = widget.total;
    double finalTotal = subtotal + _deliveryFee;

    String deliveryFeeText = _isAddressRequired(itemDeliverMethod)
        ? (_deliveryFee == 0.0
              ? 'Free'
              : 'RM${_deliveryFee.toStringAsFixed(2)}')
        : "N/A";

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 248, 221),
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 255, 229, 143), // Your color
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildStaticInfoRow('Receive Method', itemDeliverMethod), 
                if (_isAddressRequired(itemDeliverMethod)) _buildAddressSelector(),
                _buildPaymentSelector(),
                const SizedBox(height: 24),

                const Text(
                  'ITEM',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                if (singleItem != null)
                  _buildItemTile(singleItem)
                else
                  const Text("Item details not available."),

                const SizedBox(height: 24),

                // Price details
                _buildPriceRow('Subtotal', 'RM${subtotal.toStringAsFixed(2)}'),

                const SizedBox(height: 8),

                _buildPriceRow('Delivery Fee', deliveryFeeText),

                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                _buildPriceRow(
                  'Total',
                  'RM${finalTotal.toStringAsFixed(2)}',
                  isTotal: true,
                ),
              ],
            ),
          ),
          _buildPlaceOrderButton(context),
        ],
      ),
    );
  }

  Widget _buildStaticInfoRow(String title, String value) {
     return Padding(
       padding: const EdgeInsets.symmetric(vertical: 12.0),
       child: Row(
         mainAxisAlignment: MainAxisAlignment.spaceBetween,
         children: [
           Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
           Text(value, style: TextStyle(fontSize: 16, color: Colors.grey[800])), // Display value
         ],
       ),
     );
   }

  // Address row
  Widget _buildAddressSelector() {
    return InkWell(
      onTap: _showAddressModal,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Address',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      _address,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Payment Method Dropdown
  Widget _buildPaymentSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Payment Method',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          DropdownButton<String>(
            value: _selectedPayment,
            hint: Text(
              'Select a method',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            underline: const SizedBox(),
            items: _paymentMethods.map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedPayment = newValue;
              });
            },
          ),
        ],
      ),
    );
  }

  // item row in checkout
  Widget _buildItemTile(CartItem item) {
    int quantity = item.quantity;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Container(
              width: 70,
              height: 70,
              color: Colors.grey[200],
              child: (item.imageUrl == 'placeholder' || item.imageUrl.isEmpty)
                  ? Icon(
                      Icons.image_outlined,
                      color: Colors.grey[400],
                      size: 32,
                    )
                  : Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Icon(
                        Icons.broken_image_outlined,
                        color: Colors.grey[400],
                        size: 32,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Store',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Text(
                  'Description: ...',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  'Quantity: $quantity',
                  style: const TextStyle(fontSize: 15, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Price
          Text(
            'RM${item.price.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  //price summary rows
  Widget _buildPriceRow(String title, String amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.black : Colors.grey[700],
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  //bottom button
  Widget _buildPlaceOrderButton(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24.0,
        vertical: 16.0,
      ).copyWith(bottom: 32.0),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 255, 254, 246),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _validateAndPlaceOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color.fromARGB(255, 255, 153, 0),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        child: const Text(
          'Place order',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }
}
