import 'package:chikankan/Controller/profile_controller.dart';
import 'package:chikankan/Controller/seller_navigation_controller.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chikankan/Model/seller_data.dart';
import 'package:chikankan/View/sellers/edit_profile.dart'; 
import 'package:chikankan/View/sellers/bottom_navigation_bar.dart'; 

class SellerProfile extends StatefulWidget {
  const SellerProfile({super.key});

  @override
  State<SellerProfile> createState() => _SellerProfileState();
}

class _SellerProfileState extends State<SellerProfile> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  int _selectedIndex = 3; // Profile tab index
  final ProfileController _profileController = ProfileController();

  void _onNavTap(int index) {
    final handler = SellerNavigationHandler(context);
    setState(() {
      _selectedIndex = index;
    });
    handler.navigate(index);
  }
  
  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Please log in.')));
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 248, 221),
      appBar: AppBar(backgroundColor: Color.fromARGB(255, 252, 248, 221), elevation: 0, toolbarHeight: 0),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _profileController.streamSellerProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Error loading profile: ${snapshot.error ?? "Not found"}'));
          }

          final SellerData seller = SellerData.fromFirestore(snapshot.data!);

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // 1. Edit Button
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => EditProfile(seller: seller),
                                  ),
                                );
                              },
                              child: const Icon(Icons.edit_square, size: 28),
                            ),
                          ],
                        ),
                      ),
                      
                      // 2. Profile Picture
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey, width: 2.0),
                        ),
                        child: ClipOval(
                          child: (seller.profileImageUrl != null && seller.profileImageUrl!.isNotEmpty)
                              ? Image.network(
                                  seller.profileImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 100, color: Colors.grey),
                                )
                              : const Icon(Icons.person, size: 100, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // 3. Business Name
                      Text(
                        seller.businessName ?? 'N/A',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),

                      // 5. Profile Details
                      _buildProfileDetailRow(Icons.person, seller.username ?? 'username'),
                      _buildProfileDetailRow(Icons.phone, seller.phoneNumber ?? 'N/A'),
                      _buildProfileDetailRow(Icons.email, seller.email ?? 'N/A'),
                      _buildProfileDetailRow(Icons.location_on, '${seller.address ?? 'N/A'}, ${seller.state ?? ''}'),
                      
                      // Join Date
                      _buildProfileDetailRow(
                        Icons.add_circle_outline,
                        'Since ${seller.joinDate != null ? DateFormat('yyyy MMMM').format(seller.joinDate!) : 'N/A'}',
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              // Bottom Navigation Bar
              SellerBottomNavBar(
                currentIndex: _selectedIndex,
                onTap: _onNavTap,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileDetailRow(IconData icon, String text) {
    // ... (This helper remains the same) ...
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 43, child: Icon(icon, size: 28, color: Colors.black)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                text,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}