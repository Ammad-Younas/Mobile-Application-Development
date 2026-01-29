import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/car_ad_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/favorites_provider.dart';
import '../account_subscreens/chatdetails_screen.dart';
import 'booking_screen.dart';

class CarDetailsScreen extends ConsumerStatefulWidget {
  final String carId;

  const CarDetailsScreen({
    Key? key,
    required this.carId,
  }) : super(key: key);

  @override
  ConsumerState<CarDetailsScreen> createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends ConsumerState<CarDetailsScreen> {
  bool _isLoadingChat = false;

  // Generate a consistent avatar color based on seller name
  Color _getAvatarColor(String name) {
    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.amber,
    ];

    // Use the hash code of the name to pick a consistent color
    final index = name.hashCode. abs() % colors.length;
    return colors[index];
  }

  // Start a chat with the seller
  Future<void> _startChatWithSeller(Map<String, dynamic> car) async {
    final sellerUid = car['seller_uid'] ?? '';
    final sellerName = car['seller_name'] ?? 'Seller';

    if (sellerUid.isEmpty) {
      _showSnackBar('Seller information not available');
      return;
    }

    final currentUser = ref.read(authStateProvider).value;
    if (currentUser == null) {
      _showSnackBar('Please log in to contact the seller');
      return;
    }

    if (currentUser.uid == sellerUid) {
      _showSnackBar('This is your own listing');
      return;
    }

    setState(() {
      _isLoadingChat = true;
    });

    try {
      final chatService = ref.read(chatServiceProvider);
      final currentUserName = currentUser.displayName ?? 'User';

      // Create or get existing chat room
      final chatId = await chatService.getOrCreateChatRoom(
        currentUser.uid,
        sellerUid,
        currentUserName,
        sellerName,
      );

      setState(() {
        _isLoadingChat = false;
      });

      // Navigate to chat screen with all required parameters
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              name: sellerName,
              avatarColor: _getAvatarColor(sellerName),
              chatId: chatId,
              otherUserId: sellerUid,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingChat = false;
      });
      _showSnackBar('Error starting chat: $e');
    }
  }

  void _showSnackBar(String message) {
    if (! mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:  Text(message),
        backgroundColor: const Color(0xFF1E3A5F),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ✅ HELPER METHOD TO SAFELY PARSE NUMBERS
  int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final cleaned = value.replaceAll(',', '').trim();
      return int.tryParse(cleaned) ?? 0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final carAsync = ref.watch(carByIdProvider(widget.carId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: carAsync.when(
        data: (car) {
          if (car == null) {
            return _buildCarNotFound();
          }
          return _buildCarDetails(car);
        },
        loading: () => SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF1E3A5F),
                  ),
                ),
              ),
            ],
          ),
        ),
        error: (error, stack) => SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading car details',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.red[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: const Color(0xFFE8C87C),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children:  [
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
                child:  const Text(
                  'GC',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE8C87C),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Get Cars',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1E3A5F),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A5F)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCarNotFound() {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment. center,
                children: [
                  Icon(Icons.directions_car_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Car not found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style:  ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A5F),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Go Back',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarDetails(Map<String, dynamic> car) {
    final carName = car['Car Name'] ?? 'Unknown Car';
    final brand = car['Brand'] ?? '';
    final model = car['Model'] ?? '';
    final variant = car['Variant'] ?? '';

    // ✅ SAFE PARSING FOR NUMERIC FIELDS
    final year = _parseToInt(car['Year']);
    final kmDriven = _parseToInt(car['KM Driven']);
    final engineCapacity = _parseToInt(car['Engine Capacity']);

    final fuelType = car['Fuel Type'] ?? 'Unknown';
    final location = car['Set Location'] ?? 'Unknown';
    final transmissionType = car['Transmission Type'] ?? 'Unknown';
    final estimatedPrice = car['Estimated Price'] ?? '';
    final finalPrice = car['Final Estimated Price'] ?? '';
    final sellerName = car['seller_name'] ?? 'Unknown Seller';
    final status = car['status'] ?? '';
    final listedAt = car['listed_at'];

    // Get related cars (same fuel type)
    final relatedCars = ref.watch(carsByFuelTypeProvider(fuelType));

    return SafeArea(
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              child:  Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Related Cars Section
                      () {
                    // Filter out current car and limit to 5
                    final filtered = relatedCars.where((c) => c['id'] != car['id']).take(5).toList();

                    if (filtered.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Container(
                      color: const Color(0xFFE8C87C),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Related cars',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A5F),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height:  200,
                            child:  ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                return _buildRelatedCarCard(filtered[index]);
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }(),
                  const SizedBox(height: 20),
                  // Main Car Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey. withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:  CrossAxisAlignment.start,
                        children: [
                          // Car Image
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            child:  Stack(
                              children: [
                                Center(
                                  child: Icon(
                                    Icons.directions_car,
                                    size: 80,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                // Location Badge
                                Positioned(
                                  bottom: 12,
                                  left: 12,
                                  child:  Container(
                                    padding:  const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors. black.withOpacity(0.6),
                                      borderRadius:  BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons. location_on,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          location,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Status Badge (if sold)
                                if (status.toLowerCase() == 'sold')
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child:  Container(
                                      padding:  const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'SOLD',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Car Details
                          Padding(
                            padding: const EdgeInsets. all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child:  Text(
                                        carName,
                                        style: const TextStyle(
                                          fontSize:  24,
                                          fontWeight:  FontWeight.bold,
                                          color: Color(0xFF1E3A5F),
                                        ),
                                      ),
                                    ),

                                    // FAVORITE ICON - uses favorites_provider
                                    IconButton(
                                      icon: () {
                                        final isFavAsync = ref.watch(isFavoriteProvider(widget.carId));
                                        return isFavAsync. when(
                                          data:  (isFav) => Icon(
                                            isFav ? Icons.favorite : Icons.favorite_border,
                                            color: isFav ? Colors.red : const Color(0xFF1E3A5F),
                                          ),
                                          loading: () => const Icon(
                                            Icons.favorite_border,
                                            color: Color(0xFF1E3A5F),
                                          ),
                                          error: (_, __) => const Icon(
                                            Icons.favorite_border,
                                            color: Color(0xFF1E3A5F),
                                          ),
                                        );
                                      }(),
                                      onPressed:  () async {
                                        final currentUser = ref.read(authStateProvider).value;
                                        if (currentUser == null) {
                                          _showSnackBar('Please log in to add favorites');
                                          return;
                                        }

                                        try {
                                          await ref.read(favoritesServiceProvider).toggleFavorite(widget.carId);

                                          // small delay to let Firestore update and provider stream reflect change
                                          await Future.delayed(const Duration(milliseconds: 300));

                                          // read updated state
                                          final isFav = await ref.read(isFavoriteProvider(widget.carId).future);

                                          _showSnackBar(isFav ? 'Added to favorites ❤️' : 'Removed from favorites');
                                        } catch (e) {
                                          _showSnackBar('Error updating favorites: $e');
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${NumberFormat('#,###').format(kmDriven)} KM  •  $fuelType  •  $location',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Year: $year',
                                  style: const TextStyle(
                                    fontSize:  14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Specifications
                                Row(
                                  children: [
                                    Expanded(
                                      child:  _buildSpecItem(
                                        'Transmission',
                                        transmissionType,
                                      ),
                                    ),
                                    Expanded(
                                      child:  _buildSpecItem(
                                        'Engine Capacity',
                                        '$engineCapacity cc',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSpecItem(
                                        'Brand',
                                        brand,
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildSpecItem(
                                        'Model',
                                        model,
                                      ),
                                    ),
                                  ],
                                ),
                                if (variant.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  _buildSpecItem('Variant', variant),
                                ],
                                const SizedBox(height: 20),
                                // Seller Info
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8C87C).withOpacity(0.2),
                                    borderRadius:  BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: _getAvatarColor(sellerName),
                                        child: const Icon(
                                          Icons. person,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child:  Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Seller',
                                              style:  TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            Text(
                                              sellerName,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight:  FontWeight.w600,
                                                color: Color(0xFF1E3A5F),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Price Section
                                Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (estimatedPrice.isNotEmpty && estimatedPrice != finalPrice) ...[
                                          Text(
                                            estimatedPrice,
                                            style: TextStyle(
                                              fontSize:  16,
                                              color: Colors.grey[600],
                                              decoration: TextDecoration.lineThrough,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                        ],
                                        Text(
                                          finalPrice. isNotEmpty ? finalPrice : 'Price on request',
                                          style:  const TextStyle(
                                            fontSize: 28,
                                            fontWeight:  FontWeight.bold,
                                            color: Color(0xFF1E3A5F),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (listedAt != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Listed on ${DateFormat('MMM dd, yyyy').format((listedAt).toDate())}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Action Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: status.toLowerCase() == 'sold'
                                ? null
                                : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookTestDriveScreen(
                                    carName: carName,
                                    carId: car['id'],
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A5F),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Text(
                              status.toLowerCase() == 'sold' ? 'Sold Out' : 'Book Test Drive',
                              style:  const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoadingChat || status.toLowerCase() == 'sold' ? null : () => _startChatWithSeller(car),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(
                                color: Color(0xFF1E3A5F),
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: _isLoadingChat
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF1E3A5F),
                              ),
                            )
                                :  const Text(
                              'Contact Seller',
                              style:  TextStyle(
                                fontSize:  16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E3A5F),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E3A5F),
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedCarCard(Map<String, dynamic> car) {
    final carName = car['Car Name'] ?? '${car['Brand']} ${car['Model']}';
    final location = car['Set Location'] ?? 'Unknown';
    final fuelType = car['Fuel Type'] ?? 'Unknown';
    final price = car['Final Estimated Price'] ?? car['Estimated Price'] ?? 'N/A';
    final carId = car['id'] ?? '';
    final status = car['status'] ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CarDetailsScreen(carId: carId),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow:  [
            BoxShadow(
              color: Colors.grey. withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Car Image
            Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius:  const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.directions_car,
                      size: 35,
                      color: Colors. grey[600],
                    ),
                  ),
                  if (status.toLowerCase() == 'sold')
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding:  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'SOLD',
                          style:  TextStyle(
                            color:  Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    carName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A5F),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$location - $fuelType',
                    style: TextStyle(fontSize: 8, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height:  6),
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A5F),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width:  double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CarDetailsScreen(carId:  carId),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A5F),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment:  MainAxisAlignment.center,
                        children: [
                          Text(
                            'View car',
                            style: TextStyle(fontSize: 9, color: Colors.white),
                          ),
                          SizedBox(width: 2),
                          Icon(Icons.arrow_forward, size: 9, color: Colors.white),
                        ],
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
}