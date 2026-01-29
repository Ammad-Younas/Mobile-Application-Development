import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/car_model.dart';
import 'auth_provider.dart';

// Cars collection reference
final carsCollectionProvider = Provider<CollectionReference>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('global');
});

// ✅ FIXED: Stream of ALL cars (uses 'createdAt' instead of 'listed_at')
final allCarsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final carsCollection = ref.watch(carsCollectionProvider);

  // ✅ FIXED: Changed 'listed_at' to 'createdAt' to match your Firestore schema
  return carsCollection
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot. docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc. id;
      return data;
    }).toList();
  }).handleError((error) {
    // ✅ ADDED: Better error handling
    print('❌ Error fetching cars: $error');
    return <Map<String, dynamic>>[];
  });
});

// ✅ Search query notifier
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier. new,
);

// ✅ Filtered cars based on search (client-side filtering)
final filteredCarsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final allCarsAsync = ref.watch(allCarsStreamProvider);
  final searchQuery = ref.watch(searchQueryProvider);

  return allCarsAsync. when(
    data: (cars) {
      if (searchQuery. isEmpty) {
        return cars;
      }

      final searchLower = searchQuery.toLowerCase();
      return cars.where((car) {
        final carName = (car['Car Name'] as String?  ?? '').toLowerCase();
        final brand = (car['Brand'] as String? ?? '').toLowerCase();
        final model = (car['Model'] as String? ?? '').toLowerCase();
        final location = (car['Set Location'] as String? ??  '').toLowerCase();

        return carName.contains(searchLower) ||
            brand.contains(searchLower) ||
            model. contains(searchLower) ||
            location.contains(searchLower);
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// ✅ Get single car by ID (Stream)
final carByIdProvider = StreamProvider. family<Map<String, dynamic>?, String>((ref, carId) {
  if (carId.isEmpty) {
    return Stream.value(null);
  }

  final carsCollection = ref.watch(carsCollectionProvider);

  return carsCollection
      .doc(carId)
      .snapshots()
      .map((snapshot) {
    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      data['id'] = snapshot.id;
      return data;
    }
    return null;
  });
});

// ✅ Get single car by ID (Future - one-time fetch)
final carByIdFutureProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, carId) async {
  if (carId.isEmpty) {
    return null;
  }

  final carsCollection = ref.watch(carsCollectionProvider);

  final snapshot = await carsCollection.doc(carId).get();
  if (snapshot.exists) {
    final data = snapshot.data() as Map<String, dynamic>;
    data['id'] = snapshot.id;
    return data;
  }
  return null;
});

// ✅ FIXED: Cars by seller (uses 'createdAt' instead of 'listed_at')
final carsBySellerProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, sellerUid) {
  if (sellerUid. isEmpty) {
    return Stream. value([]);
  }

  final carsCollection = ref.watch(carsCollectionProvider);

  // ✅ FIXED: Changed 'listed_at' to 'createdAt'
  return carsCollection
      .where('seller_uid', isEqualTo: sellerUid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  });
});

// ✅ Cars by fuel type (client-side filtering)
final carsByFuelTypeProvider = Provider.family<List<Map<String, dynamic>>, String>((ref, fuelType) {
  final allCarsAsync = ref.watch(allCarsStreamProvider);

  return allCarsAsync.when(
    data: (cars) {
      if (fuelType.isEmpty || fuelType.toLowerCase() == 'all') {
        return cars;
      }

      final fuelLower = fuelType.toLowerCase();
      return cars.where((car) {
        final carFuel = (car['Fuel Type'] as String? ?? '').toLowerCase();
        return carFuel. contains(fuelLower);
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// ✅ Cars by status (client-side filtering)
final carsByStatusProvider = Provider.family<List<Map<String, dynamic>>, String>((ref, status) {
  final allCarsAsync = ref.watch(allCarsStreamProvider);

  return allCarsAsync.when(
    data: (cars) {
      if (status.isEmpty || status.toLowerCase() == 'all') {
        return cars;
      }

      return cars.where((car) {
        final carStatus = (car['status'] as String? ??  '').toLowerCase();
        return carStatus == status.toLowerCase();
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});