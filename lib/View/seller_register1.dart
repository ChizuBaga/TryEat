import 'package:chikankan/Model/seller_data.dart';
import 'package:chikankan/View/customer_login_page.dart';
import 'package:flutter/material.dart';
import 'package:chikankan/View/seller_register2.dart'; // the next page

class SellerRegisterPage1 extends StatefulWidget {
  const SellerRegisterPage1({super.key});

  @override
  State<SellerRegisterPage1> createState() => _SellerRegisterPage1State();
}

class _SellerRegisterPage1State extends State<SellerRegisterPage1> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for the input fields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final SellerData _sellerData = SellerData();

  void _navigateToNextStep() {
    if (_formKey.currentState!.validate()) {
      _sellerData.username = _usernameController.text;
      _sellerData.phoneNumber = _phoneController.text;
      _sellerData.email = _emailController.text;
      _sellerData.password = _passwordController.text;
      // Form is valid, proceed to the next page
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SellerRegisterPage2(data: _sellerData),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // --- Logo Placeholder ---
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: const Center(
                  child: Text(
                    'logo?',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- Title ---
              const Text(
                'Seller Register',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),

              // --- Step Info ---
              const Text(
                'Page 1 of 3: Personal Info',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 40),

              // --- Form Fields ---
              _buildInputField(
                controller: _usernameController,
                label: 'Username:',
                hint: 'username',
                validator: (value) => (value == null || value.isEmpty) ? 'Please enter a username.' : null,
              ),
              const SizedBox(height: 24),

              _buildInputField(
                controller: _phoneController,
                label: 'Phone Number:',
                hint: 'e.g. 0123456789',
                keyboardType: TextInputType.phone,
                validator: (value) => (value == null || value.length < 8) ? 'Enter a valid phone number.' : null,
              ),
              const SizedBox(height: 24),

              _buildInputField(
                controller: _emailController,
                label: 'Email:',
                hint: 'e.g. example@gmail.com',
                keyboardType: TextInputType.emailAddress,
                validator: (value) => (value == null || !value.contains('@')) ? 'Enter a valid email address.' : null,
              ),
              const SizedBox(height: 24),

              _buildInputField(
                controller: _passwordController,
                label: 'Password:',
                hint: '8 characters (include number, symbol)',
                obscureText: true,
                validator: (value) {
                  if (value == null || value.length < 8) {
                    return 'Password must be at least 8 characters.';
                  }
                  // Add regex???
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // --- Navigation and Login Link ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // --- Next Button ---
                    ElevatedButton(
                      onPressed: _navigateToNextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Text('Next', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // --- Login Link ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text("Already haven an account? "),
                  GestureDetector(
                    onTap: () {
                      // Navigate to the Seller Login Page
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CustomerLoginPage()));//Change
                    },
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          ),
          validator: validator,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}