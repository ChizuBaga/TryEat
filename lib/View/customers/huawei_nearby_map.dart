import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:huawei_map/huawei_map.dart' hide Location;
import 'package:huawei_location/huawei_location.dart';
import 'package:chikankan/locator.dart';
import 'package:chikankan/Controller/location_controller.dart';
import 'package:chikankan/View/customers/customer_itemlist.dart';

// --- MODIFIED: Renamed widget ---
class HuaweiMapNearbyPage extends StatefulWidget {
  final List<DocumentSnapshot> nearbySellers;

  const HuaweiMapNearbyPage({super.key, required this.nearbySellers});

  @override
  State<HuaweiMapNearbyPage> createState() => _HuaweiMapNearbyPageState();
}

class _HuaweiMapNearbyPageState extends State<HuaweiMapNearbyPage> {
  final LocationController _locationController = locator<LocationController>();

  // --- MODIFIED: Use Set<Marker> (Huawei Map's type) ---
  Set<Marker> _markers = {};
  // --- MODIFIED: Use LatLng from Huawei Map Kit ---
  LatLng? _initialCenter;
  bool _isLoading = true;

  // --- NEW: Controller for the map ---
  HuaweiMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _initializeMapData();
  }

  Future<void> _initializeMapData() async {
    // --- MODIFIED: Use LatLng from Huawei Map Kit ---
    LatLng? userLatLng;
    try {
      // 1. Fetch user's current location (same logic)
      Location userLocation = await _locationController.getLocation();
      if (userLocation.latitude != null && userLocation.longitude != null) {
        // Use Huawei's LatLng constructor
        userLatLng = LatLng(userLocation.latitude!, userLocation.longitude!);
        print("User location fetched: $userLatLng");
      } else {
        print("Failed to get user location, using default.");
      }
    } catch (e) {
      print("Error getting user location: $e. Using default.");
    }

    // 2. Create markers
    // --- MODIFIED: Use Set<Marker> ---
    Set<Marker> tempMarkers = {};
    LatLng? firstSellerPosition; // To help center map if user location fails

    for (var doc in widget.nearbySellers) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      // --- CHECK THIS FIELD NAME ---
      final GeoPoint? geoPoint =
          data['location'] as GeoPoint?; // Ensure 'coordinates' is correct
      final String sellerName = data['businessName'] ?? 'Unknown Seller';
      final String sellerId = doc.id;

      if (geoPoint != null) {
        // --- MODIFIED: Use Huawei's LatLng ---
        LatLng sellerPosition = LatLng(geoPoint.latitude, geoPoint.longitude);
        firstSellerPosition ??=
            sellerPosition; // Note the first seller's position

        Marker marker = Marker(
          // Use the seller ID as the unique markerId
          markerId: MarkerId(sellerId),
          position: sellerPosition,
          clickable: true,
          onClick: () {
              _showSellerDetailsSheet(context, doc);
            },
          infoWindow: InfoWindow(
            title: sellerName,
            onClick: () {
              _showSellerDetailsSheet(context, doc);
            },
          ),

        );
        // --- END MODIFIED MARKER ---
        tempMarkers.add(marker);
      }
    }

    setState(() {
      _markers = tempMarkers;
      // Set initial center to user's location, or first seller, or default
      _initialCenter =
          userLatLng ??
          firstSellerPosition ??
          const LatLng(1.557, 110.34); // Default to Kuching
      _isLoading = false; // Mark loading as complete
    });
  }

  void _showSellerDetailsSheet(
    BuildContext context,
    DocumentSnapshot sellerDoc,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bc) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.75,
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 255, 254, 246),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                ),
              ),
              child: _SellerDetailsContent(
                sellerDoc: sellerDoc,
                scrollController: scrollController,
              ),
            );
          },
        );
      },
    );
  }
  // --- END NO CHANGE ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Stores Map'),
        backgroundColor: const Color.fromARGB(255, 255, 229, 143),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            )
          // --- MODIFIED: Use HuaweiMap ---
          : HuaweiMap(
              // --- Set initial camera position ---
              initialCameraPosition: CameraPosition(
                target: _initialCenter!, // Use fetched user/seller location
                zoom: 14.0,
              ),
              // --- Add markers to the map ---
              markers: _markers,

              // --- Other map settings ---
              mapType: MapType.normal,
              myLocationEnabled: true, // Show user's blue dot
              myLocationButtonEnabled: true, // Button to center on user
              // --- Get the map controller ---
              onMapCreated: (HuaweiMapController controller) {
                _mapController = controller;
              },
            ),
      // --- END MODIFICATION ---
    );
  }
}

// --- NO CHANGE: This widget is map-agnostic ---
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

    final String sellerPhone =
        data['phone_number'] ??
        'Phone not available'; // Adjust field name if needed

    final String sellerId = sellerDoc.id;

    return ListView(
      // Use ListView for scrollability within the sheet
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

          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),

          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        // Address
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Icon(Icons.location_on_outlined, color: Colors.grey[700], size: 20),

            const SizedBox(width: 8),

            Expanded(
              child: Text(sellerAddress, style: const TextStyle(fontSize: 15)),
            ),
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
        ElevatedButton.icon(
          icon: const Icon(Icons.storefront_outlined),

          label: const Text('View Items'),

          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(
              255,
              255,
              153,
              0,
            ), // Your button color

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
      ],
    );
  }
}
// --- END NO CHANGE ---