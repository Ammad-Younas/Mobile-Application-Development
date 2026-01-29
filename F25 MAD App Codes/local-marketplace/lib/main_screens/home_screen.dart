import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import '../filter_screen.dart';
import '../providers/car_ad_provider.dart';
import 'car_details/car_details.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final PersistentTabController controller;
  const HomeScreen({Key? key, required this.controller}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController. dispose();
    super.dispose();
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterBottomSheet(),
    );
  }

// ✅ FIXED "KNOW MORE" DIALOG WITH SCROLLING AND WORKING CLOSE
  void _showKnowMoreDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 600), // ← Max height to prevent overflow
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: SingleChildScrollView( // ← Wrap content in scrollable view
              child:  Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize. min,
                  children: [
                    // Logo
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8C87C),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.directions_car,
                        size: 48,
                        color: Color(0xFF1E3A5F),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    const Text(
                      'Welcome to Get Cars',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A5F),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Description points
                    _buildInfoRow(Icons.search, 'Browse thousands of verified car listings'),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.favorite, 'Save your favorite cars for later'),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.chat_bubble_outline, 'Chat directly with sellers'),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons. event_available, 'Book test drives easily'),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.verified_user, 'Buy and sell with confidence'),
                    const SizedBox(height: 24),

                    // Tagline
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8C87C).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Your dream car is just a tap away!',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF1E3A5F),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Close button - ✅ FIXED TO ACTUALLY CLOSE THE DIALOG
                    SizedBox(
                      width:  double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // ← This closes the dialog
                        },
                        style: ElevatedButton. styleFrom(
                          backgroundColor:  const Color(0xFF1E3A5F),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'Got it! ',
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8C87C).withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xFF1E3A5F),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1E3A5F),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch all cars stream
    final allCarsAsync = ref.watch(allCarsStreamProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Container(
              color: const Color(0xFFE8C87C),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Top Bar with Logo and Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo
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
                      // Buy and Sell Buttons
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
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border. all(
                                  color:  const Color(0xFF1E3A5F),
                                  width: 2,
                                ),
                              ),
                              child: const Text(
                                'Buy',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight:  FontWeight.w600,
                                  color: Color(0xFF1E3A5F),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              widget.controller.jumpToTab(3);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD54F),
                                borderRadius:  BorderRadius.circular(20),
                              ),
                              child:  const Text(
                                'Sell',
                                style: TextStyle(
                                  fontSize:  14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E3A5F),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Search Bar
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Search cars...',
                              border: InputBorder.none,
                              icon: Icon(Icons.search, color: Color(0xFF1E3A5F)),
                            ),
                            onChanged: (value) {
                              // Update search query
                              ref.read(searchQueryProvider.notifier).setQuery(value);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          _showFilterBottomSheet(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.tune,
                            color: Color(0xFF1E3A5F),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Banner
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD54F),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Get your',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFF1E3A5F),
                                ),
                              ),
                              const Text(
                                'dream car here',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight:  FontWeight.bold,
                                  color: Color(0xFF1E3A5F),
                                ),
                              ),
                              const SizedBox(height:  12),
                              ElevatedButton(
                                onPressed: () {
                                  // ✅ SHOW DIALOG ON BUTTON PRESS
                                  _showKnowMoreDialog(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E3A5F),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text(
                                  'Know more',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 80),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Car Categories with Real Data
            Expanded(
              child: allCarsAsync.when(
                data: (allCars) {
                  if (allCars.isEmpty) {
                    return _buildEmptyState();
                  }

                  // Apply search filter
                  List<Map<String, dynamic>> displayCars = allCars;
                  if (searchQuery.isNotEmpty) {
                    final searchLower = searchQuery.toLowerCase();
                    displayCars = allCars. where((car) {
                      final carName = (car['Car Name'] as String?  ?? '').toLowerCase();
                      final brand = (car['Brand'] as String? ?? '').toLowerCase();
                      final model = (car['Model'] as String? ?? '').toLowerCase();
                      final location = (car['Set Location'] as String? ?? '').toLowerCase();

                      return carName.contains(searchLower) ||
                          brand.contains(searchLower) ||
                          model.contains(searchLower) ||
                          location.contains(searchLower);
                    }).toList();
                  }

                  if (displayCars.isEmpty) {
                    return _buildEmptySearchState();
                  }

                  // ✅ Group cars by fuel type (client-side filtering)
                  final petrolCars = displayCars. where((car) =>
                      (car['Fuel Type'] as String? ?? '').toLowerCase().contains('petrol')
                  ).toList();

                  final dieselCars = displayCars.where((car) =>
                      (car['Fuel Type'] as String? ?? '').toLowerCase().contains('diesel')
                  ).toList();

                  final electricCars = displayCars.where((car) =>
                      (car['Fuel Type'] as String? ?? '').toLowerCase().contains('electric')
                  ).toList();

                  final hybridCars = displayCars.where((car) =>
                      (car['Fuel Type'] as String?  ?? '').toLowerCase().contains('hybrid')
                  ).toList();

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (petrolCars.isNotEmpty) ...[
                        _buildCarCategory(
                          context,
                          'Petrol Cars',
                          'Efficient and Popular',
                          petrolCars,
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (dieselCars.isNotEmpty) ...[
                        _buildCarCategory(
                          context,
                          'Diesel Cars',
                          'Powerful and Economical',
                          dieselCars,
                        ),
                        const SizedBox(height:  20),
                      ],
                      if (electricCars. isNotEmpty) ...[
                        _buildCarCategory(
                          context,
                          'Electric Cars',
                          'Eco-Friendly Future',
                          electricCars,
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (hybridCars.isNotEmpty) ...[
                        _buildCarCategory(
                          context,
                          'Hybrid Cars',
                          'Best of Both Worlds',
                          hybridCars,
                        ),
                        const SizedBox(height: 20),
                      ],
                      // Show remaining cars if any
                      if (displayCars.length > (petrolCars.length + dieselCars.length + electricCars.length + hybridCars.length)) ...[
                        _buildCarCategory(
                          context,
                          'All Cars',
                          'Browse Our Collection',
                          displayCars,
                        ),
                      ],
                    ],
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF1E3A5F),
                  ),
                ),
                error: (error, stack) => _buildErrorState(error. toString()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarCategory(
      BuildContext context,
      String title,
      String subtitle,
      List<Map<String, dynamic>> cars,
      ) {
    return Column(
      children: [
        // Category Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8C87C),
            borderRadius: BorderRadius. circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A5F),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1E3A5F),
                    ),
                  ),
                ],
              ),
              Text(
                '${cars.length} cars',
                style: const TextStyle(
                  fontSize:  14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E3A5F),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Car Cards - Horizontal Scroll
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: cars.length > 10 ? 10 : cars. length,
            itemBuilder: (context, index) {
              final car = cars[index];
              return _buildCarCard(context, car);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCarCard(BuildContext context, Map<String, dynamic> car) {
    final carName = car['Car Name'] ??  '${car['Brand']} ${car['Model']}';
    final location = car['Set Location'] ?? 'Unknown';
    final fuelType = car['Fuel Type'] ?? 'Unknown';
    final price = car['Final Estimated Price'] ?? car['Estimated Price'] ?? 'N/A';
    final carId = car['id'] ?? '';
    final status = car['status'] ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
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
          boxShadow: [
            BoxShadow(
              color:  Colors.grey.withOpacity(0.2),
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
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.directions_car,
                      size:  50,
                      color: Colors.grey[600],
                    ),
                  ),
                  // Status badge
                  if (status.toLowerCase() == 'sold')
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding:  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'SOLD',
                          style: TextStyle(
                            color: Colors. white,
                            fontSize: 10,
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
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A5F),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$location - $fuelType',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors. grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A5F),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width:  double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CarDetailsScreen(carId: carId),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A5F),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment:  MainAxisAlignment.center,
                        children: [
                          Text(
                            'View car',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward, size: 14, color: Colors.white),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No cars available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new listings',
            style: TextStyle(fontSize: 14, color: Colors. grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return Center(
      child:  Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons. search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No cars found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight. w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child:  Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons. error_outline, size: 80, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text(
              'Unable to load cars',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF1E3A5F),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height:  12),
            Text(
              'Please check your internet connection and try again.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}