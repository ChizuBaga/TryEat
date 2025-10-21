import 'package:chikankan/Model/sellerData.dart';
import 'package:flutter/material.dart';
import 'package:chikankan/View/sellerRegister3.dart'; // the next page

class SellerRegisterPage2 extends StatefulWidget {
  final SellerData data;
  const SellerRegisterPage2({super.key, required this.data});

  @override
  State<SellerRegisterPage2> createState() => _SellerRegisterPage2State();
}

class _SellerRegisterPage2State extends State<SellerRegisterPage2> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _icNameController = TextEditingController();
  final TextEditingController _icNumberController = TextEditingController();

  // Placeholder variables to show if a file has been 'uploaded'
  String? _icFrontFileName;
  String? _bankStatementFileName;

  // !!!requires file_picker package in a real app
  Future<void> _pickFile(Function(String) onFilePicked, String fieldName) async {
    setState(() {
      onFilePicked('${fieldName}_uploaded.jpg');
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$fieldName uploaded successfully!')),
    );
  }

  void _navigateToNextStep() {
    if (_formKey.currentState!.validate() && _icFrontFileName != null && _bankStatementFileName != null) {
      // 1. Populate the data model
      widget.data.icName = _icNameController.text;
      widget.data.icNumber = _icNumberController.text;
      widget.data.icFrontImagePath = _icFrontFileName;
      widget.data.bankStatementImagePath = _bankStatementFileName;

      // 2. Navigate to Page 3, passing the data model
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SellerRegisterPage3(data: widget.data),
        ),
      );
    } else if (_icFrontFileName == null || _bankStatementFileName == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload all required documents.')),
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

              // --- Name as per IC Field ---
              _buildInputField(
                controller: _icNameController,
                label: 'Name as per IC (for verification purpose)',
                hint: 'name',
                validator: (v) => v!.isEmpty ? 'Enter name on IC.' : null,
              ),
              const SizedBox(height: 24),

              // --- IC Number Field ---
              _buildInputField(
                controller: _icNumberController,
                label: 'IC Number:',
                hint: '000000-00-0000',
                keyboardType: TextInputType.number,
                validator: (v) => v!.length < 12 ? 'Enter a valid IC number.' : null,
              ),
              const SizedBox(height: 24),
              
              // --- IC Front Upload ---
              _buildUploadField(
                label: 'IC Fronts:',
                subtext: 'Upload an image of IC',
                fileName: _icFrontFileName,
                onTap: () => _pickFile((name) => _icFrontFileName = name, 'IC Front'),
              ),
              const SizedBox(height: 24),

              // --- E-Bank Statement Upload ---
              _buildUploadField(
                label: 'E-Bank Statement:',
                subtext: 'Upload e-bank statement',
                fileName: _bankStatementFileName,
                onTap: () => _pickFile((name) => _bankStatementFileName = name, 'Bank Statement'),
              ),
              const SizedBox(height: 32),

              // --- Navigation Buttons (Back/Next) ---
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
                  // Next Button
                  ElevatedButton(
                    onPressed: _navigateToNextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
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
            ],
          ),
        ),
      ),
    );
  }
  
  // Helper for consistent headers
  Widget _buildHeader() {
    return Column(
      children: [
        Container( /* ... Logo UI ... */),
        const SizedBox(height: 16),
        const Text('Seller Register', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Page 2 of 3: Personal Info', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54)),
      ],
    );
  }

  // Helper for regular text fields
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    // ... (same as the helper in Page 1) ...
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
  
  // Helper for upload fields
  Widget _buildUploadField({
    required String label,
    required String subtext,
    required String? fileName,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  fileName ?? subtext,
                  style: TextStyle(
                    color: fileName != null ? Colors.black : Colors.grey,
                    fontStyle: fileName != null ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
                const Icon(Icons.cloud_upload_outlined, color: Colors.black),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _icNameController.dispose();
    _icNumberController.dispose();
    super.dispose();
  }
}