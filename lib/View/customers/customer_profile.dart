import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'customer_edit_profile.dart';
import 'package:chikankan/View/select_user_type_page.dart';

class CustomerProfile extends StatelessWidget {
  const CustomerProfile({super.key});

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color.fromARGB(255, 255, 254, 246);
    const Color iconColor = Color.fromARGB(255, 50, 50, 50);
    const Color textColor = Color.fromARGB(255, 50, 50, 50);

    final User? currentUser = FirebaseAuth.instance.currentUser;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    // Handle user not logged in
    /*
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
            title: const Text('Profile'),
            backgroundColor: backgroundColor,
            elevation: 0),
        body: const Center(
          child: Text(
            'Please log in to see your profile.',
            style: TextStyle(fontSize: 18, color: textColor),
          ),
        ),
      );
    }
    */

    // Use a StreamBuilder to get the user's data in real-time
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('customers')
          .doc(currentUser!.uid) // We assume currentUser is not null here
          .snapshots(),
      builder: (context, snapshot) {
        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: backgroundColor,
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        // Handle error state
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: backgroundColor,
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        // --- Data has been successfully loaded ---
        final data = snapshot.data!.data() as Map<String, dynamic>;
        // Provide sensible defaults if fields are missing
        final String username = data['username'] ?? 'No Username';
        final String email = data['email'] ?? 'No Email';
        final String phone = data['phone_number'] ?? 'No Phone Number';
        // Get the profile image URL, default to null if not present
        final String? profileImageUrl = data['profileImageUrl'];

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            title: const Text(
              'Profile',
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
            ),
            backgroundColor: backgroundColor, 
            elevation: 0, 
            automaticallyImplyLeading: false,
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  // --- Profile picture avatar (Keep As Is) ---
                  CircleAvatar(
                    radius: 64,
                    backgroundColor: Colors.black,
                    backgroundImage: profileImageUrl != null
                        ? NetworkImage(profileImageUrl)
                        : null,
                    child: (profileImageUrl == null)
                        ? Icon(Icons.person_outline, size: 80, color: iconColor)
                        : null,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    username,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 60),

                  Column(
                    mainAxisSize: MainAxisSize.min, // Shrink-wrap the column
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // Left-align children
                    children: [
                      _InfoRow(
                        icon: Icons.phone_outlined,
                        text: phone,
                        iconColor: iconColor,
                        textColor: textColor,
                      ),
                      const SizedBox(height: 24), // Adjusted space
                      _InfoRow(
                        icon: Icons.email_outlined,
                        text: email,
                        iconColor: iconColor,
                        textColor: textColor,
                      ),
                    ],
                  ),

                  const SizedBox(height: 60),

                  // --- First Card with Fixed Size ---
                  SizedBox(
                    width: screenWidth * 1.0,
                    height:
                        screenHeight * 0.07,
                    child: Card(
                      color: Color.fromARGB(255, 255, 153, 0),
                      margin: EdgeInsets.zero,
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditCustomerProfile(currentData: data),
                            ),
                          );
                        },
                        child: SizedBox.expand(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.edit_outlined, color: Colors.black),
                              Text(
                                'Edit Profile',
                                style: TextStyle(color: Colors.black, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  // --- Second Card with Fixed Size ---
                   SizedBox(
                    width: screenWidth * 1.0,
                    height:
                        screenHeight * 0.07,
                    child: Card(
                      margin: EdgeInsets.zero,
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SelectUserTypePage(),
                            ),
                          );
                        },
                        child: SizedBox.expand(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.switch_account, color: iconColor),
                              Text(
                                'Log Out',
                                style: TextStyle(color: textColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ), // Example extra space at the botto
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A reusable widget for displaying an icon and text in a row.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
    required this.iconColor,
    required this.textColor,
  });

  final IconData icon;
  final String text;
  final Color iconColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 50),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 18,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis, 
            ),
          ),
        ],
      ),
    );
  }
}
