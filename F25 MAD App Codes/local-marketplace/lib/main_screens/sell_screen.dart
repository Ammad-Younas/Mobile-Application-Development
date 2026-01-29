import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

class SellScreen extends StatefulWidget {
  final PersistentTabController controller;
  const SellScreen({Key? key, required this.controller}) : super(key: key);

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Text Controllers
  final _carNumberController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _variantController = TextEditingController();
  final _yearController = TextEditingController();
  final _kmDrivenController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();

  // Dropdown values
  String? _transmissionType;
  String? _fuelType;

  // Dropdown options
  final List<String> _transmissionTypes = [
    'Manual',
    'Automatic',
    'CVT',
    'Semi-Automatic'
  ];
  final List<String> _fuelTypes = [
    'Petrol',
    'Diesel',
    'Electric',
    'Hybrid',
    'CNG',
    'LPG'
  ];

  @override
  void dispose() {
    _carNumberController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _variantController.dispose();
    _yearController.dispose();
    _kmDrivenController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // Validate car number
  String? _validateCarNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Car number is required';
    }
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
      return 'Only letters and numbers allowed (no spaces)';
    }
    if (value.length < 5 || value.length > 15) {
      return 'Must be between 5 and 15 characters';
    }
    return null;
  }

  // Validate brand
  String? _validateBrand(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Brand is required';
    }
    if (!RegExp(r'^[a-zA-Z\s-]+$').hasMatch(value)) {
      return 'Brand must contain only letters';
    }
    return null;
  }

  // Validate required text field
  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Validate year
  String? _validateYear(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Year is required';
    }
    final year = int.tryParse(value);
    if (year == null) {
      return 'Year must be a valid number';
    }
    if (year < 1900 || year > DateTime.now().year + 1) {
      return 'Year must be between 1900 and ${DateTime.now().year + 1}';
    }
    return null;
  }

  // Validate KM Driven
  String? _validateKmDriven(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'KM Driven is required';
    }
    final km = int.tryParse(value);
    if (km == null) {
      return 'KM Driven must be a valid number';
    }
    if (km < 0) {
      return 'KM Driven cannot be negative';
    }
    return null;
  }

  // Validate price
  String? _validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Price is required';
    }
    final price = int.tryParse(value.replaceAll(',', ''));
    if (price == null) {
      return 'Price must be a valid number';
    }
    if (price <= 0) {
      return 'Price must be greater than zero';
    }
    return null;
  }

  // Get current user data
  Future<Map<String, dynamic>> _getCurrentUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw 'No user logged in';
      }

      // Get user data from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        return {
          'seller_uid': user.uid,
          'seller_name': user.displayName ?? 'Unknown User',
          'seller_email': user.email ?? '',
        };
      }

      final userData = userDoc.data()!;

      return {
        'seller_uid': user.uid,
        'seller_name': userData['name'] ?? user.displayName ?? 'Unknown User',
        'seller_email': user.email ?? '',
      };
    } catch (e) {
      print('❌ Error getting user data: $e');
      rethrow;
    }
  }

  // Submit car listing
  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Additional validation for dropdowns
    if (_transmissionType == null) {
      _showSnackBar('Please select Transmission Type', Colors.red);
      return;
    }

    if (_fuelType == null) {
      _showSnackBar('Please select Fuel Type', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user data
      final userData = await _getCurrentUserData();

      // Construct car name from user input
      final brand = _brandController.text.trim();
      final model = _modelController.text.trim();
      final variant = _variantController.text.trim();
      final carName = '$brand $model $variant'.trim();

      // Prepare the car data
      final carData = {
        // Basic car details
        'Brand': brand,
        'Model': model,
        'Variant': variant,
        'Year': int.parse(_yearController.text.trim()),
        'Transmission Type': _transmissionType!,
        'Fuel Type': _fuelType!,
        'KM Driven': int.parse(_kmDrivenController.text.trim()),
        'Set Location': _locationController.text.trim(),

        // Car name constructed from user input
        'Car Name': carName,

        // Pricing
        'Price': _priceController.text.trim(),
        'Estimated Price': _priceController.text.trim(),
        'Final Estimated Price': _priceController.text.trim(),

        // Car number
        'Car Number': _carNumberController.text.trim(),

        // Optional details
        'Engine Capacity': 'N/A',
        'Address': '',
        'Pin Code': '',

        // Seller information
        'seller_uid': userData['seller_uid'],
        'seller_name': userData['seller_name'],
        'seller_email': userData['seller_email'],

        // Status and timestamp
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add car to Firestore 'global' collection
      final docRef =
      await FirebaseFirestore.instance.collection('global').add(carData);

      print('✅ Car listed successfully with ID: ${docRef.id}');
      print('✅ Car Name saved: $carName');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show success message
        _showSnackBar(
          '✅ Car listed successfully! Your car is now visible to buyers.',
          Colors.green,
        );

        // Navigate to home screen after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            // Jump to home tab
            widget.controller.jumpToTab(0);

            // Clear the form
            _formKey.currentState!.reset();
            _carNumberController.clear();
            _brandController.clear();
            _modelController.clear();
            _variantController.clear();
            _yearController.clear();
            _kmDrivenController.clear();
            _priceController.clear();
            _locationController.clear();
            setState(() {
              _transmissionType = null;
              _fuelType = null;
            });
          }
        });
      }
    } on FirebaseException catch (e) {
      print('❌ Firebase Error: ${e.code} - ${e.message}');

      String errorMessage;
      switch (e.code) {
        case 'permission-denied':
          errorMessage =
          '❌ Permission denied. Please check your Firestore security rules.';
          break;
        case 'unavailable':
          errorMessage =
          '❌ Service unavailable. Please check your internet connection.';
          break;
        case 'deadline-exceeded':
          errorMessage = '❌ Request timeout. Please try again.';
          break;
        default:
          errorMessage = '❌ Failed to list car: ${e.message ?? 'Unknown error'}';
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar(errorMessage, Colors.red);
      }
    } catch (e) {
      print('❌ Unexpected Error: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('❌ An unexpected error occurred: ${e.toString()}', Colors.red);
      }
    }
  }

  // Show SnackBar
  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              backgroundColor == Colors.green ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header with Logo and Buttons
            Container(
              color: const Color(0xFFE8C87C),
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A5F),
                      borderRadius: BorderRadius. circular(8),
                    ),
                    child: const Text(
                      'GC',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:  FontWeight.bold,
                        color: Color(0xFFE8C87C),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          widget.controller.jumpToTab(1);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD54F),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Buy',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E3A5F),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF1E3A5F),
                            width: 2,
                          ),
                        ),
                        child: const Text(
                          'Sell',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E3A5F),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Form Section
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'List Your Car',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A5F),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Fill in all the details to list your car',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Car Number Section
                      _buildSectionHeader('Car Registration'),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _carNumberController,
                        label: 'Car Number',
                        hint: 'e.g., ABC1234',
                        validator: _validateCarNumber,
                        textCapitalization: TextCapitalization.characters,
                      ),
                      const SizedBox(height: 30),

                      // Basic Details Section
                      _buildSectionHeader('Basic Information'),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _brandController,
                        label: 'Brand',
                        hint: 'e.g., Toyota, Honda',
                        validator: _validateBrand,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _modelController,
                        label: 'Model',
                        hint: 'e.g., Corolla, Civic',
                        validator: (value) => _validateRequired(value, 'Model'),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _variantController,
                        label: 'Variant',
                        hint: 'e.g., GLi, Altis',
                        validator: (value) => _validateRequired(value, 'Variant'),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _yearController,
                        label: 'Year',
                        hint: 'e.g., 2020',
                        validator: _validateYear,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown(
                        label: 'Transmission Type',
                        value: _transmissionType,
                        items: _transmissionTypes,
                        onChanged: (value) {
                          setState(() {
                            _transmissionType = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown(
                        label: 'Fuel Type',
                        value: _fuelType,
                        items: _fuelTypes,
                        onChanged: (value) {
                          setState(() {
                            _fuelType = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _kmDrivenController,
                        label: 'KM Driven',
                        hint: 'e.g., 50000',
                        validator: _validateKmDriven,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                      const SizedBox(height: 30),

                      // Pricing Section
                      _buildSectionHeader('Pricing'),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _priceController,
                        label: 'Asking Price',
                        hint: 'e.g., 2500000',
                        validator: _validatePrice,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        prefix: 'RS: ',
                      ),
                      const SizedBox(height: 30),

                      // Location Section
                      _buildSectionHeader('Location'),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _locationController,
                        label: 'Location',
                        hint: 'e.g., Lahore, Punjab',
                        validator: (value) => _validateRequired(value, 'Location'),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 30),

                      // Image Upload Section (Placeholder)
                      _buildSectionHeader('Photos (Optional)'),
                      const SizedBox(height: 12),
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[400]!,
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 50,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Image upload coming soon',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitListing,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A5F),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            disabledBackgroundColor:
                            const Color(0xFF1E3A5F).withOpacity(0.5),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : const Text(
                            'List My Car',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E3A5F),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? prefix,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefix,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E3A5F), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E3A5F), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label is required';
        }
        return null;
      },
    );
  }
}