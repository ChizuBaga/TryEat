import 'dart:io'; 
import 'package:chikankan/Controller/item_controller.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final TextEditingController _reservedDaysController = TextEditingController();

  File? _selectedImage; // To store the selected image file
  bool _isLoading = false; // To show loading indicator

  //Dropdown options
  final List<String> _orderTypes = ['Instant', 'Pre-order'];
  final List<String> _deliveryModesInstant = ['Self-delivery', '3rd Party'];
  final List<String> _deliveryModesPreOrder = ['Meet-up', 'Self-delivery', '3rd Party', 'Self-collection'];

  String? _selectedOrderType;
  String? _selectedDeliveryMode;

  //Item Controller
  final ItemController _itemController = ItemController();

  // Function to pick an image from the gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Function to save item details to Firestore
  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: User not logged in.')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String? imageUrl;
    bool success = false;
    String errorMessage = 'Failed to add item.';

    try {
      if (_selectedImage != null) {
        imageUrl = await _itemController.uploadImage(_selectedImage!);
        if (imageUrl == null) {
          errorMessage = 'Failed to upload image. Please try again.';
          throw Exception('Image upload failed.');
        }
      }

      final int reservedDays = int.tryParse(_reservedDaysController.text.trim()) ?? 0;

      success = await _itemController.saveItemDetails(
        sellerId: currentUser.uid,
        itemName: _foodNameController.text.trim(),
        itemPrice: double.tryParse(_priceController.text.trim()) ?? 0.0,
        itemCategory: _categoryController.text.trim(),
        itemDescription: _descriptionController.text.trim(),
        orderType: _selectedOrderType!,
        deliveryMode: _selectedDeliveryMode!,
        reservedDays: reservedDays,
        imageUrl: imageUrl,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added successfully!')),
        );
        Navigator.of(context).pop();
      } else {
        errorMessage = 'Failed to save item details to database.';
        throw Exception(errorMessage);
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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

                    // --- Order Type ---
                    _buildDropdownField<String>(
                      label: 'Order Type',
                      selectedValue: _selectedOrderType,
                      items: _orderTypes,
                      onChanged: (newValue) {
                        setState(() {
                          _selectedOrderType = newValue;
                          _selectedDeliveryMode = null;
                          _reservedDaysController.clear();
                        });
                      },
                      validator: (v) => v == null ? 'Select order type' : null,
                    ),

                    // --- Reserved Days ---
                    if (_selectedOrderType == 'Pre-order')
                     ...[const Text('Reserved Days:', style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _reservedDaysController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Not more than 15 days',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter reserved days.';
                          }
                          final int? days = int.tryParse(value);
                          if (days == null || days <= 0) { 
                            return 'Please enter a valid number of days greater than 0.';
                          }
                          if (days > 15) {
                            return 'Reserved days cannot be more than 15.';
                          }
                          return null;
                        },
                      ),],
                      
                    // --- Delivery Mode ---
                    if (_selectedOrderType != null)
                      ...[const SizedBox(height: 8),
                      _buildDropdownField<String>(
                        label: 'Delivery Mode',
                        selectedValue: _selectedDeliveryMode,
                        
                        items: _selectedOrderType == 'Instant' 
                            ? _deliveryModesInstant 
                            : _deliveryModesPreOrder, 
                            
                        onChanged: (newValue) {
                          setState(() {
                            _selectedDeliveryMode = newValue;
                          });
                        },
                        validator: (v) => v == null ? 'Select delivery mode' : null,
                      ),],


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
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? selectedValue,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    String? Function(T?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label:', style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: selectedValue,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          ),
          items: items.map((T value) {
            return DropdownMenuItem<T>(
              value: value,
              child: Text(value.toString()),
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator != null ? (value) => validator(value) : null,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}