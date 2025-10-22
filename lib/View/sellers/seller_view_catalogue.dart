import 'package:chikankan/View/sellers/add_item.dart';
import 'package:chikankan/View/sellers/bottom_navigation_bar.dart';
import 'package:chikankan/View/sellers/custom_toggle_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:chikankan/Model/item_model.dart';

class SellerCataloguePage extends StatefulWidget {
  const SellerCataloguePage({super.key});

  @override
  State<SellerCataloguePage> createState() => _SellerCataloguePageState();
}

class _SellerCataloguePageState extends State<SellerCataloguePage> {
  
  final List<Item> _items = [
    Item(id: '1', name: 'Food Name', category: 'Food Name', description: 'Food Name', price: 99.99, imageUrl: 'assets/food_item.png', isAvailable: true),
    Item(id: '2', name: 'Food Name', category: 'Food Name', description: 'Food Name', price: 99.99, imageUrl: 'assets/food_item.png', isAvailable: true),
    Item(id: '3', name: 'Food Name', category: 'Food Name', description: 'Food Name', price: 99.99, imageUrl: 'assets/food_item.png', isAvailable: false),
  ];

  // ⭐️ State variable to track which nav bar item is active (usually managed by a top-level Shell)
  int _selectedIndex = 2; // Assuming the Catalogue/Orders icon is the 3rd item (index 2)

  void _onNavTap(int index) {
      // ⭐️ You would typically handle navigation here, e.g., using a PageView or Navigator.push
      setState(() {
          _selectedIndex = index;
          // Example: if (index == 0) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SellerHomePage()));
      });
  }

  void _toggleAvailability(Item item, bool newValue) {
    setState(() {
      item.isAvailable = newValue;
      FirebaseFirestore.instance.collection('items').doc(item.id).update({'isAvailable': newValue});
    });
  }
  
  void _addItem() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => AddItem()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 248, 221),
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
            child: Text(
              'Catalogue',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ),
          
          // --- Add Item Button ---
          GestureDetector(
            onTap: _addItem,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Colors.black),
                  SizedBox(width: 8),
                  Text(
                    'Add Item',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          
          // --- Item List ---
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                return _buildCatalogueItem(context, _items[index], index);
              },
            ),
          ),
        ],
      ),
      // --- Bottom Navigation Bar ---
      bottomNavigationBar: SellerBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
    );
  }

  // --- Widget Builders ---

  Widget _buildCatalogueItem(BuildContext context, Item item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Side: Image Placeholder
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                color: Colors.grey[200],
                // In a real app, use Image.network or Image.asset
                image: const DecorationImage(
                  image: AssetImage('assets/food_item.png'), // Placeholder
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 15),
            
            // Right Side: Details and Switch
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Food Name and Price
                  Text(
                    item.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'RM${item.price.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),

                  // Availability Switch and Text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CustomAvailabilityToggle(
                        initialValue: item.isAvailable, // Pass the current state
                        onChanged: (newValue) => _toggleAvailability(item, newValue), // Pass the handler
                      ),
                    ],
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