import 'dart:io'; 
import 'package:chikankan/Controller/seller_navigation_handler.dart';
import 'package:chikankan/View/sellers/bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddItem extends StatefulWidget {
  const AddItem({super.key});

  @override
  State<AddItem> createState() => _AddItemState();
}

class _AddItemState extends State<AddItem> {
  final _formKey = GlobalKey<FormState>(); // Key for form validation

  // Text editing controllers for the input fields
  final TextEditingController _foodNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();  
  final TextEditingController _categoryController = TextEditingController();

  File? _selectedImage; // To store the selected image file
  String? _imageUrl; // To store the uploaded image URL
  bool _isLoading = false; // To show loading indicator

  int _selectedIndex = 2;
  void _onNavTap(int index) {
    final handler = SellerNavigationHandler(context);
    setState(() {
      _selectedIndex = index;
    });
    handler.navigate(index);
  }

  // Function to pick an image from the gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        // Clear previous image URL if a new image is picked
        _imageUrl = null; 
      });
    }
  }

  // Function to upload image to Firebase Storage
  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('item_images')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg'); // Unique name
      
      final uploadTask = storageRef.putFile(_selectedImage!);
      final snapshot = await uploadTask.whenComplete(() => {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
      return null;
    }
  }

  // Function to save item details to Firestore
  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) {
      return; // If form is not valid, do not proceed
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Upload image
      _imageUrl = await _uploadImage();
      if (_selectedImage != null && _imageUrl == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get current seller's UID
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("No seller is currently logged in.");
      }
      final String sellerId = currentUser.uid;

      // 2. Prepare data for Firestore
      final String itemName = _foodNameController.text.trim();
      final double itemPrice = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final String itemDescription = _descriptionController.text.trim();
      final String itemCategory = _categoryController.text.trim();

      await FirebaseFirestore.instance.collection('items').add({
        'Name': itemName,
        'Price': itemPrice,
        'Category': itemCategory,
        'Description': itemDescription,
        'imageUrl': _imageUrl, 
        'isAvailable': true, // Default to available
        'sellerId': sellerId, 
        'createdAt': FieldValue.serverTimestamp(), 
      });

      // Show success message and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item added successfully!')),
      );
      Navigator.of(context).pop(); // Go back to catalogue page

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add item: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 248, 221),
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: const Text(
                        'Add Catalogue Item',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // --- Food Image Upload ---
                    const Text('Food Image:', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickImage,
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
                                _selectedImage != null
                                    ? _selectedImage!.path.split('/').last // Show filename
                                    : 'Upload image',
                                style: TextStyle(color: _selectedImage != null ? Colors.black : Colors.grey),
                              ),
                              const Icon(Icons.upload_file),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _selectedImage != null
                        ? Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Image.file(
                              _selectedImage!,
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const SizedBox.shrink(),
                    const SizedBox(height: 20),

                    // --- Food Name ---
                    const Text('Food Name:', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _foodNameController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Laksa',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
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
                        hintText: 'RM',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
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

                    // --- Category ---
                    const Text('Category:', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _categoryController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Noodles',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
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


                    // --- Description ---
                    const Text('Description:', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Not more than 50 words',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
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

                    // --- Submit Button ---
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveItem,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 255, 153, 0),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: const Text(
                          'Add Item',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: SellerBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
      ), // Reusing existing bottom nav bar
    );
  }
}