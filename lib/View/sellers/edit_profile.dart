import 'dart:io';
import 'package:chikankan/Controller/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chikankan/Model/seller_data.dart';

class EditProfile extends StatefulWidget {
  final SellerData seller; 

  const EditProfile({super.key, required this.seller});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _formKey = GlobalKey<FormState>();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool _isBusinessNameEditable = true;//default true for user to change business name
  Timestamp? modifyBNAt;
   final ProfileController _profileController = ProfileController();

  // Controllers initialized with passed data
  late TextEditingController _businessNameController;
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;

  File? _newProfileImage; 
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController(text: widget.seller.businessName ?? '');
    _usernameController = TextEditingController(text: widget.seller.username ?? '');
    _phoneController = TextEditingController(text: widget.seller.phoneNumber ?? '');
    _emailController = TextEditingController(text: widget.seller.email ?? '');
    _addressController = TextEditingController(text: widget.seller.address ?? '');
    modifyBNAt = widget.seller.lastBusinessNamemodified;
  }

  void _checkNameEditability(Timestamp? modifyBNAt) {
  if (modifyBNAt == null) {
    _isBusinessNameEditable = true;
    return;
  }

  final lastModifiedDate = modifyBNAt.toDate();
  final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));//Return true or false

  setState(() {
    // If the last modification was less than one year ago, cannot edit
    _isBusinessNameEditable = lastModifiedDate.isBefore(oneYearAgo);
  });
}

  Future<void> _pickNewProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _newProfileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (currentUser == null);
    setState(() { _isLoading = true; });
    String? finalProfileImageUrl = widget.seller.profileImageUrl;

    try {
      if (_newProfileImage != null) {
        final newUrl = await _profileController.uploadProfileImage(_newProfileImage!, currentUser!.uid);

        if (newUrl != null) {
          if (widget.seller.profileImageUrl != null && widget.seller.profileImageUrl!.isNotEmpty) {
            await _profileController.deleteOldProfileImage(widget.seller.profileImageUrl);
          }
          finalProfileImageUrl = newUrl;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Warning: Profile image upload failed. Saving text data only.')),
          );
        }
      }

      final originalBusinessName = widget.seller.businessName ?? '';
      final newBusinessName = _businessNameController.text.trim();
      bool businessNameWasChanged = (newBusinessName != originalBusinessName);

      Map<String, dynamic> updateData = {
        'businessName': newBusinessName,
        'username': _usernameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'profileImageUrl': finalProfileImageUrl, 
      };

      if (businessNameWasChanged) {
        updateData['modifyBusinessNameAt'] = FieldValue.serverTimestamp();
      }

      await _profileController.updateProfile(
        userId: currentUser!.uid,
        updateData: updateData,
      );

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
      Navigator.of(context).pop(); 
    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Firestore Error: ${e.message}')));
    }
    catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    _checkNameEditability(widget.seller.lastBusinessNamemodified);
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 248, 221),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 252, 248, 221),
        elevation: 1, 
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    SizedBox(width:30),
                    // Profile Picture with Edit Icon
                    GestureDetector(
                      onTap: _pickNewProfileImage,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey, width: 2.0),
                            ),
                            child: ClipOval(
                              child: _newProfileImage != null
                                  ? Image.file(_newProfileImage!, fit: BoxFit.cover)
                                  : (widget.seller.profileImageUrl != null
                                      ? Image.network(widget.seller.profileImageUrl!, fit: BoxFit.cover)
                                      : const Icon(Icons.person, size: 80, color: Colors.grey)),
                            ),
                          ),
                          const Positioned(
                            bottom: 0, right: 0,
                            child: CircleAvatar(
                              backgroundColor: Colors.black, radius: 15,
                              child: Icon(Icons.edit, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Business Name Field
                    TextFormField(
                      enabled: _isBusinessNameEditable,
                      controller: _businessNameController,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        labelText: 'Business Name',
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        hintText: '*You are allowed to change once per year',
                        hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                        border: UnderlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 0),
                      ),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      validator: (v) => v!.isEmpty ? 'Enter business name' : null,
                    ),
                    const SizedBox(height: 40),

                    // Username, Phone, Email, Address
                    _buildIconInputField(Icons.person, _usernameController, 'username'),
                    _buildIconInputField(Icons.phone, _phoneController, '012-345 6789', keyboardType: TextInputType.phone),
                    _buildIconInputField(Icons.email, _emailController, 'example@gmail.com', keyboardType: TextInputType.emailAddress),
                    _buildIconInputField(Icons.location_on, _addressController, 'Address', maxLines: 3),
                    const SizedBox(height: 50),

                    // Save Changes Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 255, 153, 0), 
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) : const Text('Save Changes', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
  }

  Widget _buildIconInputField(
      IconData icon, TextEditingController controller, String hintText, {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 43,child: Icon(icon, size: 28, color: Colors.black)),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              maxLines: maxLines,
              decoration: InputDecoration(
                hintText: hintText,
                contentPadding: const EdgeInsets.symmetric(vertical: 5),
              ),
              style: const TextStyle(fontSize: 18), // Underline style
              validator: (v) => v!.isEmpty ? 'Field cannot be empty' : null,
            ),
          ),
        ],
      ),
    );
  }
}