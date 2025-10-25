import 'dart:io'; // Required for File
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Required for Storage
import 'package:image_picker/image_picker.dart'; // Required for Image Picker

class EditCustomerProfile extends StatefulWidget {
  // We accept the current data to pre-fill the text fields
  final Map<String, dynamic> currentData;
  const EditCustomerProfile({super.key, required this.currentData});

  @override
  State<EditCustomerProfile> createState() => _EditCustomerProfileState();
}

class _EditCustomerProfileState extends State<EditCustomerProfile> {
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  // Email is often used as an auth identifier, so we might not allow editing it.
  // For this example, I'll make it editable, but you can change to just display it.
  late TextEditingController _emailController;

  String? _existingImageUrl;
  File? _newImageFile; // Holds the new image picked by the user
  bool _isLoading = false;

  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    // Pre-fill controllers with existing data
    _usernameController =
        TextEditingController(text: widget.currentData['username']);
    _phoneController =
        TextEditingController(text: widget.currentData['phone_number']);
    _emailController =
        TextEditingController(text: widget.currentData['email']);
    _existingImageUrl = widget.currentData['profileImageUrl'];
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Function to pick an image from the gallery
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    // Pick an image
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _newImageFile = File(image.path); // Store the file
      });
    }
  }

  // Function to upload image and save all changes
  Future<void> _saveChanges() async {
    if (currentUser == null) return;
    setState(() {
      _isLoading = true;
    });

    try {
      String? newImageUrl;

      // 1. Upload new image if one was selected
      if (_newImageFile != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('customer_profile_images')
            .child('${currentUser!.uid}.jpg');

        UploadTask uploadTask = storageRef.putFile(_newImageFile!);
        TaskSnapshot snapshot = await uploadTask;
        newImageUrl = await snapshot.ref.getDownloadURL();
      }

      // 2. Prepare data to update in Firestore
      final Map<String, dynamic> dataToUpdate = {
        'username': _usernameController.text,
        'phone_number': _phoneController.text,
        'email': _emailController.text,
        // Only update image URL if a new one was uploaded
        if (newImageUrl != null) 'profileImageUrl': newImageUrl,
      };

      // 3. Update Firestore document
      await FirebaseFirestore.instance
          .collection('customers')
          .doc(currentUser!.uid)
          .update(dataToUpdate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Go back to the profile page
        Navigator.pop(context);
      }
    } catch (e) {
      print("Error saving profile: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color.fromARGB(255, 252, 248, 221);
    const Color textColor = Color.fromARGB(255, 50, 50, 50);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Edit Profile',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: textColor), // Back button color
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Avatar with edit button
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 64,
                  backgroundColor: Colors.black.withOpacity(0.05),
                  // Show new image if picked, else existing, else default icon
                  backgroundImage: _newImageFile != null
                      ? FileImage(_newImageFile!)
                      : (_existingImageUrl != null
                          ? NetworkImage(_existingImageUrl!)
                          : null) as ImageProvider?,
                  child: (_newImageFile == null && _existingImageUrl == null)
                      ? Icon(Icons.person_outline,
                          size: 80, color: textColor.withOpacity(0.7))
                      : null,
                ),
                // Edit button on avatar
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                    child: const Icon(Icons.edit, color: Colors.black, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            // TextFields for editing
            _buildTextField(_usernameController, 'Username', textColor),
            const SizedBox(height: 20),
            _buildTextField(_phoneController, 'Phone Number', textColor),
            const SizedBox(height: 20),
            _buildTextField(_emailController, 'Email', textColor),
            const SizedBox(height: 60),

            // Save Changes Button
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _saveChanges,
                child: const Text(
                  'Save Changes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build styled TextFields
  Widget _buildTextField(
      TextEditingController controller, String label, Color textColor) {
    return TextField(
      controller: controller,
      style: TextStyle(color: textColor, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: textColor.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.black, width: 2.0),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
