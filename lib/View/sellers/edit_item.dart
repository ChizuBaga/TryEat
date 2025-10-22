// File: edit_item_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For currency formatting

// Assuming your Item model is defined in item_model.dart or similar
import 'package:chikankan/Model/item_model.dart'; 
// You might need to adjust this path

class EditItem extends StatefulWidget {
  final Item item; // The item object passed from the previous page

  const EditItem({super.key, required this.item});

  @override
  State<EditItem> createState() => _EditItemState();
}

class _EditItemState extends State<EditItem> {
  final _formKey = GlobalKey<FormState>();

  // Text editing controllers
  late TextEditingController _foodNameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;

  File? _newSelectedImage; // To store a newly picked image file
  String? _currentImageUrl; // The URL of the currently displayed image
  bool _isLoading = false; // For showing loading indicators

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current item data
    _foodNameController = TextEditingController(text: widget.item.name);
    _priceController = TextEditingController(text: widget.item.price.toStringAsFixed(2));
    _descriptionController = TextEditingController(text: widget.item.description);
    _currentImageUrl = widget.item.imageUrl;
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // --- Image Handling ---
  Future<void> _pickNewImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _newSelectedImage = File(pickedFile.path);
        // We don't update _currentImageUrl yet, as it's not uploaded
      });
    }
  }

  Future<String?> _uploadNewImage() async {
    if (_newSelectedImage == null) return null; // No new image to upload

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('item_images')
          .child('${DateTime.now().millisecondsSinceEpoch}_${_newSelectedImage!.path.split('/').last}');
      
      final uploadTask = storageRef.putFile(_newSelectedImage!);
      final snapshot = await uploadTask.whenComplete(() => {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading new image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload new image: $e')),
      );
      return null;
    }
  }

  Future<void> _deleteOldImage(String? oldImageUrl) async {
    if (oldImageUrl == null || oldImageUrl.isEmpty) return;
    if (!oldImageUrl.contains('firebasestorage.googleapis.com')) return; // Not a Firebase Storage URL

    try {
      final ref = FirebaseStorage.instance.refFromURL(oldImageUrl);
      await ref.delete();
    } catch (e) {
      print('Error deleting old image from Storage: $e');
    }
  }

  // --- CRUD Operations ---
  Future<void> _updateItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? finalImageUrl = _currentImageUrl; // Start with existing URL

      if (_newSelectedImage != null) {
        // If a new image was selected, upload it
        final newUploadedUrl = await _uploadNewImage();
        if (newUploadedUrl != null) {
          // If upload successful, delete the old image (if it exists)
          await _deleteOldImage(widget.item.imageUrl);
          finalImageUrl = newUploadedUrl; // Update to new URL
        } else {
          // If new image upload failed, stop and inform user
          setState(() { _isLoading = false; });
          return;
        }
      }

      await FirebaseFirestore.instance.collection('items').doc(widget.item.id).update({
        'name': _foodNameController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'description': _descriptionController.text.trim(),
        'imageUrl': finalImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item updated successfully!')),
      );
      Navigator.of(context).pop(); // Go back to catalogue
    } catch (e) {
      print('Error updating item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update item: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteItem() async {
    // Confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${widget.item.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });
      try {
        // Delete image from Storage first
        await _deleteOldImage(widget.item.imageUrl);
        
        // Delete document from Firestore
        await FirebaseFirestore.instance.collection('items').doc(widget.item.id).delete();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted successfully!')),
        );
        Navigator.of(context).pop(); // Pop this page
        // You might need to pop again if you want to go past the catalogue to home
        // Navigator.of(context).pop(); 
      } catch (e) {
        print('Error deleting item: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete item: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 248, 221),
      appBar: AppBar(
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _deleteItem, // Disable when loading
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: _isLoading && _formKey.currentState?.validate() == false 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Delete', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
            child: Column(
              children: [
                Text('Edit Catalogue Item', style: TextStyle(fontSize: 24, color: Colors.black)),
                Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const SizedBox(height: 10), // Space from app bar
                
                          // --- Food Image Display & Upload ---
                          const Text('Food Image:', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: _newSelectedImage != null
                                  ? Image.file(_newSelectedImage!, fit: BoxFit.cover)
                                  : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty
                                      ? Image.network(_currentImageUrl!, fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)))
                                      : const Center(child: Icon(Icons.image, size: 50, color: Colors.grey))),
                            ),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: _pickNewImage,
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _newSelectedImage != null
                                          ? _newSelectedImage!.path.split('/').last // New filename
                                          : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty
                                              ? _currentImageUrl!.split('/').last.split('?').first // Existing filename
                                              : 'Upload image'),
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                    const Icon(Icons.upload_file),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                
                          // --- Food Name ---
                          const Text('Food Name:', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _foodNameController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter food name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                
                          // --- Price ---
                          const Text('Price:', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              prefixText: 'RM ', // Display RM prefix
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter price';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                
                          // --- Description ---
                          const Text('Description:', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText: 'Not more than 50 words',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                              contentPadding: const EdgeInsets.all(12.0),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a description';
                              }
                              if (value.split(' ').length > 50) {
                                return 'Description cannot exceed 50 words';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),
                
                          // --- Save Changes Button ---
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _updateItem, // Disable when loading
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 255, 153, 0),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                  : const Text(
                                      'Save Changes',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
      // --- Reusable Bottom Navigation Bar ---
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  // --- Reusable Bottom Navigation Bar (can be refactored to a common widget) ---
  // You would typically import and use your SellerBottomNavBar widget here
  // For now, I'll include a minimal version to avoid errors if you haven't moved it.
  Widget _buildBottomNavBar(BuildContext context) {
    // These streams are for demonstration if SellerBottomNavBar is not used.
    final Stream<int> _unreadMessagesStream = const Stream.empty();
    final Stream<int> _newOrdersStream = const Stream.empty();

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      currentIndex: 2, // Highlight Catalogue/Orders as we are on an item-related page
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
        _buildBottomNavItemWithIndicator(
          icon: Icons.chat_bubble_outline,
          label: 'Chat',
          stream: _unreadMessagesStream,
        ),
        _buildBottomNavItemWithIndicator(
          icon: Icons.shopping_cart_outlined,
          label: 'Orders',
          stream: _newOrdersStream,
        ),
        const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
      onTap: (index) {
        // Handle navigation taps (e.g., Navigator.push to respective pages)
        print('Tapped index: $index');
      },
    );
  }

  BottomNavigationBarItem _buildBottomNavItemWithIndicator({
    required IconData icon,
    required String label,
    required Stream<int> stream,
    int initialCount = 0,
  }) {
    return BottomNavigationBarItem(
      label: label,
      icon: StreamBuilder<int>(
        stream: stream,
        initialData: initialCount,
        builder: (context, snapshot) {
          final unseenCount = snapshot.data ?? 0;
          return Stack(
            children: [
              Icon(icon),
              if (unseenCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}