import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Customer Homepage',
      theme: ThemeData(
        // Set a primary color for the overall app, matching the blue accent in the image
        primarySwatch: Colors.blue,
        // Set background color to white for the content area
        scaffoldBackgroundColor: Colors.white,
        // Use a consistent font for a clean look
        fontFamily: 'Roboto',
      ),
      home: const CustomerHomepage(),
    );
  }
}

// --- Data Models (for clean code) ---

class Category {
  final String name;
  final bool isSelected;

  Category(this.name, {this.isSelected = false});
}

class FoodItem {
  final String storeName;
  final String foodName;
  final String price;
  final String imagePath; // Placeholder for actual image path or asset

  FoodItem(this.storeName, this.foodName, this.price, this.imagePath);
}

// --- Main Homepage Widget ---

class CustomerHomepage extends StatelessWidget {
  const CustomerHomepage({super.key});

  // Sample data for the categories
  final List<Category> _categories = const [
    Category('Category1', isSelected: true),
    Category('Category2'),
    Category('Category3'),
    Category('Category4'),
    Category('Category5'),
  ];

  // Sample data for the product grid
  final List<FoodItem> _foodItems = const [
    FoodItem('Store Name', 'Food name', 'RM0.00', 'assets/image1.jpg'),
    FoodItem('Store Name', 'Food name', 'RM0.00', 'assets/image2.jpg'),
    FoodItem('Store Name', 'Food name', 'RM0.00', 'assets/image3.jpg'),
    FoodItem('Store Name', 'Food name', 'RM0.00', 'assets/image4.jpg'),
    // Add more items here...
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // The image title "Customer Homepage" appears outside the Scaffold's AppBar area
        // but we'll use the AppBar for a clean layout and a title.
        title: const Text(
          'Customer Homepage',
          style: TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0, // Remove the shadow/line under the AppBar
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: SearchBarWidget(), // Custom Search Bar
            ),
            
            // --- Categories Section ---
            CategoriesBar(categories: _categories),

            const SizedBox(height: 16.0),

            // --- Carousel/Banner Section ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: ImageCarousel(),
            ),

            const SizedBox(height: 24.0),

            // --- Product Grid Title ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Title',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 10.0),

            // --- Product Grid Section ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ProductGrid(foodItems: _foodItems),
            ),
          ],
        ),
      ),
      // --- Bottom Navigation Bar ---
      bottomNavigationBar: const CustomBottomNavBar(),
    );
  }
}

// ------------------------------------------------------------------
// --- WIDGETS ---
// ------------------------------------------------------------------

/// 1. Search Bar Widget
class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: const TextField(
        decoration: InputDecoration(
          hintText: 'Search',
          hintStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          prefixIconConstraints: BoxConstraints(minWidth: 40),
        ),
      ),
    );
  }
}

/// 2. Categories Horizontal Scroll Bar
class CategoriesBar extends StatelessWidget {
  final List<Category> categories;
  const CategoriesBar({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: TextButton(
              onPressed: () {
                // Add category selection logic here
              },
              style: TextButton.styleFrom(
                foregroundColor: category.isSelected ? Colors.white : Colors.black87,
                backgroundColor: category.isSelected ? Colors.blue : Colors.grey[200],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
              ),
              child: Text(category.name),
            ),
          );
        },
      ),
    );
  }
}

/// 3. Featured Image Carousel
class ImageCarousel extends StatelessWidget {
  const ImageCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey[200], // Background color for placeholder
        borderRadius: BorderRadius.circular(12.0),
        // A placeholder for the actual image. In a real app, you'd use a PageView.builder
        // with an actual image (e.g., Image.network or Image.asset)
        image: const DecorationImage(
          image: AssetImage('assets/carousel_image.png'), // Replace with your asset
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // Text overlay on the image
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'New/Hot Selling\nFood?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          // Placeholder for the dots indicator
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5, // Number of carousel items
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3.0),
                    width: index == 0 ? 16.0 : 8.0, // Make the selected dot wider
                    height: 8.0,
                    decoration: BoxDecoration(
                      color: index == 0 ? Colors.black : Colors.grey,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 4. Product Grid
class ProductGrid extends StatelessWidget {
  final List<FoodItem> foodItems;
  const ProductGrid({super.key, required this.foodItems});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true, // Important to make it work inside a SingleChildScrollView
      physics: const NeverScrollableScrollPhysics(), // Disable internal scrolling
      itemCount: foodItems.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Two columns
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 0.75, // Adjust this ratio to control item height
      ),
      itemBuilder: (context, index) {
        return FoodItemCard(item: foodItems[index], index: index);
      },
    );
  }
}

/// 4a. Single Product Item Card
class FoodItemCard extends StatelessWidget {
  final FoodItem item;
  final int index;
  const FoodItemCard({super.key, required this.item, required this.index});

  // Helper to simulate the different background patterns from the image
  String getPlaceholderAsset() {
    switch (index % 4) {
      case 0:
        return 'assets/item_radish.png'; // Reddish/Green pattern
      case 1:
        return 'assets/item_mushrooms.png'; // Mushroom pattern
      case 2:
        return 'assets/item_cherries.png'; // Cherry pattern
      case 3:
        return 'assets/item_cherries.png'; // Cherry pattern (repeated for a 4th item)
      default:
        return 'assets/item_default.png'; 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Container(
              width: double.infinity,
              // For a real app, replace the placeholder with an Image.asset or Image.network
              decoration: BoxDecoration(
                color: Colors.grey[100], // Light background for the image area
                image: DecorationImage(
                  // Use a real asset here to mimic the design
                  image: AssetImage(getPlaceholderAsset()), 
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.storeName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.foodName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.price,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


/// 5. Custom Bottom Navigation Bar
class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed, // Important for more than 3 items
      backgroundColor: Colors.white,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home_filled), // Home icon is solid
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline), // Chat icon
          label: 'Chat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart_outlined), // Cart icon
          label: 'Cart',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu_book_outlined), // Book/Menu icon
          label: 'Orders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline), // Profile icon
          label: 'Profile',
        ),
      ],
      // currentIndex: 0, // Set the currently selected index
      onTap: (index) {
        // Handle navigation taps
      },
    );
  }
}