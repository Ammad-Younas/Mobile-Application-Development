import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../car_details/car_details.dart';
import '../../services/test_drive_reminder_service.dart';

class BookedCarsScreen extends StatefulWidget {
  const BookedCarsScreen({Key? key}) : super(key: key);

  @override
  State<BookedCarsScreen> createState() => _BookedCarsScreenState();
}

class _BookedCarsScreenState extends State<BookedCarsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TestDriveReminderService _reminderService = TestDriveReminderService();

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFE8C87C),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.login, size: 64, color: Colors.grey[600]),
                const SizedBox(height: 16),
                const Text(
                  'Please log in to view your bookings',
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF1E3A5F),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE8C87C),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: const Color(0xFFE8C87C),
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
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
                      const SizedBox(width: 12),
                      const Text(
                        'My Bookings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A5F),
                        ),
                      ),
                    ],
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
            // Bookings List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .doc(currentUser.uid)
                    . collection('my_bookings')
                    . orderBy('bookedAt', descending: true)
                    .snapshots(),
                builder: (context, bookingsSnapshot) {
                  if (bookingsSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1E3A5F),
                      ),
                    );
                  }

                  if (bookingsSnapshot.hasError) {
                    return Center(
                      child:  Column(
                        mainAxisAlignment:  MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                          const SizedBox(height: 16),
                          const Text(
                            'Error loading bookings',
                            style: TextStyle(fontSize: 16, color: Color(0xFF1E3A5F)),
                          ),
                        ],
                      ),
                    );
                  }

                  final bookings = bookingsSnapshot.data?. docs ?? [];

                  if (bookings.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 64, color:  Colors.grey[600]),
                          const SizedBox(height:  16),
                          const Text(
                            'No bookings yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A5F),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Book a test drive to see it here',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final booking = bookings[index]. data() as Map<String, dynamic>;
                      final carId = booking['carId'] ?? '';

                      return FutureBuilder<DocumentSnapshot>(
                        future: _firestore. collection('global').doc(carId).get(),
                        builder: (context, carSnapshot) {
                          if (carSnapshot.connectionState == ConnectionState.waiting) {
                            return _buildBookingCardSkeleton();
                          }

                          if (! carSnapshot.hasData || ! carSnapshot.data!.exists) {
                            return _buildBookingCard(
                              booking:  booking,
                              carData: null,
                              bookingId: bookings[index].id,
                            );
                          }

                          final carData = carSnapshot.data!. data() as Map<String, dynamic>;
                          return _buildBookingCard(
                            booking: booking,
                            carData: carData,
                            bookingId: bookings[index].id,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard({
    required Map<String, dynamic> booking,
    required Map<String, dynamic>? carData,
    required String bookingId,
  }) {
    final carName = booking['carName'] ?? 'Unknown Car';
    final carPrice = booking['carPrice'] ?? 'N/A';
    final testDriveDate = (booking['testDriveDate'] as Timestamp?)?.toDate();
    final testDriveTime = booking['testDriveTime'] ??  'N/A';
    final paymentMethod = booking['paymentMethod'] ?? 'Unknown';
    final status = booking['status'] ?? 'pending';
    final carId = booking['carId'] ??  '';

    final carImage = carData? ['Image1'] ?? '';
    final kmDriven = carData?['KM Driven'] ?? 0;
    final fuelType = carData?['Fuel Type'] ?? 'Unknown';
    final location = carData?['Set Location'] ?? 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow:  [
          BoxShadow(
            color: Colors.grey. withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: InkWell(
        onTap: carData != null
            ? () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CarDetailsScreen(carId: carId),
            ),
          );
        }
            : null,
        borderRadius: BorderRadius.circular(16),
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
                    borderRadius: const BorderRadius. vertical(
                      top:  Radius.circular(16),
                    ),
                    child: Image.network(
                      carImage,
                      width: double.infinity,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.directions_car,
                            size: 60,
                            color: Colors.grey[600],
                          ),
                        );
                      },
                    ),
                  )
                      : Center(
                    child: Icon(
                      Icons.directions_car,
                      size: 60,
                      color: Colors. grey[600],
                    ),
                  ),
                  // Status Badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: status == 'confirmed'
                            ? Colors.green
                            : Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status. toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Booking Details
            Padding(
              padding: const EdgeInsets. all(16),
              child:  Column(
                crossAxisAlignment:  CrossAxisAlignment.start,
                children: [
                  Text(
                    carName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight. bold,
                      color: Color(0xFF1E3A5F),
                    ),
                  ),
                  if (carData != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${NumberFormat('#,###').format(kmDriven)} KM  •  $fuelType  •  $location',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors. grey,
                      ),
                    ),
                  ],
                  const SizedBox(height:  12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:  CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 6),
                                Text(
                                  testDriveDate != null
                                      ? DateFormat('MMM d, yyyy')
                                      .format(testDriveDate)
                                      : 'N/A',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF1E3A5F),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.access_time,
                                    size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 6),
                                Text(
                                  testDriveTime,
                                  style: const TextStyle(
                                    fontSize:  13,
                                    color: Color(0xFF1E3A5F),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment:  CrossAxisAlignment.end,
                        children: [
                          Text(
                            carPrice,
                            style: const TextStyle(
                              fontSize:  18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A5F),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8C87C).withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              paymentMethod,
                              style:  const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E3A5F),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Cancel Button
                  SizedBox(
                    width:  double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _showCancelDialog(bookingId),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color:  Colors.red, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Cancel Booking',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCardSkeleton() {
    return Container(
      margin: const EdgeInsets. only(bottom: 16),
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:  Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1E3A5F),
        ),
      ),
    );
  }

  void _showCancelDialog(String bookingId) {
    showDialog(
      context:  context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius:  BorderRadius.circular(20),
        ),
        title: const Text(
          'Cancel Booking',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A5F),
          ),
        ),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cancelBooking(bookingId);
            },
            child:  const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelBooking(String bookingId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Get booking data to check for reminder notification ID
        final bookingDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('my_bookings')
            .doc(bookingId)
            .get();

        if (bookingDoc.exists) {
          final bookingData = bookingDoc.data();
          final reminderNotificationId = bookingData?['reminderNotificationId'] as int?;
          
          // Cancel the scheduled reminder if it exists
          if (reminderNotificationId != null && reminderNotificationId != -1) {
            await _reminderService.cancelReminder(reminderNotificationId);
          }
          
          // Also cancel by booking ID (in case notification is in Firestore)
          await _reminderService.cancelReminderByBookingId(bookingId);
        }

        // Delete the booking
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('my_bookings')
            .doc(bookingId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: Color(0xFF1E3A5F),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling booking:  $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}