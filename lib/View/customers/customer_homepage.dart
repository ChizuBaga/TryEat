import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:huawei_location/huawei_location.dart'; // Import Location
import 'package:chikankan/locator.dart'; // Import locator
import 'package:chikankan/Controller/location_controller.dart'; // Import controller
import 'package:chikankan/Model/seller_temp.dart'; // Import Seller model
import 'package:chikankan/View/customers/customer_itemlist.dart'; // Assuming this is your item list page
// Assuming StoreCard is in this file or imported separately

class CustomerHomepage extends StatefulWidget {
  const CustomerHomepage({super.key});

  @override
  State<CustomerHomepage> createState() => _CustomerHomepageState();
}

class _CustomerHomepageState extends State<CustomerHomepage> {
  // Get the location controller instance
  final LocationController _locationController = locator<LocationController>();
  
  // Future to hold the result of getting nearby sellers
  late Future<List<DocumentSnapshot>> _nearbySellersFuture;

  @override
  void initState() {
    super.initState();
    // Start fetching nearby sellers when the widget is initialized
    _nearbySellersFuture = _locationController.getNearbySellers(radiusKm: 50);
  }
  
  // Define the stream for other sections (New, Last Order)
  final Stream<QuerySnapshot> storesStream = FirebaseFirestore.instance
      .collection('sellers')
      .where('isVerified', isEqualTo: true)
      // Add ordering if needed, e.g., by creation date for 'New'
      // .orderBy('createdAt', descending: true) 
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          backgroundColor: const Color.fromARGB(255, 255, 229, 143),
          elevation: 0,
          automaticallyImplyLeading: false,
          title: _buildSearchBar(),
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 255, 254, 246),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          // Use FutureBuilder specifically for 'Nearby'
          _buildNearbyStoreSection(context, title: 'Nearby'), 
          // Keep using StreamBuilder for other sections
          _buildStoreSection(context, title: 'New', stream: storesStream),
          _buildStoreSection(context, title: 'Last Order', stream: storesStream),
        ],
      ),
    );
  }

  // --- WIDGET BUILDER METHODS --- 
  // (Keep _buildSearchBar as is)

  // NEW: Widget builder specifically for the Nearby section using FutureBuilder
  Widget _buildNearbyStoreSection(BuildContext context, {required String title}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 190,
          child: FutureBuilder<List<DocumentSnapshot>>(
            future: _nearbySellersFuture, // Use the future from initState
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                // Display a more specific error
                return Center(child: Text("Error finding nearby stores: ${snapshot.error}")); 
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No nearby stores found."));
              }

              // Data loaded successfully - Use the filtered list
              List<DocumentSnapshot> nearbyDocs = snapshot.data!; 

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: nearbyDocs.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot doc = nearbyDocs[index];
                  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                  return StoreCard(
                    name: data['businessName'] ?? 'Store Name',
                    imageUrl: data['imageUrl'] ?? 'placeholder',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CustomerItemListPage(
                            sellerId: doc.id,
                            storeName: data['businessName'] ?? 'Store Name',
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // Keep your original _buildStoreSection for sections using StreamBuilder
  Widget _buildStoreSection(
    BuildContext context, {
    required String title,
    required Stream<QuerySnapshot> stream,
  }) {
    // ... (Your existing _buildStoreSection code remains unchanged)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 190,
          child: StreamBuilder<QuerySnapshot>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text("Error loading stores."));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No stores found."));
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot doc = snapshot.data!.docs[index];
                  Map<String, dynamic> data =
                      doc.data() as Map<String, dynamic>;
                  return StoreCard(
                    name: data['businessName'] ?? 'Store Name',
                    imageUrl: data['imageUrl'] ?? 'placeholder',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CustomerItemListPage(
                            sellerId: doc.id,
                            storeName: data['businessName'] ?? 'Store Name',
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // Keep your _buildSearchBar
   Widget _buildSearchBar() {
    // ... (Your existing _buildSearchBar code remains unchanged)
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(40.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: const Color.fromARGB(255, 252, 248, 221),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40.0),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

// Keep your StoreCard widget (ensure it's defined or imported)
class StoreCard extends StatelessWidget {
  // ... (Your StoreCard code)
  final String name;
  final String imageUrl;
  final VoidCallback onTap;

  const StoreCard({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 16.0),
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          color: const Color.fromARGB(255, 252, 248, 221),
          elevation: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image part
              Expanded(
                flex: 3,
                child: Container(
                  color: Colors.grey[300],
                  // TODO: Replace with actual image loading (Image.network)
                  child: imageUrl == 'placeholder' 
                    ? const Center(
                        child: Icon(Icons.image_outlined, color: Colors.black, size: 48),
                      )
                    : Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity),
                ),
              ),
              // Text part
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Center(
                    child: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
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