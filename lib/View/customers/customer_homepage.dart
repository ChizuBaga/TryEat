import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chikankan/Controller/new_recommendation_controller.dart'; // Import Location
import 'package:chikankan/locator.dart'; // Import locator
import 'package:chikankan/Controller/location_controller.dart'; // Import controller
import 'package:chikankan/View/customers/customer_itemlist.dart'; // Assuming this is your item list page
import 'package:chikankan/View/item_detail_page.dart'; // Import Item Details Page
import 'package:chikankan/View/customers/nearby_seller_map.dart';

class CustomerHomepage extends StatefulWidget {
  const CustomerHomepage({super.key});

  @override
  State<CustomerHomepage> createState() => _CustomerHomepageState();
}

class _CustomerHomepageState extends State<CustomerHomepage> {
  // Get the location controller instance
  final LocationController _locationController = locator<LocationController>();
  final NewRecommendationController _newRecommendationController = locator<NewRecommendationController>();

  late Future<List<DocumentSnapshot>> _nearbySellersFuture;
  late Future<List<DocumentSnapshot>> _newSellersFuture;

  @override
  void initState() {
    super.initState();
    // Start fetching nearby sellers when the widget is initialized
    _nearbySellersFuture = _locationController.getNearbySellers(radiusKm: 50);
    _newSellersFuture = _newRecommendationController.getRecentlyCreatedSellers();
  }
  
  // Define the stream for other sections (New, Last Order)
  final Stream<QuerySnapshot> storesStream = FirebaseFirestore.instance
      .collection('sellers')
      .where('isVerified', isEqualTo: true)
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
          _buildNearbyStoreSection(context, title: 'In Your Neighborhood'), 
          // Keep using StreamBuilder for other sections
          _buildStoreSection(context, title: 'Last Order', stream: storesStream),
          _buildNewStoreSection(context, title: 'Freshly Added'),
          
        ],
      ),
    );
  }

Widget _buildNearbyStoreSection(BuildContext context, {required String title}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
      ),

      // --- Keep FutureBuilder for the list ---
      FutureBuilder<List<DocumentSnapshot>>(
        future: _nearbySellersFuture,
        builder: (context, snapshot) {
          // --- Handle Loading ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show only loading indicator while fetching
            return const SizedBox(
              height: 190, // Keep consistent height during load
              child: Center(child: CircularProgressIndicator()),
            );
          }
          // --- Handle Error ---
          if (snapshot.hasError) {
            return SizedBox( // Keep consistent height on error
              height: 190,
              child: Center(child: Text("Error: ${snapshot.error}")),
            );
          }
          // --- Handle Empty ---
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
             return const SizedBox( // Keep consistent height when empty
               height: 190,
               child: Center(child: Text("No nearby stores found.")),
             );
          }

          // --- Data loaded successfully ---
          List<DocumentSnapshot> nearbyDocs = snapshot.data!;

          // --- Build UI: Title Row (with button) + Horizontal List ---
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Rebuild the Title Row with the actual Button ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text( // Title again (could be passed or styled differently)
                      title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    // --- Map Icon Button ---
                    IconButton(
                      icon: const Icon(Icons.map_outlined, color: Colors.blueAccent, size: 28),
                      tooltip: 'View Nearby on Map',
                      onPressed: () {
                        // --- Navigate to Map Page ---
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FlutterMapNearbyPage(
                              nearbySellers: nearbyDocs,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12), // Spacing between title row and list

              // --- Horizontal ListView ---
              SizedBox(
                height: 190, // Height for the horizontal list view
                child: ListView.builder(
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
                ),
              ),
            ],
          ); // End Column returned by builder
        }, // End FutureBuilder builder
      ), // End FutureBuilder
      const SizedBox(height: 24), // Space after the section
    ], // End Outer Column children
  ); // End Outer Column
}

  Widget _buildNewStoreSection(BuildContext context, {required String title}) {
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
            future: _newSellersFuture, // Use the future for new sellers
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error finding new stores: ${snapshot.error}"));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No new stores found."));
              }

              // Data loaded successfully - Use the list of new sellers
              List<DocumentSnapshot> newDocs = snapshot.data!;

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: newDocs.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot doc = newDocs[index];
                  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                  // --- Re-use your StoreCard widget ---
                  return StoreCard(
                    name: data['Name'] ?? 'Store Name',
                    imageUrl: data['imageUrl'] ?? 'placeholder',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ItemDetailsPage(
                            sellerId: data['sellerId'] ?? 'Store Name',
                            itemId: doc.id,
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
          child: StreamBuilder<QuerySnapshot>( //here??? wo zhende bu dong
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