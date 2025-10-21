import 'package:chikankan/Model/sellerData.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chikankan/Controller/user_auth.dart'; 
import 'package:flutter/material.dart';
import 'package:chikankan/View/seller_verification.dart'; // the next page

class SellerRegisterPage3 extends StatefulWidget {
  final SellerData data;
  const SellerRegisterPage3({super.key, required this.data});

  @override
  State<SellerRegisterPage3> createState() => _SellerRegisterPage3State();
}

class _SellerRegisterPage3State extends State<SellerRegisterPage3> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  SellerData _sellerData = SellerData();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _postcodeController = TextEditingController();
  
  String? _selectedState;
  final List<String> _states = ['Sabah','Sarawak','Selangor', 'Negeri Sembilan', 'Kedah', 'Kelantan','Terengganu','Perlis','Perak','Penang','Pahang', 'Johor','Melaka']; // Sample states

  bool _isLoading = false;
  String? _errorMessage;

  void _handleRegistration() async{
    if (_formKey.currentState!.validate() && _selectedState != null) {
      widget.data.businessName = _businessNameController.text;
      widget.data.address = _addressController.text;
      widget.data.postcode = _postcodeController.text;
      widget.data.state = _selectedState;

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Firebase Auth only uses email and password for creation
        User? user = await _authService.signUp(
          email: widget.data.email!, 
          password: widget.data.password!, 
          username: widget.data.username!,
          phoneNumber: widget.data.phoneNumber!,
          role: UserRole.seller,
          additionalData: {
            'businessName': widget.data.businessName!,
            'address': widget.data.address!,
            'postcode': widget.data.postcode!,
            'state': widget.data.state!, 
            'icName': widget.data.icName!, 
            'icNumber': widget.data.icNumber!, 
            'icFrontImagePath': widget.data.icFrontImagePath!, 
            'bankStatementImagePath': widget.data.bankStatementImagePath!, 
            'isVerified': false,
            'verificationPending': true,
          }
        );
        if (mounted && user != null) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const SellerVerification()),
            (route) => false, 
          );
        }
      } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists for that email.';
      } else {
        message = 'Sign Up failed: ${e.message}';
      }
      setState(() {
        _errorMessage = message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  } else if (_selectedState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a state.')),
      );
    }
  }
  
  void _goBack() {
    Navigator.of(context).pop();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(toolbarHeight: 0, backgroundColor: Colors.white, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // ... (Logo, Title, and Step Info) ...
              _buildHeader(),
              const SizedBox(height: 40),

              // --- Business Name Field ---
              _buildInputField(
                controller: _businessNameController,
                label: 'Business Name:',
                hint: 'business name',
                validator: (v) => v!.isEmpty ? 'Enter business name.' : null,
              ),
              const SizedBox(height: 24),

              // --- Address Field ---
              _buildInputField(
                controller: _addressController,
                label: 'Address:',
                hint: 'address',
                validator: (v) => v!.isEmpty ? 'Enter a business address.' : null,
              ),
              const SizedBox(height: 24),

              // --- Postcode Field ---
              _buildInputField(
                controller: _postcodeController,
                label: 'Postcode:',
                hint: 'e.g. 31600',
                keyboardType: TextInputType.number,
                validator: (v) => v!.length < 5 ? 'Enter a valid postcode.' : null,
              ),
              const SizedBox(height: 24),

              // --- State Dropdown ---
              _buildStateDropdown(),
              const SizedBox(height: 32),

              // --- Navigation Buttons (Back/Register) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  TextButton(
                    onPressed: _goBack,
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back_ios, size: 16),
                        SizedBox(width: 8),
                        Text('Back', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                  // Register Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey, // Matches image
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                    ),
                    child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Text('Register', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container( /* ... Logo UI ... */),
        const SizedBox(height: 16),
        const Text('Seller Register', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Page 3 of 3: Business Info', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54)),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8.0))),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          ),
          validator: validator,
        ),
      ],
    );
  }
  
  Widget _buildStateDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('State:', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            hintText: 'Select a state',
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8.0))),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12),
          ),
          value: _selectedState,
          items: _states.map((String state) {
            return DropdownMenuItem<String>(
              value: state,
              child: Text(state),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedState = newValue;
            });
          },
          validator: (value) => value == null ? 'Please select a state.' : null,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _addressController.dispose();
    _postcodeController.dispose();
    super.dispose();
  }
}