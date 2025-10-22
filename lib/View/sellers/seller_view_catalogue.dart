import 'package:chikankan/View/sellers/add_item.dart';
import 'package:chikankan/View/sellers/bottom_navigation_bar.dart';
import 'package:chikankan/View/sellers/custom_toggle_button.dart';
import 'package:chikankan/View/sellers/edit_item.dart';
import 'package:chikankan/View/sellers/seller_chat.dart';
import 'package:chikankan/View/sellers/seller_homepage.dart';
import 'package:chikankan/View/sellers/seller_pending_order.dart';
import 'package:chikankan/View/sellers/seller_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:chikankan/Model/item_model.dart';

class SellerCataloguePage extends StatefulWidget {
  const SellerCataloguePage({super.key});

  @override
  State<SellerCataloguePage> createState() => _SellerCataloguePageState();
}

class _SellerCataloguePageState extends State<SellerCataloguePage> {
  
  //Seller UID
  final String? _currentSellerId = FirebaseAuth.instance.currentUser?.uid;
  late final Stream<List<Item>> _itemsStream;
  @override
  void initState() {
    super.initState();
    if (_currentSellerId != null) {
      _itemsStream = FirebaseFirestore.instance
          .collection('items')
          .where('sellerId', isEqualTo: _currentSellerId) 
          .snapshots()
          .map((snapshot) {
        // Convert the QuerySnapshot into a List of Item objects
        return snapshot.docs.map((doc) => Item.fromFirestore(doc)).toList();
      });
    } else {
      // Handle the case where the user is not logged in (e.g., return an empty stream)
      _itemsStream = Stream.value([]);
    }
  }

  
  int _selectedIndex = 0; //Default Homepage since not appear in btm bar

  void _onNavTap(int index) {
      setState(() {
          _selectedIndex = index;
          if (index == 0) {
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SellerHomepage()));
          } else if (index == 1) {
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SellerChat()));
          } else if (index == 2) {
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SellerPendingOrder()));
          } else {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SellerProfile()));
      }});
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
                color: const Color.fromARGB(255, 255, 153, 0),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: SizedBox(
                width: 300,
                height: 40,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Add Item',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // --- Item List ---
          Expanded(
            child: StreamBuilder<List<Item>>(
              stream: _itemsStream,
              builder: (context, snapshot) {
                // Loading State
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Error State
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading catalogue: ${snapshot.error}'));
                }

                // Data Available State
                final items = snapshot.data;
                if (items == null || items.isEmpty) {
                  return const Center(child: Text('No items found in your catalogue.'));
                }

                // Build the list with retrieved items
                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return _buildCatalogueItem(context, items[index]);
                  },
                );
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

  Widget _buildCatalogueItem(BuildContext context, Item item) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EditItem(item: item),
          ),
        );
      },
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Side: Image Placeholder
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  color: Colors.grey[400],
                  // In a real app, use Image.network or Image.asset
                  image: DecorationImage(
                    image: NetworkImage(item.imageUrl), 
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              
              // Right Side: Details and Switch
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                      const SizedBox(height: 30),
                  
                      // Availability Switch and Text
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            CustomAvailabilityToggle(
                              initialValue: item.isAvailable, // Pass the current state
                              onChanged: (newValue) => _toggleAvailability(item, newValue), // Pass the handler
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}