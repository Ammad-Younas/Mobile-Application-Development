import 'package:cloud_firestore/cloud_firestore.dart';

class Car {
  final String id;
  final bool autoDetect;
  final String brand;
  final String carName;
  final int engineCapacity;
  final String estimatedPrice;
  final String finalEstimatedPrice;
  final String fuelType;
  final int imagesUploaded;
  final int kmDriven;
  final String model;
  final String screen;
  final String setLocation;
  final String transmissionType;
  final String variant;
  final int year;
  final DateTime listedAt;
  final String sellerEmail;
  final String sellerName;
  final String sellerUid;
  final String status;

  Car({
    required this. id,
    required this.autoDetect,
    required this. brand,
    required this.carName,
    required this.engineCapacity,
    required this. estimatedPrice,
    required this.finalEstimatedPrice,
    required this.fuelType,
    required this.imagesUploaded,
    required this. kmDriven,
    required this.model,
    required this.screen,
    required this. setLocation,
    required this. transmissionType,
    required this.variant,
    required this. year,
    required this.listedAt,
    required this. sellerEmail,
    required this.sellerName,
    required this.sellerUid,
    required this.status,
  });

  factory Car.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Car(
      id: doc.id,
      autoDetect: data['Auto Detect'] ??  false,
      brand: data['Brand'] ?? '',
      carName: data['Car Name'] ?? '',
      engineCapacity: data['Engine Capacity'] ?? 0,
      estimatedPrice: data['Estimated Price'] ?? '',
      finalEstimatedPrice: data['Final Estimated Price'] ?? '',
      fuelType: data['Fuel Type'] ?? '',
      imagesUploaded: data['Images Uploaded'] ?? 0,
      kmDriven: data['KM Driven'] ?? 0,
      model: data['Model'] ?? '',
      screen: data['Screen'] ?? '',
      setLocation: data['Set Location'] ?? '',
      transmissionType: data['Transmission Type'] ?? '',
      variant: data['Variant'] ??  '',
      year: data['Year'] ?? 0,
      listedAt: (data['listed_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sellerEmail: data['seller_email'] ?? '',
      sellerName: data['seller_name'] ?? '',
      sellerUid: data['seller_uid'] ?? '',
      status: data['status'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Auto Detect': autoDetect,
      'Brand': brand,
      'Car Name': carName,
      'Engine Capacity': engineCapacity,
      'Estimated Price': estimatedPrice,
      'Final Estimated Price': finalEstimatedPrice,
      'Fuel Type': fuelType,
      'Images Uploaded': imagesUploaded,
      'KM Driven': kmDriven,
      'Model': model,
      'Screen': screen,
      'Set Location': setLocation,
      'Transmission Type': transmissionType,
      'Variant': variant,
      'Year': year,
      'listed_at': Timestamp.fromDate(listedAt),
      'seller_email': sellerEmail,
      'seller_name': sellerName,
      'seller_uid': sellerUid,
      'status': status,
    };
  }
}