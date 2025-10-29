// lib/View/customers/flutter_map_nearby_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart'; // Import flutter_map
import 'package:latlong2/latlong.dart'; // Import latlong2
import 'package:huawei_location/huawei_location.dart'; // <-- NEW: Import Location type
import 'package:chikankan/locator.dart'; // <-- NEW: Import locator
import 'package:chikankan/Controller/location_controller.dart';
import 'package:chikankan/Model/seller_data.dart';
import 'package:chikankan/View/customers/customer_itemlist.dart';

class FlutterMapNearbyPage extends StatefulWidget {
  final List<DocumentSnapshot> nearbySellers;

  const FlutterMapNearbyPage({
    super.key,
    required this.nearbySellers,
  });

  @override
  State<FlutterMapNearbyPage> createState() => _FlutterMapNearbyPageState();
}

class _FlutterMapNearbyPageState extends State<FlutterMapNearbyPage> {

  final LocationController _locationController = locator<LocationController>();
  List<Marker> _markers = [];
  LatLng? _initialCenter; // To center the map
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeMapData();
  }

  Future<void> _initializeMapData() async {
    LatLng? userLatLng;
    try {
      // 1. Fetch user's current location
      Location userLocation = await _locationController.getLocation();
      if (userLocation.latitude != null && userLocation.longitude != null) {
        userLatLng = LatLng(userLocation.latitude!, userLocation.longitude!);
        print("User location fetched: $userLatLng");
      } else {
        print("Failed to get user location, using default.");
      }
    } catch (e) {
      print("Error getting user location: $e. Using default.");
      // Handle error (e.g., show SnackBar) or just use default
    }

    // 2. Create markers (existing logic)
    Set<Marker> tempMarkers = {}; // Use Set temporarily to avoid duplicates if needed
    for (var doc in widget.nearbySellers) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final GeoPoint? geoPoint = data['location'] as GeoPoint?;
      final String sellerName = data['businessName'] ?? 'Unknown Seller';
      final String sellerId = doc.id;

      if (geoPoint != null) {
        LatLng sellerPosition = LatLng(geoPoint.latitude, geoPoint.longitude);
        Marker marker = Marker(
          width: 80.0,
          height: 80.0,
          point: sellerPosition,
          child: GestureDetector(
            onTap: () {
              _showSellerDetailsSheet(context, doc);
              
            },
            child: Tooltip(
              message: sellerName,
              child: Icon(Icons.location_pin, color: Colors.red.shade700, size: 40.0),
            ),
          ),
        );
        tempMarkers.add(marker);
      }
    }

    // 3. Update state with fetched location and markers
    setState(() {
      _markers = tempMarkers.toList();
      // Set initial center to user's location, or default if fetch failed
      _initialCenter = userLatLng ?? const LatLng(1.557, 110.34); // Default to Kuching
      _isLoading = false; // Mark loading as complete
    });
  }

  void _showSellerDetailsSheet(BuildContext context, DocumentSnapshot sellerDoc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // IMPORTANT: Allows sheet to be taller than 50%
      backgroundColor: Colors.transparent, // Make background transparent
      builder: (BuildContext bc) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5, // Start at 50% height
          minChildSize: 0.3, // Minimum height when partially dragged down
          maxChildSize: 0.75, // Max height (75%)
          expand: false, // Prevent it from taking full screen height initially
          builder: (BuildContext context, ScrollController scrollController) {
            // Use a container with rounded top corners
            return Container(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 255, 254, 246), // Your background color
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                ),
              ),
              child: _SellerDetailsContent( // Pass data to the content widget
                sellerDoc: sellerDoc,
                scrollController: scrollController, // Pass controller for scrolling
              ),
            );
          },
        );
      },
    );
  }

  // --- END NEW FUNCTION ---
@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Stores Map'),
        backgroundColor: const Color.fromARGB(255, 255, 229, 143),
      ),
      // --- MODIFIED: Use _isLoading flag ---
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange), // Example color
            )) // Show loading while fetching location/processing markers
          : FlutterMap(
              options: MapOptions(
                initialCenter: _initialCenter!, // Use fetched user location
                initialZoom: 14.0, // Zoom in a bit closer by default
                 interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.chikankan', // Use your package name
                ),
                MarkerLayer(markers: _markers), // Display markers
              ],
            ),
      // --- END MODIFICATION ---
    );
  }
}

// --- NEW: Widget to display content inside the bottom sheet ---
class _SellerDetailsContent extends StatelessWidget {
  final DocumentSnapshot sellerDoc;
  final ScrollController scrollController;

  const _SellerDetailsContent({
    required this.sellerDoc,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final data = sellerDoc.data() as Map<String, dynamic>? ?? {};
    final String sellerName = data['businessName'] ?? 'Store Details';
    final String sellerAddress = data['address'] ?? 'Address not available';
    final String sellerPhone = data['phone_number'] ?? 'Phone not available'; // Adjust field name if needed
    final String sellerId = sellerDoc.id;

    return ListView( // Use ListView for scrollability within the sheet
      controller: scrollController, // Attach the controller
      padding: const EdgeInsets.all(20.0),
      children: [
        // Optional: Drag handle indicator
        Center(
          child: Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        // Seller Name
        Text(
          sellerName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        // Address
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.location_on_outlined, color: Colors.grey[700], size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(sellerAddress, style: const TextStyle(fontSize: 15))),
          ],
        ),
        const SizedBox(height: 12),
        // Phone
        Row(
          children: [
            Icon(Icons.phone_outlined, color: Colors.grey[700], size: 20),
            const SizedBox(width: 8),
            Text(sellerPhone, style: const TextStyle(fontSize: 15)),
          ],
        ),
        const SizedBox(height: 24),
        // "View Items" Button
        ElevatedButton.icon(
          icon: const Icon(Icons.storefront_outlined),
          label: const Text('View Items'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 255, 153, 0), // Your button color
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 45), // Make button wide
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          onPressed: () {
            // Close the bottom sheet BEFORE navigating
            Navigator.pop(context);
            // Navigate to the item list page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CustomerItemListPage(
                  sellerId: sellerId,
                  storeName: sellerName,
                ),
              ),
            );
          },
        ),
        // Add more details here if needed
      ],
    );
  }
}
// --- END NEW WIDGET ---