import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({Key? key}) : super(key: key);

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final TextEditingController _questionController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  bool _isSubmitting = false;

  // List of default FAQs
  final List<Map<String, String>> _defaultFaqs = [
    {
      'question': 'How do I list my car for sale?',
      'answer': 'Go to the Sell screen, tap "Add New Listing", fill in your car details, upload photos, and submit. Your listing will be visible to all users immediately.'
    },
    {
      'question': 'Is it free to use GetCars?',
      'answer': 'Yes!  GetCars is completely free to use. You can browse, list, and message sellers without any charges.'
    },
    {
      'question': 'How do I contact a seller?',
      'answer': 'On any car listing, tap the "Chat" button to start a conversation with the seller directly through our messaging system.'
    },
    {
      'question': 'Can I edit my listing after posting?',
      'answer': 'Yes, go to your Account screen, find your listing, and tap "Edit" to update details, photos, or pricing.'
    },
    {
      'question': 'How do I mark a car as sold?',
      'answer': 'Go to your listings, find the sold car, and tap "Mark as Sold".  This will remove it from active listings.'
    },
    {
      'question': 'What payment methods are accepted?',
      'answer': 'GetCars is a marketplace platform.  Payment is handled directly between buyer and seller.  We recommend meeting in person and using secure payment methods.'
    },
    {
      'question': 'How do I report a suspicious listing?',
      'answer': 'Tap the three dots on any listing and select "Report".  Our team will review it within 24 hours.'
    },
    {
      'question': 'Can I save favorite cars?',
      'answer': 'Yes!  Tap the heart icon on any listing to add it to your favorites. View all saved cars in the Favorites screen.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _createDefaultFaqsIfNeeded();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Create default FAQs in Firebase if they don't exist
  Future<void> _createDefaultFaqsIfNeeded() async {
    try {
      final snapshot = await _firestore.collection('faqs').limit(1).get();

      if (snapshot.docs.isEmpty) {
        for (var faq in _defaultFaqs) {
          await _firestore.collection('faqs').add({
            'question': faq['question'],
            'answer': faq['answer'],
            'timestamp': FieldValue.serverTimestamp(),
            'isActive': true,
            'isAnswered': true,
          });
        }
        debugPrint('Default FAQs created');
      }
    } catch (e) {
      debugPrint('Error creating default FAQs: $e');
    }
  }

  Future<void> _submitQuestion() async {
    if (_questionController. text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your question'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final currentUser = _auth.currentUser;

      // Save directly to FAQs collection as "unanswered"
      await _firestore.collection('faqs').add({
        'userId': currentUser?.uid ??  'anonymous',
        'userEmail': currentUser?.email ?? 'anonymous',
        'question': _questionController.text.trim(),
        'answer': 'This question is pending review.  We will answer it soon! ',
        'timestamp': FieldValue.serverTimestamp(),
        'isActive': true,
        'isAnswered': false, // Mark as unanswered
        'isPending': true,
      });

      _questionController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your question has been submitted and will appear below! '),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error submitting question: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit question: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: const Color(0xFFE8C87C),
              padding: const EdgeInsets. all(16),
              child: Column(
                children: [
                  Row(
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
                              borderRadius: BorderRadius. circular(8),
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
                        icon: const Icon(
                          Icons.menu,
                          color: Color(0xFF1E3A5F),
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  // FAQ Title with Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "FAQ's",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A5F),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E3A5F),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.help_outline,
                          color: Color(0xFFE8C87C),
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Search Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value. toLowerCase();
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Search FAQs...',
                        border: InputBorder.none,
                        icon: Icon(Icons.search, color: Color(0xFF1E3A5F)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            // FAQ List from Firebase
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // REQUIRES INDEX: [isActive, timestamp DESC]
                // Firebase will automatically prompt you to create it when first used
                stream: _firestore
                    .collection('faqs')
                    .where('isActive', isEqualTo: true)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 60,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text('Error: ${snapshot.error}'),
                          const SizedBox(height: 8),
                          const Text(
                            'You may need to create a Firestore index',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState. waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1E3A5F),
                      ),
                    );
                  }

                  var faqs = snapshot.data?. docs ?? [];

                  // Filter FAQs based on search query
                  if (_searchQuery.isNotEmpty) {
                    faqs = faqs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final question = (data['question'] ??  '').toString().toLowerCase();
                      final answer = (data['answer'] ?? '').toString().toLowerCase();
                      return question.contains(_searchQuery) ||
                          answer.contains(_searchQuery);
                    }).toList();
                  }

                  if (faqs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.help_outline,
                            size: 80,
                            color: Colors. grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No FAQs found'
                                : 'No FAQs available',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        ... faqs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final isPending = data['isPending'] ??  false;
                          final isAnswered = data['isAnswered'] ?? true;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildFaqItem(
                              data['question'] ?? 'Question',
                              data['answer'] ??  'Answer',
                              isPending: isPending,
                              isAnswered: isAnswered,
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 30),
                        // Question Input Section
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Put up your Question',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1E3A5F),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _questionController,
                          enabled: !_isSubmitting,
                          maxLines: 3,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'Type your question here...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius. circular(25),
                              borderSide: const BorderSide(
                                color: Color(0xFF1E3A5F),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: const BorderSide(
                                color: Color(0xFF1E3A5F),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius. circular(25),
                              borderSide: const BorderSide(
                                color: Color(0xFF1E3A5F),
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ?  null : _submitQuestion,
                            style: ElevatedButton. styleFrom(
                              backgroundColor: const Color(0xFF1E3A5F),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : const Text(
                              'Submit Question',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer, {bool isPending = false, bool isAnswered = true}) {
    return _FaqExpansionTile(
      question: question,
      answer: answer,
      isPending: isPending,
      isAnswered: isAnswered,
    );
  }
}

// Expandable FAQ Item Widget
class _FaqExpansionTile extends StatefulWidget {
  final String question;
  final String answer;
  final bool isPending;
  final bool isAnswered;

  const _FaqExpansionTile({
    required this.question,
    required this.answer,
    this.isPending = false,
    this.isAnswered = true,
  });

  @override
  State<_FaqExpansionTile> createState() => _FaqExpansionTileState();
}

class _FaqExpansionTileState extends State<_FaqExpansionTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isPending ?  Colors.orange.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: widget.isPending
            ? Border.all(color: Colors.orange, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors. grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Material(
        color: Colors. transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _isExpanded = ! _isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(25),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          if (widget.isPending)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius. circular(12),
                              ),
                              child: const Text(
                                'PENDING',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (widget.isPending) const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.question,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E3A5F),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: const Color(0xFF1E3A5F),
                    ),
                  ],
                ),
                if (_isExpanded) ...[
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFE8C87C), thickness: 1),
                  const SizedBox(height: 12),
                  Text(
                    widget.answer,
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.isPending ? Colors.orange[800] : Colors.grey[700],
                      height: 1.5,
                      fontStyle: widget.isPending ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}