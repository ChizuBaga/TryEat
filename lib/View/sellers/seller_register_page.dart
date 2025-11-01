import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:chikankan/Controller/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'seller_register_widgets.dart';
import 'seller_verification.dart';
import '../../Model/seller_data.dart';
import '../../Controller/user_auth.dart';
import 'package:chikankan/View/sellers/seller_login_page.dart';


class SellerRegisterPage extends StatefulWidget {
  const SellerRegisterPage({super.key});

  @override
  State<SellerRegisterPage> createState() => _SellerRegisterPageState();
}

class _SellerRegisterPageState extends State<SellerRegisterPage> {
  int _currentStep = 0; // 0 for Step 1, 1 for Step 2, 2 for Step 3

  final SellerData _sellerData = SellerData();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  // --- Step 1 Controllers & Form Key ---
  final _step1FormKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // --- Step 2 Controllers & Form Key ---
  final _step2FormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _icNumberController = TextEditingController();
  String? _icFrontFileName;
  String? _bankStatementFileName;

  // --- Step 3 Controllers & Form Key ---
  final _step3FormKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _postcodeController = TextEditingController();
  String? _selectedState;

  // List of Malaysian states for the dropdown
  final List<String> _malaysianStates = [
    'Johor',
    'Kedah',
    'Kelantan',
    'Melaka',
    'Negeri Sembilan',
    'Pahang',
    'Perak',
    'Perlis',
    'Pulau Pinang',
    'Sabah',
    'Sarawak',
    'Selangor',
    'Terengganu',
    'Kuala Lumpur',
    'Labuan',
    'Putrajaya',
  ];

  // Dispose controllers to free up resources
  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _icNumberController.dispose();
    _businessNameController.dispose();
    _addressController.dispose();
    _postcodeController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(
  Function(String) onFilePicked,
  String fieldName,
) async {
  // Use FilePicker to allow the user to select one file (image or document)
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'], // Restrict file types
  );

