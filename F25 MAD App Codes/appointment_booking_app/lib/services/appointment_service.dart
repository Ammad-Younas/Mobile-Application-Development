import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Book an appointment
  Future<Map<String, dynamic>> bookAppointment({required String userId, required String doctorId, required String doctorName, required String patientName, required DateTime date, required String timeSlot, required String status, String? doctorImage}) async {
    try {
      // 1. Check for Double Booking
      // Query if there is already an appointment for this doctor at this date and time
      // We filter by status != 'Cancelled' effectively by checking active bookings
      final QuerySnapshot existingAppointments = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('date', isEqualTo: Timestamp.fromDate(date))
          .where('timeSlot', isEqualTo: timeSlot)
          .where('status', isNotEqualTo: 'Cancelled') // Assumes 'Cancelled' is the only status that frees up a slot
          .get();

      if (existingAppointments.docs.isNotEmpty) {
        return {'success': false, 'message': 'This time slot is already booked. Please choose another one.'};
      }

      // 2. Perform Booking & Update Slots Atomically
      return await _firestore.runTransaction((transaction) async {
        final doctorRef = _firestore.collection('doctors').doc(doctorId);
        final doctorSnapshot = await transaction.get(doctorRef);

        if (!doctorSnapshot.exists) {
          throw Exception("Doctor not found");
        }

        final dynamic slotsData = (doctorSnapshot.data() as Map<String, dynamic>)['slots'];
        int currentSlots = 0;
        if (slotsData is int) {
          currentSlots = slotsData;
        } else if (slotsData is String) {
          currentSlots = int.tryParse(slotsData) ?? 0;
        } else if (slotsData is double) {
          currentSlots = slotsData.toInt();
        }

        if (currentSlots <= 0) {
          throw Exception("No slots available for this doctor");
        }

        // Create new appointment reference
        final newAppointmentRef = _firestore.collection('appointments').doc();

        transaction.set(newAppointmentRef, {'userId': userId, 'doctorId': doctorId, 'doctorName': doctorName, 'doctorImage': doctorImage, 'patientName': patientName, 'date': Timestamp.fromDate(date), 'timeSlot': timeSlot, 'status': status, 'createdAt': FieldValue.serverTimestamp()});

        // Decrement slots
        transaction.update(doctorRef, {'slots': currentSlots - 1});

        return {'success': true, 'message': 'Appointment booked successfully', 'appointmentId': newAppointmentRef.id};
      });
    } catch (e) {
      // Clean up error message if it was an exception
      String message = e.toString();
      if (message.contains('Exception: ')) {
        message = message.replaceAll('Exception: ', '');
      }
      return {'success': false, 'message': 'Failed to book: $message'};
    }
  }

  // Get appointments for a user
  Stream<QuerySnapshot> getAppointments(String userId) {
    return _firestore.collection('appointments').where('userId', isEqualTo: userId).orderBy('date', descending: false).snapshots();
  }

  // Cancel an appointment
  Future<void> cancelAppointment(String appointmentId) async {
    await _firestore.collection('appointments').doc(appointmentId).update({'status': 'Cancelled'});
  }

  // Delete an appointment
  Future<void> deleteAppointment(String appointmentId) async {
    await _firestore.collection('appointments').doc(appointmentId).delete();
  }

  // Reschedule an appointment
  Future<Map<String, dynamic>> rescheduleAppointment({required String appointmentId, required DateTime newDate, required String newTimeSlot}) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({'date': Timestamp.fromDate(newDate), 'timeSlot': newTimeSlot, 'status': 'Rescheduled', 'updatedAt': FieldValue.serverTimestamp()});

      return {'success': true, 'message': 'Appointment rescheduled successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to reschedule appointment: $e'};
    }
  }
}
