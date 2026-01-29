import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';
import '../../services/payment_service.dart';
import '../../services/test_drive_reminder_service.dart';

class PaymentScreen extends StatefulWidget {
  final String carName;
  final String carId;
  final DateTime testDriveDate;
  final TimeOfDay testDriveTime;
  final Map<String, dynamic> carData; // ✅ Added full car data

  const PaymentScreen({
    Key? key,
    required this.carName,
    required this.carId,
    required this.testDriveDate,
    required this.testDriveTime,
    required this.carData, // ✅ Required parameter
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String selectedPaymentMethod = 'PhonePe';
  bool _isProcessing = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();
  final TestDriveReminderService _reminderService = TestDriveReminderService();

  // ✅ Extract car details from passed data
  String get carName => widget.carData['Car Name'] ?? 'Unknown Car';
  String get carPrice => widget.carData['Final Estimated Price'] ??
      widget.carData['Estimated Price'] ??
      'N/A';
  int get kmDriven => widget. carData['KM Driven'] ?? 0;
  String get fuelType => widget.carData['Fuel Type'] ?? 'Unknown';
  String get location => widget.carData['Set Location'] ?? 'Unknown';
  String get carImage => widget.carData['Image1'] ?? '';

  // ✅ Process payment and save booking
  Future<void> _processPayment() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        _showSnackBar('Please log in to complete booking', isError: true);
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // Validation for card fields
      if ((selectedPaymentMethod == 'Credit Card') &&
          (_cardNumberController.text.isEmpty || _cvcController.text.isEmpty)) {
        _showSnackBar('Please enter card details for testing', isError: true);
        return;
      }

      try{

        // 1. Initialize Polar Service
        final polarService = PolarPaymentService();

        // 2. Perform Transactional API Call (No Webhooks)
        final paymentResult = await polarService.processPayment(
          amount: 10.0,
          currency: 'USD',
          description: 'Booking for car',
          metadata: {
            'userId': currentUser.uid,
            'carID': 'bleh',
          },
          paymentMethod: selectedPaymentMethod,
        );

        if (paymentResult['success'] == true) {
          // Create booking data
          final bookingData = {
            'carId': widget.carId,
            'carName': carName,
            'carPrice': carPrice,
            'testDriveDate': Timestamp.fromDate(widget.testDriveDate),
            'testDriveTime': '${widget.testDriveTime.hour}:${widget
                .testDriveTime.minute}',
            'paymentMethod': selectedPaymentMethod,
            'bookedAt': FieldValue.serverTimestamp(),
            'status': 'confirmed',
            'userId': currentUser.uid,
            'userName': currentUser.displayName ?? 'User',
            'userEmail': currentUser.email ?? '',
          };

          // Save to user's my_bookings subcollection
          final bookingRef = await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .collection('my_bookings')
              .add(bookingData);

          // Get seller information from car data
          final sellerUid = widget.carData['seller_uid'] ?? '';
          final buyerName = currentUser.displayName ?? 'A user';

          // Format date and time for notification
          final dateStr = DateFormat('MMM d, yyyy').format(
              widget.testDriveDate);
          final timeStr = '${widget.testDriveTime.hour}:${widget.testDriveTime
              .minute.toString().padLeft(2, '0')}';

          // Send notification to seller about the booking
          if (sellerUid.isNotEmpty) {
            await _notificationService.notifyTestDriveBooked(
              carId: widget.carId,
              carName: carName,
              sellerUid: sellerUid,
              buyerName: buyerName,
              date: dateStr,
              time: timeStr,
              bookingId: bookingRef.id,
            );
          }

          // Schedule reminder notification 24 hours before test drive
          final testDriveDateTime = DateTime(
            widget.testDriveDate.year,
            widget.testDriveDate.month,
            widget.testDriveDate.day,
            widget.testDriveTime.hour,
            widget.testDriveTime.minute,
          );

          final reminderNotificationId = await _reminderService
              .scheduleTestDriveReminder(
            testDriveDateTime: testDriveDateTime,
            carName: carName,
            time: timeStr,
            buyerUid: currentUser.uid,
            bookingId: bookingRef.id,
          );

          // Store reminder notification ID in booking document for future reference
          await bookingRef.update({
            'reminderNotificationId': reminderNotificationId,
            'reminderScheduled': reminderNotificationId != -1,
          });
        } else {
          throw paymentResult['error'] ?? 'Payment Failed';
        }
      }catch(e){
        setState(() => _isProcessing = false);
        _showSnackBar('$e', isError: true);
      }
      
