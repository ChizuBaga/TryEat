import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chikankan/Controller/new_recommendation_controller.dart'; // Import Location
import 'package:chikankan/locator.dart'; // Import locator
import 'package:chikankan/Controller/location_controller.dart'; // Import controller
import 'package:chikankan/View/customers/customer_itemlist.dart'; // Assuming this is your item list page
import 'package:chikankan/View/item_detail_page.dart'; // Import Item Details Page
import 'package:chikankan/View/customers/huawei_nearby_map.dart';
import 'package:chikankan/Controller/user_auth.dart';

class CustomerHomepage extends StatefulWidget {
  const CustomerHomepage({super.key});

  @override
  State<CustomerHomepage> createState() => _CustomerHomepageState();
}

class _CustomerHomepageState extends State<CustomerHomepage> {
  // Get the location controller instance
  final LocationController _locationController = locator<LocationController>();
  final NewRecommendationController _newRecommendationController =
      locator<NewRecommendationController>();
  final AuthService _authService = locator<AuthService>();

  late Future<List<DocumentSnapshot>> _nearbySellersFuture;
  late Future<List<DocumentSnapshot>> _newSellersFuture;


  @override 
  void initState() {
    super.initState();
    // Start fetching nearby sellers when the widget is initialized
    _nearbySellersFuture = _locationController.getNearbySellers(radiusKm: 50);
    _newSellersFuture = _newRecommendationController
        .getRecentlyCreatedSellers();
  }

  // Define the stream for other sections (New, Last Order)
  final Stream<QuerySnapshot> storesStream = FirebaseFirestore.instance
      .collection('sellers')
      .where('isVerified', isEqualTo: true)
      .snapshots();

  @override
  Widget build(BuildContext context) {
    // --- Get username ---
    final String username =
        _authService.getCurrentUser()?.displayName ?? "Customer"; // <-- ADDED

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          backgroundColor: const Color.fromRGBO(251, 192, 45, 1),
          elevation: 0,
          automaticallyImplyLeading: false,
          title: _buildSearchBar(),
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),

      // --- MODIFIED: Wrap body in FutureBuilder for nearbySellers ---
      // This gives the Welcome Card access to the list for the map button
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _nearbySellersFuture,
        builder: (context, snapshot) {
          // --- Handle Loading ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // --- Handle Error ---
          if (snapshot.hasError) {
            // Show error but still build part of the UI
            print("Error fetching nearby sellers: ${snapshot.error}");
          }

          // --- Handle Data (or error/no data) ---
          // We get the list, or an empty list if it failed/has no data
          final List<DocumentSnapshot> nearbyDocs = snapshot.data ?? [];

          return ListView(
            children: [
              // --- 1. NEW WELCOME CARD ---
              _buildWelcomeCard(context, username, nearbyDocs), // Pass data
              // --- 2. NEARBY SECTION ---
              _buildNearbyStoreSection(
                context,
                title: 'In Your Neighborhood',
                nearbyDocs: nearbyDocs, // Pass the loaded data
                isLoading: snapshot.connectionState == ConnectionState.waiting,
                hasError: snapshot.hasError,
              ),

              // --- 3. OTHER SECTIONS (Remain the same) ---
              _buildStoreSection(
                context,
                title: 'Last Order',
                stream: storesStream,
              ),
              _buildNewStoreSection(
                context,
                title: 'Freshly Added'
              ), // <-- Pass future
            ],
          );
        },
      ),
      // --- END MODIFICATION ---
    );
  }

  Widget _buildWelcomeCard(
    BuildContext context,
    String username,
    List<DocumentSnapshot> nearbyDocs,
  ) {
    // Your theme's gold color
    final Color goldColor = const Color.fromRGBO(251, 192, 45, 1);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      clipBehavior: Clip.antiAlias, // Clips the overlapping circles
      decoration: BoxDecoration(
        color: const Color.fromARGB(
          255,
          252,
          248,
          221,
        ), // Light yellow background
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // --- STACK DECORATION (Right Side) ---
          Positioned(
            right: -50,
            top: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: goldColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 20,
            top: 60,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: goldColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // --- CONTENT (Left Side) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Text: "Welcome <username>"
                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.w300,
                    ),
                    children: [
                      const TextSpan(text: 'Welcome,\n'),
                      TextSpan(
                        text: username,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Subheader
                Text(
                  'See what'
                  's cooking nearby?',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.black54),
                ),
              ],
            ),
          ),
          //MAP BUTTON!!
          Positioned(
            top: 50,
            right: 16,
            child: Card(
              
              elevation: 6.0, // This makes it look "pressable" and "obvious"
            shape: CircleBorder(), // Makes the Card itself circular
            child: CircleAvatar(
              radius: 25,
              backgroundColor: Colors.white,
              child: IconButton(
                icon: Icon(Icons.location_pin),
                color: Colors.red,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // Use the map page you have (FlutterMap or HuaweiMap)
                      builder: (context) => HuaweiMapNearbyPage(
                        nearbySellers: nearbyDocs,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          )
        ],
      ),
    );
  }

  Widget _buildNearbyStoreSection(
    BuildContext context, {
    required String title,
    required List<DocumentSnapshot> nearbyDocs, // Accept the list
    required bool isLoading,
    required bool hasError,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            // Title only
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 190,
          // --- NO FUTUREBUILDER HERE ---
          // Directly check the state passed from the parent
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : hasError
              ? const Center(child: Text("Error finding nearby stores."))
              : nearbyDocs.isEmpty
              ? const Center(child: Text("No nearby stores found."))
              : ListView.builder(
                  // Build the list from the passed data
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: nearbyDocs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot doc = nearbyDocs[index];
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
                ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
  // --- END MODIFICATION ---

  // --- 3. MODIFIED: _buildNewStoreSection ---
  // Changed to FutureBuilder to match its controller
 // This method now accesses _newSellersFuture directly from the state
Widget _buildNewStoreSection(
  BuildContext context, {
  required String title,
}) {
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
          // Use the Future defined in your State's initState
          future: _newSellersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text("Error loading stores."));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No new stores found."));
            }

            final docs = snapshot.data!;
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                DocumentSnapshot doc = docs[index];
                Map<String, dynamic> data =
                    doc.data() as Map<String, dynamic>;
                return StoreCard(
                  name: data['Name'] ?? 'Store Name',
                  imageUrl: data['imageUrl'] ?? 'placeholder',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ItemDetailsPage(
                          sellerId: data['sellerId'],
                          itemId: doc.id
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
            //here??? wo zhende bu dong
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

                  child: imageUrl == 'placeholder'
                      ? const Center(
                          child: Icon(
                            Icons.image_outlined,
                            color: Colors.black,
                            size: 48,
                          ),
                        )
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                ),
              ),
              // Text part
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  child: Center(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
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
