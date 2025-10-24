import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'customer_itemlist.dart';

class CustomerHomepage extends StatelessWidget {
  const CustomerHomepage({super.key});

  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot> storesStream = FirebaseFirestore.instance
        .collection('sellers')
        .where('isVerified', isEqualTo: true)
        .snapshots();

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
          _buildStoreSection(context, title: 'Nearby', stream: storesStream),
          _buildStoreSection(context, title: 'New', stream: storesStream),
          _buildStoreSection(
            context,
            title: 'Last Order',
            stream: storesStream,
          ),
        ],
      ),
    );
  }

  // Helper widget to build a whole section
  Widget _buildStoreSection(
    BuildContext context, {
    required String title,
    required Stream<QuerySnapshot> stream,
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
                            // pass the store's ID and Name to the next page
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

  // Search bar
  Widget _buildSearchBar() {
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

// card widget
class StoreCard extends StatelessWidget {
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
                  // image placeholder
                  child: const Center(
                    child: Icon(
                      Icons.image_outlined,
                      color: Colors.black,
                      size: 48,
                    ),
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