      setState(() {
        _isProcessing = false;
      });

      // Show success message
      _showSuccessDialog();
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showSnackBar('Error processing payment: $e', isError: true);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context:  context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius:  BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors. green,
                size: 64,
              ),
            ),
            const SizedBox(height:  20),
            const Text(
              'Booking Confirmed!',
              style: TextStyle(
                fontSize:  22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A5F),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your test drive for $carName has been booked successfully.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A5F),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child:  const Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ?  Colors.red : const Color(0xFF1E3A5F),
      ),
    );
  }

  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child:  Column(
          children: [
            // Header
            Container(
              color: const Color(0xFFE8C87C),
              padding: const EdgeInsets. all(16),
              child:  Row(
                mainAxisAlignment:  MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration:  BoxDecoration(
                      color: const Color(0xFF1E3A5F),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'GC',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE8C87C),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color:  Color(0xFF1E3A5F),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Car Card - ✅ Now uses actual car data
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius:  8,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Car Image
                          Container(
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            child: Stack(
                              children: [
                                carImage.isNotEmpty
                                    ? ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top:  Radius.circular(16),
                                  ),
                                  child: Image.network(
                                    carImage,
                                    width: double.infinity,
                                    height: 150,
                                    fit: BoxFit. cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Icon(
                                          Icons.directions_car,
                                          size: 70,
                                          color: Colors.grey[600],
                                        ),
                                      );
                                    },
                                  ),
                                )
                                    : Center(
                                  child: Icon(
                                    Icons.directions_car,
                                    size: 70,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Car Details - ✅ Now shows real data
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  carName,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight:  FontWeight.bold,
                                    color: Color(0xFF1E3A5F),
                                  ),
                                ),
                                const SizedBox(height:  8),
                                Text(
                                  '${NumberFormat('#,###').format(kmDriven)} KM  •  $fuelType  •  $location',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  carPrice,
                                  style:  const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E3A5F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Booking Details
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius. circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius:  5,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Test Drive Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A5F),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('EEEE, MMMM d, yyyy').format(widget.testDriveDate),
                                style:  const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 18, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                '${widget.testDriveTime.hour}:${widget.testDriveTime.minute. toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Payment Methods
                    Row(
                      mainAxisAlignment:  MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildPaymentMethodButton('Credit Card'),
                        _buildPaymentMethodButton('PhonePe'),
                        _buildPaymentMethodButton('Gpay'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Payment Method Icons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildPaymentIcon('PhonePe', Colors.purple),
                        const SizedBox(width: 20),
                        _buildPaymentIcon('GPay', Colors.blue),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildCardFields(),
                    const SizedBox(height: 20),
                    // Pay Button - ✅ Now functional
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:  _isProcessing ? null : _processPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A5F),
                          padding:  const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          'Book $carName for 10\$',
                          style:  const TextStyle(
                            fontSize: 18,
                            fontWeight:  FontWeight.w600,
                            color:  Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardFields() {
    if (selectedPaymentMethod != 'Credit Card') {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Card Information (Sandbox Mode)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _cardNumberController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '4242 4242 4242 4242',
            labelText: 'Card Number',
            prefixIcon: const Icon(Icons.credit_card),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _expiryController,
                decoration: InputDecoration(
                  hintText: 'MM/YY',
                  labelText: 'Expiry',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _cvcController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: '123',
                  labelText: 'CVC',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPaymentMethodButton(String method) {
    bool isSelected = selectedPaymentMethod == method;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPaymentMethod = method;
        });
      },
      child: Container(
        padding: const EdgeInsets. symmetric(horizontal: 30, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E3A5F) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: const Color(0xFF1E3A5F),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
            ),
          ],
        ),
        child: Text(
          method,
          style:  TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white :  const Color(0xFF1E3A5F),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentIcon(String name, Color color) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:  Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.payment,
            size: 35,
            color: color,
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}