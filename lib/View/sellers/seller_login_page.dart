import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../Controller/user_auth.dart'; 

class SellerLoginPage extends StatefulWidget {
  const SellerLoginPage({super.key});

  @override
  State<SellerLoginPage> createState() => _SellerLoginPageState();
}

class _SellerLoginPageState extends State<SellerLoginPage> {
  // Initialize Firebase Auth Service
  final AuthService _authService = AuthService();

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Text field controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // State variables for loading and error messages
  bool _isLoading = false;
  String? _errorMessage;

  // Dispose controllers when the widget is removed from the widget tree
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- Sign-in Logic ---
  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      //For debug
      // Attempt to sign in with email and password
      User? user = await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // If sign-in is successful and the widget is still mounted
      if (mounted && user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login Successful!')),
        );
        // Navigate to the seller homepage and remove the login page from the stack
        Navigator.pushReplacementNamed(context, '/seller_homepage');
      }
      
      //For deployment
      // User? user = await _authService.signIn(
      //   email: _emailController.text,
      //   password: _passwordController.text,
      // );

      // if (user == null || !mounted) return;

      // final AuthStatus? userRole = await _authService.getUserAuthStatus(user.uid);
      // if (!mounted) return;

      // if(userRole!.role == UserRole.seller) {
      //   final isVerified = userRole!.isVerified!;
      //   if (isVerified) {
      //     Navigator.pushReplacementNamed(context, '/seller_homepage');
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       const SnackBar(content: Text('Login Successful!')),
      //     );
      //   } else {
      //     _authService.signOut();
      //     Navigator.pushReplacementNamed(context, '/seller_verification');
      //   }
      // } else {
      //   _authService.signOut();
      //   Navigator.pushReplacementNamed(context, '/seller_register');
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('Error: Please re-register.')),
      //   );
      // }
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase authentication errors
      String message;
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        message = 'Invalid email or password.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      } else {
        message = 'Login failed. Please try again.';
      }
      setState(() {
        _errorMessage = message;
      });
    } catch (e) {
      // Handle other generic errors
      setState(() {
        _errorMessage = 'An unexpected error occurred.';
      });
    } finally {
      // Always set loading state back to false
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
          // Use a Form widget to enable validation
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 100),

                Image.asset('assets/applogo.png', height: 100),

                const SizedBox(height: 15),

                const Text(
                  'Seller Login',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 85),

                // --- Email Text Form Field ---
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'e.g. example.gmail.com',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty || !value.contains('@')) {
                      return 'Please enter a valid email address.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 50),

                // --- Password Text Form Field ---
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    hintText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Password must be at least 6 characters.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 40),

                // --- Error Message Display ---
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 25),

                // --- Login Button ---
                SizedBox(
                  width: 200,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignIn, // Disable button when loading
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 255, 153, 0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      elevation: 6,
                    ),
                    // Show a loading indicator or text
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text('Login'),
                  ),
                ),

                const SizedBox(height: 65),

                //new seller
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'New seller? ',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/seller_register'),
                      child: const Text(
                        'Register your business',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}