  if (result != null) {
    // Get the local file path
    final filePath = result.files.single.path; 
    final fileName = result.files.single.name;
    
    if (filePath != null) {
      setState(() {
        onFilePicked(filePath); 
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File selected: $fileName')),
      );
    }
  } else {
    // User canceled the picker
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('File selection canceled for $fieldName.')),
    );
  }
}

  void _nextStep() {
    // Validate the current step before proceeding
    bool isStepValid = false;
    if (_currentStep == 0) {
      isStepValid = _step1FormKey.currentState!.validate();
      if (isStepValid) {
        // Save Step 1 data to the model
        _sellerData.username = _usernameController.text;
        _sellerData.phoneNumber = _phoneController.text;
        _sellerData.email = _emailController.text;
        _sellerData.password = _passwordController.text;
      }
    } else if (_currentStep == 1) {
      isStepValid = _step2FormKey.currentState!.validate();
      if (_icFrontFileName == null || _bankStatementFileName == null) {
        isStepValid = false; // Invalidate step if files are missing
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload all required documents.'),
          ),
        );
      }

      if (isStepValid) {
        // Save Step 2 data to the model
        _sellerData.icName = _nameController.text;
        _sellerData.icNumber = _icNumberController.text;
        _sellerData.icFrontImagePath = _icFrontFileName;
        _sellerData.bankStatementImagePath = _bankStatementFileName;
      }
    }

    if (isStepValid && _currentStep < 2) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _register() async {
    if (!_step3FormKey.currentState!.validate() || _selectedState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and select a state.'),
        ),
      );
      return;
    }

    // 1. Save final data
    _sellerData.businessName = _businessNameController.text;
    _sellerData.address = _addressController.text;
    _sellerData.postcode = _postcodeController.text;
    _sellerData.state = _selectedState;

    // 2. Set loading state
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // 3. Attempt to register with Firebase
    try {
      final icFrontUrl = await _authService.uploadVerificationFile(_sellerData.icFrontImagePath!, 'IC_Front');
      final bankStatementUrl = await _authService.uploadVerificationFile(_sellerData.bankStatementImagePath!, 'Bank_Statement');

      //Delete when done
      if (_sellerData.icFrontImagePath != null && icFrontUrl == null) {
        throw Exception('Failed to upload IC image. Registration aborted.');
      }
      String? fullAddr = _sellerData.address! + _sellerData.postcode! + _sellerData.state!;
      GeoPoint? location = await getCoordinatesFromAddress(fullAddr);      
      User? registeredUser = await _authService.signUp(
        email: _sellerData.email!,
        password: _sellerData.password!,
        username: _sellerData.username!,
        phoneNumber: _sellerData.phoneNumber!,
        role: UserRole.seller,
        additionalData: {
          'businessName': _sellerData.businessName!,
          'address': _sellerData.address!,
          'postcode': _sellerData.postcode!,
          'state': _sellerData.state!,
          'icName': _sellerData.icName!,
          'icNumber': _sellerData.icNumber!,
          'icFrontImagePath': icFrontUrl!,
          'bankStatementImagePath': bankStatementUrl!,
          'isVerified': true, // Future improvement
          'verificationPending': false, // Future improvement (to verify seller)
          'location': location,
        },
      );
      if (mounted && registeredUser != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SellerLoginPage()),
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
    } catch (e, stackTrace) {
      setState(() {
        print('An unexpected error occurred: $e');
        print('--- FULL STACK TRACE ---');
        print(stackTrace); // Print the stack trace object
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(255, 244, 164, 1),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 10),

              Image.asset('assets/applogo.png', height: 100),

              const SizedBox(height: 10),

              const Text(
                'Seller Register',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // AnimatedSwitcher provides a nice transition between steps
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildCurrentStep(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _Step1Personal(
          key: const ValueKey('Step1'),
          formKey: _step1FormKey,
          usernameController: _usernameController,
          phoneController: _phoneController,
          emailController: _emailController,
          passwordController: _passwordController,
          onNext: _nextStep,
        );
      case 1:
        return _Step2Verification(
          key: const ValueKey('Step2'),
          formKey: _step2FormKey,
          nameController: _nameController,
          icNumberController: _icNumberController,
          // NEW: Pass file info and callbacks
          icFrontFileName: _icFrontFileName,
          bankStatementFileName: _bankStatementFileName,
          onPickIC: () =>
              _pickFile((name) => _icFrontFileName = name, 'IC Front'),
          onPickStatement: () => _pickFile(
            (name) => _bankStatementFileName = name,
            'Bank Statement',
          ),
          onNext: _nextStep,
          onBack: _previousStep,
        );
      case 2:
        return _Step3Business(
          key: const ValueKey('Step3'),
          formKey: _step3FormKey,
          businessNameController: _businessNameController,
          addressController: _addressController,
          postcodeController: _postcodeController,
          selectedState: _selectedState,
          states: _malaysianStates,
          onStateChanged: (newValue) {
            setState(() {
              _selectedState = newValue;
            });
          },
          // NEW: Pass loading state and error message
          isLoading: _isLoading,
          errorMessage: _errorMessage,
          onRegister: _register,
          onBack: _previousStep,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// --- WIDGET FOR STEP 1: PERSONAL INFO ---
class _Step1Personal extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onNext;

  const _Step1Personal({
    super.key,
    required this.formKey,
    required this.usernameController,
    required this.phoneController,
    required this.emailController,
    required this.passwordController,
    required this.onNext,
  });

  @override
  State<_Step1Personal> createState() => _Step1PersonalState();
}

class _Step1PersonalState extends State<_Step1Personal> {
  // State variables to track password criteria
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSymbol = false;

  @override
  void initState() {
    super.initState();
    // Add a listener to the password controller to check criteria in real-time
    widget.passwordController.addListener(_validatePasswordCriteria);
  }

  @override
  void dispose() {
    // Clean up the listener when the widget is removed
    widget.passwordController.removeListener(_validatePasswordCriteria);
    super.dispose();
  }

  void _validatePasswordCriteria() {
    final password = widget.passwordController.text;
    // Update the state based on the current password input
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = RegExp(r'(?=.*[A-Z])').hasMatch(password);
      _hasLowercase = RegExp(r'(?=.*[a-z])').hasMatch(password);
      _hasNumber = RegExp(r'(?=.*\d)').hasMatch(password);
      _hasSymbol = RegExp(r'(?=.*[!@#\$%^&*(),.?":{}|<>])').hasMatch(password);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      autovalidateMode: AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Page 1 of 3: Personal Info',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 30),

          RegisterTextFormField(
            labelText: 'Username:',
            hintText: 'e.g. johnlee',
            controller: widget.usernameController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Username cannot be empty';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          RegisterTextFormField(
            labelText: 'Phone Number:',
            hintText: 'e.g. 0123456789',
            controller: widget.phoneController,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Phone number cannot be empty';
              }
              final phoneRegExp = RegExp(r'^0\d{8,10}$');
              if (!phoneRegExp.hasMatch(value)) {
                return 'Enter a valid Malaysian phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          RegisterTextFormField(
            labelText: 'Email:',
            hintText: 'e.g. example@gmail.com',
            controller: widget.emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email cannot be empty';
              }
              final emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
              if (!emailRegExp.hasMatch(value)) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          RegisterTextFormField(
            labelText: 'Password:',
            hintText: 'Enter your password',
            controller: widget.passwordController,
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password cannot be empty';
              }
              if (!_hasMinLength ||
                  !_hasUppercase ||
                  !_hasLowercase ||
                  !_hasNumber ||
                  !_hasSymbol) {
                return 'Please meet all password criteria';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // NEW: Password criteria checklist
          _PasswordCriteriaView(
            hasMinLength: _hasMinLength,
            hasUppercase: _hasUppercase,
            hasLowercase: _hasLowercase,
            hasNumber: _hasNumber,
            hasSymbol: _hasSymbol,
          ),
          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: widget.onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 255, 153, 0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 6,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Next',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Already have an account? ",
                style: TextStyle(fontSize: 16),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- DISPLAYING PASSWORD CRITERIA ---
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
        _CriteriaItem(
          text: 'Contains an uppercase letter (A-Z)',
          isMet: hasUppercase,
        ),
        const SizedBox(height: 4),
        _CriteriaItem(
          text: 'Contains a lowercase letter (a-z)',
          isMet: hasLowercase,
        ),
        const SizedBox(height: 4),
        _CriteriaItem(text: 'Contains a number (0-9)', isMet: hasNumber),
        const SizedBox(height: 4),
        _CriteriaItem(
          text: 'Contains a special character (!@#\$)',
          isMet: hasSymbol,
        ),
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
            decoration: isMet ? TextDecoration.none : TextDecoration.none,
          ),
        ),
      ],
    );
  }
}

// --- WIDGET FOR STEP 2: VERIFICATION INFO  ---
class _Step2Verification extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController icNumberController;
  final VoidCallback onNext;
  final VoidCallback onBack;

  final String? icFrontFileName;
  final String? bankStatementFileName;
  final VoidCallback onPickIC;
  final VoidCallback onPickStatement;

  const _Step2Verification({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.icNumberController,
    required this.onNext,
    required this.onBack,
    required this.icFrontFileName,
    required this.bankStatementFileName,
    required this.onPickIC,
    required this.onPickStatement,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Page 2 of 3: Personal Info',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const Text(
            '(For verification purpose)',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 30),
          RegisterTextFormField(
            labelText: 'Name as per IC:',
            hintText: 'Your full name',
            controller: nameController,
            validator: (value) =>
                value!.isEmpty ? 'Name cannot be empty' : null,
          ),
          const SizedBox(height: 16),
          RegisterTextFormField(
            labelText: 'IC Number:',
            hintText: 'e.g. 990101-01-5555',
            controller: icNumberController,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'IC Number cannot be empty';
              }
              if (!RegExp(r'^\d{12}$').hasMatch(value.replaceAll('-', ''))) {
                return 'Enter a valid 12-digit IC number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          DynamicUploadButton(
            label: 'IC (Front):',
            hintText: 'Upload an image of your IC',
            fileName: icFrontFileName,
            onTap: onPickIC,
          ),

          const SizedBox(height: 16),

          DynamicUploadButton(
            label: 'E-Bank Statement:',
            hintText: 'Upload your bank statement',
            fileName: bankStatementFileName,
            onTap: onPickStatement,
          ),

          const SizedBox(height: 40),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 150,
                height: 52,
                child: ElevatedButton(
                  onPressed: onBack,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 255, 184, 32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 6,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Back',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 140,
                height: 52,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 255, 153, 0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 6,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Next',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- WIDGET FOR STEP 3: BUSINESS INFO ---
class _Step3Business extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController businessNameController;
  final TextEditingController addressController;
  final TextEditingController postcodeController;
  final String? selectedState;
  final List<String> states;
  final ValueChanged<String?> onStateChanged;
  final VoidCallback onRegister;
  final VoidCallback onBack;

  final bool isLoading;
  final String? errorMessage;

  const _Step3Business({
    super.key,
    required this.formKey,
    required this.businessNameController,
    required this.addressController,
    required this.postcodeController,
    this.selectedState,
    required this.states,
    required this.onStateChanged,
    required this.onRegister,
    required this.onBack,
    required this.isLoading,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Page 3 of 3: Business Info',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 30),
          RegisterTextFormField(
            labelText: 'Business Name:',
            hintText: 'e.g. Tonic Triad Food',
            controller: businessNameController,
            validator: (value) =>
                value!.isEmpty ? 'Business name cannot be empty' : null,
          ),
          const SizedBox(height: 16),
          RegisterTextFormField(
            labelText: 'Address:',
            hintText: 'Your business address',
            controller: addressController,
            maxLines: 3,
            validator: (value) =>
                value!.isEmpty ? 'Address cannot be empty' : null,
          ),
          const SizedBox(height: 16),
          RegisterTextFormField(
            labelText: 'Postcode:',
            hintText: 'e.g. 11900',
            controller: postcodeController,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Postcode cannot be empty';
              }
              if (!RegExp(r'^\d{5}$').hasMatch(value)) {
                return 'Enter a valid 5-digit postcode';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomDropdownField(
            labelText: 'State:',
            value: selectedState,
            items: states,
            onChanged: onStateChanged,
            validator: (value) =>
                value == null ? 'Please select a state' : null,
          ),

          const SizedBox(height: 24),

          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 150,
                height: 52,
                child: ElevatedButton(
                  onPressed: onBack,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 255, 184, 32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 6,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Back',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 140,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : onRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 255, 153, 0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 6,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          'Register',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
