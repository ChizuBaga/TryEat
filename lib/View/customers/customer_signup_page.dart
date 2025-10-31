import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../Controller/user_auth.dart';

class CustomerSignUpPage extends StatefulWidget {
  const CustomerSignUpPage({super.key});

  @override
  State<CustomerSignUpPage> createState() => _CustomerSignUpPageState();
}

class _CustomerSignUpPageState extends State<CustomerSignUpPage> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  // Controllers for the input fields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSymbol = false;

  @override
  void initState() {
    super.initState();
    // --- NEW: Add listener to password controller ---
    _passwordController.addListener(_validatePasswordCriteria);
    // --- END NEW ---
  }

  @override
  void dispose() {
    _passwordController.removeListener(_validatePasswordCriteria);
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validatePasswordCriteria() {
    final password = _passwordController.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = RegExp(r'(?=.*[A-Z])').hasMatch(password);
      _hasLowercase = RegExp(r'(?=.*[a-z])').hasMatch(password);
      _hasNumber = RegExp(r'(?=.*\d)').hasMatch(password);
      _hasSymbol = RegExp(r'(?=.*[!@#\$%^&*(),.?":{}|<>])').hasMatch(password);
    });
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      User? user = await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        username: _usernameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        role: UserRole.customer,
      );
      if (mounted && user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign Up Successful! Please log in.')),
        );
        // *** MODIFIED HERE: Use pushReplacementNamed for navigation ***
        Navigator.pushReplacementNamed(context, '/customer_login');
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists for that email.';
      } else {
        message = 'An error occurred during sign up.';
      }
      setState(() {
        _errorMessage = message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
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
        toolbarHeight: 0,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 10),

              Image.asset('assets/applogo.png', height: 100),

              const SizedBox(height: 10),
              const Text(
                'Customer Sign Up',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              // --- Form Fields ---
              _buildLabel('Username:'),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  hintText: 'username',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Please enter a username.'
                    : null,
              ),
              const SizedBox(height: 16),

              _buildLabel('Phone Number:'),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: 'e.g. 0123456789',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                ),
                validator: (value) => (value == null || value.length < 9)
                    ? 'Please enter a valid phone number.'
                    : null,
              ),
              const SizedBox(height: 16),

              _buildLabel('Email:'),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'e.g. example@gmail.com',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                ),
                validator: (value) => (value == null || !value.contains('@'))
                    ? 'Please enter a valid email address.'
                    : null,
              ),
              const SizedBox(height: 16),

              _buildLabel('Password:'),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Enter your password',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password cannot be empty';
                  }
                  // Check criteria flags
                  if (!_hasMinLength || !_hasUppercase || !_hasLowercase || !_hasNumber || !_hasSymbol) {
                    return 'Please meet all password criteria';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _PasswordCriteriaView(
                hasMinLength: _hasMinLength,
                hasUppercase: _hasUppercase,
                hasLowercase: _hasLowercase,
                hasNumber: _hasNumber,
                hasSymbol: _hasSymbol,
              ),

              const SizedBox(height: 32),

              // --- Error Message Display ---
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // --- Sign Up Button ---
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSignUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 255, 153, 0),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text('Sign Up', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 20),

              // --- Login Link ---
              GestureDetector(
                // *** MODIFIED HERE: Use pushReplacementNamed for navigation ***
                onTap: () =>
                    Navigator.pushReplacementNamed(context, '/customer_login'),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _PasswordCriteriaView extends StatelessWidget {
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasNumber;
  final bool hasSymbol;

  const _PasswordCriteriaView({
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasNumber,
    required this.hasSymbol,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CriteriaItem(text: 'At least 8 characters long', isMet: hasMinLength),
        const SizedBox(height: 4),
        _CriteriaItem(text: 'Contains an uppercase letter (A-Z)', isMet: hasUppercase),
        const SizedBox(height: 4),
        _CriteriaItem(text: 'Contains a lowercase letter (a-z)', isMet: hasLowercase),
        const SizedBox(height: 4),
        _CriteriaItem(text: 'Contains a number (0-9)', isMet: hasNumber),
        const SizedBox(height: 4),
        _CriteriaItem(text: 'Contains a special character (!@#\$...)', isMet: hasSymbol),
      ],
    );
  }
}

class _CriteriaItem extends StatelessWidget {
  final String text;
  final bool isMet;

  const _CriteriaItem({required this.text, required this.isMet});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.remove_circle_outline,
          color: isMet ? Colors.green : Colors.grey,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: isMet ? Colors.green : Colors.grey,
            decoration: TextDecoration.none, // Keep text visible
          ),
        ),
      ],
    );
  }
}