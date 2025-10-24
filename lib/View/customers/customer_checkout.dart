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
  String? _selectedMethod; // Nullable to show hint text
  String _address = "Enter your address"; // Default text
  double _deliveryFee = 0.0; // Default fee

  String? _selectedPayment; // For the payment dropdown
  final List<String> _paymentMethods = [
    'Touch N Go',
    'Credit/Debit Card',
    'Online Transfer',
  ];

  // Controller for the address input
  final _addressController = TextEditingController();

  final List<String> _receivingMethods = ['Delivery', 'Meetup', 'Pickup'];

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  // Function to show the address input modal
  void _showAddressModal() {
    // Set the controller's text to the current address if it's not the placeholder
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
                    Navigator.of(ctx).pop(); // Close the modal
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
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Container(
        padding: const EdgeInsets.all(14),
        height: 70, 
        child: const Center(
          child: Text(
            '✅ Order placed successfully!\nYou can view the order status in the Orders tab.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      backgroundColor: Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 8,
      duration: const Duration(seconds: 3),
    ),
  );

  // Navigate to home after a short delay
  Future.delayed(const Duration(seconds: 2, milliseconds: 500), () {
    if (mounted) {
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
    if (_selectedMethod == null) {
      _showErrorSnackbar('Please select a receiving method.');
      return;
    }

    if (_selectedMethod == 'Delivery' && _address == "Enter your address") {
      _showErrorSnackbar('Please enter your address for delivery.');
      return;
    }

    if (_selectedPayment == null) {
      _showErrorSnackbar('Please select a payment method.');
      return;
    }

    // If all checks pass:
    _placeOrder();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate totals using widget.total (from parent) and _deliveryFee (from state)
    double subtotal = widget.total;
    double finalTotal = subtotal + _deliveryFee;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 248, 221),
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 255, 225, 0),
        elevation: 1,
        // Custom back button
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Main content list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildMethodSelector(),

                // Conditionally show Address selector
                if (_selectedMethod == 'Delivery') _buildAddressSelector(),

                _buildPaymentSelector(),

                const SizedBox(height: 24),

                // Items list
                const Text(
                  'ITEMS',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // This creates a list of widgets from your items
                ...widget.items.map((item) => _buildItemTile(item)).toList(),

                const SizedBox(height: 24),

                // Price details
                _buildPriceRow(
                  'Subtotal (${widget.items.length})',
                  'RM${subtotal.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 8),
                _buildPriceRow(
                  'Delivery Fee',
                  _deliveryFee == 0.0
                      ? 'Free'
                      : 'RM${_deliveryFee.toStringAsFixed(2)}',
                ),
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

          // Bottom "Place order" button
          _buildPlaceOrderButton(context),
        ],
      ),
    );
  }

  // Receiving Method Dropdown
  Widget _buildMethodSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Receiving Method',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          DropdownButton<String>(
            value: _selectedMethod,
            hint: Text(
              'Select a method',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            underline: const SizedBox(), // Hides the default underline
            items: _receivingMethods.map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedMethod = newValue;
                // Update delivery fee based on selection
                if (newValue == 'Delivery') {
                  _deliveryFee = 5.00; // Example fee
                } else {
                  _deliveryFee = 0.0;
                }
              });
            },
          ),
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
                  // The Expanded + Flexible here prevents the text from overflowing
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
            underline: const SizedBox(), // Hides the default underline
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          // Image
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
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Store',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
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
                const Text(
                  'Quantity: 01',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
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
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ElevatedButton(
        // Hooked up the validation function
        onPressed: _validateAndPlaceOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
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
